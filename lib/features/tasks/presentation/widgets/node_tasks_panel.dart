import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import 'quick_add_task_bar.dart';
import 'task_detail_sheet.dart';
import 'task_item_widget.dart';

/// Collapsible panel or sheet embedding tasks associated with a specific [nodeId].
/// Used inside [DocumentEditorScreen] and [NotebookEditorScreen].
class NodeTasksPanel extends ConsumerStatefulWidget {
  final String nodeId;
  final bool initialExpanded;

  const NodeTasksPanel({
    super.key,
    required this.nodeId,
    this.initialExpanded = false,
  });

  @override
  ConsumerState<NodeTasksPanel> createState() => _NodeTasksPanelState();
}

class _NodeTasksPanelState extends ConsumerState<NodeTasksPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final taskRepo = ref.watch(taskRepositoryProvider);

    return StreamBuilder<List<TaskEntry>>(
      stream: taskRepo.tasksDao.watchTasksForNode(widget.nodeId),
      builder: (context, snapshot) {
        final nodeTasks = snapshot.data ?? [];
        final pendingCount = nodeTasks.where((t) => !t.isCompleted).length;

        return Material(
          color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
            side: BorderSide(
              color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expandable Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpacing.md,
                    vertical: AtlasSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_box_outlined,
                        size: 18,
                        color: AtlasColors.accentSage,
                      ),
                      const SizedBox(width: AtlasSpacing.sm),
                      Text(
                        'Linked Tasks',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AtlasColors.accentSageSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount pending',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AtlasColors.accentSage,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Body
              if (_isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AtlasSpacing.sm),
                  child: Column(
                    children: [
                      // Quick-add task referencing this node directly
                      QuickAddTaskBar(defaultNodeId: widget.nodeId),
                      const SizedBox(height: AtlasSpacing.sm),

                      if (nodeTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No tasks linked to this note yet.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextTertiary
                                    : AtlasColors.lightTextTertiary,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: nodeTasks.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 36),
                          itemBuilder: (context, index) {
                            final task = nodeTasks[index];
                            return TaskItemWidget(
                              task: task,
                              onToggle: (val) =>
                                  taskRepo.toggleTask(task.id, val),
                              onTap: () => TaskDetailSheet.show(context, task),
                              onDelete: () => taskRepo.deleteTask(task.id),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
