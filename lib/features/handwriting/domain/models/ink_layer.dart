import 'ink_stroke.dart';

class InkLayer {
  final String id;
  final String name;
  final bool visible;
  final double opacity;
  final String blendMode; // 'srcOver', 'multiply'
  final List<InkStroke> strokes;

  const InkLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = 'srcOver',
    required this.strokes,
  });

  InkLayer copyWith({
    String? id,
    String? name,
    bool? visible,
    double? opacity,
    String? blendMode,
    List<InkStroke>? strokes,
  }) {
    return InkLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      strokes: strokes ?? this.strokes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'visible': visible,
    'opacity': opacity,
    'blendMode': blendMode,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  factory InkLayer.fromJson(Map<String, dynamic> json) => InkLayer(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? 'Layer',
    visible: (json['visible'] as bool?) ?? true,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    blendMode: (json['blendMode'] as String?) ?? 'srcOver',
    strokes: (json['strokes'] as List<dynamic>)
        .map((s) => InkStroke.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}
