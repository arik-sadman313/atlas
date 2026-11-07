import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../domain/models/document_embed_models.dart';

/// Embed builder for rendering actionable SQLite database tasks inside documents.
class TaskEmbedBuilder extends EmbedBuilder {
  const TaskEmbedBuilder();

  @override
  String get key => TaskBlockEmbed.taskBlockType;

  @override
  bool get expanded => true;

  @override
  String toPlainText(Embed node) {
    final task = TaskBlockEmbed.fromData(node.value.data);
    return task.title.isNotEmpty ? ' [Task: ${task.title}] ' : ' [Task] ';
  }

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Consumer(
      builder: (context, ref, child) {
        return TaskBlockWidget(embedContext: embedContext, ref: ref);
      },
    );
  }
}

class TaskBlockWidget extends StatefulWidget {
  final EmbedContext embedContext;
  final WidgetRef ref;

  const TaskBlockWidget({
    super.key,
    required this.embedContext,
    required this.ref,
  });

  @override
  State<TaskBlockWidget> createState() => _TaskBlockWidgetState();
}

class _TaskBlockWidgetState extends State<TaskBlockWidget> {
  late TaskBlockEmbed _task;
  late TextEditingController _titleController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _task = TaskBlockEmbed.fromData(widget.embedContext.node.value.data);
    _titleController = TextEditingController(text: _task.title);
  }

  @override
  void didUpdateWidget(TaskBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedContext.node.value.data !=
        widget.embedContext.node.value.data) {
      final updated = TaskBlockEmbed.fromData(
        widget.embedContext.node.value.data,
      );
      if (updated.title != _titleController.text) {
        _titleController.text = updated.title;
      }
      _task = updated;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateTask({String? title, bool? isCompleted, String? priority}) {
    final updated = _task.copyWith(
      title: title ?? _task.title,
      isCompleted: isCompleted ?? _task.isCompleted,
      priority: priority ?? _task.priority,
    );
    _task = updated;

    final quill = widget.embedContext.controller;
    final node = widget.embedContext.node;
    final offset = node.documentOffset;

    final block = BlockEmbed(
      TaskBlockEmbed.taskBlockType,
      jsonEncode(updated.toMap()),
    );
    quill.replaceText(offset, 1, block, null);

    // Update SQLite if taskId is present
    if (updated.taskId.isNotEmpty) {
      final tasksDao = widget.ref.read(tasksDaoProvider);
      tasksDao.toggleTaskCompletion(updated.taskId, updated.isCompleted);
    }
  }

  void _deleteBlock() {
    final quill = widget.embedContext.controller;
    final node = widget.embedContext.node;
    final offset = node.documentOffset;
    quill.replaceText(offset, 1, '', null);
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AtlasColors.priorityP1;
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return AtlasColors.accentAmber;
      case 'low':
      default:
        return AtlasColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AtlasSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isDark ? AtlasColors.darkCard : AtlasColors.lightCard,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
          border: Border.all(
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: _task.isCompleted,
              activeColor: AtlasColors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: widget.embedContext.readOnly
                  ? null
                  : (val) {
                      _updateTask(isCompleted: val ?? false);
                    },
            ),
            const SizedBox(width: AtlasSpacing.xs),
            // Title
            Expanded(
              child: widget.embedContext.readOnly
                  ? Text(
                      _task.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: _task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: _task.isCompleted
                            ? (isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary)
                            : (isDark
                                  ? AtlasColors.darkTextPrimary
                                  : AtlasColors.lightTextPrimary),
                      ),
                    )
                  : TextField(
                      controller: _titleController,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: _task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: _task.isCompleted
                            ? (isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary)
                            : (isDark
                                  ? AtlasColors.darkTextPrimary
                                  : AtlasColors.lightTextPrimary),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Task description...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        _updateTask(title: val);
                      },
                    ),
            ),
            // Priority Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _priorityColor(_task.priority).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _task.priority.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _priorityColor(_task.priority),
                ),
              ),
            ),
            if (!widget.embedContext.readOnly && _isHovered) ...[
              const SizedBox(width: AtlasSpacing.xs),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                tooltip: 'Delete task embed',
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: _deleteBlock,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
