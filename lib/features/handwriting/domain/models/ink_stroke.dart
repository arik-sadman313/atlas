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

  // Excalidraw Sketch & Shape Attributes
  final String? shapeType; // 'rectangle', 'ellipse', 'diamond', 'arrow', 'curvedArrow', 'line', 'text', 'stickyNote', 'frame'
  final String? fillStyle; // 'none', 'hachure', 'cross-hatch', 'solid', 'dots'
  final int? fillColor; // ARGB integer for sketchy hatching or fill
  final double roughness; // 0.0 (clean), 1.0 (artist), 2.0 (cartoonist)
  final String? text; // Content for text & sticky note elements
  final double? fontSize; // Font size for text elements
  final String? strokeStyle; // 'solid', 'dashed', 'dotted'
  final String? roundness; // 'sharp', 'round'
  final String? startArrowhead; // 'none', 'arrow', 'dot', 'bar'
  final String? endArrowhead; // 'arrow', 'none', 'dot', 'bar'
  final double angle; // Rotation angle in radians
  final String? fontFamily; // 'Virgil', 'Helvetica', 'Cascadia'
  final String? textAlign; // 'left', 'center', 'right'
  final bool isLocked; // Prevent accidental editing
  final String? groupId; // Group identifier
  final bool isCurved; // Curved arrow or spline line
  final int seed; // Deterministic seed for stable Rough.js sketchy rendering

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
    this.shapeType,
    this.fillStyle,
    this.fillColor,
    this.roughness = 1.0,
    this.text,
    this.fontSize,
    this.strokeStyle,
    this.roundness,
    this.startArrowhead,
    this.endArrowhead,
    this.angle = 0.0,
    this.fontFamily,
    this.textAlign,
    this.isLocked = false,
    this.groupId,
    this.isCurved = false,
    this.seed = 42,
  });

  bool get isShape => tool.isShape || shapeType != null;

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
    if (shapeType != null) 'shapeType': shapeType,
    if (fillStyle != null) 'fillStyle': fillStyle,
    if (fillColor != null) 'fillColor': fillColor,
    'roughness': roughness,
    if (text != null) 'text': text,
    if (fontSize != null) 'fontSize': fontSize,
    if (strokeStyle != null) 'strokeStyle': strokeStyle,
    if (roundness != null) 'roundness': roundness,
    if (startArrowhead != null) 'startArrowhead': startArrowhead,
    if (endArrowhead != null) 'endArrowhead': endArrowhead,
    'angle': angle,
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (textAlign != null) 'textAlign': textAlign,
    'isLocked': isLocked,
    if (groupId != null) 'groupId': groupId,
    'isCurved': isCurved,
    'seed': seed,
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
      shapeType: json['shapeType'] as String?,
      fillStyle: json['fillStyle'] as String?,
      fillColor: json['fillColor'] is int
          ? json['fillColor'] as int
          : (json['fillColor'] != null
                ? int.tryParse(json['fillColor'].toString())
                : null),
      roughness: (json['roughness'] as num?)?.toDouble() ?? 1.0,
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      strokeStyle: json['strokeStyle'] as String?,
      roundness: json['roundness'] as String?,
      startArrowhead: json['startArrowhead'] as String?,
      endArrowhead: json['endArrowhead'] as String?,
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      fontFamily: json['fontFamily'] as String?,
      textAlign: json['textAlign'] as String?,
      isLocked: json['isLocked'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      isCurved: json['isCurved'] as bool? ?? false,
      seed: json['seed'] as int? ?? 42,
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
    String? shapeType,
    String? fillStyle,
    int? fillColor,
    double? roughness,
    String? text,
    double? fontSize,
    String? strokeStyle,
    String? roundness,
    String? startArrowhead,
    String? endArrowhead,
    double? angle,
    String? fontFamily,
    String? textAlign,
    bool? isLocked,
    String? groupId,
    bool clearGroupId = false,
    bool? isCurved,
    int? seed,
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
      shapeType: shapeType ?? this.shapeType,
      fillStyle: fillStyle ?? this.fillStyle,
      fillColor: fillColor ?? this.fillColor,
      roughness: roughness ?? this.roughness,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      strokeStyle: strokeStyle ?? this.strokeStyle,
      roundness: roundness ?? this.roundness,
      startArrowhead: startArrowhead ?? this.startArrowhead,
      endArrowhead: endArrowhead ?? this.endArrowhead,
      angle: angle ?? this.angle,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      isLocked: isLocked ?? this.isLocked,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      isCurved: isCurved ?? this.isCurved,
      seed: seed ?? this.seed,
    );
  }
}
