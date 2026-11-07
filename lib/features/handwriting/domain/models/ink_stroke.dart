import 'dart:ui';

import 'ink_point.dart';
import 'ink_tool.dart';

class InkStroke {
  final String id;
  final InkToolType tool;
  final int color; // 32-bit ARGB (e.g. 0xFF18181B)
  final double baseWidth;
  final double opacity;
  final String blendMode; // 'srcOver', 'multiply'
  final List<InkPoint> points;
  final List<double>? transform; // 2x3 affine matrix [a, b, c, d, tx, ty]
  final Rect? bounds;

  const InkStroke({
    required this.id,
    required this.tool,
    required this.color,
    required this.baseWidth,
    this.opacity = 1.0,
    this.blendMode = 'srcOver',
    required this.points,
    this.transform,
    this.bounds,
  });

  Rect get computedBounds {
    if (bounds != null) return bounds!;
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    for (final pt in points) {
      if (pt.x < minX) minX = pt.x;
      if (pt.x > maxX) maxX = pt.x;
      if (pt.y < minY) minY = pt.y;
      if (pt.y > maxY) maxY = pt.y;
    }
    final halfW = baseWidth * 1.5;
    return Rect.fromLTRB(
      minX - halfW,
      minY - halfW,
      maxX + halfW,
      maxY + halfW,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tool': tool.toJson(),
    'color': color,
    'baseWidth': baseWidth,
    'opacity': opacity,
    'blendMode': blendMode,
    'points': points.map((p) => p.toJson()).toList(),
    if (transform != null) 'transform': transform,
    'bounds': [
      computedBounds.left,
      computedBounds.top,
      computedBounds.right,
      computedBounds.bottom,
    ],
  };

  factory InkStroke.fromJson(Map<String, dynamic> json) {
    Rect? boundsRect;
    if (json['bounds'] is List && (json['bounds'] as List).length == 4) {
      final b = json['bounds'] as List;
      boundsRect = Rect.fromLTRB(
        (b[0] as num).toDouble(),
        (b[1] as num).toDouble(),
        (b[2] as num).toDouble(),
        (b[3] as num).toDouble(),
      );
    }

    return InkStroke(
      id: json['id'] as String,
      tool: InkToolType.fromJson(json['tool'] as String),
      color: json['color'] is int
          ? json['color'] as int
          : int.parse(json['color'].toString()),
      baseWidth: (json['baseWidth'] as num).toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: (json['blendMode'] as String?) ?? 'srcOver',
      points: (json['points'] as List<dynamic>)
          .map((p) => InkPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      transform: (json['transform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      bounds: boundsRect,
    );
  }

  InkStroke copyWith({
    String? id,
    InkToolType? tool,
    int? color,
    double? baseWidth,
    double? opacity,
    String? blendMode,
    List<InkPoint>? points,
    List<double>? transform,
    Rect? bounds,
  }) {
    return InkStroke(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      baseWidth: baseWidth ?? this.baseWidth,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      points: points ?? this.points,
      transform: transform ?? this.transform,
      bounds: bounds ?? this.bounds,
    );
  }
}
