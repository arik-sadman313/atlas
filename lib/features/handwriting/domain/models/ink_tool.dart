enum InkToolType {
  ballpointPen,
  fountainPen,
  highlighter,
  pencil,
  vectorEraser,
  pixelEraser,
  lasso,
  // Excalidraw Sketch Shape Tools
  rectangle,
  ellipse,
  diamond,
  arrow,
  line,
  text;

  String toJson() => name;

  static InkToolType fromJson(String value) {
    return InkToolType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InkToolType.ballpointPen,
    );
  }

  bool get isEraser =>
      this == InkToolType.vectorEraser || this == InkToolType.pixelEraser;

  bool get isHighlighter => this == InkToolType.highlighter;

  bool get isLasso => this == InkToolType.lasso;

  bool get isShape =>
      this == InkToolType.rectangle ||
      this == InkToolType.ellipse ||
      this == InkToolType.diamond ||
      this == InkToolType.arrow ||
      this == InkToolType.line ||
      this == InkToolType.text;
}

class InkToolConfig {
  final InkToolType type;
  final int color; // ARGB integer
  final double baseWidth;
  final double opacity;
  // Excalidraw Styling
  final String fillStyle; // 'none', 'hachure', 'cross-hatch', 'solid'
  final int? fillColor; // ARGB integer
  final double roughness; // 0.0 (architect), 1.0 (artist), 2.0 (cartoonist)
  final String strokeStyle; // 'solid', 'dashed', 'dotted'

  bool get isEraser => type.isEraser;
  bool get isHighlighter => type.isHighlighter;
  bool get isLasso => type.isLasso;
  bool get isShape => type.isShape;

  const InkToolConfig({
    required this.type,
    required this.color,
    required this.baseWidth,
    this.opacity = 1.0,
    this.fillStyle = 'none',
    this.fillColor,
    this.roughness = 1.0,
    this.strokeStyle = 'solid',
  });

  InkToolConfig copyWith({
    InkToolType? type,
    int? color,
    double? baseWidth,
    double? opacity,
    String? fillStyle,
    int? fillColor,
    double? roughness,
    String? strokeStyle,
  }) {
    return InkToolConfig(
      type: type ?? this.type,
      color: color ?? this.color,
      baseWidth: baseWidth ?? this.baseWidth,
      opacity: opacity ?? this.opacity,
      fillStyle: fillStyle ?? this.fillStyle,
      fillColor: fillColor ?? this.fillColor,
      roughness: roughness ?? this.roughness,
      strokeStyle: strokeStyle ?? this.strokeStyle,
    );
  }
}
