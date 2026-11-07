import 'dart:ui';

import 'package:perfect_freehand/perfect_freehand.dart';

import '../models/ink_point.dart';
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
      case InkToolType.lasso:
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

  /// Evaluates whether a point is inside a polygon using ray casting (even-odd rule).
  static bool isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      final intersect =
          ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Determines if a stroke is selected by the lasso polygon.
  /// A stroke is selected if its bounding box center is inside,
  /// or if >= 50% of its points are inside.
  static bool isStrokeSelectedByLasso(InkStroke stroke, List<Offset> polygon) {
    if (polygon.length < 3 || stroke.points.isEmpty) return false;
    final bounds = computeBounds(stroke);
    if (isPointInPolygon(bounds.center, polygon)) {
      return true;
    }
    int insideCount = 0;
    for (final p in stroke.points) {
      if (isPointInPolygon(Offset(p.x, p.y), polygon)) {
        insideCount++;
      }
    }
    return (insideCount / stroke.points.length) >= 0.5;
  }

  /// Computes the union bounding box enclosing a collection of strokes.
  static Rect computeEnclosingBounds(Iterable<InkStroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;
    Rect? bounds;
    for (final s in strokes) {
      final b = computeBounds(s);
      bounds = bounds == null ? b : bounds.expandToInclude(b);
    }
    return bounds ?? Rect.zero;
  }

  /// Transforms an [InkStroke] with translation, scale around origin, and optional recolor.
  static InkStroke transformStroke(
    InkStroke stroke, {
    Offset delta = Offset.zero,
    double scaleX = 1.0,
    double scaleY = 1.0,
    Offset? origin,
    int? newColor,
  }) {
    final ox = origin?.dx ?? 0.0;
    final oy = origin?.dy ?? 0.0;

    final newPoints = stroke.points.map((p) {
      final scaledX = ox + (p.x - ox) * scaleX;
      final scaledY = oy + (p.y - oy) * scaleY;
      return InkPoint(
        x: scaledX + delta.dx,
        y: scaledY + delta.dy,
        pressure: p.pressure,
        tiltAzimuth: p.tiltAzimuth,
        tiltAltitude: p.tiltAltitude,
        timeOffsetMs: p.timeOffsetMs,
      );
    }).toList();

    final avgScale = ((scaleX.abs() + scaleY.abs()) / 2.0);
    final newBaseWidth = (stroke.baseWidth * (avgScale == 0 ? 1.0 : avgScale))
        .clamp(0.2, 50.0);
    final newBounds = computeBoundsFromPoints(newPoints, newBaseWidth);

    return stroke.copyWith(
      points: newPoints,
      baseWidth: newBaseWidth,
      color: newColor ?? stroke.color,
      bounds: newBounds,
    );
  }

  /// Computes the bounding box of a list of points padded by baseWidth.
  static Rect computeBoundsFromPoints(List<InkPoint> points, double baseWidth) {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    for (final pt in points) {
      if (pt.x < minX) minX = pt.x;
      if (pt.x > maxX) maxX = pt.x;
      if (pt.y < minY) minY = pt.y;
      if (pt.y > maxY) maxY = pt.y;
    }
    final halfW = baseWidth * 1.5;
    return Rect.fromLTRB(
      minX - halfW,
      minY - halfW,
      maxX + halfW,
      maxY + halfW,
    );
  }

  /// Computes the bounding box of an [InkStroke].
  static Rect computeBounds(InkStroke stroke) {
    if (stroke.bounds != null) return stroke.bounds!;
    return computeBoundsFromPoints(stroke.points, stroke.baseWidth);
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
