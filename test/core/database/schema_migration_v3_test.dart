import 'package:atlas/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema Migration v3 Tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test('fresh database initializes schema version with all tables', () async {
      expect(database.schemaVersion, greaterThanOrEqualTo(3));

      final now = DateTime.now();

      // Verify workspace insertion
      await database.into(database.workspaces).insert(
        WorkspacesCompanion.insert(
          id: 'ws-1',
          name: 'Workspace 1',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Verify node insertion with contentHash
      await database.into(database.nodes).insert(
        NodesCompanion.insert(
          id: 'node-1',
          workspaceId: 'ws-1',
          type: 'document',
          title: 'First Document',
          contentHash: const Value('cas-sha256-hash-123'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final insertedNode = await (database.select(database.nodes)
            ..where((tbl) => tbl.id.equals('node-1')))
          .getSingle();

      expect(insertedNode.title, 'First Document');
      expect(insertedNode.contentHash, 'cas-sha256-hash-123');

      // Verify node_links insertion
      await database.into(database.nodes).insert(
        NodesCompanion.insert(
          id: 'node-2',
          workspaceId: 'ws-1',
          type: 'document',
          title: 'Target Document',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.into(database.nodeLinks).insert(
        NodeLinksCompanion.insert(
          id: 'link-1',
          sourceNodeId: 'node-1',
          targetNodeId: 'node-2',
          linkText: const Value('Target Document'),
          createdAt: now,
        ),
      );

      final links = await database.select(database.nodeLinks).get();
      expect(links.length, 1);
      expect(links.first.sourceNodeId, 'node-1');
      expect(links.first.targetNodeId, 'node-2');
      expect(links.first.linkText, 'Target Document');

      // Verify tags insertion
      await database.into(database.tags).insert(
        TagsCompanion.insert(
          id: 'tag-1',
          workspaceId: 'ws-1',
          name: 'Important',
          createdAt: now,
        ),
      );

      await database.into(database.nodeTags).insert(
        NodeTagsCompanion.insert(
          nodeId: 'node-1',
          tagId: 'tag-1',
        ),
      );

      final nodeTags = await database.select(database.nodeTags).get();
      expect(nodeTags.length, 1);
      expect(nodeTags.first.nodeId, 'node-1');
      expect(nodeTags.first.tagId, 'tag-1');
    });

    test('LinksDao queries return expected backlinks and forward links', () async {
      final now = DateTime.now();

      await database.into(database.workspaces).insert(
        WorkspacesCompanion.insert(
          id: 'ws-test',
          name: 'Test WS',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.into(database.nodes).insert(
        NodesCompanion.insert(
          id: 'source-node',
          workspaceId: 'ws-test',
          type: 'document',
          title: 'Source Document',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.into(database.nodes).insert(
        NodesCompanion.insert(
          id: 'target-node',
          workspaceId: 'ws-test',
          type: 'notebook',
          title: 'Target Notebook',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.linksDao.insertLink(
        NodeLinksCompanion.insert(
          id: 'link-test-1',
          sourceNodeId: 'source-node',
          targetNodeId: 'target-node',
          linkText: const Value('Target Notebook'),
          createdAt: now,
        ),
      );

      final backlinks = await database.linksDao.getBacklinksForTarget('target-node');
      expect(backlinks.length, 1);
      expect(backlinks.first.sourceNodeId, 'source-node');
      expect(backlinks.first.sourceTitle, 'Source Document');
      expect(backlinks.first.sourceType, 'document');

      final forwardLinks = await database.linksDao.watchForwardLinksForSource('source-node').first;
      expect(forwardLinks.length, 1);
      expect(forwardLinks.first.targetNodeId, 'target-node');
      expect(forwardLinks.first.targetTitle, 'Target Notebook');
      expect(forwardLinks.first.targetType, 'notebook');
    });
  });
}
