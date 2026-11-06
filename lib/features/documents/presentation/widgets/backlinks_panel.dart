import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/daos/links_dao.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

/// Collapsible Backlinks Panel displaying incoming references pointing to [nodeId].
///
/// Usable across both typed documents and handwritten notebooks.
class BacklinksPanel extends ConsumerStatefulWidget {
  final String nodeId;
  final bool initialExpanded;

  const BacklinksPanel({
    super.key,
    required this.nodeId,
    this.initialExpanded = false,
  });

  @override
  ConsumerState<BacklinksPanel> createState() => _BacklinksPanelState();
}

class _BacklinksPanelState extends ConsumerState<BacklinksPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  void _navigateToNode(BuildContext context, BacklinkItem item) {
    if (item.sourceType == 'notebook') {
      context.push('/notebooks/${item.sourceNodeId}');
    } else {
      context.push('/documents/${item.sourceNodeId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final linkRepo = ref.watch(linkRepositoryProvider);

    return StreamBuilder<List<BacklinkItem>>(
      stream: linkRepo.watchBacklinks(widget.nodeId),
      builder: (context, snapshot) {
        final backlinks = snapshot.data ?? const [];
        final count = backlinks.length;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AtlasSpacing.md,
            vertical: AtlasSpacing.lg,
          ),
          child: Material(
            color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
              side: BorderSide(
                color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header Toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpacing.md,
                    vertical: AtlasSpacing.sm + 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 20,
                        color: count > 0
                            ? AtlasColors.accentBlue
                            : (isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary),
                      ),
                      const SizedBox(width: AtlasSpacing.sm),
                      Text(
                        'Backlinks ($count)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AtlasColors.darkTextPrimary
                              : AtlasColors.lightTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
              if (_isExpanded) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
                if (count == 0)
                  Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.md),
                    child: Text(
                      'No other notes link to this document yet. Type [[Title]] in another note to create a link.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: AtlasSpacing.xs,
                    ),
                    itemCount: count,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: AtlasSpacing.md,
                      endIndent: AtlasSpacing.md,
                      color: isDark
                          ? AtlasColors.darkBorder
                          : AtlasColors.lightBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = backlinks[index];
                      final isNotebook = item.sourceType == 'notebook';
                      final formattedDate = DateFormat.yMMMd().format(
                        item.sourceUpdatedAt,
                      );

                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                        onTap: () => _navigateToNode(context, item),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AtlasSpacing.md,
                          vertical: AtlasSpacing.xs,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(AtlasSpacing.xs),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AtlasColors.darkElevated
                                : AtlasColors.lightElevated,
                            borderRadius: BorderRadius.circular(
                              AtlasSpacing.radiusSm,
                            ),
                          ),
                          child: Icon(
                            isNotebook
                                ? Icons.draw_outlined
                                : Icons.description_outlined,
                            size: 20,
                            color: isNotebook
                                ? Colors.purpleAccent
                                : AtlasColors.accentBlue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.sourceTitle,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isNotebook
                                        ? Colors.purple
                                        : AtlasColors.accentBlue)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isNotebook ? 'Notebook' : 'Document',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isNotebook
                                      ? Colors.purple
                                      : AtlasColors.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              if (item.linkText != null &&
                                  item.linkText!.isNotEmpty) ...[
                                Text(
                                  'Linked as "${item.linkText}"',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AtlasColors.darkTextSecondary
                                        : AtlasColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: AtlasSpacing.sm),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: isDark
                                        ? AtlasColors.darkTextSecondary
                                        : AtlasColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: AtlasSpacing.sm),
                              ],
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextSecondary
                                      : AtlasColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
      },
    );
  }
}
