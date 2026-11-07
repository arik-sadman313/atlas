import 'package:atlas/features/handwriting/domain/math/stroke_tessellator.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lasso Selection & Math Tests', () {
    final boxPolygon = [
      const Offset(0, 0),
      const Offset(100, 0),
      const Offset(100, 100),
      const Offset(0, 100),
    ];

    test('isPointInPolygon correctly detects interior and exterior points', () {
      expect(
        StrokeTessellator.isPointInPolygon(const Offset(50, 50), boxPolygon),
        isTrue,
      );
      expect(
        StrokeTessellator.isPointInPolygon(const Offset(20, 80), boxPolygon),
        isTrue,
      );
      expect(
        StrokeTessellator.isPointInPolygon(const Offset(150, 50), boxPolygon),
        isFalse,
      );
      expect(
        StrokeTessellator.isPointInPolygon(const Offset(-10, 50), boxPolygon),
        isFalse,
      );
      expect(
        StrokeTessellator.isPointInPolygon(const Offset(50, 120), boxPolygon),
        isFalse,
      );
    });

    test(
      'isStrokeSelectedByLasso selects stroke if points or center are inside',
      () {
        final insideStroke = InkStroke(
          id: 's_inside',
          tool: InkToolType.ballpointPen,
          color: 0xFF18181B,
          baseWidth: 3.0,
          points: const [
            InkPoint(x: 20, y: 20),
            InkPoint(x: 30, y: 30),
            InkPoint(x: 40, y: 40),
          ],
        );

        final outsideStroke = InkStroke(
          id: 's_outside',
          tool: InkToolType.ballpointPen,
          color: 0xFF18181B,
          baseWidth: 3.0,
          points: const [InkPoint(x: 200, y: 200), InkPoint(x: 250, y: 250)],
        );

        final halfInsideStroke = InkStroke(
          id: 's_half',
          tool: InkToolType.ballpointPen,
          color: 0xFF18181B,
          baseWidth: 3.0,
          points: const [
            InkPoint(x: 20, y: 20),
            InkPoint(x: 30, y: 30),
            InkPoint(x: 120, y: 120), // 2 of 3 points inside (66% >= 50%)
          ],
        );

        expect(
          StrokeTessellator.isStrokeSelectedByLasso(insideStroke, boxPolygon),
          isTrue,
        );
        expect(
          StrokeTessellator.isStrokeSelectedByLasso(outsideStroke, boxPolygon),
          isFalse,
        );
        expect(
          StrokeTessellator.isStrokeSelectedByLasso(
            halfInsideStroke,
            boxPolygon,
          ),
          isTrue,
        );
      },
    );

    test('transformStroke translates, scales, and recolors accurately', () {
      final stroke = InkStroke(
        id: 's1',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: const [InkPoint(x: 10, y: 20), InkPoint(x: 30, y: 40)],
      );

      // 1. Translation
      final translated = StrokeTessellator.transformStroke(
        stroke,
        delta: const Offset(15, -5),
      );
      expect(translated.points[0].x, 25);
      expect(translated.points[0].y, 15);
      expect(translated.points[1].x, 45);
      expect(translated.points[1].y, 35);

      // 2. Scale relative to origin (10, 20)
      final scaled = StrokeTessellator.transformStroke(
        stroke,
        scaleX: 2.0,
        scaleY: 2.0,
        origin: const Offset(10, 20),
      );
      expect(scaled.points[0].x, 10);
      expect(scaled.points[0].y, 20);
      expect(scaled.points[1].x, 50); // 10 + (30 - 10) * 2 = 50
      expect(scaled.points[1].y, 60); // 20 + (40 - 20) * 2 = 60
      expect(scaled.baseWidth, 6.0); // 3.0 * 2.0

      // 3. Recolor
      final recolored = StrokeTessellator.transformStroke(
        stroke,
        newColor: 0xFF6366F1,
      );
      expect(recolored.color, 0xFF6366F1);
    });
  });

  group('InkCanvasController Lasso Interactions & Batch Actions', () {
    late InkCanvasController controller;
    late InkStroke strokeA;
    late InkStroke strokeB;

    setUp(() {
      strokeA = InkStroke(
        id: 'stroke_a',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: const [InkPoint(x: 20, y: 20), InkPoint(x: 40, y: 40)],
      );

      strokeB = InkStroke(
        id: 'stroke_b',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: const [InkPoint(x: 200, y: 200), InkPoint(x: 220, y: 220)],
      );

      final doc = AtlasInkDocument(
        documentId: 'doc_1',
        layers: [
          InkLayer(
            id: 'layer_default',
            name: 'Main',
            strokes: [strokeA, strokeB],
          ),
        ],
      );

      controller = InkCanvasController(document: doc);
    });

    tearDown(() {
      controller.dispose();
    });

    test('drawing with lasso selects stroke and computes bounds', () {
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.lasso,
          color: 0xFF6366F1,
          baseWidth: 2.0,
        ),
      );

      expect(controller.hasSelection, isFalse);

      // Draw lasso around strokeA: (0, 0) -> (100, 0) -> (100, 100) -> (0, 100)
      controller.startStroke(const Offset(0, 0));
      controller.updateStroke(const Offset(100, 0));
      controller.updateStroke(const Offset(100, 100));
      controller.updateStroke(const Offset(0, 100));
      controller.endStroke();

      expect(controller.hasSelection, isTrue);
      expect(controller.selectedStrokeIds, contains('stroke_a'));
      expect(controller.selectedStrokeIds, isNot(contains('stroke_b')));
      expect(controller.selectionBounds, isNotNull);
    });

    test(
      'translateSelectedStrokes moves selected strokes and shifts bounds',
      () {
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.lasso,
            color: 0xFF6366F1,
            baseWidth: 2.0,
          ),
        );

        // Select strokeA
        controller.startStroke(const Offset(0, 0));
        controller.updateStroke(const Offset(100, 0));
        controller.updateStroke(const Offset(100, 100));
        controller.updateStroke(const Offset(0, 100));
        controller.endStroke();

        final initialBounds = controller.selectionBounds!;
        controller.translateSelectedStrokes(
          const Offset(25, 30),
          recordUndo: true,
        );

        final updatedStrokeA = controller.document.layers.first.strokes
            .firstWhere((s) => s.id == 'stroke_a');
        expect(updatedStrokeA.points[0].x, 45); // 20 + 25
        expect(updatedStrokeA.points[0].y, 50); // 20 + 30

        // Verify strokeB untouched
        final updatedStrokeB = controller.document.layers.first.strokes
            .firstWhere((s) => s.id == 'stroke_b');
        expect(updatedStrokeB.points[0].x, 200);

        expect(controller.selectionBounds!.left, initialBounds.left + 25);
        expect(controller.selectionBounds!.top, initialBounds.top + 30);
      },
    );

    test(
      'duplicateSelectedStrokes clones strokes with offset and selects clones',
      () {
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.lasso,
            color: 0xFF6366F1,
            baseWidth: 2.0,
          ),
        );

        // Select strokeA
        controller.startStroke(const Offset(0, 0));
        controller.updateStroke(const Offset(100, 0));
        controller.updateStroke(const Offset(100, 100));
        controller.updateStroke(const Offset(0, 100));
        controller.endStroke();

        expect(controller.document.totalStrokeCount, 2);

        controller.duplicateSelectedStrokes(offset: const Offset(20, 20));

        expect(controller.document.totalStrokeCount, 3);
        expect(controller.selectedStrokeIds.length, 1);
        final newStrokeId = controller.selectedStrokeIds.first;
        expect(newStrokeId, isNot('stroke_a'));

        final duplicatedStroke = controller.document.layers.first.strokes
            .firstWhere((s) => s.id == newStrokeId);
        expect(duplicatedStroke.points[0].x, 40); // 20 + 20
        expect(duplicatedStroke.points[0].y, 40); // 20 + 20
      },
    );

    test(
      'recolorSelectedStrokes batches color update and undo restores original',
      () {
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.lasso,
            color: 0xFF6366F1,
            baseWidth: 2.0,
          ),
        );

        // Select strokeA
        controller.startStroke(const Offset(0, 0));
        controller.updateStroke(const Offset(100, 0));
        controller.updateStroke(const Offset(100, 100));
        controller.updateStroke(const Offset(0, 100));
        controller.endStroke();

        controller.recolorSelectedStrokes(0xFF10B981);

        var updatedA = controller.document.layers.first.strokes.firstWhere(
          (s) => s.id == 'stroke_a',
        );
        expect(updatedA.color, 0xFF10B981);

        // Undo restores original color
        expect(controller.canUndo, isTrue);
        controller.undo();

        updatedA = controller.document.layers.first.strokes.firstWhere(
          (s) => s.id == 'stroke_a',
        );
        expect(updatedA.color, 0xFF18181B);
      },
    );

    test(
      'deleteSelectedStrokes atomically removes strokes and supports undo',
      () {
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.lasso,
            color: 0xFF6366F1,
            baseWidth: 2.0,
          ),
        );

        // Select strokeA
        controller.startStroke(const Offset(0, 0));
        controller.updateStroke(const Offset(100, 0));
        controller.updateStroke(const Offset(100, 100));
        controller.updateStroke(const Offset(0, 100));
        controller.endStroke();

        controller.deleteSelectedStrokes();

        expect(controller.document.totalStrokeCount, 1);
        expect(controller.hasSelection, isFalse);
        expect(
          controller.document.layers.first.strokes.any(
            (s) => s.id == 'stroke_a',
          ),
          isFalse,
        );

        // Undo brings it back
        controller.undo();
        expect(controller.document.totalStrokeCount, 2);
        expect(
          controller.document.layers.first.strokes.any(
            (s) => s.id == 'stroke_a',
          ),
          isTrue,
        );
      },
    );
  });
}
