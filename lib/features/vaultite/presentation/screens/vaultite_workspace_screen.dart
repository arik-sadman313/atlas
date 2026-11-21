import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../documents/presentation/document_editor_screen.dart';
import '../../../handwriting/presentation/screens/notebook_editor_screen.dart';
import '../controllers/vault_workspace_controller.dart';
import '../widgets/vault_inspector_panel.dart';
import '../widgets/vault_status_bar.dart';
import '../widgets/vault_tab_bar.dart';
import '../widgets/vault_tree_explorer.dart';

/// Master Vaultite Workspace Screen.
///
/// Integrates the Vaultite / Obsidian-style multi-tab workspace, collapsible file tree explorer,
/// vector handwriting notebooks, typed markdown documents, collapsible frontmatter properties,
/// 4-tab right inspector dock (backlinks, unlinked mentions, outline, local graph), split view,
/// and live status bar into a single cohesive core.
class VaultiteWorkspaceScreen extends ConsumerStatefulWidget {
  final String? initialNodeId;

  const VaultiteWorkspaceScreen({super.key, this.initialNodeId});

  @override
  ConsumerState<VaultiteWorkspaceScreen> createState() =>
      _VaultiteWorkspaceScreenState();
}

class _VaultiteWorkspaceScreenState
    extends ConsumerState<VaultiteWorkspaceScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoOpenDefaultTab();
    });
  }

  Future<void> _autoOpenDefaultTab() async {
    if (_initialized) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);

    final initialId = widget.initialNodeId;
    if (initialId != null && initialId.isNotEmpty) {
      final node = await nodesDao.getNode(initialId);
      if (node != null && mounted) {
        ref.read(vaultWorkspaceProvider.notifier).openNode(
              id: node.id,
              title: node.title,
              type: node.type,
            );
        _initialized = true;
        return;
      }
    }

    final workspaceState = ref.read(vaultWorkspaceProvider);
    if (workspaceState.tabs.isNotEmpty) {
      _initialized = true;
      return;
    }

    final allNodes = await nodesDao.getAllNodes(workspaceId);

    if (!mounted) return;

    if (allNodes.isNotEmpty) {
      // Prioritize the most recently updated note
      final sorted = List<NodeEntry>.from(allNodes)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final first = sorted.first;

      ref.read(vaultWorkspaceProvider.notifier).openNode(
            id: first.id,
            title: first.title,
            type: first.type,
          );
    }
    _initialized = true;
  }

  void _showCreateDocumentDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor:
              isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
            side: BorderSide(
              color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
              width: 1.0,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AtlasColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'New Markdown Note',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Note Title',
              hintText: 'e.g. Architecture Decisions, Meeting Notes',
            ),
            onSubmitted: (val) => _createAndOpenDocument(dialogCtx, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  _createAndOpenDocument(dialogCtx, titleController.text),
              child: const Text('Create Note'),
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
          backgroundColor:
              isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
            side: BorderSide(
              color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
              width: 1.0,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.draw_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'New Vector Handwriting Notebook',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Notebook Title',
              hintText: 'e.g. Sketches, Math Lecture, Apple Pencil Draft',
            ),
            onSubmitted: (val) => _createAndOpenNotebook(dialogCtx, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  _createAndOpenNotebook(dialogCtx, titleController.text),
              child: const Text('Create Notebook'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createAndOpenDocument(
      BuildContext dialogCtx, String title) async {
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

    // Initial paragraph block
    await nodesDao.createBlock(
      NodeBlocksCompanion.insert(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}',
        nodeId: newId,
        type: 'paragraph',
        contentJson: const Value('{"text": "Start typing..."}'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
    }

    ref.read(vaultWorkspaceProvider.notifier).openNode(
          id: newId,
          title: clean,
          type: 'document',
        );
  }

  Future<void> _createAndOpenNotebook(
      BuildContext dialogCtx, String title) async {
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

    ref.read(vaultWorkspaceProvider.notifier).openNode(
          id: newId,
          title: clean,
          type: 'notebook',
        );
  }

  Widget _buildBreadcrumbs(
    BuildContext context,
    String title,
    bool isNotebook,
    bool isDark,
  ) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14161A) : const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF232730) : const Color(0xFFEEEEEE),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 13,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
          const SizedBox(width: 5),
          Text(
            'Atlas Vault',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '›',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isNotebook ? 'Handwriting & Canvases' : 'Notes & Markdown',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '›',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isNotebook ? Icons.gesture_rounded : Icons.article_outlined,
            size: 12,
            color: isNotebook ? const Color(0xFF10B981) : AtlasColors.accentBlue,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$title${isNotebook ? ".notebook" : ".md"}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPane({
    required BuildContext context,
    required String nodeId,
    required String title,
    required bool isNotebook,
    required bool isDark,
  }) {
    return Column(
      children: [
        _buildBreadcrumbs(context, title, isNotebook, isDark),
        Expanded(
          child: isNotebook
              ? NotebookEditorScreen(
                  key: ValueKey('notebook_$nodeId'),
                  notebookId: nodeId,
                  embedded: true,
                )
              : DocumentEditorScreen(
                  key: ValueKey('document_$nodeId'),
                  documentId: nodeId,
                  embedded: true,
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyVaultView(ThemeData theme, bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AtlasColors.accentBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  size: 38,
                  color: AtlasColors.accentBlue,
                ),
              ),
              const SizedBox(height: AtlasSpacing.lg),
              Text(
                'Welcome to Atlas Vault',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AtlasSpacing.sm),
              Text(
                'Vaultite & Obsidian-compatible personal knowledge base with unified Markdown notes, vector handwriting canvases, and bidirectional wiki-links.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AtlasSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('New Note'),
                    onPressed: () => _showCreateDocumentDialog(context),
                  ),
                  const SizedBox(width: AtlasSpacing.md),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.draw_outlined, size: 18),
                    label: const Text('New Notebook'),
                    onPressed: () => _showCreateNotebookDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: AtlasSpacing.md),
              TextButton.icon(
                icon: const Icon(Icons.hub_outlined, size: 16),
                label: const Text('Open Knowledge Graph'),
                onPressed: () => context.go('/graph'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceState = ref.watch(vaultWorkspaceProvider);

    final activeTab = workspaceState.activeTab;
    final secondaryTab = workspaceState.secondaryTab;
    final isSplit = workspaceState.isSplitViewActive && secondaryTab != null;

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Multi-Tab Bar
            VaultTabBar(
              onNewTab: () => _showCreateDocumentDialog(context),
              onOpenGraph: () => context.go('/graph'),
            ),

            // Main Horizontal Body: Tree Explorer | Center Editor(s) | Inspector
            Expanded(
              child: Row(
                children: [
                  // Collapsible Left File Tree Explorer
                  if (workspaceState.isLeftSidebarVisible)
                    VaultTreeExplorer(
                      onNewDocument: () => _showCreateDocumentDialog(context),
                      onNewNotebook: () => _showCreateNotebookDialog(context),
                    ),

                  // Center Editor Surface
                  Expanded(
                    child: activeTab == null
                        ? _buildEmptyVaultView(theme, isDark)
                        : isSplit
                            ? Row(
                                children: [
                                  // Left / Primary Pane
                                  Expanded(
                                    child: _buildEditorPane(
                                      context: context,
                                      nodeId: activeTab.nodeId,
                                      title: activeTab.title,
                                      isNotebook: activeTab.isNotebook,
                                      isDark: isDark,
                                    ),
                                  ),
                                  // Split Vertical Divider
                                  Container(
                                    width: 1.0,
                                    color: isDark
                                        ? const Color(0xFF282C37)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  // Right / Secondary Pane
                                  Expanded(
                                    child: _buildEditorPane(
                                      context: context,
                                      nodeId: secondaryTab.nodeId,
                                      title: secondaryTab.title,
                                      isNotebook: secondaryTab.isNotebook,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              )
                            : _buildEditorPane(
                                context: context,
                                nodeId: activeTab.nodeId,
                                title: activeTab.title,
                                isNotebook: activeTab.isNotebook,
                                isDark: isDark,
                              ),
                  ),

                  // Collapsible Right Inspector Dock
                  if (workspaceState.isRightInspectorVisible &&
                      activeTab != null) ...[
                    Container(
                      width: 1.0,
                      color: isDark
                          ? const Color(0xFF282C37)
                          : const Color(0xFFE2E8F0),
                    ),
                    VaultInspectorPanel(
                      activeNodeId: activeTab.nodeId,
                      activeTitle: activeTab.title,
                      activeBody: '',
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Status Bar
            VaultStatusBar(
              path: activeTab != null
                  ? 'Atlas Vault / ${activeTab.path}'
                  : 'Atlas Vault',
              wordCount: 0,
              charCount: 0,
              kind: activeTab?.isNotebook == true ? 'notebook' : 'note',
              isSaving: false,
            ),
          ],
        ),
      ),
    );
  }
}
