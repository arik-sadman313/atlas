import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:atlas/features/handwriting/presentation/controllers/ink_canvas_controller.dart';
import 'package:atlas/features/handwriting/presentation/platform/pencil_kit_bridge.dart';
import 'package:atlas/features/handwriting/presentation/widgets/floating_tool_dock.dart';
import 'package:atlas/features/handwriting/presentation/widgets/ink_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple Pencil Hardware Telemetry & Palm Rejection Tests', () {
    testWidgets(
      'Stylus draws and captures hardware pressure and tilt altitude',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_pencil_1',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(
          document: doc,
          drawWithFinger: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InkCanvas(controller: controller, width: 800, height: 600),
            ),
          ),
        );

        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 1,
            position: Offset(100, 100),
            kind: PointerDeviceKind.stylus,
            pressure: 0.75,
            tilt: 0.45,
          ),
        );
        await tester.pump();

        expect(controller.isDrawing, isTrue);
        expect(controller.activePoints.length, equals(1));
        final firstPt = controller.activePoints.first;
        expect(firstPt.pressure, closeTo(0.75, 0.01));
        expect(firstPt.tiltAltitude, closeTo(0.45, 0.01));

        await tester.sendEventToBinding(
          const PointerMoveEvent(
            pointer: 1,
            position: Offset(200, 200),
            kind: PointerDeviceKind.stylus,
            pressure: 0.85,
            tilt: 0.45,
          ),
        );
        await tester.pump();
        expect(controller.activePoints.length, equals(2));

        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 1,
            position: Offset(200, 200),
            kind: PointerDeviceKind.stylus,
          ),
        );
        await tester.pump();

        expect(controller.isDrawing, isFalse);
        expect(controller.document.totalStrokeCount, equals(1));
      },
    );

    testWidgets('Inverted stylus automatically activates vector eraser', (
      tester,
    ) async {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_inverted_1',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(
        document: doc,
        initialTool: const InkToolConfig(
          type: InkToolType.ballpointPen,
          color: 0xFF000000,
          baseWidth: 3.0,
        ),
        drawWithFinger: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkCanvas(controller: controller, width: 800, height: 600),
          ),
        ),
      );

      expect(controller.activeTool.type, equals(InkToolType.ballpointPen));

      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 1,
          position: Offset(150, 150),
          kind: PointerDeviceKind.invertedStylus,
        ),
      );
      await tester.pump();

      // Should switch to vector eraser
      expect(controller.activeTool.type, equals(InkToolType.vectorEraser));

      await tester.sendEventToBinding(
        const PointerUpEvent(
          pointer: 1,
          position: Offset(150, 150),
          kind: PointerDeviceKind.invertedStylus,
        ),
      );
      await tester.pump();
    });

    testWidgets(
      'When drawWithFinger is false: finger touch does NOT draw, triggers onCanvasPan',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_finger_pan',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(
          document: doc,
          drawWithFinger: false,
        );

        Offset panDelta = Offset.zero;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InkCanvas(
                controller: controller,
                width: 800,
                height: 600,
                onCanvasPan: (delta) {
                  panDelta += delta;
                },
              ),
            ),
          ),
        );

        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 2,
            position: Offset(200, 200),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();

        // Finger MUST NOT start drawing strokes
        expect(controller.isDrawing, isFalse);
        expect(controller.activePoints, isEmpty);

        // Drag finger
        await tester.sendEventToBinding(
          const PointerMoveEvent(
            pointer: 2,
            position: Offset(220, 240),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();

        expect(controller.isDrawing, isFalse);
        expect(panDelta.dx, closeTo(20.0, 0.1));
        expect(panDelta.dy, closeTo(40.0, 0.1));

        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 2,
            position: Offset(220, 240),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();

        expect(controller.document.totalStrokeCount, equals(0));
      },
    );

    testWidgets(
      'Concurrent touch during stylus inking is completely rejected (Palm Rejection)',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_palm_reject',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(
          document: doc,
          drawWithFinger:
              true, // even if finger mode was on, pencil down rejects touches!
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InkCanvas(controller: controller, width: 800, height: 600),
            ),
          ),
        );

        // 1. Apple Pencil begins inking
        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 1,
            position: Offset(100, 100),
            kind: PointerDeviceKind.stylus,
          ),
        );
        await tester.pump();
        expect(controller.isDrawing, isTrue);
        expect(controller.activePoints.length, equals(1));

        // 2. Resting wrist / palm contacts screen concurrently
        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 2,
            position: Offset(180, 250),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();

        // Palm must not add points or interfere with drawing
        expect(controller.activePoints.length, equals(1));

        // Palm moves slightly
        await tester.sendEventToBinding(
          const PointerMoveEvent(
            pointer: 2,
            position: Offset(185, 255),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();
        expect(controller.activePoints.length, equals(1));

        // Pencil moves and writes
        await tester.sendEventToBinding(
          const PointerMoveEvent(
            pointer: 1,
            position: Offset(120, 130),
            kind: PointerDeviceKind.stylus,
          ),
        );
        await tester.pump();
        expect(controller.activePoints.length, equals(2));

        // Palm lifts
        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 2,
            position: Offset(185, 255),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();

        // Pencil completes stroke
        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 1,
            position: Offset(120, 130),
            kind: PointerDeviceKind.stylus,
          ),
        );
        await tester.pump();

        expect(controller.document.totalStrokeCount, equals(1));
      },
    );

    testWidgets('Large contact patch (radiusMajor > 20) is rejected as palm', (
      tester,
    ) async {
      final doc = AtlasInkDocument.empty(
        documentId: 'doc_large_patch',
        width: 800,
        height: 600,
      );
      final controller = InkCanvasController(
        document: doc,
        drawWithFinger: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkCanvas(controller: controller, width: 800, height: 600),
          ),
        ),
      );

      // Contact patch with large radius (e.g. 25.0)
      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 1,
          position: Offset(200, 200),
          kind: PointerDeviceKind.touch,
          radiusMajor: 25.0,
          radiusMinor: 22.0,
        ),
      );
      await tester.pump();

      expect(controller.isDrawing, isFalse);
      expect(controller.activePoints, isEmpty);

      await tester.sendEventToBinding(
        const PointerMoveEvent(
          pointer: 1,
          position: Offset(210, 210),
          kind: PointerDeviceKind.touch,
          radiusMajor: 25.0,
          radiusMinor: 22.0,
        ),
      );
      await tester.pump();
      expect(controller.isDrawing, isFalse);

      await tester.sendEventToBinding(
        const PointerUpEvent(
          pointer: 1,
          position: Offset(210, 210),
          kind: PointerDeviceKind.touch,
        ),
      );
      await tester.pump();
      expect(controller.document.totalStrokeCount, equals(0));
    });

    testWidgets(
      'When drawWithFinger is true: finger touch draws strokes normally',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_finger_draw',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(
          document: doc,
          drawWithFinger: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InkCanvas(controller: controller, width: 800, height: 600),
            ),
          ),
        );

        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 1,
            position: Offset(100, 100),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();
        expect(controller.isDrawing, isTrue);

        await tester.sendEventToBinding(
          const PointerMoveEvent(
            pointer: 1,
            position: Offset(150, 150),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();
        expect(controller.activePoints.length, equals(2));

        await tester.sendEventToBinding(
          const PointerUpEvent(
            pointer: 1,
            position: Offset(150, 150),
            kind: PointerDeviceKind.touch,
          ),
        );
        await tester.pump();
        expect(controller.document.totalStrokeCount, equals(1));
      },
    );
  });

  group('Apple Pencil Double-Tap & Floating Tool Dock Tests', () {
    testWidgets(
      'Apple Pencil double-tap method channel toggles eraser and previous tool',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_bridge_test',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(
          document: doc,
          initialTool: const InkToolConfig(
            type: InkToolType.fountainPen,
            color: 0xFF2563EB,
            baseWidth: 4.0,
          ),
        );

        final bridge = PencilKitBridge();
        bridge.initializeMethodChannel();
        bridge.attachController(controller);

        expect(controller.activeTool.type, equals(InkToolType.fountainPen));

        // 1. Simulate native double-tap from UIPencilInteraction
        final binaryMessenger = tester.binding.defaultBinaryMessenger;
        await binaryMessenger.handlePlatformMessage(
          'com.atlas/pencil_kit_interop',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onApplePencilDoubleTap'),
          ),
          (ByteData? _) {},
        );
        await tester.pump();

        // Must toggle to vector eraser
        expect(controller.activeTool.type, equals(InkToolType.vectorEraser));

        // 2. Second double-tap restores fountain pen
        await binaryMessenger.handlePlatformMessage(
          'com.atlas/pencil_kit_interop',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onApplePencilDoubleTap'),
          ),
          (ByteData? _) {},
        );
        await tester.pump();

        expect(controller.activeTool.type, equals(InkToolType.fountainPen));
        expect(controller.activeTool.color, equals(0xFF2563EB));
      },
    );

    testWidgets(
      'FloatingToolDock renders Draw with Finger button and toggles state',
      (tester) async {
        final doc = AtlasInkDocument.empty(
          documentId: 'doc_dock_test',
          width: 800,
          height: 600,
        );
        final controller = InkCanvasController(
          document: doc,
          drawWithFinger: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FloatingToolDock(
                    controller: controller,
                    onClearRequested: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Initially drawWithFinger is false -> Icon should be do_not_touch_rounded
        expect(find.byIcon(Icons.do_not_touch_rounded), findsOneWidget);
        expect(controller.drawWithFinger, isFalse);

        // Tap the toggle button
        await tester.tap(find.byIcon(Icons.do_not_touch_rounded));
        await tester.pump();

        // State toggled to true -> Icon changes to touch_app_rounded
        expect(controller.drawWithFinger, isTrue);
        expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
        expect(find.textContaining('Finger Drawing Enabled'), findsOneWidget);
      },
    );
  });
}
