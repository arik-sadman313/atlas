import 'dart:math' as math;
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
      case InkToolType.selection:
      case InkToolType.pan:
      case InkToolType.rectangle:
      case InkToolType.ellipse:
      case InkToolType.diamond:
      case InkToolType.arrow:
      case InkToolType.curvedArrow:
      case InkToolType.line:
      case InkToolType.text:
      case InkToolType.stickyNote:
      case InkToolType.frame:
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
  /// Matches GoodNotes selection ergonomics:
  /// A stroke is selected if its center is inside, or ANY point is inside,
  /// or if any line segment intersects the lasso polygon, or if the lasso
  /// loop encloses the bounding box.
  static bool isStrokeSelectedByLasso(InkStroke stroke, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    final bounds = computeBounds(stroke);

    // 1. Center point inside
    if (isPointInPolygon(bounds.center, polygon)) {
      return true;
    }

    // 2. Any corner of bounding box inside
    if (isPointInPolygon(bounds.topLeft, polygon) ||
        isPointInPolygon(bounds.topRight, polygon) ||
        isPointInPolygon(bounds.bottomLeft, polygon) ||
        isPointInPolygon(bounds.bottomRight, polygon)) {
      return true;
    }

    if (stroke.points.isEmpty) return false;

    // 3. Any discrete stroke point inside
    for (final p in stroke.points) {
      if (isPointInPolygon(Offset(p.x, p.y), polygon)) {
        return true;
      }
    }

    // 4. Line segment intersection between stroke segments and polygon edges
    final polyLen = polygon.length;
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final s1 = Offset(stroke.points[i].x, stroke.points[i].y);
      final s2 = Offset(stroke.points[i + 1].x, stroke.points[i + 1].y);
      for (int j = 0, k = polyLen - 1; j < polyLen; k = j++) {
        final p1 = polygon[k];
        final p2 = polygon[j];
        if (_segmentsIntersect(s1, s2, p1, p2)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _segmentsIntersect(Offset p1, Offset p2, Offset p3, Offset p4) {
    final d1 = _crossProduct(p3, p4, p1);
    final d2 = _crossProduct(p3, p4, p2);
    final d3 = _crossProduct(p1, p2, p3);
    final d4 = _crossProduct(p1, p2, p4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }
    return false;
  }

  static double _crossProduct(Offset a, Offset b, Offset c) {
    return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
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

  /// Transforms an [InkStroke] with translation, scale around origin, rotation, and optional recolor.
  static InkStroke transformStroke(
    InkStroke stroke, {
    Offset delta = Offset.zero,
    double scaleX = 1.0,
    double scaleY = 1.0,
    double deltaAngle = 0.0,
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

    Rect newBounds;
    if (stroke.bounds != null && stroke.points.length <= 2) {
      final b = stroke.bounds!;
      final newLeft = ox + (b.left - ox) * scaleX + delta.dx;
      final newTop = oy + (b.top - oy) * scaleY + delta.dy;
      final newRight = ox + (b.right - ox) * scaleX + delta.dx;
      final newBottom = oy + (b.bottom - oy) * scaleY + delta.dy;
      newBounds = Rect.fromLTRB(
        math.min(newLeft, newRight),
        math.min(newTop, newBottom),
        math.max(newLeft, newRight),
        math.max(newTop, newBottom),
      );
    } else {
      newBounds = computeBoundsFromPoints(newPoints, newBaseWidth);
    }

    final newFontSize = stroke.fontSize != null
        ? (stroke.fontSize! * (avgScale == 0 ? 1.0 : avgScale)).clamp(
            8.0,
            120.0,
          )
        : null;

    return stroke.copyWith(
      points: newPoints,
      baseWidth: newBaseWidth,
      color: newColor ?? stroke.color,
      bounds: newBounds,
      fontSize: newFontSize,
      angle: stroke.angle + deltaAngle,
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

  /// Converts a list of InkPoints into a closed vector Path using perfect_freehand
  static Path tessellatePoints(
    List<InkPoint> points,
    InkToolType tool,
    double baseWidth,
  ) {
    if (points.isEmpty) return Path();

    if (points.length == 1) {
      final p = points.first;
      final radius = (baseWidth * (0.5 + p.pressure * 0.5)) / 2;
      return Path()
        ..addOval(Rect.fromCircle(center: Offset(p.x, p.y), radius: radius));
    }

    final pointVectors = points
        .map((p) => PointVector(p.x, p.y, p.pressure))
        .toList();

    final options = _getOptionsForTool(tool, baseWidth);
    final outline = getStroke(pointVectors, options: options);

    return outlineToPath(outline);
  }

  /// Converts an InkStroke into a closed vector Path using perfect_freehand
  static Path tessellate(InkStroke stroke) {
    return tessellatePoints(stroke.points, stroke.tool, stroke.baseWidth);
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
