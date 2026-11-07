import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/math/stroke_tessellator.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_point.dart';
import '../../domain/models/ink_stroke.dart';
import '../../domain/models/ink_tool.dart';
import 'ink_render_cache.dart';

/// CustomPainter that renders an [AtlasInkDocument] including paper templates,
/// multiply-composited highlighters, standard pen/pencil strokes, and any
/// currently active in-flight stroke.
///
/// Performance Optimizations (Milestone 9):
/// 1. Viewport Culling & Bounding Box Pruning:
///    Strokes whose bounding boxes fall outside the visible clip bounds
///    are culled before tessellation and drawing.
/// 2. Static Stroke Bitmap/Picture Caching:
///    When [document.totalStrokeCount] exceeds [cacheThreshold] (default 500),
///    committed background strokes are cached into an offscreen [ui.Picture]
///    and blitted in a single GPU operation during pan/zoom or in-flight drawing.
class InkDocumentPainter extends CustomPainter {
  final AtlasInkDocument document;
  final List<InkPoint> activePoints;
  final List<Offset> lassoPolygon;
  final InkToolConfig? activeTool;
  final bool isDrawing;
  final bool drawBackground;
  final InkRenderCache? renderCache;
  final int cacheThreshold;
  final int revision;

  InkDocumentPainter({
    required this.document,
    this.activePoints = const [],
    this.lassoPolygon = const [],
    this.activeTool,
    this.isDrawing = false,
    this.drawBackground = true,
    this.renderCache,
    this.cacheThreshold = InkRenderCache.defaultThreshold,
    this.revision = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Paper Background & Grid Template
    if (drawBackground) {
      _drawPaperBackground(canvas, size);
    }

    final totalStrokes = document.totalStrokeCount;
    final useCache = renderCache != null && totalStrokes >= cacheThreshold;

    if (useCache) {
      if (!renderCache!.isValid(revision, size)) {
        // Record all committed background strokes into an offscreen ui.Picture
        final recorder = ui.PictureRecorder();
        final recordCanvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, size.width, size.height),
        );
        _paintCommittedLayers(recordCanvas, size, null);
        final recordedPicture = recorder.endRecording();
        renderCache!.update(recordedPicture, revision, size, totalStrokes);
      }

      // Single GPU blit of all committed strokes
      if (renderCache!.picture != null) {
        canvas.drawPicture(renderCache!.picture!);
      }
    } else {
      // Direct rendering with Viewport Culling & Bounding Box Pruning
      final clipBounds = canvas.getLocalClipBounds();
      final effectiveClip = (clipBounds.isFinite && !clipBounds.isEmpty)
          ? clipBounds
          : null;
      _paintCommittedLayers(canvas, size, effectiveClip);
    }

    // 4. Draw In-Flight Active Stroke on Top
    if (isDrawing && activePoints.isNotEmpty && activeTool != null) {
      final isHighlighter = activeTool!.type.isHighlighter;
      final tempStroke = InkStroke(
        id: 'active',
        tool: activeTool!.type,
        color: activeTool!.color,
        baseWidth: activeTool!.baseWidth,
        opacity: isHighlighter ? 0.4 : activeTool!.opacity,
        blendMode: isHighlighter ? 'multiply' : 'srcOver',
        points: activePoints,
        bounds: StrokeTessellator.computeBoundsFromPoints(
          activePoints,
          activeTool!.baseWidth,
        ),
      );

      if (isHighlighter) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..blendMode = BlendMode.multiply,
        );
        _drawStroke(canvas, tempStroke, null);
        canvas.restore();
      } else {
        _drawStroke(canvas, tempStroke, null);
      }
    }

    // 5. Draw Active Lasso Selection Polygon
    if (lassoPolygon.isNotEmpty) {
      _drawLassoPolygon(canvas, lassoPolygon);
    }
  }

  void _drawLassoPolygon(Canvas canvas, List<Offset> polygon) {
    if (polygon.isEmpty) return;
    final path = Path();
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(polygon[i].dx, polygon[i].dy);
    }
    // Translucent fill
    final fillPaint = Paint()
      ..color = const Color(0x1F6366F1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Dashed border
    final strokePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, strokePaint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _paintCommittedLayers(Canvas canvas, Size size, Rect? clipBounds) {
    // 2. Draw Highlighter Layers (Multi-pass Multiply Compositing)
    final highlighterLayers = document.layers.where(
      (l) => l.blendMode == 'multiply' && l.visible,
    );
    for (final layer in highlighterLayers) {
      if (layer.strokes.isNotEmpty) {
        final visibleStrokes = clipBounds != null
            ? layer.strokes
                  .where((s) => s.computedBounds.overlaps(clipBounds))
                  .toList()
            : layer.strokes;

        if (visibleStrokes.isNotEmpty) {
          // Isolate highlighter layer to prevent overlapping stroke darkening
          canvas.saveLayer(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Paint()..blendMode = BlendMode.multiply,
          );

          for (final stroke in visibleStrokes) {
            _drawStroke(canvas, stroke, clipBounds);
          }

          canvas.restore();
        }
      }
    }

    // 3. Draw Standard Ink Layers (Pen, Pencil, etc.)
    final normalLayers = document.layers.where(
      (l) => l.blendMode != 'multiply' && l.visible,
    );
    for (final layer in normalLayers) {
      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke, clipBounds);
      }
    }
  }

  void _drawStroke(Canvas canvas, InkStroke stroke, Rect? clipBounds) {
    // Viewport Culling & Bounding Box Pruning
    if (clipBounds != null) {
      final bounds = stroke.computedBounds;
      if (bounds.isFinite && !clipBounds.overlaps(bounds)) {
        return; // Culled! Skip tessellation and drawPath
      }
    }

    final path = StrokeTessellator.tessellate(stroke);
    final paint = Paint()
      ..color = Color(stroke.color).withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  void _drawPaperBackground(Canvas canvas, Size size) {
    PaperPatternPainter.paintPattern(
      canvas,
      size,
      document.backgroundTemplate,
      Color(document.backgroundColor),
      spacing: document.templateSpacing,
    );
  }

  @override
  bool shouldRepaint(covariant InkDocumentPainter oldDelegate) {
    return isDrawing ||
        oldDelegate.isDrawing ||
        oldDelegate.document != document ||
        oldDelegate.revision != revision ||
        oldDelegate.activePoints.length != activePoints.length ||
        oldDelegate.lassoPolygon.length != lassoPolygon.length;
  }
}

/// Standalone paper pattern painter rendering standard stationery guidelines
/// (ruled, dotted, square grid, or blank) with subtle DPI-scaled aesthetics
/// adapting cleanly to light and dark backgrounds.
class PaperPatternPainter extends CustomPainter {
  final String template;
  final Color backgroundColor;
  final double spacing;

  const PaperPatternPainter({
    required this.template,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.spacing = 28.35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintPattern(canvas, size, template, backgroundColor, spacing: spacing);
  }

  static void paintPattern(
    Canvas canvas,
    Size size,
    String template,
    Color backgroundColor, {
    double spacing = 28.35,
  }) {
    // Base paper background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final normalized = template.toLowerCase();
    if (normalized == 'blank') return;

    final isDark = backgroundColor.computeLuminance() < 0.5;
    final guideColor = isDark
        ? const Color(0x2EFFFFFF)
        : const Color(0x1F000000);
    final dotColor = isDark ? const Color(0x44FFFFFF) : const Color(0x33000000);

    final gridPaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final s = spacing > 0 ? spacing : 28.35;

    if (normalized.contains('dot')) {
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      for (double y = s; y < size.height; y += s) {
        for (double x = s; x < size.width; x += s) {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    } else if (normalized.contains('grid') || normalized.contains('graph')) {
      for (double x = s; x < size.width; x += s) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = s; y < size.height; y += s) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else {
      // Default: ruled / lined
      for (double y = s * 1.5; y < size.height; y += s) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PaperPatternPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.spacing != spacing;
  }
}
