import 'dart:convert';
import 'dart:io';

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/sync/device/device_identity_service.dart';
import 'package:atlas/core/sync/folder/changeset_model.dart';
import 'package:atlas/core/sync/folder/folder_sync_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FolderSyncEngine Tests', () {
    late Directory tempDir;
    late Directory syncDir;
    late Directory casDir;
    late AppDatabase database;
    late DeviceIdentityService deviceIdentity;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp(
        'atlas_folder_sync_test_',
      );
      syncDir = Directory(p.join(tempDir.path, 'shared_sync_folder'));
      casDir = Directory(p.join(tempDir.path, 'local_cas'));
      await syncDir.create(recursive: true);
      await casDir.create(recursive: true);

      database = AppDatabase.inMemory();
      deviceIdentity = DeviceIdentityService();
      await deviceIdentity.setSyncDirectoryPath(syncDir.path);
    });

    tearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('FolderSyncEngine exports local mutations and CAS blobs to sync directory', () async {
      final now = DateTime.now().toUtc();
      const wsId = 'ws-folder-sync-1';
      const nodeId = 'node-folder-1';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Folder Sync WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Create a local blob in CAS
      final blobData = Uint8List.fromList(utf8.encode('Sync engine blob test'));
      final blobHash = sha256.convert(blobData).toString().toLowerCase();
      final localBlobFile = File(
        p.join(casDir.path, blobHash.substring(0, 2), blobHash),
      );
      await localBlobFile.parent.create(recursive: true);
      await localBlobFile.writeAsBytes(blobData);

      // Create local document node
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: nodeId,
          workspaceId: wsId,
          type: 'document',
          title: 'Folder Sync Document',
          contentHash: Value(blobHash),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final engine = FolderSyncEngine(
        database: database,
        syncDao: database.syncDao,
        deviceIdentity: deviceIdentity,
        casDirectory: casDir,
        overrideSyncDirectory: syncDir,
      );

      final result = await engine.sync();
      expect(result.success, isTrue);
      expect(result.recordsExported, greaterThanOrEqualTo(1));

      final deviceId = await deviceIdentity.getOrCreateDeviceId();

      // Verify client info.json exists in sync directory
      final infoFile = File(
        p.join(syncDir.path, 'clients', deviceId, 'info.json'),
      );
      expect(infoFile.existsSync(), isTrue);

      // Verify changeset file was written
      final changesDir = Directory(
        p.join(syncDir.path, 'clients', deviceId, 'changes'),
      );
      expect(changesDir.existsSync(), isTrue);
      final changesets = changesDir.listSync().whereType<File>().toList();
      expect(changesets.length, 1);
      expect(changesets.first.path.endsWith('.atlas_changeset'), isTrue);

      // Verify blob was replicated to shared blobs directory
      final replicatedBlob = File(
        p.join(syncDir.path, 'blobs', blobHash.substring(0, 2), blobHash),
      );
      expect(replicatedBlob.existsSync(), isTrue);
      expect(await replicatedBlob.readAsBytes(), blobData);
    });

    test('FolderSyncEngine ingests remote changesets and blobs', () async {
      final now = DateTime.now().toUtc();
      const wsId = 'ws-folder-ingest-1';
      const remoteDeviceId = 'client-remote-laptop';
      const remoteNodeId = 'remote-node-999';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Ingest WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 1. Simulate remote device putting a blob in shared blobs directory
      final remoteBlobData = Uint8List.fromList(
        utf8.encode('Remote blob contents'),
      );
      final remoteBlobHash = sha256
          .convert(remoteBlobData)
          .toString()
          .toLowerCase();
      final remoteSharedBlob = File(
        p.join(
          syncDir.path,
          'blobs',
          remoteBlobHash.substring(0, 2),
          remoteBlobHash,
        ),
      );
      await remoteSharedBlob.parent.create(recursive: true);
      await remoteSharedBlob.writeAsBytes(remoteBlobData);

      // 2. Simulate remote device placing an .atlas_changeset
      final remoteChangeset = AtlasChangeset(
        deviceId: remoteDeviceId,
        sequence: 1,
        timestamp: now,
        referencedBlobHashes: [remoteBlobHash],
        nodes: [
          {
            'id': remoteNodeId,
            'workspaceId': wsId,
            'type': 'document',
            'title': 'Remote Laptop Note',
            'contentHash': remoteBlobHash,
            'sortOrder': 0,
            'isFavorite': false,
            'isPinned': false,
            'isArchived': false,
            'isDeleted': false,
            'metadataJson': '{}',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'clientModifiedAt': now.toIso8601String(),
            'modifiedDeviceId': remoteDeviceId,
            'syncVersion': 1,
          },
        ],
      );

      final remoteClientDir = Directory(
        p.join(syncDir.path, 'clients', remoteDeviceId, 'changes'),
      );
      await remoteClientDir.create(recursive: true);
      final changesetFile = File(
        p.join(
          remoteClientDir.path,
          '${now.millisecondsSinceEpoch}_1.atlas_changeset',
        ),
      );
      await changesetFile.writeAsBytes(remoteChangeset.encodeCompressed());

      // 3. Execute local sync
      final engine = FolderSyncEngine(
        database: database,
        syncDao: database.syncDao,
        deviceIdentity: deviceIdentity,
        casDirectory: casDir,
        overrideSyncDirectory: syncDir,
      );

      final result = await engine.sync();
      expect(result.success, isTrue);
      expect(result.recordsImported, greaterThanOrEqualTo(1));
      expect(result.blobsTransferred, 1);

      // Verify remote node was inserted locally
      final importedNode = await database.nodesDao.getNode(remoteNodeId);
      expect(importedNode, isNotNull);
      expect(importedNode!.title, 'Remote Laptop Note');
      expect(importedNode.contentHash, remoteBlobHash);

      // Verify remote blob was copied into local CAS
      final localCopiedBlob = File(
        p.join(casDir.path, remoteBlobHash.substring(0, 2), remoteBlobHash),
      );
      expect(localCopiedBlob.existsSync(), isTrue);
      expect(await localCopiedBlob.readAsBytes(), remoteBlobData);
    });

    test('FolderSyncEngine performs non-destructive conflict forking on concurrent edits within 5 minutes', () async {
      final t0 = DateTime.utc(2026, 11, 7, 12, 0);
      final tLocalEdit = DateTime.utc(2026, 11, 7, 12, 2); // 2 minutes later
      final tRemoteEdit = DateTime.utc(
        2026,
        11,
        7,
        12,
        3,
      ); // 3 minutes later (within 5 minutes!)
      const wsId = 'ws-conflict-test';
      const sharedNodeId = 'node-concurrent-edit';
      const remoteDeviceId = 'client-ipad-pro';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Conflict WS',
              createdAt: t0,
              updatedAt: t0,
            ),
          );

      // Local version
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: sharedNodeId,
          workspaceId: wsId,
          type: 'document',
          title: 'Project Roadmap',
          contentHash: const Value('hash_local_version'),
          createdAt: t0,
          updatedAt: tLocalEdit,
          clientModifiedAt: Value(tLocalEdit),
          modifiedDeviceId: const Value('local-workstation'),
          syncVersion: const Value(1),
        ),
      );

      // Remote incoming changeset for the same node edited concurrently at 12:03 with different content
      final remoteChangeset = AtlasChangeset(
        deviceId: remoteDeviceId,
        sequence: 1,
        timestamp: tRemoteEdit,
        nodes: [
          {
            'id': sharedNodeId,
            'workspaceId': wsId,
            'type': 'document',
            'title': 'Project Roadmap (iPad Edits)',
            'contentHash': 'hash_remote_version',
            'sortOrder': 0,
            'isFavorite': false,
            'isPinned': false,
            'isArchived': false,
            'isDeleted': false,
            'metadataJson': '{}',
            'createdAt': t0.toIso8601String(),
            'updatedAt': tRemoteEdit.toIso8601String(),
            'clientModifiedAt': tRemoteEdit.toIso8601String(),
            'modifiedDeviceId': remoteDeviceId,
            'syncVersion': 2,
          },
        ],
      );

      final remoteChangesDir = Directory(
        p.join(syncDir.path, 'clients', remoteDeviceId, 'changes'),
      );
      await remoteChangesDir.create(recursive: true);
      final changesetFile = File(
        p.join(
          remoteChangesDir.path,
          '${tRemoteEdit.millisecondsSinceEpoch}_1.atlas_changeset',
        ),
      );
      await changesetFile.writeAsBytes(remoteChangeset.encodeCompressed());

      final engine = FolderSyncEngine(
        database: database,
        syncDao: database.syncDao,
        deviceIdentity: deviceIdentity,
        casDirectory: casDir,
        overrideSyncDirectory: syncDir,
      );

      final result = await engine.sync();
      expect(result.success, isTrue);

      // Verify all nodes in workspace - there should now be TWO nodes!
      final allNodes = await database.nodesDao.getAllNodes(wsId);
      expect(allNodes.length, 2);

      // One node has the primary ID and the later edit (12:03)
      final primaryNode = (await database.nodesDao.getNode(sharedNodeId))!;
      expect(primaryNode.contentHash, 'hash_remote_version');

      // The other node is a non-destructive conflict fork!
      final forkedNode = allNodes.firstWhere((n) => n.id != sharedNodeId);
      expect(forkedNode.title, contains('(Sync Conflict'));
      expect(forkedNode.contentHash, 'hash_local_version');
    });
  });
}
