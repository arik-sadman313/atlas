import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_button.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../../../shared/widgets/atlas_empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String selectedType = 'document';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  width: 1.0,
                ),
              ),
              title: Text('Create Item', style: theme.textTheme.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'document',
                        label: Text('Document'),
                        icon: Icon(Icons.description_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'notebook',
                        label: Text('Notebook'),
                        icon: Icon(Icons.menu_book_outlined, size: 16),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) {
                      setDialogState(() {
                        selectedType = set.first;
                      });
                    },
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: selectedType == 'document'
                          ? 'e.g. Design Principles'
                          : 'e.g. Quarterly Planning',
                    ),
                    onSubmitted: (_) => _saveItem(
                      dialogCtx,
                      ref,
                      titleController.text,
                      selectedType,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _saveItem(
                    dialogCtx,
                    ref,
                    titleController.text,
                    selectedType,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveItem(
    BuildContext dialogCtx,
    WidgetRef ref,
    String title,
    String type,
  ) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'node_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: type,
        title: clean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceAsync = ref.watch(currentWorkspaceProvider);
    final recentNodesAsync = ref.watch(recentNodesProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar / Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtlasSpacing.xl,
                  AtlasSpacing.xl,
                  AtlasSpacing.xl,
                  AtlasSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.xs),
                          Text(
                            'Workspace Overview',
                            style: theme.textTheme.displayMedium,
                          ),
                          const SizedBox(height: AtlasSpacing.xs),
                          workspaceAsync.when(
                            data: (ws) => Text(
                              ws?.name ?? 'Personal Vault',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    AtlasButton.primary(
                      label: 'New Page',
                      icon: Icons.add,
                      onPressed: () => _showCreateDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.xl,
                  vertical: AtlasSpacing.md,
                ),
                child: recentNodesAsync.when(
                  data: (nodes) {
                    final docsCount = nodes
                        .where((n) => n.type == 'document')
                        .length;
                    final notebookCount = nodes
                        .where((n) => n.type == 'notebook')
                        .length;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Recent Documents',
                                value: docsCount.toString(),
                                icon: Icons.article_outlined,
                                accentColor: AtlasColors.accentBlue,
                                onTap: () => context.go('/documents'),
                              ),
                            ),
                            const SizedBox(width: AtlasSpacing.md),
                            Expanded(
                              child: _StatCard(
                                title: 'Active Notebooks',
                                value: notebookCount.toString(),
                                icon: Icons.menu_book_outlined,
                                accentColor: AtlasColors.accentSage,
                                onTap: () => context.go('/notebooks'),
                              ),
                            ),
                            if (isWide) ...[
                              const SizedBox(width: AtlasSpacing.md),
                              Expanded(
                                child: _StatCard(
                                  title: 'Quick Search',
                                  value: 'Vault Index',
                                  icon: Icons.search_outlined,
                                  accentColor: AtlasColors.accentAmber,
                                  onTap: () => context.go('/search'),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Section Header: Recent Pages
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtlasSpacing.xl,
                  AtlasSpacing.lg,
                  AtlasSpacing.xl,
                  AtlasSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recently Modified',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/documents'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Nodes List
            recentNodesAsync.when(
              data: (nodes) {
                if (nodes.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AtlasEmptyState(
                      icon: Icons.auto_stories_outlined,
                      title: 'Your workspace is empty',
                      description: 'Create your first document or notebook to begin organizing your thoughts.',
                      actionLabel: 'Create First Page',
                      onAction: () => _showCreateDialog(context, ref),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpacing.xl,
                    vertical: AtlasSpacing.sm,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final node = nodes[index];
                      final formattedDate = DateFormat.yMMMd().add_jm().format(
                        node.updatedAt,
                      );
                      final isNotebook = node.type == 'notebook';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AtlasSpacing.sm),
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isNotebook
                                      ? AtlasColors.accentSageSubtle
                                      : AtlasColors.accentBlueSubtle,
                                  borderRadius: BorderRadius.circular(
                                    AtlasSpacing.radiusSm,
                                  ),
                                ),
                                child: Icon(
                                  isNotebook
                                      ? Icons.menu_book_outlined
                                      : Icons.description_outlined,
                                  size: 18,
                                  color: isNotebook
                                      ? AtlasColors.accentSage
                                      : AtlasColors.accentBlue,
                                ),
                              ),
                              const SizedBox(width: AtlasSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      node.title,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AtlasSpacing.xxs),
                                    Text(
                                      'Updated $formattedDate',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  node.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: node.isFavorite
                                      ? AtlasColors.accentAmber
                                      : null,
                                ),
                                onPressed: () async {
                                  final nodesDao = ref.read(nodesDaoProvider);
                                  await nodesDao.updateNode(
                                    node
                                        .toCompanion(true)
                                        .copyWith(
                                          isFavorite: Value(!node.isFavorite),
                                          updatedAt: Value(DateTime.now()),
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: nodes.length),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AtlasSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AtlasSpacing.xl),
                  child: Text('Error loading dashboard: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AtlasCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
