import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class WikiLinkDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  final String? initialQuery;

  const WikiLinkDialog({
    super.key,
    required this.workspaceId,
    this.initialQuery,
  });

  /// Static helper to display the dialog and return the formatted `[[Note Title]]` string,
  /// or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String workspaceId,
    String? initialQuery,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) =>
          WikiLinkDialog(workspaceId: workspaceId, initialQuery: initialQuery),
    );
  }

  @override
  ConsumerState<WikiLinkDialog> createState() => _WikiLinkDialogState();
}

class _WikiLinkDialogState extends ConsumerState<WikiLinkDialog> {
  late final TextEditingController _searchController;
  final TextEditingController _aliasController = TextEditingController();
  List<NodeEntry> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _performSearch(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final linkRepo = ref.read(linkRepositoryProvider);
    final trimmed = query.trim();

    List<NodeEntry> matches;
    if (trimmed.isEmpty) {
      // Default: fetch recent nodes
      final nodesDao = ref.read(nodesDaoProvider);
      matches = await nodesDao
          .watchRecentNodes(widget.workspaceId, limit: 15)
          .first;
    } else {
      matches = await linkRepo.searchTargets(widget.workspaceId, trimmed);
    }

    if (mounted) {
      setState(() {
        _results = matches;
        _isLoading = false;
      });
    }
  }

  void _submitSelection(String targetTitle) {
    final alias = _aliasController.text.trim();
    final link = (alias.isNotEmpty && alias != targetTitle)
        ? '[[$targetTitle|$alias]]'
        : '[[$targetTitle]]';
    Navigator.of(context).pop(link);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trimmedQuery = _searchController.text.trim();

    return AlertDialog(
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
        side: BorderSide(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          width: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AtlasSpacing.lg,
        AtlasSpacing.lg,
        AtlasSpacing.lg,
        AtlasSpacing.sm,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AtlasSpacing.lg),
      actionsPadding: const EdgeInsets.all(AtlasSpacing.md),
      title: const Row(
        children: [
          Icon(Icons.link_rounded, color: AtlasColors.accentBlue),
          SizedBox(width: AtlasSpacing.sm),
          Text(
            'Insert Wiki-Link',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search note by title...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.md,
                  vertical: AtlasSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                ),
              ),
              onChanged: _performSearch,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _submitSelection(val.trim());
                }
              },
            ),
            const SizedBox(height: AtlasSpacing.sm),

            // Optional Alias Input
            TextField(
              controller: _aliasController,
              decoration: InputDecoration(
                hintText: 'Custom label/alias (optional)',
                prefixIcon: const Icon(Icons.label_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.md,
                  vertical: AtlasSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                ),
              ),
            ),
            const SizedBox(height: AtlasSpacing.md),

            // Results List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AtlasSpacing.lg),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AtlasSpacing.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            trimmedQuery.isEmpty
                                ? 'No notes found in workspace'
                                : 'No existing note named "$trimmedQuery"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary,
                            ),
                          ),
                          if (trimmedQuery.isNotEmpty) ...[
                            const SizedBox(height: AtlasSpacing.sm),
                            TextButton.icon(
                              onPressed: () => _submitSelection(trimmedQuery),
                              icon: const Icon(Icons.add_link, size: 18),
                              label: Text('Link to "[[$trimmedQuery]]" anyway'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: isDark
                            ? AtlasColors.darkBorder
                            : AtlasColors.lightBorder,
                      ),
                      itemBuilder: (context, index) {
                        final node = _results[index];
                        final isNotebook = node.type == 'notebook';

                        return Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AtlasSpacing.sm,
                              vertical: 2,
                            ),
                            leading: Icon(
                              isNotebook
                                  ? Icons.draw_outlined
                                  : Icons.description_outlined,
                              size: 18,
                              color: isNotebook
                                  ? Colors.purpleAccent
                                  : AtlasColors.accentBlue,
                            ),
                            title: Text(
                              node.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isNotebook
                                            ? Colors.purple
                                            : AtlasColors.accentBlue)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isNotebook ? 'Notebook' : 'Document',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isNotebook
                                      ? Colors.purple
                                      : AtlasColors.accentBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () => _submitSelection(node.title),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        if (trimmedQuery.isNotEmpty)
          FilledButton(
            onPressed: () => _submitSelection(trimmedQuery),
            child: const Text('Insert Link'),
          ),
      ],
    );
  }
}
