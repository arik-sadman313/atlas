import 'dart:io';

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/documents/data/services/document_content_service.dart';
import 'package:atlas/features/journal/data/repositories/journal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JournalRepository Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late CasStorageService blobStorage;
    late JournalRepository repo;
    const wsId = 'ws-journal-repo';

    setUp(() async {
      db = AppDatabase.inMemory();
      tempDir = Directory.systemTemp.createTempSync('atlas_journal_test_');
      blobStorage = CasStorageService(rootDirectory: tempDir);
      repo = JournalRepository(
        journalDao: db.journalDao,
        nodesDao: db.nodesDao,
        blobStorage: blobStorage,
      );

      await db.workspacesDao.createWorkspace(
        WorkspacesCompanion.insert(
          id: wsId,
          name: 'Journal Workspace',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getOrCreateTodayJournalNode auto-scaffolds document and reuses existing entry', () async {
      final now = DateTime(2026, 11, 6, 10, 0);

      // 1. Initial creation
      final nodeId1 = await repo.getOrCreateTodayJournalNode(
        wsId,
        today: now,
        mood: 'great',
      );
      expect(nodeId1, isNotEmpty);

      // Verify node created
      final node = await db.nodesDao.getNode(nodeId1);
      expect(node, isNotNull);
      expect(node!.type, 'document');
      expect(node.title, contains('Journal:'));
      expect(node.contentHash, isNotNull);

      // Verify CAS storage content contains sections
      final docContentService = DocumentContentService(
        blobStorage: blobStorage,
      );
      final doc = await docContentService.loadDocument(node.contentHash);
      final plainText = DocumentContentService.extractPlainText(doc);
      expect(plainText, contains('Daily Focus'));
      expect(plainText, contains('Key Wins'));
      expect(plainText, contains('Reflections'));

      // Verify journal entry record in database
      final entry = await repo.findEntryByDate(wsId, '2026-11-06');
      expect(entry, isNotNull);
      expect(entry!.nodeId, nodeId1);
      expect(entry.mood, 'great');

      // 2. Calling again for same day returns the SAME node id
      final nodeId2 = await repo.getOrCreateTodayJournalNode(
        wsId,
        today: now,
        mood: 'good',
      );
      expect(nodeId2, nodeId1);

      // Mood updated on the existing record
      final updatedEntry = await repo.findEntryByDate(wsId, '2026-11-06');
      expect(updatedEntry!.mood, 'good');

      // Nodes count is still 1
      final nodes = await db.nodesDao.watchNodesInWorkspace(wsId).first;
      expect(nodes.length, 1);
    });
  });
}
