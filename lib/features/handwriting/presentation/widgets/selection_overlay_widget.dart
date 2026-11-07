import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/ink_canvas_controller.dart';

/// Floating vector selection overlay displaying a dashed bounding box,
/// four corner scale handles, and a floating action bar for Goodnotes-style
/// stroke transformations (translate, scale, duplicate, recolor, delete).
class SelectionOverlayWidget extends StatelessWidget {
  final InkCanvasController controller;
  final double canvasWidth;
  final double canvasHeight;

  const SelectionOverlayWidget({
    super.key,
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  static const List<int> _paletteColors = [
    0xFF18181B, // Obsidian
    0xFF6366F1, // Indigo
    0xFF10B981, // Sage Emerald
    0xFFF59E0B, // Amber
    0xFFEF4444, // Crimson
  ];

  @override
  Widget build(BuildContext context) {
    if (!controller.hasSelection || controller.selectionBounds == null) {
      return const SizedBox.shrink();
    }

    final bounds = controller.selectionBounds!;
    // Add comfortable padding around strokes
    final paddedBounds = bounds.inflate(6.0);

    // Calculate action bar position
    final showAbove = paddedBounds.top >= 52;
    final toolbarTop = showAbove
        ? paddedBounds.top - 48
        : paddedBounds.bottom + 8;
    const toolbarWidth = 260.0;
    final toolbarLeft = (paddedBounds.center.dx - (toolbarWidth / 2))
        .clamp(8.0, max(8.0, canvasWidth - toolbarWidth - 8.0))
        .toDouble();

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Moveable Bounding Box Interior & Border
          Positioned(
            left: paddedBounds.left,
            top: paddedBounds.top,
            width: paddedBounds.width,
            height: paddedBounds.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => controller.recordSelectionUndoSnapshot(),
              onPanUpdate: (details) {
                controller.translateSelectedStrokes(details.delta);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x0A6366F1),
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
          // Top-Left Handle
          _buildCornerHandle(
            position: paddedBounds.topLeft,
            onPanStart: () => controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.bottomRight;
              final newW = (bounds.width - delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height - delta.dy).clamp(10.0, 5000.0);
              controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),

          // Top-Right Handle
          _buildCornerHandle(
            position: paddedBounds.topRight,
            onPanStart: () => controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.bottomLeft;
              final newW = (bounds.width + delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height - delta.dy).clamp(10.0, 5000.0);
              controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),

          // Bottom-Left Handle
          _buildCornerHandle(
            position: paddedBounds.bottomLeft,
            onPanStart: () => controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.topRight;
              final newW = (bounds.width - delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height + delta.dy).clamp(10.0, 5000.0);
              controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),

          // Bottom-Right Handle
          _buildCornerHandle(
            position: paddedBounds.bottomRight,
            onPanStart: () => controller.recordSelectionUndoSnapshot(),
            onPanUpdate: (delta) {
              final origin = bounds.topLeft;
              final newW = (bounds.width + delta.dx).clamp(10.0, 5000.0);
              final newH = (bounds.height + delta.dy).clamp(10.0, 5000.0);
              controller.scaleSelectedStrokes(
                newW / bounds.width,
                newH / bounds.height,
                origin,
              );
            },
          ),

          // 3. Floating Context Action Bar
          Positioned(
            left: toolbarLeft,
            top: toolbarTop,
            child: _buildFloatingActionBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerHandle({
    required Offset position,
    required VoidCallback onPanStart,
    required void Function(Offset delta) onPanUpdate,
  }) {
    const handleSize = 14.0;
    return Positioned(
      left: position.dx - (handleSize / 2),
      top: position.dy - (handleSize / 2),
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
    );
  }

  Widget _buildFloatingActionBar(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF181B24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D3343), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color Swatches
            ..._paletteColors.map((colorVal) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => controller.recolorSelectedStrokes(colorVal),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 6),
            const VerticalDivider(
              color: Color(0xFF2D3343),
              thickness: 1,
              width: 8,
              indent: 4,
              endIndent: 4,
            ),
            const SizedBox(width: 2),

            // Duplicate Button
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              color: const Color(0xFF94A3B8),
              hoverColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Duplicate (+20px)',
              onPressed: () => controller.duplicateSelectedStrokes(),
            ),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              color: const Color(0xFFEF4444),
              hoverColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Delete',
              onPressed: () => controller.deleteSelectedStrokes(),
            ),

            // Close / Deselect Button
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              color: const Color(0xFF64748B),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Deselect',
              onPressed: () => controller.clearSelection(),
            ),
          ],
        ),
      ),
    );
  }
}
