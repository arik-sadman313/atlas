import 'package:atlas/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema Migration v7 & Sync Metadata Tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test('fresh database initializes schema version 7 with syncHistory and sync metadata columns', () async {
      expect(database.schemaVersion, greaterThanOrEqualTo(7));

      final now = DateTime.now().toUtc();
      const wsId = 'ws-v7-sync-test';

      // 1. Verify workspace insertion with sync metadata
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Workspace V7 Sync',
              createdAt: now,
              updatedAt: now,
              deletedAt: const Value(null),
              clientModifiedAt: Value(now),
              modifiedDeviceId: const Value('device-alpha'),
              syncVersion: const Value(1),
            ),
          );

      final ws = await (database.select(
        database.workspaces,
      )..where((tbl) => tbl.id.equals(wsId))).getSingle();
      expect(ws.id, wsId);
      expect(ws.deletedAt, isNull);
      expect(ws.modifiedDeviceId, 'device-alpha');
      expect(ws.syncVersion, 1);

      // 2. Verify node insertion with sync metadata
      const nodeId = 'node-sync-1';
      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: nodeId,
              workspaceId: wsId,
              type: 'document',
              title: 'Sync Note',
              createdAt: now,
              updatedAt: now,
              deletedAt: const Value(null),
              clientModifiedAt: Value(now),
              modifiedDeviceId: const Value('device-alpha'),
              syncVersion: const Value(1),
            ),
          );

      final node = await (database.select(
        database.nodes,
      )..where((tbl) => tbl.id.equals(nodeId))).getSingle();
      expect(node.title, 'Sync Note');
      expect(node.deletedAt, isNull);
      expect(node.modifiedDeviceId, 'device-alpha');
      expect(node.syncVersion, 1);
    });

    test(
      'soft deleted records are excluded from standard DAO queries',
      () async {
        final now = DateTime.now().toUtc();
        const wsId = 'ws-soft-delete-test';

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: wsId,
                name: 'Soft Delete Test Workspace',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Create two nodes
        const activeNodeId = 'node-active';
        const deletedNodeId = 'node-to-delete';

        await database.nodesDao.createNode(
          NodesCompanion.insert(
            id: activeNodeId,
            workspaceId: wsId,
            type: 'document',
            title: 'Active Document',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.nodesDao.createNode(
          NodesCompanion.insert(
            id: deletedNodeId,
            workspaceId: wsId,
            type: 'document',
            title: 'Doomed Document',
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Soft delete the second node
        await database.nodesDao.deleteNode(deletedNodeId);

        // Query active nodes
        final activeNodes = await database.nodesDao.getAllNodes(wsId);
        expect(activeNodes.length, 1);
        expect(activeNodes.first.id, activeNodeId);

        // Search active nodes
        final searchResults = await database.nodesDao.searchNodes(
          wsId,
          'Document',
        );
        expect(searchResults.length, 1);
        expect(searchResults.first.id, activeNodeId);

        // Node can still be queried by ID from database table directly
        final rawDeleted = await (database.select(
          database.nodes,
        )..where((tbl) => tbl.id.equals(deletedNodeId))).getSingle();
        expect(rawDeleted.isDeleted, isTrue);
        expect(rawDeleted.deletedAt, isNotNull);
      },
    );

    test('SyncDao records sync history progression', () async {
      const syncId = 'sync-run-001';

      // 1. Start sync
      await database.syncDao.startSync(id: syncId, syncType: 'folder_sync');

      var history = await database.syncDao.getRecentSyncHistory(limit: 5);
      expect(history.length, 1);
      expect(history.first.id, syncId);
      expect(history.first.status, 'in_progress');
      expect(history.first.syncCompletedAt, isNull);

      // 2. Complete sync
      await database.syncDao.completeSync(
        id: syncId,
        recordsExported: 12,
        recordsImported: 4,
        blobsTransferred: 6,
      );

      history = await database.syncDao.getRecentSyncHistory(limit: 5);
      expect(history.length, 1);
      expect(history.first.status, 'completed');
      expect(history.first.syncCompletedAt, isNotNull);
      expect(history.first.recordsExported, 12);
      expect(history.first.recordsImported, 4);
      expect(history.first.blobsTransferred, 6);
    });

    test('SyncDao upsertRemoteNode applies Last-Write-Wins (LWW)', () async {
      final t0 = DateTime.utc(2026, 11, 7, 10, 0);
      final tEarlier = DateTime.utc(2026, 11, 7, 9, 30);
      final tLater = DateTime.utc(2026, 11, 7, 10, 30);
      const wsId = 'ws-lww-test';
      const nodeId = 'node-lww-1';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'LWW Workspace',
              createdAt: t0,
              updatedAt: t0,
            ),
          );

      // 1. Insert initial local node at t0
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: nodeId,
          workspaceId: wsId,
          type: 'document',
          title: 'Initial Title',
          createdAt: t0,
          updatedAt: t0,
          clientModifiedAt: Value(t0),
          modifiedDeviceId: const Value('local-device'),
          syncVersion: const Value(1),
        ),
      );

      // 2. Attempt remote upsert with older timestamp (tEarlier) -> should reject
      final olderIncoming = NodeEntry(
        id: nodeId,
        workspaceId: wsId,
        type: 'document',
        title: 'Stale Older Title',
        sortOrder: 0,
        isFavorite: false,
        isPinned: false,
        isArchived: false,
        isDeleted: false,
        metadataJson: '{}',
        createdAt: tEarlier,
        updatedAt: tEarlier,
        clientModifiedAt: tEarlier,
        modifiedDeviceId: 'remote-device',
        syncVersion: 2,
      );

      final acceptedOlder = await database.syncDao.upsertRemoteNode(
        olderIncoming,
      );
      expect(acceptedOlder, isFalse);

      var current = (await database.nodesDao.getNode(nodeId))!;
      expect(current.title, 'Initial Title');

      // 3. Remote upsert with newer timestamp (tLater) -> should apply
      final newerIncoming = NodeEntry(
        id: nodeId,
        workspaceId: wsId,
        type: 'document',
        title: 'Updated Newer Title',
        sortOrder: 0,
        isFavorite: false,
        isPinned: false,
        isArchived: false,
        isDeleted: false,
        metadataJson: '{}',
        createdAt: t0,
        updatedAt: tLater,
        clientModifiedAt: tLater,
        modifiedDeviceId: 'remote-device',
        syncVersion: 2,
      );

      final acceptedNewer = await database.syncDao.upsertRemoteNode(
        newerIncoming,
      );
      expect(acceptedNewer, isTrue);

      current = (await database.nodesDao.getNode(nodeId))!;
      expect(current.title, 'Updated Newer Title');
      expect(current.modifiedDeviceId, 'remote-device');
    });
  });
}
