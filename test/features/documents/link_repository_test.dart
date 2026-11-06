import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/documents/data/repositories/link_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinkRepository', () {
    late AppDatabase database;
    late LinkRepository repository;

    setUp(() {
      database = AppDatabase.inMemory();
      repository = LinkRepository(
        linksDao: database.linksDao,
        nodesDao: database.nodesDao,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('syncLinksFromText creates links for existing target nodes only', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-main',
              name: 'Main Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'doc-source',
              workspaceId: 'ws-main',
              type: 'document',
              title: 'Source Document',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'doc-target-1',
              workspaceId: 'ws-main',
              type: 'document',
              title: 'Meeting Notes',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'nb-target-2',
              workspaceId: 'ws-main',
              type: 'notebook',
              title: 'Sketches',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Text references doc-target-1, nb-target-2, and an uncreated note "Future Ideas", plus a self-reference "Source Document"
      const text =
          'Refer to [[Meeting Notes]] and [[Sketches|Handwritten Wireframes]]. Also check [[Future Ideas]] and [[Source Document]].';

      await repository.syncLinksFromText(
        sourceNodeId: 'doc-source',
        workspaceId: 'ws-main',
        text: text,
      );

      final links = await database.select(database.nodeLinks).get();
      // Should have 2 links: Meeting Notes and Sketches (no Future Ideas because it doesn't exist; no self-link to doc-source)
      expect(links.length, 2);

      final targetIds = links.map((l) => l.targetNodeId).toSet();
      expect(targetIds, {'doc-target-1', 'nb-target-2'});

      final sketchesLink = links.firstWhere(
        (l) => l.targetNodeId == 'nb-target-2',
      );
      expect(sketchesLink.linkText, 'Handwritten Wireframes');

      // Now verify backlinks query
      final backlinksToSketches = await repository.getBacklinks('nb-target-2');
      expect(backlinksToSketches.length, 1);
      expect(backlinksToSketches.first.sourceNodeId, 'doc-source');
      expect(backlinksToSketches.first.sourceTitle, 'Source Document');
      expect(backlinksToSketches.first.sourceType, 'document');
    });

    test('syncLinks replaces previous links with updated links', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-main',
              name: 'Main Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'doc-source',
              workspaceId: 'ws-main',
              type: 'document',
              title: 'Source Document',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'doc-target-1',
              workspaceId: 'ws-main',
              type: 'document',
              title: 'Topic A',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'doc-target-2',
              workspaceId: 'ws-main',
              type: 'document',
              title: 'Topic B',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // First sync references Topic A
      await repository.syncLinksFromText(
        sourceNodeId: 'doc-source',
        workspaceId: 'ws-main',
        text: 'Refer to [[Topic A]].',
      );
      var links = await database.select(database.nodeLinks).get();
      expect(links.length, 1);
      expect(links.first.targetNodeId, 'doc-target-1');

      // Second sync removes Topic A and references Topic B
      await repository.syncLinksFromText(
        sourceNodeId: 'doc-source',
        workspaceId: 'ws-main',
        text: 'Now refer to [[Topic B]].',
      );
      links = await database.select(database.nodeLinks).get();
      expect(links.length, 1);
      expect(links.first.targetNodeId, 'doc-target-2');
    });
  });
}
