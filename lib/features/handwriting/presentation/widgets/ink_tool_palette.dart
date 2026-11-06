import 'package:flutter/material.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';

/// Floating adaptive tool palette for Atlas ink surfaces.
///
/// Provides tool selection (ballpoint pen, fountain pen, highlighter, eraser),
/// stroke width adjustment, curated color palette swatches, and undo/redo controls.
class InkToolPalette extends StatelessWidget {
  final InkCanvasController controller;
  final VoidCallback? onClearRequested;

  const InkToolPalette({
    super.key,
    required this.controller,
    this.onClearRequested,
  });

  static const List<int> defaultColors = [
    0xFF18181B, // Charcoal / Black
    0xFF1D4ED8, // Deep Blue
    0xFFDC2626, // Crimson Red
    0xFF059669, // Forest Green
    0xFFFACC15, // Highlighter Yellow
    0xFF7C3AED, // Violet
  ];

  static const List<double> penWidths = [1.5, 3.0, 5.0];
  static const List<double> highlighterWidths = [10.0, 18.0, 26.0];
  static const List<double> eraserWidths = [8.0, 16.0, 28.0];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final activeTool = controller.activeTool;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Material(
          elevation: 6,
          shadowColor: Colors.black.withAlpha(isDark ? 80 : 30),
          borderRadius: BorderRadius.circular(32),
          color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Tool Selection Group ---
                  _buildToolButton(
                    context: context,
                    icon: Icons.edit_outlined,
                    tooltip: 'Ballpoint Pen',
                    isSelected: activeTool.type == InkToolType.ballpointPen,
                    onTap: () => controller.setTool(
                      activeTool.copyWith(
                        type: InkToolType.ballpointPen,
                        baseWidth: 3.0,
                        opacity: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildToolButton(
                    context: context,
                    icon: Icons.draw_outlined,
                    tooltip: 'Fountain Pen',
                    isSelected: activeTool.type == InkToolType.fountainPen,
                    onTap: () => controller.setTool(
                      activeTool.copyWith(
                        type: InkToolType.fountainPen,
                        baseWidth: 3.5,
                        opacity: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildToolButton(
                    context: context,
                    icon: Icons.highlight_outlined,
                    tooltip: 'Highlighter',
                    isSelected: activeTool.type == InkToolType.highlighter,
                    onTap: () => controller.setTool(
                      activeTool.copyWith(
                        type: InkToolType.highlighter,
                        baseWidth: 18.0,
                        opacity: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildToolButton(
                    context: context,
                    icon: Icons.auto_fix_normal_outlined,
                    tooltip: 'Vector Eraser',
                    isSelected: activeTool.type == InkToolType.vectorEraser,
                    onTap: () => controller.setTool(
                      activeTool.copyWith(
                        type: InkToolType.vectorEraser,
                        baseWidth: 16.0,
                      ),
                    ),
                  ),

                  _buildDivider(isDark),

                  // --- Width Selection Group ---
                  ..._buildWidthSelectors(context, activeTool),

                  if (!activeTool.type.isEraser) ...[
                    _buildDivider(isDark),

                    // --- Color Swatches ---
                    ...defaultColors.map(
                      (c) => _buildColorSwatch(
                        context: context,
                        colorValue: c,
                        isSelected: activeTool.color == c,
                        onTap: () =>
                            controller.setTool(activeTool.copyWith(color: c)),
                      ),
                    ),
                  ],

                  _buildDivider(isDark),

                  // --- Undo / Redo / Clear Actions ---
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: 'Undo',
                    onPressed: controller.canUndo ? controller.undo : null,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    tooltip: 'Redo',
                    onPressed: controller.canRedo ? controller.redo : null,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Clear Page',
                    onPressed: controller.document.isEmpty
                        ? null
                        : () => _confirmClear(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? (isDark
                  ? AtlasColors.accentBlueSubtle
                  : AtlasColors.accentBlueSubtle)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
              border: isSelected
                  ? Border.all(
                      color: AtlasColors.accentBlue.withAlpha(150),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AtlasColors.accentBlue
                  : (isDark
                        ? AtlasColors.darkTextSecondary
                        : AtlasColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWidthSelectors(
    BuildContext context,
    InkToolConfig activeTool,
  ) {
    List<double> widths;
    if (activeTool.type.isEraser) {
      widths = eraserWidths;
    } else if (activeTool.type.isHighlighter) {
      widths = highlighterWidths;
    } else {
      widths = penWidths;
    }

    return widths.map((w) {
      final isSelected = (activeTool.baseWidth - w).abs() < 0.5;
      final dotSize = activeTool.type.isHighlighter
          ? (w / 2.5).clamp(6.0, 16.0)
          : (w * 2).clamp(4.0, 14.0);

      return Tooltip(
        message: 'Width: ${w.toStringAsFixed(1)}px',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.setTool(activeTool.copyWith(baseWidth: w)),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AtlasColors.accentBlue,
                      width: 1.5,
                    ),
                  )
                : null,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AtlasColors.accentBlue
                    : Theme.of(context).brightness == Brightness.dark
                    ? AtlasColors.darkTextMuted
                    : AtlasColors.lightTextMuted,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildColorSwatch({
    required BuildContext context,
    required int colorValue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = Color(colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message:
            '#${colorValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AtlasColors.accentBlue
                    : Colors.black.withAlpha(25),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 22,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear ink page?'),
        content: const Text(
          'This will erase all handwritten strokes on this page. You can undo this action immediately if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.clear();
              onClearRequested?.call();
            },
            child: const Text('Clear Page'),
          ),
        ],
      ),
    );
  }
}
