import 'dart:async';
import 'dart:ui' as ui;

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
  final ValueChanged<Offset>? onCanvasPan;

  const InkCanvas({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
    this.readOnly = false,
    this.backgroundWidget,
    this.drawBackground = true,
    this.onCanvasPan,
  });

  @override
  State<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends State<InkCanvas> {
  Timer? _drawAndHoldTimer;
  int? _activeStylusPointer;
  int? _activeFingerPanPointer;
  Offset? _lastFingerPanPos;

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

    final isStylus =
        event.kind == ui.PointerDeviceKind.stylus ||
        event.kind == ui.PointerDeviceKind.invertedStylus;
    final isTouch = event.kind == ui.PointerDeviceKind.touch;

    // 1. Hardware Palm Rejection:
    // If Apple Pencil is currently in contact or inking, reject all touch events (palm/wrist resting on screen)
    if (isTouch && _activeStylusPointer != null) {
      return;
    }

    // Reject accidental large contact patches (palms, wrists, side of hand)
    if (isTouch && (event.radiusMajor > 20.0 || event.radiusMinor > 20.0)) {
      return;
    }

    // 2. Apple Pencil / Stylus Inking
    if (isStylus) {
      _activeStylusPointer = event.pointer;

      // Inverted stylus tip (eraser on compatible styluses)
      if (event.kind == ui.PointerDeviceKind.invertedStylus &&
          !widget.controller.activeTool.type.isEraser) {
        widget.controller.setTool(
          widget.controller.activeTool.copyWith(
            type: InkToolType.vectorEraser,
            baseWidth: 16.0,
          ),
        );
      }
    } else if (isTouch && !widget.controller.drawWithFinger) {
      // 3. Finger Interaction when "Draw with Finger" is OFF:
      // If the touch is within the active selection overlay bounds, allow manipulating handles.
      // Otherwise, the finger is dedicated solely to panning/scrolling the canvas!
      final hasSelection = widget.controller.hasSelection;
      final selBounds = widget.controller.selectionBounds;
      final isOnSelection =
          hasSelection &&
          selBounds != null &&
          selBounds.inflate(28.0).contains(event.localPosition);

      if (!isOnSelection) {
        _activeFingerPanPointer = event.pointer;
        _lastFingerPanPos = event.position;
        return;
      }
    }

    if (widget.controller.activeTool.type == InkToolType.text) {
      _showTextInputDialog(event.localPosition);
      return;
    }

    if (widget.controller.activeTool.type == InkToolType.stickyNote) {
      _showStickyNoteDialog(event.localPosition);
      return;
    }

    if (widget.controller.activeTool.type == InkToolType.frame) {
      _showFrameDialog(event.localPosition);
      return;
    }

    // Capture real hardware pressure & tilt angles from Apple Pencil
    final pressure = event.pressure == 0.0
        ? 0.5
        : event.pressure.clamp(0.01, 1.0);
    final tiltAltitude = event.tilt;
    final tiltAzimuth = event.orientation;

    widget.controller.startStroke(
      event.localPosition,
      pressure: pressure,
      tiltAzimuth: tiltAzimuth,
      tiltAltitude: tiltAltitude,
    );
  }

  void _showStickyNoteDialog(Offset position) {
    final textCtrl = TextEditingController();
    int selectedColor = 0xFFFFF9B1; // Classic canary yellow

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.sticky_note_2_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 8),
              Text('New Sticky Note'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type note thoughts...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              const Text(
                'Note Color',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    [
                      0xFFFFF9B1, // Canary Yellow
                      0xFFE0F2FE, // Sky Blue
                      0xFFDCFCE7, // Mint Green
                      0xFFFCE7F3, // Soft Pink
                      0xFFEDE9FE, // Lavender
                    ].map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setDlgState(() => selectedColor = color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.black26,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textCtrl.text.trim().isNotEmpty) {
                  widget.controller.addStickyNote(
                    position,
                    textCtrl.text.trim(),
                    bgColor: selectedColor,
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Create Note'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFrameDialog(Offset position) {
    final titleCtrl = TextEditingController(text: 'Section');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.crop_free_rounded, size: 20, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Create Frame Container'),
          ],
        ),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Frame Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim().isEmpty
                  ? 'Frame'
                  : titleCtrl.text.trim();
              final snapped = widget.controller.snapPoint(position);
              final frameBounds = Rect.fromLTWH(
                snapped.dx,
                snapped.dy,
                320,
                240,
              );
              widget.controller.addFrame(frameBounds, title);
              Navigator.of(ctx).pop();
            },
            child: const Text('Create Frame'),
          ),
        ],
      ),
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (widget.readOnly) return;

    // Handle finger panning when Draw with Finger is OFF
    if (event.pointer == _activeFingerPanPointer) {
      if (_lastFingerPanPos != null && widget.onCanvasPan != null) {
        final delta = event.position - _lastFingerPanPos!;
        _lastFingerPanPos = event.position;
        widget.onCanvasPan!(delta);
      }
      return;
    }

    // Hardware Palm Rejection: If an Apple Pencil is active, ignore secondary touch pointer moves
    if (_activeStylusPointer != null && event.pointer != _activeStylusPointer) {
      return;
    }

    if (!widget.controller.isDrawing) return;

    final pressure = event.pressure == 0.0
        ? 0.5
        : event.pressure.clamp(0.01, 1.0);
    final tiltAltitude = event.tilt;
    final tiltAzimuth = event.orientation;

    widget.controller.updateStroke(
      event.localPosition,
      pressure: pressure,
      tiltAzimuth: tiltAzimuth,
      tiltAltitude: tiltAltitude,
    );

    // iPad Draw-and-Hold Shape Recognition:
    // If drawing freehand and user pauses at the end of the stroke for 450ms without lifting
    final tool = widget.controller.activeTool.type;
    final isFreehand =
        tool == InkToolType.ballpointPen ||
        tool == InkToolType.fountainPen ||
        tool == InkToolType.pencil;

    if (isFreehand && widget.controller.activePoints.length >= 8) {
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

    if (event.pointer == _activeFingerPanPointer) {
      _activeFingerPanPointer = null;
      _lastFingerPanPos = null;
      return;
    }

    if (event.pointer == _activeStylusPointer) {
      _activeStylusPointer = null;
    }

    if (widget.controller.activeTool.type != InkToolType.text) {
      widget.controller.endStroke();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _drawAndHoldTimer?.cancel();
    if (widget.readOnly) return;

    if (event.pointer == _activeFingerPanPointer) {
      _activeFingerPanPointer = null;
      _lastFingerPanPos = null;
      return;
    }

    if (event.pointer == _activeStylusPointer) {
      _activeStylusPointer = null;
    }

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
                widget.controller.addTextElement(
                  position,
                  textCtrl.text.trim(),
                );
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
