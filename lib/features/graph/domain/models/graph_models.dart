import 'package:flutter/material.dart';

enum GraphNodeType { document, notebook, tag }

class GraphNode {
  final String id;
  final String title;
  final GraphNodeType type;
  double x;
  double y;
  double vx;
  double vy;
  bool isPinned;
  int degree;
  double radius;
  Color color;

  GraphNode({
    required this.id,
    required this.title,
    required this.type,
    this.x = 0.0,
    this.y = 0.0,
    this.vx = 0.0,
    this.vy = 0.0,
    this.isPinned = false,
    this.degree = 0,
    this.radius = 6.0,
    required this.color,
  });

  GraphNode copyWith({
    String? id,
    String? title,
    GraphNodeType? type,
    double? x,
    double? y,
    double? vx,
    double? vy,
    bool? isPinned,
    int? degree,
    double? radius,
    Color? color,
  }) {
    return GraphNode(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      isPinned: isPinned ?? this.isPinned,
      degree: degree ?? this.degree,
      radius: radius ?? this.radius,
      color: color ?? this.color,
    );
  }
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final double weight;

  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    this.weight = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          runtimeType == other.runtimeType &&
          ((sourceId == other.sourceId && targetId == other.targetId) ||
              (sourceId == other.targetId && targetId == other.sourceId));

  @override
  int get hashCode => sourceId.hashCode ^ targetId.hashCode;
}

class GraphData {
  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;

  const GraphData({required this.nodes, required this.edges});

  GraphData copyWith({Map<String, GraphNode>? nodes, List<GraphEdge>? edges}) {
    return GraphData(nodes: nodes ?? this.nodes, edges: edges ?? this.edges);
  }
}
