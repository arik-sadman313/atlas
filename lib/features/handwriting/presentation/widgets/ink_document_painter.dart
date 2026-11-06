import 'package:flutter/material.dart';

import '../../domain/math/stroke_tessellator.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_point.dart';
import '../../domain/models/ink_stroke.dart';
import '../../domain/models/ink_tool.dart';

/// CustomPainter that renders an [AtlasInkDocument] including paper templates,
/// multiply-composited highlighters, standard pen/pencil strokes, and any
/// currently active in-flight stroke.
class InkDocumentPainter extends CustomPainter {
  final AtlasInkDocument document;
  final List<InkPoint> activePoints;
  final InkToolConfig? activeTool;
  final bool isDrawing;
  final bool drawBackground;

  InkDocumentPainter({
    required this.document,
    this.activePoints = const [],
    this.activeTool,
    this.isDrawing = false,
    this.drawBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Paper Background & Grid Template
    if (drawBackground) {
      _drawPaperBackground(canvas, size);
    }

    // 2. Draw Highlighter Layers (Multi-pass Multiply Compositing)
    final highlighterLayers = document.layers.where(
      (l) => l.blendMode == 'multiply' && l.visible,
    );
    for (final layer in highlighterLayers) {
      if (layer.strokes.isNotEmpty) {
        // Isolate highlighter layer to prevent overlapping stroke darkening
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..blendMode = BlendMode.multiply,
        );

        for (final stroke in layer.strokes) {
          _drawStroke(canvas, stroke);
        }

        canvas.restore();
      }
    }

    // 3. Draw Standard Ink Layers (Pen, Pencil, etc.)
    final normalLayers = document.layers.where(
      (l) => l.blendMode != 'multiply' && l.visible,
    );
    for (final layer in normalLayers) {
      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke);
      }
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
      );

      if (isHighlighter) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..blendMode = BlendMode.multiply,
        );
        _drawStroke(canvas, tempStroke);
        canvas.restore();
      } else {
        _drawStroke(canvas, tempStroke);
      }
    }
  }

  void _drawStroke(Canvas canvas, InkStroke stroke) {
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
        oldDelegate.activePoints.length != activePoints.length;
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
    final guideColor =
        isDark ? const Color(0x2EFFFFFF) : const Color(0x1F000000);
    final dotColor =
        isDark ? const Color(0x44FFFFFF) : const Color(0x33000000);

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
