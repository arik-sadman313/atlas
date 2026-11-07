import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

enum SlashCommandCategory {
  text('Text & Headings'),
  lists('Lists'),
  containers('Containers'),
  dividersAndCode('Dividers & Code'),
  embeds('ATLAS Embeds');

  final String title;
  const SlashCommandCategory(this.title);
}

class SlashCommandItem {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<String> keywords;
  final SlashCommandCategory category;
  final FutureOr<void> Function() onExecute;

  const SlashCommandItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.keywords,
    required this.category,
    required this.onExecute,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (label.toLowerCase().contains(q)) return true;
    if (description.toLowerCase().contains(q)) return true;
    for (final kw in keywords) {
      if (kw.toLowerCase().contains(q) || q.contains(kw.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

class SlashCommandMenu extends StatefulWidget {
  final String query;
  final List<SlashCommandItem> items;
  final VoidCallback onDismiss;

  const SlashCommandMenu({
    super.key,
    required this.query,
    required this.items,
    required this.onDismiss,
  });

  @override
  State<SlashCommandMenu> createState() => SlashCommandMenuState();
}

class SlashCommandMenuState extends State<SlashCommandMenu> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  List<SlashCommandItem> get filteredItems {
    return widget.items.where((it) => it.matches(widget.query)).toList();
  }

  @override
  void didUpdateWidget(SlashCommandMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      final items = filteredItems;
      if (_selectedIndex >= items.length) {
        _selectedIndex = items.isEmpty ? 0 : items.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void selectNext() {
    final items = filteredItems;
    if (items.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % items.length;
    });
    _scrollToSelected();
  }

  void selectPrevious() {
    final items = filteredItems;
    if (items.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + items.length) % items.length;
    });
    _scrollToSelected();
  }

  void executeSelected() {
    final items = filteredItems;
    if (items.isEmpty) return;
    final index = _selectedIndex.clamp(0, items.length - 1);
    items[index].onExecute();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    const itemHeight = 52.0;
    final targetOffset = _selectedIndex * itemHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;

    if (targetOffset < currentOffset) {
      _scrollController.jumpTo(targetOffset);
    } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
      _scrollController.jumpTo(targetOffset + itemHeight - viewportHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = filteredItems;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: isDark ? AtlasColors.darkCard : AtlasColors.lightCard,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          border: Border.all(
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpacing.md,
                vertical: AtlasSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkElevated
                    : AtlasColors.lightElevated,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AtlasColors.accentBlue,
                  ),
                  const SizedBox(width: AtlasSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.query.isEmpty
                          ? 'Insert Block'
                          : 'Matching "${widget.query}"',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AtlasColors.darkTextPrimary
                            : AtlasColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AtlasSpacing.xs),
                  Text(
                    '${items.length} items',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AtlasColors.darkTextSecondary
                          : AtlasColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Items List
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AtlasSpacing.lg),
                child: Center(
                  child: Text(
                    'No commands matching "/${widget.query}"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AtlasColors.darkTextSecondary
                          : AtlasColors.lightTextSecondary,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = index == _selectedIndex;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        item.onExecute();
                      },
                      onHover: (hovered) {
                        if (hovered) {
                          setState(() => _selectedIndex = index);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AtlasSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? AtlasColors.darkElevated
                                    : AtlasColors.lightElevated)
                              : Colors.transparent,
                          border: isSelected
                              ? const Border(
                                  left: BorderSide(
                                    color: AtlasColors.accentBlue,
                                    width: 3.0,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AtlasColors.accentBlue.withValues(
                                        alpha: 0.15,
                                      )
                                    : (isDark
                                          ? AtlasColors.darkSurface
                                          : AtlasColors.lightSurface),
                                borderRadius: BorderRadius.circular(
                                  AtlasSpacing.radiusSm,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 16,
                                color: isSelected
                                    ? AtlasColors.accentBlue
                                    : (isDark
                                          ? AtlasColors.darkTextSecondary
                                          : AtlasColors.lightTextSecondary),
                              ),
                            ),
                            const SizedBox(width: AtlasSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isDark
                                          ? AtlasColors.darkTextPrimary
                                          : AtlasColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    item.description,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isDark
                                          ? AtlasColors.darkTextSecondary
                                          : AtlasColors.lightTextSecondary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Footer keyboard hints
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkSurface
                    : AtlasColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      '↑↓ Navigate',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Text(
                      '↵ Select',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Text(
                      'Esc Dismiss',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
