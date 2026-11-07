import 'package:flutter/material.dart';

import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';

/// Compact, floating tool dock widget for Goodnotes-grade ink workflows.
///
/// Features:
/// - Dockable to top or bottom edge of canvas
/// - 1-tap tool switcher: Pen, Highlighter, Eraser, Lasso
/// - 3 quick stroke widths: Fine (1.5px), Medium (3.0px), Bold (6.0px)
/// - 3 quick colors: Obsidian Black (#18181B), Indigo Slate (#6366F1), Sage Emerald (#10B981)
/// - Undo / Redo & Clear actions
class FloatingToolDock extends StatefulWidget {
  final InkCanvasController controller;
  final VoidCallback? onClearRequested;
  final bool initialDockedTop;

  const FloatingToolDock({
    super.key,
    required this.controller,
    this.onClearRequested,
    this.initialDockedTop = false,
  });

  @override
  State<FloatingToolDock> createState() => _FloatingToolDockState();
}

class _FloatingToolDockState extends State<FloatingToolDock> {
  late bool _dockedTop;

  static const List<double> _quickWidths = [1.5, 3.0, 6.0, 12.0];
  static const List<int> _quickColors = [
    0xFF18181B, // Obsidian Charcoal
    0xFF2563EB, // Cobalt Blue
    0xFF10B981, // Sage Emerald
    0xFFF59E0B, // Amber Ochre
    0xFFEF4444, // Crimson Red
    0xFF8B5CF6, // Royal Violet
  ];

  @override
  void initState() {
    super.initState();
    _dockedTop = widget.initialDockedTop;
  }

  void _toggleDockPosition() {
    setState(() {
      _dockedTop = !_dockedTop;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final activeTool = widget.controller.activeTool;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          top: _dockedTop ? 16 : null,
          bottom: !_dockedTop ? 20 : null,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
              borderRadius: BorderRadius.circular(32),
              color: isDark ? const Color(0xFF14171F) : Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF282F3E)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    // Position Toggle (Top/Bottom Dock)
                    IconButton(
                      icon: Icon(
                        _dockedTop
                            ? Icons.keyboard_double_arrow_down_rounded
                            : Icons.keyboard_double_arrow_up_rounded,
                        size: 18,
                      ),
                      tooltip: _dockedTop ? 'Dock at Bottom' : 'Dock at Top',
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      splashRadius: 16,
                      visualDensity: VisualDensity.compact,
                      onPressed: _toggleDockPosition,
                    ),

                    _buildDivider(isDark),

                    // 1-Tap Tool Switcher
                    _buildToolButton(
                      context: context,
                      icon: Icons.edit_rounded,
                      tooltip: 'Pen',
                      isSelected: activeTool.type == InkToolType.ballpointPen,
                      onTap: () => widget.controller.setTool(
                        activeTool.copyWith(
                          type: InkToolType.ballpointPen,
                          baseWidth: 3.0,
                          opacity: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    _buildToolButton(
                      context: context,
                      icon: Icons.highlight_rounded,
                      tooltip: 'Highlighter',
                      isSelected: activeTool.type == InkToolType.highlighter,
                      onTap: () => widget.controller.setTool(
                        activeTool.copyWith(
                          type: InkToolType.highlighter,
                          baseWidth: 16.0,
                          opacity: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    _buildToolButton(
                      context: context,
                      icon: Icons.auto_fix_normal_rounded,
                      tooltip: 'Eraser',
                      isSelected: activeTool.type.isEraser,
                      onTap: () => widget.controller.setTool(
                        activeTool.copyWith(
                          type: InkToolType.vectorEraser,
                          baseWidth: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    _buildToolButton(
                      context: context,
                      icon: Icons.gesture_rounded,
                      tooltip: 'Lasso Select',
                      isSelected: activeTool.type == InkToolType.lasso,
                      onTap: () => widget.controller.setTool(
                        activeTool.copyWith(
                          type: InkToolType.lasso,
                          baseWidth: 2.0,
                        ),
                      ),
                    ),

                    // Width & Color Selectors (shown when not in Eraser/Lasso)
                    if (!activeTool.type.isEraser &&
                        !activeTool.type.isLasso) ...[
                      _buildDivider(isDark),

                      // Quick Stroke Widths
                      ..._quickWidths.map((w) {
                        final isSelected =
                            (activeTool.baseWidth - w).abs() < 0.5;
                        return _buildWidthButton(
                          widthValue: w,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => widget.controller.setTool(
                            activeTool.copyWith(baseWidth: w),
                          ),
                        );
                      }),

                      _buildDivider(isDark),

                      // Quick Colors
                      ..._quickColors.map((colorVal) {
                        final isSelected = activeTool.color == colorVal;
                        return _buildColorSwatch(
                          colorValue: colorVal,
                          isSelected: isSelected,
                          onTap: () => widget.controller.setTool(
                            activeTool.copyWith(color: colorVal),
                          ),
                        );
                      }),
                    ],

                    // Lasso Selection Contextual Actions
                    if (activeTool.type.isLasso &&
                        widget.controller.hasSelection) ...[
                      _buildDivider(isDark),

                      // Duplicate Selection
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Duplicate Selection',
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                        splashRadius: 16,
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            widget.controller.duplicateSelectedStrokes(),
                      ),

                      // Recolor Selection (Quick Color Swatches)
                      ..._quickColors.take(4).map((colorVal) {
                        return _buildColorSwatch(
                          colorValue: colorVal,
                          isSelected: false,
                          onTap: () => widget.controller.recolorSelectedStrokes(
                            colorVal,
                          ),
                        );
                      }),

                      // Delete Selection
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        tooltip: 'Delete Selected Strokes',
                        color: const Color(0xFFEF4444),
                        splashRadius: 16,
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            widget.controller.deleteSelectedStrokes(),
                      ),

                      // Deselect
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        tooltip: 'Deselect',
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        splashRadius: 16,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => widget.controller.clearSelection(),
                      ),
                    ],

                    _buildDivider(isDark),

                    // Undo / Redo Actions
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      tooltip: 'Undo',
                      color: widget.controller.canUndo
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (isDark ? Colors.white24 : Colors.black26),
                      onPressed: widget.controller.canUndo
                          ? widget.controller.undo
                          : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, size: 18),
                      tooltip: 'Redo',
                      color: widget.controller.canRedo
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (isDark ? Colors.white24 : Colors.black26),
                      onPressed: widget.controller.canRedo
                          ? widget.controller.redo
                          : null,
                      visualDensity: VisualDensity.compact,
                    ),

                    if (widget.onClearRequested != null) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        tooltip: 'Clear Page',
                        color: isDark ? const Color(0xFFEF4444) : Colors.red,
                        onPressed: widget.controller.document.isEmpty
                            ? null
                            : widget.onClearRequested,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = const Color(0xFF6366F1).withValues(alpha: 0.18);
    final activeColor = const Color(0xFF6366F1);
    final inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(
                      color: activeColor.withValues(alpha: 0.5),
                      width: 1.2,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 19,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidthButton({
    required double widthValue,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final indicatorSize = widthValue * 1.8 + 2.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: '${widthValue}px',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Container(
              width: indicatorSize.clamp(3.0, 14.0),
              height: indicatorSize.clamp(3.0, 14.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch({
    required int colorValue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Color(colorValue),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x556366F1),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? const Color(0xFF282F3E) : const Color(0xFFE2E8F0),
    );
  }
}
