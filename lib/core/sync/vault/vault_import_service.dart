import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../database/daos/sync_dao.dart';
import 'vault_manifest.dart';

class VaultImportResult {
  final VaultManifest manifest;
  final int restoredBlobsCount;
  final int restoredRecordsCount;

  const VaultImportResult({
    required this.manifest,
    required this.restoredBlobsCount,
    required this.restoredRecordsCount,
  });
}

class VaultImportService {
  final AppDatabase database;
  final SyncDao syncDao;
  final File databaseFile;
  final Directory casDirectory;
  final Uuid _uuid;

  VaultImportService({
    required this.database,
    required this.syncDao,
    required this.databaseFile,
    required this.casDirectory,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Inspects a `.atlas_vault` container, validating format version and returning its manifest.
  Future<VaultManifest> inspectVault(File vaultFile) async {
    if (!vaultFile.existsSync()) {
      throw FileNotFoundException(
        'Vault archive file not found: ${vaultFile.path}',
      );
    }

    final bytes = await vaultFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Corrupted vault: manifest.json missing');
    }

    final manifestBytes = manifestFile.content as List<int>;
    final manifestJson = jsonDecode(utf8.decode(manifestBytes));
    final manifest = VaultManifest.fromJson(manifestJson);

    if (manifest.formatVersion != '1.0') {
      throw UnsupportedError(
        'Incompatible vault version: ${manifest.formatVersion}. Expected: 1.0',
      );
    }

    return manifest;
  }

  /// Restores all CAS attachments and the SQLite database atomically after checksum verification.
  Future<VaultImportResult> restoreVault(File vaultFile) async {
    final syncId = _uuid.v4();
    await syncDao.startSync(id: syncId, syncType: 'vault_import');

    File? backupFile;

    try {
      final bytes = await vaultFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Inspect & Validate Manifest
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null) {
        throw const FormatException('Corrupted vault: manifest.json missing');
      }
      final manifest = VaultManifest.fromJson(
        jsonDecode(utf8.decode(manifestFile.content as List<int>)),
      );

      if (manifest.formatVersion != '1.0') {
        throw UnsupportedError(
          'Incompatible vault version: ${manifest.formatVersion}. Expected: 1.0',
        );
      }

      // 2. Validate Database File & Checksum
      final dbArchiveFile = archive.findFile('database.sqlite');
      if (dbArchiveFile == null) {
        throw const FormatException('Corrupted vault: database.sqlite missing');
      }
      final dbBytes = Uint8List.fromList(dbArchiveFile.content as List<int>);
      final computedDbChecksum = sha256
          .convert(dbBytes)
          .toString()
          .toLowerCase();

      if (computedDbChecksum != manifest.databaseChecksum.toLowerCase()) {
        throw const FormatException(
          'Database integrity verification failed: checksum mismatch',
        );
      }

      // 3. Validate and collect CAS blobs
      final blobsToExtract = <String, Uint8List>{};
      for (final file in archive.files) {
        if (file.name.startsWith('cas/') && !file.isDirectory) {
          final relPath = file.name.substring(4); // remove 'cas/'
          final blobBytes = Uint8List.fromList(file.content as List<int>);
          final expectedChecksum = manifest.blobs[relPath];

          if (expectedChecksum != null) {
            final computed = sha256.convert(blobBytes).toString().toLowerCase();
            if (computed != expectedChecksum.toLowerCase()) {
              throw FormatException(
                'Corrupted CAS blob $relPath: checksum mismatch',
              );
            }
          }
          blobsToExtract[relPath] = blobBytes;
        }
      }

      // 4. Atomic Restoration: Backup current database if it exists
      if (databaseFile.existsSync()) {
        backupFile = File(
          '${databaseFile.path}.bak_${DateTime.now().microsecondsSinceEpoch}',
        );
        await databaseFile.copy(backupFile.path);
      }

      // Flush current database before replacing
      await database.walCheckpoint();

      // Write restored database
      if (!databaseFile.parent.existsSync()) {
        databaseFile.parent.createSync(recursive: true);
      }
      await databaseFile.writeAsBytes(dbBytes, flush: true);

      // Remove any leftover WAL/SHM files to prevent WAL inconsistency
      final walFile = File('${databaseFile.path}-wal');
      final shmFile = File('${databaseFile.path}-shm');
      if (walFile.existsSync()) await walFile.delete();
      if (shmFile.existsSync()) await shmFile.delete();

      // 5. Unpack CAS blobs into local CAS storage
      int restoredBlobs = 0;
      for (final entry in blobsToExtract.entries) {
        final targetBlob = File(p.join(casDirectory.path, entry.key));
        if (!targetBlob.parent.existsSync()) {
          targetBlob.parent.createSync(recursive: true);
        }
        await targetBlob.writeAsBytes(entry.value, flush: true);
        restoredBlobs++;
      }

      // Clean up backup after success
      if (backupFile != null && backupFile.existsSync()) {
        try {
          await backupFile.delete();
        } catch (_) {}
      }

      // 6. Record successful sync run
      await syncDao.completeSync(
        id: syncId,
        recordsImported: manifest.totalNodes,
        blobsTransferred: restoredBlobs,
      );

      return VaultImportResult(
        manifest: manifest,
        restoredBlobsCount: restoredBlobs,
        restoredRecordsCount: manifest.totalNodes,
      );
    } catch (e) {
      // Revert database from backup if failure occurred during overwrite
      if (backupFile != null && backupFile.existsSync()) {
        try {
          await backupFile.copy(databaseFile.path);
          await backupFile.delete();
        } catch (_) {}
      }

      await syncDao.failSync(id: syncId, errorMessage: e.toString());
      rethrow;
    }
  }
}

class FileNotFoundException implements IOException {
  final String message;
  const FileNotFoundException(this.message);

  @override
  String toString() => 'FileNotFoundException: $message';
}
