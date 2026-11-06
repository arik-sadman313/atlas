import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../../shared/widgets/atlas_card.dart';

class JournalContextDayPanel extends ConsumerStatefulWidget {
  final String journalDate; // YYYY-MM-DD
  final bool initialExpanded;

  const JournalContextDayPanel({
    super.key,
    required this.journalDate,
    this.initialExpanded = true,
  });

  @override
  ConsumerState<JournalContextDayPanel> createState() =>
      _JournalContextDayPanelState();
}

class _JournalContextDayPanelState
    extends ConsumerState<JournalContextDayPanel> {
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
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final habitsAsync = ref.watch(habitsWithProgressProvider);
    final tasksDao = ref.watch(tasksDaoProvider);

    // Format display date
    String formattedHeader = widget.journalDate;
    try {
      final parts = widget.journalDate.split('-').map(int.parse).toList();
      final dt = DateTime(parts[0], parts[1], parts[2]);
      formattedHeader = DateFormat('EEEE, MMMM d').format(dt);
    } catch (_) {}

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      size: 18,
                      color: AtlasColors.accentAmber,
                    ),
                    const SizedBox(width: AtlasSpacing.sm),
                    Text(
                      'Day Summary — $formattedHeader',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AtlasColors.darkTextPrimary
                            : AtlasColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
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
          if (_isExpanded) ...[
            const SizedBox(height: AtlasSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AtlasSpacing.md),

            // Habits section
            Text(
              'Habits Completed',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AtlasColors.darkTextSecondary
                    : AtlasColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xs),
            habitsAsync.when(
              data: (habitsWithProgress) {
                final completedHabits = habitsWithProgress.where((hp) {
                  return hp.weeklyCompletion[widget.journalDate] ?? false;
                }).toList();

                if (completedHabits.isEmpty) {
                  return Text(
                    'No habits checked in for this date.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AtlasColors.darkTextTertiary
                          : AtlasColors.lightTextTertiary,
                    ),
                  );
                }

                return Wrap(
                  spacing: AtlasSpacing.xs,
                  runSpacing: AtlasSpacing.xs,
                  children: completedHabits.map((hp) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AtlasColors.accentSageSubtle
                            : AtlasColors.accentSageSubtle,
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color: AtlasColors.accentSage.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AtlasColors.accentSage,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hp.habit.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AtlasColors.accentSage,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AtlasSpacing.md),

            // Tasks section
            Text(
              'Tasks Activity',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AtlasColors.darkTextSecondary
                    : AtlasColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xs),
            FutureBuilder(
              future: tasksDao.getTasksForWorkspace(workspaceId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final tasks = snapshot.data ?? [];
                final completedTasks = tasks.where((t) {
                  if (t.completedAt == null) return false;
                  final cDate =
                      '${t.completedAt!.year.toString().padLeft(4, '0')}-${t.completedAt!.month.toString().padLeft(2, '0')}-${t.completedAt!.day.toString().padLeft(2, '0')}';
                  return cDate == widget.journalDate;
                }).toList();

                if (completedTasks.isEmpty) {
                  return Text(
                    'No tasks completed on this date.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AtlasColors.darkTextTertiary
                          : AtlasColors.lightTextTertiary,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: completedTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AtlasSpacing.xxs,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AtlasColors.accentBlue,
                          ),
                          const SizedBox(width: AtlasSpacing.xs),
                          Expanded(
                            child: Text(
                              task.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
