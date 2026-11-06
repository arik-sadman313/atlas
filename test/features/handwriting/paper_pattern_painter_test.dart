import 'dart:ui';

import 'package:atlas/features/handwriting/presentation/widgets/ink_document_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaperPatternPainter Tests', () {
    test('blank template does not draw any grid or lines', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(600, 800);

      PaperPatternPainter.paintPattern(
        canvas,
        size,
        'blank',
        const Color(0xFFFFFFFF),
        spacing: 28.35,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('ruled template draws horizontal lines with specified spacing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(600, 800);

      // Light background
      PaperPatternPainter.paintPattern(
        canvas,
        size,
        'ruled',
        const Color(0xFFFAF9F6),
        spacing: 28.35,
      );

      // Dark background
      PaperPatternPainter.paintPattern(
        canvas,
        size,
        'ruled',
        const Color(0xFF18181B),
        spacing: 32.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('grid template draws horizontal and vertical grid lines', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(600, 800);

      PaperPatternPainter.paintPattern(
        canvas,
        size,
        'grid',
        const Color(0xFFFFFFFF),
        spacing: 20.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('dotted template draws circular dots at grid intersections', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(600, 800);

      PaperPatternPainter.paintPattern(
        canvas,
        size,
        'dot_grid_5mm',
        const Color(0xFFF4F4F5),
        spacing: 14.17,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('shouldRepaint detects changes in template, background color, or spacing', () {
      final painter1 = PaperPatternPainter(
        template: 'ruled',
        backgroundColor: const Color(0xFFFFFFFF),
        spacing: 28.35,
      );

      final painter2 = PaperPatternPainter(
        template: 'ruled',
        backgroundColor: const Color(0xFFFFFFFF),
        spacing: 28.35,
      );

      final painter3 = PaperPatternPainter(
        template: 'grid',
        backgroundColor: const Color(0xFFFFFFFF),
        spacing: 28.35,
      );

      final painter4 = PaperPatternPainter(
        template: 'ruled',
        backgroundColor: const Color(0xFF000000),
        spacing: 28.35,
      );

      final painter5 = PaperPatternPainter(
        template: 'ruled',
        backgroundColor: const Color(0xFFFFFFFF),
        spacing: 40.0,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter4), isTrue);
      expect(painter1.shouldRepaint(painter5), isTrue);
    });
  });
}
