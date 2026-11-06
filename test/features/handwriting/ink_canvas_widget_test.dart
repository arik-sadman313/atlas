import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_page_view.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_tool_palette.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InkCanvas Controller & Drawing', () {
    testWidgets('records strokes via pointer gestures', (tester) async {
      final initialDoc = AtlasInkDocument.empty(
        documentId: 'doc_1',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: initialDoc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InkCanvas(controller: controller, width: 800, height: 600),
            ),
          ),
        ),
      );

      expect(controller.document.isEmpty, isTrue);

      // Simulate drawing a line
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();

      expect(controller.isDrawing, isTrue);
      expect(controller.activePoints.length, equals(1));

      await gesture.moveTo(const Offset(150, 150));
      await tester.pump();
      expect(controller.activePoints.length, equals(2));

      await gesture.up();
      await tester.pump();

      expect(controller.isDrawing, isFalse);
      expect(controller.document.isEmpty, isFalse);
      expect(controller.document.totalStrokeCount, equals(1));
    });

    testWidgets('undo and redo revert and restore strokes', (tester) async {
      final initialDoc = AtlasInkDocument.empty(
        documentId: 'doc_1',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(document: initialDoc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InkCanvas(controller: controller, width: 800, height: 600),
            ),
          ),
        ),
      );

      // Draw stroke
      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.moveTo(const Offset(80, 80));
      await gesture.up();
      await tester.pump();

      expect(controller.document.totalStrokeCount, equals(1));
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);

      // Undo
      controller.undo();
      await tester.pump();
      expect(controller.document.totalStrokeCount, equals(0));
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      // Redo
      controller.redo();
      await tester.pump();
      expect(controller.document.totalStrokeCount, equals(1));
    });

    testWidgets('vector eraser removes intersecting stroke', (tester) async {
      final stroke = InkStroke(
        id: 'stroke_to_erase',
        tool: InkToolType.ballpointPen,
        color: 0xFF000000,
        baseWidth: 4.0,
        points: const [
          InkPoint(x: 100, y: 100, pressure: 0.5, timeOffsetMs: 0),
          InkPoint(x: 200, y: 200, pressure: 0.5, timeOffsetMs: 10),
        ],
      );

      final docWithStroke = AtlasInkDocument(
        version: 1,
        documentId: 'doc_erase',
        pageNumber: 1,
        width: 800,
        height: 600,
        layers: [
          InkLayer(id: 'l1', name: 'Ink', strokes: [stroke]),
        ],
      );

      final controller = InkCanvasController(document: docWithStroke);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InkCanvas(controller: controller, width: 800, height: 600),
            ),
          ),
        ),
      );

      expect(controller.document.totalStrokeCount, equals(1));

      // Switch to vector eraser
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.vectorEraser,
          color: 0xFF000000,
          baseWidth: 20.0,
        ),
      );

      // Erase directly on the stroke point (100, 100)
      final eraserGesture = await tester.startGesture(const Offset(105, 105));
      await eraserGesture.up();
      await tester.pump();

      expect(controller.document.totalStrokeCount, equals(0));
    });
  });

  group('InkToolPalette Widget', () {
    testWidgets('switches tools and colors accurately', (tester) async {
      final doc = AtlasInkDocument.empty(documentId: 'doc_p');
      final controller = InkCanvasController(document: doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: InkToolPalette(controller: controller)),
          ),
        ),
      );

      // Initially ballpoint pen
      expect(controller.activeTool.type, equals(InkToolType.ballpointPen));

      // Tap Highlighter icon
      await tester.tap(find.byIcon(Icons.highlight_outlined));
      await tester.pump();
      expect(controller.activeTool.type, equals(InkToolType.highlighter));

      // Tap Eraser icon
      await tester.tap(find.byIcon(Icons.auto_fix_normal_outlined));
      await tester.pump();
      expect(controller.activeTool.type, equals(InkToolType.vectorEraser));
    });
  });

  group('InkPageView (Companion Read-Only)', () {
    testWidgets('renders document in read-only mode with zoom/pan', (
      tester,
    ) async {
      final doc = AtlasInkDocument(
        version: 1,
        documentId: 'doc_companion',
        pageNumber: 1,
        width: 800,
        height: 600,
        backgroundTemplate: 'ruled',
        backgroundColor: 0xFFFFFFFF,
        layers: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkPageView(document: doc, showCompanionBadge: true),
          ),
        ),
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byIcon(Icons.fit_screen_outlined), findsOneWidget);
    });
  });
}
