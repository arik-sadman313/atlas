import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../features/search/domain/models/search_result_item.dart';
import 'command_registry.dart';

class CommandPaletteModal extends ConsumerStatefulWidget {
  const CommandPaletteModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => const CommandPaletteModal(),
    );
  }

  @override
  ConsumerState<CommandPaletteModal> createState() =>
      _CommandPaletteModalState();
}

enum _PaletteMode { unified, commands, tags, dates }

class _CommandItemWrapper {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? category;
  final String? shortcut;
  final VoidCallback onSelect;

  const _CommandItemWrapper({
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.category,
    this.shortcut,
    required this.onSelect,
  });
}

class _CommandPaletteModalState extends ConsumerState<CommandPaletteModal> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  _PaletteMode _mode = _PaletteMode.unified;
  String _activeQuery = '';
  int _selectedIndex = 0;
  List<_CommandItemWrapper> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems('');
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    _parseModeAndQuery(text);
    _loadItems(_activeQuery);
  }

  void _parseModeAndQuery(String text) {
    final trimmed = text.trimLeft();
    if (trimmed.startsWith('>')) {
      _mode = _PaletteMode.commands;
      _activeQuery = trimmed.substring(1).trim();
    } else if (trimmed.startsWith('#')) {
      _mode = _PaletteMode.tags;
      _activeQuery = trimmed.substring(1).trim();
    } else if (trimmed.startsWith('@')) {
      _mode = _PaletteMode.dates;
      _activeQuery = trimmed.substring(1).trim();
    } else {
      _mode = _PaletteMode.unified;
      _activeQuery = trimmed;
    }
  }

  Future<void> _loadItems(String query) async {
    setState(() => _isLoading = true);

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final allActions = CommandRegistry.getActions();
    final lowerQuery = query.toLowerCase();

    final results = <_CommandItemWrapper>[];

    // 1. Actions Mode (> prefix)
    if (_mode == _PaletteMode.commands) {
      final filteredActions = allActions.where((a) {
        if (query.isEmpty) return true;
        return a.label.toLowerCase().contains(lowerQuery) ||
            a.keywords.any((k) => k.contains(lowerQuery)) ||
            a.category.toLowerCase().contains(lowerQuery);
      }).toList();

      for (final a in filteredActions) {
        results.add(
          _CommandItemWrapper(
            title: a.label,
            subtitle: a.category,
            icon: a.icon,
            iconColor: a.category == 'Create'
                ? AtlasColors.accentSage
                : (a.category == 'System'
                      ? AtlasColors.accentAmber
                      : AtlasColors.accentBlue),
            category: a.category,
            shortcut: a.shortcut,
            onSelect: () {
              Navigator.of(context).pop();
              a.run(context, ref);
            },
          ),
        );
      }
    }
    // 2. Tags Mode (# prefix)
    else if (_mode == _PaletteMode.tags) {
      final linksDao = ref.read(linksDaoProvider);
      final tags = await linksDao.getAllTagsForWorkspace(workspaceId);
      final filtered = tags.where((t) {
        if (query.isEmpty) return true;
        return t.name.toLowerCase().contains(lowerQuery);
      });

      for (final t in filtered) {
        results.add(
          _CommandItemWrapper(
            title: '#${t.name}',
            subtitle: 'Tag',
            icon: Icons.tag,
            iconColor: AtlasColors.accentPurple,
            category: 'Taxonomy',
            onSelect: () {
              Navigator.of(context).pop();
              context.go('/graph');
            },
          ),
        );
      }
    }
    // 3. Dates Mode (@ prefix)
    else if (_mode == _PaletteMode.dates) {
      final now = DateTime.now();
      final calendarDao = ref.read(calendarDaoProvider);
      final events = await calendarDao.getEventsForDay(workspaceId, now);

      results.add(
        _CommandItemWrapper(
          title: 'Jump to Today',
          subtitle: DateFormat.yMMMMEEEEd().format(now),
          icon: Icons.today,
          iconColor: AtlasColors.accentBlue,
          category: 'Calendar',
          onSelect: () {
            Navigator.of(context).pop();
            context.go('/calendar');
          },
        ),
      );

      for (final e in events) {
        final timeStr = DateFormat.jm().format(e.startTime);
        results.add(
          _CommandItemWrapper(
            title: e.title,
            subtitle: 'Today at $timeStr',
            icon: Icons.event,
            iconColor: AtlasColors.accentAmber,
            category: 'Event',
            onSelect: () {
              Navigator.of(context).pop();
              context.go('/calendar');
            },
          ),
        );
      }
    }
    // 4. Unified Mode (No prefix: search recent items + top commands)
    else {
      // Add commands that match query
      final matchingActions = allActions
          .where((a) {
            if (query.isEmpty) return false;
            return a.label.toLowerCase().contains(lowerQuery) ||
                a.keywords.any((k) => k.contains(lowerQuery));
          })
          .take(3);

      for (final a in matchingActions) {
        results.add(
          _CommandItemWrapper(
            title: a.label,
            subtitle: a.category,
            icon: a.icon,
            iconColor: AtlasColors.accentBlue,
            category: 'Action',
            shortcut: a.shortcut,
            onSelect: () {
              Navigator.of(context).pop();
              a.run(context, ref);
            },
          ),
        );
      }

      // Add search results via searchRepository
      final searchRepo = ref.read(searchRepositoryProvider);
      if (query.isNotEmpty) {
        final searchResults = await searchRepo.search(
          workspaceId,
          query,
          limit: 7,
        );
        for (final r in searchResults) {
          results.add(
            _CommandItemWrapper(
              title: r.title,
              subtitle: r.subtitle ?? r.parentBreadcrumb,
              icon: _getIconForType(r.type),
              iconColor: _getColorForType(r.type),
              category: _getCategoryForType(r.type),
              onSelect: () {
                Navigator.of(context).pop();
                context.go(r.route);
              },
            ),
          );
        }
      } else {
        // Show recent nodes when query is empty
        final nodesDao = ref.read(nodesDaoProvider);
        final recentNodes = await nodesDao.getRecentNodes(
          workspaceId,
          limit: 6,
        );
        for (final n in recentNodes) {
          final isNotebook = n.type == 'notebook';
          results.add(
            _CommandItemWrapper(
              title: n.title,
              subtitle: isNotebook ? 'Notebook' : 'Document',
              icon: isNotebook
                  ? Icons.menu_book_outlined
                  : Icons.description_outlined,
              iconColor: isNotebook
                  ? AtlasColors.accentSage
                  : AtlasColors.accentBlue,
              category: 'Recent',
              onSelect: () {
                Navigator.of(context).pop();
                if (isNotebook) {
                  context.go('/notebooks/${n.id}');
                } else {
                  context.go('/documents/${n.id}');
                }
              },
            ),
          );
        }

        // Add top actions as well
        for (final a in allActions.take(4)) {
          results.add(
            _CommandItemWrapper(
              title: a.label,
              subtitle: a.category,
              icon: a.icon,
              iconColor: AtlasColors.lightTextSecondary,
              category: a.category,
              shortcut: a.shortcut,
              onSelect: () {
                Navigator.of(context).pop();
                a.run(context, ref);
              },
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _items = results;
        _selectedIndex = 0;
        _isLoading = false;
      });
    }
  }

  IconData _getIconForType(SearchEntityType type) {
    switch (type) {
      case SearchEntityType.document:
        return Icons.article_outlined;
      case SearchEntityType.notebook:
        return Icons.menu_book_outlined;
      case SearchEntityType.task:
        return Icons.check_circle_outline;
      case SearchEntityType.calendarEvent:
        return Icons.calendar_today_outlined;
      case SearchEntityType.journal:
        return Icons.auto_stories_outlined;
      case SearchEntityType.tag:
        return Icons.tag;
    }
  }

  Color _getColorForType(SearchEntityType type) {
    switch (type) {
      case SearchEntityType.document:
        return AtlasColors.accentBlue;
      case SearchEntityType.notebook:
        return AtlasColors.accentSage;
      case SearchEntityType.task:
        return AtlasColors.priorityP1;
      case SearchEntityType.calendarEvent:
        return AtlasColors.accentAmber;
      case SearchEntityType.journal:
        return AtlasColors.accentSage;
      case SearchEntityType.tag:
        return AtlasColors.accentPurple;
    }
  }

  String _getCategoryForType(SearchEntityType type) {
    switch (type) {
      case SearchEntityType.document:
        return 'Document';
      case SearchEntityType.notebook:
        return 'Notebook';
      case SearchEntityType.task:
        return 'Task';
      case SearchEntityType.calendarEvent:
        return 'Calendar';
      case SearchEntityType.journal:
        return 'Journal';
      case SearchEntityType.tag:
        return 'Tag';
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_items.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _items.length - 1);
        });
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_items.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, _items.length - 1);
        });
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_items.isNotEmpty && _selectedIndex < _items.length) {
        _items[_selectedIndex].onSelect();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (_items.isEmpty) return;
    const itemHeight = 52.0;
    final targetOffset = _selectedIndex * itemHeight;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  String _getHintText() {
    switch (_mode) {
      case _PaletteMode.commands:
        return 'Type an action or command...';
      case _PaletteMode.tags:
        return 'Filter pages by #tag...';
      case _PaletteMode.dates:
        return 'Jump to date or event...';
      case _PaletteMode.unified:
        return 'Type a command (>), tag (#), date (@), or search pages...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        alignment: Alignment.topCenter,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
            decoration: BoxDecoration(
              color: isDark
                  ? AtlasColors.darkSurface
                  : AtlasColors.lightSurface,
              borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        _mode == _PaletteMode.commands
                            ? Icons.terminal
                            : (_mode == _PaletteMode.tags
                                  ? Icons.tag
                                  : (_mode == _PaletteMode.dates
                                        ? Icons.calendar_today
                                        : Icons.search)),
                        size: 20,
                        color: AtlasColors.accentBlue,
                      ),
                      const SizedBox(width: AtlasSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: _getHintText(),
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onInputChanged,
                        ),
                      ),
                      if (_textController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _textController.clear();
                            _onInputChanged('');
                          },
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AtlasColors.darkElevated
                              : AtlasColors.lightElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ESC to close',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),

                // Results / Items List
                Flexible(
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AtlasSpacing.lg),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AtlasSpacing.xl),
                          child: Center(
                            child: Text(
                              'No matching commands or notes found.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: AtlasSpacing.xs,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final isSelected = index == _selectedIndex;

                            return InkWell(
                              onTap: item.onSelect,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                            ? AtlasColors.darkElevated
                                            : AtlasColors.lightElevated)
                                      : Colors.transparent,
                                  border: isSelected
                                      ? Border(
                                          left: BorderSide(
                                            color: AtlasColors.accentBlue,
                                            width: 3.0,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 18,
                                      color:
                                          item.iconColor ??
                                          (isDark
                                              ? AtlasColors.darkTextSecondary
                                              : AtlasColors.lightTextSecondary),
                                    ),
                                    const SizedBox(width: AtlasSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.subtitle != null) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              item.subtitle!,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? AtlasColors
                                                              .darkTextSecondary
                                                        : AtlasColors
                                                              .lightTextSecondary,
                                                    fontSize: 11,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (item.shortcut != null) ...[
                                      const SizedBox(width: AtlasSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AtlasColors.darkBg
                                              : AtlasColors.lightBg,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? AtlasColors.darkBorderSubtle
                                                : AtlasColors.lightBorderSubtle,
                                          ),
                                        ),
                                        child: Text(
                                          item.shortcut!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer Mode Hints
                Divider(
                  height: 1,
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildHintBadge('> Actions', theme, isDark),
                      const SizedBox(width: AtlasSpacing.sm),
                      _buildHintBadge('# Tags', theme, isDark),
                      const SizedBox(width: AtlasSpacing.sm),
                      _buildHintBadge('@ Dates', theme, isDark),
                      const Spacer(),
                      Text(
                        '↑↓ to navigate · ↵ to select',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBadge(String label, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AtlasColors.darkElevated : AtlasColors.lightElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: isDark
              ? AtlasColors.darkTextSecondary
              : AtlasColors.lightTextSecondary,
        ),
      ),
    );
  }
}
