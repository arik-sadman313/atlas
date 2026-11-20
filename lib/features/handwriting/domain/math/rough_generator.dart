import 'dart:math' as math;
import 'dart:ui';

/// Generates organic, hand-drawn vector paths and sketchy hatching fills
/// inspired by the Rough.js algorithms that power Excalidraw.
///
/// Deterministic seeded randomness ensures shapes retain stable,
/// jitter-free visual aesthetics across frame redraws and zoom operations.
class RoughGenerator {
  /// Converts a continuous [Path] into a dashed or dotted path based on [strokeStyle].
  static Path applyStrokeStyle(Path path, String? strokeStyle) {
    if (strokeStyle == null || strokeStyle == 'solid') {
      return path;
    }

    final dashedPath = Path();
    final isDotted = strokeStyle == 'dotted';
    final dashLength = isDotted ? 2.0 : 7.0;
    final spaceLength = isDotted ? 4.0 : 5.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : spaceLength;
        final next = math.min(distance + length, metric.length);
        if (draw) {
          dashedPath.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  /// Builds a hand-drawn sketchy line connecting [p1] and [p2].
  ///
  /// Uses a double-pass technique with slight endpoint overshoot to achieve
  /// the signature architect / hand-sketched aesthetic.
  static Path buildRoughLine(
    Offset p1,
    Offset p2, {
    double roughness = 1.0,
    int seed = 42,
    double overshoot = 2.5,
    String? strokeStyle,
  }) {
    final path = Path();
    if (roughness <= 0.05) {
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      return applyStrokeStyle(path, strokeStyle);
    }

    final rng = math.Random(seed);
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 1.0) {
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      return applyStrokeStyle(path, strokeStyle);
    }

    final ux = dx / length;
    final uy = dy / length;
    final perpX = -uy;
    final perpY = ux;

    final maxOffset = math.min(length * 0.08, 2.5 * roughness);
    final over = math.min(length * 0.1, overshoot * roughness);

    // Pass 1: Primary organic stroke with overshoot
    final start1 = Offset(p1.dx - ux * over * 0.5, p1.dy - uy * over * 0.5);
    final end1 = Offset(p2.dx + ux * over, p2.dy + uy * over);
    final mid1 = Offset(
      (p1.dx + p2.dx) / 2 + perpX * (rng.nextDouble() - 0.5) * maxOffset * 1.5,
      (p1.dy + p2.dy) / 2 + perpY * (rng.nextDouble() - 0.5) * maxOffset * 1.5,
    );
    path.moveTo(start1.dx, start1.dy);
    path.quadraticBezierTo(mid1.dx, mid1.dy, end1.dx, end1.dy);

    // Pass 2: Secondary reinforcing sketch line
    if (roughness > 0.4) {
      final start2 = Offset(p1.dx + ux * over * 0.3, p1.dy + uy * over * 0.3);
      final end2 = Offset(p2.dx - ux * over * 0.2, p2.dy - uy * over * 0.2);
      final mid2 = Offset(
        (p1.dx + p2.dx) / 2 -
            perpX * (rng.nextDouble() - 0.5) * maxOffset * 1.2,
        (p1.dy + p2.dy) / 2 -
            perpY * (rng.nextDouble() - 0.5) * maxOffset * 1.2,
      );
      path.moveTo(start2.dx, start2.dy);
      path.quadraticBezierTo(mid2.dx, mid2.dy, end2.dx, end2.dy);
    }

    return applyStrokeStyle(path, strokeStyle);
  }

  /// Builds a sketchy hand-drawn rectangle with 4 overshooting edges and optional round corners.
  static Path buildRoughRectangle(
    Rect rect, {
    double roughness = 1.0,
    int seed = 101,
    String? roundness,
    String? strokeStyle,
  }) {
    final isRound = roundness == 'round';
    final radius = isRound
        ? math.min(12.0, math.min(rect.width, rect.height) * 0.2)
        : 0.0;

    if (roughness <= 0.05) {
      final path = Path();
      if (isRound) {
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
      } else {
        path.addRect(rect);
      }
      return applyStrokeStyle(path, strokeStyle);
    }

    final path = Path();

    if (!isRound) {
      // 4 edges with unique sub-seeds
      path.addPath(
        buildRoughLine(
          rect.topLeft,
          rect.topRight,
          roughness: roughness,
          seed: seed + 1,
        ),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(
          rect.topRight,
          rect.bottomRight,
          roughness: roughness,
          seed: seed + 2,
        ),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(
          rect.bottomRight,
          rect.bottomLeft,
          roughness: roughness,
          seed: seed + 3,
        ),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(
          rect.bottomLeft,
          rect.topLeft,
          roughness: roughness,
          seed: seed + 4,
        ),
        Offset.zero,
      );
    } else {
      // Rounded edges with sketchy arcs
      final tl1 = Offset(rect.left + radius, rect.top);
      final tr1 = Offset(rect.right - radius, rect.top);
      final tr2 = Offset(rect.right, rect.top + radius);
      final br1 = Offset(rect.right, rect.bottom - radius);
      final br2 = Offset(rect.right - radius, rect.bottom);
      final bl1 = Offset(rect.left + radius, rect.bottom);
      final bl2 = Offset(rect.left, rect.bottom - radius);
      final tl2 = Offset(rect.left, rect.top + radius);

      path.addPath(
        buildRoughLine(tl1, tr1, roughness: roughness, seed: seed + 1),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(tr2, br1, roughness: roughness, seed: seed + 2),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(br2, bl1, roughness: roughness, seed: seed + 3),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(bl2, tl2, roughness: roughness, seed: seed + 4),
        Offset.zero,
      );

      // Corner arcs
      path.moveTo(tr1.dx, tr1.dy);
      path.quadraticBezierTo(rect.right, rect.top, tr2.dx, tr2.dy);
      path.moveTo(br1.dx, br1.dy);
      path.quadraticBezierTo(rect.right, rect.bottom, br2.dx, br2.dy);
      path.moveTo(bl1.dx, bl1.dy);
      path.quadraticBezierTo(rect.left, rect.bottom, bl2.dx, bl2.dy);
      path.moveTo(tl2.dx, tl2.dy);
      path.quadraticBezierTo(rect.left, rect.top, tl1.dx, tl1.dy);
    }

    return applyStrokeStyle(path, strokeStyle);
  }

  /// Builds a sketchy hand-drawn diamond (rhombus).
  static Path buildRoughDiamond(
    Rect rect, {
    double roughness = 1.0,
    int seed = 202,
    String? strokeStyle,
  }) {
    if (roughness <= 0.05) {
      final p = Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
      return applyStrokeStyle(p, strokeStyle);
    }

    final path = Path();
    final top = Offset(rect.center.dx, rect.top);
    final right = Offset(rect.right, rect.center.dy);
    final bottom = Offset(rect.center.dx, rect.bottom);
    final left = Offset(rect.left, rect.center.dy);

    path.addPath(
      buildRoughLine(top, right, roughness: roughness, seed: seed + 1),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(right, bottom, roughness: roughness, seed: seed + 2),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(bottom, left, roughness: roughness, seed: seed + 3),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(left, top, roughness: roughness, seed: seed + 4),
      Offset.zero,
    );

    return applyStrokeStyle(path, strokeStyle);
  }

  /// Builds a sketchy hand-drawn ellipse/circle using dual sinusoidal arcs.
  static Path buildRoughEllipse(
    Rect rect, {
    double roughness = 1.0,
    int seed = 303,
    String? strokeStyle,
  }) {
    if (roughness <= 0.05) {
      return applyStrokeStyle(Path()..addOval(rect), strokeStyle);
    }

    final path = Path();
    final rng = math.Random(seed);
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    const segments = 24;
    final maxJitter = math.min(math.min(rx, ry) * 0.1, 2.0 * roughness);

    for (int step = 0; step < 2; step++) {
      final startAngle = step == 0 ? 0.0 : math.pi * 0.08;
      final endAngle = startAngle + math.pi * 2 + (step == 0 ? 0.25 : 0.15);
      final angleStep = (endAngle - startAngle) / segments;

      var first = true;
      for (int i = 0; i <= segments; i++) {
        final angle = startAngle + i * angleStep;
        final jitterR = (rng.nextDouble() - 0.5) * maxJitter;
        final curRx = rx + jitterR;
        final curRy = ry + jitterR;
        final x = cx + curRx * math.cos(angle);
        final y = cy + curRy * math.sin(angle);

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    return applyStrokeStyle(path, strokeStyle);
  }

  /// Builds a sketchy hand-drawn directional arrow (straight or curved),
  /// with customizable start and end arrowheads.
  static Path buildRoughArrow(
    Offset start,
    Offset end, {
    double roughness = 1.0,
    int seed = 404,
    bool isCurved = false,
    String startArrowhead = 'none',
    String endArrowhead = 'arrow',
    double arrowheadLength = 18.0,
    double arrowheadAngle = math.pi / 6, // 30 degrees
    String? strokeStyle,
  }) {
    final path = Path();
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length < 2.0) {
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
      return path;
    }

    Offset midPoint;
    double endAngle;
    double startAngle;

    if (isCurved) {
      final ux = dx / length;
      final uy = dy / length;
      final perpX = -uy;
      final perpY = ux;
      final curveOffset = math.min(length * 0.25, 40.0);
      midPoint = Offset(
        (start.dx + end.dx) / 2 + perpX * curveOffset,
        (start.dy + end.dy) / 2 + perpY * curveOffset,
      );

      // Curved shaft using quadratic bezier
      final shaft = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(midPoint.dx, midPoint.dy, end.dx, end.dy);
      path.addPath(applyStrokeStyle(shaft, strokeStyle), Offset.zero);

      endAngle = math.atan2(end.dy - midPoint.dy, end.dx - midPoint.dx);
      startAngle = math.atan2(start.dy - midPoint.dy, start.dx - midPoint.dx);
    } else {
      // Straight shaft
      path.addPath(
        buildRoughLine(
          start,
          end,
          roughness: roughness,
          seed: seed,
          strokeStyle: strokeStyle,
        ),
        Offset.zero,
      );
      endAngle = math.atan2(dy, dx);
      startAngle = math.atan2(-dy, -dx);
    }

    final len = math.min(arrowheadLength, length * 0.35);

    // End Arrowhead
    _buildArrowhead(
      path,
      end,
      endAngle,
      len,
      endArrowhead,
      roughness,
      seed + 10,
    );

    // Start Arrowhead
    if (startArrowhead != 'none') {
      _buildArrowhead(
        path,
        start,
        startAngle,
        len,
        startArrowhead,
        roughness,
        seed + 30,
      );
    }

    return path;
  }

  static void _buildArrowhead(
    Path path,
    Offset tip,
    double angle,
    double len,
    String type,
    double roughness,
    int seed,
  ) {
    if (type == 'none') return;

    if (type == 'arrow') {
      const arrowheadAngle = math.pi / 6;
      final barb1 = Offset(
        tip.dx - len * math.cos(angle - arrowheadAngle),
        tip.dy - len * math.sin(angle - arrowheadAngle),
      );
      final barb2 = Offset(
        tip.dx - len * math.cos(angle + arrowheadAngle),
        tip.dy - len * math.sin(angle + arrowheadAngle),
      );

      path.addPath(
        buildRoughLine(tip, barb1, roughness: roughness, seed: seed),
        Offset.zero,
      );
      path.addPath(
        buildRoughLine(tip, barb2, roughness: roughness, seed: seed + 1),
        Offset.zero,
      );
    } else if (type == 'bar') {
      final perpX = -math.sin(angle);
      final perpY = math.cos(angle);
      final bar1 = Offset(
        tip.dx + perpX * (len * 0.6),
        tip.dy + perpY * (len * 0.6),
      );
      final bar2 = Offset(
        tip.dx - perpX * (len * 0.6),
        tip.dy - perpY * (len * 0.6),
      );
      path.addPath(
        buildRoughLine(bar1, bar2, roughness: roughness, seed: seed),
        Offset.zero,
      );
    } else if (type == 'dot') {
      final radius = len * 0.35;
      final dotCenter = Offset(
        tip.dx - radius * math.cos(angle),
        tip.dy - radius * math.sin(angle),
      );
      path.addOval(Rect.fromCircle(center: dotCenter, radius: radius));
    }
  }

  /// Builds a hand-drawn Sticky Post-It Note card with folded paper corner.
  static Path buildRoughStickyNote(
    Rect rect, {
    double roughness = 1.0,
    int seed = 606,
  }) {
    final path = Path();
    const foldSize = 20.0;
    final brFold1 = Offset(rect.right - foldSize, rect.bottom);
    final brFold2 = Offset(rect.right, rect.bottom - foldSize);

    // Outline path (with folded corner at bottom-right)
    path.addPath(
      buildRoughLine(
        rect.topLeft,
        rect.topRight,
        roughness: roughness,
        seed: seed + 1,
      ),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(
        rect.topRight,
        brFold2,
        roughness: roughness,
        seed: seed + 2,
      ),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(brFold2, brFold1, roughness: roughness, seed: seed + 3),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(
        brFold1,
        rect.bottomLeft,
        roughness: roughness,
        seed: seed + 4,
      ),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(
        rect.bottomLeft,
        rect.topLeft,
        roughness: roughness,
        seed: seed + 5,
      ),
      Offset.zero,
    );

    // Inner fold flap
    final foldInner = Offset(rect.right - foldSize, rect.bottom - foldSize);
    path.addPath(
      buildRoughLine(brFold1, foldInner, roughness: roughness, seed: seed + 6),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(foldInner, brFold2, roughness: roughness, seed: seed + 7),
      Offset.zero,
    );

    return path;
  }

  /// Builds an Excalidraw Frame element with top title header tab.
  static Path buildRoughFrame(
    Rect rect, {
    double roughness = 1.0,
    int seed = 707,
  }) {
    final path = Path();
    // Outer bounding dashed frame
    path.addPath(
      buildRoughRectangle(
        rect,
        roughness: roughness,
        seed: seed,
        strokeStyle: 'dashed',
      ),
      Offset.zero,
    );

    // Header tab banner
    const tabHeight = 24.0;
    final tabWidth = math.min(180.0, rect.width * 0.6);
    final tabRect = Rect.fromLTWH(
      rect.left,
      rect.top - tabHeight,
      tabWidth,
      tabHeight,
    );
    path.addPath(
      buildRoughRectangle(
        tabRect,
        roughness: roughness,
        seed: seed + 10,
        roundness: 'round',
      ),
      Offset.zero,
    );

    return path;
  }

  /// Builds organic hand-drawn diagonal hatching lines (Hachure),
  /// cross-hatching, or stippled dots for shape interiors.
  static Path buildHachureLines(
    Rect rect, {
    double spacing = 12.0,
    bool crossHatch = false,
    bool dots = false,
    double roughness = 1.0,
    int seed = 505,
  }) {
    final path = Path();
    if (rect.width <= 2 || rect.height <= 2) return path;

    final rng = math.Random(seed);

    if (dots) {
      // Stippled sketchy dots grid
      final step = math.max(12.0, spacing);
      for (double y = rect.top + step / 2; y < rect.bottom; y += step) {
        for (double x = rect.left + step / 2; x < rect.right; x += step) {
          final jitterX = (rng.nextDouble() - 0.5) * 3.0 * roughness;
          final jitterY = (rng.nextDouble() - 0.5) * 3.0 * roughness;
          path.addOval(
            Rect.fromCircle(
              center: Offset(x + jitterX, y + jitterY),
              radius: 1.5,
            ),
          );
        }
      }
      return path;
    }

    final double diagonal = math.sqrt(
      rect.width * rect.width + rect.height * rect.height,
    );
    final int lineCount = (diagonal / spacing).ceil() + 2;

    // Pass 1: 45 degree forward hatching
    for (int i = -lineCount ~/ 2; i <= lineCount; i++) {
      final offset = i * spacing;
      final start = Offset(rect.left + offset, rect.top - spacing);
      final end = Offset(
        rect.left + offset + rect.height,
        rect.bottom + spacing,
      );

      final jitter = (rng.nextDouble() - 0.5) * 1.5 * roughness;
      path.moveTo(start.dx + jitter, start.dy);
      path.lineTo(end.dx - jitter, end.dy);
    }

    // Pass 2: -45 degree backward cross-hatching if enabled
    if (crossHatch) {
      for (int i = -lineCount ~/ 2; i <= lineCount; i++) {
        final offset = i * spacing;
        final start = Offset(rect.right - offset, rect.top - spacing);
        final end = Offset(
          rect.right - offset - rect.height,
          rect.bottom + spacing,
        );

        final jitter = (rng.nextDouble() - 0.5) * 1.5 * roughness;
        path.moveTo(start.dx + jitter, start.dy);
        path.lineTo(end.dx - jitter, end.dy);
      }
    }

    return path;
  }
}
