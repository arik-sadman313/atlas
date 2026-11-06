import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../../shared/widgets/atlas_card.dart';

class GoalsSummaryCard extends ConsumerWidget {
  const GoalsSummaryCard({super.key});

  void _showGoalDialog(BuildContext context, WidgetRef ref, [GoalEntry? goal]) {
    final titleController = TextEditingController(text: goal?.title ?? '');
    final descController = TextEditingController(text: goal?.description ?? '');
    DateTime? selectedTargetDate = goal?.targetDate;
    String selectedStatus = goal?.status ?? 'in_progress';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(dialogCtx);
            final isDark = theme.brightness == Brightness.dark;
            final isEditing = goal != null;

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
              title: Text(
                isEditing ? 'Edit Goal' : 'New Goal',
                style: theme.textTheme.headlineMedium,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Goal Title',
                        hintText: 'e.g. Finish ATLAS v1.0',
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Key milestones and scope',
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),

                    // Target Date Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Date', style: theme.textTheme.labelMedium),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            selectedTargetDate != null
                                ? DateFormat.yMMMd().format(selectedTargetDate!)
                                : 'Select date',
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: selectedTargetDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTargetDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AtlasSpacing.md),

                    // Status
                    Text('Status', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AtlasSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      items: const [
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'achieved',
                          child: Text('Achieved'),
                        ),
                        DropdownMenuItem(
                          value: 'not_started',
                          child: Text('Not Started'),
                        ),
                        DropdownMenuItem(
                          value: 'abandoned',
                          child: Text('Abandoned'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedStatus = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () async {
                      final repo = ref.read(habitRepositoryProvider);
                      await repo.deleteGoal(goal.id);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AtlasColors.accentRose,
                    ),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final cleanTitle = titleController.text.trim();
                    if (cleanTitle.isEmpty) return;

                    final repo = ref.read(habitRepositoryProvider);
                    final workspaceId = ref.read(currentWorkspaceIdProvider);

                    if (isEditing) {
                      await repo.updateGoal(
                        goal.copyWith(
                          title: cleanTitle,
                          description: Value(
                            descController.text.trim().isEmpty
                                ? null
                                : descController.text.trim(),
                          ),
                          targetDate: Value(selectedTargetDate),
                          status: selectedStatus,
                          updatedAt: DateTime.now(),
                        ),
                      );
                    } else {
                      await repo.createGoal(
                        workspaceId: workspaceId,
                        title: cleanTitle,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        targetDate: selectedTargetDate,
                        status: selectedStatus,
                      );
                    }
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'achieved':
        return AtlasColors.statusSuccess;
      case 'in_progress':
        return AtlasColors.accentBlue;
      case 'not_started':
        return AtlasColors.lightTextSecondary;
      case 'abandoned':
        return AtlasColors.accentRose;
      default:
        return AtlasColors.accentBlue;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'achieved':
        return 'Achieved';
      case 'in_progress':
        return 'In Progress';
      case 'not_started':
        return 'Not Started';
      case 'abandoned':
        return 'Abandoned';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalsAsync = ref.watch(activeGoalsProvider);

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: AtlasColors.accentRose,
                  ),
                  const SizedBox(width: AtlasSpacing.xs),
                  Text(
                    'Goals & Milestones',
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
                tooltip: 'Add Goal',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showGoalDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AtlasSpacing.sm,
                  ),
                  child: Text(
                    'No active goals. Tap + to set a target for this workspace.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AtlasColors.darkTextSecondary
                          : AtlasColors.lightTextSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: goals.map((goal) {
                  final statusColor = _getStatusColor(goal.status);
                  final isAchieved = goal.status == 'achieved';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AtlasSpacing.xs,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AtlasSpacing.radiusSm,
                      ),
                      onTap: () => _showGoalDialog(context, ref, goal),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AtlasSpacing.xxs,
                          horizontal: AtlasSpacing.xxs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAchieved
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: AtlasSpacing.xs),
                            Expanded(
                              child: Text(
                                goal.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: isAchieved
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (goal.targetDate != null) ...[
                              const SizedBox(width: AtlasSpacing.xs),
                              Text(
                                DateFormat.MMMd().format(goal.targetDate!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextSecondary
                                      : AtlasColors.lightTextSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(width: AtlasSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatStatus(goal.status),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
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
                padding: EdgeInsets.all(AtlasSpacing.sm),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) =>
                Text('Error loading goals', style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
