enum InkToolType {
  ballpointPen,
  fountainPen,
  highlighter,
  pencil,
  vectorEraser,
  pixelEraser,
  lasso;

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
}

class InkToolConfig {
  final InkToolType type;
  final int color; // ARGB integer
  final double baseWidth;
  final double opacity;

  const InkToolConfig({
    required this.type,
    required this.color,
    required this.baseWidth,
    this.opacity = 1.0,
  });

  InkToolConfig copyWith({
    InkToolType? type,
    int? color,
    double? baseWidth,
    double? opacity,
  }) {
    return InkToolConfig(
      type: type ?? this.type,
      color: color ?? this.color,
      baseWidth: baseWidth ?? this.baseWidth,
      opacity: opacity ?? this.opacity,
    );
  }
}
