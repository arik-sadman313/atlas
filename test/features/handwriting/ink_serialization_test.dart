import 'dart:typed_data';

import 'package:atlas/core/errors/failures.dart';
import 'package:atlas/features/handwriting/data/serializers/ink_binary_serializer.dart';
import 'package:atlas/features/handwriting/data/serializers/ink_json_serializer.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ink Serialization', () {
    late AtlasInkDocument sampleDoc;

    setUp(() {
      final points1 = [
        const InkPoint(x: 10.5, y: 20.25, pressure: 0.6, timeOffsetMs: 0),
        const InkPoint(x: 35.0, y: 50.75, pressure: 0.85, timeOffsetMs: 15),
      ];
      final points2 = [
        const InkPoint(x: 100.0, y: 150.0, pressure: 0.4, timeOffsetMs: 0),
        const InkPoint(x: 120.0, y: 180.0, pressure: 0.7, timeOffsetMs: 22),
      ];

      final stroke1 = InkStroke(
        id: 's_001',
        tool: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
        points: points1,
      );

      final stroke2 = InkStroke(
        id: 's_002',
        tool: InkToolType.highlighter,
        color: 0xFFFACC15,
        baseWidth: 16.0,
        opacity: 0.4,
        blendMode: 'multiply',
        points: points2,
      );

      final layer1 = InkLayer(
        id: 'layer_main',
        name: 'Main Ink',
        strokes: [stroke1],
      );

      final layer2 = InkLayer(
        id: 'layer_highlighter',
        name: 'Highlighters',
        blendMode: 'multiply',
        strokes: [stroke2],
      );

      sampleDoc = AtlasInkDocument(
        version: 1,
        documentId: 'doc_math_01',
        pageNumber: 1,
        width: 1600.0,
        height: 2200.0,
        backgroundTemplate: 'ruled',
        backgroundColor: 0xFFFFFFFF,
        layers: [layer1, layer2],
        metadata: {'author': 'Atlas User', 'subject': 'Calculus'},
      );
    });

    group('InkJsonSerializer', () {
      test('roundtrips AtlasInkDocument to/from JSON string', () {
        final jsonStr = InkJsonSerializer.serialize(sampleDoc);
        expect(jsonStr, contains('doc_math_01'));
        expect(jsonStr, contains('layer_highlighter'));

        final deserialized = InkJsonSerializer.deserialize(jsonStr);

        expect(deserialized.documentId, equals(sampleDoc.documentId));
        expect(deserialized.pageNumber, equals(sampleDoc.pageNumber));
        expect(deserialized.width, equals(sampleDoc.width));
        expect(deserialized.height, equals(sampleDoc.height));
        expect(deserialized.backgroundTemplate, equals('ruled'));
        expect(deserialized.layers.length, equals(2));

        final layer1 = deserialized.layers[0];
        expect(layer1.strokes.length, equals(1));
        expect(layer1.strokes[0].tool, equals(InkToolType.ballpointPen));
        expect(layer1.strokes[0].points.length, equals(2));
        expect(layer1.strokes[0].points[0].x, equals(10.5));

        final layer2 = deserialized.layers[1];
        expect(layer2.blendMode, equals('multiply'));
        expect(layer2.strokes[0].tool, equals(InkToolType.highlighter));
      });

      test('roundtrips from UTF-8 bytes', () {
        final bytes = InkJsonSerializer.serializeToBytes(sampleDoc);
        final deserialized = InkJsonSerializer.deserializeFromBytes(bytes);

        expect(deserialized.documentId, equals(sampleDoc.documentId));
        expect(deserialized.layers.length, equals(2));
      });

      test('throws StorageException on invalid JSON', () {
        expect(
          () => InkJsonSerializer.deserialize('{"invalid_json": true'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('InkBinarySerializer', () {
      test('serializes with ATLASINK magic header and version', () {
        final bytes = InkBinarySerializer.serialize(sampleDoc);

        expect(bytes.length, greaterThan(16));
        // Check magic bytes: 'ATLASINK' (0x41, 0x54, 0x4C, 0x41, 0x53, 0x49, 0x4E, 0x4B)
        expect(
          bytes.sublist(0, 8),
          equals([0x41, 0x54, 0x4C, 0x41, 0x53, 0x49, 0x4E, 0x4B]),
        );
      });

      test('roundtrips AtlasInkDocument accurately via binary format', () {
        final bytes = InkBinarySerializer.serialize(sampleDoc);
        final deserialized = InkBinarySerializer.deserialize(bytes);

        expect(deserialized.documentId, equals(sampleDoc.documentId));
        expect(deserialized.pageNumber, equals(sampleDoc.pageNumber));
        expect(deserialized.width, equals(sampleDoc.width));
        expect(deserialized.height, equals(sampleDoc.height));
        expect(
          deserialized.backgroundTemplate,
          equals(sampleDoc.backgroundTemplate),
        );
        expect(deserialized.backgroundColor, equals(sampleDoc.backgroundColor));
        expect(deserialized.layers.length, equals(sampleDoc.layers.length));

        // Check Stroke 1
        final s1 = deserialized.layers[0].strokes[0];
        expect(s1.id, equals('s_001'));
        expect(s1.tool, equals(InkToolType.ballpointPen));
        expect(s1.color, equals(0xFF18181B));
        expect(s1.baseWidth, closeTo(3.0, 0.001));
        expect(s1.points.length, equals(2));
        expect(s1.points[0].x, closeTo(10.5, 0.001));
        expect(s1.points[0].y, closeTo(20.25, 0.001));
        expect(s1.points[0].pressure, closeTo(0.6, 0.001));

        // Check Stroke 2
        final s2 = deserialized.layers[1].strokes[0];
        expect(s2.id, equals('s_002'));
        expect(s2.tool, equals(InkToolType.highlighter));
        expect(s2.blendMode, equals('multiply'));
        expect(s2.opacity, closeTo(0.4, 0.001));
      });

      test('rejects corrupt binary payload with wrong magic header', () {
        final corruptBytes = Uint8List.fromList([
          0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // Invalid magic
          0x00, 0x01,
        ]);

        expect(
          () => InkBinarySerializer.deserialize(corruptBytes),
          throwsA(isA<StorageException>()),
        );
      });

      test('rejects truncated binary data', () {
        final truncatedBytes = Uint8List.fromList([
          0x41, 0x54, 0x4C, 0x41, // Only 4 bytes
        ]);

        expect(
          () => InkBinarySerializer.deserialize(truncatedBytes),
          throwsA(isA<StorageException>()),
        );
      });
    });
  });
}
