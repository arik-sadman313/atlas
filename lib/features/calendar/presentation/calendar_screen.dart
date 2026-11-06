import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_empty_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(now),
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: AtlasSpacing.xs),
                      Text(
                        'Timeline, daily journal notes, and scheduled reviews',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AtlasSpacing.xl),
              const Expanded(
                child: AtlasEmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No calendar events scheduled',
                  description: 'The calendar and daily journal engine arrives in Milestone 5, linking daily notes, habit tracking, and time-blocked task agendas.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
