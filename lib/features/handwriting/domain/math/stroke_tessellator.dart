import 'dart:ui';

import 'package:perfect_freehand/perfect_freehand.dart';

import '../models/ink_stroke.dart';
import '../models/ink_tool.dart';

class StrokeTessellator {
  static StrokeOptions _getOptionsForTool(InkToolType tool, double baseWidth) {
    switch (tool) {
      case InkToolType.ballpointPen:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.25,
          smoothing: 0.5,
          streamline: 0.45,
          simulatePressure: false,
          start: StrokeEndOptions.start(taperEnabled: false),
          end: StrokeEndOptions.end(taperEnabled: false),
          isComplete: true,
        );
      case InkToolType.fountainPen:
        return StrokeOptions(
          size: baseWidth * 1.2,
          thinning: 0.7,
          smoothing: 0.6,
          streamline: 0.55,
          simulatePressure: false,
          start: StrokeEndOptions.start(customTaper: 4.0),
          end: StrokeEndOptions.end(customTaper: 8.0),
          isComplete: true,
        );
      case InkToolType.highlighter:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.0, // Constant width for chisel highlighter
          smoothing: 0.35,
          streamline: 0.25,
          simulatePressure: false,
          start: StrokeEndOptions.start(taperEnabled: false),
          end: StrokeEndOptions.end(taperEnabled: false),
          isComplete: true,
        );
      case InkToolType.pencil:
        return StrokeOptions(
          size: baseWidth * 0.9,
          thinning: 0.35,
          smoothing: 0.3,
          streamline: 0.2,
          simulatePressure: false,
          start: StrokeEndOptions.start(customTaper: 2.0),
          end: StrokeEndOptions.end(customTaper: 2.0),
          isComplete: true,
        );
      case InkToolType.vectorEraser:
      case InkToolType.pixelEraser:
        return StrokeOptions(
          size: baseWidth,
          thinning: 0.0,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: false,
          isComplete: true,
        );
    }
  }

  /// Converts an InkStroke into a closed vector Path using perfect_freehand
  static Path tessellate(InkStroke stroke) {
    if (stroke.points.isEmpty) return Path();

    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      final radius = (stroke.baseWidth * (0.5 + p.pressure * 0.5)) / 2;
      return Path()
        ..addOval(Rect.fromCircle(center: Offset(p.x, p.y), radius: radius));
    }

    final pointVectors = stroke.points
        .map((p) => PointVector(p.x, p.y, p.pressure))
        .toList();

    final options = _getOptionsForTool(stroke.tool, stroke.baseWidth);
    final outline = getStroke(pointVectors, options: options);

    return outlineToPath(outline);
  }

  /// Converts outline offsets into a smooth quadratic Bézier closed path
  static Path outlineToPath(List<Offset> outline) {
    final path = Path();
    if (outline.isEmpty) return path;

    if (outline.length < 3) {
      path.moveTo(outline.first.dx, outline.first.dy);
      for (int i = 1; i < outline.length; i++) {
        path.lineTo(outline[i].dx, outline[i].dy);
      }
      path.close();
      return path;
    }

    path.moveTo(outline.first.dx, outline.first.dy);

    for (int i = 0; i < outline.length - 1; i++) {
      final p0 = outline[i];
      final p1 = outline[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }

    final last = outline.last;
    final first = outline.first;
    final closingMid = Offset(
      (last.dx + first.dx) / 2,
      (last.dy + first.dy) / 2,
    );
    path.quadraticBezierTo(last.dx, last.dy, closingMid.dx, closingMid.dy);
    path.close();

    return path;
  }
}
