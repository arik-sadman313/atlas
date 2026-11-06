import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../../../shared/widgets/atlas_empty_state.dart';
import '../domain/models/search_result_item.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  List<SearchResultItem> _results = [];
  bool _isLoading = false;
  SearchFilter _selectedFilter = SearchFilter.all;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _selectedIndex = 0;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final repo = ref.read(searchRepositoryProvider);

    final results = await repo.search(
      workspaceId,
      clean,
      filter: _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
        _selectedIndex = 0;
      });
    }
  }

  void _onFilterChanged(SearchFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _executeSearch(_searchController.text);
  }

  void _openResult(SearchResultItem item) {
    context.go(item.route);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_results.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _results.length - 1);
        });
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_results.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, _results.length - 1);
        });
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_results.isNotEmpty && _selectedIndex < _results.length) {
        _openResult(_results[_selectedIndex]);
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _searchController.clear();
      _executeSearch('');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (_results.isEmpty) return;
    const itemHeight = 88.0;
    final targetOffset = _selectedIndex * itemHeight;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getBadgeColor(SearchEntityType type) {
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

  IconData _getBadgeIcon(SearchEntityType type) {
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

  String _formatType(SearchEntityType type) {
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

  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle? baseStyle,
    TextStyle? highlightStyle,
  ) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return Text(text, style: baseStyle);

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(cleanQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + cleanQuery.length),
          style: highlightStyle,
        ),
      );
      start = index + cleanQuery.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      focusNode: _inputFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(AtlasSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text('Search Vault', style: theme.textTheme.displayMedium),
                    const SizedBox(height: AtlasSpacing.xs),
                    Text(
                      'Unified multi-entity search across notes, notebooks, tasks, calendar & journals',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),

                    // Search Input Field
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Type keywords to search (e.g. Architecture, sprint, [[link]])...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _executeSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _onQueryChanged,
                    ),
                    const SizedBox(height: AtlasSpacing.md),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _selectedFilter == SearchFilter.all,
                            onSelected: () =>
                                _onFilterChanged(SearchFilter.all),
                          ),
                          const SizedBox(width: AtlasSpacing.xs),
                          _FilterChip(
                            label: 'Documents',
                            icon: Icons.article_outlined,
                            isSelected:
                                _selectedFilter == SearchFilter.document,
                            onSelected: () =>
                                _onFilterChanged(SearchFilter.document),
                          ),
                          const SizedBox(width: AtlasSpacing.xs),
                          _FilterChip(
                            label: 'Notebooks',
                            icon: Icons.menu_book_outlined,
                            isSelected:
                                _selectedFilter == SearchFilter.notebook,
                            onSelected: () =>
                                _onFilterChanged(SearchFilter.notebook),
                          ),
                          const SizedBox(width: AtlasSpacing.xs),
                          _FilterChip(
                            label: 'Tasks',
                            icon: Icons.check_circle_outline,
                            isSelected: _selectedFilter == SearchFilter.task,
                            onSelected: () =>
                                _onFilterChanged(SearchFilter.task),
                          ),
                          const SizedBox(width: AtlasSpacing.xs),
                          _FilterChip(
                            label: 'Calendar',
                            icon: Icons.calendar_today_outlined,
                            isSelected:
                                _selectedFilter == SearchFilter.calendar,
                            onSelected: () =>
                                _onFilterChanged(SearchFilter.calendar),
                          ),
                          const SizedBox(width: AtlasSpacing.xs),
                          _FilterChip(
                            label: 'Journal',
                            icon: Icons.auto_stories_outlined,
                            isSelected: _selectedFilter == SearchFilter.journal,
                            onSelected: () =>
                                _onFilterChanged(SearchFilter.journal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.lg),

                    // Results Console or Jump Back In Dashboard
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _searchController.text.trim().isEmpty
                          ? _buildJumpBackInDashboard(context, theme, isDark)
                          : _results.isEmpty
                          ? AtlasEmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No results found',
                              description:
                                  'No matches found for "${_searchController.text.trim()}". Try adjusting your filters or keywords.',
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final item = _results[index];
                                final isSelected = index == _selectedIndex;
                                final badgeColor = _getBadgeColor(item.type);
                                final badgeIcon = _getBadgeIcon(item.type);
                                final typeLabel = _formatType(item.type);
                                final timeAgo = DateFormat.yMMMd().format(
                                  item.updatedAt,
                                );

                                final highlightStyle = theme
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.amberAccent
                                          : Colors.orange.shade800,
                                      backgroundColor: isDark
                                          ? Colors.amber.withValues(alpha: 0.2)
                                          : Colors.amber.withValues(
                                              alpha: 0.15,
                                            ),
                                    );

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AtlasSpacing.sm,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      AtlasSpacing.radiusMd,
                                    ),
                                    onTap: () => _openResult(item),
                                    child: AtlasCard(
                                      child: Container(
                                        decoration: isSelected
                                            ? BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AtlasSpacing.radiusSm,
                                                    ),
                                                border: Border.all(
                                                  color: AtlasColors.accentBlue,
                                                  width: 1.5,
                                                ),
                                              )
                                            : null,
                                        padding: isSelected
                                            ? const EdgeInsets.all(2.0)
                                            : EdgeInsets.zero,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Entity Icon Badge
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AtlasSpacing.radiusSm,
                                                    ),
                                              ),
                                              child: Icon(
                                                badgeIcon,
                                                size: 18,
                                                color: badgeColor,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AtlasSpacing.md,
                                            ),

                                            // Content details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      // Type pill
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: badgeColor
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          typeLabel,
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color:
                                                                    badgeColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      ),
                                                      if (item.parentBreadcrumb !=
                                                          null) ...[
                                                        const SizedBox(
                                                          width:
                                                              AtlasSpacing.xs,
                                                        ),
                                                        Text(
                                                          '· ${item.parentBreadcrumb}',
                                                          style: theme
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: isDark
                                                                    ? AtlasColors
                                                                          .darkTextSecondary
                                                                    : AtlasColors
                                                                          .lightTextSecondary,
                                                              ),
                                                        ),
                                                      ],
                                                      const Spacer(),
                                                      Text(
                                                        timeAgo,
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
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
                                                  const SizedBox(
                                                    height: AtlasSpacing.xxs,
                                                  ),

                                                  // Highlighted Title
                                                  _buildHighlightedText(
                                                    item.title,
                                                    _searchController.text,
                                                    theme.textTheme.bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    highlightStyle,
                                                  ),

                                                  if (item.subtitle !=
                                                      null) ...[
                                                    const SizedBox(
                                                      height: AtlasSpacing.xxs,
                                                    ),
                                                    Text(
                                                      item.subtitle!,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: isDark
                                                                ? AtlasColors
                                                                      .darkTextSecondary
                                                                : AtlasColors
                                                                      .lightTextSecondary,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],

                                                  // Context Snippet if any
                                                  if (item.snippet != null &&
                                                      item
                                                          .snippet!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(
                                                      height: AtlasSpacing.xs,
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            AtlasSpacing.xs,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? AtlasColors
                                                                  .darkElevated
                                                            : AtlasColors
                                                                  .lightElevated,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              AtlasSpacing
                                                                  .radiusSm,
                                                            ),
                                                      ),
                                                      child:
                                                          _buildHighlightedText(
                                                            item.snippet!,
                                                            _searchController
                                                                .text,
                                                            theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                ),
                                                            highlightStyle,
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJumpBackInDashboard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final recentNodesAsync = ref.watch(recentNodesProvider);
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final tasksDao = ref.watch(tasksDaoProvider);
    final calendarDao = ref.watch(calendarDaoProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Jump Back In Header
            Row(
              children: [
                Icon(Icons.history, size: 16, color: AtlasColors.accentBlue),
                const SizedBox(width: 8),
                Text(
                  'Jump Back In',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AtlasColors.darkTextSecondary
                        : AtlasColors.lightTextSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.sm),

            // 3 Recent Items Row
            recentNodesAsync.when(
              data: (nodes) {
                final recent3 = nodes.take(3).toList();
                if (recent3.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AtlasSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AtlasColors.darkCard
                          : AtlasColors.lightSurface,
                      borderRadius: BorderRadius.circular(
                        AtlasSpacing.radiusCard,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AtlasColors.darkBorder
                            : AtlasColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      'No recent documents or notebooks yet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: recent3
                            .map(
                              (node) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _RecentItemCard(node: node),
                              ),
                            )
                            .toList(),
                      );
                    }

                    return Row(
                      children: [
                        for (int i = 0; i < recent3.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: _RecentItemCard(node: recent3[i])),
                        ],
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AtlasSpacing.xl),

            // Quick Filter Category Badges with counts
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: AtlasColors.accentSage,
                ),
                const SizedBox(width: 8),
                Text(
                  'Browse by Category',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AtlasColors.darkTextSecondary
                        : AtlasColors.lightTextSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AtlasSpacing.sm),

            recentNodesAsync.when(
              data: (nodes) {
                final docsCount = nodes
                    .where((n) => n.type == 'document')
                    .length;
                final notebookCount = nodes
                    .where((n) => n.type == 'notebook')
                    .length;

                return StreamBuilder<List<TaskEntry>>(
                  stream: tasksDao.watchTasksForWorkspace(
                    workspaceId,
                    isCompleted: false,
                  ),
                  builder: (context, taskSnap) {
                    final taskCount = taskSnap.data?.length ?? 0;
                    return StreamBuilder<List<CalendarEventEntry>>(
                      stream: calendarDao.watchAllEvents(workspaceId),
                      builder: (context, calSnap) {
                        final calCount = calSnap.data?.length ?? 0;

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _CategoryBadgeCard(
                              label: 'Documents',
                              count: docsCount,
                              icon: Icons.article_outlined,
                              accentColor: AtlasColors.accentBlue,
                              onTap: () =>
                                  _onFilterChanged(SearchFilter.document),
                            ),
                            _CategoryBadgeCard(
                              label: 'Notebooks',
                              count: notebookCount,
                              icon: Icons.menu_book_outlined,
                              accentColor: AtlasColors.accentSage,
                              onTap: () =>
                                  _onFilterChanged(SearchFilter.notebook),
                            ),
                            _CategoryBadgeCard(
                              label: 'Tasks',
                              count: taskCount,
                              icon: Icons.check_circle_outline,
                              accentColor: AtlasColors.priorityP1,
                              onTap: () => _onFilterChanged(SearchFilter.task),
                            ),
                            _CategoryBadgeCard(
                              label: 'Calendar',
                              count: calCount,
                              icon: Icons.calendar_today_outlined,
                              accentColor: AtlasColors.accentAmber,
                              onTap: () =>
                                  _onFilterChanged(SearchFilter.calendar),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AtlasSpacing.xxl),

            // Keyboard Shortcut Tips Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AtlasColors.darkCard : AtlasColors.lightSurface,
                borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
                border: Border.all(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _KeyboardShortcutBadge(keys: '↑ / ↓', label: 'Navigate'),
                  SizedBox(width: 20),
                  _KeyboardShortcutBadge(keys: 'Enter', label: 'Open'),
                  SizedBox(width: 20),
                  _KeyboardShortcutBadge(keys: 'Esc', label: 'Clear'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final NodeEntry node;
  const _RecentItemCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNotebook = node.type == 'notebook';
    final accentColor = isNotebook
        ? AtlasColors.accentSage
        : AtlasColors.accentBlue;

    return AtlasCard(
      onTap: () {
        if (isNotebook) {
          context.go('/notebooks');
        } else {
          context.go('/documents/${node.id}');
        }
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isNotebook
                      ? Icons.menu_book_outlined
                      : Icons.article_outlined,
                  size: 14,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                isNotebook ? 'Notebook' : 'Doc',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            node.title.isEmpty ? 'Untitled' : node.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat.MMMd().format(node.updatedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: isDark
                  ? AtlasColors.darkTextMuted
                  : AtlasColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadgeCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _CategoryBadgeCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardShortcutBadge extends StatelessWidget {
  final String keys;
  final String label;

  const _KeyboardShortcutBadge({required this.keys, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDark
                ? AtlasColors.darkElevated
                : AtlasColors.lightElevated,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            ),
          ),
          child: Text(
            keys,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AtlasColors.darkTextSecondary
                : AtlasColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AtlasColors.accentBlue
              : (isDark ? AtlasColors.darkElevated : AtlasColors.lightElevated),
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
          border: Border.all(
            color: isSelected
                ? AtlasColors.accentBlue
                : (isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AtlasColors.darkTextSecondary
                          : AtlasColors.lightTextSecondary),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AtlasColors.darkTextPrimary
                          : AtlasColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
