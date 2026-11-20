import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/ink_canvas_controller.dart';

/// Full-featured Excalidraw transform overlay featuring:
/// - 8 Bounding transform handles (4 corners + 4 edge midpoints)
/// - Top rotation handle for rotating selected elements
/// - Rich floating property inspector for colors, fill styles, stroke styles,
///   roughness, roundness, z-ordering, alignment, group/ungroup, flip, lock, and delete.
class SelectionOverlayWidget extends StatefulWidget {
  final InkCanvasController controller;
  final double canvasWidth;
  final double canvasHeight;

  const SelectionOverlayWidget({
    super.key,
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  State<SelectionOverlayWidget> createState() => _SelectionOverlayWidgetState();
}

class _SelectionOverlayWidgetState extends State<SelectionOverlayWidget> {
  double? _rotationStartAngle;

  static const List<int> _paletteColors = [
    0xFF18181B, // Obsidian
    0xFF2563EB, // Cobalt Blue
    0xFF10B981, // Sage Emerald
    0xFFF59E0B, // Amber
    0xFFEF4444, // Crimson
    0xFF8B5CF6, // Royal Violet
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.hasSelection ||
        widget.controller.selectionBounds == null) {
      return const SizedBox.shrink();
    }

    final bounds = widget.controller.selectionBounds!;
    final paddedBounds = bounds.inflate(6.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Action bar positioning
    final showAbove = paddedBounds.top >= 56;
    final toolbarTop = showAbove
        ? paddedBounds.top - 52
        : paddedBounds.bottom + 12;
    const toolbarWidth = 480.0;
    final toolbarLeft = (paddedBounds.center.dx - (toolbarWidth / 2))
        .clamp(8.0, math.max(8.0, widget.canvasWidth - toolbarWidth - 8.0))
        .toDouble();

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Moveable Bounding Box
          Positioned(
            left: paddedBounds.left,
            top: paddedBounds.top,
            width: paddedBounds.width,
            height: paddedBounds.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) =>
                  widget.controller.recordSelectionUndoSnapshot(),
              onPanUpdate: (details) {
                widget.controller.translateSelectedStrokes(details.delta);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x0C6366F1),
                  border: Border.all(
                    color: const Color(0xFF6366F1),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // 2. Corner Scaling Handles
          _buildCornerHandle(
            position: paddedBounds.topLeft,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.bottomRight;
              final newW = (bounds.width - delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height - delta.dy).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),
          _buildCornerHandle(
            position: paddedBounds.topRight,
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.bottomLeft;
              final newW = (bounds.width + delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height - delta.dy).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),
          _buildCornerHandle(
            position: paddedBounds.bottomLeft,
            cursor: SystemMouseCursors.resizeUpRightDownLeft,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.topRight;
              final newW = (bounds.width - delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height + delta.dy).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),
          _buildCornerHandle(
            position: paddedBounds.bottomRight,
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.topLeft;
              final newW = (bounds.width + delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height + delta.dy).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),

          // 3. Edge Midpoint Scaling Handles
          _buildEdgeHandle(
            position: Offset(paddedBounds.center.dx, paddedBounds.top),
            cursor: SystemMouseCursors.resizeUpDown,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = Offset(bounds.center.dx, bounds.bottom);
              final newH = (bounds.height - delta.dy).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                1.0,
                newH / bounds.height,
                origin,
              );
            },
          ),
          _buildEdgeHandle(
            position: Offset(paddedBounds.center.dx, paddedBounds.bottom),
            cursor: SystemMouseCursors.resizeUpDown,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = Offset(bounds.center.dx, bounds.top);
              final newH = (bounds.height + delta.dy).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                1.0,
                newH / bounds.height,
                origin,
              );
            },
          ),
          _buildEdgeHandle(
            position: Offset(paddedBounds.left, paddedBounds.center.dy),
            cursor: SystemMouseCursors.resizeLeftRight,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = Offset(bounds.right, bounds.center.dy);
              final newW = (bounds.width - delta.dx).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                newW / bounds.width,
                1.0,
                origin,
              );
            },
          ),
          _buildEdgeHandle(
            position: Offset(paddedBounds.right, paddedBounds.center.dy),
            cursor: SystemMouseCursors.resizeLeftRight,
            onPanStart: () => widget.controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = Offset(bounds.left, bounds.center.dy);
              final newW = (bounds.width + delta.dx).clamp(10.0, 5000.0);
              widget.controller.scaleSelectedStrokes(
                newW / bounds.width,
                1.0,
                origin,
              );
            },
          ),

          // 4. Rotation Handle & Stem
          Positioned(
            left: paddedBounds.center.dx - 1,
            top: paddedBounds.top - 24,
            width: 2,
            height: 24,
            child: Container(color: const Color(0xFF6366F1)),
          ),
          Positioned(
            left: paddedBounds.center.dx - 8,
            top: paddedBounds.top - 32,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  widget.controller.recordSelectionUndoSnapshot();
                  final center = bounds.center;
                  _rotationStartAngle = math.atan2(
                    details.globalPosition.dy - center.dy,
                    details.globalPosition.dx - center.dx,
                  );
                },
                onPanUpdate: (details) {
                  if (_rotationStartAngle == null) return;
                  final center = bounds.center;
                  final currentAngle = math.atan2(
                    details.globalPosition.dy - center.dy,
                    details.globalPosition.dx - center.dx,
                  );
                  final deltaAngle = currentAngle - _rotationStartAngle!;
                  _rotationStartAngle = currentAngle;
                  widget.controller.rotateSelectedStrokes(deltaAngle, center);
                },
                onPanEnd: (_) => _rotationStartAngle = null,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1),
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Floating Context Property Bar
          Positioned(
            left: toolbarLeft,
            top: toolbarTop,
            child: _buildFloatingActionBar(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerHandle({
    required Offset position,
    required MouseCursor cursor,
    required VoidCallback onPanStart,
    required void Function(Offset delta) onPanUpdate,
  }) {
    const handleSize = 14.0;
    return Positioned(
      left: position.dx - (handleSize / 2),
      top: position.dy - (handleSize / 2),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onPanStart(),
          onPanUpdate: (details) => onPanUpdate(details.delta),
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6366F1), width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle({
    required Offset position,
    required MouseCursor cursor,
    required VoidCallback onPanStart,
    required void Function(Offset delta) onPanUpdate,
  }) {
    const handleW = 12.0;
    const handleH = 8.0;
    return Positioned(
      left: position.dx - (handleW / 2),
      top: position.dy - (handleH / 2),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => onPanStart(),
          onPanUpdate: (details) => onPanUpdate(details.delta),
          child: Container(
            width: handleW,
            height: handleH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionBar(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3343) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stroke Color Swatches
              ..._paletteColors.map((colorVal) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () =>
                        widget.controller.recolorSelectedStrokes(colorVal),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              _buildDivider(isDark),

              // Fill Style Switcher
              PopupMenuButton<String>(
                icon: const Icon(Icons.format_color_fill_rounded, size: 16),
                tooltip: 'Fill Style',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onSelected: (style) {
                  widget.controller.updateSelectedStrokesStyle(
                    fillStyle: style,
                    fillColor: style == 'none' ? null : 0xFF2563EB,
                  );
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'none',
                    child: Text('Transparent / None'),
                  ),
                  const PopupMenuItem(
                    value: 'hachure',
                    child: Text('Hachure (Diagonal)'),
                  ),
                  const PopupMenuItem(
                    value: 'cross-hatch',
                    child: Text('Cross-Hatch'),
                  ),
                  const PopupMenuItem(
                    value: 'solid',
                    child: Text('Solid Fill'),
                  ),
                  const PopupMenuItem(
                    value: 'dots',
                    child: Text('Sketchy Dots'),
                  ),
                ],
              ),

              // Stroke Width
              PopupMenuButton<double>(
                icon: const Icon(Icons.line_weight_rounded, size: 16),
                tooltip: 'Stroke Width',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onSelected: (w) =>
                    widget.controller.updateSelectedStrokesStyle(baseWidth: w),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 1.5, child: Text('Thin (1.5px)')),
                  const PopupMenuItem(
                    value: 3.0,
                    child: Text('Medium (3.0px)'),
                  ),
                  const PopupMenuItem(value: 5.0, child: Text('Bold (5.0px)')),
                  const PopupMenuItem(
                    value: 8.0,
                    child: Text('Extra Bold (8.0px)'),
                  ),
                ],
              ),

              // Stroke Style
              PopupMenuButton<String>(
                icon: const Icon(Icons.border_style_rounded, size: 16),
                tooltip: 'Stroke Style',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onSelected: (s) => widget.controller.updateSelectedStrokesStyle(
                  strokeStyle: s,
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'solid',
                    child: Text('Solid Stroke'),
                  ),
                  const PopupMenuItem(
                    value: 'dashed',
                    child: Text('Dashed Stroke'),
                  ),
                  const PopupMenuItem(
                    value: 'dotted',
                    child: Text('Dotted Stroke'),
                  ),
                ],
              ),

              // Roughness (Sloppiness)
              PopupMenuButton<double>(
                icon: const Icon(Icons.brush_outlined, size: 16),
                tooltip: 'Roughness / Sloppiness',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onSelected: (r) =>
                    widget.controller.updateSelectedStrokesStyle(roughness: r),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 0.0,
                    child: Text('Architect (Clean Vector)'),
                  ),
                  const PopupMenuItem(
                    value: 1.0,
                    child: Text('Artist (Natural Sketch)'),
                  ),
                  const PopupMenuItem(
                    value: 2.0,
                    child: Text('Cartoonist (Playful Rough)'),
                  ),
                ],
              ),

              // Roundness (Corners)
              IconButton(
                icon: const Icon(Icons.rounded_corner_rounded, size: 16),
                tooltip: 'Toggle Round Corners',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () {
                  final cur =
                      widget
                          .controller
                          .selectedStrokes
                          .firstOrNull
                          ?.roundness ??
                      'sharp';
                  final next = cur == 'sharp' ? 'round' : 'sharp';
                  widget.controller.updateSelectedStrokesStyle(roundness: next);
                },
              ),

              _buildDivider(isDark),

              // Layer Ordering (Bring to Front, Send to Back)
              IconButton(
                icon: const Icon(Icons.flip_to_front_rounded, size: 16),
                tooltip: 'Bring to Front',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => widget.controller.bringToFront(),
              ),
              IconButton(
                icon: const Icon(Icons.flip_to_back_rounded, size: 16),
                tooltip: 'Send to Back',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => widget.controller.sendToBack(),
              ),

              // Alignment Popover
              PopupMenuButton<String>(
                icon: const Icon(Icons.align_horizontal_left_rounded, size: 16),
                tooltip: 'Align Elements',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onSelected: (align) =>
                    widget.controller.alignSelectedStrokes(align),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'left', child: Text('Align Left')),
                  const PopupMenuItem(
                    value: 'center',
                    child: Text('Align Center'),
                  ),
                  const PopupMenuItem(
                    value: 'right',
                    child: Text('Align Right'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'top', child: Text('Align Top')),
                  const PopupMenuItem(
                    value: 'middle',
                    child: Text('Align Middle'),
                  ),
                  const PopupMenuItem(
                    value: 'bottom',
                    child: Text('Align Bottom'),
                  ),
                ],
              ),

              // Flip Operations
              IconButton(
                icon: const Icon(Icons.flip_rounded, size: 16),
                tooltip: 'Flip Horizontal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () =>
                    widget.controller.flipSelectedStrokesHorizontal(),
              ),

              // Group / Ungroup
              IconButton(
                icon: const Icon(Icons.group_work_outlined, size: 16),
                tooltip: 'Group / Ungroup',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () {
                  final anyGrouped = widget.controller.selectedStrokes.any(
                    (s) => s.groupId != null,
                  );
                  if (anyGrouped) {
                    widget.controller.ungroupSelectedStrokes();
                  } else {
                    widget.controller.groupSelectedStrokes();
                  }
                },
              ),

              // Lock / Unlock
              IconButton(
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                tooltip: 'Lock / Unlock',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () => widget.controller.toggleLockSelectedStrokes(),
              ),

              _buildDivider(isDark),

              // Duplicate Button
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                color: const Color(0xFF6366F1),
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Duplicate',
                onPressed: () => widget.controller.duplicateSelectedStrokes(),
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: const Color(0xFFEF4444),
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Delete',
                onPressed: () => widget.controller.deleteSelectedStrokes(),
              ),

              // Close / Deselect Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: const Color(0xFF64748B),
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Deselect',
                onPressed: () => widget.controller.clearSelection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF2D3343) : const Color(0xFFE2E8F0),
    );
  }
}
