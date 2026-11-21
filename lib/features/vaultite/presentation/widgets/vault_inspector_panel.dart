import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/vaultite/vaultite_models.dart';
import '../../../../core/vaultite/vaultite_section_scanner.dart';
import '../../../graph/presentation/widgets/local_graph_panel.dart';
import '../controllers/vault_workspace_controller.dart';

/// Collapsible Right-Hand Inspector Dock.
///
/// Features:
/// 1. Backlinks: incoming references pointing to the active note with surrounding context.
/// 2. Unlinked Mentions: prose appearances of this note's title with a 1-click `[[Link]]` action.
/// 3. Outline: ATX heading tree (H1–H6).
/// 4. Local Graph: focused local knowledge network around the active note.
class VaultInspectorPanel extends ConsumerStatefulWidget {
  final String activeNodeId;
  final String activeTitle;
  final String activeBody;

  const VaultInspectorPanel({
    super.key,
    required this.activeNodeId,
    required this.activeTitle,
    required this.activeBody,
  });

  @override
  ConsumerState<VaultInspectorPanel> createState() =>
      _VaultInspectorPanelState();
}

class _VaultInspectorPanelState extends ConsumerState<VaultInspectorPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(vaultWorkspaceProvider).activeInspectorTab;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(vaultWorkspaceProvider.notifier)
            .setInspectorTab(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant VaultInspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTab = ref.read(vaultWorkspaceProvider).activeInspectorTab;
    if (_tabController.index != currentTab) {
      _tabController.index = currentTab;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vaultiteIndex = ref.watch(vaultiteIndexProvider);

    final backlinks = vaultiteIndex.getBacklinks(widget.activeNodeId);
    final mentions = vaultiteIndex.getUnlinkedMentions(widget.activeNodeId);
    final headings = VaultiteSectionScanner.scan(widget.activeBody).headings;

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181D) : const Color(0xFFF8FAFC),
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF282C37) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inspector Header & Tab Bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF282C37)
                      : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AtlasColors.accentBlue,
                    unselectedLabelColor:
                        isDark ? Colors.white54 : Colors.black54,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Links (${backlinks.length})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.find_in_page_outlined, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Mentions (${mentions.length})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Outline (${headings.length})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hub_outlined, size: 14),
                            SizedBox(width: 4),
                            Text('Graph', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  tooltip: 'Close Inspector',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref
                        .read(vaultWorkspaceProvider.notifier)
                        .toggleRightInspector();
                  },
                ),
              ],
            ),
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Backlinks
                _buildBacklinksList(backlinks, isDark),

                // 2. Unlinked Mentions
                _buildMentionsList(mentions, isDark),

                // 3. Outline Headings
                _buildOutlineList(headings, isDark),

                // 4. Local Graph View
                LocalGraphPanel(nodeId: widget.activeNodeId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacklinksList(List<VaultiteBacklink> backlinks, bool isDark) {
    if (backlinks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No incoming backlinks to this note yet.\nLink to this note using [[${widget.activeTitle}]]',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: backlinks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final bl = backlinks[index];
        final isNotebook = bl.sourceKind == VaultiteKind.notebook;

        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            ref.read(vaultWorkspaceProvider.notifier).openNode(
              id: bl.sourceNodeId,
              title: bl.sourceTitle,
              type: isNotebook ? 'notebook' : 'document',
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E222A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF282C37)
                    : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isNotebook ? Icons.draw_rounded : Icons.description_outlined,
                      size: 13,
                      color: isNotebook ? const Color(0xFFF59E0B) : AtlasColors.accentBlue,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        bl.sourceTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bl.isEmbed)
                      const Text(
                        'embed',
                        style: TextStyle(fontSize: 10, color: Colors.purpleAccent),
                      ),
                  ],
                ),
                if (bl.contextLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bl.contextLine,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMentionsList(List<VaultiteMention> mentions, bool isDark) {
    if (mentions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No unlinked mentions found across your vault.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: mentions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final m = mentions[index];
        final isNotebook = m.sourceKind == VaultiteKind.notebook;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E222A)
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF282C37)
                  : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isNotebook ? Icons.draw_rounded : Icons.description_outlined,
                    size: 13,
                    color: isNotebook ? const Color(0xFFF59E0B) : AtlasColors.accentBlue,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      m.sourceTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      ref.read(vaultWorkspaceProvider.notifier).openNode(
                        id: m.sourceNodeId,
                        title: m.sourceTitle,
                        type: isNotebook ? 'notebook' : 'document',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AtlasColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Open & Link',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AtlasColors.accentBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                m.contextLine,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutlineList(List<VaultiteHeading> headings, bool isDark) {
    if (headings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No headings found in this note.\nAdd ATX headings like # Heading or ## Section',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: headings.length,
      itemBuilder: (context, index) {
        final h = headings[index];
        final indent = (h.level - 1) * 12.0;

        return Padding(
          padding: EdgeInsets.only(left: indent, bottom: 4),
          child: Row(
            children: [
              Text(
                'H${h.level}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: h.level == 1 ? AtlasColors.accentBlue : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  h.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: h.level <= 2 ? FontWeight.w600 : FontWeight.w400,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
