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
                  _buildStarterScreen(context, ref, theme, isDark)
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AtlasColors.accentBlue.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AtlasSpacing.radiusSm,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              doc.title,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AtlasColors.darkElevated
                                                  : AtlasColors.lightElevated,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Page',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? AtlasColors
                                                          .darkTextSecondary
                                                    : AtlasColors
                                                          .lightTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AtlasSpacing.xxs),
                                      Text(
                                        'Last edited $formattedDate',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? AtlasColors.darkTextMuted
                                                  : AtlasColors.lightTextMuted,
                                            ),
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

  Future<void> _createFromTemplate(
    BuildContext context,
    WidgetRef ref,
    String title,
    String initialContent,
  ) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: 'document',
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await nodesDao.createBlock(
      NodeBlocksCompanion.insert(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}',
        nodeId: newId,
        type: 'paragraph',
        contentJson: Value('{"text": "$initialContent"}'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (context.mounted) {
      context.go('/documents/$newId');
    }
  }

  Widget _buildStarterScreen(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.xl,
          vertical: AtlasSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary Starter Card
                AtlasCard(
                  onTap: () => _showCreateDocumentDialog(context, ref),
                  padding: const EdgeInsets.all(AtlasSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AtlasColors.accentBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          size: 26,
                          color: AtlasColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: AtlasSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Blank Document',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rich-text blocks, bidirectional [[wiki-links]], code snippets, and checklists.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AtlasSpacing.md),
                      FilledButton.tonal(
                        onPressed: () =>
                            _showCreateDocumentDialog(context, ref),
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AtlasSpacing.xl),

                // Starter Templates Section
                Text(
                  'Quick-Start Templates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AtlasColors.darkTextPrimary
                        : AtlasColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  'Jumpstart your thoughts with pre-structured document scaffolding',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AtlasColors.darkTextSecondary
                        : AtlasColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: _DocTemplateCard(
                        icon: Icons.architecture,
                        accentColor: AtlasColors.accentPurple,
                        title: 'RFC & Architecture Plan',
                        description:
                            'System design, constraints, and ADR notes',
                        onTap: () => _createFromTemplate(
                          context,
                          ref,
                          'RFC: Architecture Plan',
                          '# RFC & System Architecture\\n\\n## Context & Problem\\n\\n## Proposed Architecture\\n\\n## Trade-offs\\n',
                        ),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Expanded(
                      child: _DocTemplateCard(
                        icon: Icons.groups_outlined,
                        accentColor: AtlasColors.accentSage,
                        title: 'Meeting Notes',
                        description:
                            'Agenda, discussion topics, and action items',
                        onTap: () => _createFromTemplate(
                          context,
                          ref,
                          'Meeting Notes: ${DateFormat.MMMd().format(DateTime.now())}',
                          '# Meeting Notes\\n\\n**Date:** ${DateFormat.yMMMd().format(DateTime.now())}\\n\\n## Attendees\\n\\n## Agenda\\n\\n## Action Items\\n',
                        ),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Expanded(
                      child: _DocTemplateCard(
                        icon: Icons.track_changes_outlined,
                        accentColor: AtlasColors.accentAmber,
                        title: 'Project Roadmap',
                        description:
                            'Milestones, deliverables, and dependencies',
                        onTap: () => _createFromTemplate(
                          context,
                          ref,
                          'Project Roadmap',
                          '# Project Roadmap\\n\\n## Objectives\\n\\n## Milestones\\n\\n## Dependencies\\n',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocTemplateCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _DocTemplateCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtlasSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: isDark
                  ? AtlasColors.darkTextSecondary
                  : AtlasColors.lightTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
