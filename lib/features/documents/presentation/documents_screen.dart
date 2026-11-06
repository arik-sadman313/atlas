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

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  void _showCreateDocumentDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

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
          title: Text('New Document', style: theme.textTheme.headlineMedium),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Document Title',
              hintText: 'e.g. Sprint Goals, Research Plan',
            ),
            onSubmitted: (val) => _createAndOpen(dialogCtx, ref, context, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  _createAndOpen(dialogCtx, ref, context, titleController.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAndOpen(
    BuildContext dialogCtx,
    WidgetRef ref,
    BuildContext screenCtx,
    String title,
  ) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: 'document',
        title: clean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Create an initial paragraph block
    await nodesDao.createBlock(
      NodeBlocksCompanion.insert(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}',
        nodeId: newId,
        type: 'paragraph',
        contentJson: const Value('{"text": "Start writing..."}'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
    }

    if (screenCtx.mounted) {
      screenCtx.go('/documents/$newId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final nodesDao = ref.watch(nodesDaoProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: StreamBuilder<List<NodeEntry>>(
          stream: nodesDao.watchNodesInWorkspace(workspaceId, type: 'document'),
          builder: (context, snapshot) {
            final docs = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Documents',
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: AtlasSpacing.xs),
                            Text(
                              'Typed documents, notes, and research pages',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        AtlasButton.primary(
                          label: 'New Document',
                          icon: Icons.add,
                          onPressed: () =>
                              _showCreateDocumentDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
                if (docs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AtlasEmptyState(
                      icon: Icons.description_outlined,
                      title: 'No documents yet',
                      description: 'Create your first document to capture structured notes, plans, and knowledge.',
                      actionLabel: 'New Document',
                      onAction: () => _showCreateDocumentDialog(context, ref),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.xl,
                      vertical: AtlasSpacing.sm,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final doc = docs[index];
                        final formattedDate = DateFormat.yMMMd()
                            .add_jm()
                            .format(doc.updatedAt);

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AtlasSpacing.sm,
                          ),
                          child: AtlasCard(
                            onTap: () => context.go('/documents/${doc.id}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AtlasColors.accentBlueSubtle,
                                    borderRadius: BorderRadius.circular(
                                      AtlasSpacing.radiusSm,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                    color: AtlasColors.accentBlue,
                                  ),
                                ),
                                const SizedBox(width: AtlasSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.title,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AtlasSpacing.xxs),
                                      Text(
                                        'Last edited $formattedDate',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    doc.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: doc.isFavorite
                                        ? AtlasColors.accentAmber
                                        : null,
                                  ),
                                  onPressed: () async {
                                    await nodesDao.updateNode(
                                      doc
                                          .toCompanion(true)
                                          .copyWith(
                                            isFavorite: Value(!doc.isFavorite),
                                            updatedAt: Value(DateTime.now()),
                                          ),
                                    );
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 16),
                                  onSelected: (action) async {
                                    if (action == 'delete') {
                                      await nodesDao.deleteNode(doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: docs.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
