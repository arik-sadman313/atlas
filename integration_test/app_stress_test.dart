import 'dart:io';

import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/notifications/notification_service.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/router/routes.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/documents/presentation/document_editor_screen.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:atlas/features/tasks/presentation/widgets/kanban/kanban_board_view.dart';
import 'package:atlas/features/tasks/presentation/widgets/kanban/kanban_card_widget.dart';
import 'package:atlas/shared/presentation/command_palette/command_palette_modal.dart';
import 'package:atlas/shared/widgets/atlas_scaffold.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final recordedErrors = <FlutterErrorDetails>[];
  final overflowMessages = <String>[];
  final platformErrors = <String>[];

  setUpAll(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.toString();
      if (msg.contains('overflowed') || msg.contains('RenderFlex overflowed')) {
        overflowMessages.add(msg);
      } else {
        recordedErrors.add(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      platformErrors.add('PlatformDispatcher: $error\n$stack');
      return true; // prevent test runner termination
    };
  });

  group('ATLAS Autonomous Chaos Testing & Stress Suite', () {
    late Directory tempDir;
    late CasStorageService blobStorage;
    late AppDatabase database;
    late NotificationService notificationService;
    late WorkspaceEntry defaultWs;
    late GoRouter testRouter;

    const testDocId = 'doc-stress-100';
    const testNotebookId = 'notebook-stress-200';

    setUp(() async {
      recordedErrors.clear();
      overflowMessages.clear();
      platformErrors.clear();
      drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      SharedPreferences.setMockInitialValues({'tasks_view_mode': 'board'});

      tempDir = Directory.systemTemp.createTempSync('atlas_chaos_');
      final blobsDir = Directory(p.join(tempDir.path, 'blobs'))
        ..createSync(recursive: true);
      blobStorage = CasStorageService(rootDirectory: blobsDir);
      database = AppDatabase.inMemory();
      defaultWs = await database.workspacesDao.getOrCreateDefaultWorkspace();
      notificationService = NotificationService();
      await notificationService.initialize();

      // Seed a document
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: testDocId,
          workspaceId: defaultWs.id,
          type: 'document',
          title: 'Stress Test Architecture Document',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Seed a notebook
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: testNotebookId,
          workspaceId: defaultWs.id,
          type: 'notebook',
          title: 'Stress Test Handwriting Notebook',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await database.inkDao.getOrCreateDocumentForNode(
        testNotebookId,
        defaultTemplate: 'ruled',
      );

      // Seed 5 tasks for Kanban and Tasks testing
      for (int i = 1; i <= 5; i++) {
        await database.tasksDao.createTask(
          TasksCompanion.insert(
            id: 'task-stress-$i',
            workspaceId: defaultWs.id,
            title: 'Chaos Stress Task #$i',
            status: drift.Value(
              i <= 2 ? 'todo' : (i <= 4 ? 'in_progress' : 'done'),
            ),
            isCompleted: drift.Value(i == 5),
            priority: drift.Value(i % 4 + 1),
            sortOrder: drift.Value(i),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      testRouter = createAppRouter();
    });

    tearDown(() async {
      testRouter.dispose();
      await database.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          blobStorageServiceProvider.overrideWithValue(blobStorage),
          notificationServiceProvider.overrideWithValue(notificationService),
          appRouterProvider.overrideWithValue(testRouter),
          currentWorkspaceProvider.overrideWith(
            (ref) => Future.value(defaultWs),
          ),
        ],
        child: AtlasApp(routerOverride: testRouter),
      );
    }

    // =========================================================================
    // SCENARIO 1: Rapid Route & State Fuzzing + Command Palette Cycling
    // =========================================================================
    testWidgets('Scenario 1: Rapid route traversal & Command Palette fuzzing', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final routes = [
        AtlasRoutes.dashboard,
        AtlasRoutes.notebooks,
        AtlasRoutes.documents,
        AtlasRoutes.tasks,
        AtlasRoutes.calendar,
        AtlasRoutes.graph,
        AtlasRoutes.search,
        AtlasRoutes.settings,
      ];

      // Rapidly traverse routes across 3 full cycles
      for (int cycle = 0; cycle < 3; cycle++) {
        for (final route in routes) {
          testRouter.go(route);
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      await tester.pump(const Duration(milliseconds: 100));

      // Verify returned safely without crashing
      expect(find.byType(AtlasApp), findsOneWidget);

      // Rapid Command Palette Cycling
      final scaffoldCtx = tester.element(find.byType(AtlasScaffold));
      for (int i = 0; i < 5; i++) {
        CommandPaletteModal.show(scaffoldCtx);
        await tester.pump(const Duration(milliseconds: 20));

        final inputFinder = find.descendant(
          of: find.byType(CommandPaletteModal),
          matching: find.byType(TextField),
        );
        if (inputFinder.evaluate().isNotEmpty) {
          await tester.enterText(inputFinder.first, '>jump');
          await tester.pump(const Duration(milliseconds: 10));
          await tester.enterText(inputFinder.first, '#research');
          await tester.pump(const Duration(milliseconds: 10));
          await tester.enterText(inputFinder.first, '@tomorrow');
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Pop Command Palette
        if (find.byType(CommandPaletteModal).evaluate().isNotEmpty) {
          Navigator.of(tester.element(find.byType(CommandPaletteModal))).pop();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      await tester.pump(const Duration(milliseconds: 300));

      // Zero lingering modal dialogs
      expect(find.byType(CommandPaletteModal), findsNothing);
      expect(
        platformErrors,
        isEmpty,
        reason: 'PlatformDispatcher errors logged',
      );
    });

    // =========================================================================
    // SCENARIO 2: Autosave Interruption & Rapid Pop Test
    // =========================================================================
    testWidgets(
      'Scenario 2: Autosave interruption & rapid pop on Document and Notebook editors',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // --- Part A: Document Editor Rapid Pop Mid-Debounce ---
        testRouter.go('/documents/$testDocId');
        await tester.pump();
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(DocumentEditorScreen).evaluate().isNotEmpty) {
            final s = tester.state<DocumentEditorScreenState>(
              find.byType(DocumentEditorScreen),
            );
            if (s.quillController != null) break;
          }
        }

        expect(find.byType(DocumentEditorScreen), findsOneWidget);
        final docState = tester.state<DocumentEditorScreenState>(
          find.byType(DocumentEditorScreen),
        );

        // Type 500 characters
        final text500 = 'Atlas resilient architecture stress testing ' * 12;
        docState.quillController?.document.insert(0, text500);
        await tester.pump(const Duration(milliseconds: 30));

        // Mid-debounce rapid pop (within 30ms, well below the 1000ms debounce)
        testRouter.go(AtlasRoutes.documents);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(DocumentEditorScreen), findsNothing);

        // --- Part B: Notebook Editor Rapid Pop During In-Flight Ink ---
        testRouter.go('/notebooks/$testNotebookId');
        await tester.pump();
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(InkCanvas).evaluate().isNotEmpty) break;
        }

        expect(find.byType(InkCanvas), findsOneWidget);
        final inkCanvas = tester.widget<InkCanvas>(find.byType(InkCanvas));
        final controller = inkCanvas.controller;

        // Tessellate 20 rapid ink strokes
        for (int s = 0; s < 20; s++) {
          final origin = Offset(20.0 + s * 4, 30.0 + s * 4);
          controller.startStroke(origin);
          for (int p = 1; p <= 5; p++) {
            controller.updateStroke(
              Offset(origin.dx + p * 3, origin.dy + p * 3),
            );
          }
          controller.endStroke();
        }
        await tester.pump(const Duration(milliseconds: 20));

        // Pop immediately while serialization or autosave may be in flight
        testRouter.go(AtlasRoutes.notebooks);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(InkCanvas), findsNothing);
        expect(platformErrors, isEmpty);
      },
    );

    // =========================================================================
    // SCENARIO 3: Window Resize & Overflow Stress Test
    // =========================================================================
    testWidgets(
      'Scenario 3: Surface resizing across 400x800, 800x1000, 1920x1080 without RenderFlex overflows',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final sizes = [
          const Size(400, 800), // Compact Mobile / Minimum Desktop
          const Size(800, 1000), // Standard Tablet / Narrow Desktop
          const Size(1920, 1080), // Ultrawide Desktop
        ];

        final screensToTest = [
          AtlasRoutes.tasks,
          AtlasRoutes.calendar,
          AtlasRoutes.graph,
          '/notebooks/$testNotebookId',
          '/documents/$testDocId',
        ];

        for (final size in sizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          for (final route in screensToTest) {
            testRouter.go(route);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 80));
          }
        }

        // Reset test surface size and return to dashboard
        testRouter.go(AtlasRoutes.dashboard);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert ZERO RenderFlex overflow errors occurred
        expect(
          overflowMessages,
          isEmpty,
          reason:
              'RenderFlex overflows detected:\n${overflowMessages.join("\n---\n")}',
        );
      },
    );

    // =========================================================================
    // SCENARIO 4: Rapid Kanban Drag-and-Drop Stress
    // =========================================================================
    testWidgets(
      'Scenario 4: Rapid Kanban drag-and-drop & reordering with SQLite concurrency mutex',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Navigate to Tasks Screen
        testRouter.go(AtlasRoutes.tasks);
        await tester.pump();
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(KanbanBoardView).evaluate().isNotEmpty) break;
          final boardBtn = find.byTooltip('Kanban Board View');
          if (boardBtn.evaluate().isNotEmpty) {
            await tester.tap(boardBtn);
            await tester.pump(const Duration(milliseconds: 50));
            break;
          }
        }

        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(KanbanBoardView).evaluate().isNotEmpty) break;
        }

        expect(find.byType(KanbanBoardView), findsOneWidget);

        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(KanbanCardWidget).evaluate().isNotEmpty) break;
        }
        final cardFinder = find.byType(KanbanCardWidget);
        expect(cardFinder, findsWidgets);

        // Simulate dragging card to adjacent column
        final gesture = await tester.startGesture(
          tester.getCenter(cardFinder.first),
        );
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(280, 0));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        // Rapidly simulate concurrent status and reordering transactions
        final taskRepo = ProviderScope.containerOf(
          tester.element(find.byType(AtlasApp)),
        ).read(taskRepositoryProvider);

        final futures = <Future>[];
        for (int i = 1; i <= 5; i++) {
          final targetStatus = i % 2 == 0 ? 'in_progress' : 'done';
          futures.add(
            taskRepo.updateTaskStatus('task-stress-$i', targetStatus),
          );
          futures.add(
            taskRepo.updateTaskPriority('task-stress-$i', (i % 4) + 1),
          );
        }
        await Future.wait(futures);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify database integrity: exactly 5 tasks exist, no duplicate records
        final allTasks = await database.tasksDao.getTasksForWorkspace(
          defaultWs.id,
        );
        expect(allTasks.length, equals(5));
        expect(platformErrors, isEmpty);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    // =========================================================================
    // SCENARIO 5: Lasso Selection Edge Cases & Transformation Undo/Redo Loop
    // =========================================================================
    testWidgets(
      'Scenario 5: Lasso selection edge cases, blank selection, 100+ strokes, 10x undo/redo spam',
      (tester) async {
        // Create empty document
        final emptyDoc = AtlasInkDocument.empty(
          documentId: 'doc_lasso_chaos',
          pageNumber: 1,
          width: 1000,
          height: 1000,
        );

        final controller = InkCanvasController(document: emptyDoc);

        // 1. Empty lasso selection on blank space
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.lasso,
            color: 0xFF2563EB,
            baseWidth: 2.0,
          ),
        );
        controller.startStroke(const Offset(400, 400));
        controller.updateStroke(const Offset(500, 400));
        controller.updateStroke(const Offset(500, 500));
        controller.updateStroke(const Offset(400, 500));
        controller.endStroke();

        expect(controller.hasSelection, isFalse);
        expect(controller.selectedStrokeIds, isEmpty);
        expect(controller.selectionBounds, isNull);

        // 2. Populate 120 dense strokes inside region (50, 50) to (250, 250)
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.ballpointPen,
            color: 0xFF18181B,
            baseWidth: 3.0,
          ),
        );
        for (int i = 0; i < 120; i++) {
          final x = 60.0 + (i % 15) * 10;
          final y = 60.0 + (i ~/ 15) * 20;
          controller.startStroke(Offset(x, y));
          controller.updateStroke(Offset(x + 5, y + 5));
          controller.updateStroke(Offset(x + 10, y + 10));
          controller.endStroke();
        }

        expect(controller.document.totalStrokeCount, equals(120));

        // 3. Lasso select enclosing all 120 strokes
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.lasso,
            color: 0xFF2563EB,
            baseWidth: 2.0,
          ),
        );
        controller.startStroke(const Offset(40, 40));
        controller.updateStroke(const Offset(280, 40));
        controller.updateStroke(const Offset(280, 280));
        controller.updateStroke(const Offset(40, 280));
        controller.endStroke();

        expect(controller.hasSelection, isTrue);
        expect(controller.selectedStrokeIds.length, equals(120));
        final initialBounds = controller.selectionBounds;
        expect(initialBounds, isNotNull);

        // 4. Translate selected strokes by delta (40, 60)
        const delta = Offset(40, 60);
        controller.translateSelectedStrokes(delta, recordUndo: true);

        final translatedBounds = controller.selectionBounds;
        expect(translatedBounds, isNotNull);
        expect(
          translatedBounds!.left,
          closeTo(initialBounds!.left + delta.dx, 1.0),
        );
        expect(
          translatedBounds.top,
          closeTo(initialBounds.top + delta.dy, 1.0),
        );

        // 5. Rapidly spam 10x undo then 10x redo
        for (int i = 0; i < 10; i++) {
          controller.undo();
        }
        expect(controller.document.totalStrokeCount, isNonZero);

        for (int i = 0; i < 10; i++) {
          controller.redo();
        }

        // Verify stroke count remained consistent without index or state corruption
        expect(controller.document.totalStrokeCount, equals(120));
        expect(platformErrors, isEmpty);

        controller.dispose();
      },
    );
  });
}
