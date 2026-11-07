import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_button.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../data/repositories/task_repository.dart';
import 'widgets/kanban/kanban_board_view.dart';
import 'widgets/quick_add_task_bar.dart';
import 'widgets/task_detail_sheet.dart';
import 'widgets/task_item_widget.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _currentFilter = TaskFilter.inbox;
  TaskGrouping _currentGrouping = TaskGrouping.none;
  String? _selectedProjectId;
  String _viewMode = 'list'; // 'list' or 'board'

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('tasks_view_mode') ?? 'list';
    if (mounted) {
      setState(() => _viewMode = mode);
    }
  }

  Future<void> _setViewMode(String mode) async {
    setState(() => _viewMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_view_mode', mode);
  }

  void _showNewProjectDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String colorHex = '#4F46E5';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark
                  ? AtlasColors.darkSurface
                  : AtlasColors.lightSurface,
              title: Text('New Project', style: theme.textTheme.headlineSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Project Name',
                      hintText: 'e.g., Mobile App Launch, Thesis',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 8),
                      ...[
                        '#4F46E5', // Indigo
                        '#10B981', // Green
                        '#F59E0B', // Amber
                        '#EF4444', // Red
                        '#EC4899', // Pink
                        '#8B5CF6', // Purple
                      ].map((hex) {
                        final isSelected = colorHex == hex;
                        final color = Color(
                          int.parse(hex.replaceFirst('#', '0xFF')),
                        );
                        return GestureDetector(
                          onTap: () => setDialogState(() => colorHex = hex),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      const BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final workspaceId = ref.read(currentWorkspaceIdProvider);
                    final taskRepo = ref.read(taskRepositoryProvider);
                    final created = await taskRepo.createProject(
                      workspaceId: workspaceId,
                      name: name,
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      colorHex: colorHex,
                    );

                    if (mounted) {
                      setState(() {
                        _currentFilter = TaskFilter.projects;
                        _selectedProjectId = created.id;
                      });
                    }
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, List<TaskEntry>> _groupTasks(
    List<TaskEntry> tasks,
    List<ProjectEntry> projects,
  ) {
    if (_currentGrouping == TaskGrouping.none) {
      return {'Tasks': tasks};
    }

    final Map<String, List<TaskEntry>> grouped = {};

    if (_currentGrouping == TaskGrouping.byProject) {
      final projectMap = {for (final p in projects) p.id: p.name};
      for (final t in tasks) {
        final groupName = t.projectId != null
            ? (projectMap[t.projectId] ?? 'Unknown Project')
            : 'No Project (Inbox)';
        grouped.putIfAbsent(groupName, () => []).add(t);
      }
    } else if (_currentGrouping == TaskGrouping.byPriority) {
      for (final t in tasks) {
        final groupName = 'Priority ${t.priority} (P${t.priority})';
        grouped.putIfAbsent(groupName, () => []).add(t);
      }
    } else if (_currentGrouping == TaskGrouping.byDueDate) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      for (final t in tasks) {
        String groupName;
        if (t.dueDate == null) {
          groupName = 'No Due Date';
        } else {
          final due = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          if (due.isBefore(today)) {
            groupName = 'Overdue';
          } else if (due.isAtSameMomentAs(today)) {
            groupName = 'Today';
          } else if (due.isAtSameMomentAs(tomorrow)) {
            groupName = 'Tomorrow';
          } else {
            groupName = DateFormat.yMMMd().format(due);
          }
        }
        grouped.putIfAbsent(groupName, () => []).add(t);
      }
    }

    return grouped;
  }

  Future<void> _createSuggestedTask(String title) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.createTask(
      workspaceId: workspaceId,
      title: title,
      priority: 3,
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    final isCompleted = _currentFilter == TaskFilter.completed;
    final title = isCompleted
        ? 'No completed tasks'
        : (_currentFilter == TaskFilter.inbox
              ? 'All clear in Inbox'
              : 'No tasks in ${_currentFilter.name}');

    final subtitle = isCompleted
        ? 'Completed tasks will appear here for review and tracking.'
        : 'Everything is caught up. Capture an action item or start planning ahead.';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.all(AtlasSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AtlasColors.darkCard : AtlasColors.lightSurface,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusXl),
          border: Border.all(
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AtlasColors.accentSage.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 28,
                color: AtlasColors.accentSage,
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AtlasSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AtlasColors.darkTextSecondary
                    : AtlasColors.lightTextSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isCompleted) ...[
              const SizedBox(height: AtlasSpacing.lg),
              Divider(
                height: 1,
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
              ),
              const SizedBox(height: AtlasSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Start Suggestions',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AtlasColors.darkTextMuted
                        : AtlasColors.lightTextMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: AtlasSpacing.sm),
              _SuggestionRow(
                icon: Icons.school_outlined,
                label: 'Create a study task',
                onTap: () => _createSuggestedTask('Create a study task'),
              ),
              const SizedBox(height: 6),
              _SuggestionRow(
                icon: Icons.calendar_view_week_outlined,
                label: 'Plan your week',
                onTap: () => _createSuggestedTask('Plan your week'),
              ),
              const SizedBox(height: 6),
              _SuggestionRow(
                icon: Icons.flag_outlined,
                label: 'Review project goals',
                onTap: () => _createSuggestedTask('Review project goals'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _viewMode == 'board' ? double.infinity : 880,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AtlasSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tasks & Planning',
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: AtlasSpacing.xs),
                            Text(
                              'Actionable task management integrated with your knowledge graph',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AtlasSpacing.md),
                      Row(
                        children: [
                          // View Mode Switcher (List vs Board)
                          _buildViewModeSwitcher(isDark),
                          const SizedBox(width: AtlasSpacing.sm),

                          // Grouping Menu (for List view)
                          if (_viewMode == 'list') ...[
                            PopupMenuButton<TaskGrouping>(
                              tooltip: 'Group Tasks',
                              initialValue: _currentGrouping,
                              onSelected: (g) =>
                                  setState(() => _currentGrouping = g),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: TaskGrouping.none,
                                  child: Text('No Grouping'),
                                ),
                                const PopupMenuItem(
                                  value: TaskGrouping.byProject,
                                  child: Text('Group by Project'),
                                ),
                                const PopupMenuItem(
                                  value: TaskGrouping.byDueDate,
                                  child: Text('Group by Due Date'),
                                ),
                                const PopupMenuItem(
                                  value: TaskGrouping.byPriority,
                                  child: Text('Group by Priority'),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AtlasColors.darkSurface
                                      : AtlasColors.lightSurface,
                                  borderRadius: BorderRadius.circular(
                                    AtlasSpacing.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? AtlasColors.darkBorder
                                        : AtlasColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sort, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      _currentGrouping == TaskGrouping.none
                                          ? 'Group'
                                          : _currentGrouping.name,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AtlasSpacing.sm),
                          ],
                          AtlasButton.secondary(
                            label: 'New Project',
                            icon: Icons.create_new_folder_outlined,
                            onPressed: _showNewProjectDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AtlasSpacing.md),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox, size: 14),
                              SizedBox(width: 4),
                              Text('Inbox'),
                            ],
                          ),
                          selected: _currentFilter == TaskFilter.inbox,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _currentFilter = TaskFilter.inbox;
                                _selectedProjectId = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: AtlasSpacing.sm),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.today, size: 14),
                              SizedBox(width: 4),
                              Text('Today'),
                            ],
                          ),
                          selected: _currentFilter == TaskFilter.today,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _currentFilter = TaskFilter.today;
                                _selectedProjectId = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: AtlasSpacing.sm),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upcoming, size: 14),
                              SizedBox(width: 4),
                              Text('Upcoming'),
                            ],
                          ),
                          selected: _currentFilter == TaskFilter.upcoming,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _currentFilter = TaskFilter.upcoming;
                                _selectedProjectId = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: AtlasSpacing.sm),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_outlined, size: 14),
                              SizedBox(width: 4),
                              Text('Projects'),
                            ],
                          ),
                          selected: _currentFilter == TaskFilter.projects,
                          onSelected: (val) {
                            if (val) {
                              setState(
                                () => _currentFilter = TaskFilter.projects,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: AtlasSpacing.sm),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 14),
                              SizedBox(width: 4),
                              Text('Completed'),
                            ],
                          ),
                          selected: _currentFilter == TaskFilter.completed,
                          onSelected: (val) {
                            if (val) {
                              setState(
                                () => _currentFilter = TaskFilter.completed,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Project Filter Sub-bar (if Projects view selected)
                  if (_currentFilter == TaskFilter.projects) ...[
                    const SizedBox(height: 8),
                    StreamBuilder<List<ProjectEntry>>(
                      stream: taskRepo.watchProjects(workspaceId),
                      builder: (context, snapshot) {
                        final projects = snapshot.data ?? [];
                        if (projects.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'No projects yet. Create one with "+ New Project".',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Projects'),
                                selected: _selectedProjectId == null,
                                onSelected: (_) =>
                                    setState(() => _selectedProjectId = null),
                              ),
                              const SizedBox(width: 6),
                              ...projects.map((p) {
                                final isSel = _selectedProjectId == p.id;
                                final color = Color(
                                  int.parse(
                                    p.colorHex.replaceFirst('#', '0xFF'),
                                  ),
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    avatar: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    label: Text(p.name),
                                    selected: isSel,
                                    onSelected: (sel) {
                                      setState(() {
                                        _selectedProjectId = sel ? p.id : null;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: AtlasSpacing.md),

                  // Quick Add Bar
                  QuickAddTaskBar(defaultProjectId: _selectedProjectId),

                  const SizedBox(height: AtlasSpacing.md),

                  // Main Task List / Streams
                  Expanded(
                    child: StreamBuilder<List<ProjectEntry>>(
                      stream: taskRepo.watchProjects(workspaceId),
                      builder: (context, projectSnap) {
                        final projects = projectSnap.data ?? [];

                        return StreamBuilder<List<TaskEntry>>(
                          stream: taskRepo.watchTasks(
                            workspaceId,
                            filter: _currentFilter,
                            projectId: _selectedProjectId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final tasks = snapshot.data ?? [];

                            if (_viewMode == 'board') {
                              return KanbanBoardView(
                                allTasks: tasks,
                                projects: projects,
                                workspaceId: workspaceId,
                                taskRepo: taskRepo,
                              );
                            }

                            if (tasks.isEmpty) {
                              return _buildEmptyState(context, theme, isDark);
                            }

                            final grouped = _groupTasks(tasks, projects);

                            return ListView.builder(
                              itemCount: grouped.keys.length,
                              itemBuilder: (context, index) {
                                final groupTitle = grouped.keys.elementAt(
                                  index,
                                );
                                final groupItems = grouped[groupTitle]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_currentGrouping != TaskGrouping.none)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12,
                                          bottom: 6,
                                          left: 8,
                                        ),
                                        child: Text(
                                          '$groupTitle (${groupItems.length})',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? AtlasColors
                                                          .darkTextSecondary
                                                    : AtlasColors
                                                          .lightTextSecondary,
                                              ),
                                        ),
                                      ),
                                    AtlasCard(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Column(
                                        children: [
                                          for (
                                            int i = 0;
                                            i < groupItems.length;
                                            i++
                                          ) ...[
                                            TaskItemWidget(
                                              task: groupItems[i],
                                              onToggle: (completed) {
                                                taskRepo.toggleTask(
                                                  groupItems[i].id,
                                                  completed,
                                                );
                                              },
                                              onTap: () {
                                                TaskDetailSheet.show(
                                                  context,
                                                  groupItems[i],
                                                );
                                              },
                                              onDelete: () {
                                                taskRepo.deleteTask(
                                                  groupItems[i].id,
                                                );
                                              },
                                            ),
                                            if (i < groupItems.length - 1)
                                              const Divider(
                                                height: 1,
                                                indent: 44,
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'List View',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _setViewMode('list'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _viewMode == 'list'
                      ? (isDark ? const Color(0xFF282F3E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.view_list_rounded,
                  size: 16,
                  color: _viewMode == 'list'
                      ? const Color(0xFF6366F1)
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Kanban Board View',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _setViewMode('board'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _viewMode == 'board'
                      ? (isDark ? const Color(0xFF282F3E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.view_kanban_rounded,
                  size: 16,
                  color: _viewMode == 'board'
                      ? const Color(0xFF6366F1)
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: isDark ? AtlasColors.darkElevated : AtlasColors.lightElevated,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AtlasColors.accentBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.add,
                  size: 16,
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
