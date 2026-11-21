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

/// Unified Vault & Notes Explorer.
///
/// Integrates Vaultite/Obsidian-compatible typed documents and vector handwriting
/// notebooks into a single cohesive knowledge vault.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _activeFilter = 'all'; // 'all', 'document', 'notebook', 'favorites'

  void _showCreateDocumentDialog(BuildContext context) {
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
            onSubmitted: (val) =>
                _createAndOpenDocument(dialogCtx, context, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createAndOpenDocument(
                dialogCtx,
                context,
                titleController.text,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateNotebookDialog(BuildContext context) {
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
          title: Text('New Notebook', style: theme.textTheme.headlineMedium),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Notebook Title',
              hintText: 'e.g. Sketches, Math Lecture Notes',
            ),
            onSubmitted: (val) =>
                _createAndOpenNotebook(dialogCtx, context, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _createAndOpenNotebook(
                dialogCtx,
                context,
                titleController.text,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAndOpenDocument(
    BuildContext dialogCtx,
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

  Future<void> _createAndOpenNotebook(
    BuildContext dialogCtx,
    BuildContext screenCtx,
    String title,
  ) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'nb_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: 'notebook',
        title: clean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
    }

    if (screenCtx.mounted) {
      screenCtx.go('/notebooks/$newId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final nodesDao = ref.watch(nodesDaoProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: StreamBuilder<List<NodeEntry>>(
          stream: nodesDao.watchNodesInWorkspace(workspaceId),
          builder: (context, snapshot) {
            final allNodes = snapshot.data ?? [];
            final docs = allNodes.where((n) {
              if (n.type != 'document' && n.type != 'notebook') return false;
              switch (_activeFilter) {
                case 'document':
                  return n.type == 'document';
                case 'notebook':
                  return n.type == 'notebook';
                case 'favorites':
                  return n.isFavorite;
                default:
                  return true;
              }
            }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.xl),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;
                        final titleColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Documents & Vault',
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: AtlasSpacing.xs),
                            Text(
                              'Obsidian-compatible Markdown notes, vector notebooks, and knowledge graph',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        );

                        final actionButtons = Wrap(
                          spacing: AtlasSpacing.sm,
                          runSpacing: AtlasSpacing.sm,
                          children: [
                            AtlasButton.primary(
                              label: 'New Document',
                              icon: Icons.add,
                              onPressed: () =>
                                  _showCreateDocumentDialog(context),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showCreateNotebookDialog(context),
                              icon: const Icon(Icons.draw_rounded, size: 18),
                              label: const Text('New Notebook'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark
                                      ? AtlasColors.darkBorder
                                      : AtlasColors.lightBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AtlasSpacing.radiusSm,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AtlasSpacing.md,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isNarrow) ...[
                              titleColumn,
                              const SizedBox(height: AtlasSpacing.md),
                              actionButtons,
                            ] else ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: titleColumn),
                                  const SizedBox(width: AtlasSpacing.md),
                                  actionButtons,
                                ],
                              ),
                            ],
                            const SizedBox(height: AtlasSpacing.lg),
                            // Filter Segment Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip(
                                    label: 'All Notes',
                                    value: 'all',
                                    icon: Icons.folder_open_rounded,
                                    count: allNodes
                                        .where(
                                          (n) =>
                                              n.type == 'document' ||
                                              n.type == 'notebook',
                                        )
                                        .length,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: 'Documents',
                                    value: 'document',
                                    icon: Icons.article_outlined,
                                    count: allNodes
                                        .where((n) => n.type == 'document')
                                        .length,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: 'Handwriting',
                                    value: 'notebook',
                                    icon: Icons.draw_rounded,
                                    count: allNodes
                                        .where((n) => n.type == 'notebook')
                                        .length,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    label: 'Starred',
                                    value: 'favorites',
                                    icon: Icons.star_rounded,
                                    count: allNodes
                                        .where(
                                          (n) =>
                                              (n.type == 'document' ||
                                                  n.type == 'notebook') &&
                                              n.isFavorite,
                                        )
                                        .length,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (docs.isEmpty)
                  _buildStarterScreen(context, theme, isDark)
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
                        final isNotebook = doc.type == 'notebook';

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AtlasSpacing.sm,
                          ),
                          child: AtlasCard(
                            onTap: () {
                              if (isNotebook) {
                                context.go('/notebooks/${doc.id}');
                              } else {
                                context.go('/documents/${doc.id}');
                              }
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color:
                                        (isNotebook
                                                ? const Color(0xFFF59E0B)
                                                : AtlasColors.accentBlue)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AtlasSpacing.radiusSm,
                                    ),
                                  ),
                                  child: Icon(
                                    isNotebook
                                        ? Icons.draw_rounded
                                        : Icons.article_outlined,
                                    size: 20,
                                    color: isNotebook
                                        ? const Color(0xFFF59E0B)
                                        : AtlasColors.accentBlue,
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
                                              color:
                                                  (isNotebook
                                                          ? const Color(
                                                              0xFFF59E0B,
                                                            )
                                                          : AtlasColors
                                                                .accentBlue)
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isNotebook
                                                  ? 'Handwriting'
                                                  : 'Document',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isNotebook
                                                    ? const Color(0xFFD97706)
                                                    : AtlasColors.accentBlue,
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

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required int count,
    required bool isDark,
  }) {
    final isSelected = _activeFilter == value;
    final primaryColor = isSelected
        ? AtlasColors.accentBlue
        : (isDark
              ? AtlasColors.darkTextSecondary
              : AtlasColors.lightTextSecondary);

    return FilterChip(
      selected: isSelected,
      avatar: Icon(icon, size: 16, color: primaryColor),
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected
            ? (isDark ? Colors.white : Colors.black87)
            : primaryColor,
      ),
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      selectedColor: AtlasColors.accentBlue.withValues(alpha: 0.18),
      side: BorderSide(
        color: isSelected
            ? AtlasColors.accentBlue
            : (isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
      ),
      onSelected: (_) {
        setState(() => _activeFilter = value);
      },
    );
  }

  Future<void> _createFromTemplate(
    BuildContext context,
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
                // Dual Creation Cards
                Row(
                  children: [
                    Expanded(
                      child: AtlasCard(
                        onTap: () => _showCreateDocumentDialog(context),
                        padding: const EdgeInsets.all(AtlasSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AtlasColors.accentBlue.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.article_outlined,
                                size: 24,
                                color: AtlasColors.accentBlue,
                              ),
                            ),
                            const SizedBox(height: AtlasSpacing.md),
                            Text(
                              'Create Markdown Document',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rich text, [[wiki-links]], code blocks, frontmatter properties, and backlinks.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Expanded(
                      child: AtlasCard(
                        onTap: () => _showCreateNotebookDialog(context),
                        padding: const EdgeInsets.all(AtlasSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.draw_rounded,
                                size: 24,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(height: AtlasSpacing.md),
                            Text(
                              'Create Vector Notebook',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vector handwriting, Apple Pencil pressure/tilt, sticky notes with [[WikiLinks]], Excalidraw.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
