import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/handwriting/domain/math/stroke_tessellator.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/widgets/floating_tool_dock.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:atlas/features/handwriting/presentation/widgets/notebook_page_grid_dialog.dart';
import 'package:atlas/shared/widgets/atlas_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note-Taking Optimization Tests', () {
    test('addTextElement and updateTextElement allow full re-editing of text boxes', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_text_edit',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: doc);

      // Create text element
      controller.addTextElement(
        const Offset(100, 150),
        'Initial Concept Note',
        fontSize: 18.0,
      );

      expect(controller.document.totalStrokeCount, equals(1));
      final stroke = controller.document.allStrokes.first;
      expect(stroke.text, equals('Initial Concept Note'));
      expect(stroke.fontSize, equals(18.0));
      expect(stroke.shapeType, equals('text'));
      // Bounding box must be non-zero
      expect(stroke.bounds, isNotNull);
      expect(stroke.bounds!.width, greaterThan(50));
      expect(stroke.bounds!.height, greaterThan(15));

      // Re-edit text element
      controller.updateTextElement(
        stroke.id,
        'Updated Architectural Diagram Notes',
        fontSize: 24.0,
        textAlign: 'center',
        color: 0xFF2563EB,
      );

      final updated = controller.getStrokeById(stroke.id);
      expect(updated, isNotNull);
      expect(updated!.text, equals('Updated Architectural Diagram Notes'));
      expect(updated.fontSize, equals(24.0));
      expect(updated.textAlign, equals('center'));
      expect(updated.color, equals(0xFF2563EB));
      expect(updated.bounds!.width, greaterThan(100));

      // Undo reverts edit
      controller.undo();
      final reverted = controller.getStrokeById(stroke.id);
      expect(reverted!.text, equals('Initial Concept Note'));
      expect(reverted.fontSize, equals(18.0));

      // Redo restores edit
      controller.redo();
      final redone = controller.getStrokeById(stroke.id);
      expect(redone!.text, equals('Updated Architectural Diagram Notes'));
      expect(redone.fontSize, equals(24.0));
    });

    test('addStickyNote and updateStickyNote allow full re-editing of sticky notes', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_sticky_edit',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: doc);

      controller.addStickyNote(
        const Offset(200, 200),
        'Action item: Review PR',
        bgColor: 0xFFFEF3C7,
      );

      expect(controller.document.totalStrokeCount, equals(1));
      final note = controller.document.allStrokes.first;
      expect(note.text, equals('Action item: Review PR'));
      expect(note.shapeType, equals('stickyNote'));
      expect(note.fillColor, equals(0xFFFEF3C7));

      // Re-edit sticky note
      controller.updateStickyNote(
        note.id,
        'Done: PR Reviewed and Merged!',
        bgColor: 0xFFD1FAE5, // Mint Green
        fontSize: 20.0,
      );

      final updatedNote = controller.getStrokeById(note.id);
      expect(updatedNote, isNotNull);
      expect(updatedNote!.text, equals('Done: PR Reviewed and Merged!'));
      expect(updatedNote.fillColor, equals(0xFFD1FAE5));
      expect(updatedNote.fontSize, equals(20.0));

      // Undo reverts note edit
      controller.undo();
      expect(
        controller.getStrokeById(note.id)!.text,
        equals('Action item: Review PR'),
      );
      expect(controller.getStrokeById(note.id)!.fillColor, equals(0xFFFEF3C7));
    });

    test(
      'StrokeTessellator preserves and scales bounds for text and sticky notes',
      () {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_tess_scale',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(document: doc);

        controller.addTextElement(
          const Offset(100, 100),
          'Scale Test Text',
          fontSize: 20.0,
        );

        final originalStroke = controller.document.allStrokes.first;
        final originalBounds = originalStroke.bounds!;

        // Scale 2x around origin
        final scaled = StrokeTessellator.transformStroke(
          originalStroke,
          scaleX: 2.0,
          scaleY: 2.0,
          delta: const Offset(50.0, 50.0),
          origin: const Offset(100, 100),
        );

        // Bounds width and height should scale by 2x without collapsing
        expect(scaled.bounds, isNotNull);
        expect(scaled.bounds!.width, closeTo(originalBounds.width * 2.0, 1.0));
        expect(
          scaled.bounds!.height,
          closeTo(originalBounds.height * 2.0, 1.0),
        );
        expect(scaled.fontSize, closeTo(originalStroke.fontSize! * 2.0, 0.1));
      },
    );

    testWidgets(
      'FloatingToolDock minimizes into distraction-free pill and expands back',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_dock_collapse',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(document: doc);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(children: [FloatingToolDock(controller: controller)]),
            ),
          ),
        );

        // Initially expanded: minimize button is present
        final minimizeBtn = find.byTooltip('Minimize Dock (Distraction-Free)');
        expect(minimizeBtn, findsOneWidget);

        // Tap minimize
        await tester.tap(minimizeBtn);
        await tester.pumpAndSettle();

        // In collapsed mode: expand button is present
        final expandBtn = find.byTooltip('Expand Dock');
        expect(expandBtn, findsOneWidget);
        expect(
          find.byTooltip('Minimize Dock (Distraction-Free)'),
          findsNothing,
        );

        // Tap expand
        await tester.tap(expandBtn);
        await tester.pumpAndSettle();

        // Back to expanded mode
        expect(
          find.byTooltip('Minimize Dock (Distraction-Free)'),
          findsOneWidget,
        );
        expect(find.byTooltip('Expand Dock'), findsNothing);
      },
    );

    testWidgets(
      'SelectionOverlayWidget shows Edit Text/Note button when text is selected',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_sel_edit_btn',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(document: doc);

        controller.addTextElement(const Offset(150, 150), 'Editable Element');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: InkCanvas(
                  controller: controller,
                  width: 800,
                  height: 600,
                ),
              ),
            ),
          ),
        );

        // Element was automatically selected on creation
        expect(controller.hasSelection, isTrue);

        // Verify "Edit Text" action button is rendered in the action bar
        expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
      },
    );

    test('Erase Highlighter Only preserves regular ink and only erases highlighter', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_erase_hl',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: doc);

      // Add regular pen stroke at (100, 100)
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.ballpointPen,
          color: 0xFF000000,
          baseWidth: 2.0,
        ),
      );
      controller.startStroke(const Offset(100, 100), pressure: 0.5);
      controller.updateStroke(const Offset(120, 100), pressure: 0.5);
      controller.endStroke();

      // Add highlighter stroke at (200, 100)
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.highlighter,
          color: 0xFFFFFF00,
          baseWidth: 20.0,
          opacity: 0.4,
        ),
      );
      controller.startStroke(const Offset(200, 100), pressure: 0.5);
      controller.updateStroke(const Offset(220, 100), pressure: 0.5);
      controller.endStroke();

      expect(controller.document.totalStrokeCount, equals(2));

      // Enable Erase Highlighter Only
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.vectorEraser,
          color: 0x00000000,
          baseWidth: 22.0,
        ),
      );
      controller.eraseHighlighterOnly = true;

      // Try erasing regular pen stroke at (110, 100)
      controller.eraseAt(const Offset(110, 100), 15.0);
      expect(
        controller.document.totalStrokeCount,
        equals(2),
      ); // Pen stroke preserved!

      // Erase highlighter stroke at (210, 100)
      controller.eraseAt(const Offset(210, 100), 15.0);
      expect(
        controller.document.totalStrokeCount,
        equals(1),
      ); // Highlighter erased!

      // Turn off Erase Highlighter Only and erase pen stroke
      controller.eraseHighlighterOnly = false;
      controller.eraseAt(const Offset(110, 100), 15.0);
      expect(
        controller.document.totalStrokeCount,
        equals(0),
      ); // Pen stroke erased!
    });

    test('Auto-Deselect Eraser returns to previous writing tool upon stroke completion', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_auto_deselect',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: doc);

      // User was using pencil
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.pencil,
          color: 0xFF333333,
          baseWidth: 1.5,
        ),
      );
      expect(controller.activeTool.type, equals(InkToolType.pencil));

      // Switch to eraser and enable auto-deselect
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.vectorEraser,
          color: 0x00000000,
          baseWidth: 22.0,
        ),
      );
      controller.autoDeselectEraser = true;
      expect(controller.activeTool.type, equals(InkToolType.vectorEraser));

      // Erase gesture
      controller.startStroke(const Offset(50, 50), pressure: 0.5);
      controller.updateStroke(const Offset(60, 50), pressure: 0.5);
      controller.endStroke();

      // Tool should automatically revert back to pencil
      expect(controller.activeTool.type, equals(InkToolType.pencil));
    });

    test('Eraser perpendicular segment distance detects fast strokes between sampled points', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_segment_erase',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: doc);

      // Create a fast stroke with only two distant points: (100, 100) and (300, 100)
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.ballpointPen,
          color: 0xFF000000,
          baseWidth: 2.0,
        ),
      );
      controller.startStroke(const Offset(100, 100), pressure: 0.5);
      controller.updateStroke(const Offset(300, 100), pressure: 0.5);
      controller.endStroke();

      expect(controller.document.totalStrokeCount, equals(1));

      // Erase at (200, 100) which has no discrete point, using 10px radius
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.vectorEraser,
          color: 0x00000000,
          baseWidth: 22.0,
        ),
      );
      controller.eraseAt(const Offset(200, 100), 10.0);

      // Segment projection should catch it and erase
      expect(controller.document.totalStrokeCount, equals(0));
    });

    test('Lasso filters selectively include or exclude handwriting, text, notes, and shapes', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_lasso_filters',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: doc);

      // 1. Handwriting stroke at (150, 150)
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.ballpointPen,
          color: 0xFF000000,
          baseWidth: 2.0,
        ),
      );
      controller.startStroke(const Offset(140, 150), pressure: 0.5);
      controller.updateStroke(const Offset(160, 150), pressure: 0.5);
      controller.endStroke();

      // 2. Text element at (200, 200)
      controller.addTextElement(const Offset(200, 200), 'Lasso Filter Text');

      // Clear selection from text addition
      controller.clearSelection();

      // Disable text selection in lasso
      controller.lassoText = false;
      controller.lassoHandwriting = true;

      // Draw lasso encircling both elements (bounding box roughly 100..300, 100..300)
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.lasso,
          color: 0xFF2563EB,
          baseWidth: 1.0,
        ),
      );
      controller.startStroke(const Offset(100, 100), pressure: 0.5);
      controller.updateStroke(const Offset(350, 100), pressure: 0.5);
      controller.updateStroke(const Offset(350, 350), pressure: 0.5);
      controller.updateStroke(const Offset(100, 350), pressure: 0.5);
      controller.updateStroke(const Offset(100, 100), pressure: 0.5);
      controller.endStroke();

      // Only handwriting should be selected; text element is excluded by filter
      expect(controller.hasSelection, isTrue);
      expect(controller.selectedStrokes.length, equals(1));
      expect(controller.selectedStrokes.first.shapeType, isNull); // pen stroke
    });

    test('SidebarExpandedNotifier toggles and sets state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sidebarExpandedProvider), isTrue);

      container.read(sidebarExpandedProvider.notifier).state = false;
      expect(container.read(sidebarExpandedProvider), isFalse);

      container.read(sidebarExpandedProvider.notifier).toggle();
      expect(container.read(sidebarExpandedProvider), isTrue);

      container.read(sidebarExpandedProvider.notifier).setExpanded(false);
      expect(container.read(sidebarExpandedProvider), isFalse);
    });

    testWidgets(
      'NotebookPageGridDialog renders pages, active badge, and triggers page selection',
      (tester) async {
        final now = DateTime.now();
        final pages = [
          InkPageEntry(
            id: 'page_1',
            documentId: 'doc_pages',
            pageNumber: 1,
            width: 800.0,
            height: 1000.0,
            templateType: 'ruled',
            templateSpacing: 28.35,
            backgroundColor: 0xFFFFFFFF,
            createdAt: now,
            updatedAt: now,
            clientModifiedAt: now,
            modifiedDeviceId: 'device-1',
            syncVersion: 1,
          ),
          InkPageEntry(
            id: 'page_2',
            documentId: 'doc_pages',
            pageNumber: 2,
            width: 800.0,
            height: 1000.0,
            templateType: 'cornell',
            templateSpacing: 28.35,
            backgroundColor: 0xFFFFFFFF,
            createdAt: now,
            updatedAt: now,
            clientModifiedAt: now,
            modifiedDeviceId: 'device-1',
            syncVersion: 1,
          ),
        ];

        int? selectedPageIndex;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: NotebookPageGridDialog(
                  pages: pages,
                  currentPageIndex: 0,
                  onPageSelected: (index) => selectedPageIndex = index,
                  onAddPage: () {},
                  onInsertPageBelow: (_) {},
                  onDuplicatePage: (_) {},
                  onDeletePage: (_) {},
                  onMovePage: (from, to) {},
                  onChangeTemplate: (idx, template) {},
                ),
              ),
            ),
          ),
        );

        // Verify Header
        expect(find.textContaining('Page Overview'), findsOneWidget);

        // Verify Page Number indicators & templates
        expect(find.text('1'), findsWidgets);
        expect(find.text('2'), findsWidgets);
        expect(find.text('Ruled Paper'), findsWidgets);
        expect(find.text('Cornell Notes'), findsWidgets);

        // Verify Add Page filled button exists
        final addBtn = find.widgetWithText(FilledButton, 'Add Page');
        expect(addBtn, findsOneWidget);

        // Tap on Page 2 card (Cornell Notes)
        await tester.tap(find.text('Cornell Notes').first);
        await tester.pumpAndSettle();

        expect(selectedPageIndex, equals(1));
      },
    );

    testWidgets(
      'NotebookPageGridDialog triggers onAddPage when Add Page button is tapped',
      (tester) async {
        final now = DateTime.now();
        final pages = [
          InkPageEntry(
            id: 'page_1',
            documentId: 'doc_pages',
            pageNumber: 1,
            width: 800.0,
            height: 1000.0,
            templateType: 'ruled',
            templateSpacing: 28.35,
            backgroundColor: 0xFFFFFFFF,
            createdAt: now,
            updatedAt: now,
            clientModifiedAt: now,
            modifiedDeviceId: 'device-1',
            syncVersion: 1,
          ),
        ];

        bool addPageClicked = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: NotebookPageGridDialog(
                  pages: pages,
                  currentPageIndex: 0,
                  onPageSelected: (_) {},
                  onAddPage: () => addPageClicked = true,
                  onInsertPageBelow: (_) {},
                  onDuplicatePage: (_) {},
                  onDeletePage: (_) {},
                  onMovePage: (from, to) {},
                  onChangeTemplate: (idx, template) {},
                ),
              ),
            ),
          ),
        );

        final addBtn = find.widgetWithText(FilledButton, 'Add Page');
        expect(addBtn, findsOneWidget);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        expect(addPageClicked, isTrue);
      },
    );
  });
}
