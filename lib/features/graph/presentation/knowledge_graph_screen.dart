import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../domain/models/graph_models.dart';
import 'widgets/interactive_knowledge_graph.dart';

class KnowledgeGraphScreen extends ConsumerStatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  ConsumerState<KnowledgeGraphScreen> createState() =>
      _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends ConsumerState<KnowledgeGraphScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showOrphans = true;
  final Set<GraphNodeType> _visibleTypes = {
    GraphNodeType.document,
    GraphNodeType.notebook,
    GraphNodeType.tag,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNodeTapped(GraphNode node) {
    if (node.type == GraphNodeType.document) {
      context.go('/documents/${node.id}');
    } else if (node.type == GraphNodeType.notebook) {
      context.go('/notebooks/${node.id}');
    } else if (node.type == GraphNodeType.tag) {
      setState(() {
        _searchController.text = node.title.replaceAll('#', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final graphAsync = ref.watch(workspaceGraphProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: Stack(
        children: [
          // 0. Dotted Canvas Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: DottedGraphCanvasPainter(
                dotColor: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
              ),
            ),
          ),

          // 1. Graph Canvas
          graphAsync.when(
            data: (graphData) {
              if (graphData.nodes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hub_outlined,
                        size: 48,
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                      ),
                      const SizedBox(height: AtlasSpacing.md),
                      Text(
                        'Knowledge Graph is Empty',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AtlasSpacing.xs),
                      Text(
                        'Create documents and use [[Wiki-Links]] to connect ideas.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AtlasColors.darkTextSecondary
                              : AtlasColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  InteractiveKnowledgeGraph(
                    graph: graphData,
                    onNodeTap: _onNodeTapped,
                    highlightQuery: _searchController.text,
                    showOrphans: _showOrphans,
                    visibleTypes: _visibleTypes,
                  ),
                  // Floating contextual hint card when only 1 node exists
                  if (graphData.nodes.length == 1)
                    Positioned(
                      bottom: AtlasSpacing.xl,
                      right: AtlasSpacing.xl,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 360),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AtlasColors.darkCard
                                      : AtlasColors.lightSurface)
                                  .withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(
                            AtlasSpacing.radiusCard,
                          ),
                          border: Border.all(
                            color: isDark
                                ? AtlasColors.darkBorder
                                : AtlasColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AtlasColors.accentBlue.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.hub_outlined,
                                size: 18,
                                color: AtlasColors.accentBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Build Your Network',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Connect notes together using [[Note Title]] to build your knowledge network.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AtlasColors.darkTextSecondary
                                          : AtlasColors.lightTextSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, _) => Center(child: Text('Error loading graph: $err')),
          ),

          // 2. Floating Filter & Control Bar (Quiet Craft Floating Capsule)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(AtlasSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpacing.md,
                  vertical: AtlasSpacing.xs,
                ),
                constraints: const BoxConstraints(maxWidth: 860),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AtlasColors.darkSurface
                              : AtlasColors.lightSurface)
                          .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AtlasSpacing.radiusXl),
                  border: Border.all(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Search Filter Field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Filter nodes...',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.sm),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark
                          ? AtlasColors.darkBorder
                          : AtlasColors.lightBorder,
                    ),
                    const SizedBox(width: AtlasSpacing.sm),

                    // Filter Types Toggle Buttons
                    _TypeToggleChip(
                      label: 'Docs',
                      color: AtlasColors.accentBlue,
                      isActive: _visibleTypes.contains(GraphNodeType.document),
                      onToggle: () {
                        setState(() {
                          if (_visibleTypes.contains(GraphNodeType.document)) {
                            _visibleTypes.remove(GraphNodeType.document);
                          } else {
                            _visibleTypes.add(GraphNodeType.document);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: AtlasSpacing.xs),
                    _TypeToggleChip(
                      label: 'Notebooks',
                      color: AtlasColors.accentSage,
                      isActive: _visibleTypes.contains(GraphNodeType.notebook),
                      onToggle: () {
                        setState(() {
                          if (_visibleTypes.contains(GraphNodeType.notebook)) {
                            _visibleTypes.remove(GraphNodeType.notebook);
                          } else {
                            _visibleTypes.add(GraphNodeType.notebook);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: AtlasSpacing.xs),
                    _TypeToggleChip(
                      label: 'Tags',
                      color: AtlasColors.accentAmber,
                      isActive: _visibleTypes.contains(GraphNodeType.tag),
                      onToggle: () {
                        setState(() {
                          if (_visibleTypes.contains(GraphNodeType.tag)) {
                            _visibleTypes.remove(GraphNodeType.tag);
                          } else {
                            _visibleTypes.add(GraphNodeType.tag);
                          }
                        });
                      },
                    ),

                    const SizedBox(width: AtlasSpacing.sm),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark
                          ? AtlasColors.darkBorder
                          : AtlasColors.lightBorder,
                    ),
                    const SizedBox(width: AtlasSpacing.sm),

                    // Show Orphans Toggle
                    Tooltip(
                      message: _showOrphans
                          ? 'Hide orphan nodes'
                          : 'Show orphan nodes',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        onTap: () {
                          setState(() {
                            _showOrphans = !_showOrphans;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _showOrphans
                                ? AtlasColors.accentBlue.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AtlasSpacing.radiusSm,
                            ),
                          ),
                          child: Icon(
                            _showOrphans
                                ? Icons.scatter_plot
                                : Icons.scatter_plot_outlined,
                            size: 18,
                            color: _showOrphans
                                ? AtlasColors.accentBlue
                                : (isDark
                                      ? AtlasColors.darkTextSecondary
                                      : AtlasColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AtlasSpacing.sm),
                    Container(
                      width: 1,
                      height: 24,
                      color: isDark
                          ? AtlasColors.darkBorder
                          : AtlasColors.lightBorder,
                    ),
                    const SizedBox(width: AtlasSpacing.xs),

                    // Zoom Controls
                    Tooltip(
                      message: 'Fit to View',
                      child: IconButton(
                        icon: const Icon(Icons.crop_free, size: 16),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedGraphCanvasPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  DottedGraphCanvasPainter({required this.dotColor, this.spacing = 28.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.85, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedGraphCanvasPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor || oldDelegate.spacing != spacing;
}

class _TypeToggleChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onToggle;

  const _TypeToggleChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? color : color.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
