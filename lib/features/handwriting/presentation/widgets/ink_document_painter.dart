import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/math/rough_generator.dart';
import '../../domain/math/stroke_tessellator.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_point.dart';
import '../../domain/models/ink_stroke.dart';
import '../../domain/models/ink_tool.dart';
import 'ink_render_cache.dart';

/// CustomPainter that renders an [AtlasInkDocument] including paper stationery
/// templates (ruled, dotted, square grid, Cornell notes, blank), multiply-composited
/// highlighters, standard vector pen/pencil strokes, Excalidraw sketchy shapes
/// (rectangles, ellipses, diamonds, arrows, lines, text) with hachure fills, and
/// any currently active in-flight stroke.
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

    // 4. Draw Active In-Flight Stroke / Shape Preview
    if (isDrawing && activePoints.isNotEmpty && activeTool != null) {
      if (activeTool!.isShape && activePoints.length >= 2) {
        // Live Excalidraw shape preview
        final p1 = Offset(activePoints.first.x, activePoints.first.y);
        final p2 = Offset(activePoints.last.x, activePoints.last.y);
        final previewBounds = Rect.fromPoints(p1, p2);

        final previewStroke = InkStroke(
          id: 'active_shape_preview',
          tool: activeTool!.type,
          color: activeTool!.color,
          baseWidth: activeTool!.baseWidth,
          opacity: activeTool!.opacity,
          points: activePoints,
          bounds: previewBounds,
          fillStyle: activeTool!.fillStyle,
          fillColor: activeTool!.fillColor,
          roughness: activeTool!.roughness,
          seed: 777,
        );
        _drawExcalidrawShape(canvas, previewStroke);
      } else if (!activeTool!.isEraser && !activeTool!.isLasso) {
        // Freehand ink stroke
        final path = StrokeTessellator.tessellatePoints(
          activePoints,
          activeTool!.type,
          activeTool!.baseWidth,
        );

        final inFlightPaint = Paint()
          ..color = Color(activeTool!.color).withValues(alpha: activeTool!.opacity)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        if (activeTool!.isHighlighter) {
          canvas.saveLayer(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Paint()..blendMode = BlendMode.multiply,
          );
          canvas.drawPath(path, inFlightPaint);
          canvas.restore();
        } else {
          canvas.drawPath(path, inFlightPaint);
        }
      }
    }

    // 5. Draw Active Lasso Selection Boundary
    if (activeTool != null && activeTool!.isLasso && lassoPolygon.length > 1) {
      final lassoPath = Path();
      lassoPath.moveTo(lassoPolygon.first.dx, lassoPolygon.first.dy);
      for (int i = 1; i < lassoPolygon.length; i++) {
        lassoPath.lineTo(lassoPolygon[i].dx, lassoPolygon[i].dy);
      }

      final strokePaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..isAntiAlias = true;

      canvas.drawPath(lassoPath, strokePaint);

      final fillPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(lassoPath, fillPaint);
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

    // 3. Draw Standard Ink Layers (Pen, Shapes, Text, etc.)
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
    if (clipBounds != null) {
      final bounds = stroke.computedBounds;
      if (bounds.isFinite && !clipBounds.overlaps(bounds)) {
        return;
      }
    }

    if (stroke.isShape) {
      _drawExcalidrawShape(canvas, stroke);
    } else {
      final path = StrokeTessellator.tessellate(stroke);
      final paint = Paint()
        ..color = Color(stroke.color).withValues(alpha: stroke.opacity)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    }
  }

  void _drawExcalidrawShape(Canvas canvas, InkStroke stroke) {
    final bounds = stroke.computedBounds;
    final strokeColor = Color(stroke.color).withValues(alpha: stroke.opacity);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, stroke.baseWidth)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final roughness = stroke.roughness;
    final seed = stroke.seed;

    // 1. Draw Rough Interior Fill (Solid, Hachure, or Cross-Hatch)
    if (stroke.fillStyle != null &&
        stroke.fillStyle != 'none' &&
        stroke.fillColor != null) {
      final fillColor = Color(stroke.fillColor!).withValues(alpha: stroke.opacity * 0.75);
      final fillPaint = Paint()
        ..color = fillColor
        ..isAntiAlias = true;

      if (stroke.fillStyle == 'solid') {
        fillPaint.style = PaintingStyle.fill;
        if (stroke.tool == InkToolType.ellipse || stroke.shapeType == 'ellipse') {
          canvas.drawOval(bounds, fillPaint);
        } else if (stroke.tool == InkToolType.diamond || stroke.shapeType == 'diamond') {
          final diamondPath = Path()
            ..moveTo(bounds.center.dx, bounds.top)
            ..lineTo(bounds.right, bounds.center.dy)
            ..lineTo(bounds.center.dx, bounds.bottom)
            ..lineTo(bounds.left, bounds.center.dy)
            ..close();
          canvas.drawPath(diamondPath, fillPaint);
        } else {
          canvas.drawRect(bounds, fillPaint);
        }
      } else if (stroke.fillStyle == 'hachure' || stroke.fillStyle == 'cross-hatch') {
        fillPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, stroke.baseWidth * 0.65);

        final hachurePath = RoughGenerator.buildHachureLines(
          bounds,
          spacing: math.max(8.0, stroke.baseWidth * 3.5),
          crossHatch: stroke.fillStyle == 'cross-hatch',
          roughness: roughness,
          seed: seed + 50,
        );

        canvas.save();
        if (stroke.tool == InkToolType.ellipse || stroke.shapeType == 'ellipse') {
          canvas.clipPath(Path()..addOval(bounds));
        } else if (stroke.tool == InkToolType.diamond || stroke.shapeType == 'diamond') {
          final diamondClip = Path()
            ..moveTo(bounds.center.dx, bounds.top)
            ..lineTo(bounds.right, bounds.center.dy)
            ..lineTo(bounds.center.dx, bounds.bottom)
            ..lineTo(bounds.left, bounds.center.dy)
            ..close();
          canvas.clipPath(diamondClip);
        } else {
          canvas.clipRect(bounds);
        }
        canvas.drawPath(hachurePath, fillPaint);
        canvas.restore();
      }
    }

    // 2. Draw Rough Shape Outlines
    final shape = stroke.shapeType ?? stroke.tool.name;
    switch (shape) {
      case 'rectangle':
        final path = RoughGenerator.buildRoughRectangle(
          bounds,
          roughness: roughness,
          seed: seed,
        );
        canvas.drawPath(path, strokePaint);
        break;
      case 'ellipse':
        final path = RoughGenerator.buildRoughEllipse(
          bounds,
          roughness: roughness,
          seed: seed,
        );
        canvas.drawPath(path, strokePaint);
        break;
      case 'diamond':
        final path = RoughGenerator.buildRoughDiamond(
          bounds,
          roughness: roughness,
          seed: seed,
        );
        canvas.drawPath(path, strokePaint);
        break;
      case 'arrow':
        final p1 = stroke.points.isNotEmpty
            ? Offset(stroke.points.first.x, stroke.points.first.y)
            : bounds.topLeft;
        final p2 = stroke.points.length > 1
            ? Offset(stroke.points.last.x, stroke.points.last.y)
            : bounds.bottomRight;
        final path = RoughGenerator.buildRoughArrow(
          p1,
          p2,
          roughness: roughness,
          seed: seed,
        );
        canvas.drawPath(path, strokePaint);
        break;
      case 'line':
        final p1 = stroke.points.isNotEmpty
            ? Offset(stroke.points.first.x, stroke.points.first.y)
            : bounds.topLeft;
        final p2 = stroke.points.length > 1
            ? Offset(stroke.points.last.x, stroke.points.last.y)
            : bounds.bottomRight;
        final path = RoughGenerator.buildRoughLine(
          p1,
          p2,
          roughness: roughness,
          seed: seed,
        );
        canvas.drawPath(path, strokePaint);
        break;
      case 'text':
        if (stroke.text != null && stroke.text!.isNotEmpty) {
          final textSpan = TextSpan(
            text: stroke.text,
            style: TextStyle(
              color: strokeColor,
              fontSize: stroke.fontSize ?? 18.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: bounds.width > 20 ? bounds.width : 400);
          textPainter.paint(canvas, bounds.topLeft);
        }
        break;
      default:
        final path = RoughGenerator.buildRoughRectangle(
          bounds,
          roughness: roughness,
          seed: seed,
        );
        canvas.drawPath(path, strokePaint);
    }
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
/// (ruled, dotted, square grid, Cornell notes, or blank) with subtle DPI-scaled aesthetics
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

    if (normalized.contains('cornell')) {
      // Cornell Notes Layout (Optimized for iPad study & research notes)
      final headerY = math.min(140.0, size.height * 0.12);
      final summaryY = math.max(size.height - 180.0, size.height * 0.84);
      final cueX = size.width * 0.28;

      final majorLinePaint = Paint()
        ..color = guideColor.withValues(alpha: isDark ? 0.5 : 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Header rule
      canvas.drawLine(Offset(0, headerY), Offset(size.width, headerY), majorLinePaint);
      // Cue column vertical divider
      canvas.drawLine(Offset(cueX, headerY), Offset(cueX, summaryY), majorLinePaint);
      // Bottom summary rule
      canvas.drawLine(Offset(0, summaryY), Offset(size.width, summaryY), majorLinePaint);

      // Ruled lines in main notes section
      for (double y = headerY + s; y < summaryY; y += s) {
        canvas.drawLine(Offset(cueX, y), Offset(size.width, y), gridPaint);
      }
      // Ruled lines in summary section
      for (double y = summaryY + s; y < size.height; y += s) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else if (normalized.contains('dot')) {
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
