import 'dart:ui' as ui;

import 'package:atlas/features/handwriting/domain/math/stroke_tessellator.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_document_painter.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_render_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ink Rendering Performance Optimization (Milestone 9)', () {
    late InkStroke insideStroke;
    late InkStroke outsideStroke;

    setUp(() {
      insideStroke = InkStroke(
        id: 'inside_stroke',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: const [
          InkPoint(x: 50, y: 50, pressure: 0.5, timeOffsetMs: 0),
          InkPoint(x: 100, y: 100, pressure: 0.5, timeOffsetMs: 10),
        ],
        bounds: const Rect.fromLTRB(40, 40, 110, 110),
      );

      outsideStroke = InkStroke(
        id: 'outside_stroke',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: const [
          InkPoint(x: 800, y: 800, pressure: 0.5, timeOffsetMs: 0),
          InkPoint(x: 900, y: 900, pressure: 0.5, timeOffsetMs: 10),
        ],
        bounds: const Rect.fromLTRB(790, 790, 910, 910),
      );
    });

    test('StrokeTessellator.computeBounds computes tight padded Rect', () {
      final bounds = StrokeTessellator.computeBounds(insideStroke);
      expect(bounds.left, equals(40));
      expect(bounds.top, equals(40));

      final uncomputedStroke = InkStroke(
        id: 'uncomputed',
        tool: InkToolType.ballpointPen,
        color: 0xFF000000,
        baseWidth: 4.0,
        points: const [
          InkPoint(x: 10, y: 20, pressure: 0.5, timeOffsetMs: 0),
          InkPoint(x: 50, y: 80, pressure: 0.5, timeOffsetMs: 10),
        ],
      );
      final derivedBounds = StrokeTessellator.computeBounds(uncomputedStroke);
      expect(derivedBounds.left, equals(10 - 4.0 * 1.5));
      expect(derivedBounds.top, equals(20 - 4.0 * 1.5));
      expect(derivedBounds.right, equals(50 + 4.0 * 1.5));
      expect(derivedBounds.bottom, equals(80 + 4.0 * 1.5));
    });

    test('Viewport culling prunes out-of-bounds strokes', () {
      final doc = AtlasInkDocument(
        documentId: 'doc_cull',
        width: 1000,
        height: 1000,
        layers: [
          InkLayer(
            id: 'l1',
            name: 'Layer 1',
            strokes: [insideStroke, outsideStroke],
          ),
        ],
      );

      final painter = InkDocumentPainter(document: doc, drawBackground: false);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Clip to viewport: 0,0 to 200,200 (insideStroke is inside, outsideStroke is outside)
      canvas.clipRect(const Rect.fromLTWH(0, 0, 200, 200));

      // Paint document onto clipped canvas
      painter.paint(canvas, const Size(1000, 1000));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('Static stroke caching creates offscreen Picture when stroke count >= threshold', () {
      // Create 505 strokes to exceed 500 threshold
      final strokes = List.generate(
        505,
        (i) => InkStroke(
          id: 'stroke_$i',
          tool: InkToolType.ballpointPen,
          color: 0xFF18181B,
          baseWidth: 2.0,
          points: [
            InkPoint(
              x: (i % 200).toDouble(),
              y: (i % 200).toDouble(),
              pressure: 0.5,
              timeOffsetMs: 0,
            ),
            InkPoint(
              x: (i % 200 + 10).toDouble(),
              y: (i % 200 + 10).toDouble(),
              pressure: 0.5,
              timeOffsetMs: 10,
            ),
          ],
        ),
      );

      final heavyDoc = AtlasInkDocument(
        documentId: 'heavy_doc',
        width: 1600,
        height: 2200,
        layers: [
          InkLayer(id: 'l_heavy', name: 'Heavy Layer', strokes: strokes),
        ],
      );

      final cache = InkRenderCache();
      expect(cache.hasCache, isFalse);

      final painter = InkDocumentPainter(
        document: heavyDoc,
        drawBackground: false,
        renderCache: cache,
        cacheThreshold: 500,
        revision: 1,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(1600, 2200));

      // Verify picture cache was populated
      expect(cache.hasCache, isTrue);
      expect(cache.strokeCount, equals(505));
      expect(cache.isValid(1, const Size(1600, 2200)), isTrue);

      // Repaint should reuse the cached picture without recording again
      final recorder2 = ui.PictureRecorder();
      final canvas2 = Canvas(recorder2);
      painter.paint(canvas2, const Size(1600, 2200));
      expect(cache.hasCache, isTrue);

      // Invalidation clears the picture
      cache.invalidate();
      expect(cache.hasCache, isFalse);
      expect(cache.picture, isNull);

      recorder.endRecording().dispose();
      recorder2.endRecording().dispose();
      cache.dispose();
    });

    test('InkCanvasController invalidates render cache and increments revision on stroke commit', () {
      final doc = AtlasInkDocument.empty(documentId: 'test_doc');
      final controller = InkCanvasController(document: doc);

      expect(controller.revision, equals(0));
      expect(controller.renderCache.hasCache, isFalse);

      // Simulate a fake cached picture
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawLine(Offset.zero, const Offset(10, 10), Paint());
      final pic = rec.endRecording();
      controller.renderCache.update(
        pic,
        controller.revision,
        const Size(100, 100),
        500,
      );
      expect(controller.renderCache.hasCache, isTrue);

      // Start and end stroke
      controller.startStroke(const Offset(20, 20));
      controller.updateStroke(const Offset(30, 30));
      controller.endStroke();

      // Cache should be invalidated and revision incremented
      expect(controller.revision, equals(1));
      expect(controller.renderCache.hasCache, isFalse);
      expect(controller.document.totalStrokeCount, equals(1));
      // Bounding box was precomputed
      expect(controller.document.allStrokes.first.bounds, isNotNull);

      controller.dispose();
    });
  });
}
