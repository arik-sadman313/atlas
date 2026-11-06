import 'ink_layer.dart';
import 'ink_stroke.dart';

class AtlasInkDocument {
  static const int currentSchemaVersion = 1;

  final int version;
  final String documentId;
  final int pageNumber;
  final double width;
  final double height;
  final double dpi;
  final String backgroundTemplate;
  final int backgroundColor;
  final List<InkLayer> layers;
  final Map<String, dynamic> metadata;

  const AtlasInkDocument({
    this.version = currentSchemaVersion,
    required this.documentId,
    this.pageNumber = 1,
    this.width = 1600.0,
    this.height = 2200.0,
    this.dpi = 264.0,
    this.backgroundTemplate = 'dot_grid_5mm',
    this.backgroundColor = 4294967295, // 0xFFFFFFFF
    required this.layers,
    this.metadata = const {},
  });

  factory AtlasInkDocument.empty({
    required String documentId,
    int pageNumber = 1,
    double width = 1600.0,
    double height = 2200.0,
    String backgroundTemplate = 'dot_grid_5mm',
    int backgroundColor = 4294967295,
  }) {
    return AtlasInkDocument(
      documentId: documentId,
      pageNumber: pageNumber,
      width: width,
      height: height,
      backgroundTemplate: backgroundTemplate,
      backgroundColor: backgroundColor,
      layers: const [
        InkLayer(
          id: 'layer_highlighter',
          name: 'Highlighters',
          blendMode: 'multiply',
          strokes: [],
        ),
        InkLayer(
          id: 'layer_default',
          name: 'Main Ink',
          blendMode: 'srcOver',
          strokes: [],
        ),
      ],
    );
  }

  int get totalStrokeCount =>
      layers.fold(0, (acc, layer) => acc + layer.strokes.length);

  bool get isEmpty => totalStrokeCount == 0;

  List<InkStroke> get allStrokes =>
      layers.expand((layer) => layer.strokes).toList();

  AtlasInkDocument copyWith({
    int? version,
    String? documentId,
    int? pageNumber,
    double? width,
    double? height,
    double? dpi,
    String? backgroundTemplate,
    int? backgroundColor,
    List<InkLayer>? layers,
    Map<String, dynamic>? metadata,
  }) {
    return AtlasInkDocument(
      version: version ?? this.version,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      dpi: dpi ?? this.dpi,
      backgroundTemplate: backgroundTemplate ?? this.backgroundTemplate,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      layers: layers ?? this.layers,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'documentId': documentId,
    'pageNumber': pageNumber,
    'dimensions': {'width': width, 'height': height, 'dpi': dpi},
    'background': {'template': backgroundTemplate, 'color': backgroundColor},
    'layers': layers.map((l) => l.toJson()).toList(),
    'metadata': metadata,
  };

  factory AtlasInkDocument.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions'] as Map<String, dynamic>?;
    final bg = json['background'] as Map<String, dynamic>?;

    return AtlasInkDocument(
      version: (json['version'] as num?)?.toInt() ?? currentSchemaVersion,
      documentId: json['documentId'] as String,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      width: (dims?['width'] as num?)?.toDouble() ?? 1600.0,
      height: (dims?['height'] as num?)?.toDouble() ?? 2200.0,
      dpi: (dims?['dpi'] as num?)?.toDouble() ?? 264.0,
      backgroundTemplate: (bg?['template'] as String?) ?? 'dot_grid_5mm',
      backgroundColor: (bg?['color'] as num?)?.toInt() ?? 4294967295,
      layers:
          (json['layers'] as List<dynamic>?)
              ?.map((l) => InkLayer.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}
