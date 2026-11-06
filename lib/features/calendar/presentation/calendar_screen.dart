import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../../tasks/presentation/widgets/quick_add_task_bar.dart';
import '../domain/models/calendar_agenda_item.dart';
import 'widgets/agenda_item_card.dart';
import 'widgets/event_detail_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = ref.watch(currentWorkspaceProvider);
    final workspaceId = workspace.value?.id ?? 'default';

    final calendarRepo = ref.watch(calendarRepositoryProvider);
    final tasksDao = ref.watch(tasksDaoProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: StreamBuilder<List<CalendarEventEntry>>(
          stream: calendarRepo.watchAllEvents(workspaceId),
          builder: (context, eventSnapshot) {
            return StreamBuilder<List<TaskEntry>>(
              stream: tasksDao.watchTasksForWorkspace(workspaceId),
              builder: (context, taskSnapshot) {
                final allEvents = eventSnapshot.data ?? [];
                final allTasks = taskSnapshot.data ?? [];

                List<CalendarAgendaItem> getItemsForDay(DateTime day) {
                  final items = <CalendarAgendaItem>[];
                  final startOfDay = DateTime(day.year, day.month, day.day);
                  final endOfDay = DateTime(
                    day.year,
                    day.month,
                    day.day,
                    23,
                    59,
                    59,
                  );

                  for (final e in allEvents) {
                    if (!e.endTime.isBefore(startOfDay) &&
                        !e.startTime.isAfter(endOfDay)) {
                      items.add(CalendarAgendaItem.fromEvent(e));
                    }
                  }

                  for (final t in allTasks) {
                    if (t.parentTaskId != null) continue;
                    if (t.dueDate != null) {
                      final due = t.dueDate!;
                      if (!due.isBefore(startOfDay) && !due.isAfter(endOfDay)) {
                        items.add(CalendarAgendaItem.fromTask(t));
                      }
                    }
                  }

                  return items;
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;
                    final isTablet =
                        constraints.maxWidth >= 600 &&
                        constraints.maxWidth < 900;

                    if (isDesktop || isTablet) {
                      return _buildWideLayout(
                        theme: theme,
                        isDark: isDark,
                        workspaceId: workspaceId,
                        getItemsForDay: getItemsForDay,
                        calendarWidth: isDesktop ? 380 : 330,
                      );
                    } else {
                      return _buildMobileLayout(
                        theme: theme,
                        isDark: isDark,
                        workspaceId: workspaceId,
                        getItemsForDay: getItemsForDay,
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideLayout({
    required ThemeData theme,
    required bool isDark,
    required String workspaceId,
    required List<CalendarAgendaItem> Function(DateTime) getItemsForDay,
    required double calendarWidth,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AtlasSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(theme, isDark, showFormatButtons: false),
          const SizedBox(height: AtlasSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Calendar Card & Quick Navigation
                SizedBox(
                  width: calendarWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AtlasColors.darkSurface
                                : AtlasColors.lightSurface,
                            borderRadius: BorderRadius.circular(
                              AtlasSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AtlasColors.darkBorder
                                  : AtlasColors.lightBorder,
                            ),
                          ),
                          padding: const EdgeInsets.all(AtlasSpacing.sm),
                          child: _buildTableCalendar(isDark, getItemsForDay),
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        _buildQuickStats(isDark, theme, getItemsForDay),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AtlasSpacing.xl),

                // Right Column: Daily Agenda Timeline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAgendaHeader(theme, isDark),
                      const SizedBox(height: AtlasSpacing.md),
                      Expanded(child: _buildAgendaStream(workspaceId, isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout({
    required ThemeData theme,
    required bool isDark,
    required String workspaceId,
    required List<CalendarAgendaItem> Function(DateTime) getItemsForDay,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.md,
            vertical: AtlasSpacing.sm,
          ),
          child: _buildHeaderRow(theme, isDark, showFormatButtons: true),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
              ),
            ),
          ),
          child: _buildTableCalendar(isDark, getItemsForDay),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AtlasSpacing.md,
            AtlasSpacing.md,
            AtlasSpacing.md,
            AtlasSpacing.xs,
          ),
          child: _buildAgendaHeader(theme, isDark),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AtlasSpacing.md),
            child: _buildAgendaStream(workspaceId, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(
    ThemeData theme,
    bool isDark, {
    required bool showFormatButtons,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Timeline & Day Planner',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.today, size: 20),
              tooltip: 'Jump to Today',
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
            ),
            if (showFormatButtons) ...[
              IconButton(
                icon: Icon(
                  _calendarFormat == CalendarFormat.month
                      ? Icons.view_week_outlined
                      : Icons.calendar_view_month_outlined,
                  size: 20,
                ),
                tooltip: _calendarFormat == CalendarFormat.month
                    ? 'Week View'
                    : 'Month View',
                onPressed: () {
                  setState(() {
                    _calendarFormat = _calendarFormat == CalendarFormat.month
                        ? CalendarFormat.week
                        : CalendarFormat.month;
                  });
                },
              ),
              const SizedBox(width: 4),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                side: BorderSide(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
              ),
              icon: const Icon(Icons.add_task, size: 15),
              label: const Text('Task'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: isDark
                      ? AtlasColors.darkSurface
                      : AtlasColors.lightSurface,
                  builder: (ctx) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      left: AtlasSpacing.md,
                      right: AtlasSpacing.md,
                      top: AtlasSpacing.md,
                    ),
                    child: QuickAddTaskBar(defaultDueDate: _selectedDay),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () =>
                  EventDetailSheet.show(context, initialDate: _selectedDay),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Event'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCalendar(
    bool isDark,
    List<CalendarAgendaItem> Function(DateTime) getItemsForDay,
  ) {
    return TableCalendar<CalendarAgendaItem>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: getItemsForDay,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: AtlasColors.accentBlue.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(100),
        ),
        todayTextStyle: const TextStyle(
          color: AtlasColors.accentBlue,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: AtlasColors.accentBlue,
          borderRadius: BorderRadius.circular(100),
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        markerDecoration: const BoxDecoration(
          color: AtlasColors.accentBlue,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 4.5,
        markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark
              ? AtlasColors.darkTextPrimary
              : AtlasColors.lightTextPrimary,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: isDark
              ? AtlasColors.darkTextSecondary
              : AtlasColors.lightTextSecondary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: isDark
              ? AtlasColors.darkTextSecondary
              : AtlasColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    bool isDark,
    ThemeData theme,
    List<CalendarAgendaItem> Function(DateTime) getItemsForDay,
  ) {
    final todayItems = getItemsForDay(DateTime.now());
    final completedCount = todayItems.where((i) => i.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(AtlasSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AtlasColors.darkElevated : AtlasColors.lightElevated,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            label: 'Today Total',
            count: '${todayItems.length}',
            theme: theme,
            color: AtlasColors.accentBlue,
          ),
          Container(
            height: 32,
            width: 1,
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          ),
          _buildStatColumn(
            label: 'Completed',
            count: '$completedCount',
            theme: theme,
            color: AtlasColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String count,
    required ThemeData theme,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaHeader(ThemeData theme, bool isDark) {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final dayLabel = isToday
        ? 'Today, ${DateFormat('EEEE, MMM d').format(_selectedDay)}'
        : DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay);

    return Row(
      children: [
        Expanded(
          child: Text(
            dayLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add_task, size: 16),
          label: const Text('Add Task'),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: isDark
                  ? AtlasColors.darkSurface
                  : AtlasColors.lightSurface,
              builder: (ctx) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: AtlasSpacing.md,
                  right: AtlasSpacing.md,
                  top: AtlasSpacing.md,
                ),
                child: QuickAddTaskBar(defaultDueDate: _selectedDay),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgendaStream(String workspaceId, bool isDark) {
    final calendarRepo = ref.watch(calendarRepositoryProvider);

    return StreamBuilder<List<CalendarAgendaItem>>(
      stream: calendarRepo.watchAgendaForDay(workspaceId, _selectedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyTimeline(context, Theme.of(context), isDark);
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AgendaItemCard(key: ValueKey(item.id), item: item);
          },
        );
      },
    );
  }

  Widget _buildEmptyTimeline(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final hours = ['9:00 AM', '12:00 PM', '3:00 PM', '5:00 PM'];
    final dateStr = DateFormat('MMMM d').format(_selectedDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encouraging Day Summary Card
          AtlasCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AtlasColors.accentSage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    size: 20,
                    color: AtlasColors.accentSage,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clear Horizon for $dateStr',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No events or tasks scheduled. Great window for uninterrupted deep work.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    side: BorderSide(
                      color: isDark
                          ? AtlasColors.darkBorder
                          : AtlasColors.lightBorder,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Event', style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      EventDetailSheet.show(context, initialDate: _selectedDay),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Time-Blocking Outline Markers
          ...hours.map(
            (time) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    child: Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextMuted
                            : AtlasColors.lightTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AtlasColors.darkBorder
                            : AtlasColors.lightBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
