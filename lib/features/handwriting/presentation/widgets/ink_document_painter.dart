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

  InkDocumentPainter({
    required this.document,
    this.activePoints = const [],
    this.activeTool,
    this.isDrawing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Paper Background & Grid Template
    _drawPaperBackground(canvas, size);

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
/// (ruled, dotted, square grid, or blank) with subtle DPI-scaled aesthetics.
class PaperPatternPainter extends CustomPainter {
  final String template;
  final Color backgroundColor;

  const PaperPatternPainter({
    required this.template,
    this.backgroundColor = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintPattern(canvas, size, template, backgroundColor);
  }

  static void paintPattern(
    Canvas canvas,
    Size size,
    String template,
    Color backgroundColor,
  ) {
    // Base paper background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (template == 'blank') return;

    final gridPaint = Paint()
      ..color =
          const Color(0x1F000000) // 12% black subtle guide
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double spacing = 28.35; // ~5mm at 144 DPI standard

    if (template.contains('dot')) {
      final dotPaint = Paint()
        ..color =
            const Color(0x33000000) // 20% black
        ..style = PaintingStyle.fill;

      for (double y = spacing; y < size.height; y += spacing) {
        for (double x = spacing; x < size.width; x += spacing) {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    } else if (template.contains('grid')) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else {
      // Default: ruled / lined
      for (double y = spacing * 1.5; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PaperPatternPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
