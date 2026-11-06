import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<NodeEntry> _results = [];
  bool _isSearching = false;

  void _onQueryChanged(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final results = await nodesDao.searchNodes(workspaceId, clean);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Search Vault', style: theme.textTheme.displayMedium),
              const SizedBox(height: AtlasSpacing.xs),
              Text(
                'Real-time search across pages and notebooks in SQLite',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AtlasSpacing.lg),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search by title...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onQueryChanged,
              ),
              const SizedBox(height: AtlasSpacing.lg),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchController.text.trim().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_outlined,
                              size: 40,
                              color: isDark
                                  ? AtlasColors.darkTextMuted
                                  : AtlasColors.lightTextMuted,
                            ),
                            const SizedBox(height: AtlasSpacing.md),
                            Text(
                              'Enter a search term to find pages',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                    ? Center(
                        child: Text(
                          'No matching pages found for "${_searchController.text}"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final node = _results[index];
                          final formattedDate = DateFormat.yMMMd().format(
                            node.updatedAt,
                          );
                          final isNotebook = node.type == 'notebook';

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AtlasSpacing.sm,
                            ),
                            child: AtlasCard(
                              onTap: () {
                                if (isNotebook) {
                                  context.go('/notebooks');
                                } else {
                                  context.go('/documents/${node.id}');
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    isNotebook
                                        ? Icons.menu_book_outlined
                                        : Icons.description_outlined,
                                    size: 18,
                                    color: isNotebook
                                        ? AtlasColors.accentSage
                                        : AtlasColors.accentBlue,
                                  ),
                                  const SizedBox(width: AtlasSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          node.title,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          '${node.type.toUpperCase()} • Modified $formattedDate',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 12),
                                ],
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
    );
  }
}
