import 'package:atlas/features/handwriting/domain/math/stroke_tessellator.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StrokeTessellator', () {
    test('tessellates a multi-point stroke into a non-empty Path', () {
      final points = [
        const InkPoint(x: 10, y: 10, pressure: 0.5, timeOffsetMs: 0),
        const InkPoint(x: 20, y: 30, pressure: 0.7, timeOffsetMs: 10),
        const InkPoint(x: 40, y: 60, pressure: 0.9, timeOffsetMs: 25),
        const InkPoint(x: 70, y: 80, pressure: 0.4, timeOffsetMs: 40),
      ];

      final stroke = InkStroke(
        id: 'stroke_1',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: points,
      );

      final path = StrokeTessellator.tessellate(stroke);

      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.isEmpty, isFalse);
      expect(bounds.left, lessThanOrEqualTo(10.0));
      expect(bounds.top, lessThanOrEqualTo(10.0));
      expect(bounds.right, greaterThanOrEqualTo(70.0));
      expect(bounds.bottom, greaterThanOrEqualTo(80.0));
    });

    test('tessellates a single point as a dot', () {
      final stroke = InkStroke(
        id: 'dot_1',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 4.0,
        points: const [InkPoint(x: 50, y: 50, pressure: 0.5, timeOffsetMs: 0)],
      );

      final path = StrokeTessellator.tessellate(stroke);
      final bounds = path.getBounds();

      expect(bounds.isEmpty, isFalse);
      expect(bounds.contains(const Offset(50, 50)), isTrue);
    });

    test('returns empty Path when points list is empty', () {
      final stroke = InkStroke(
        id: 'empty_stroke',
        tool: InkToolType.ballpointPen,
        color: 0xFF000000,
        baseWidth: 2.0,
        points: const [],
      );

      final path = StrokeTessellator.tessellate(stroke);
      expect(path.getBounds().isEmpty, isTrue);
    });

    test('tessellates across all Atlas ink tools without error', () {
      final samplePoints = [
        const InkPoint(x: 100, y: 100, pressure: 0.5, timeOffsetMs: 0),
        const InkPoint(x: 150, y: 120, pressure: 0.8, timeOffsetMs: 15),
        const InkPoint(x: 200, y: 110, pressure: 0.6, timeOffsetMs: 30),
      ];

      for (final tool in InkToolType.values) {
        final stroke = InkStroke(
          id: 'tool_test_${tool.name}',
          tool: tool,
          color: 0xFF1D4ED8,
          baseWidth: 4.0,
          points: samplePoints,
        );

        final path = StrokeTessellator.tessellate(stroke);
        expect(path.getBounds().isEmpty, isFalse);
      }
    });

    test('computedBounds correctly pads bounding box by baseWidth', () {
      final stroke = InkStroke(
        id: 'bounds_test',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 6.0,
        points: const [
          InkPoint(x: 100, y: 200, pressure: 0.5, timeOffsetMs: 0),
          InkPoint(x: 300, y: 400, pressure: 0.5, timeOffsetMs: 10),
        ],
      );

      final b = stroke.computedBounds;
      final expectedPadding = stroke.baseWidth * 1.5;
      expect(b.left, equals(100.0 - expectedPadding));
      expect(b.top, equals(200.0 - expectedPadding));
      expect(b.right, equals(300.0 + expectedPadding));
      expect(b.bottom, equals(400.0 + expectedPadding));
    });
  });
}
