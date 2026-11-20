import 'dart:math' as math;
import 'dart:ui';

import '../models/ink_point.dart';
import '../models/ink_tool.dart';

class DetectedShape {
  final InkToolType type;
  final Rect bounds;
  final Offset start;
  final Offset end;
  final double confidence;

  const DetectedShape({
    required this.type,
    required this.bounds,
    required this.start,
    required this.end,
    required this.confidence,
  });
}

/// Detects geometric intent from freehand stylus/finger input for
/// iPad draw-and-hold shape snapping.
class SmartShapeDetector {
  /// Evaluates whether [points] represent an intentional geometric shape.
  /// Returns `null` if the stroke is arbitrary handwriting or doodle.
  static DetectedShape? detect(List<InkPoint> points) {
    if (points.length < 8) return null;

    final offsets = points.map((p) => Offset(p.x, p.y)).toList();
    final first = offsets.first;
    final last = offsets.last;

    // Calculate bounding box
    double minX = offsets.first.dx;
    double maxX = offsets.first.dx;
    double minY = offsets.first.dy;
    double maxY = offsets.first.dy;

    for (final p in offsets) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
    final diag = math.sqrt(rect.width * rect.width + rect.height * rect.height);
    if (diag < 24.0) return null; // Too small

    final closingDist = (first - last).distance;
    final isClosed = closingDist < math.max(30.0, diag * 0.3);

    if (isClosed) {
      return _detectClosedShape(offsets, rect, diag);
    } else {
      return _detectOpenShape(offsets, rect, first, last);
    }
  }

  static DetectedShape? _detectClosedShape(
    List<Offset> pts,
    Rect bounds,
    double diag,
  ) {
    final center = bounds.center;
    final rx = bounds.width / 2;
    final ry = bounds.height / 2;

    if (rx < 6.0 || ry < 6.0) return null;

    // 1. Check for sharp corners first (Rectangles & Diamonds)
    final corners = _findCorners(pts);
    if (corners.length >= 3 && corners.length <= 6) {
      final aspectRatio = bounds.width / bounds.height;
      if (aspectRatio > 0.15 && aspectRatio < 6.5) {
        // Distinguish diamond vs rectangle by checking corner positions
        final cornerNearTop = corners.any(
          (c) =>
              (c.dy - bounds.top).abs() < bounds.height * 0.15 &&
              (c.dx - bounds.center.dx).abs() < bounds.width * 0.25,
        );
        final cornerNearBottom = corners.any(
          (c) =>
              (c.dy - bounds.bottom).abs() < bounds.height * 0.15 &&
              (c.dx - bounds.center.dx).abs() < bounds.width * 0.25,
        );

        if (cornerNearTop && cornerNearBottom) {
          return DetectedShape(
            type: InkToolType.diamond,
            bounds: bounds,
            start: bounds.topLeft,
            end: bounds.bottomRight,
            confidence: 0.88,
          );
        }

        return DetectedShape(
          type: InkToolType.rectangle,
          bounds: bounds,
          start: bounds.topLeft,
          end: bounds.bottomRight,
          confidence: 0.90,
        );
      }
    }

    // 2. Check circularity / ellipse fit (Circles & Ellipses)
    double totalEllipseDiff = 0.0;
    for (final p in pts) {
      final dx = (p.dx - center.dx) / rx;
      final dy = (p.dy - center.dy) / ry;
      final normalizedDist = math.sqrt(dx * dx + dy * dy);
      totalEllipseDiff += (normalizedDist - 1.0).abs();
    }
    final avgEllipseError = totalEllipseDiff / pts.length;

    if (avgEllipseError < 0.25) {
      return DetectedShape(
        type: InkToolType.ellipse,
        bounds: bounds,
        start: bounds.topLeft,
        end: bounds.bottomRight,
        confidence: 1.0 - avgEllipseError,
      );
    }

    return null;
  }

  static DetectedShape? _detectOpenShape(
    List<Offset> pts,
    Rect bounds,
    Offset first,
    Offset last,
  ) {
    final chordLen = (last - first).distance;
    if (chordLen < 20.0) return null;

    // Check if points stay close to the straight chord connecting first and last
    final dx = last.dx - first.dx;
    final dy = last.dy - first.dy;

    double maxDeviation = 0.0;
    for (int i = 1; i < pts.length - 1; i++) {
      final p = pts[i];
      // Perpendicular distance from p to line(first, last)
      final num =
          ((dy * p.dx - dx * p.dy + last.dx * first.dy - last.dy * first.dx))
              .abs();
      final dist = num / chordLen;
      if (dist > maxDeviation) {
        maxDeviation = dist;
      }
    }

    final deviationRatio = maxDeviation / chordLen;

    // Straight line
    if (deviationRatio < 0.15) {
      return DetectedShape(
        type: InkToolType.line,
        bounds: bounds,
        start: first,
        end: last,
        confidence: 1.0 - deviationRatio,
      );
    }

    // Check for Arrow: straight shaft with a hook or barb at the end
    if (pts.length >= 12) {
      final shaftEndIndex = (pts.length * 0.80).toInt();
      final shaftFirst = pts.first;
      final shaftLast = pts[shaftEndIndex];
      final shaftChord = (shaftLast - shaftFirst).distance;

      if (shaftChord > 24.0) {
        final sdx = shaftLast.dx - shaftFirst.dx;
        final sdy = shaftLast.dy - shaftFirst.dy;

        double shaftMaxDev = 0.0;
        for (int i = 1; i < shaftEndIndex; i++) {
          final p = pts[i];
          final num =
              ((sdy * p.dx -
                      sdx * p.dy +
                      shaftLast.dx * shaftFirst.dy -
                      shaftLast.dy * shaftFirst.dx))
                  .abs();
          final dist = num / shaftChord;
          if (dist > shaftMaxDev) shaftMaxDev = dist;
        }

        if (shaftMaxDev / shaftChord < 0.18) {
          // Shaft is straight, now check if the tail hooks sharply
          final barb = pts.sublist(shaftEndIndex);
          final barbDist = (barb.last - shaftLast).distance;
          if (barbDist > 8.0) {
            return DetectedShape(
              type: InkToolType.arrow,
              bounds: bounds,
              start: first,
              end: shaftLast,
              confidence: 0.82,
            );
          }
        }
      }
    }

    return null;
  }

  static List<Offset> _findCorners(List<Offset> pts) {
    final corners = <Offset>[];
    if (pts.length < 10) return corners;

    const step = 4;
    for (int i = step; i < pts.length - step; i += 2) {
      final pPrev = pts[i - step];
      final pCurr = pts[i];
      final pNext = pts[i + step];

      final v1 = pCurr - pPrev;
      final v2 = pNext - pCurr;

      final dot = v1.dx * v2.dx + v1.dy * v2.dy;
      final m1 = v1.distance;
      final m2 = v2.distance;
      if (m1 > 0 && m2 > 0) {
        final cosAngle = (dot / (m1 * m2)).clamp(-1.0, 1.0);
        final angle = math.acos(cosAngle);
        // Angle deviation > 45 degrees
        if (angle > math.pi * 0.3) {
          corners.add(pCurr);
        }
      }
    }
    return corners;
  }
}
