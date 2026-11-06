import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/calendar_dao.dart';
import '../../../core/database/daos/habits_dao.dart';
import '../../../core/database/daos/tasks_dao.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_button.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../../../shared/widgets/atlas_empty_state.dart';
import '../../habits/presentation/widgets/goals_summary_card.dart';
import '../../habits/presentation/widgets/habit_check_in_tile.dart';
import '../../habits/presentation/widgets/habit_edit_dialog.dart';
import '../../habits/presentation/widgets/habit_progress_ring_painter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showCreateNodeDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String selectedType = 'document';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark
                  ? AtlasColors.darkSurface
                  : AtlasColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
                side: BorderSide(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                  width: 1.0,
                ),
              ),
              title: Text('Create Item', style: theme.textTheme.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'document',
                        label: Text('Document'),
                        icon: Icon(Icons.description_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'notebook',
                        label: Text('Notebook'),
                        icon: Icon(Icons.menu_book_outlined, size: 16),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) {
                      setDialogState(() {
                        selectedType = set.first;
                      });
                    },
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: selectedType == 'document'
                          ? 'e.g. Design Principles'
                          : 'e.g. Quarterly Planning',
                    ),
                    onSubmitted: (_) => _saveNode(
                      dialogCtx,
                      ref,
                      titleController.text,
                      selectedType,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _saveNode(
                    dialogCtx,
                    ref,
                    titleController.text,
                    selectedType,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveNode(
    BuildContext dialogCtx,
    WidgetRef ref,
    String title,
    String type,
  ) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'node_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: type,
        title: clean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
      if (type == 'notebook') {
        GoRouter.of(dialogCtx).go('/notebooks');
      } else {
        GoRouter.of(dialogCtx).go('/documents/$newId');
      }
    }
  }

  void _showQuickTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    int selectedPriority = 4;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark
                  ? AtlasColors.darkSurface
                  : AtlasColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
                side: BorderSide(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
              ),
              title: Text('New Task', style: theme.textTheme.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'e.g. Review system architecture',
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Priority', style: theme.textTheme.labelMedium),
                      DropdownButton<int>(
                        value: selectedPriority,
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('P1 - Urgent'),
                          ),
                          DropdownMenuItem(value: 2, child: Text('P2 - High')),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('P3 - Medium'),
                          ),
                          DropdownMenuItem(value: 4, child: Text('P4 - Low')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPriority = val);
                          }
                        },
                      ),
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
                    final clean = titleController.text.trim();
                    if (clean.isEmpty) return;

                    final workspaceId = ref.read(currentWorkspaceIdProvider);
                    final taskRepo = ref.read(taskRepositoryProvider);
                    await taskRepo.createTask(
                      workspaceId: workspaceId,
                      title: clean,
                      priority: selectedPriority,
                      dueDate: selectedDate,
                    );

                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openTodayJournal(BuildContext context, WidgetRef ref) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final journalRepo = ref.read(journalRepositoryProvider);
    final nodeId = await journalRepo.getOrCreateTodayJournalNode(workspaceId);
    if (context.mounted) {
      context.go('/documents/$nodeId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceAsync = ref.watch(currentWorkspaceProvider);
    final recentNodesAsync = ref.watch(recentNodesProvider);
    final habitsAsync = ref.watch(habitsWithProgressProvider);
    final journalAsync = ref.watch(todayJournalEntryProvider);
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final tasksDao = ref.watch(tasksDaoProvider);
    final calendarDao = ref.watch(calendarDaoProvider);

    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(now);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar / Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtlasSpacing.xl,
                  AtlasSpacing.xl,
                  AtlasSpacing.xl,
                  AtlasSpacing.md,
                ),
                child: LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final isCompact = headerConstraints.maxWidth < 760;

                    final headerText = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting · $formattedDate',
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 0.5,
                            color: isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.xs),
                        Text(
                          'Workspace Overview',
                          style: theme.textTheme.displayMedium,
                        ),
                        const SizedBox(height: AtlasSpacing.xs),
                        workspaceAsync.when(
                          data: (ws) => Text(
                            ws?.name ?? 'Personal Workspace',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary,
                            ),
                          ),
                          loading: () => const Text('Personal Workspace'),
                          error: (_, _) => const Text('Personal Workspace'),
                        ),
                      ],
                    );

                    final actionButtons = Wrap(
                      spacing: AtlasSpacing.sm,
                      runSpacing: AtlasSpacing.sm,
                      alignment: isCompact
                          ? WrapAlignment.start
                          : WrapAlignment.end,
                      children: [
                        AtlasButton.secondary(
                          label: 'New Task',
                          icon: Icons.check_circle_outline,
                          onPressed: () => _showQuickTaskDialog(context, ref),
                        ),
                        AtlasButton.secondary(
                          label: "Today's Journal",
                          icon: Icons.auto_stories_outlined,
                          onPressed: () => _openTodayJournal(context, ref),
                        ),
                        AtlasButton.primary(
                          label: 'New Note',
                          icon: Icons.add,
                          onPressed: () => _showCreateNodeDialog(context, ref),
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerText,
                          const SizedBox(height: AtlasSpacing.md),
                          actionButtons,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: headerText),
                        actionButtons,
                      ],
                    );
                  },
                ),
              ),
            ),

            // Quick Stats Row (Preserving Documents, Notebooks, Tasks counters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.xl,
                  vertical: AtlasSpacing.sm,
                ),
                child: recentNodesAsync.when(
                  data: (nodes) {
                    final docsCount = nodes
                        .where((n) => n.type == 'document')
                        .length;
                    final notebookCount = nodes
                        .where((n) => n.type == 'notebook')
                        .length;

                    return StreamBuilder<List<TaskEntry>>(
                      stream: tasksDao.watchTasksForWorkspace(
                        workspaceId,
                        isCompleted: false,
                      ),
                      builder: (context, taskSnapshot) {
                        final pendingTasksCount =
                            taskSnapshot.data?.length ?? 0;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;
                            return Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    title: 'Documents',
                                    value: docsCount.toString(),
                                    icon: Icons.article_outlined,
                                    accentColor: AtlasColors.accentBlue,
                                    onTap: () => context.go('/documents'),
                                  ),
                                ),
                                const SizedBox(width: AtlasSpacing.md),
                                Expanded(
                                  child: _StatCard(
                                    title: 'Notebooks',
                                    value: notebookCount.toString(),
                                    icon: Icons.menu_book_outlined,
                                    accentColor: AtlasColors.accentSage,
                                    onTap: () => context.go('/notebooks'),
                                  ),
                                ),
                                const SizedBox(width: AtlasSpacing.md),
                                Expanded(
                                  child: _StatCard(
                                    title: 'Tasks',
                                    value: pendingTasksCount.toString(),
                                    icon: Icons.check_circle_outline,
                                    accentColor: AtlasColors.accentRose,
                                    onTap: () => context.go('/tasks'),
                                  ),
                                ),
                                if (isWide) ...[
                                  const SizedBox(width: AtlasSpacing.md),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'Search',
                                      value: 'Vault Index',
                                      icon: Icons.search_outlined,
                                      accentColor: AtlasColors.accentAmber,
                                      onTap: () => context.go('/search'),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Bento Grid Modular Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpacing.xl,
                vertical: AtlasSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 960;

                    if (isDesktop) {
                      // Multi-column Wide Bento Grid
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Primary Column (Focus & Agenda + Recent Notes)
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTodayFocusCard(
                                  context,
                                  ref,
                                  theme,
                                  isDark,
                                  workspaceId,
                                  tasksDao,
                                  calendarDao,
                                ),
                                const SizedBox(height: AtlasSpacing.lg),
                                _buildRecentNotesCard(
                                  context,
                                  ref,
                                  theme,
                                  isDark,
                                  recentNodesAsync,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AtlasSpacing.lg),
                          // Right Secondary Column (Journal + Habits + Goals)
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildJournalCard(
                                  context,
                                  ref,
                                  theme,
                                  isDark,
                                  journalAsync,
                                ),
                                const SizedBox(height: AtlasSpacing.lg),
                                _buildHabitsStripCard(
                                  context,
                                  ref,
                                  theme,
                                  isDark,
                                  habitsAsync,
                                ),
                                const SizedBox(height: AtlasSpacing.lg),
                                const GoalsSummaryCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Single-column Responsive Feed (Tablet & Mobile)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildJournalCard(
                            context,
                            ref,
                            theme,
                            isDark,
                            journalAsync,
                          ),
                          const SizedBox(height: AtlasSpacing.lg),
                          _buildHabitsStripCard(
                            context,
                            ref,
                            theme,
                            isDark,
                            habitsAsync,
                          ),
                          const SizedBox(height: AtlasSpacing.lg),
                          _buildTodayFocusCard(
                            context,
                            ref,
                            theme,
                            isDark,
                            workspaceId,
                            tasksDao,
                            calendarDao,
                          ),
                          const SizedBox(height: AtlasSpacing.lg),
                          const GoalsSummaryCard(),
                          const SizedBox(height: AtlasSpacing.lg),
                          _buildRecentNotesCard(
                            context,
                            ref,
                            theme,
                            isDark,
                            recentNodesAsync,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildJournalCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    AsyncValue<JournalEntryData?> journalAsync,
  ) {
    return AtlasCard(
      child: journalAsync.when(
        data: (entry) {
          final hasJournal = entry != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AtlasSpacing.xs),
                        decoration: BoxDecoration(
                          color: hasJournal
                              ? AtlasColors.accentSageSubtle
                              : AtlasColors.accentAmberSubtle,
                          borderRadius: BorderRadius.circular(
                            AtlasSpacing.radiusSm,
                          ),
                        ),
                        child: Icon(
                          hasJournal
                              ? Icons.auto_stories_outlined
                              : Icons.edit_note_outlined,
                          size: 18,
                          color: hasJournal
                              ? AtlasColors.accentSage
                              : AtlasColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: AtlasSpacing.sm),
                      Text(
                        hasJournal
                            ? "Today's Journal Written"
                            : "Daily Reflection",
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AtlasColors.darkTextPrimary
                              : AtlasColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (hasJournal && entry.mood != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AtlasColors.darkElevated
                            : AtlasColors.lightElevated,
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        'Mood: ${entry.mood!}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Text(
                hasJournal
                    ? "Your thoughts and daily reflections for today are recorded."
                    : "Capture your focus, key wins, and mindful reflections for today.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AtlasSpacing.md),
              FilledButton.tonalIcon(
                icon: Icon(
                  hasJournal ? Icons.arrow_forward : Icons.edit,
                  size: 16,
                ),
                label: Text(
                  hasJournal ? "Open Today's Journal" : "Write Today's Journal",
                ),
                onPressed: () => _openTodayJournal(context, ref),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AtlasSpacing.md),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (err, _) => Text(
          'Error loading journal status: $err',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildHabitsStripCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    AsyncValue<List<HabitWithProgress>> habitsAsync,
  ) {
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.repeat, size: 18, color: AtlasColors.accentSage),
                  const SizedBox(width: AtlasSpacing.xs),
                  Text(
                    'Daily Habits',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AtlasColors.darkTextPrimary
                          : AtlasColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Add Habit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => HabitEditDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          habitsAsync.when(
            data: (habits) {
              if (habits.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AtlasSpacing.md,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'No habits tracked yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.xs),
                        Text(
                          'Tap + to create your first daily routine.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final completedToday = habits
                  .where((h) => h.isCompletedToday)
                  .length;
              final total = habits.length;
              final progressFraction = total > 0 ? completedToday / total : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overall Progress Indicator
                  Row(
                    children: [
                      HabitProgressRing(
                        progress: progressFraction,
                        progressColor: AtlasColors.accentSage,
                        size: 32,
                        strokeWidth: 3,
                        child: Text(
                          '$completedToday/$total',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AtlasSpacing.sm),
                      Text(
                        '$completedToday of $total completed today',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AtlasSpacing.md),
                  // Habit Tiles List
                  ...habits.map((h) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AtlasSpacing.xs),
                      child: HabitCheckInTile(
                        progress: h,
                        showWeeklyTracker: false,
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AtlasSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Text(
              'Error loading habits: $err',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFocusCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    String workspaceId,
    TasksDao tasksDao,
    CalendarDao calendarDao,
  ) {
    final now = DateTime.now();

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 18, color: AtlasColors.accentAmber),
                  const SizedBox(width: AtlasSpacing.xs),
                  Text(
                    "Today's Focus & Agenda",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AtlasColors.darkTextPrimary
                          : AtlasColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/tasks'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.md),

          // Events & Tasks Stream
          StreamBuilder<List<TaskEntry>>(
            stream: tasksDao.watchTasksForWorkspace(
              workspaceId,
              isCompleted: false,
            ),
            builder: (context, taskSnapshot) {
              final allTasks = taskSnapshot.data ?? [];
              final focusTasks = allTasks
                  .where((t) {
                    if (t.priority <= 2) return true;
                    if (t.dueDate != null) {
                      return t.dueDate!.isBefore(
                        DateTime(now.year, now.month, now.day, 23, 59, 59),
                      );
                    }
                    return false;
                  })
                  .take(5)
                  .toList();

              return StreamBuilder<List<CalendarEventEntry>>(
                stream: calendarDao.watchEventsForDay(workspaceId, now),
                builder: (context, eventSnapshot) {
                  final events = eventSnapshot.data ?? [];

                  if (focusTasks.isEmpty && events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AtlasSpacing.sm,
                      ),
                      child: Text(
                        'Clear horizon. No pending high-priority tasks or calendar events for today.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Calendar Events Strip
                      if (events.isNotEmpty) ...[
                        ...events.map((event) {
                          final timeStr = DateFormat.jm().format(
                            event.startTime,
                          );
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AtlasSpacing.xs,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AtlasColors.accentBlueSubtle
                                  : AtlasColors.accentBlueSubtle,
                              borderRadius: BorderRadius.circular(
                                AtlasSpacing.radiusSm,
                              ),
                              border: Border.all(
                                color: AtlasColors.accentBlue.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  size: 14,
                                  color: AtlasColors.accentBlue,
                                ),
                                const SizedBox(width: AtlasSpacing.xs),
                                Text(
                                  timeStr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AtlasColors.accentBlue,
                                  ),
                                ),
                                const SizedBox(width: AtlasSpacing.sm),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: AtlasSpacing.xs),
                      ],

                      // Focus Tasks List
                      ...focusTasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AtlasSpacing.xxs,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AtlasSpacing.radiusSm,
                            ),
                            onTap: () async {
                              final taskRepo = ref.read(taskRepositoryProvider);
                              await taskRepo.toggleTask(
                                task.id,
                                !task.isCompleted,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AtlasSpacing.xxs,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    task.isCompleted
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: _getPriorityColor(task.priority),
                                  ),
                                  const SizedBox(width: AtlasSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            decoration: task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (task.dueDate != null) ...[
                                    const SizedBox(width: AtlasSpacing.xs),
                                    Text(
                                      DateFormat.MMMd().format(task.dueDate!),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AtlasColors.darkTextSecondary
                                                : AtlasColors
                                                      .lightTextSecondary,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
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

  Widget _buildRecentNotesCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    AsyncValue<List<NodeEntry>> recentNodesAsync,
  ) {
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Modified',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AtlasColors.darkTextPrimary
                      : AtlasColors.lightTextPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/documents'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          recentNodesAsync.when(
            data: (nodes) {
              if (nodes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AtlasSpacing.lg,
                  ),
                  child: AtlasEmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: 'Your workspace is empty',
                    description: 'Create your first document or notebook to begin organizing your thoughts.',
                    actionLabel: 'Create First Page',
                    onAction: () => _showCreateNodeDialog(context, ref),
                  ),
                );
              }

              return Column(
                children: nodes.take(6).map((node) {
                  final formattedDate = DateFormat.yMMMd().add_jm().format(
                    node.updatedAt,
                  );
                  final isNotebook = node.type == 'notebook';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AtlasSpacing.xs),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AtlasSpacing.radiusSm,
                      ),
                      onTap: () {
                        if (isNotebook) {
                          context.go('/notebooks');
                        } else {
                          context.go('/documents/${node.id}');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AtlasSpacing.xs,
                          horizontal: AtlasSpacing.xxs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isNotebook
                                    ? AtlasColors.accentSageSubtle
                                    : AtlasColors.accentBlueSubtle,
                                borderRadius: BorderRadius.circular(
                                  AtlasSpacing.radiusSm,
                                ),
                              ),
                              child: Icon(
                                isNotebook
                                    ? Icons.menu_book_outlined
                                    : Icons.description_outlined,
                                size: 16,
                                color: isNotebook
                                    ? AtlasColors.accentSage
                                    : AtlasColors.accentBlue,
                              ),
                            ),
                            const SizedBox(width: AtlasSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    node.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Updated $formattedDate',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                node.isFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 18,
                                color: node.isFavorite
                                    ? AtlasColors.accentAmber
                                    : null,
                              ),
                              onPressed: () async {
                                final nodesDao = ref.read(nodesDaoProvider);
                                await nodesDao.updateNode(
                                  node
                                      .toCompanion(true)
                                      .copyWith(
                                        isFavorite: Value(!node.isFavorite),
                                        updatedAt: Value(DateTime.now()),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AtlasSpacing.md),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(AtlasSpacing.md),
              child: Text('Error loading dashboard: $err'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AtlasCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
