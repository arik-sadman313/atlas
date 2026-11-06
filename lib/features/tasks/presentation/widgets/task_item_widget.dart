import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class TaskItemWidget extends ConsumerWidget {
  final TaskEntry task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
  });

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444); // P1 - Red
      case 2:
        return const Color(0xFFF59E0B); // P2 - Amber
      case 3:
        return const Color(0xFF3B82F6); // P3 - Blue
      case 4:
      default:
        return const Color(0xFF9CA3AF); // P4 - Gray
    }
  }

  Widget _buildDueDateBadge(
    BuildContext context,
    DateTime dueDate,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final isOverdue = dueDay.isBefore(today) && !task.isCompleted;
    final isToday = dueDay.isAtSameMomentAs(today);
    final isTomorrow = dueDay.isAtSameMomentAs(
      today.add(const Duration(days: 1)),
    );

    String label;
    if (isToday) {
      label = task.hasTime
          ? 'Today at ${DateFormat.jm().format(dueDate)}'
          : 'Today';
    } else if (isTomorrow) {
      label = task.hasTime
          ? 'Tomorrow at ${DateFormat.jm().format(dueDate)}'
          : 'Tomorrow';
    } else if (dueDay.isBefore(today.subtract(const Duration(days: 365))) ||
        dueDay.isAfter(today.add(const Duration(days: 365)))) {
      label = DateFormat.yMMMd().format(dueDate);
    } else {
      label = task.hasTime
          ? DateFormat('MMM d, h:mm a').format(dueDate)
          : DateFormat.MMMd().format(dueDate);
    }

    final color = isOverdue
        ? Colors.red
        : (isToday
              ? Colors.amber.shade700
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600));

    final bgColor = isOverdue
        ? Colors.red.withValues(alpha: 0.12)
        : (isToday
              ? Colors.amber.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.error_outline : Icons.calendar_today_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nodesDao = ref.watch(nodesDaoProvider);
    final tasksDao = ref.watch(tasksDaoProvider);

    final priorityColor = _getPriorityColor(task.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.sm,
            vertical: AtlasSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Circular Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: InkResponse(
                  onTap: () => onToggle(!task.isCompleted),
                  radius: 18,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? AtlasColors.accentSage
                            : priorityColor,
                        width: task.isCompleted ? 0 : 2.0,
                      ),
                      color: task.isCompleted
                          ? AtlasColors.accentSage
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),

              // Title and Meta Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? (isDark
                                  ? AtlasColors.darkTextTertiary
                                  : AtlasColors.lightTextTertiary)
                            : (isDark
                                  ? AtlasColors.darkTextPrimary
                                  : AtlasColors.lightTextPrimary),
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Badges Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Due date badge
                        if (task.dueDate != null)
                          _buildDueDateBadge(context, task.dueDate!, isDark),

                        // Project badge
                        if (task.projectId != null)
                          FutureBuilder<ProjectEntry?>(
                            future: tasksDao.getProject(task.projectId!),
                            builder: (context, snapshot) {
                              final project = snapshot.data;
                              if (project == null) {
                                return const SizedBox.shrink();
                              }
                              final color = Color(
                                int.parse(
                                  project.colorHex.replaceFirst('#', '0xFF'),
                                ),
                              );

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  project.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              );
                            },
                          ),

                        // Linked Node badge
                        if (task.nodeId != null)
                          FutureBuilder<NodeEntry?>(
                            future: nodesDao.getNode(task.nodeId!),
                            builder: (context, snapshot) {
                              final node = snapshot.data;
                              if (node == null) return const SizedBox.shrink();

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AtlasColors.accentBlueSubtle
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      node.type == 'notebook'
                                          ? Icons.menu_book_outlined
                                          : Icons.description_outlined,
                                      size: 11,
                                      color: AtlasColors.accentBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      node.title,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AtlasColors.accentBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        // Recurrence Indicator
                        if (task.recurrenceRule != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.repeat,
                              size: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing Actions (Priority & Options)
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete Task',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
