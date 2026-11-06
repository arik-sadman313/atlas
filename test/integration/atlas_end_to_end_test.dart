import 'dart:convert';
import 'dart:io';

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/database/daos/habits_dao.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/core/sync/device/device_identity_service.dart';
import 'package:atlas/core/sync/vault/vault_export_service.dart';
import 'package:atlas/core/sync/vault/vault_import_service.dart';
import 'package:atlas/features/documents/data/repositories/link_repository.dart';
import 'package:atlas/features/handwriting/data/serializers/ink_binary_serializer.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/journal/data/repositories/journal_repository.dart';
import 'package:atlas/features/search/data/services/search_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ATLAS Full End-to-End System Smoke Test (Milestone 9)', () {
    late Directory tempDir;
    late File dbFile;
    late Directory casDir;
    late AppDatabase database;
    late CasStorageService blobStorage;
    late DeviceIdentityService deviceIdentity;

    const workspaceId = 'ws-e2e-main';
    const docId = 'doc-typed-1';
    const docTitle = 'Field Research Notes';
    const docMarkdown =
        '# Expedition Strategy\n\nCross-reference geological data with [[Field Notebook]] before departure.';
    const notebookId = 'notebook-field-1';
    const notebookTitle = 'Field Notebook';
    const inkDocId = 'ink-doc-1';
    const taskId = 'task-e2e-high-1';
    const habitId = 'habit-e2e-1';

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('atlas_e2e_');
      dbFile = File(p.join(tempDir.path, 'atlas_primary.db'));
      casDir = Directory(p.join(tempDir.path, 'cas'));
      await casDir.create(recursive: true);

      database = AppDatabase(NativeDatabase(dbFile));
      blobStorage = CasStorageService(rootDirectory: casDir);
      deviceIdentity = DeviceIdentityService();
    });

    tearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Complete Lifecycle: Document, Ink Notebook, Backlinks, Tasks, Habit, Journal, Search, Vault Export & Restore', () async {
      final now = DateTime.now().toUtc();
      final todayLocal = DateTime.now();
      final todayDateStr = HabitsDao.formatDate(todayLocal);

      // =====================================================================
      // 1. Initialize Workspace
      // =====================================================================
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: workspaceId,
              name: 'Primary Atlas Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // =====================================================================
      // 2. Create Typed Document with Markdown and [[Field Notebook]]
      // =====================================================================
      final docBlobHash = await blobStorage.writeBlob(utf8.encode(docMarkdown));
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: docId,
          workspaceId: workspaceId,
          type: 'document',
          title: docTitle,
          contentHash: Value(docBlobHash),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final createdDoc = await database.nodesDao.getNode(docId);
      expect(createdDoc, isNotNull);
      expect(createdDoc!.title, equals(docTitle));

      // =====================================================================
      // 3. Create Handwritten Notebook titled "Field Notebook" with 2 Vector Pages
      // =====================================================================
      final page1Ink = AtlasInkDocument(
        documentId: 'page_1',
        pageNumber: 1,
        layers: [
          InkLayer(
            id: 'l1',
            name: 'Main Ink',
            strokes: [
              InkStroke(
                id: 'stroke_1',
                tool: InkToolType.ballpointPen,
                color: 0xFF18181B,
                baseWidth: 3.0,
                points: const [
                  InkPoint(x: 100, y: 150, pressure: 0.5, timeOffsetMs: 0),
                  InkPoint(x: 200, y: 250, pressure: 0.7, timeOffsetMs: 20),
                ],
              ),
            ],
          ),
        ],
      );
      final page1Bytes = InkBinarySerializer.serialize(page1Ink);
      final page1Hash = await blobStorage.writeBlob(page1Bytes);

      final page2Ink = AtlasInkDocument(
        documentId: 'page_2',
        pageNumber: 2,
        layers: [
          InkLayer(
            id: 'l2',
            name: 'Highlighters',
            blendMode: 'multiply',
            strokes: [
              InkStroke(
                id: 'stroke_2',
                tool: InkToolType.highlighter,
                color: 0x66F59E0B,
                baseWidth: 15.0,
                opacity: 0.4,
                blendMode: 'multiply',
                points: const [
                  InkPoint(x: 50, y: 300, pressure: 0.5, timeOffsetMs: 0),
                  InkPoint(x: 400, y: 300, pressure: 0.5, timeOffsetMs: 30),
                ],
              ),
            ],
          ),
        ],
      );
      final page2Bytes = InkBinarySerializer.serialize(page2Ink);
      final page2Hash = await blobStorage.writeBlob(page2Bytes);

      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: notebookId,
          workspaceId: workspaceId,
          type: 'notebook',
          title: notebookTitle,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.inkDao.createDocument(
        InkDocumentsCompanion.insert(
          id: inkDocId,
          nodeId: notebookId,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.inkDao.createPage(
        InkPagesCompanion.insert(
          id: 'page-entry-1',
          documentId: inkDocId,
          pageNumber: 1,
          portableInkHash: Value(page1Hash),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.inkDao.createPage(
        InkPagesCompanion.insert(
          id: 'page-entry-2',
          documentId: inkDocId,
          pageNumber: 2,
          portableInkHash: Value(page2Hash),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final notebookPages = await database.inkDao.getPagesForDocument(inkDocId);
      expect(notebookPages.length, equals(2));

      // =====================================================================
      // 4. Verify Bidirectional Backlink in Both Nodes
      // =====================================================================
      final linkRepo = LinkRepository(
        linksDao: database.linksDao,
        nodesDao: database.nodesDao,
      );
      await linkRepo.syncLinksFromText(
        sourceNodeId: docId,
        workspaceId: workspaceId,
        text: docMarkdown,
      );

      // Forward link from typed document
      final forwardLinks = await linkRepo.watchForwardLinks(docId).first;
      expect(forwardLinks.length, equals(1));
      expect(forwardLinks.first.targetNodeId, equals(notebookId));

      // Backlink on Field Notebook
      final backlinks = await linkRepo.getBacklinks(notebookId);
      expect(backlinks.length, equals(1));
      expect(backlinks.first.sourceNodeId, equals(docId));
      expect(backlinks.first.sourceTitle, equals(docTitle));

      // =====================================================================
      // 5. Create High-Priority Task Linked to "Field Notebook" Due Today
      // =====================================================================
      final todayDate = DateTime.utc(
        todayLocal.year,
        todayLocal.month,
        todayLocal.day,
      );
      await database.tasksDao.createTask(
        TasksCompanion.insert(
          id: taskId,
          workspaceId: workspaceId,
          title: 'Review Field Notebook vector telemetry',
          priority: const Value(3), // Priority.high
          nodeId: const Value(notebookId),
          dueDate: Value(todayDate),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final createdTask = await database.tasksDao.getTask(taskId);
      expect(createdTask, isNotNull);
      expect(createdTask!.priority, equals(3));
      expect(createdTask.nodeId, equals(notebookId));
      expect(createdTask.dueDate?.year, equals(todayDate.year));
      expect(createdTask.dueDate?.month, equals(todayDate.month));
      expect(createdTask.dueDate?.day, equals(todayDate.day));

      // =====================================================================
      // 6. Complete Today's Habit Check-In
      // =====================================================================
      await database.habitsDao.createHabit(
        HabitsCompanion.insert(
          id: habitId,
          workspaceId: workspaceId,
          title: 'Deep Inking Practice',
          frequency: const Value('daily'),
          colorHex: const Value('#10B981'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final toggledState = await database.habitsDao.toggleHabit(
        habitId,
        todayDateStr,
      );
      expect(toggledState, isTrue);

      final habitProgress = await database.habitsDao.getHabitWithProgress(
        habitId,
      );
      expect(habitProgress, isNotNull);
      expect(habitProgress!.isCompletedToday, isTrue);

      // =====================================================================
      // 7. Scaffold Today's Daily Journal Entry & Verify Linked Task Presence
      // =====================================================================
      final journalRepo = JournalRepository(
        journalDao: database.journalDao,
        nodesDao: database.nodesDao,
        blobStorage: blobStorage,
      );

      final journalNodeId = await journalRepo.getOrCreateTodayJournalNode(
        workspaceId,
        today: todayLocal,
        mood: 'focused',
      );
      expect(journalNodeId, isNotEmpty);

      final journalEntry = await database.journalDao.findEntryByNodeId(
        journalNodeId,
      );
      expect(journalEntry, isNotNull);
      expect(journalEntry!.journalDate, equals(todayDateStr));
      expect(journalEntry.mood, equals('focused'));

      // Verify task linked to the notebook is present in workspace tasks
      final allTasks = await database.tasksDao.getTasksForWorkspace(
        workspaceId,
      );
      final notebookLinkedTasks = allTasks
          .where((t) => t.nodeId == notebookId)
          .toList();
      expect(notebookLinkedTasks.length, equals(1));
      expect(notebookLinkedTasks.first.id, equals(taskId));

      // =====================================================================
      // 8. Run Global Search Querying Document Title & Verify Rank Score
      // =====================================================================
      final searchService = SearchService(
        nodesDao: database.nodesDao,
        tasksDao: database.tasksDao,
        calendarDao: database.calendarDao,
        journalDao: database.journalDao,
        linksDao: database.linksDao,
        blobStorage: blobStorage,
      );

      final searchResults = await searchService.search(
        workspaceId,
        'Field Research Notes',
      );
      expect(searchResults, isNotEmpty);
      final topResult = searchResults.first;
      expect(topResult.title, equals(docTitle));
      expect(topResult.score, greaterThan(0.0));

      // =====================================================================
      // 9. Execute Full Vault Export (.atlas_vault) & Verify Manifest Checksums
      // =====================================================================
      final exportService = VaultExportService(
        database: database,
        syncDao: database.syncDao,
        nodesDao: database.nodesDao,
        deviceIdentity: deviceIdentity,
        databaseFile: dbFile,
        casDirectory: casDir,
      );

      final exportFile = File(p.join(tempDir.path, 'e2e_export.atlas_vault'));
      final exportedVault = await exportService.exportVault(
        destinationFile: exportFile,
        workspaceId: workspaceId,
      );
      expect(exportedVault.existsSync(), isTrue);
      expect(exportedVault.lengthSync(), greaterThan(100));

      final importService = VaultImportService(
        database: database,
        syncDao: database.syncDao,
        databaseFile: dbFile,
        casDirectory: casDir,
      );

      final manifest = await importService.inspectVault(exportedVault);
      expect(manifest.formatVersion, equals('1.0'));
      expect(manifest.databaseChecksum, isNotEmpty);
      // Blobs: doc markdown, 2 ink pages, plus journal starter delta
      expect(manifest.blobs.length, greaterThanOrEqualTo(3));
      expect(
        manifest.totalNodes,
        greaterThanOrEqualTo(3),
      ); // doc, notebook, journal

      // =====================================================================
      // 10. Execute Vault Import & Verify Zero Data Loss
      // =====================================================================
      final restoreDir = await Directory.systemTemp.createTemp(
        'atlas_e2e_restore_',
      );
      final restoreDbFile = File(p.join(restoreDir.path, 'atlas_restored.db'));
      final restoreCasDir = Directory(p.join(restoreDir.path, 'cas'));
      await restoreCasDir.create(recursive: true);

      final restoreDb = AppDatabase(NativeDatabase(restoreDbFile));
      final restoreImportService = VaultImportService(
        database: restoreDb,
        syncDao: restoreDb.syncDao,
        databaseFile: restoreDbFile,
        casDirectory: restoreCasDir,
      );

      final restoreResult = await restoreImportService.restoreVault(
        exportedVault,
      );
      expect(restoreResult.restoredBlobsCount, equals(manifest.blobs.length));
      expect(restoreResult.restoredRecordsCount, equals(manifest.totalNodes));

      // Query restored database to prove zero data loss
      final restoredNodes = await restoreDb.nodesDao.getAllNodes(workspaceId);
      expect(
        restoredNodes.any((n) => n.id == docId && n.title == docTitle),
        isTrue,
      );
      expect(
        restoredNodes.any(
          (n) => n.id == notebookId && n.title == notebookTitle,
        ),
        isTrue,
      );
      expect(restoredNodes.any((n) => n.id == journalNodeId), isTrue);

      final restoredPages = await restoreDb.inkDao.getPagesForDocument(
        inkDocId,
      );
      expect(restoredPages.length, equals(2));

      final restoredTasks = await restoreDb.tasksDao.getTasksForWorkspace(
        workspaceId,
      );
      expect(
        restoredTasks.any((t) => t.id == taskId && t.priority == 3),
        isTrue,
      );

      final restoredHabitProgress = await restoreDb.habitsDao
          .getHabitWithProgress(habitId);
      expect(restoredHabitProgress, isNotNull);
      expect(restoredHabitProgress!.isCompletedToday, isTrue);

      // Verify CAS blobs are intact and deserializable
      final restoredBlobStorage = CasStorageService(
        rootDirectory: restoreCasDir,
      );
      final restoredDocBytes = await restoredBlobStorage.readBlob(docBlobHash);
      expect(utf8.decode(restoredDocBytes), equals(docMarkdown));

      final restoredInkBytes = await restoredBlobStorage.readBlob(page1Hash);
      final restoredInkDoc = InkBinarySerializer.deserialize(restoredInkBytes);
      expect(restoredInkDoc.documentId, equals('page_1'));
      expect(restoredInkDoc.totalStrokeCount, equals(1));
      expect(restoredInkDoc.allStrokes.first.points.length, equals(2));

      await restoreDb.close();
      if (restoreDir.existsSync()) {
        await restoreDir.delete(recursive: true);
      }
    });
  });
}
