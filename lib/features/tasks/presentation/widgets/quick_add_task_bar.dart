import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class QuickAddTaskBar extends ConsumerStatefulWidget {
  final String? defaultProjectId;
  final String? defaultNodeId;
  final DateTime? defaultDueDate;
  final ValueChanged<String>? onTaskCreated;

  const QuickAddTaskBar({
    super.key,
    this.defaultProjectId,
    this.defaultNodeId,
    this.defaultDueDate,
    this.onTaskCreated,
  });

  @override
  ConsumerState<QuickAddTaskBar> createState() => _QuickAddTaskBarState();
}

class _QuickAddTaskBarState extends ConsumerState<QuickAddTaskBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  int _priority = 4;
  DateTime? _dueDate;
  bool _hasTime = false;
  String? _selectedProjectId;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.defaultProjectId;
    _dueDate = widget.defaultDueDate;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_focusNode.hasFocus) _isExpanded = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _getPriorityColor(int p) {
    switch (p) {
      case 1:
        return AtlasColors.priorityP1;
      case 2:
        return AtlasColors.priorityP2;
      case 3:
        return AtlasColors.priorityP3;
      default:
        return AtlasColors.priorityP4;
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickTime = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add specific time?'),
        content: const Text(
          'Do you want to set a specific due time for this task?',
        ),
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
        return;
      }
    }

    setState(() {
      _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _hasTime = false;
    });
  }

  Future<void> _submitTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final created = await taskRepo.createTask(
      workspaceId: workspaceId,
      title: text,
      projectId: _selectedProjectId ?? widget.defaultProjectId,
      nodeId: widget.defaultNodeId,
      priority: _priority,
      dueDate: _dueDate,
      hasTime: _hasTime,
      reminderMinutesBefore: _dueDate != null ? 15 : null,
    );

    widget.onTaskCreated?.call(created.id);

    _controller.clear();
    setState(() {
      _priority = 4;
      _dueDate = null;
      _hasTime = false;
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    final activeBorderColor = _isFocused
        ? AtlasColors.accentBlue
        : (isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isDark ? AtlasColors.darkCard : AtlasColors.lightSurface,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusXl),
        border: Border.all(
          color: activeBorderColor,
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? (_isFocused ? 0.35 : 0.20) : 0.05,
            ),
            blurRadius: _isFocused ? 18 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.md,
        vertical: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Circle Plus Icon / Priority dot
              Icon(
                Icons.add_circle_outline,
                size: 20,
                color: _getPriorityColor(_priority),
              ),
              const SizedBox(width: AtlasSpacing.sm),

              // Title input
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Add a task... (Press Enter to create)',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _submitTask(),
                  onTap: () {
                    if (!_isExpanded) {
                      setState(() => _isExpanded = true);
                    }
                  },
                ),
              ),

              // Inline Priority Pill
              PopupMenuButton<int>(
                tooltip: 'Set Priority',
                initialValue: _priority,
                onSelected: (val) => setState(() => _priority = val),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: AtlasColors.priorityP1,
                        ),
                        const SizedBox(width: 8),
                        const Text('Priority 1 (Urgent)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: AtlasColors.priorityP2,
                        ),
                        const SizedBox(width: 8),
                        const Text('Priority 2 (High)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: AtlasColors.priorityP3,
                        ),
                        const SizedBox(width: 8),
                        const Text('Priority 3 (Medium)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 4,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: AtlasColors.priorityP4,
                        ),
                        const SizedBox(width: 8),
                        const Text('Priority 4 (Low)'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_priority).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 12,
                        color: _getPriorityColor(_priority),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'P$_priority',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getPriorityColor(_priority),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Inline Due Date Pill
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _dueDate != null
                        ? AtlasColors.accentBlue.withValues(alpha: 0.15)
                        : (isDark
                              ? AtlasColors.darkElevated
                              : AtlasColors.lightElevated),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: _dueDate != null
                            ? AtlasColors.accentBlue
                            : (isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dueDate == null
                            ? 'Due'
                            : (_hasTime
                                  ? DateFormat('MMM d, h:mm a')
                                        .format(_dueDate!)
                                  : DateFormat.MMMd().format(_dueDate!)),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _dueDate != null
                              ? AtlasColors.accentBlue
                              : (isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary),
                        ),
                      ),
                      if (_dueDate != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setState(() {
                            _dueDate = null;
                            _hasTime = false;
                          }),
                          child: const Icon(Icons.close, size: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Submit button
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                tooltip: 'Add Task',
                onPressed: _submitTask,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: AtlasColors.accentBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          // Secondary option bar (if project selector or expanded)
          if (_isExpanded && widget.defaultProjectId == null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(
              children: [
                StreamBuilder<List<ProjectEntry>>(
                  stream: taskRepo.watchProjects(workspaceId),
                  builder: (context, snapshot) {
                    final projects = snapshot.data ?? [];
                    if (projects.isEmpty) return const SizedBox.shrink();

                    return PopupMenuButton<String?>(
                      tooltip: 'Assign Project',
                      initialValue: _selectedProjectId,
                      onSelected: (val) =>
                          setState(() => _selectedProjectId = val),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem<String?>(
                          value: null,
                          child: Text('Inbox (No Project)'),
                        ),
                        ...projects.map(
                          (p) => PopupMenuItem<String?>(
                            value: p.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(
                                      int.parse(
                                        p.colorHex.replaceFirst('#', '0xFF'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AtlasColors.darkElevated
                              : AtlasColors.lightElevated,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_outlined, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _selectedProjectId == null
                                  ? 'Project: Inbox'
                                  : (projects
                                        .firstWhere(
                                          (p) => p.id == _selectedProjectId,
                                          orElse: () => projects.first,
                                        )
                                        .name),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                  tooltip: 'Hide Options',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _isExpanded = false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
