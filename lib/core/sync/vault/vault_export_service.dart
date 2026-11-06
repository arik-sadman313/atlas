import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../database/daos/nodes_dao.dart';
import '../../database/daos/sync_dao.dart';
import '../device/device_identity_service.dart';
import 'vault_manifest.dart';

class VaultExportService {
  final AppDatabase database;
  final SyncDao syncDao;
  final NodesDao nodesDao;
  final DeviceIdentityService deviceIdentity;
  final File databaseFile;
  final Directory casDirectory;
  final Uuid _uuid;

  VaultExportService({
    required this.database,
    required this.syncDao,
    required this.nodesDao,
    required this.deviceIdentity,
    required this.databaseFile,
    required this.casDirectory,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Exports a complete `.atlas_vault` archive to [destinationFile].
  Future<File> exportVault({
    required File destinationFile,
    String? workspaceId,
  }) async {
    final syncId = _uuid.v4();
    await syncDao.startSync(id: syncId, syncType: 'vault_export');

    try {
      // 1. Flush in-flight database WAL logs to disk
      await database.walCheckpoint();

      // 2. Compute DB checksum
      final dbBytes = databaseFile.existsSync()
          ? await databaseFile.readAsBytes()
          : Uint8List(0);
      final dbChecksum = sha256.convert(dbBytes).toString().toLowerCase();

      // 3. Scan CAS directory and compute SHA-256 for all blobs
      final blobsMap = <String, String>{};
      final casFiles = <String, Uint8List>{};

      if (casDirectory.existsSync()) {
        final entities = casDirectory.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            final relPath = p.relative(entity.path, from: casDirectory.path);
            final bytes = await entity.readAsBytes();
            final hash = sha256.convert(bytes).toString().toLowerCase();
            blobsMap[relPath] = hash;
            casFiles[relPath] = bytes;
          }
        }
      }

      // 4. Count total nodes
      int totalNodes = 0;
      if (workspaceId != null) {
        final nodes = await nodesDao.getAllNodes(workspaceId);
        totalNodes = nodes.length;
      } else {
        final allWorkspaces = await database.workspacesDao.getAllWorkspaces();
        for (final ws in allWorkspaces) {
          final nodes = await nodesDao.getAllNodes(ws.id);
          totalNodes += nodes.length;
        }
      }

      // 5. Build Manifest
      final deviceId = await deviceIdentity.getOrCreateDeviceId();
      final deviceName = await deviceIdentity.getDeviceName();
      final manifest = VaultManifest(
        createdAt: DateTime.now().toUtc().toIso8601String(),
        deviceId: deviceId,
        deviceName: deviceName,
        totalNodes: totalNodes,
        databaseChecksum: dbChecksum,
        blobs: blobsMap,
      );

      // 6. Assemble ZIP archive
      final archive = Archive();

      // manifest.json
      final manifestBytes = utf8.encode(manifest.encode());
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      // database.sqlite
      archive.addFile(ArchiveFile('database.sqlite', dbBytes.length, dbBytes));

      // cas/ blobs
      for (final entry in casFiles.entries) {
        archive.addFile(
          ArchiveFile('cas/${entry.key}', entry.value.length, entry.value),
        );
      }

      // 7. Write to destination file
      final zipEncoder = ZipEncoder();
      final encoded = zipEncoder.encode(archive);

      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      await destinationFile.writeAsBytes(encoded, flush: true);

      // 8. Record completed sync metrics
      await syncDao.completeSync(
        id: syncId,
        recordsExported: totalNodes,
        blobsTransferred: blobsMap.length,
      );

      return destinationFile;
    } catch (e) {
      await syncDao.failSync(id: syncId, errorMessage: e.toString());
      rethrow;
    }
  }
}
