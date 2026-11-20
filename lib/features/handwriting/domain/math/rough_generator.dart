import 'dart:math' as math;
import 'dart:ui';

/// Generates organic, hand-drawn vector paths and sketchy hatching fills
/// inspired by the Rough.js algorithms that power Excalidraw.
///
/// Deterministic seeded randomness ensures shapes retain stable,
/// jitter-free visual aesthetics across frame redraws and zoom operations.
class RoughGenerator {
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
  }) {
    final path = Path();
    if (roughness <= 0.05) {
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      return path;
    }

    final rng = math.Random(seed);
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 1.0) {
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      return path;
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

    return path;
  }

  /// Builds a sketchy hand-drawn rectangle with 4 overshooting edges.
  static Path buildRoughRectangle(
    Rect rect, {
    double roughness = 1.0,
    int seed = 101,
  }) {
    if (roughness <= 0.05) {
      return Path()..addRect(rect);
    }

    final path = Path();
    final pTopLeft = rect.topLeft;
    final pTopRight = rect.topRight;
    final pBottomRight = rect.bottomRight;
    final pBottomLeft = rect.bottomLeft;

    // 4 edges with unique sub-seeds
    path.addPath(
      buildRoughLine(
        pTopLeft,
        pTopRight,
        roughness: roughness,
        seed: seed + 1,
      ),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(
        pTopRight,
        pBottomRight,
        roughness: roughness,
        seed: seed + 2,
      ),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(
        pBottomRight,
        pBottomLeft,
        roughness: roughness,
        seed: seed + 3,
      ),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(
        pBottomLeft,
        pTopLeft,
        roughness: roughness,
        seed: seed + 4,
      ),
      Offset.zero,
    );

    return path;
  }

  /// Builds a sketchy hand-drawn diamond (rhombus).
  static Path buildRoughDiamond(
    Rect rect, {
    double roughness = 1.0,
    int seed = 202,
  }) {
    if (roughness <= 0.05) {
      return Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
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

    return path;
  }

  /// Builds a sketchy hand-drawn ellipse/circle using dual sinusoidal arcs.
  static Path buildRoughEllipse(
    Rect rect, {
    double roughness = 1.0,
    int seed = 303,
  }) {
    if (roughness <= 0.05) {
      return Path()..addOval(rect);
    }

    final path = Path();
    final rng = math.Random(seed);
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    const segments = 24;
    final maxJitter = math.min(math.min(rx, ry) * 0.1, 2.0 * roughness);

    // Pass 1: Ellipse loop 1
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

    return path;
  }

  /// Builds a sketchy hand-drawn directional arrow.
  static Path buildRoughArrow(
    Offset start,
    Offset end, {
    double roughness = 1.0,
    int seed = 404,
    double arrowheadLength = 18.0,
    double arrowheadAngle = math.pi / 6, // 30 degrees
  }) {
    final path = Path();
    // Shaft line
    path.addPath(
      buildRoughLine(start, end, roughness: roughness, seed: seed),
      Offset.zero,
    );

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    final len = math.min(
      arrowheadLength,
      math.sqrt(dx * dx + dy * dy) * 0.35,
    );

    final barb1 = Offset(
      end.dx - len * math.cos(angle - arrowheadAngle),
      end.dy - len * math.sin(angle - arrowheadAngle),
    );
    final barb2 = Offset(
      end.dx - len * math.cos(angle + arrowheadAngle),
      end.dy - len * math.sin(angle + arrowheadAngle),
    );

    // Arrowhead barbs
    path.addPath(
      buildRoughLine(end, barb1, roughness: roughness, seed: seed + 10),
      Offset.zero,
    );
    path.addPath(
      buildRoughLine(end, barb2, roughness: roughness, seed: seed + 20),
      Offset.zero,
    );

    return path;
  }

  /// Builds organic hand-drawn diagonal hatching lines (Hachure)
  /// or cross-hatching for shape interiors.
  static Path buildHachureLines(
    Rect rect, {
    double spacing = 12.0,
    bool crossHatch = false,
    double roughness = 1.0,
    int seed = 505,
  }) {
    final path = Path();
    if (rect.width <= 2 || rect.height <= 2) return path;

    final rng = math.Random(seed);
    final double diagonal = math.sqrt(
      rect.width * rect.width + rect.height * rect.height,
    );
    final int lineCount = (diagonal / spacing).ceil() + 2;

    // Pass 1: 45 degree forward hatching
    for (int i = -lineCount ~/ 2; i <= lineCount; i++) {
      final offset = i * spacing;
      final start = Offset(rect.left + offset, rect.top - spacing);
      final end = Offset(rect.left + offset + rect.height, rect.bottom + spacing);

      // Jitter endpoints slightly
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
