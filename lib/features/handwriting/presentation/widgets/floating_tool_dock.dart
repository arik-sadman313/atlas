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
  bool _isCollapsed = false;

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
                child: _isCollapsed
                    ? _buildCollapsedDock(context, activeTool, isDark)
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Minimize / Distraction-Free Toggle
                            IconButton(
                              icon: const Icon(
                                Icons.unfold_less_rounded,
                                size: 18,
                              ),
                              tooltip: 'Minimize Dock (Distraction-Free)',
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              splashRadius: 16,
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _isCollapsed = true),
                            ),
                            // Position Toggle (Top/Bottom Dock)
                            IconButton(
                              icon: Icon(
                                _dockedTop
                                    ? Icons.keyboard_double_arrow_down_rounded
                                    : Icons.keyboard_double_arrow_up_rounded,
                                size: 18,
                              ),
                              tooltip: _dockedTop
                                  ? 'Dock at Bottom'
                                  : 'Dock at Top',
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
                              isSelected:
                                  activeTool.type == InkToolType.selection,
                              onTap: () => widget.controller.setTool(
                                activeTool.copyWith(
                                  type: InkToolType.selection,
                                ),
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
                            const SizedBox(width: 2),
                            // Apple Pencil & Finger Mode Toggle (iPad Optimization)
                            _buildToolButton(
                              context: context,
                              icon: widget.controller.drawWithFinger
                                  ? Icons.touch_app_rounded
                                  : Icons.do_not_touch_rounded,
                              tooltip: widget.controller.drawWithFinger
                                  ? 'Draw with Finger: ON (both finger & pencil draw)'
                                  : 'Draw with Finger: OFF (Apple Pencil only, finger scrolls/zooms)',
                              isSelected: widget.controller.drawWithFinger,
                              onTap: () {
                                widget.controller.toggleDrawWithFinger();
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.controller.drawWithFinger
                                          ? 'Finger Drawing Enabled (Both Pencil & fingers draw)'
                                          : 'Apple Pencil Only (Fingers will scroll & zoom without interrupting writing)',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),

                            _buildDivider(isDark),

                            // --- Section 1: Inking & Note-Taking Tools ---
                            _buildToolButton(
                              context: context,
                              icon: Icons.edit_rounded,
                              tooltip: 'Pen (P)',
                              isSelected:
                                  activeTool.type == InkToolType.ballpointPen,
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
                              isSelected:
                                  activeTool.type == InkToolType.highlighter,
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
                              tooltip: 'Eraser (E) - Tap again for settings',
                              isSelected: activeTool.type.isEraser,
                              onTap: () {
                                if (!activeTool.type.isEraser) {
                                  widget.controller.setTool(
                                    activeTool.copyWith(
                                      type: InkToolType.vectorEraser,
                                      baseWidth: 16.0,
                                    ),
                                  );
                                } else {
                                  _showEraserSettingsModal(context, isDark);
                                }
                              },
                              onLongPress: () =>
                                  _showEraserSettingsModal(context, isDark),
                            ),
                            const SizedBox(width: 2),
                            _buildToolButton(
                              context: context,
                              icon: Icons.gesture_rounded,
                              tooltip: 'Lasso Select - Tap again for filters',
                              isSelected: activeTool.type == InkToolType.lasso,
                              onTap: () {
                                if (activeTool.type != InkToolType.lasso) {
                                  widget.controller.setTool(
                                    activeTool.copyWith(
                                      type: InkToolType.lasso,
                                      baseWidth: 2.0,
                                    ),
                                  );
                                } else {
                                  _showLassoSettingsModal(context, isDark);
                                }
                              },
                              onLongPress: () =>
                                  _showLassoSettingsModal(context, isDark),
                            ),

                            _buildDivider(isDark),

                            // --- Section 2: Excalidraw Sketch Shapes & Elements ---
                            _buildToolButton(
                              context: context,
                              icon: Icons.crop_square_rounded,
                              tooltip: 'Excalidraw Box (R)',
                              isSelected:
                                  activeTool.type == InkToolType.rectangle,
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
                              isSelected:
                                  activeTool.type == InkToolType.diamond,
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
                              isSelected:
                                  activeTool.type == InkToolType.ellipse,
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
                              isSelected:
                                  activeTool.type == InkToolType.curvedArrow,
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
                              isSelected:
                                  activeTool.type == InkToolType.stickyNote,
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
                                                ? Icons
                                                      .format_color_fill_rounded
                                                : (activeTool.fillStyle ==
                                                          'dots'
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
                                    widget.controller
                                        .updateSelectedStrokesStyle(
                                          fillStyle: style,
                                          fillColor: style == 'none'
                                              ? null
                                              : (activeTool.fillColor ??
                                                    activeTool.color),
                                        );
                                  }
                                } else if (val.startsWith('rough:')) {
                                  final r =
                                      double.tryParse(val.substring(6)) ?? 1.0;
                                  widget.controller.setTool(
                                    activeTool.copyWith(roughness: r),
                                  );
                                  if (widget.controller.hasSelection) {
                                    widget.controller
                                        .updateSelectedStrokesStyle(
                                          roughness: r,
                                        );
                                  }
                                } else if (val.startsWith('stroke:')) {
                                  final s = val.substring(7);
                                  widget.controller.setTool(
                                    activeTool.copyWith(strokeStyle: s),
                                  );
                                  if (widget.controller.hasSelection) {
                                    widget.controller
                                        .updateSelectedStrokesStyle(
                                          strokeStyle: s,
                                        );
                                  }
                                } else if (val.startsWith('round:')) {
                                  final r = val.substring(6);
                                  widget.controller.setTool(
                                    activeTool.copyWith(roundness: r),
                                  );
                                  if (widget.controller.hasSelection) {
                                    widget.controller
                                        .updateSelectedStrokesStyle(
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
                                      Icon(
                                        Icons.format_color_fill_rounded,
                                        size: 16,
                                      ),
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
                              onPressed: () =>
                                  widget.controller.toggleSnapToGrid(),
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
                              icon: const Icon(
                                Icons.view_agenda_outlined,
                                size: 18,
                              ),
                              tooltip: 'Stationery Template',
                              onSelected: (template) {
                                widget.controller.setBackgroundTemplate(
                                  template,
                                );
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
                                      Icon(
                                        Icons.view_headline_rounded,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Cornell Notes'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'dotted',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.drag_indicator_rounded,
                                        size: 16,
                                      ),
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
                                      Icon(
                                        Icons.crop_portrait_rounded,
                                        size: 16,
                                      ),
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
                                color: isDark
                                    ? const Color(0xFFEF4444)
                                    : Colors.red,
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
    VoidCallback? onLongPress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
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

  Widget _buildCollapsedDock(
    BuildContext context,
    InkToolConfig activeTool,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Expand Button
        IconButton(
          icon: const Icon(Icons.unfold_more_rounded, size: 18),
          tooltip: 'Expand Dock',
          color: const Color(0xFF2563EB),
          splashRadius: 16,
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _isCollapsed = false),
        ),
        _buildDivider(isDark),
        // Active Tool Icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            _getToolIcon(activeTool.type),
            size: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        // Active Color dot
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(activeTool.color),
            border: Border.all(
              color: isDark ? Colors.white38 : Colors.black26,
              width: 1.5,
            ),
          ),
        ),
        // Active stroke width chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
          child: Text(
            '${activeTool.baseWidth.toStringAsFixed(activeTool.baseWidth.truncateToDouble() == activeTool.baseWidth ? 0 : 1)}px',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ),
        // Finger mode status
        IconButton(
          icon: Icon(
            widget.controller.drawWithFinger
                ? Icons.touch_app_rounded
                : Icons.do_not_touch_rounded,
            size: 16,
          ),
          tooltip: widget.controller.drawWithFinger
              ? 'Finger Drawing: ON'
              : 'Apple Pencil Only: ON',
          color: widget.controller.drawWithFinger
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          splashRadius: 14,
          visualDensity: VisualDensity.compact,
          onPressed: () {
            widget.controller.toggleDrawWithFinger();
          },
        ),
        _buildDivider(isDark),
        // Undo
        IconButton(
          icon: const Icon(Icons.undo_rounded, size: 16),
          tooltip: 'Undo',
          color: widget.controller.canUndo
              ? (isDark ? Colors.white70 : Colors.black87)
              : (isDark ? Colors.white24 : Colors.black26),
          onPressed: widget.controller.canUndo ? widget.controller.undo : null,
          visualDensity: VisualDensity.compact,
        ),
        // Redo
        IconButton(
          icon: const Icon(Icons.redo_rounded, size: 16),
          tooltip: 'Redo',
          color: widget.controller.canRedo
              ? (isDark ? Colors.white70 : Colors.black87)
              : (isDark ? Colors.white24 : Colors.black26),
          onPressed: widget.controller.canRedo ? widget.controller.redo : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _showEraserSettingsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF181B24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeTool = widget.controller.activeTool;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_fix_normal_rounded,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eraser Settings (GoodNotes Style)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Erase Highlighter Only Switch
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.highlight_rounded),
                      title: const Text('Erase Highlighter Only'),
                      subtitle: const Text(
                        'Preserve handwritten ink and only erase highlighter strokes',
                      ),
                      value: widget.controller.eraseHighlighterOnly,
                      onChanged: (val) {
                        setModalState(() {
                          widget.controller.toggleEraseHighlighterOnly(val);
                        });
                      },
                    ),
                    // Auto-Deselect Switch
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.undo_rounded),
                      title: const Text('Auto-Deselect'),
                      subtitle: const Text(
                        'Automatically switch back to Pen after lifting stylus',
                      ),
                      value: widget.controller.autoDeselectEraser,
                      onChanged: (val) {
                        setModalState(() {
                          widget.controller.toggleAutoDeselectEraser(val);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Eraser Size Chips
                    Text(
                      'ERASER SIZE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildEraserSizeChip(
                          'Small (10px)',
                          10.0,
                          activeTool,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildEraserSizeChip(
                          'Medium (22px)',
                          22.0,
                          activeTool,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildEraserSizeChip(
                          'Large (42px)',
                          42.0,
                          activeTool,
                          setModalState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Clear Page Button
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: const Text(
                        'Clear Entire Page',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.controller.clearPage();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Page cleared'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: widget.controller.undo,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEraserSizeChip(
    String label,
    double size,
    InkToolConfig activeTool,
    StateSetter setModalState,
  ) {
    final isSelected = activeTool.type.isEraser && activeTool.baseWidth == size;
    return Expanded(
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) {
          widget.controller.setTool(
            activeTool.copyWith(
              type: InkToolType.vectorEraser,
              baseWidth: size,
            ),
          );
          setModalState(() {});
        },
      ),
    );
  }

  void _showLassoSettingsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF181B24) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.gesture_rounded,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lasso Selection Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select what the lasso includes when you circle elements on the canvas:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const Divider(height: 20),
                    CheckboxListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.edit_rounded),
                      title: const Text('Handwriting & Drawing'),
                      value: widget.controller.lassoHandwriting,
                      onChanged: (val) {
                        setModalState(() {
                          widget.controller.lassoHandwriting = val ?? true;
                        });
                      },
                    ),
                    CheckboxListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.text_fields_rounded),
                      title: const Text('Text Boxes'),
                      value: widget.controller.lassoText,
                      onChanged: (val) {
                        setModalState(() {
                          widget.controller.lassoText = val ?? true;
                        });
                      },
                    ),
                    CheckboxListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.sticky_note_2_outlined),
                      title: const Text('Sticky Notes'),
                      value: widget.controller.lassoStickyNotes,
                      onChanged: (val) {
                        setModalState(() {
                          widget.controller.lassoStickyNotes = val ?? true;
                        });
                      },
                    ),
                    CheckboxListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.crop_square_rounded),
                      title: const Text('Shapes & Containers'),
                      value: widget.controller.lassoShapes,
                      onChanged: (val) {
                        setModalState(() {
                          widget.controller.lassoShapes = val ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getToolIcon(InkToolType type) {
    switch (type) {
      case InkToolType.selection:
        return Icons.near_me_rounded;
      case InkToolType.pan:
        return Icons.pan_tool_rounded;
      case InkToolType.ballpointPen:
      case InkToolType.fountainPen:
      case InkToolType.pencil:
        return Icons.edit_rounded;
      case InkToolType.highlighter:
        return Icons.highlight_rounded;
      case InkToolType.pixelEraser:
      case InkToolType.vectorEraser:
        return Icons.auto_fix_normal_rounded;
      case InkToolType.lasso:
        return Icons.gesture_rounded;
      case InkToolType.rectangle:
        return Icons.crop_square_rounded;
      case InkToolType.diamond:
        return Icons.diamond_outlined;
      case InkToolType.ellipse:
        return Icons.circle_outlined;
      case InkToolType.arrow:
        return Icons.arrow_right_alt_rounded;
      case InkToolType.curvedArrow:
        return Icons.turn_right_rounded;
      case InkToolType.line:
        return Icons.horizontal_rule_rounded;
      case InkToolType.text:
        return Icons.text_fields_rounded;
      case InkToolType.stickyNote:
        return Icons.sticky_note_2_outlined;
      case InkToolType.frame:
        return Icons.crop_free_rounded;
    }
  }
}
