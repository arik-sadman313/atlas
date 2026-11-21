import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../controllers/vault_workspace_controller.dart';

/// Vaultite Multi-Tab Bar.
///
/// Features:
/// - Horizontal scrollable tab row for typed markdown documents and vector notebooks.
/// - Active tab indicator, dirty state tracking, and tab close buttons.
/// - Split-view toggle, graph toggle, and right-hand inspector dock controls.
class VaultTabBar extends ConsumerWidget {
  final VoidCallback onNewTab;
  final VoidCallback onOpenGraph;

  const VaultTabBar({
    super.key,
    required this.onNewTab,
    required this.onOpenGraph,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceState = ref.watch(vaultWorkspaceProvider);
    final controller = ref.read(vaultWorkspaceProvider.notifier);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14161A) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF282C37) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          IconButton(
            icon: Icon(
              workspaceState.isLeftSidebarVisible
                  ? Icons.view_sidebar_rounded
                  : Icons.view_sidebar_outlined,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            tooltip: workspaceState.isLeftSidebarVisible
                ? 'Collapse Vault Explorer'
                : 'Expand Vault Explorer',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.toggleLeftSidebar(),
          ),

          // Scrollable Open Tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < workspaceState.tabs.length; i++)
                    _buildTab(
                      index: i,
                      tab: workspaceState.tabs[i],
                      isActive: i == workspaceState.activeTabIndex,
                      isDark: isDark,
                      theme: theme,
                      controller: controller,
                    ),
                  // New Tab Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: onNewTab,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Controls: Split Editor, Graph, Inspector Toggle
          if (workspaceState.tabs.length >= 2)
            IconButton(
              icon: Icon(
                workspaceState.isSplitViewActive
                    ? Icons.vertical_split_rounded
                    : Icons.vertical_split_outlined,
                size: 16,
                color: workspaceState.isSplitViewActive
                    ? AtlasColors.accentBlue
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              tooltip: workspaceState.isSplitViewActive
                  ? 'Close Split View'
                  : 'Split Editor (Side-by-Side)',
              visualDensity: VisualDensity.compact,
              onPressed: () => controller.toggleSplitView(),
            ),

          IconButton(
            icon: const Icon(Icons.hub_outlined, size: 16),
            tooltip: 'Knowledge Graph View',
            visualDensity: VisualDensity.compact,
            onPressed: onOpenGraph,
          ),

          IconButton(
            icon: Icon(
              workspaceState.isRightInspectorVisible
                  ? Icons.view_sidebar_rounded
                  : Icons.view_sidebar_outlined,
              size: 16,
              color: workspaceState.isRightInspectorVisible
                  ? AtlasColors.accentBlue
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            tooltip: workspaceState.isRightInspectorVisible
                ? 'Collapse Inspector Panel'
                : 'Expand Inspector Panel (Backlinks, Mentions, Outline)',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.toggleRightInspector(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required dynamic tab,
    required bool isActive,
    required bool isDark,
    required ThemeData theme,
    required VaultWorkspaceNotifier controller,
  }) {
    final isNotebook = tab.isNotebook;

    return Container(
      constraints: const BoxConstraints(maxWidth: 180, minWidth: 90),
      margin: const EdgeInsets.only(top: 2, right: 2),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF1E2128) : Colors.white)
            : (isDark ? const Color(0xFF16181D) : const Color(0xFFE2E8F0)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border(
          top: BorderSide(
            color: isActive ? AtlasColors.accentBlue : Colors.transparent,
            width: 2.0,
          ),
          left: BorderSide(
            color: isDark ? const Color(0xFF282C37) : const Color(0xFFCBD5E1),
            width: 0.5,
          ),
          right: BorderSide(
            color: isDark ? const Color(0xFF282C37) : const Color(0xFFCBD5E1),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        onTap: () => controller.selectTab(index),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNotebook ? Icons.draw_rounded : Icons.description_outlined,
                size: 13,
                color: isNotebook
                    ? const Color(0xFFF59E0B)
                    : (isActive
                          ? AtlasColors.accentBlue
                          : (isDark ? Colors.white60 : Colors.black54)),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  tab.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => controller.closeTab(index),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
