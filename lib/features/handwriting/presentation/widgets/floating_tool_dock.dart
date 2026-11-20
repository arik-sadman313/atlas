import 'package:flutter/material.dart';

import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';

/// Floating tool dock widget elevated with the complete Excalidraw toolset
/// and iPad note-taking ergonomics.
///
/// Features:
/// - Dockable to top or bottom edge of the screen
/// - Canvas navigation: Selection tool, Hand/Pan tool
/// - Inking tools: Pen, Highlighter, Eraser, Lasso
/// - Sketch Shapes: Rectangle, Diamond, Ellipse, Arrow, Curved Arrow, Line, Text, Sticky Note, Frame
/// - Excalidraw style flyout: Fill styles, Stroke styles, Roughness, Round corners, Arrowheads
/// - Grid Snapping toggle (20px alignment)
/// - Stroke width presets & Quick color swatches
/// - Paper stationery template picker (Ruled, Cornell, Dotted, Grid, Blank)
/// - Undo / Redo & Clear page actions
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

  static const List<double> _quickWidths = [1.5, 3.0, 5.0, 8.0];
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

                      // --- Section 0: Canvas Navigation & Selection ---
                      _buildToolButton(
                        context: context,
                        icon: Icons.near_me_rounded,
                        tooltip: 'Selection Tool (V)',
                        isSelected: activeTool.type == InkToolType.selection,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(type: InkToolType.selection),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.pan_tool_rounded,
                        tooltip: 'Hand / Pan Canvas (H)',
                        isSelected: activeTool.type == InkToolType.pan,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(type: InkToolType.pan),
                        ),
                      ),

                      _buildDivider(isDark),

                      // --- Section 1: Inking & Note-Taking Tools ---
                      _buildToolButton(
                        context: context,
                        icon: Icons.edit_rounded,
                        tooltip: 'Pen (P)',
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
                        tooltip: 'Eraser (E)',
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

                      _buildDivider(isDark),

                      // --- Section 2: Excalidraw Sketch Shapes & Elements ---
                      _buildToolButton(
                        context: context,
                        icon: Icons.crop_square_rounded,
                        tooltip: 'Excalidraw Box (R)',
                        isSelected: activeTool.type == InkToolType.rectangle,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.rectangle,
                            baseWidth: 2.5,
                            opacity: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.diamond_outlined,
                        tooltip: 'Excalidraw Diamond (D)',
                        isSelected: activeTool.type == InkToolType.diamond,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.diamond,
                            baseWidth: 2.5,
                            opacity: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.circle_outlined,
                        tooltip: 'Excalidraw Ellipse (O)',
                        isSelected: activeTool.type == InkToolType.ellipse,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.ellipse,
                            baseWidth: 2.5,
                            opacity: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.arrow_right_alt_rounded,
                        tooltip: 'Excalidraw Arrow (A)',
                        isSelected: activeTool.type == InkToolType.arrow,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.arrow,
                            baseWidth: 2.5,
                            opacity: 1.0,
                            isCurved: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.turn_right_rounded,
                        tooltip: 'Curved / Elbow Arrow',
                        isSelected: activeTool.type == InkToolType.curvedArrow,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.curvedArrow,
                            baseWidth: 2.5,
                            opacity: 1.0,
                            isCurved: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.horizontal_rule_rounded,
                        tooltip: 'Excalidraw Line (L)',
                        isSelected: activeTool.type == InkToolType.line,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.line,
                            baseWidth: 2.5,
                            opacity: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.text_fields_rounded,
                        tooltip: 'Text (T)',
                        isSelected: activeTool.type == InkToolType.text,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.text,
                            baseWidth: 1.5,
                            opacity: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.sticky_note_2_outlined,
                        tooltip: 'Sticky Note (N)',
                        isSelected: activeTool.type == InkToolType.stickyNote,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.stickyNote,
                            baseWidth: 1.5,
                            opacity: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      _buildToolButton(
                        context: context,
                        icon: Icons.crop_free_rounded,
                        tooltip: 'Frame Container (F)',
                        isSelected: activeTool.type == InkToolType.frame,
                        onTap: () => widget.controller.setTool(
                          activeTool.copyWith(
                            type: InkToolType.frame,
                            baseWidth: 2.0,
                            opacity: 1.0,
                          ),
                        ),
                      ),

                      // --- Section 3: Excalidraw Style & Fill Controls ---
                      _buildDivider(isDark),

                      // Style Flyout
                      PopupMenuButton<String>(
                        icon: Icon(
                          activeTool.fillStyle == 'hachure'
                              ? Icons.texture_rounded
                              : (activeTool.fillStyle == 'cross-hatch'
                                    ? Icons.grid_3x3_rounded
                                    : (activeTool.fillStyle == 'solid'
                                          ? Icons.format_color_fill_rounded
                                          : (activeTool.fillStyle == 'dots'
                                                ? Icons.grain_rounded
                                                : Icons
                                                      .format_color_reset_rounded))),
                          size: 18,
                        ),
                        tooltip: 'Excalidraw Fill & Roughness',
                        onSelected: (val) {
                          if (val.startsWith('fill:')) {
                            final style = val.substring(5);
                            widget.controller.setTool(
                              activeTool.copyWith(
                                fillStyle: style,
                                fillColor: style == 'none'
                                    ? null
                                    : (activeTool.fillColor ??
                                          activeTool.color),
                              ),
                            );
                            if (widget.controller.hasSelection) {
                              widget.controller.updateSelectedStrokesStyle(
                                fillStyle: style,
                                fillColor: style == 'none'
                                    ? null
                                    : (activeTool.fillColor ??
                                          activeTool.color),
                              );
                            }
                          } else if (val.startsWith('rough:')) {
                            final r = double.tryParse(val.substring(6)) ?? 1.0;
                            widget.controller.setTool(
                              activeTool.copyWith(roughness: r),
                            );
                            if (widget.controller.hasSelection) {
                              widget.controller.updateSelectedStrokesStyle(
                                roughness: r,
                              );
                            }
                          } else if (val.startsWith('stroke:')) {
                            final s = val.substring(7);
                            widget.controller.setTool(
                              activeTool.copyWith(strokeStyle: s),
                            );
                            if (widget.controller.hasSelection) {
                              widget.controller.updateSelectedStrokesStyle(
                                strokeStyle: s,
                              );
                            }
                          } else if (val.startsWith('round:')) {
                            final r = val.substring(6);
                            widget.controller.setTool(
                              activeTool.copyWith(roundness: r),
                            );
                            if (widget.controller.hasSelection) {
                              widget.controller.updateSelectedStrokesStyle(
                                roundness: r,
                              );
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            enabled: false,
                            child: Text(
                              'FILL STYLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'fill:none',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.format_color_reset_rounded,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('None (Transparent)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'fill:hachure',
                            child: Row(
                              children: [
                                Icon(Icons.texture_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Hachure (Sketchy Hatch)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'fill:cross-hatch',
                            child: Row(
                              children: [
                                Icon(Icons.grid_3x3_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Cross-Hatch'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'fill:solid',
                            child: Row(
                              children: [
                                Icon(Icons.format_color_fill_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Solid Fill'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'fill:dots',
                            child: Row(
                              children: [
                                Icon(Icons.grain_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Sketchy Dots'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            enabled: false,
                            child: Text(
                              'SLOPPINESS / ROUGHNESS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rough:0.0',
                            child: Text('Architect (Clean & Precise)'),
                          ),
                          const PopupMenuItem(
                            value: 'rough:1.0',
                            child: Text('Artist (Classic Excalidraw)'),
                          ),
                          const PopupMenuItem(
                            value: 'rough:2.0',
                            child: Text('Cartoonist (Playful Wobble)'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            enabled: false,
                            child: Text(
                              'STROKE & CORNERS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'stroke:solid',
                            child: Text('Solid Outline'),
                          ),
                          const PopupMenuItem(
                            value: 'stroke:dashed',
                            child: Text('Dashed Outline'),
                          ),
                          const PopupMenuItem(
                            value: 'stroke:dotted',
                            child: Text('Dotted Outline'),
                          ),
                          const PopupMenuItem(
                            value: 'round:sharp',
                            child: Text('Sharp Corners'),
                          ),
                          const PopupMenuItem(
                            value: 'round:round',
                            child: Text('Round Corners'),
                          ),
                        ],
                      ),

                      // Grid Snapping Toggle
                      IconButton(
                        icon: Icon(
                          widget.controller.snapToGrid
                              ? Icons.grid_on_rounded
                              : Icons.grid_off_rounded,
                          size: 18,
                        ),
                        tooltip: widget.controller.snapToGrid
                            ? 'Snap to Grid: ON'
                            : 'Snap to Grid: OFF',
                        color: widget.controller.snapToGrid
                            ? (isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB))
                            : (isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8)),
                        splashRadius: 16,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => widget.controller.toggleSnapToGrid(),
                      ),

                      // Quick Stroke Widths
                      if (!activeTool.type.isEraser &&
                          !activeTool.type.isLasso &&
                          !activeTool.type.isSelection &&
                          !activeTool.type.isPan) ...[
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
                              activeTool.copyWith(
                                color: colorVal,
                                fillColor: activeTool.fillStyle != 'none'
                                    ? colorVal
                                    : activeTool.fillColor,
                              ),
                            ),
                          );
                        }),
                      ],

                      _buildDivider(isDark),

                      // Paper Stationery Template Quick Switcher
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.view_agenda_outlined, size: 18),
                        tooltip: 'Stationery Template',
                        onSelected: (template) {
                          widget.controller.setBackgroundTemplate(template);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'ruled',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.format_align_justify_rounded,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Ruled / Lined'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'cornell',
                            child: Row(
                              children: [
                                Icon(Icons.view_headline_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Cornell Notes'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'dotted',
                            child: Row(
                              children: [
                                Icon(Icons.drag_indicator_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Dotted Grid'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'grid',
                            child: Row(
                              children: [
                                Icon(Icons.grid_4x4_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Square Grid'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'blank',
                            child: Row(
                              children: [
                                Icon(Icons.crop_portrait_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Blank Canvas'),
                              ],
                            ),
                          ),
                        ],
                      ),

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

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF282F3E) : const Color(0xFFE2E8F0),
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

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? (isDark ? const Color(0xFF2563EB) : const Color(0xFFDBEAFE))
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF1D4ED8))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
    return Tooltip(
      message: '${widthValue.toStringAsFixed(1)}px Width',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: Container(
              width: widthValue.clamp(2.0, 10.0),
              height: widthValue.clamp(2.0, 10.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white : Colors.black87,
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
    return Tooltip(
      message: 'Color',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(colorValue),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.black26,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Colors.black38,
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
}
