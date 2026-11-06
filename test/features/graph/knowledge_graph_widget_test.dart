import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/app/providers.dart';
import 'package:atlas/core/theme/atlas_colors.dart';
import 'package:atlas/features/graph/domain/models/graph_models.dart';
import 'package:atlas/features/graph/presentation/knowledge_graph_screen.dart';
import 'package:atlas/features/graph/presentation/widgets/interactive_knowledge_graph.dart';
import 'package:atlas/features/graph/presentation/widgets/local_graph_panel.dart';

void main() {
  group('KnowledgeGraphScreen Widget Tests', () {
    final mockNodes = {
      'doc-1': GraphNode(
        id: 'doc-1',
        title: 'Architecture Spec',
        type: GraphNodeType.document,
        color: AtlasColors.accentBlue,
        degree: 2,
        x: 400,
        y: 300,
      ),
      'nb-1': GraphNode(
        id: 'nb-1',
        title: 'Meeting Log',
        type: GraphNodeType.notebook,
        color: AtlasColors.accentSage,
        degree: 1,
        x: 450,
        y: 320,
      ),
      'tag-1': GraphNode(
        id: 'tag-1',
        title: '#sprint-7',
        type: GraphNodeType.tag,
        color: AtlasColors.accentAmber,
        degree: 1,
        x: 350,
        y: 280,
      ),
    };

    final mockEdges = const [
      GraphEdge(sourceId: 'doc-1', targetId: 'nb-1'),
      GraphEdge(sourceId: 'doc-1', targetId: 'tag-1'),
    ];

    final mockGraphData = GraphData(nodes: mockNodes, edges: mockEdges);

    testWidgets('renders empty state when graph contains no nodes', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceGraphProvider.overrideWith(
              (ref) async => const GraphData(nodes: {}, edges: []),
            ),
          ],
          child: const MaterialApp(home: KnowledgeGraphScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Knowledge Graph is Empty'), findsOneWidget);
      expect(
        find.text('Create documents and use [[Wiki-Links]] to connect ideas.'),
        findsOneWidget,
      );
    });

    testWidgets('renders graph canvas and control toolbar with type chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceGraphProvider.overrideWith((ref) async => mockGraphData),
          ],
          child: const MaterialApp(home: KnowledgeGraphScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // InteractiveKnowledgeGraph canvas is mounted
      expect(find.byType(InteractiveKnowledgeGraph), findsOneWidget);

      // Filter chips and orphans toggle are rendered
      expect(find.text('Docs'), findsOneWidget);
      expect(find.text('Notebooks'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      expect(find.byIcon(Icons.scatter_plot), findsOneWidget);

      // Search input field is rendered
      expect(find.byType(TextField), findsOneWidget);

      // Toggle filter chip
      await tester.tap(find.text('Docs'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // InteractiveViewer is mounted for pinch-to-zoom and panning
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('LocalGraphPanel renders collapsible 1-hop view for node', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceGraphProvider.overrideWith((ref) async => mockGraphData),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LocalGraphPanel(nodeId: 'doc-1', initialExpanded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Panel title is rendered
      expect(find.text('Local Knowledge Graph (1-Hop)'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('Local Knowledge Graph (1-Hop)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap header to re-expand
      await tester.tap(find.text('Local Knowledge Graph (1-Hop)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Local Knowledge Graph (1-Hop)'), findsOneWidget);
    });
  });
}
