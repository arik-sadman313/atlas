import 'package:flutter/material.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../../domain/models/graph_models.dart';

class KnowledgeGraphPainter extends CustomPainter {
  final GraphData graph;
  final String? hoveredNodeId;
  final String? selectedNodeId;
  final String? highlightQuery;
  final bool showOrphans;
  final Set<GraphNodeType> visibleTypes;
  final bool isDark;

  const KnowledgeGraphPainter({
    required this.graph,
    this.hoveredNodeId,
    this.selectedNodeId,
    this.highlightQuery,
    this.showOrphans = true,
    required this.visibleTypes,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (graph.nodes.isEmpty) return;

    final cleanQuery = highlightQuery?.trim().toLowerCase() ?? '';
    final hasSearch = cleanQuery.isNotEmpty;

    // Filter nodes by type and orphan status
    final visibleNodeMap = <String, GraphNode>{};
    for (final node in graph.nodes.values) {
      if (!visibleTypes.contains(node.type)) continue;
      if (!showOrphans && node.degree == 0) continue;
      visibleNodeMap[node.id] = node;
    }

    // 1. Draw Edges
    final defaultEdgePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final highlightedEdgePaint = Paint()
      ..color = AtlasColors.accentBlue.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final edge in graph.edges) {
      final n1 = visibleNodeMap[edge.sourceId];
      final n2 = visibleNodeMap[edge.targetId];
      if (n1 == null || n2 == null) continue;

      final isEdgeHighlighted =
          n1.id == hoveredNodeId ||
          n2.id == hoveredNodeId ||
          n1.id == selectedNodeId ||
          n2.id == selectedNodeId;

      canvas.drawLine(
        Offset(n1.x, n1.y),
        Offset(n2.x, n2.y),
        isEdgeHighlighted ? highlightedEdgePaint : defaultEdgePaint,
      );
    }

    // 2. Draw Nodes
    for (final node in visibleNodeMap.values) {
      final isHovered = node.id == hoveredNodeId;
      final isSelected = node.id == selectedNodeId;
      final matchesSearch =
          hasSearch && node.title.toLowerCase().contains(cleanQuery);

      double opacity = 1.0;
      if (hasSearch && !matchesSearch) {
        opacity = 0.25;
      }

      final center = Offset(node.x, node.y);
      final radius = isHovered || isSelected ? node.radius + 3.0 : node.radius;

      // Glow halo for hovered, selected, or search matched node
      if (isHovered || isSelected || matchesSearch) {
        final glowPaint = Paint()
          ..color =
              (matchesSearch ? AtlasColors.accentAmber : AtlasColors.accentBlue)
                  .withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius + 5.0, glowPaint);
      }

      // Base Node Circle
      final nodePaint = Paint()
        ..color = node.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, nodePaint);

      // Node border ring
      final borderPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(
          alpha: opacity * 0.4,
        )
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, borderPaint);

      // 3. Draw Text Labels for hovered, selected, search match, or prominent nodes
      final shouldShowLabel =
          isHovered ||
          isSelected ||
          matchesSearch ||
          node.degree >= 3 ||
          visibleNodeMap.length <= 15;

      if (shouldShowLabel && opacity > 0.5) {
        final textSpan = TextSpan(
          text: node.title,
          style: TextStyle(
            color: isDark
                ? AtlasColors.darkTextPrimary
                : AtlasColors.lightTextPrimary,
            fontSize: isHovered || isSelected ? 12 : 10,
            fontWeight: isHovered || isSelected
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout(maxWidth: 160);

        tp.paint(
          canvas,
          Offset(center.dx + radius + 4, center.dy - tp.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) {
    return true; // Continuously animated during physics simulation
  }
}
