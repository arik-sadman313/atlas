import 'dart:io';

import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/handwriting/data/repositories/ink_repository.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/presentation/screens/notebook_editor_screen.dart';
import 'package:atlas/features/handwriting/presentation/widgets/floating_tool_dock.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_page_view.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_tool_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencil_kit/pencil_kit.dart';

class FailingInkRepository extends InkRepository {
  FailingInkRepository({required super.inkDao, required super.blobStorage});

  @override
  Future<InkPageEntry> savePageDrawing({
    required InkPageEntry page,
    required AtlasInkDocument doc,
    Uint8List? rawPencilKitBytes,
    Uint8List? previewPngBytes,
  }) async {
    throw Exception('Simulated CAS disk failure');
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late CasStorageService storage;

  setUp(() async {
    db = AppDatabase.inMemory();
    final ws = await db.workspacesDao.getOrCreateDefaultWorkspace();
    tempDir = Directory.systemTemp.createTempSync('atlas_nav_test_');
    storage = CasStorageService(rootDirectory: tempDir);

    // Seed test notebook node
    await db.nodesDao.createNode(
      NodesCompanion.insert(
        id: 'nb_nav_test',
        workspaceId: ws.id,
        type: 'notebook',
        title: 'Platform Test Notebook',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestApp({List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        blobStorageServiceProvider.overrideWithValue(storage),
        ...overrides,
      ],
      child: const MaterialApp(
        home: NotebookEditorScreen(notebookId: 'nb_nav_test'),
      ),
    );
  }

  group('NotebookEditorScreen - Platform Canvas Selection', () {
    testWidgets(
      'Android platform mounts read-only InkPageView and omits InkCanvas and palette',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Android must mount InkPageView
          expect(find.byType(InkPageView), findsOneWidget);
          expect(find.text('Android Companion (Read-Only)'), findsOneWidget);

          // Android must NOT mount interactive drawing components
          expect(find.byType(InkCanvas), findsNothing);
          expect(find.byType(PencilKit), findsNothing);
          expect(
            find.byWidgetPredicate(
              (w) => w is FloatingToolDock || w is InkToolPalette,
            ),
            findsNothing,
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Linux desktop mounts interactive InkCanvas and InkToolPalette',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Linux must mount InkCanvas & tool palette
          expect(find.byType(InkCanvas), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (w) => w is FloatingToolDock || w is InkToolPalette,
            ),
            findsOneWidget,
          );

          // Linux must NOT mount read-only viewer or PencilKit
          expect(find.byType(InkPageView), findsNothing);
          expect(find.byType(PencilKit), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'iOS / iPadOS mounts native PencilKit widget and tool palette',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.mjstudio/flutter_pencil_kit/util'),
          (call) async {
            if (call.method == 'checkAvailable') return true;
            return null;
          },
        );

        try {
          await tester.pumpWidget(buildTestApp());
          await tester.pump();

          // iOS must mount native PencilKit widget
          expect(find.byType(PencilKit), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (w) => w is FloatingToolDock || w is InkToolPalette,
            ),
            findsOneWidget,
          );

          // iOS must NOT mount Linux InkCanvas or Android read-only InkPageView
          expect(find.byType(InkCanvas), findsNothing);
          expect(find.byType(InkPageView), findsNothing);
        } finally {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('plugins.mjstudio/flutter_pencil_kit/util'),
            null,
          );
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });

  group('NotebookEditorScreen - Autosave & Back-Navigation Guards', () {
    testWidgets(
      'Back navigation flushes pending changes safely without data loss',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Draw a stroke on Linux canvas
          final gesture = await tester.startGesture(const Offset(300, 300));
          await gesture.moveTo(const Offset(350, 350));
          await gesture.up();
          await tester.pump();

          // Unsaved status icon should be displayed
          expect(find.byIcon(Icons.pending_outlined), findsOneWidget);

          // Click the back button before the 1500ms debounce timer expires
          final backButton = find.byTooltip('Back to Notebooks');
          expect(backButton, findsOneWidget);

          await tester.runAsync(() async {
            await tester.tap(backButton);
            for (int i = 0; i < 50; i++) {
              await Future.delayed(const Duration(milliseconds: 20));
              final pages = await db.inkDao.getPagesForDocument(
                'inkdoc_nb_nav_test',
              );
              if (pages.isNotEmpty && pages.first.portableInkHash != null) {
                break;
              }
            }

            // Verify ink was saved into SQLite page entry
            final inkDao = db.inkDao;
            final pages = await inkDao.getPagesForDocument(
              'inkdoc_nb_nav_test',
            );
            expect(pages.isNotEmpty, isTrue);
            expect(pages.first.portableInkHash, isNotNull);

            // Verify blob exists in CAS
            final blobBytes = await storage.readBlob(
              pages.first.portableInkHash!,
            );
            expect(blobBytes.isNotEmpty, isTrue);
          });
          await tester.pump();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'Save failures preserve unsaved state, show SnackBar, and prevent route exit',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final failingRepo = FailingInkRepository(
            inkDao: db.inkDao,
            blobStorage: storage,
          );

          await tester.pumpWidget(
            buildTestApp(
              overrides: [inkRepositoryProvider.overrideWithValue(failingRepo)],
            ),
          );
          await tester.pumpAndSettle();

          // Draw a stroke
          final gesture = await tester.startGesture(const Offset(200, 200));
          await gesture.moveTo(const Offset(250, 250));
          await gesture.up();
          await tester.pump();

          expect(find.byIcon(Icons.pending_outlined), findsOneWidget);

          // Attempt to back navigate
          final backButton = find.byTooltip('Back to Notebooks');
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Screen should still be mounted (not popped!)
          expect(find.text('Platform Test Notebook'), findsOneWidget);

          // SnackBar with error message must be shown
          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.textContaining('Failed to save drawing'), findsOneWidget);
          expect(find.text('Retry'), findsOneWidget);

          // Unsaved changes icon must still be visible
          expect(find.byIcon(Icons.pending_outlined), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
