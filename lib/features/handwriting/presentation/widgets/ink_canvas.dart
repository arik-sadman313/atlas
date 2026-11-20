import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/math/smart_shape_detector.dart';
import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';
import 'ink_document_painter.dart';
import 'selection_overlay_widget.dart';

class InkCanvas extends StatefulWidget {
  final InkCanvasController controller;
  final double width;
  final double height;
  final bool readOnly;
  final Widget? backgroundWidget;
  final bool drawBackground;

  const InkCanvas({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
    this.readOnly = false,
    this.backgroundWidget,
    this.drawBackground = true,
  });

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> {
  Timer? _drawAndHoldTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(InkCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _drawAndHoldTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.readOnly) return;
    _drawAndHoldTimer?.cancel();

    if (widget.controller.activeTool.type == InkToolType.text) {
      _showTextInputDialog(event.localPosition);
      return;
    }

    final pressure = event.pressure == 0.0 ? 0.5 : event.pressure;
    widget.controller.startStroke(
      event.localPosition,
      pressure: pressure,
      tiltAzimuth: event.orientation,
      tiltAltitude: event.tilt,
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.readOnly) return;
    final pressure = event.pressure == 0.0 ? 0.5 : event.pressure;
    widget.controller.updateStroke(
      event.localPosition,
      pressure: pressure,
      tiltAzimuth: event.orientation,
      tiltAltitude: event.tilt,
    );

    // iPad Draw-and-Hold Shape Recognition:
    // If drawing freehand and user pauses at the end of the stroke for 450ms without lifting
    final tool = widget.controller.activeTool.type;
    final isFreehand = tool == InkToolType.ballpointPen ||
        tool == InkToolType.fountainPen ||
        tool == InkToolType.pencil;

    if (isFreehand && widget.controller.activePoints.length >= 10) {
      _drawAndHoldTimer?.cancel();
      _drawAndHoldTimer = Timer(const Duration(milliseconds: 450), () {
        if (!mounted || !widget.controller.isDrawing) return;
        final shape = SmartShapeDetector.detect(widget.controller.activePoints);
        if (shape != null) {
          widget.controller.snapInFlightStrokeToShape(shape);
        }
      });
    } else {
      _drawAndHoldTimer?.cancel();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _drawAndHoldTimer?.cancel();
    if (widget.readOnly) return;
    if (widget.controller.activeTool.type != InkToolType.text) {
      widget.controller.endStroke();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _drawAndHoldTimer?.cancel();
    if (widget.readOnly) return;
    widget.controller.endStroke();
  }

  void _showTextInputDialog(Offset position) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.text_fields_rounded, size: 20),
            SizedBox(width: 8),
            Text('Add Note Text'),
          ],
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Type handwritten label or note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              widget.controller.addTextElement(position, val.trim());
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                widget.controller.addTextElement(position, textCtrl.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Text'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.backgroundWidget != null) widget.backgroundWidget!,
          Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: InkDocumentPainter(
                document: widget.controller.document,
                activePoints: widget.controller.activePoints,
                lassoPolygon: widget.controller.lassoPolygon,
                activeTool: widget.controller.activeTool,
                isDrawing: widget.controller.isDrawing,
                drawBackground:
                    widget.drawBackground && widget.backgroundWidget == null,
                renderCache: widget.controller.renderCache,
                revision: widget.controller.revision,
              ),
            ),
          ),
          if (!widget.readOnly && widget.controller.hasSelection)
            SelectionOverlayWidget(
              controller: widget.controller,
              canvasWidth: widget.width,
              canvasHeight: widget.height,
            ),
        ],
      ),
    );
  }
}
