import 'dart:convert';

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/search/data/services/search_service.dart';
import 'package:atlas/features/search/domain/models/search_result_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_blob_storage_service.dart';

void main() {
  late AppDatabase db;
  late InMemoryBlobStorageService blobStorage;
  late SearchService searchService;
  const workspaceId = 'test-workspace-m7';

  setUp(() async {
    db = AppDatabase.inMemory();
    blobStorage = InMemoryBlobStorageService();
    searchService = SearchService(
      nodesDao: db.nodesDao,
      tasksDao: db.tasksDao,
      calendarDao: db.calendarDao,
      journalDao: db.journalDao,
      linksDao: db.linksDao,
      blobStorage: blobStorage,
    );

    final now = DateTime.now();

    // Create workspace
    await db.workspacesDao.createWorkspace(
      WorkspacesCompanion.insert(
        id: workspaceId,
        name: 'Workspace M7',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 1. Insert Document Node with CAS content
    final docContent = jsonEncode({
      'ops': [
        {'insert': 'Deep Dive into Distributed Systems and consensus.'},
      ],
    });
    final docBlobHash = await blobStorage.writeBlob(
      utf8.encode(docContent),
      mimeType: 'application/json',
    );
    await db.nodesDao.createNode(
      NodesCompanion.insert(
        id: 'doc-node-1',
        workspaceId: workspaceId,
        title: 'Distributed Systems Architecture',
        type: 'document',
        contentHash: Value(docBlobHash),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 2. Insert Notebook Node
    await db.nodesDao.createNode(
      NodesCompanion.insert(
        id: 'nb-node-1',
        workspaceId: workspaceId,
        title: 'Meeting Notes - Architecture Review',
        type: 'notebook',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 3. Insert Task with Project
    await db.tasksDao.createProject(
      ProjectsCompanion.insert(
        id: 'proj-1',
        workspaceId: workspaceId,
        name: 'Infrastructure V2',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.tasksDao.createTask(
      TasksCompanion.insert(
        id: 'task-1',
        workspaceId: workspaceId,
        title: 'Implement Raft consensus algorithm',
        description: const Value('Ensure leader election and log replication.'),
        projectId: const Value('proj-1'),
        priority: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 4. Insert Calendar Event
    await db.calendarDao.createEvent(
      CalendarEventsCompanion.insert(
        id: 'cal-1',
        workspaceId: workspaceId,
        title: 'Quarterly Planning Architecture Sync',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 1)),
        description: const Value('Roadmap discussion for backend scaling.'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 5. Insert Daily Journal Node + Entry
    final journalContent = jsonEncode({
      'ops': [
        {'insert': 'Today I refactored the search indexing and graph physics.'},
      ],
    });
    final journalBlobHash = await blobStorage.writeBlob(
      utf8.encode(journalContent),
      mimeType: 'application/json',
    );
    await db.nodesDao.createNode(
      NodesCompanion.insert(
        id: 'journal-node-1',
        workspaceId: workspaceId,
        title: 'Journal: 2026-11-07',
        type: 'document',
        contentHash: Value(journalBlobHash),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.journalDao.createJournalEntry(
      JournalEntriesCompanion.insert(
        id: 'journal-entry-1',
        workspaceId: workspaceId,
        nodeId: 'journal-node-1',
        journalDate: '2026-11-07',
        mood: const Value('focused'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 6. Insert Tag and associate with doc
    await db.linksDao.addTag(
      TagsCompanion.insert(
        id: 'tag-1',
        workspaceId: workspaceId,
        name: 'consensus-protocols',
        color: const Value(0xFFFFC107),
        createdAt: now,
      ),
    );
    await db.linksDao.tagNode('doc-node-1', 'tag-1');
  });

  tearDown(() async {
    await db.close();
  });

  group('SearchService multi-entity search', () {
    test(
      'returns matching items across documents, notebooks, tasks, and calendar',
      () async {
        final results = await searchService.search(
          workspaceId,
          'Architecture',
          filter: SearchFilter.all,
        );

        expect(results.length, greaterThanOrEqualTo(3));
        final types = results.map((r) => r.type).toSet();
        expect(types, contains(SearchEntityType.document));
        expect(types, contains(SearchEntityType.notebook));
        expect(types, contains(SearchEntityType.calendarEvent));

        // Results must be sorted in descending order of relevance score
        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
        }
      },
    );

    test('filters search results by entity type chip', () async {
      final docResults = await searchService.search(
        workspaceId,
        'Architecture',
        filter: SearchFilter.document,
      );
      expect(
        docResults.every((r) => r.type == SearchEntityType.document),
        isTrue,
      );
      expect(docResults.length, equals(1));
      expect(docResults.first.id, equals('doc-node-1'));

      final taskResults = await searchService.search(
        workspaceId,
        'Raft',
        filter: SearchFilter.task,
      );
      expect(taskResults.length, equals(1));
      expect(taskResults.first.type, equals(SearchEntityType.task));
      expect(taskResults.first.title, contains('Raft'));
      expect(taskResults.first.subtitle, contains('Infrastructure V2'));
    });

    test('searches tag names and journal reflections', () async {
      final tagResults = await searchService.search(
        workspaceId,
        'consensus-protocols',
        filter: SearchFilter.all,
      );
      expect(tagResults.any((r) => r.type == SearchEntityType.tag), isTrue);

      final journalResults = await searchService.search(
        workspaceId,
        'refactored',
        filter: SearchFilter.journal,
      );
      expect(journalResults.length, equals(1));
      expect(journalResults.first.type, equals(SearchEntityType.journal));
      expect(journalResults.first.snippet, contains('refactored'));
    });

    test('returns empty list for non-matching query', () async {
      final results = await searchService.search(
        workspaceId,
        'NonexistentUnrelatedKeyword12345',
        filter: SearchFilter.all,
      );
      expect(results, isEmpty);
    });
  });
}
