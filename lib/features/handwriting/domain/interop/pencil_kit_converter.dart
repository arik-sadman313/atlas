import '../models/atlas_ink_document.dart';
import '../models/ink_layer.dart';
import '../models/ink_point.dart';
import '../models/ink_stroke.dart';
import '../models/ink_tool.dart';

/// Bidirectional converter between ATLAS portable ink format and Apple PencilKit
/// stroke dictionaries as exchanged over native platform channels.
///
/// Features:
/// - Maps pressure, tilt azimuth, tilt altitude, and timestamps.
/// - Preserves coordinates (x, y) without coordinate-space drift.
/// - Maps ARGB 32-bit colors to/from iOS UIColor ARGB representations.
/// - Maps ATLAS tool types to PencilKit ink types with documented fallback.
class PencilKitConverter {
  /// Maps an ATLAS [InkToolType] to a PencilKit ink type string.
  static String mapToolToPencilKit(InkToolType tool) {
    switch (tool) {
      case InkToolType.ballpointPen:
        return 'ballpointPen'; // Maps to PKInk.InkType.pen in Swift
      case InkToolType.fountainPen:
        return 'fountainPen'; // Maps to PKInk.InkType.pen with weight profile in Swift
      case InkToolType.highlighter:
        return 'highlighter'; // Maps to PKInk.InkType.marker in Swift
      case InkToolType.pencil:
        return 'pencil'; // Maps to PKInk.InkType.pencil in Swift
      case InkToolType.vectorEraser:
      case InkToolType.pixelEraser:
      case InkToolType.lasso:
      case InkToolType.selection:
      case InkToolType.pan:
      case InkToolType.rectangle:
      case InkToolType.ellipse:
      case InkToolType.diamond:
      case InkToolType.arrow:
      case InkToolType.curvedArrow:
      case InkToolType.line:
      case InkToolType.text:
      case InkToolType.stickyNote:
      case InkToolType.frame:
        return 'ballpointPen'; // Erasers, lasso and shapes fallback safely to pen stroke
    }
  }

  /// Maps a PencilKit ink type string back to an ATLAS [InkToolType].
  static InkToolType mapPencilKitToTool(String? pkTool) {
    if (pkTool == null) return InkToolType.ballpointPen;
    switch (pkTool.toLowerCase()) {
      case 'marker':
      case 'highlighter':
        return InkToolType.highlighter;
      case 'pencil':
        return InkToolType.pencil;
      case 'fountainpen':
        return InkToolType.fountainPen;
      case 'pen':
      case 'ballpointpen':
      case 'monoline':
      case 'watercolor':
      case 'crayon':
      default:
        // Graceful fallback for standard and iOS 17+ tools
        return InkToolType.ballpointPen;
    }
  }

  /// Converts a single [InkStroke] into a native PencilKit dictionary.
  static Map<String, dynamic> strokeToPencilKitDictionary(InkStroke stroke) {
    final pointsList = stroke.points.map((pt) {
      return {
        'x': pt.x,
        'y': pt.y,
        'pressure': pt.pressure.clamp(0.01, 1.0),
        'tiltAzimuth': pt.tiltAzimuth,
        'tiltAltitude': pt.tiltAltitude,
        'timeOffsetMs': pt.timeOffsetMs.toDouble(),
      };
    }).toList();

    final isHighlighter = stroke.tool == InkToolType.highlighter;

    return {
      'id': stroke.id,
      'tool': mapToolToPencilKit(stroke.tool),
      'color': stroke.color,
      'baseWidth': stroke.baseWidth,
      'opacity': stroke.opacity,
      'blendMode': isHighlighter ? 'multiply' : stroke.blendMode,
      'points': pointsList,
    };
  }

  /// Converts all strokes in an [AtlasInkDocument] into PencilKit dictionaries.
  static List<Map<String, dynamic>> documentToPencilKitStrokes(
    AtlasInkDocument doc,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final layer in doc.layers) {
      if (!layer.visible) continue;
      for (final stroke in layer.strokes) {
        result.add(strokeToPencilKitDictionary(stroke));
      }
    }
    return result;
  }

  /// Converts a native PencilKit stroke dictionary into an [InkStroke].
  static InkStroke pencilKitDictionaryToStroke(Map<String, dynamic> dict) {
    final strokeId =
        dict['id'] as String? ?? 'pk_${DateTime.now().microsecondsSinceEpoch}';
    final toolStr = dict['tool'] as String?;
    final tool = mapPencilKitToTool(toolStr);
    final color = dict['color'] is int
        ? dict['color'] as int
        : (dict['color'] is num ? (dict['color'] as num).toInt() : 0xFF18181B);
    final baseWidth = (dict['baseWidth'] as num?)?.toDouble() ?? 3.0;
    final opacity =
        (dict['opacity'] as num?)?.toDouble() ??
        (tool == InkToolType.highlighter ? 0.4 : 1.0);
    final blendMode =
        (dict['blendMode'] as String?) ??
        (tool == InkToolType.highlighter ? 'multiply' : 'srcOver');

    final rawPoints = dict['points'] as List? ?? const [];
    final points = <InkPoint>[];

    for (final pt in rawPoints) {
      if (pt is! Map) continue;
      final x = (pt['x'] as num?)?.toDouble() ?? 0.0;
      final y = (pt['y'] as num?)?.toDouble() ?? 0.0;
      final pressure = (pt['pressure'] as num?)?.toDouble() ?? 0.5;
      final tiltAzimuth = (pt['tiltAzimuth'] as num?)?.toDouble() ?? 0.0;
      final tiltAltitude =
          (pt['tiltAltitude'] as num?)?.toDouble() ?? 1.5707963;
      final timeOffsetMs = (pt['timeOffsetMs'] as num?)?.toInt() ?? 0;

      points.add(
        InkPoint(
          x: x,
          y: y,
          pressure: pressure,
          tiltAzimuth: tiltAzimuth,
          tiltAltitude: tiltAltitude,
          timeOffsetMs: timeOffsetMs,
        ),
      );
    }

    return InkStroke(
      id: strokeId,
      tool: tool,
      color: color,
      baseWidth: baseWidth,
      opacity: opacity,
      blendMode: blendMode,
      points: points,
    );
  }

  /// Reconstructs an [AtlasInkDocument] from a list of native PencilKit stroke dictionaries.
  static AtlasInkDocument pencilKitStrokesToDocument(
    List<Map<String, dynamic>> strokesList, {
    required String documentId,
    required int pageNumber,
    double width = 1600.0,
    double height = 2200.0,
    String backgroundTemplate = 'ruled',
    int backgroundColor = 0xFFFFFFFF,
  }) {
    final highlighterStrokes = <InkStroke>[];
    final defaultStrokes = <InkStroke>[];

    for (final dict in strokesList) {
      final stroke = pencilKitDictionaryToStroke(dict);
      if (stroke.tool == InkToolType.highlighter ||
          stroke.blendMode == 'multiply') {
        highlighterStrokes.add(stroke);
      } else {
        defaultStrokes.add(stroke);
      }
    }

    final layers = <InkLayer>[];
    if (highlighterStrokes.isNotEmpty) {
      layers.add(
        InkLayer(
          id: 'layer_highlighter',
          name: 'Highlighters',
          blendMode: 'multiply',
          strokes: highlighterStrokes,
        ),
      );
    }

    layers.add(
      InkLayer(
        id: 'layer_default',
        name: 'Main Ink',
        blendMode: 'srcOver',
        strokes: defaultStrokes,
      ),
    );

    return AtlasInkDocument(
      version: 1,
      documentId: documentId,
      pageNumber: pageNumber,
      width: width,
      height: height,
      backgroundTemplate: backgroundTemplate,
      backgroundColor: backgroundColor,
      layers: layers,
    );
  }
}
