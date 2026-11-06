import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight custom painter for circular habit and streak completion rings.
/// Adheres strictly to the < 150 lines constraint and optimizes paint boundaries.
class HabitProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const HabitProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(
      0.0,
      (math.min(size.width, size.height) - stroke) / 2,
    );

    if (radius <= 0) return;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    // Foreground progress arc
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final sweepAngle = clamped * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at 12 o'clock
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HabitProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Standalone habit progress ring widget with isolated repaint boundary.
class HabitProgressRing extends StatelessWidget {
  final double progress;
  final Color progressColor;
  final Color? trackColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const HabitProgressRing({
    super.key,
    required this.progress,
    required this.progressColor,
    this.trackColor,
    this.size = 36.0,
    this.strokeWidth = 3.5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackTrack = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: HabitProgressRingPainter(
            progress: progress,
            trackColor: trackColor ?? fallbackTrack,
            progressColor: progressColor,
            strokeWidth: strokeWidth,
          ),
          child: child != null ? Center(child: child) : null,
        ),
      ),
    );
  }
}
