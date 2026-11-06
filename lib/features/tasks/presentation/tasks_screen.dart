import 'package:flutter/material.dart';

import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_empty_state.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tasks & Planning', style: theme.textTheme.displayMedium),
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                'Actionable task management integrated with your knowledge graph',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AtlasSpacing.lg),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Inbox'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: AtlasSpacing.sm),
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: AtlasSpacing.sm),
                  ChoiceChip(
                    label: const Text('Upcoming'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const Expanded(
                child: AtlasEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No pending tasks',
                  description: 'The full task and project planning engine is scheduled for Milestone 5, including recurring RRULE schedules, priorities (P1-P4), and bidirectional note embedding.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
