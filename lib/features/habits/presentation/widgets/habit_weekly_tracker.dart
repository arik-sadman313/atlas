import 'package:flutter/material.dart';

import '../../../../core/database/daos/habits_dao.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class HabitWeeklyTracker extends StatelessWidget {
  final Map<String, bool> weeklyCompletion;
  final Color habitColor;
  final DateTime? today;

  const HabitWeeklyTracker({
    super.key,
    required this.weeklyCompletion,
    required this.habitColor,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveToday = today ?? DateTime.now();
    final todayStr = HabitsDao.formatDate(effectiveToday);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final days = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      days.add(
        DateTime(
          effectiveToday.year,
          effectiveToday.month,
          effectiveToday.day - i,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final dateStr = HabitsDao.formatDate(day);
        final isCompleted = weeklyCompletion[dateStr] ?? false;
        final isToday = dateStr == todayStr;
        final letter = weekdayLetters[(day.weekday - 1) % 7];

        return Tooltip(
          message: '$dateStr: ${isCompleted ? "Completed" : "Incomplete"}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                letter,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? (isDark
                            ? AtlasColors.darkTextPrimary
                            : AtlasColors.lightTextPrimary)
                      : (isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary),
                ),
              ),
              const SizedBox(height: AtlasSpacing.xs),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? habitColor
                      : (isDark
                            ? AtlasColors.darkElevated
                            : AtlasColors.lightElevated),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isToday
                        ? habitColor
                        : (isDark
                              ? AtlasColors.darkBorder
                              : AtlasColors.lightBorder),
                    width: isToday ? 1.5 : 1.0,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
