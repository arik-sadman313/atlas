import 'dart:io';
import 'dart:ui' as ui;

import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_document_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'capture handwriting prototype screenshot using InkDocumentPainter',
    () async {
      final strokes = <InkStroke>[
        // Highlighter background stroke (multiply blend mode)
        InkStroke(
          id: 'h_1',
          tool: InkToolType.highlighter,
          color: 0xFFFACC15,
          baseWidth: 32.0,
          opacity: 0.4,
          blendMode: 'multiply',
          points: const [
            InkPoint(x: 100, y: 150, pressure: 0.6, timeOffsetMs: 0),
            InkPoint(x: 400, y: 150, pressure: 0.8, timeOffsetMs: 50),
            InkPoint(x: 800, y: 150, pressure: 0.7, timeOffsetMs: 100),
          ],
        ),
        // Handwritten Pen stroke: Title
        InkStroke(
          id: 'p_1',
          tool: InkToolType.fountainPen,
          color: 0xFF18181B,
          baseWidth: 5.0,
          points: const [
            InkPoint(x: 110, y: 145, pressure: 0.5, timeOffsetMs: 0),
            InkPoint(x: 130, y: 130, pressure: 0.8, timeOffsetMs: 20),
            InkPoint(x: 160, y: 160, pressure: 0.9, timeOffsetMs: 40),
            InkPoint(x: 200, y: 140, pressure: 0.6, timeOffsetMs: 60),
          ],
        ),
        InkStroke(
          id: 'p_2',
          tool: InkToolType.fountainPen,
          color: 0xFF1D4ED8, // Deep blue
          baseWidth: 4.0,
          points: const [
            InkPoint(x: 240, y: 145, pressure: 0.4, timeOffsetMs: 0),
            InkPoint(x: 320, y: 145, pressure: 0.8, timeOffsetMs: 30),
            InkPoint(x: 400, y: 145, pressure: 0.5, timeOffsetMs: 60),
          ],
        ),
        // Math equation curve (sine wave)
        InkStroke(
          id: 'curve_1',
          tool: InkToolType.ballpointPen,
          color: 0xFFDC2626, // Crimson
          baseWidth: 3.5,
          points: List.generate(60, (i) {
            final x = 120.0 + i * 15;
            final y = 350.0 + 60.0 * (i.isEven ? 1.0 : -1.0) * (i / 60);
            return InkPoint(
              x: x,
              y: y,
              pressure: 0.5 + (i % 4) * 0.12,
              timeOffsetMs: i * 10,
            );
          }),
        ),
        // Handwritten annotation note
        InkStroke(
          id: 'note_1',
          tool: InkToolType.ballpointPen,
          color: 0xFF059669, // Emerald green
          baseWidth: 3.0,
          points: const [
            InkPoint(x: 120, y: 480, pressure: 0.5, timeOffsetMs: 0),
            InkPoint(x: 250, y: 490, pressure: 0.7, timeOffsetMs: 20),
            InkPoint(x: 380, y: 485, pressure: 0.6, timeOffsetMs: 40),
            InkPoint(x: 520, y: 495, pressure: 0.8, timeOffsetMs: 60),
          ],
        ),
      ];

      final inkDoc = AtlasInkDocument(
        version: 1,
        documentId: 'doc_quantum_notes',
        pageNumber: 1,
        width: 1200,
        height: 900,
        backgroundTemplate: 'ruled',
        backgroundColor: 0xFFFFFFFF,
        layers: [
          InkLayer(
            id: 'hl',
            name: 'Highlighters',
            blendMode: 'multiply',
            strokes: [strokes[0]],
          ),
          InkLayer(id: 'pen', name: 'Ink', strokes: strokes.sublist(1)),
        ],
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1200, 900));
      final painter = InkDocumentPainter(document: inkDoc);
      painter.paint(canvas, const Size(1200, 900));
      final picture = recorder.endRecording();

      final image = await picture.toImage(1200, 900);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);

      final file = File('docs/images/atlas_handwriting_prototype.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(byteData!.buffer.asUint8List());

      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1000));
    },
  );
}
