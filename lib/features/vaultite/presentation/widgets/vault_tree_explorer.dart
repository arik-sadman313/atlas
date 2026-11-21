import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../controllers/vault_workspace_controller.dart';

/// Vault File & Folder Tree Explorer.
///
/// Provides an Obsidian/Vaultite-standard file tree with collapsible folders,
/// pinned notes, quick search filter, and dual document/handwriting creation.
class VaultTreeExplorer extends ConsumerStatefulWidget {
  final VoidCallback onNewDocument;
  final VoidCallback onNewNotebook;

  const VaultTreeExplorer({
    super.key,
    required this.onNewDocument,
    required this.onNewNotebook,
  });

  @override
  ConsumerState<VaultTreeExplorer> createState() => _VaultTreeExplorerState();
}

class _VaultTreeExplorerState extends ConsumerState<VaultTreeExplorer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _collapsedFolders = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFolder(String folderName) {
    setState(() {
      if (_collapsedFolders.contains(folderName)) {
        _collapsedFolders.remove(folderName);
      } else {
        _collapsedFolders.add(folderName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final nodesDao = ref.watch(nodesDaoProvider);
    final workspaceState = ref.watch(vaultWorkspaceProvider);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181D) : const Color(0xFFF8FAFC),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF282C37) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Vault Header & Top Action Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: AtlasColors.accentBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'VAULT',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'New Markdown Note',
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onNewDocument,
                ),
                IconButton(
                  tooltip: 'New Vector Notebook',
                  icon: const Icon(Icons.draw_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  color: const Color(0xFFF59E0B),
                  onPressed: widget.onNewNotebook,
                ),
              ],
            ),
          ),

          // 2. Search Filter Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Filter files in vault...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E222B)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 3. Tree List (Pinned & Folders)
          Expanded(
            child: StreamBuilder<List<NodeEntry>>(
              stream: nodesDao.watchNodesInWorkspace(workspaceId),
              builder: (context, snapshot) {
                final allNodes = snapshot.data ?? [];
                final nodes = allNodes.where((n) {
                  if (n.isDeleted || n.deletedAt != null) return false;
                  if (n.type != 'document' && n.type != 'notebook') return false;
                  if (_searchQuery.isNotEmpty) {
                    return n.title.toLowerCase().contains(_searchQuery);
                  }
                  return true;
                }).toList();

                final pinned = nodes.where((n) => n.isFavorite).toList();
                final documents = nodes
                    .where((n) => n.type == 'document')
                    .toList();
                final notebooks = nodes
                    .where((n) => n.type == 'notebook')
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  children: [
                    // Pinned Section
                    if (pinned.isNotEmpty) ...[
                      _buildSectionHeader('PINNED', isDark),
                      for (final node in pinned)
                        _buildFileItem(
                          node: node,
                          isActive:
                              workspaceState.activeTab?.nodeId == node.id,
                          isDark: isDark,
                        ),
                      const SizedBox(height: 8),
                    ],

                    // Folders
                    _buildFolderItem(
                      folderName: 'Notes & Markdown',
                      icon: Icons.folder_outlined,
                      items: documents,
                      isDark: isDark,
                      activeNodeId: workspaceState.activeTab?.nodeId,
                    ),
                    const SizedBox(height: 4),

                    _buildFolderItem(
                      folderName: 'Handwriting & Canvases',
                      icon: Icons.folder_special_outlined,
                      folderColor: const Color(0xFFF59E0B),
                      items: notebooks,
                      isDark: isDark,
                      activeNodeId: workspaceState.activeTab?.nodeId,
                    ),
                  ],
                );
              },
            ),
          ),

          // 4. Vault Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF282C37)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.dns_outlined,
                  size: 14,
                  color: AtlasColors.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Local Vault',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Obsidian Mode',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildFolderItem({
    required String folderName,
    required IconData icon,
    Color? folderColor,
    required List<NodeEntry> items,
    required bool isDark,
    required String? activeNodeId,
  }) {
    final isCollapsed = _collapsedFolders.contains(folderName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _toggleFolder(folderName),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 15,
                  color: folderColor ??
                      (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    folderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Column(
              children: items.map((node) {
                return _buildFileItem(
                  node: node,
                  isActive: activeNodeId == node.id,
                  isDark: isDark,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFileItem({
    required NodeEntry node,
    required bool isActive,
    required bool isDark,
  }) {
    final isNotebook = node.type == 'notebook';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                  ? AtlasColors.accentBlue.withValues(alpha: 0.18)
                  : AtlasColors.accentBlue.withValues(alpha: 0.12))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          ref
              .read(vaultWorkspaceProvider.notifier)
              .openNode(id: node.id, title: node.title, type: node.type);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Icon(
                isNotebook ? Icons.draw_rounded : Icons.description_outlined,
                size: 14,
                color: isNotebook
                    ? const Color(0xFFF59E0B)
                    : (isActive
                          ? AtlasColors.accentBlue
                          : (isDark ? Colors.white60 : Colors.black54)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  node.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (node.isFavorite)
                const Icon(Icons.star, size: 12, color: AtlasColors.accentAmber),
            ],
          ),
        ),
      ),
    );
  }
}
