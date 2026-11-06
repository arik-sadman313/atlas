import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/graph_models.dart';
import '../../domain/services/force_directed_layout_service.dart';
import 'knowledge_graph_painter.dart';

class InteractiveKnowledgeGraph extends StatefulWidget {
  final GraphData graph;
  final void Function(GraphNode node)? onNodeTap;
  final String? highlightQuery;
  final bool showOrphans;
  final Set<GraphNodeType> visibleTypes;
  final Size canvasSize;

  const InteractiveKnowledgeGraph({
    super.key,
    required this.graph,
    this.onNodeTap,
    this.highlightQuery,
    this.showOrphans = true,
    this.visibleTypes = const {
      GraphNodeType.document,
      GraphNodeType.notebook,
      GraphNodeType.tag,
    },
    this.canvasSize = const Size(2000, 2000),
  });

  @override
  State<InteractiveKnowledgeGraph> createState() =>
      _InteractiveKnowledgeGraphState();
}

class _InteractiveKnowledgeGraphState extends State<InteractiveKnowledgeGraph>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformController;
  late final ForceDirectedLayoutService _layoutService;
  late final AnimationController _tickerController;

  String? _hoveredNodeId;
  String? _selectedNodeId;
  GraphNode? _draggedNode;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _layoutService = const ForceDirectedLayoutService();

    // Center the viewport initially
    final initialOffset = Offset(
      -widget.canvasSize.width / 4,
      -widget.canvasSize.height / 4,
    );
    _transformController.value = Matrix4.translationValues(
      initialOffset.dx,
      initialOffset.dy,
      0,
    );

    // Initialize layout positions
    _layoutService.initializePositions(
      widget.graph,
      bounds: widget.canvasSize,
      center: Offset(widget.canvasSize.width / 2, widget.canvasSize.height / 2),
    );

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    _startSimulation();
  }

  @override
  void didUpdateWidget(covariant InteractiveKnowledgeGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.graph != oldWidget.graph) {
      _layoutService.initializePositions(
        widget.graph,
        bounds: widget.canvasSize,
        center: Offset(
          widget.canvasSize.width / 2,
          widget.canvasSize.height / 2,
        ),
      );
      _startSimulation();
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _startSimulation() {
    if (!_isSimulating) {
      _isSimulating = true;
      _tickerController.repeat();
    }
  }

  void _stopSimulation() {
    if (_isSimulating) {
      _isSimulating = false;
      _tickerController.stop();
    }
  }

  void _onTick() {
    if (!_isSimulating) return;

    final energy = _layoutService.step(
      widget.graph,
      bounds: widget.canvasSize,
      center: Offset(widget.canvasSize.width / 2, widget.canvasSize.height / 2),
    );

    setState(() {});

    // If kinetic energy is below convergence threshold and no node is being dragged, stop ticking
    if (energy < _layoutService.convergenceThreshold && _draggedNode == null) {
      _stopSimulation();
    }
  }

  GraphNode? _findNodeAt(Offset localPosition) {
    for (final node in widget.graph.nodes.values) {
      if (!widget.visibleTypes.contains(node.type)) continue;
      if (!widget.showOrphans && node.degree == 0) continue;

      final dx = localPosition.dx - node.x;
      final dy = localPosition.dy - node.y;
      final touchRadius = math.max(16.0, node.radius + 10.0);
      if (dx * dx + dy * dy <= touchRadius * touchRadius) {
        return node;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.2,
      maxScale: 3.5,
      constrained: false,
      child: MouseRegion(
        onHover: (event) {
          final node = _findNodeAt(event.localPosition);
          if (node?.id != _hoveredNodeId) {
            setState(() {
              _hoveredNodeId = node?.id;
            });
          }
        },
        child: GestureDetector(
          onTapUp: (details) {
            final node = _findNodeAt(details.localPosition);
            if (node != null) {
              setState(() {
                _selectedNodeId = node.id;
              });
              if (widget.onNodeTap != null) {
                widget.onNodeTap!(node);
              }
            } else {
              setState(() {
                _selectedNodeId = null;
              });
            }
          },
          onPanStart: (details) {
            final node = _findNodeAt(details.localPosition);
            if (node != null) {
              _draggedNode = node;
              node.isPinned = true;
              node.x = details.localPosition.dx;
              node.y = details.localPosition.dy;
              _startSimulation();
            }
          },
          onPanUpdate: (details) {
            if (_draggedNode != null) {
              _draggedNode!.x = details.localPosition.dx;
              _draggedNode!.y = details.localPosition.dy;
              _startSimulation();
            }
          },
          onPanEnd: (_) {
            if (_draggedNode != null) {
              _draggedNode!.isPinned = false;
              _draggedNode = null;
            }
          },
          child: RepaintBoundary(
            child: CustomPaint(
              size: widget.canvasSize,
              painter: KnowledgeGraphPainter(
                graph: widget.graph,
                hoveredNodeId: _hoveredNodeId,
                selectedNodeId: _selectedNodeId,
                highlightQuery: widget.highlightQuery,
                showOrphans: widget.showOrphans,
                visibleTypes: widget.visibleTypes,
                isDark: isDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
