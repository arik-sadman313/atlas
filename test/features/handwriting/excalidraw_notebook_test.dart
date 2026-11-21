import 'dart:math' as math;

import 'package:atlas/features/handwriting/domain/interop/excalidraw_converter.dart';
import 'package:atlas/features/handwriting/domain/math/rough_generator.dart';
import 'package:atlas/features/handwriting/domain/math/smart_shape_detector.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_document_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoughGenerator Tests', () {
    test('buildRoughLine generates non-empty path with roughness', () {
      final p1 = const Offset(10, 10);
      final p2 = const Offset(100, 100);
      final path = RoughGenerator.buildRoughLine(
        p1,
        p2,
        roughness: 1.0,
        seed: 42,
      );
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(80));
      expect(bounds.height, greaterThan(80));
    });

    test('buildRoughRectangle generates non-empty path with 4 sides', () {
      const rect = Rect.fromLTWH(50, 50, 200, 150);
      final path = RoughGenerator.buildRoughRectangle(
        rect,
        roughness: 1.0,
        seed: 101,
      );
      final bounds = path.getBounds();
      expect(bounds.width, greaterThanOrEqualTo(190));
      expect(bounds.height, greaterThanOrEqualTo(140));
    });

    test('buildRoughEllipse generates non-empty path loop', () {
      const rect = Rect.fromLTWH(100, 100, 160, 160);
      final path = RoughGenerator.buildRoughEllipse(
        rect,
        roughness: 1.0,
        seed: 202,
      );
      final bounds = path.getBounds();
      expect(bounds.width, greaterThanOrEqualTo(140));
      expect(bounds.height, greaterThanOrEqualTo(140));
    });

    test('buildRoughDiamond generates 4-pointed diamond', () {
      const rect = Rect.fromLTWH(50, 50, 120, 120);
      final path = RoughGenerator.buildRoughDiamond(
        rect,
        roughness: 1.0,
        seed: 303,
      );
      final bounds = path.getBounds();
      expect(bounds.width, greaterThanOrEqualTo(100));
      expect(bounds.height, greaterThanOrEqualTo(100));
    });

    test('buildRoughArrow generates shaft and arrowhead barbs', () {
      final start = const Offset(20, 50);
      final end = const Offset(150, 50);
      final path = RoughGenerator.buildRoughArrow(
        start,
        end,
        roughness: 1.0,
        seed: 404,
      );
      final bounds = path.getBounds();
      expect(bounds.width, greaterThanOrEqualTo(120));
      expect(bounds.height, greaterThan(5));
    });

    test('buildHachureLines generates diagonal parallel hatching lines', () {
      const rect = Rect.fromLTWH(50, 50, 200, 200);
      final hachure = RoughGenerator.buildHachureLines(
        rect,
        spacing: 12.0,
        crossHatch: false,
      );
      expect(hachure.getBounds().isEmpty, isFalse);

      final crossHatch = RoughGenerator.buildHachureLines(
        rect,
        spacing: 12.0,
        crossHatch: true,
      );
      expect(crossHatch.getBounds().isEmpty, isFalse);

      final dots = RoughGenerator.buildHachureLines(
        rect,
        spacing: 12.0,
        dots: true,
      );
      expect(dots.getBounds().isEmpty, isFalse);
    });

    test('buildRoughRectangle supports rounded corners', () {
      const rect = Rect.fromLTWH(30, 30, 150, 100);
      final path = RoughGenerator.buildRoughRectangle(
        rect,
        roundness: 'round',
        roughness: 1.0,
      );
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(130));
      expect(bounds.height, greaterThan(80));
    });

    test('buildRoughArrow supports curved arrows and arrowheads', () {
      const start = Offset(20, 20);
      const end = Offset(180, 100);
      final curvedArrow = RoughGenerator.buildRoughArrow(
        start,
        end,
        isCurved: true,
        startArrowhead: 'dot',
        endArrowhead: 'bar',
      );
      expect(curvedArrow.getBounds().isEmpty, isFalse);
    });

    test('buildRoughStickyNote and buildRoughFrame generate valid paths', () {
      const noteRect = Rect.fromLTWH(40, 40, 140, 140);
      final notePath = RoughGenerator.buildRoughStickyNote(noteRect);
      expect(notePath.getBounds().isEmpty, isFalse);

      const frameRect = Rect.fromLTWH(20, 20, 300, 200);
      final framePath = RoughGenerator.buildRoughFrame(frameRect);
      expect(framePath.getBounds().isEmpty, isFalse);
    });

    test('applyStrokeStyle converts path to dashed and dotted styles', () {
      final linePath = Path()
        ..moveTo(10, 10)
        ..lineTo(200, 200);

      final dashed = RoughGenerator.applyStrokeStyle(linePath, 'dashed');
      expect(dashed.getBounds().isEmpty, isFalse);
      expect(dashed.getBounds().width, greaterThan(150));

      final dotted = RoughGenerator.applyStrokeStyle(linePath, 'dotted');
      expect(dotted.getBounds().isEmpty, isFalse);
      expect(dotted.getBounds().width, greaterThan(150));
    });
  });

  group('SmartShapeDetector Tests (iPad Draw-and-Hold)', () {
    test('detects circle / ellipse for round closed points', () {
      final points = <InkPoint>[];
      const count = 32;
      const cx = 200.0;
      const cy = 200.0;
      const r = 80.0;

      for (int i = 0; i <= count; i++) {
        final angle = (i / count) * 2 * math.pi;
        points.add(
          InkPoint(x: cx + r * math.cos(angle), y: cy + r * math.sin(angle)),
        );
      }

      final shape = SmartShapeDetector.detect(points);
      expect(shape, isNotNull);
      expect(shape!.type, equals(InkToolType.ellipse));
    });

    test('detects rectangle for closed 4-corner points', () {
      final points = <InkPoint>[];
      // Top edge
      for (double x = 100; x <= 250; x += 15) {
        points.add(InkPoint(x: x, y: 100));
      }
      // Right edge
      for (double y = 100; y <= 200; y += 15) {
        points.add(InkPoint(x: 250, y: y));
      }
      // Bottom edge
      for (double x = 250; x >= 100; x -= 15) {
        points.add(InkPoint(x: x, y: 200));
      }
      // Left edge
      for (double y = 200; y >= 100; y -= 15) {
        points.add(InkPoint(x: 100, y: y));
      }

      final shape = SmartShapeDetector.detect(points);
      expect(shape, isNotNull);
      expect(shape!.type, equals(InkToolType.rectangle));
    });

    test('detects straight line for linear open stroke', () {
      final points = <InkPoint>[];
      for (double i = 0; i <= 100; i += 5) {
        points.add(InkPoint(x: 50 + i * 2, y: 50 + i * 0.5));
      }

      final shape = SmartShapeDetector.detect(points);
      expect(shape, isNotNull);
      expect(shape!.type, equals(InkToolType.line));
    });

    test('rejects tiny or sparse points as random doodle', () {
      final fewPoints = [
        const InkPoint(x: 10, y: 10),
        const InkPoint(x: 12, y: 12),
        const InkPoint(x: 14, y: 14),
      ];
      expect(SmartShapeDetector.detect(fewPoints), isNull);
    });
  });

  group('ExcalidrawConverter Tests', () {
    test('exports and imports Excalidraw v2 JSON schema roundtrip', () {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_excal_test',
        backgroundColor: 0xFF14171F,
      );

      final controller = InkCanvasController(document: doc);
      // Add rectangle shape
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.rectangle,
          color: 0xFF2563EB,
          baseWidth: 3.0,
          fillStyle: 'hachure',
          fillColor: 0xFF3B82F6,
          roughness: 1.0,
        ),
      );
      controller.startStroke(const Offset(50, 50));
      controller.updateStroke(const Offset(250, 180));
      controller.endStroke();

      // Add text element
      controller.addTextElement(const Offset(60, 70), 'Excalidraw Note Header');

      final excalJson = ExcalidrawConverter.exportToExcalidraw(
        controller.document,
      );
      expect(excalJson['type'], equals('excalidraw'));
      expect(excalJson['version'], equals(2));
      final elements = excalJson['elements'] as List;
      expect(elements.length, equals(2));

      // Import back
      final importedDoc = ExcalidrawConverter.importFromExcalidraw(
        excalJson,
        documentId: 'doc_excal_imported',
      );
      expect(importedDoc.totalStrokeCount, equals(2));
      final rectStroke = importedDoc.allStrokes.firstWhere(
        (s) => s.shapeType == 'rectangle',
      );
      expect(rectStroke.fillStyle, equals('hachure'));
      expect(rectStroke.color, equals(0xFF2563EB));

      final textStroke = importedDoc.allStrokes.firstWhere(
        (s) => s.shapeType == 'text',
      );
      expect(textStroke.text, equals('Excalidraw Note Header'));
    });

    test('exports and imports notes, frames, arrowheads and locked state', () {
      final doc = AtlasInkDocument.empty(documentId: 'doc_advanced_excal');
      final controller = InkCanvasController(document: doc);

      // Add Sticky note
      controller.addStickyNote(
        const Offset(100, 100),
        'Important Meeting Note',
        bgColor: 0xFFFEF08A,
      );

      // Add Frame
      controller.addFrame(
        const Rect.fromLTWH(50, 50, 500, 400),
        'Architecture Diagram Frame',
      );

      // Add Curved arrow with arrowheads
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.curvedArrow,
          color: 0xFF3B82F6,
          baseWidth: 2.0,
          startArrowhead: 'dot',
          endArrowhead: 'arrow',
          isCurved: true,
        ),
      );
      controller.startStroke(const Offset(60, 80));
      controller.updateStroke(const Offset(200, 180));
      controller.endStroke();

      final excalJson = ExcalidrawConverter.exportToExcalidraw(
        controller.document,
      );
      final elements = excalJson['elements'] as List;
      expect(elements.any((e) => e['type'] == 'note'), isTrue);
      expect(elements.any((e) => e['type'] == 'frame'), isTrue);
      expect(elements.any((e) => e['type'] == 'arrow'), isTrue);

      final importedDoc = ExcalidrawConverter.importFromExcalidraw(
        excalJson,
        documentId: 'doc_advanced_imported',
      );
      expect(importedDoc.totalStrokeCount, equals(3));
      final note = importedDoc.allStrokes.firstWhere(
        (s) => s.tool == InkToolType.stickyNote,
      );
      expect(note.text, equals('Important Meeting Note'));
      final frame = importedDoc.allStrokes.firstWhere(
        (s) => s.tool == InkToolType.frame,
      );
      expect(frame.text, equals('Architecture Diagram Frame'));
      final arrow = importedDoc.allStrokes.firstWhere(
        (s) => s.tool == InkToolType.curvedArrow,
      );
      expect(arrow.startArrowhead, equals('dot'));
      expect(arrow.endArrowhead, equals('arrow'));
      expect(arrow.isCurved, isTrue);
    });
  });

  group('InkCanvasController Excalidraw & iPad Note Taking Tests', () {
    test('controller supports tool switching and snap-to-shape', () {
      final doc = AtlasInkDocument.empty(documentId: 'doc_controller_test');
      final controller = InkCanvasController(document: doc);

      expect(controller.activeTool.type.isShape, isFalse);

      controller.setTool(
        controller.activeTool.copyWith(type: InkToolType.diamond),
      );
      expect(controller.activeTool.type.isShape, isTrue);

      // Simulate snapping in-flight stroke to ellipse
      controller.startStroke(const Offset(10, 10));
      controller.updateStroke(const Offset(50, 50));

      const detected = DetectedShape(
        type: InkToolType.ellipse,
        bounds: Rect.fromLTWH(10, 10, 100, 100),
        start: Offset(10, 10),
        end: Offset(110, 110),
        confidence: 0.95,
      );
      controller.snapInFlightStrokeToShape(detected);

      expect(controller.document.totalStrokeCount, equals(1));
      final stroke = controller.document.allStrokes.first;
      expect(stroke.tool, equals(InkToolType.ellipse));
      expect(stroke.shapeType, equals('ellipse'));
    });

    test('controller updates selected shape styles (fillStyle, roughness)', () {
      final doc = AtlasInkDocument.empty(documentId: 'doc_style_test');
      final controller = InkCanvasController(document: doc);

      controller.setTool(
        const InkToolConfig(
          type: InkToolType.rectangle,
          color: 0xFF18181B,
          baseWidth: 2.0,
        ),
      );
      controller.startStroke(const Offset(20, 20));
      controller.updateStroke(const Offset(120, 120));
      controller.endStroke();

      // Lasso select it
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.lasso,
          color: 0xFF2563EB,
          baseWidth: 1.0,
        ),
      );
      controller.startStroke(const Offset(10, 10));
      controller.updateStroke(const Offset(150, 10));
      controller.updateStroke(const Offset(150, 150));
      controller.updateStroke(const Offset(10, 150));
      controller.endStroke();

      expect(controller.hasSelection, isTrue);

      controller.updateSelectedShapesStyle(
        fillStyle: 'cross-hatch',
        fillColor: 0xFFEF4444,
        roughness: 2.0,
      );

      final updated = controller.selectedStrokes.first;
      expect(updated.fillStyle, equals('cross-hatch'));
      expect(updated.fillColor, equals(0xFFEF4444));
      expect(updated.roughness, equals(2.0));
    });

    test('controller supports z-ordering, grouping, alignment, flip, rotation, and lock', () {
      final doc = AtlasInkDocument.empty(documentId: 'doc_transforms_test');
      final controller = InkCanvasController(document: doc);

      // Create two shapes
      controller.setTool(
        const InkToolConfig(
          type: InkToolType.rectangle,
          color: 0xFF18181B,
          baseWidth: 2.0,
        ),
      );
      controller.startStroke(const Offset(50, 50));
      controller.updateStroke(const Offset(150, 150));
      controller.endStroke();

      controller.startStroke(const Offset(200, 200));
      controller.updateStroke(const Offset(300, 300));
      controller.endStroke();

      expect(controller.document.totalStrokeCount, equals(2));
      final stroke1Id = controller.document.allStrokes[0].id;

      // Select all
      controller.selectAll();
      expect(controller.selectedStrokes.length, equals(2));

      // Group
      controller.groupSelectedStrokes();
      expect(controller.selectedStrokes.first.groupId, isNotNull);
      expect(
        controller.selectedStrokes.first.groupId,
        equals(controller.selectedStrokes.last.groupId),
      );

      // Ungroup
      controller.ungroupSelectedStrokes();
      expect(controller.selectedStrokes.first.groupId, isNull);

      // Alignment: Left
      controller.alignSelectedStrokes('left');
      expect(
        controller.selectedStrokes[0].computedBounds.left,
        equals(controller.selectedStrokes[1].computedBounds.left),
      );

      // Flip Horizontal
      final beforeFlipX = controller.selectedStrokes[0].points.first.x;
      controller.flipSelectedStrokesHorizontal();
      expect(
        controller.selectedStrokes[0].points.first.x,
        isNot(equals(beforeFlipX)),
      );

      // Rotation
      controller.rotateSelectedStrokes(0.5, const Offset(100, 100));
      expect(controller.selectedStrokes[0].angle, equals(0.5));

      // Toggle Lock
      controller.toggleLockSelectedStrokes();
      expect(controller.selectedStrokes[0].isLocked, isTrue);

      // Z-Ordering: select first stroke and bring to front
      controller.selectStroke(stroke1Id);
      controller.bringToFront();
      expect(controller.document.allStrokes.last.id, equals(stroke1Id));

      // Send to back
      controller.sendToBack();
      expect(controller.document.allStrokes.first.id, equals(stroke1Id));
    });

    test('controller handles grid snapping correctly', () {
      final doc = AtlasInkDocument.empty(documentId: 'doc_snap_test');
      final controller = InkCanvasController(document: doc);

      controller.toggleSnapToGrid();
      expect(controller.snapToGrid, isTrue);

      final p = controller.snapPoint(const Offset(23.4, 47.8));
      expect(p.dx, equals(20.0));
      expect(p.dy, equals(40.0));
    });
  });

  group('InkDocumentPainter Stationery & Cornell Notes Tests', () {
    testWidgets(
      'renders Cornell Notes stationery and Excalidraw shapes without error',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_cornell_test',
          backgroundTemplate: 'cornell',
        );

        final controller = InkCanvasController(document: doc);
        // Add a rectangle with hachure
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.rectangle,
            color: 0xFF2563EB,
            baseWidth: 2.5,
            fillStyle: 'hachure',
            fillColor: 0xFF3B82F6,
          ),
        );
        controller.startStroke(const Offset(100, 150));
        controller.updateStroke(const Offset(300, 280));
        controller.endStroke();

        // Add an arrow
        controller.setTool(
          const InkToolConfig(
            type: InkToolType.arrow,
            color: 0xFF10B981,
            baseWidth: 2.5,
          ),
        );
        controller.startStroke(const Offset(300, 215));
        controller.updateStroke(const Offset(450, 215));
        controller.endStroke();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(800, 1000),
                painter: InkDocumentPainter(
                  document: controller.document,
                  activePoints: const [],
                  lassoPolygon: const [],
                  activeTool: controller.activeTool,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}
