import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/core/theme/atlas_colors.dart';
import 'package:atlas/features/graph/data/repositories/graph_repository.dart';
import 'package:atlas/features/graph/domain/models/graph_models.dart';
import 'package:atlas/features/graph/domain/services/force_directed_layout_service.dart';

void main() {
  group('ForceDirectedLayoutService Physics', () {
    const layoutService = ForceDirectedLayoutService(
      repulsionForce: 1000.0,
      springLength: 50.0,
      springStiffness: 0.1,
      centerGravity: 0.01,
      damping: 0.8,
    );

    const bounds = Size(800, 600);
    const center = Offset(400, 300);

    test('initializePositions assigns finite non-overlapping coordinates', () {
      final nodeA = GraphNode(
        id: 'A',
        title: 'Node A',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
      );
      final nodeB = GraphNode(
        id: 'B',
        title: 'Node B',
        type: GraphNodeType.notebook,
        color: AtlasColors.accentSage,
      );
      final nodeC = GraphNode(
        id: 'C',
        title: 'Node C',
        type: GraphNodeType.tag,
        color: AtlasColors.accentAmber,
      );

      final graph = GraphData(
        nodes: {'A': nodeA, 'B': nodeB, 'C': nodeC},
        edges: const [
          GraphEdge(sourceId: 'A', targetId: 'B'),
          GraphEdge(sourceId: 'B', targetId: 'C'),
        ],
      );

      layoutService.initializePositions(graph, bounds: bounds, center: center);

      for (final n in graph.nodes.values) {
        expect(n.x.isFinite, isTrue);
        expect(n.y.isFinite, isTrue);
        expect(n.x.isNaN, isFalse);
        expect(n.y.isNaN, isFalse);
        expect(n.x, inInclusiveRange(0.0, bounds.width));
        expect(n.y, inInclusiveRange(0.0, bounds.height));
      }

      // Check distinct coordinates
      expect(nodeA.x != nodeB.x || nodeA.y != nodeB.y, isTrue);
      expect(nodeB.x != nodeC.x || nodeB.y != nodeC.y, isTrue);
    });

    test('step simulation repels close unconnected nodes', () {
      final node1 = GraphNode(
        id: '1',
        title: 'Node 1',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
        x: 400.0,
        y: 300.0,
      );
      final node2 = GraphNode(
        id: '2',
        title: 'Node 2',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
        x: 405.0,
        y: 300.0,
      );

      final graph = GraphData(nodes: {'1': node1, '2': node2}, edges: const []);

      final initialDistance = (node1.x - node2.x).abs();
      layoutService.step(graph, bounds: bounds, center: center);
      final finalDistance = (node1.x - node2.x).abs();

      expect(finalDistance, greaterThan(initialDistance));
    });

    test(
      'step simulation attracts connected distant nodes with spring tension',
      () {
        final node1 = GraphNode(
          id: '1',
          title: 'Node 1',
          type: GraphNodeType.document,
          color: AtlasColors.accentBlue,
          x: 200.0,
          y: 300.0,
        );
        final node2 = GraphNode(
          id: '2',
          title: 'Node 2',
          type: GraphNodeType.document,
          color: AtlasColors.accentBlue,
          x: 600.0,
          y: 300.0,
        );

        final graph = GraphData(
          nodes: {'1': node1, '2': node2},
          edges: const [GraphEdge(sourceId: '1', targetId: '2')],
        );

        final initialDistance = (node1.x - node2.x).abs();
        layoutService.step(graph, bounds: bounds, center: center);
        final finalDistance = (node1.x - node2.x).abs();

        expect(finalDistance, lessThan(initialDistance));
      },
    );

    test('pinned node maintains position during simulation steps', () {
      final nodePinned = GraphNode(
        id: 'pinned',
        title: 'Pinned Node',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
        x: 450.0,
        y: 350.0,
        isPinned: true,
      );
      final nodeFree = GraphNode(
        id: 'free',
        title: 'Free Node',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
        x: 455.0,
        y: 355.0,
      );

      final graph = GraphData(
        nodes: {'pinned': nodePinned, 'free': nodeFree},
        edges: const [],
      );

      layoutService.step(graph, bounds: bounds, center: center);

      expect(nodePinned.x, equals(450.0));
      expect(nodePinned.y, equals(350.0));
      expect(nodePinned.vx, equals(0.0));
      expect(nodePinned.vy, equals(0.0));
    });

    test('multi-step simulation converges towards low kinetic energy', () {
      final nodeA = GraphNode(
        id: 'A',
        title: 'A',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
      );
      final nodeB = GraphNode(
        id: 'B',
        title: 'B',
        type: GraphNodeType.notebook,
        color: AtlasColors.accentSage,
      );
      final graph = GraphData(
        nodes: {'A': nodeA, 'B': nodeB},
        edges: const [GraphEdge(sourceId: 'A', targetId: 'B')],
      );

      layoutService.initializePositions(graph, bounds: bounds, center: center);

      double energy = 1000.0;
      for (int i = 0; i < 60; i++) {
        energy = layoutService.step(graph, bounds: bounds, center: center);
      }

      expect(energy, lessThan(1.0));
      expect(nodeA.x.isFinite, isTrue);
      expect(nodeB.x.isFinite, isTrue);
    });
  });

  group('GraphRepository.extractNeighborhood', () {
    test('extracts 1-hop local subgraph around target node', () {
      final nodeA = GraphNode(
        id: 'A',
        title: 'Node A',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
      );
      final nodeB = GraphNode(
        id: 'B',
        title: 'Node B',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
      );
      final nodeC = GraphNode(
        id: 'C',
        title: 'Node C',
        type: GraphNodeType.notebook,
        color: AtlasColors.accentSage,
      );
      final nodeIsolated = GraphNode(
        id: 'Isolated',
        title: 'Isolated Node',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
      );

      final fullGraph = GraphData(
        nodes: {'A': nodeA, 'B': nodeB, 'C': nodeC, 'Isolated': nodeIsolated},
        edges: const [
          GraphEdge(sourceId: 'A', targetId: 'B'),
          GraphEdge(sourceId: 'B', targetId: 'C'),
        ],
      );

      final neighborhood = GraphRepository.extractNeighborhood(
        fullGraph,
        'B',
        depth: 1,
      );

      expect(neighborhood.nodes.keys.toSet(), equals({'A', 'B', 'C'}));
      expect(neighborhood.nodes.containsKey('Isolated'), isFalse);
      expect(neighborhood.edges.length, equals(2));
    });

    test('returns empty graph when target node is not found', () {
      final fullGraph = const GraphData(nodes: {}, edges: []);
      final neighborhood = GraphRepository.extractNeighborhood(
        fullGraph,
        'unknown',
        depth: 1,
      );

      expect(neighborhood.nodes, isEmpty);
      expect(neighborhood.edges, isEmpty);
    });
  });
}
