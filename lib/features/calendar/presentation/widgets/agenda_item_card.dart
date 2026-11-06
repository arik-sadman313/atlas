import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../tasks/presentation/widgets/task_detail_sheet.dart';
import '../../domain/models/calendar_agenda_item.dart';
import 'event_detail_sheet.dart';

class AgendaItemCard extends ConsumerWidget {
  final CalendarAgendaItem item;
  final VoidCallback? onCompletedChanged;

  const AgendaItemCard({
    super.key,
    required this.item,
    this.onCompletedChanged,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AtlasColors.accentBlue;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AtlasColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTask = item.type == CalendarItemType.task;
    final itemColor = _parseColor(item.colorHex);

    final timeString = item.isAllDay
        ? 'All Day'
        : item.endTime != null
        ? '${DateFormat.jm().format(item.startTime)} – ${DateFormat.jm().format(item.endTime!)}'
        : DateFormat.jm().format(item.startTime);

    return InkWell(
      onTap: () {
        if (isTask && item.rawTask != null) {
          TaskDetailSheet.show(context, item.rawTask!);
        } else if (!isTask && item.rawEvent != null) {
          EventDetailSheet.show(
            context,
            event: item.rawEvent,
            initialDate: item.startTime,
          );
        }
      },
      borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AtlasSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AtlasColors.darkElevated : AtlasColors.lightElevated,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color indicator bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: isTask
                      ? (item.isCompleted ? Colors.grey : itemColor)
                      : itemColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AtlasSpacing.radiusMd),
                  ),
                ),
              ),

              // Content Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AtlasSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Checkbox OR Event Icon
                      if (isTask) ...[
                        GestureDetector(
                          onTap: () async {
                            final tasksDao = ref.read(tasksDaoProvider);
                            await tasksDao.toggleTaskCompletion(
                              item.id,
                              !item.isCompleted,
                            );
                            onCompletedChanged?.call();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 2, right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.isCompleted
                                    ? AtlasColors.statusSuccess
                                    : (itemColor),
                                width: 2,
                              ),
                              color: item.isCompleted
                                  ? AtlasColors.statusSuccess
                                  : Colors.transparent,
                            ),
                            child: item.isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: itemColor,
                          ),
                        ),
                      ],

                      // Title & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      decoration: isTask && item.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isTask && item.isCompleted
                                          ? (isDark
                                                ? AtlasColors.darkTextSecondary
                                                : AtlasColors
                                                      .lightTextSecondary)
                                          : null,
                                    ),
                                  ),
                                ),
                                // Time Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
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
                                  child: Text(
                                    timeString,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AtlasColors.darkTextSecondary
                                          : AtlasColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Subtitle or location
                            if (item.location != null &&
                                item.location!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: isDark
                                        ? AtlasColors.darkTextSecondary
                                        : AtlasColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.location!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AtlasColors.darkTextSecondary
                                                : AtlasColors
                                                      .lightTextSecondary,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Description if event
                            if (item.description != null &&
                                item.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextSecondary
                                      : AtlasColors.lightTextSecondary,
                                ),
                              ),
                            ],

                            // Meta badges (Priority, Note)
                            if (item.priority != null ||
                                item.nodeId != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (item.priority != null &&
                                      item.priority! <= 3) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: itemColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'P${item.priority}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: itemColor,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (item.nodeId != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 12,
                                          color: isDark
                                              ? AtlasColors.darkTextSecondary
                                              : AtlasColors.lightTextSecondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Linked Note',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? AtlasColors
                                                          .darkTextSecondary
                                                    : AtlasColors
                                                          .lightTextSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
