import 'package:flutter/material.dart';

import '../../../../../core/database/app_database.dart';
import 'kanban_card_widget.dart';

/// Notion-style Kanban Column with DragTarget support, count badge,
/// color indicator, and quick-add action.
class KanbanColumnWidget extends StatefulWidget {
  final String id;
  final String title;
  final Color color;
  final List<TaskEntry> tasks;
  final List<ProjectEntry> projects;
  final ValueChanged<TaskEntry> onTaskDropped;
  final void Function(TaskEntry task, int targetIndex)? onTaskReordered;
  final VoidCallback onQuickAdd;
  final ValueChanged<TaskEntry> onTaskTap;
  final void Function(TaskEntry task, bool isCompleted) onToggleTask;

  const KanbanColumnWidget({
    super.key,
    required this.id,
    required this.title,
    required this.color,
    required this.tasks,
    this.projects = const [],
    required this.onTaskDropped,
    this.onTaskReordered,
    required this.onQuickAdd,
    required this.onTaskTap,
    required this.onToggleTask,
  });

  @override
  State<KanbanColumnWidget> createState() => _KanbanColumnWidgetState();
}

class _KanbanColumnWidgetState extends State<KanbanColumnWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 290,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12141A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2330) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          _buildColumnHeader(isDark),

          // Droppable Card List Area
          Expanded(
            child: DragTarget<TaskEntry>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                widget.onTaskDropped(details.data);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? widget.color.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isHovered
                        ? Border.all(
                            color: widget.color.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: widget.tasks.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(4),
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) {
                            final task = widget.tasks[index];

                            return DragTarget<TaskEntry>(
                              onWillAcceptWithDetails: (details) =>
                                  details.data.id != task.id,
                              onAcceptWithDetails: (details) {
                                if (widget.onTaskReordered != null) {
                                  widget.onTaskReordered!(details.data, index);
                                } else {
                                  widget.onTaskDropped(details.data);
                                }
                              },
                              builder: (ctx, innerCandidates, _) {
                                final isItemHovered =
                                    innerCandidates.isNotEmpty;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isItemHovered)
                                      Container(
                                        height: 3,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.color,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    KanbanCardWidget(
                                      task: task,
                                      projects: widget.projects,
                                      onTap: () => widget.onTaskTap(task),
                                      onToggleCompletion: (done) =>
                                          widget.onToggleTask(task, done),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E2330) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Color indicator dot / bar
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Title
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Task Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.tasks.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Quick Add (+) Button
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Add task to ${widget.title}',
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            hoverColor: widget.color.withValues(alpha: 0.15),
            onPressed: widget.onQuickAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 26,
              color: isDark ? const Color(0xFF333B4F) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks here',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Drag here or tap +',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
