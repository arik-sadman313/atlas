import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final TaskEntry task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskEntry task) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => TaskDetailSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final TextEditingController _subtaskController = TextEditingController();

  late bool _isCompleted;
  late int _priority;
  DateTime? _dueDate;
  late bool _hasTime;
  String? _projectId;
  String? _nodeId;
  String? _recurrenceRule;
  int? _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _isCompleted = widget.task.isCompleted;
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
    _hasTime = widget.task.hasTime;
    _projectId = widget.task.projectId;
    _nodeId = widget.task.nodeId;
    _recurrenceRule = widget.task.recurrenceRule;
    _reminderMinutes = widget.task.reminderMinutesBefore;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final taskRepo = ref.read(taskRepositoryProvider);
    final updated = widget.task.copyWith(
      title: title,
      description: Value(
        _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      ),
      isCompleted: _isCompleted,
      priority: _priority,
      dueDate: Value(_dueDate),
      hasTime: _hasTime,
      projectId: Value(_projectId),
      nodeId: Value(_nodeId),
      recurrenceRule: Value(_recurrenceRule),
      reminderMinutesBefore: Value(_reminderMinutes),
      updatedAt: DateTime.now(),
    );

    await taskRepo.updateTask(updated);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (pickedDate == null || !mounted) return;

    final pickTime = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add specific time?'),
        content: const Text('Set a specific due time for this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Date Only'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set Time'),
          ),
        ],
      ),
    );

    if (pickTime == true && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            time.hour,
            time.minute,
          );
          _hasTime = true;
        });
        await _saveTask();
        return;
      }
    }

    setState(() {
      _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _hasTime = false;
    });
    await _saveTask();
  }

  Future<void> _addSubtask() async {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    final taskRepo = ref.read(taskRepositoryProvider);
    final workspaceId = ref.read(currentWorkspaceIdProvider);

    await taskRepo.createTask(
      workspaceId: workspaceId,
      title: text,
      parentTaskId: widget.task.id,
      priority: _priority,
    );

    _subtaskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);
    final nodesDao = ref.watch(nodesDaoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: EdgeInsets.only(
          left: AtlasSpacing.lg,
          right: AtlasSpacing.lg,
          top: AtlasSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AtlasSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Checkbox & Title Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Checkbox(
                    value: _isCompleted,
                    onChanged: (val) {
                      setState(() => _isCompleted = val ?? false);
                      _saveTask();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: _isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Task Title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => _saveTask(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description field
            TextField(
              controller: _descController,
              maxLines: 3,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Description or notes...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AtlasColors.darkTextTertiary
                      : AtlasColors.lightTextTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onChanged: (_) => _saveTask(),
            ),

            const Divider(height: 24),

            // Metadata Grid / Rows
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                // Priority Selector
                PopupMenuButton<int>(
                  initialValue: _priority,
                  onSelected: (val) {
                    setState(() => _priority = val);
                    _saveTask();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 1, child: Text('P1 (Urgent)')),
                    const PopupMenuItem(value: 2, child: Text('P2 (High)')),
                    const PopupMenuItem(value: 3, child: Text('P3 (Medium)')),
                    const PopupMenuItem(value: 4, child: Text('P4 (Low)')),
                  ],
                  child: Chip(
                    avatar: Icon(
                      Icons.flag,
                      size: 14,
                      color: _priority == 1
                          ? Colors.red
                          : _priority == 2
                          ? Colors.orange
                          : _priority == 3
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    label: Text('Priority: P$_priority'),
                  ),
                ),

                // Due Date Selector
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                  label: Text(
                    _dueDate == null
                        ? 'No Due Date'
                        : (_hasTime
                              ? DateFormat('MMM d, h:mm a').format(_dueDate!)
                              : DateFormat.yMMMd().format(_dueDate!)),
                  ),
                  onPressed: _pickDueDate,
                ),

                // Project Selector
                StreamBuilder<List<ProjectEntry>>(
                  stream: taskRepo.watchProjects(workspaceId),
                  builder: (context, snapshot) {
                    final projects = snapshot.data ?? [];
                    final currentProject = projects
                        .where((p) => p.id == _projectId)
                        .firstOrNull;

                    return PopupMenuButton<String?>(
                      initialValue: _projectId,
                      onSelected: (val) {
                        setState(() => _projectId = val);
                        _saveTask();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('No Project (Inbox)'),
                        ),
                        ...projects.map(
                          (p) =>
                              PopupMenuItem(value: p.id, child: Text(p.name)),
                        ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.folder_outlined, size: 14),
                        label: Text(
                          currentProject == null
                              ? 'Project: None'
                              : 'Project: ${currentProject.name}',
                        ),
                      ),
                    );
                  },
                ),

                // Node Link Picker (Document / Notebook)
                StreamBuilder<List<NodeEntry>>(
                  stream: nodesDao.watchRecentNodes(workspaceId),
                  builder: (context, snapshot) {
                    final recentNodes = snapshot.data ?? [];
                    final linkedNode = recentNodes
                        .where((n) => n.id == _nodeId)
                        .firstOrNull;

                    return PopupMenuButton<String?>(
                      initialValue: _nodeId,
                      onSelected: (val) {
                        setState(() => _nodeId = val);
                        _saveTask();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('No Note Link'),
                        ),
                        ...recentNodes.map(
                          (n) => PopupMenuItem(
                            value: n.id,
                            child: Row(
                              children: [
                                Icon(
                                  n.type == 'notebook'
                                      ? Icons.menu_book_outlined
                                      : Icons.description_outlined,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(n.title),
                              ],
                            ),
                          ),
                        ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.link, size: 14),
                        label: Text(
                          linkedNode == null
                              ? 'Link Note'
                              : 'Note: ${linkedNode.title}',
                        ),
                      ),
                    );
                  },
                ),

                // Recurrence Selector
                PopupMenuButton<String?>(
                  initialValue: _recurrenceRule,
                  onSelected: (val) {
                    setState(() => _recurrenceRule = val);
                    _saveTask();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('Does Not Repeat'),
                    ),
                    const PopupMenuItem(value: 'daily', child: Text('Daily')),
                    const PopupMenuItem(
                      value: 'weekdays',
                      child: Text('Every Weekday (Mon-Fri)'),
                    ),
                    const PopupMenuItem(value: 'weekly', child: Text('Weekly')),
                    const PopupMenuItem(
                      value: 'monthly',
                      child: Text('Monthly'),
                    ),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.repeat, size: 14),
                    label: Text(
                      _recurrenceRule == null
                          ? 'Repeat: Never'
                          : 'Repeat: ${_recurrenceRule![0].toUpperCase()}${_recurrenceRule!.substring(1)}',
                    ),
                  ),
                ),

                // Reminder Configuration
                PopupMenuButton<int?>(
                  initialValue: _reminderMinutes,
                  onSelected: (val) {
                    setState(() => _reminderMinutes = val);
                    _saveTask();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('No Reminder'),
                    ),
                    const PopupMenuItem(
                      value: 0,
                      child: Text('At time of event'),
                    ),
                    const PopupMenuItem(
                      value: 5,
                      child: Text('5 minutes before'),
                    ),
                    const PopupMenuItem(
                      value: 15,
                      child: Text('15 minutes before'),
                    ),
                    const PopupMenuItem(
                      value: 30,
                      child: Text('30 minutes before'),
                    ),
                    const PopupMenuItem(
                      value: 60,
                      child: Text('1 hour before'),
                    ),
                    const PopupMenuItem(
                      value: 1440,
                      child: Text('1 day before'),
                    ),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.notifications_outlined, size: 14),
                    label: Text(
                      _reminderMinutes == null
                          ? 'Reminder: None'
                          : (_reminderMinutes == 0
                                ? 'Reminder: At due time'
                                : 'Reminder: $_reminderMinutes min before'),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Subtasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtasks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subtasks Stream & List
            StreamBuilder<List<TaskEntry>>(
              stream: taskRepo.watchSubtasks(widget.task.id),
              builder: (context, snapshot) {
                final subtasks = snapshot.data ?? [];
                final completedCount = subtasks
                    .where((s) => s.isCompleted)
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subtasks.isNotEmpty) ...[
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completedCount / subtasks.length,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          color: AtlasColors.accentSage,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount of ${subtasks.length} subtasks completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextTertiary
                              : AtlasColors.lightTextTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...subtasks.map((st) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: st.isCompleted,
                            onChanged: (val) {
                              taskRepo.toggleTask(st.id, val ?? false);
                            },
                          ),
                          title: Text(
                            st.title,
                            style: TextStyle(
                              decoration: st.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => taskRepo.deleteTask(st.id),
                          ),
                        );
                      }),
                    ],

                    // Quick-add subtask field
                    Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            decoration: const InputDecoration(
                              hintText: 'Add a subtask...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addSubtask,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Delete Task Button
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Delete Task',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: Text(
                      'Are you sure you want to delete "${widget.task.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await taskRepo.deleteTask(widget.task.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
