import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/daos/habits_dao.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../../shared/widgets/atlas_card.dart';
import 'habit_edit_dialog.dart';
import 'habit_progress_ring_painter.dart';
import 'habit_weekly_tracker.dart';

class HabitCheckInTile extends ConsumerWidget {
  final HabitWithProgress progress;
  final VoidCallback? onToggle;
  final bool showWeeklyTracker;

  const HabitCheckInTile({
    super.key,
    required this.progress,
    this.onToggle,
    this.showWeeklyTracker = true,
  });

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AtlasColors.accentSage;
    }
  }

  IconData _resolveIcon(String? iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'directions_run':
        return Icons.directions_run;
      case 'code':
        return Icons.code;
      case 'edit_note':
        return Icons.edit_note;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final habit = progress.habit;
    final habitColor = _parseColor(habit.colorHex);
    final isCompleted = progress.isCompletedToday;
    final streak = progress.currentStreak;

    return AtlasCard(
      onTap: () {
        HabitEditDialog.show(context, habit: habit);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // 1-tap Check-In Button / Ring
              GestureDetector(
                onTap: () async {
                  if (onToggle != null) {
                    onToggle!();
                  } else {
                    final repo = ref.read(habitRepositoryProvider);
                    await repo.toggleHabitToday(habit.id);
                  }
                },
                child: HabitProgressRing(
                  progress: isCompleted ? 1.0 : 0.0,
                  progressColor: habitColor,
                  size: 40.0,
                  strokeWidth: 3.5,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? habitColor
                          : habitColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : _resolveIcon(habit.icon),
                      size: 18,
                      color: isCompleted ? Colors.white : habitColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AtlasSpacing.md),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isCompleted
                            ? (isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary)
                            : (isDark
                                  ? AtlasColors.darkTextPrimary
                                  : AtlasColors.lightTextPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty) ...[
                      const SizedBox(height: AtlasSpacing.xxs),
                      Text(
                        habit.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AtlasSpacing.sm),

              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? (isDark
                            ? AtlasColors.accentAmber.withValues(alpha: 0.2)
                            : AtlasColors.accentAmberSubtle)
                      : (isDark
                            ? AtlasColors.darkElevated
                            : AtlasColors.lightElevated),
                  borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                  border: Border.all(
                    color: streak > 0
                        ? AtlasColors.accentAmber.withValues(alpha: 0.4)
                        : (isDark
                              ? AtlasColors.darkBorderSubtle
                              : AtlasColors.lightBorderSubtle),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streak > 0 ? '🔥 ' : '⏳ ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      streak == 1 ? '1 day' : '$streak days',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: streak > 0
                            ? AtlasColors.accentAmber
                            : (isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (showWeeklyTracker) ...[
            const SizedBox(height: AtlasSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AtlasSpacing.sm),
            HabitWeeklyTracker(
              weeklyCompletion: progress.weeklyCompletion,
              habitColor: habitColor,
            ),
          ],
        ],
      ),
    );
  }
}
