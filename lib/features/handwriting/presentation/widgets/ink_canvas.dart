import 'package:flutter/material.dart';

import '../controllers/ink_canvas_controller.dart';
import 'ink_document_painter.dart';

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
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.readOnly) return;
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
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.readOnly) return;
    widget.controller.endStroke();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (widget.readOnly) return;
    widget.controller.endStroke();
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
                activeTool: widget.controller.activeTool,
                isDrawing: widget.controller.isDrawing,
                drawBackground:
                    widget.drawBackground && widget.backgroundWidget == null,
                renderCache: widget.controller.renderCache,
                revision: widget.controller.revision,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
