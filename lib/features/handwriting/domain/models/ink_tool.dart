enum InkToolType {
  ballpointPen,
  fountainPen,
  highlighter,
  pencil,
  vectorEraser,
  pixelEraser,
  lasso,
  // Excalidraw Sketch & Diagramming Tools
  selection,
  pan,
  rectangle,
  ellipse,
  diamond,
  arrow,
  curvedArrow,
  line,
  text,
  stickyNote,
  frame;

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

  bool get isSelection =>
      this == InkToolType.selection || this == InkToolType.lasso;

  bool get isPan => this == InkToolType.pan;

  bool get isShape =>
      this == InkToolType.rectangle ||
      this == InkToolType.ellipse ||
      this == InkToolType.diamond ||
      this == InkToolType.arrow ||
      this == InkToolType.curvedArrow ||
      this == InkToolType.line ||
      this == InkToolType.text ||
      this == InkToolType.stickyNote ||
      this == InkToolType.frame;
}

class InkToolConfig {
  final InkToolType type;
  final int color; // ARGB integer
  final double baseWidth;
  final double opacity;
  // Excalidraw Styling
  final String fillStyle; // 'none', 'hachure', 'cross-hatch', 'solid', 'dots'
  final int? fillColor; // ARGB integer
  final double roughness; // 0.0 (architect), 1.0 (artist), 2.0 (cartoonist)
  final String strokeStyle; // 'solid', 'dashed', 'dotted'
  final String roundness; // 'sharp', 'round'
  final String startArrowhead; // 'none', 'arrow', 'dot', 'bar'
  final String endArrowhead; // 'arrow', 'none', 'dot', 'bar'
  final String fontFamily; // 'Virgil', 'Helvetica', 'Cascadia'
  final String textAlign; // 'left', 'center', 'right'
  final double fontSize;
  final bool isCurved;

  bool get isEraser => type.isEraser;
  bool get isHighlighter => type.isHighlighter;
  bool get isLasso => type.isLasso;
  bool get isSelection => type.isSelection;
  bool get isPan => type.isPan;
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
    this.roundness = 'sharp',
    this.startArrowhead = 'none',
    this.endArrowhead = 'arrow',
    this.fontFamily = 'Virgil',
    this.textAlign = 'left',
    this.fontSize = 20.0,
    this.isCurved = false,
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
    String? roundness,
    String? startArrowhead,
    String? endArrowhead,
    String? fontFamily,
    String? textAlign,
    double? fontSize,
    bool? isCurved,
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
      roundness: roundness ?? this.roundness,
      startArrowhead: startArrowhead ?? this.startArrowhead,
      endArrowhead: endArrowhead ?? this.endArrowhead,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      fontSize: fontSize ?? this.fontSize,
      isCurved: isCurved ?? this.isCurved,
    );
  }
}
