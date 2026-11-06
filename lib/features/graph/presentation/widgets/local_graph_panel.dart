import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../../shared/widgets/atlas_card.dart';
import '../../data/repositories/graph_repository.dart';
import '../../domain/models/graph_models.dart';
import 'interactive_knowledge_graph.dart';

class LocalGraphPanel extends ConsumerStatefulWidget {
  final String nodeId;
  final bool initialExpanded;

  const LocalGraphPanel({
    super.key,
    required this.nodeId,
    this.initialExpanded = true,
  });

  @override
  ConsumerState<LocalGraphPanel> createState() => _LocalGraphPanelState();
}

class _LocalGraphPanelState extends ConsumerState<LocalGraphPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  void _onNodeTap(GraphNode node) {
    if (node.id == widget.nodeId) return; // Already on this node
    if (node.type == GraphNodeType.document) {
      context.push('/documents/${node.id}');
    } else if (node.type == GraphNodeType.notebook) {
      context.push('/notebooks/${node.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final graphAsync = ref.watch(workspaceGraphProvider);

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          InkWell(
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 18,
                      color: AtlasColors.accentBlue,
                    ),
                    const SizedBox(width: AtlasSpacing.sm),
                    Text(
                      'Local Knowledge Graph (1-Hop)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AtlasColors.darkTextPrimary
                            : AtlasColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ],
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: AtlasSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AtlasSpacing.sm),

            graphAsync.when(
              data: (fullGraph) {
                final localGraph = GraphRepository.extractNeighborhood(
                  fullGraph,
                  widget.nodeId,
                  depth: 1,
                );

                if (localGraph.nodes.length <= 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AtlasSpacing.md,
                    ),
                    child: Text(
                      'No connections yet. Insert [[Wiki-Links]] to link this note with other pages.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AtlasColors.darkTextTertiary
                            : AtlasColors.lightTextTertiary,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 240,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AtlasColors.darkBg
                            : AtlasColors.lightBg,
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AtlasColors.darkBorderSubtle
                              : AtlasColors.lightBorderSubtle,
                        ),
                      ),
                      child: InteractiveKnowledgeGraph(
                        graph: localGraph,
                        onNodeTap: _onNodeTap,
                        canvasSize: const Size(800, 600),
                        showOrphans: true,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AtlasSpacing.sm),
                child: Text('Error loading graph: $err'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
