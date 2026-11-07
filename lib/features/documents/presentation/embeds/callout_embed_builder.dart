import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../domain/models/document_embed_models.dart';

/// Embed builder for rendering Callout boxes in Flutter Quill editor.
class CalloutEmbedBuilder extends EmbedBuilder {
  const CalloutEmbedBuilder();

  @override
  String get key => CalloutBlockEmbed.calloutType;

  @override
  bool get expanded => true;

  @override
  String toPlainText(Embed node) {
    final callout = CalloutBlockEmbed.fromData(node.value.data);
    return callout.text.isNotEmpty ? ' ${callout.text} ' : '';
  }

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return CalloutBlockWidget(embedContext: embedContext);
  }
}

class CalloutBlockWidget extends StatefulWidget {
  final EmbedContext embedContext;

  const CalloutBlockWidget({super.key, required this.embedContext});

  @override
  State<CalloutBlockWidget> createState() => _CalloutBlockWidgetState();
}

class _CalloutBlockWidgetState extends State<CalloutBlockWidget> {
  late CalloutBlockEmbed _callout;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _isHovered = false;

  static const List<String> availableIcons = [
    '💡',
    '📌',
    '⚠️',
    'ℹ️',
    '🚀',
    '🎯',
    '📝',
    '🔥',
    '✅',
    '💬',
  ];

  static const List<String> availableColors = [
    '#6366F1', // Indigo Slate
    '#10B981', // Sage Emerald
    '#F59E0B', // Amber
    '#EF4444', // Crimson / Terracotta
    '#3B82F6', // Cobalt
    '#8B5CF6', // Violet
  ];

  @override
  void initState() {
    super.initState();
    _callout = CalloutBlockEmbed.fromData(widget.embedContext.node.value.data);
    _textController = TextEditingController(text: _callout.text);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(CalloutBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedContext.node.value.data !=
        widget.embedContext.node.value.data) {
      final updated = CalloutBlockEmbed.fromData(
        widget.embedContext.node.value.data,
      );
      if (updated.text != _textController.text) {
        _textController.text = updated.text;
      }
      _callout = updated;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return AtlasColors.accentBlue;
  }

  void _updateCallout({String? text, String? icon, String? colorHex}) {
    final updated = _callout.copyWith(
      text: text ?? _callout.text,
      icon: icon ?? _callout.icon,
      colorHex: colorHex ?? _callout.colorHex,
    );
    _callout = updated;

    final controller = widget.embedContext.controller;
    final node = widget.embedContext.node;
    final offset = node.documentOffset;

    final block = BlockEmbed(
      CalloutBlockEmbed.calloutType,
      jsonEncode(updated.toMap()),
    );
    controller.replaceText(offset, 1, block, null);
  }

  void _deleteBlock() {
    final controller = widget.embedContext.controller;
    final node = widget.embedContext.node;
    final offset = node.documentOffset;
    controller.replaceText(offset, 1, '', null);
  }

  void _showIconAndColorPicker(BuildContext context) {
    if (widget.embedContext.readOnly) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark
              ? AtlasColors.darkCard
              : AtlasColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
            side: BorderSide(
              color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            ),
          ),
          title: const Text('Callout Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Icon',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Wrap(
                spacing: AtlasSpacing.sm,
                runSpacing: AtlasSpacing.sm,
                children: availableIcons.map((ic) {
                  final isSelected = ic == _callout.icon;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    onTap: () {
                      _updateCallout(icon: ic);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AtlasColors.accentBlue.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        border: isSelected
                            ? Border.all(color: AtlasColors.accentBlue)
                            : null,
                      ),
                      child: Text(ic, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AtlasSpacing.md),
              const Text(
                'Accent Color',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Wrap(
                spacing: AtlasSpacing.sm,
                runSpacing: AtlasSpacing.sm,
                children: availableColors.map((colHex) {
                  final col = _parseColor(colHex);
                  final isSelected = colHex == _callout.colorHex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _updateCallout(colorHex: colHex);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = _parseColor(_callout.colorHex);

    final bgColor = isDark
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.08),
            AtlasColors.darkCard,
          )
        : Color.alphaBlend(
            accentColor.withValues(alpha: 0.08),
            AtlasColors.lightCard,
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AtlasSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          border: Border.all(
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Stripe
              Container(width: 4.0, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpacing.md,
                    vertical: AtlasSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Badge
                      Tooltip(
                        message: widget.embedContext.readOnly
                            ? ''
                            : 'Click to customize',
                        child: InkWell(
                          onTap: widget.embedContext.readOnly
                              ? null
                              : () => _showIconAndColorPicker(context),
                          borderRadius: BorderRadius.circular(
                            AtlasSpacing.radiusSm,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              _callout.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AtlasSpacing.sm),
                      // Callout Text Editor
                      Expanded(
                        child: widget.embedContext.readOnly
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  _callout.text,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AtlasColors.darkTextPrimary
                                        : AtlasColors.lightTextPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              )
                            : TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                maxLines: null,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextPrimary
                                      : AtlasColors.lightTextPrimary,
                                  height: 1.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Type callout text...',
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  _updateCallout(text: val);
                                },
                              ),
                      ),
                      // Action Menu / Delete Button on hover
                      if (!widget.embedContext.readOnly && _isHovered) ...[
                        IconButton(
                          icon: const Icon(Icons.palette_outlined, size: 16),
                          tooltip: 'Customize callout',
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _showIconAndColorPicker(context),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: 'Delete callout',
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: _deleteBlock,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
