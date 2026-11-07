import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../handwriting/domain/models/ink_tool.dart';
import '../../../handwriting/presentation/controllers/ink_canvas_controller.dart';
import '../../../handwriting/presentation/widgets/ink_canvas.dart';
import '../../data/services/document_content_service.dart';
import '../../domain/models/document_embed_models.dart';

/// Embed builder for rendering inline Vector Ink sketch blocks inside documents.
class InkBlockEmbedBuilder extends EmbedBuilder {
  const InkBlockEmbedBuilder();

  @override
  String get key => InkBlockEmbed.inkBlockType;

  @override
  bool get expanded => true;

  @override
  String toPlainText(Embed node) => ' [Ink Sketch] ';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Consumer(
      builder: (context, ref, child) {
        return InkBlockWidget(embedContext: embedContext, ref: ref);
      },
    );
  }
}

class InkBlockWidget extends StatefulWidget {
  final EmbedContext embedContext;
  final WidgetRef ref;

  const InkBlockWidget({
    super.key,
    required this.embedContext,
    required this.ref,
  });

  @override
  State<InkBlockWidget> createState() => _InkBlockWidgetState();
}

class _InkBlockWidgetState extends State<InkBlockWidget> {
  late InkBlockEmbed _embedData;
  InkCanvasController? _canvasController;
  bool _isLoading = true;
  Timer? _debounceSaveTimer;
  bool _isSavingInk = false;

  int _selectedColor = 0xFF6366F1;
  InkToolType _selectedTool = InkToolType.ballpointPen;
  double _strokeWidth = 2.5;

  static const List<int> presetColors = [
    0xFF18181B, // Dark ink
    0xFFFFFFFF, // White ink
    0xFF6366F1, // Indigo Slate
    0xFF10B981, // Sage Emerald
    0xFFF97316, // Terracotta
    0xFFF59E0B, // Amber
  ];

  @override
  void initState() {
    super.initState();
    _embedData = InkBlockEmbed.fromData(widget.embedContext.node.value.data);
    _initializeInkDocument();
  }

  @override
  void didUpdateWidget(InkBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedContext.node.value.data !=
        widget.embedContext.node.value.data) {
      final updated = InkBlockEmbed.fromData(
        widget.embedContext.node.value.data,
      );
      if (updated.inkHash != _embedData.inkHash && updated.inkHash.isNotEmpty) {
        _embedData = updated;
        _initializeInkDocument();
      }
    }
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _canvasController?.dispose();
    super.dispose();
  }

  Future<void> _initializeInkDocument() async {
    setState(() => _isLoading = true);

    final blobStorage = widget.ref.read(blobStorageServiceProvider);
    final contentService = DocumentContentService(blobStorage: blobStorage);

    final height = _embedData.height;
    final doc = await contentService.loadInkBlockDrawing(
      _embedData.inkHash,
      documentId: 'sketch_${DateTime.now().millisecondsSinceEpoch}',
      width: _embedData.width ?? 760.0,
      height: height,
    );

    _canvasController?.dispose();
    final controller = InkCanvasController(
      document: doc,
      initialTool: InkToolConfig(
        type: _selectedTool,
        color: _selectedColor,
        baseWidth: _strokeWidth,
      ),
    );

    controller.addListener(_onCanvasChanged);

    if (mounted) {
      setState(() {
        _canvasController = controller;
        _isLoading = false;
      });
    }
  }

  void _onCanvasChanged() {
    if (widget.embedContext.readOnly) return;
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 800), () {
      _saveInkSketch();
    });
  }

  Future<void> _saveInkSketch() async {
    final controller = _canvasController;
    if (controller == null || _isSavingInk) return;

    _isSavingInk = true;
    try {
      final blobStorage = widget.ref.read(blobStorageServiceProvider);
      final contentService = DocumentContentService(blobStorage: blobStorage);

      final newHash = await contentService.saveInkBlockDrawing(
        controller.document,
      );

      if (newHash != _embedData.inkHash) {
        _embedData = _embedData.copyWith(inkHash: newHash);

        final quill = widget.embedContext.controller;
        final node = widget.embedContext.node;
        final offset = node.documentOffset;

        final newEmbed = BlockEmbed(
          InkBlockEmbed.inkBlockType,
          jsonEncode(_embedData.toMap()),
        );
        quill.replaceText(offset, 1, newEmbed, null);
      }
    } catch (_) {
      // Ignored - will retry on next stroke
    } finally {
      _isSavingInk = false;
    }
  }

  void _selectTool(InkToolType tool) {
    _selectedTool = tool;
    double width = 2.5;
    if (tool == InkToolType.highlighter) {
      width = 16.0;
    } else if (tool == InkToolType.vectorEraser) {
      width = 8.0;
    }
    _strokeWidth = width;

    _canvasController?.setTool(
      InkToolConfig(type: tool, color: _selectedColor, baseWidth: width),
    );
    setState(() {});
  }

  void _selectColor(int color) {
    _selectedColor = color;
    _canvasController?.setTool(
      InkToolConfig(type: _selectedTool, color: color, baseWidth: _strokeWidth),
    );
    setState(() {});
  }

  void _deleteBlock() {
    final quill = widget.embedContext.controller;
    final node = widget.embedContext.node;
    final offset = node.documentOffset;
    quill.replaceText(offset, 1, '', null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AtlasSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AtlasColors.darkCard : AtlasColors.lightCard,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
        border: Border.all(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Mini Palette Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpacing.md,
              vertical: AtlasSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AtlasColors.darkElevated
                  : AtlasColors.lightElevated,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.gesture,
                  size: 16,
                  color: AtlasColors.accentBlue,
                ),
                const SizedBox(width: AtlasSpacing.xs),
                Text(
                  'Vector Ink Canvas',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!widget.embedContext.readOnly) ...[
                  // Tool Selectors
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: 'Pen',
                    color: _selectedTool == InkToolType.ballpointPen
                        ? AtlasColors.accentBlue
                        : null,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () => _selectTool(InkToolType.ballpointPen),
                  ),
                  IconButton(
                    icon: const Icon(Icons.brush, size: 16),
                    tooltip: 'Highlighter',
                    color: _selectedTool == InkToolType.highlighter
                        ? AtlasColors.accentBlue
                        : null,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () => _selectTool(InkToolType.highlighter),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_fix_normal, size: 16),
                    tooltip: 'Eraser',
                    color: _selectedTool == InkToolType.vectorEraser
                        ? AtlasColors.accentBlue
                        : null,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () => _selectTool(InkToolType.vectorEraser),
                  ),
                  const SizedBox(width: AtlasSpacing.sm),
                  // Color swatches
                  ...presetColors.map((colValue) {
                    final isSelected = _selectedColor == colValue;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => _selectColor(colValue),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Color(colValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AtlasColors.accentBlue
                                  : isDark
                                  ? Colors.white24
                                  : Colors.black26,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: AtlasSpacing.sm),
                  // Clear Canvas
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    tooltip: 'Clear Drawing',
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () => _canvasController?.clear(),
                  ),
                  // Delete Block
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Remove Ink Block',
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: _deleteBlock,
                  ),
                ],
              ],
            ),
          ),

          // Canvas Body
          SizedBox(
            height: _embedData.height,
            child: _isLoading || _canvasController == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasWidth = constraints.maxWidth > 0
                          ? constraints.maxWidth
                          : 760.0;
                      return GestureDetector(
                        // Intercept gestures so scroll view does not steal drawing strokes
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragDown: (_) {},
                        onVerticalDragUpdate: (_) {},
                        onHorizontalDragUpdate: (_) {},
                        child: InkCanvas(
                          controller: _canvasController!,
                          width: canvasWidth,
                          height: _embedData.height,
                          readOnly: widget.embedContext.readOnly,
                          drawBackground: false,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
