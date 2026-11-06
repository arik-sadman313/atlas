import 'package:atlas/features/handwriting/domain/interop/pencil_kit_converter.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PencilKitConverter - Bidirectional Interoperability', () {
    test('Direction A: Native PK stroke dictionaries -> AtlasInkDocument -> PK dictionaries', () {
      final pkStrokesInput = <Map<String, dynamic>>[
        {
          'id': 'pk_stroke_1',
          'tool': 'pen',
          'color': 0xFF003366,
          'baseWidth': 4.5,
          'opacity': 1.0,
          'blendMode': 'srcOver',
          'points': [
            {
              'x': 100.5,
              'y': 200.25,
              'pressure': 0.65,
              'tiltAzimuth': 0.785,
              'tiltAltitude': 1.12,
              'timeOffsetMs': 120,
            },
            {
              'x': 115.0,
              'y': 210.75,
              'pressure': 0.82,
              'tiltAzimuth': 0.790,
              'tiltAltitude': 1.10,
              'timeOffsetMs': 135,
            },
          ],
        },
        {
          'id': 'pk_stroke_hl',
          'tool': 'marker',
          'color': 0xFFFACC15,
          'baseWidth': 18.0,
          'opacity': 0.4,
          'blendMode': 'multiply',
          'points': [
            {
              'x': 50.0,
              'y': 80.0,
              'pressure': 0.5,
              'tiltAzimuth': 0.0,
              'tiltAltitude': 1.57,
              'timeOffsetMs': 0,
            },
            {
              'x': 250.0,
              'y': 80.0,
              'pressure': 0.5,
              'tiltAzimuth': 0.0,
              'tiltAltitude': 1.57,
              'timeOffsetMs': 50,
            },
          ],
        },
      ];

      // Convert PK dictionaries to AtlasInkDocument
      final doc = PencilKitConverter.pencilKitStrokesToDocument(
        pkStrokesInput,
        documentId: 'doc_pk_test',
        pageNumber: 1,
      );

      expect(doc.documentId, equals('doc_pk_test'));
      expect(doc.totalStrokeCount, equals(2));

      // Verify layer separation: highlighter into multiply layer, pen into default layer
      final hlLayer = doc.layers.firstWhere((l) => l.blendMode == 'multiply');
      final penLayer = doc.layers.firstWhere((l) => l.blendMode != 'multiply');

      expect(hlLayer.strokes.length, equals(1));
      expect(hlLayer.strokes.first.tool, equals(InkToolType.highlighter));
      expect(penLayer.strokes.length, equals(1));
      expect(penLayer.strokes.first.tool, equals(InkToolType.ballpointPen));

      // Convert back to PK dictionaries
      final roundTripPkStrokes = PencilKitConverter.documentToPencilKitStrokes(
        doc,
      );
      expect(roundTripPkStrokes.length, equals(2));

      final roundTripPen = roundTripPkStrokes.firstWhere(
        (s) => s['id'] == 'pk_stroke_1',
      );
      expect(roundTripPen['color'], equals(0xFF003366));
      expect(roundTripPen['baseWidth'], equals(4.5));
      expect(roundTripPen['tool'], equals('ballpointPen'));

      final points = roundTripPen['points'] as List;
      expect(points.length, equals(2));
      expect(points[0]['x'], equals(100.5));
      expect(points[0]['y'], equals(200.25));
      expect(points[0]['pressure'], closeTo(0.65, 0.001));
      expect(points[0]['tiltAzimuth'], closeTo(0.785, 0.001));
      expect(points[0]['tiltAltitude'], closeTo(1.12, 0.001));
      expect(points[0]['timeOffsetMs'], equals(120.0));
    });

    test('Direction B: Linux portable ink -> PK dictionaries -> reconstructed document', () {
      final originalStroke = InkStroke(
        id: 'linux_stroke_1',
        tool: InkToolType.fountainPen,
        color: 0xFF1E293B,
        baseWidth: 3.2,
        opacity: 0.95,
        blendMode: 'srcOver',
        points: const [
          InkPoint(
            x: 42.0,
            y: 84.0,
            pressure: 0.45,
            tiltAzimuth: 0.12,
            tiltAltitude: 1.45,
            timeOffsetMs: 10,
          ),
          InkPoint(
            x: 48.0,
            y: 92.0,
            pressure: 0.75,
            tiltAzimuth: 0.15,
            tiltAltitude: 1.40,
            timeOffsetMs: 25,
          ),
          InkPoint(
            x: 56.0,
            y: 105.0,
            pressure: 0.60,
            tiltAzimuth: 0.18,
            tiltAltitude: 1.42,
            timeOffsetMs: 40,
          ),
        ],
      );

      final originalDoc = AtlasInkDocument(
        version: 1,
        documentId: 'doc_linux_source',
        pageNumber: 2,
        width: 1600.0,
        height: 2200.0,
        backgroundTemplate: 'dotted',
        backgroundColor: 0xFFFAFAFA,
        layers: [
          InkLayer(id: 'l_main', name: 'Main', strokes: [originalStroke]),
        ],
      );

      // Convert Linux doc to PK dictionaries
      final pkStrokes = PencilKitConverter.documentToPencilKitStrokes(
        originalDoc,
      );
      expect(pkStrokes.length, equals(1));
      expect(pkStrokes.first['tool'], equals('fountainPen'));
      expect(pkStrokes.first['id'], equals('linux_stroke_1'));

      // Reconstruct document
      final reconstructedDoc = PencilKitConverter.pencilKitStrokesToDocument(
        pkStrokes,
        documentId: originalDoc.documentId,
        pageNumber: originalDoc.pageNumber,
        width: originalDoc.width,
        height: originalDoc.height,
        backgroundTemplate: originalDoc.backgroundTemplate,
        backgroundColor: originalDoc.backgroundColor,
      );

      expect(reconstructedDoc.documentId, equals('doc_linux_source'));
      expect(reconstructedDoc.pageNumber, equals(2));
      expect(reconstructedDoc.backgroundTemplate, equals('dotted'));
      expect(reconstructedDoc.backgroundColor, equals(0xFFFAFAFA));
      expect(reconstructedDoc.totalStrokeCount, equals(1));

      final reconstructedStroke = reconstructedDoc.layers.first.strokes.first;
      expect(reconstructedStroke.id, equals('linux_stroke_1'));
      expect(reconstructedStroke.tool, equals(InkToolType.fountainPen));
      expect(reconstructedStroke.color, equals(0xFF1E293B));
      expect(reconstructedStroke.baseWidth, equals(3.2));
      expect(reconstructedStroke.points.length, equals(3));
      expect(reconstructedStroke.points[1].x, equals(48.0));
      expect(reconstructedStroke.points[1].y, equals(92.0));
      expect(reconstructedStroke.points[1].pressure, closeTo(0.75, 0.001));
    });

    test('Unsupported iOS 17+ or custom tools fall back gracefully without data loss', () {
      final unsupportedTools = [
        'watercolor',
        'crayon',
        'monoline',
        'unknown_brush',
        'calligraphy',
      ];

      for (final toolName in unsupportedTools) {
        final mapped = PencilKitConverter.mapPencilKitToTool(toolName);
        expect(
          mapped,
          equals(InkToolType.ballpointPen),
          reason: 'Tool $toolName should safely fall back to ballpointPen',
        );
      }

      // Null tool safely defaults
      expect(
        PencilKitConverter.mapPencilKitToTool(null),
        equals(InkToolType.ballpointPen),
      );

      // Eraser tools safely map to pen when exporting stroke data
      expect(
        PencilKitConverter.mapToolToPencilKit(InkToolType.vectorEraser),
        equals('ballpointPen'),
      );
      expect(
        PencilKitConverter.mapToolToPencilKit(InkToolType.pixelEraser),
        equals('ballpointPen'),
      );
    });

    test(
      'Coordinates and high-resolution telemetry round-trip with zero drift',
      () {
        const x = 1234.5678;
        const y = 9876.5432;
        const pressure = 0.87654;
        const azimuth = 2.4567;
        const altitude = 0.6543;
        const timeMs = 12345;

        final stroke = InkStroke(
          id: 'telemetry_test',
          tool: InkToolType.ballpointPen,
          color: 0xFF000000,
          baseWidth: 2.0,
          points: const [
            InkPoint(
              x: x,
              y: y,
              pressure: pressure,
              tiltAzimuth: azimuth,
              tiltAltitude: altitude,
              timeOffsetMs: timeMs,
            ),
          ],
        );

        final dict = PencilKitConverter.strokeToPencilKitDictionary(stroke);
        final reconstructed = PencilKitConverter.pencilKitDictionaryToStroke(
          dict,
        );

        expect(reconstructed.points.first.x, equals(x));
        expect(reconstructed.points.first.y, equals(y));
        expect(reconstructed.points.first.pressure, closeTo(pressure, 0.0001));
        expect(
          reconstructed.points.first.tiltAzimuth,
          closeTo(azimuth, 0.0001),
        );
        expect(
          reconstructed.points.first.tiltAltitude,
          closeTo(altitude, 0.0001),
        );
        expect(reconstructed.points.first.timeOffsetMs, equals(timeMs));
      },
    );

    test('Single-point stroke (dot) is fully preserved without data loss', () {
      final dotStroke = InkStroke(
        id: 'dot_1',
        tool: InkToolType.ballpointPen,
        color: 0xFF112233,
        baseWidth: 5.0,
        points: const [
          InkPoint(x: 500.0, y: 600.0, pressure: 0.9, timeOffsetMs: 0),
        ],
      );

      final dict = PencilKitConverter.strokeToPencilKitDictionary(dotStroke);
      expect((dict['points'] as List).length, equals(1));

      final reconstructed = PencilKitConverter.pencilKitDictionaryToStroke(
        dict,
      );
      expect(reconstructed.points.length, equals(1));
      expect(reconstructed.points.first.x, equals(500.0));
      expect(reconstructed.points.first.y, equals(600.0));
    });

    test('Empty drawing conversions handle zero strokes gracefully', () {
      final emptyDoc = AtlasInkDocument.empty(
        documentId: 'doc_empty',
        width: 1600.0,
        height: 2200.0,
      );

      final pkStrokes = PencilKitConverter.documentToPencilKitStrokes(emptyDoc);
      expect(pkStrokes, isEmpty);

      final reconstructedDoc = PencilKitConverter.pencilKitStrokesToDocument(
        [],
        documentId: 'doc_empty',
        pageNumber: 1,
      );
      expect(reconstructedDoc.totalStrokeCount, equals(0));
      expect(reconstructedDoc.layers.isNotEmpty, isTrue);
    });
  });
}
