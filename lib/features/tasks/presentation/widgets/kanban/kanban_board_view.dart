import 'package:flutter/material.dart';

import '../../../../../core/database/app_database.dart';
import '../../../data/repositories/task_repository.dart';
import '../task_detail_sheet.dart';
import 'kanban_column_widget.dart';

enum KanbanGrouping { byStatus, byPriority }

/// Interactive, drag-and-drop Notion-style Kanban Board view.
///
/// Supports grouping by Status (To Do, In Progress, Done) and Priority (P1 to P4),
/// column quick-add, fluid reordering, and instant optimistic SQLite updates.
class KanbanBoardView extends StatefulWidget {
  final List<TaskEntry> allTasks;
  final List<ProjectEntry> projects;
  final String workspaceId;
  final TaskRepository taskRepo;
  final ValueChanged<TaskEntry>? onTaskTap;

  const KanbanBoardView({
    super.key,
    required this.allTasks,
    this.projects = const [],
    required this.workspaceId,
    required this.taskRepo,
    this.onTaskTap,
  });

  @override
  State<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends State<KanbanBoardView> {
  KanbanGrouping _grouping = KanbanGrouping.byStatus;

  void _showQuickAddDialog({
    String? status,
    int? priority,
    required String columnTitle,
  }) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF181B24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'New Task in $columnTitle',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (val) async {
              final text = val.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogCtx);
                await widget.taskRepo.createTask(
                  workspaceId: widget.workspaceId,
                  title: text,
                  status: status ?? 'todo',
                  priority: priority ?? 4,
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = titleController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(dialogCtx);
                  await widget.taskRepo.createTask(
                    workspaceId: widget.workspaceId,
                    title: text,
                    status: status ?? 'todo',
                    priority: priority ?? 4,
                  );
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTaskDropOnStatusColumn(
    TaskEntry task,
    String targetStatus,
  ) async {
    final currentStatus = task.status;
    if (currentStatus == targetStatus &&
        ((targetStatus == 'done') == task.isCompleted)) {
      return;
    }
    await widget.taskRepo.updateTaskStatus(task.id, targetStatus);
  }

  Future<void> _handleTaskDropOnPriorityColumn(
    TaskEntry task,
    int targetPriority,
  ) async {
    if (task.priority == targetPriority) return;
    await widget.taskRepo.updateTaskPriority(task.id, targetPriority);
  }

  Future<void> _handleTaskReorderInColumn(
    TaskEntry task,
    int targetIndex,
    List<TaskEntry> columnTasks,
    String? statusColumn,
    int? priorityColumn,
  ) async {
    // 1. If moved from another column, update status/priority first
    if (statusColumn != null && task.status != statusColumn) {
      await widget.taskRepo.updateTaskStatus(task.id, statusColumn);
    } else if (priorityColumn != null && task.priority != priorityColumn) {
      await widget.taskRepo.updateTaskPriority(task.id, priorityColumn);
    }

    // 2. Recompute sort orders
    final mutableList = columnTasks.where((t) => t.id != task.id).toList();
    final clampedIndex = targetIndex.clamp(0, mutableList.length);
    mutableList.insert(clampedIndex, task);

    final taskIds = mutableList.map((t) => t.id).toList();
    await widget.taskRepo.reorderTasks(taskIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-toolbar: Grouping Segmented Control & Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Grouping Switcher
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF14171F)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF282F3E)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGroupingOption(
                      label: 'By Status',
                      icon: Icons.view_kanban_outlined,
                      isSelected: _grouping == KanbanGrouping.byStatus,
                      onTap: () =>
                          setState(() => _grouping = KanbanGrouping.byStatus),
                      isDark: isDark,
                    ),
                    _buildGroupingOption(
                      label: 'By Priority',
                      icon: Icons.flag_outlined,
                      isSelected: _grouping == KanbanGrouping.byPriority,
                      onTap: () =>
                          setState(() => _grouping = KanbanGrouping.byPriority),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Total count badge
              Text(
                '${widget.allTasks.length} ${widget.allTasks.length == 1 ? "task" : "tasks"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Kanban Columns
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _grouping == KanbanGrouping.byStatus
                ? _buildStatusColumns()
                : _buildPriorityColumns(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColumns() {
    // Partition tasks into To Do, In Progress, Done
    final todoTasks = <TaskEntry>[];
    final inProgressTasks = <TaskEntry>[];
    final doneTasks = <TaskEntry>[];

    for (final task in widget.allTasks) {
      if (task.isCompleted ||
          task.status == 'done' ||
          task.status == 'completed') {
        doneTasks.add(task);
      } else if (task.status == 'in_progress') {
        inProgressTasks.add(task);
      } else {
        todoTasks.add(task);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. To Do Column
        KanbanColumnWidget(
          id: 'todo',
          title: 'To Do',
          color: const Color(0xFF64748B),
          tasks: todoTasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnStatusColumn(t, 'todo'),
          onTaskReordered: (t, index) =>
              _handleTaskReorderInColumn(t, index, todoTasks, 'todo', null),
          onQuickAdd: () =>
              _showQuickAddDialog(status: 'todo', columnTitle: 'To Do'),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),

        // 2. In Progress Column
        KanbanColumnWidget(
          id: 'in_progress',
          title: 'In Progress',
          color: const Color(0xFF6366F1),
          tasks: inProgressTasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnStatusColumn(t, 'in_progress'),
          onTaskReordered: (t, index) => _handleTaskReorderInColumn(
            t,
            index,
            inProgressTasks,
            'in_progress',
            null,
          ),
          onQuickAdd: () => _showQuickAddDialog(
            status: 'in_progress',
            columnTitle: 'In Progress',
          ),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),

        // 3. Done Column
        KanbanColumnWidget(
          id: 'done',
          title: 'Done',
          color: const Color(0xFF10B981),
          tasks: doneTasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnStatusColumn(t, 'done'),
          onTaskReordered: (t, index) =>
              _handleTaskReorderInColumn(t, index, doneTasks, 'done', null),
          onQuickAdd: () =>
              _showQuickAddDialog(status: 'done', columnTitle: 'Done'),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),
      ],
    );
  }

  Widget _buildPriorityColumns() {
    final p1Tasks = widget.allTasks.where((t) => t.priority == 1).toList();
    final p2Tasks = widget.allTasks.where((t) => t.priority == 2).toList();
    final p3Tasks = widget.allTasks.where((t) => t.priority == 3).toList();
    final p4Tasks = widget.allTasks
        .where((t) => t.priority == 4 || t.priority <= 0 || t.priority > 4)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // P1 Urgent
        KanbanColumnWidget(
          id: 'p1',
          title: 'Urgent (P1)',
          color: const Color(0xFFEF4444),
          tasks: p1Tasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnPriorityColumn(t, 1),
          onTaskReordered: (t, index) =>
              _handleTaskReorderInColumn(t, index, p1Tasks, null, 1),
          onQuickAdd: () =>
              _showQuickAddDialog(priority: 1, columnTitle: 'Urgent (P1)'),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),

        // P2 High
        KanbanColumnWidget(
          id: 'p2',
          title: 'High (P2)',
          color: const Color(0xFFF59E0B),
          tasks: p2Tasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnPriorityColumn(t, 2),
          onTaskReordered: (t, index) =>
              _handleTaskReorderInColumn(t, index, p2Tasks, null, 2),
          onQuickAdd: () =>
              _showQuickAddDialog(priority: 2, columnTitle: 'High (P2)'),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),

        // P3 Medium
        KanbanColumnWidget(
          id: 'p3',
          title: 'Medium (P3)',
          color: const Color(0xFF6366F1),
          tasks: p3Tasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnPriorityColumn(t, 3),
          onTaskReordered: (t, index) =>
              _handleTaskReorderInColumn(t, index, p3Tasks, null, 3),
          onQuickAdd: () =>
              _showQuickAddDialog(priority: 3, columnTitle: 'Medium (P3)'),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),

        // P4 Low / Backlog
        KanbanColumnWidget(
          id: 'p4',
          title: 'Low / Backlog (P4)',
          color: const Color(0xFF64748B),
          tasks: p4Tasks,
          projects: widget.projects,
          onTaskDropped: (t) => _handleTaskDropOnPriorityColumn(t, 4),
          onTaskReordered: (t, index) =>
              _handleTaskReorderInColumn(t, index, p4Tasks, null, 4),
          onQuickAdd: () => _showQuickAddDialog(
            priority: 4,
            columnTitle: 'Low / Backlog (P4)',
          ),
          onTaskTap: (t) => _openTaskDetail(t),
          onToggleTask: (t, done) => widget.taskRepo.toggleTask(t.id, done),
        ),
      ],
    );
  }

  Widget _buildGroupingOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF282F3E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTaskDetail(TaskEntry task) {
    if (widget.onTaskTap != null) {
      widget.onTaskTap!(task);
    } else {
      TaskDetailSheet.show(context, task);
    }
  }
}
