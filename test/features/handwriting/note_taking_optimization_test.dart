import 'package:atlas/features/handwriting/domain/math/stroke_tessellator.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/widgets/floating_tool_dock.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:flutter/material.dart';
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
  });
}
