import 'package:atlas/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkspacesDao', () {
    test('creates and retrieves default workspace', () async {
      final defaultWs = await db.workspacesDao.getOrCreateDefaultWorkspace();

      expect(defaultWs.id, equals('workspace-default-primary'));
      expect(defaultWs.name, equals('Personal Workspace'));

      final all = await db.workspacesDao.getAllWorkspaces();
      expect(all.length, equals(1));
      expect(all.first.id, equals(defaultWs.id));
    });

    test('creates and deletes custom workspace', () async {
      final now = DateTime.now();
      const wsId = 'custom-ws-1';

      await db.workspacesDao.createWorkspace(
        WorkspacesCompanion.insert(
          id: wsId,
          name: 'Research Lab',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final ws = await db.workspacesDao.getWorkspace(wsId);
      expect(ws, isNotNull);
      expect(ws!.name, equals('Research Lab'));

      // Soft delete
      await db.workspacesDao.deleteWorkspace(wsId);
      final active = await db.workspacesDao.getAllWorkspaces();
      expect(active.where((w) => w.id == wsId), isEmpty);
    });
  });

  group('NodesDao & Cascades', () {
    late String wsId;

    setUp(() async {
      final ws = await db.workspacesDao.getOrCreateDefaultWorkspace();
      wsId = ws.id;
    });

    test('creates, updates, and searches nodes', () async {
      final now = DateTime.now();
      const docId = 'doc-test-1';

      await db.nodesDao.createNode(
        NodesCompanion.insert(
          id: docId,
          workspaceId: wsId,
          type: 'document',
          title: 'Compiler Architecture Strategy',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final retrieved = await db.nodesDao.getNode(docId);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Compiler Architecture Strategy'));

      // Search matching
      final searchResults = await db.nodesDao.searchNodes(wsId, 'Compiler');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals(docId));

      // Search non-matching
      final noResults = await db.nodesDao.searchNodes(wsId, 'NonExistentXYZ');
      expect(noResults, isEmpty);

      // Favorite toggle
      await db.nodesDao.updateNode(
        retrieved.toCompanion(true).copyWith(isFavorite: const Value(true)),
      );

      final updated = await db.nodesDao.getNode(docId);
      expect(updated!.isFavorite, isTrue);
    });

    test('creates blocks for node and verifies cascade delete', () async {
      final now = DateTime.now();
      const docId = 'doc-cascade-test';
      const blockId = 'block-cascade-test';

      await db.nodesDao.createNode(
        NodesCompanion.insert(
          id: docId,
          workspaceId: wsId,
          type: 'document',
          title: 'Parent Document',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.nodesDao.createBlock(
        NodeBlocksCompanion.insert(
          id: blockId,
          nodeId: docId,
          type: 'paragraph',
          contentJson: const Value('{"text": "Sample cascade content"}'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Verify block exists
      final blocksBefore = await (db.select(
        db.nodeBlocks,
      )..where((b) => b.id.equals(blockId))).get();
      expect(blocksBefore.length, equals(1));

      // Hard delete parent node
      await db.nodesDao.deleteNode(docId, hardDelete: true);

      // Verify node deleted
      final nodeAfter = await db.nodesDao.getNode(docId);
      expect(nodeAfter, isNull);

      // Verify cascading delete of child block
      final blocksAfter = await (db.select(
        db.nodeBlocks,
      )..where((b) => b.id.equals(blockId))).get();
      expect(blocksAfter, isEmpty);
    });

    test('reactive stream emits updates when nodes change', () async {
      final stream = db.nodesDao.watchNodesInWorkspace(wsId);
      final expectation = expectLater(stream, emitsThrough(hasLength(1)));

      final now = DateTime.now();
      await db.nodesDao.createNode(
        NodesCompanion.insert(
          id: 'reactive-node-1',
          workspaceId: wsId,
          type: 'document',
          title: 'Reactive Title',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await expectation;
    });
  });
}
