import 'dart:math' as math;

import '../../../../core/database/daos/links_dao.dart';
import '../../../../core/database/daos/nodes_dao.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../domain/models/graph_models.dart';

class GraphRepository {
  final NodesDao nodesDao;
  final LinksDao linksDao;

  GraphRepository({required this.nodesDao, required this.linksDao});

  /// Loads the complete graph topology for a workspace.
  Future<GraphData> loadWorkspaceGraph(
    String workspaceId, {
    bool includeTags = true,
  }) async {
    final nodes = await nodesDao.getAllNodes(workspaceId);
    final links = await linksDao.getAllLinksForWorkspace(workspaceId);

    // Compute node degrees (in-degree + out-degree)
    final inDegree = <String, int>{};
    final outDegree = <String, int>{};

    for (final l in links) {
      outDegree[l.sourceNodeId] = (outDegree[l.sourceNodeId] ?? 0) + 1;
      inDegree[l.targetNodeId] = (inDegree[l.targetNodeId] ?? 0) + 1;
    }

    final graphNodes = <String, GraphNode>{};
    for (final n in nodes) {
      final totalDegree = (outDegree[n.id] ?? 0) + (inDegree[n.id] ?? 0);
      final isNotebook = n.type == 'notebook';
      final radius = (4.0 + math.sqrt(totalDegree) * 2.5).clamp(4.0, 16.0);
      final color = isNotebook
          ? AtlasColors.accentSage
          : AtlasColors.accentBlue;

      graphNodes[n.id] = GraphNode(
        id: n.id,
        title: n.title,
        type: isNotebook ? GraphNodeType.notebook : GraphNodeType.document,
        degree: totalDegree,
        radius: radius,
        color: color,
      );
    }

    final graphEdges = <GraphEdge>[];
    for (final l in links) {
      if (graphNodes.containsKey(l.sourceNodeId) &&
          graphNodes.containsKey(l.targetNodeId)) {
        graphEdges.add(
          GraphEdge(
            sourceId: l.sourceNodeId,
            targetId: l.targetNodeId,
            weight: 1.0,
          ),
        );
      }
    }

    // Include tag nodes & associations if enabled
    if (includeTags) {
      final tags = await linksDao.getAllTagsForWorkspace(workspaceId);
      final nodeTags = await linksDao.getAllNodeTagsForWorkspace(workspaceId);

      final tagCounts = <String, int>{};
      for (final nt in nodeTags) {
        tagCounts[nt.tagId] = (tagCounts[nt.tagId] ?? 0) + 1;
      }

      for (final tag in tags) {
        final count = tagCounts[tag.id] ?? 0;
        final tagNodeId = 'tag_${tag.id}';
        final radius = (4.0 + math.sqrt(count) * 2.0).clamp(4.0, 14.0);

        graphNodes[tagNodeId] = GraphNode(
          id: tagNodeId,
          title: '#${tag.name}',
          type: GraphNodeType.tag,
          degree: count,
          radius: radius,
          color: AtlasColors.accentAmber,
        );

        for (final nt in nodeTags.where((entry) => entry.tagId == tag.id)) {
          if (graphNodes.containsKey(nt.nodeId)) {
            graphEdges.add(
              GraphEdge(sourceId: nt.nodeId, targetId: tagNodeId, weight: 0.8),
            );
          }
        }
      }
    }

    return GraphData(nodes: graphNodes, edges: graphEdges);
  }

  /// Extracts the local neighborhood subgraph centered on [targetNodeId] up to [depth] hops.
  static GraphData extractNeighborhood(
    GraphData fullGraph,
    String targetNodeId, {
    int depth = 1,
  }) {
    if (!fullGraph.nodes.containsKey(targetNodeId)) {
      return const GraphData(nodes: {}, edges: []);
    }

    final visitedNodes = <String>{targetNodeId};
    var currentFrontier = <String>{targetNodeId};

    for (int d = 0; d < depth; d++) {
      final nextFrontier = <String>{};
      for (final currentId in currentFrontier) {
        for (final edge in fullGraph.edges) {
          if (edge.sourceId == currentId &&
              !visitedNodes.contains(edge.targetId)) {
            nextFrontier.add(edge.targetId);
            visitedNodes.add(edge.targetId);
          } else if (edge.targetId == currentId &&
              !visitedNodes.contains(edge.sourceId)) {
            nextFrontier.add(edge.sourceId);
            visitedNodes.add(edge.sourceId);
          }
        }
      }
      currentFrontier = nextFrontier;
    }

    final subNodes = <String, GraphNode>{};
    for (final id in visitedNodes) {
      final node = fullGraph.nodes[id];
      if (node != null) {
        subNodes[id] = node.copyWith();
      }
    }

    final subEdges = fullGraph.edges.where((e) {
      return visitedNodes.contains(e.sourceId) &&
          visitedNodes.contains(e.targetId);
    }).toList();

    return GraphData(nodes: subNodes, edges: subEdges);
  }
}
