import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/database/app_database.dart';

/// Notion/Craft-grade interactive Kanban Task Card.
///
/// Supports fluid drag-and-drop with 2° tilt, 1.03x scale, and deep shadow feedback.
/// Displays priority indicator, completion checkbox, due date badge with overdue alert,
/// linked note indicator, and project tag.
class KanbanCardWidget extends StatelessWidget {
  final TaskEntry task;
  final List<ProjectEntry> projects;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleCompletion;
  final VoidCallback? onDelete;

  const KanbanCardWidget({
    super.key,
    required this.task,
    this.projects = const [],
    this.onTap,
    this.onToggleCompletion,
    this.onDelete,
  });

  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444); // P1 - Urgent (Crimson)
      case 2:
        return const Color(0xFFF59E0B); // P2 - High (Amber)
      case 3:
        return const Color(0xFF6366F1); // P3 - Medium (Indigo)
      case 4:
      default:
        return const Color(0xFF64748B); // P4 - Low (Slate)
    }
  }

  static String getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'P1';
      case 2:
        return 'P2';
      case 3:
        return 'P3';
      case 4:
      default:
        return 'P4';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardContent = _buildCardSurface(
      context: context,
      isDark: isDark,
      isDragging: false,
    );

    return Draggable<TaskEntry>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 270,
          child: Transform.rotate(
            angle: 2 * 3.14159265 / 180, // 2 degrees tilt
            child: Transform.scale(
              scale: 1.03, // 1.03x scale
              child: _buildCardSurface(
                context: context,
                isDark: isDark,
                isDragging: true,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
      child: cardContent,
    );
  }

  Widget _buildCardSurface({
    required BuildContext context,
    required bool isDark,
    required bool isDragging,
  }) {
    final priorityColor = getPriorityColor(task.priority);
    final isDone = task.isCompleted || task.status == 'done';

    ProjectEntry? project;
    if (task.projectId != null) {
      for (final p in projects) {
        if (p.id == task.projectId) {
          project = p;
          break;
        }
      }
    }

    final isOverdue =
        !isDone &&
        task.dueDate != null &&
        task.dueDate!.isBefore(
          DateTime.now().subtract(const Duration(minutes: 5)),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B24) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDragging
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF282F3E) : const Color(0xFFE2E8F0)),
          width: isDragging ? 1.5 : 1.0,
        ),
        boxShadow: isDragging
            ? const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority Strip on Left Edge
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                ),

                // Card Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Checkbox + Title + More
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Completion Checkbox
                            Padding(
                              padding: const EdgeInsets.only(top: 1, right: 8),
                              child: GestureDetector(
                                onTap: () => onToggleCompletion?.call(!isDone),
                                child: Container(
                                  width: 17,
                                  height: 17,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? const Color(0xFF10B981)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isDone
                                          ? const Color(0xFF10B981)
                                          : (isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8)),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(
                                          Icons.check,
                                          size: 13,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),

                            // Title
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDone
                                      ? (isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8))
                                      : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Priority Badge
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                getPriorityLabel(task.priority),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Row 2: Badges (Due Date, Project, Note)
                        if (task.dueDate != null ||
                            project != null ||
                            task.nodeId != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Due Date Badge
                              if (task.dueDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOverdue
                                        ? const Color(0xFFEF4444)
                                              .withValues(alpha: 0.15)
                                        : (isDark
                                              ? const Color(0xFF232836)
                                              : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: isOverdue
                                        ? Border.all(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11,
                                        color: isOverdue
                                            ? const Color(0xFFEF4444)
                                            : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDueDate(task.dueDate!),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: isOverdue
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isOverdue
                                              ? const Color(0xFFEF4444)
                                              : (isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Project Badge
                              if (project != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF232836)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(
                                            int.parse(
                                              project.colorHex.replaceFirst(
                                                '#',
                                                '0xFF',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 80,
                                        ),
                                        child: Text(
                                          project.name,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Linked Note Badge
                              if (task.nodeId != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 11,
                                        color: Color(0xFF818CF8),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Note',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF818CF8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
      ),
    );
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';
    if (diffDays < 0) return '${diffDays.abs()}d overdue';
    if (diffDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
