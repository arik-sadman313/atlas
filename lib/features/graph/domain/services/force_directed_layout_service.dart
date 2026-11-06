import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/graph_models.dart';

/// Lightweight self-contained 2D Force-Directed Layout Service (< 250 lines).
/// Implements Fruchterman-Reingold / Verlet particle physics with kinetic convergence detection.
class ForceDirectedLayoutService {
  final double repulsionForce;
  final double springLength;
  final double springStiffness;
  final double centerGravity;
  final double damping;
  final double maxVelocity;
  final double convergenceThreshold;

  const ForceDirectedLayoutService({
    this.repulsionForce = 3200.0,
    this.springLength = 85.0,
    this.springStiffness = 0.05,
    this.centerGravity = 0.02,
    this.damping = 0.85,
    this.maxVelocity = 14.0,
    this.convergenceThreshold = 0.04,
  });

  /// Initializes node positions evenly in a spiral circle around [center]
  /// to prevent division-by-zero singularities.
  void initializePositions(
    GraphData graph, {
    required Size bounds,
    required Offset center,
  }) {
    final nodeList = graph.nodes.values.toList();
    final count = nodeList.length;
    if (count == 0) return;

    final initialRadius = math.min(bounds.width, bounds.height) * 0.35;
    for (int i = 0; i < count; i++) {
      final node = nodeList[i];
      if (node.x != 0.0 || node.y != 0.0) continue;

      final angle = (i * 2.399963229728653); // Golden ratio angle
      final r = initialRadius * math.sqrt((i + 1) / count);
      node.x = center.dx + r * math.cos(angle);
      node.y = center.dy + r * math.sin(angle);
      node.vx = 0.0;
      node.vy = 0.0;
    }
  }

  /// Executes a single simulation step.
  /// Returns the total kinetic energy of the system for convergence check.
  double step(GraphData graph, {required Size bounds, required Offset center}) {
    final nodeList = graph.nodes.values.toList();
    final count = nodeList.length;
    if (count == 0) return 0.0;

    final fx = <String, double>{for (final n in nodeList) n.id: 0.0};
    final fy = <String, double>{for (final n in nodeList) n.id: 0.0};

    // 1. Coulomb Repulsion between all node pairs
    for (int i = 0; i < count; i++) {
      final n1 = nodeList[i];
      for (int j = i + 1; j < count; j++) {
        final n2 = nodeList[j];

        double dx = n1.x - n2.x;
        double dy = n1.y - n2.y;
        double distSq = dx * dx + dy * dy;

        // Prevent singularity
        if (distSq < 1.0) {
          dx = (i % 2 == 0 ? 1.0 : -1.0) * 2.0;
          dy = (j % 2 == 0 ? 1.0 : -1.0) * 2.0;
          distSq = dx * dx + dy * dy;
        }

        final dist = math.sqrt(distSq);
        final force = repulsionForce / (distSq + 10.0);
        final normX = dx / dist;
        final normY = dy / dist;

        fx[n1.id] = fx[n1.id]! + normX * force;
        fy[n1.id] = fy[n1.id]! + normY * force;

        fx[n2.id] = fx[n2.id]! - normX * force;
        fy[n2.id] = fy[n2.id]! - normY * force;
      }
    }

    // 2. Hooke's Law Spring Attraction along edges
    for (final edge in graph.edges) {
      final n1 = graph.nodes[edge.sourceId];
      final n2 = graph.nodes[edge.targetId];
      if (n1 == null || n2 == null) continue;

      double dx = n2.x - n1.x;
      double dy = n2.y - n1.y;
      double dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 0.1) dist = 0.1;

      final displacement = dist - springLength;
      final force = springStiffness * displacement * edge.weight;
      final normX = dx / dist;
      final normY = dy / dist;

      fx[n1.id] = fx[n1.id]! + normX * force;
      fy[n1.id] = fy[n1.id]! + normY * force;

      fx[n2.id] = fx[n2.id]! - normX * force;
      fy[n2.id] = fy[n2.id]! - normY * force;
    }

    // 3. Center Gravity pull & Kinematics integration
    double totalEnergy = 0.0;
    const margin = 24.0;
    final minX = margin;
    final maxX = bounds.width - margin;
    final minY = margin;
    final maxY = bounds.height - margin;

    for (final node in nodeList) {
      if (node.isPinned) {
        node.vx = 0.0;
        node.vy = 0.0;
        continue;
      }

      // Gravitational pull toward center
      final gravX = (center.dx - node.x) * centerGravity;
      final gravY = (center.dy - node.y) * centerGravity;

      final netFx = fx[node.id]! + gravX;
      final netFy = fy[node.id]! + gravY;

      // Velocity update with damping
      node.vx = ((node.vx + netFx) * damping).clamp(-maxVelocity, maxVelocity);
      node.vy = ((node.vy + netFy) * damping).clamp(-maxVelocity, maxVelocity);

      // Position update
      node.x += node.vx;
      node.y += node.vy;

      // Keep within bounds
      if (node.x < minX) {
        node.x = minX;
        node.vx = -node.vx * 0.5;
      } else if (node.x > maxX) {
        node.x = maxX;
        node.vx = -node.vx * 0.5;
      }

      if (node.y < minY) {
        node.y = minY;
        node.vy = -node.vy * 0.5;
      } else if (node.y > maxY) {
        node.y = maxY;
        node.vy = -node.vy * 0.5;
      }

      totalEnergy += (node.vx * node.vx + node.vy * node.vy);
    }

    return totalEnergy;
  }
}
