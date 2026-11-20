import 'dart:ui';

import '../models/atlas_ink_document.dart';
import '../models/ink_layer.dart';
import '../models/ink_point.dart';
import '../models/ink_stroke.dart';
import '../models/ink_tool.dart';

/// Comprehensive bi-directional converter between ATLAS Notebooks and the official
/// Excalidraw JSON schema (v2).
///
/// Supports all Excalidraw element types:
/// - Shapes: Rectangle, Ellipse, Diamond, Line, Arrow (Straight & Curved)
/// - Typography: Text (Virgil, Helvetica, Cascadia), Sticky Notes, Frames
/// - Styling: Roundness, Hachure/Cross-hatch/Dots/Solid fills, Arrowhead markers,
///   Dashed/Dotted strokes, Opacity, Rotation, Locking, Grouping.
class ExcalidrawConverter {
  /// Converts an [AtlasInkDocument] page into an official Excalidraw v2 document.
  static Map<String, dynamic> exportToExcalidraw(AtlasInkDocument doc) {
    final elements = <Map<String, dynamic>>[];

    for (final layer in doc.layers) {
      for (final stroke in layer.strokes) {
        final el = _convertStrokeToExcalidrawElement(stroke);
        if (el != null) {
          elements.add(el);
        }
      }
    }

    return {
      'type': 'excalidraw',
      'version': 2,
      'source': 'https://atlas.app',
      'elements': elements,
      'appState': {
        'viewBackgroundColor': _intToHexColor(doc.backgroundColor),
        'gridSize': doc.templateSpacing.toInt(),
      },
    };
  }

  /// Imports an Excalidraw v2 document into an [AtlasInkDocument].
  static AtlasInkDocument importFromExcalidraw(
    Map<String, dynamic> json, {
    required String documentId,
    int pageNumber = 1,
  }) {
    final elements = json['elements'] as List<dynamic>? ?? [];
    final strokes = <InkStroke>[];

    for (final raw in elements) {
      if (raw is Map<String, dynamic>) {
        final isDeleted = raw['isDeleted'] as bool? ?? false;
        if (!isDeleted) {
          final stroke = _convertExcalidrawElementToStroke(raw);
          if (stroke != null) {
            strokes.add(stroke);
          }
        }
      }
    }

    final appState = json['appState'] as Map<String, dynamic>?;
    final bgHex = appState?['viewBackgroundColor'] as String?;
    final bgColor = bgHex != null ? _hexColorToInt(bgHex) : 0xFFFFFFFF;

    return AtlasInkDocument(
      documentId: documentId,
      pageNumber: pageNumber,
      backgroundColor: bgColor,
      layers: [
        const InkLayer(
          id: 'layer_highlighter',
          name: 'Highlighters',
          blendMode: 'multiply',
          strokes: [],
        ),
        InkLayer(
          id: 'layer_default',
          name: 'Excalidraw Content',
          blendMode: 'srcOver',
          strokes: strokes,
        ),
      ],
    );
  }

  static Map<String, dynamic>? _convertStrokeToExcalidrawElement(
    InkStroke stroke,
  ) {
    final bounds = stroke.computedBounds;
    final strokeColorHex = _intToHexColor(stroke.color);
    final fillStyle = stroke.fillStyle ?? 'none';
    final fillColorHex = stroke.fillColor != null
        ? _intToHexColor(stroke.fillColor!)
        : 'transparent';

    String type = 'freedraw';
    if (stroke.tool == InkToolType.rectangle ||
        stroke.shapeType == 'rectangle') {
      type = 'rectangle';
    } else if (stroke.tool == InkToolType.ellipse ||
        stroke.shapeType == 'ellipse') {
      type = 'ellipse';
    } else if (stroke.tool == InkToolType.diamond ||
        stroke.shapeType == 'diamond') {
      type = 'diamond';
    } else if (stroke.tool == InkToolType.arrow ||
        stroke.tool == InkToolType.curvedArrow ||
        stroke.shapeType == 'arrow') {
      type = 'arrow';
    } else if (stroke.tool == InkToolType.line || stroke.shapeType == 'line') {
      type = 'line';
    } else if (stroke.tool == InkToolType.text || stroke.shapeType == 'text') {
      type = 'text';
    } else if (stroke.tool == InkToolType.stickyNote ||
        stroke.shapeType == 'stickyNote') {
      type = 'note';
    } else if (stroke.tool == InkToolType.frame ||
        stroke.shapeType == 'frame') {
      type = 'frame';
    }

    final points = <List<double>>[];
    for (final pt in stroke.points) {
      points.add([pt.x - bounds.left, pt.y - bounds.top]);
    }

    int fontFamilyCode = 1; // Virgil
    if (stroke.fontFamily == 'Helvetica') fontFamilyCode = 2;
    if (stroke.fontFamily == 'Cascadia') fontFamilyCode = 3;

    final isArrowCurved =
        stroke.isCurved || stroke.tool == InkToolType.curvedArrow;
    final roundnessObj = (stroke.roundness == 'round' || isArrowCurved)
        ? {'type': 3}
        : null;

    return {
      'id': stroke.id,
      'type': type,
      'x': bounds.left,
      'y': bounds.top,
      'width': bounds.width,
      'height': bounds.height,
      'angle': stroke.angle,
      'strokeColor': strokeColorHex,
      'backgroundColor': fillColorHex,
      'fillStyle': fillStyle,
      'strokeWidth': stroke.baseWidth.clamp(1.0, 8.0).toInt(),
      'strokeStyle': stroke.strokeStyle ?? 'solid',
      'roughness': stroke.roughness.toInt(),
      'opacity': (stroke.opacity * 100).toInt(),
      'seed': stroke.seed,
      'locked': stroke.isLocked,
      if (stroke.groupId != null) 'groupIds': [stroke.groupId],
      'roundness': ?roundnessObj,
      'points': points,
      if (stroke.startArrowhead != null && stroke.startArrowhead != 'none')
        'startArrowhead': stroke.startArrowhead,
      if (stroke.endArrowhead != null && stroke.endArrowhead != 'none')
        'endArrowhead': stroke.endArrowhead,
      if (stroke.text != null) 'text': stroke.text,
      if (stroke.fontSize != null) 'fontSize': stroke.fontSize,
      if (stroke.text != null) 'fontFamily': fontFamilyCode,
      if (stroke.textAlign != null) 'textAlign': stroke.textAlign,
      if (type == 'frame') 'name': stroke.text ?? 'Frame',
    };
  }

  static InkStroke? _convertExcalidrawElementToStroke(
    Map<String, dynamic> raw,
  ) {
    final type = raw['type'] as String? ?? 'freedraw';
    final id =
        raw['id'] as String? ??
        'excal_${DateTime.now().microsecondsSinceEpoch}';
    final x = (raw['x'] as num?)?.toDouble() ?? 0.0;
    final y = (raw['y'] as num?)?.toDouble() ?? 0.0;
    final w = (raw['width'] as num?)?.toDouble() ?? 100.0;
    final h = (raw['height'] as num?)?.toDouble() ?? 100.0;
    final angle = (raw['angle'] as num?)?.toDouble() ?? 0.0;

    final strokeColorStr = raw['strokeColor'] as String? ?? '#18181b';
    final strokeColor = _hexColorToInt(strokeColorStr);

    final bgColorStr = raw['backgroundColor'] as String?;
    final fillColor = (bgColorStr != null && bgColorStr != 'transparent')
        ? _hexColorToInt(bgColorStr)
        : null;

    final fillStyle = raw['fillStyle'] as String? ?? 'none';
    final strokeWidth = (raw['strokeWidth'] as num?)?.toDouble() ?? 2.0;
    final strokeStyle = raw['strokeStyle'] as String? ?? 'solid';
    final roughness = (raw['roughness'] as num?)?.toDouble() ?? 1.0;
    final opacity = ((raw['opacity'] as num?)?.toDouble() ?? 100.0) / 100.0;
    final seed = raw['seed'] as int? ?? 42;
    final rawPoints = raw['points'] as List<dynamic>? ?? [];
    final locked = raw['locked'] as bool? ?? false;
    final roundness = raw['roundness'] != null ? 'round' : 'sharp';
    final startArrow = raw['startArrowhead'] as String?;
    final endArrow =
        raw['endArrowhead'] as String? ?? (type == 'arrow' ? 'arrow' : null);
    final groupIds = raw['groupIds'] as List<dynamic>?;
    final groupId = groupIds != null && groupIds.isNotEmpty
        ? groupIds.first.toString()
        : null;

    final fontCode = raw['fontFamily'] as int? ?? 1;
    String fontFamily = 'Virgil';
    if (fontCode == 2) fontFamily = 'Helvetica';
    if (fontCode == 3) fontFamily = 'Cascadia';
    final textAlign = raw['textAlign'] as String? ?? 'left';

    final points = <InkPoint>[];
    if (rawPoints.isNotEmpty) {
      for (final p in rawPoints) {
        if (p is List && p.length >= 2) {
          final px = (p[0] as num).toDouble();
          final py = (p[1] as num).toDouble();
          points.add(InkPoint(x: x + px, y: y + py));
        }
      }
    } else {
      points.add(InkPoint(x: x, y: y));
      points.add(InkPoint(x: x + w, y: y + h));
    }

    InkToolType toolType = InkToolType.ballpointPen;
    String? shapeType;

    switch (type) {
      case 'rectangle':
        toolType = InkToolType.rectangle;
        shapeType = 'rectangle';
        break;
      case 'ellipse':
        toolType = InkToolType.ellipse;
        shapeType = 'ellipse';
        break;
      case 'diamond':
        toolType = InkToolType.diamond;
        shapeType = 'diamond';
        break;
      case 'arrow':
        final isCurved = raw['roundness'] != null || (raw['elbowed'] == true);
        toolType = isCurved ? InkToolType.curvedArrow : InkToolType.arrow;
        shapeType = isCurved ? 'curvedArrow' : 'arrow';
        break;
      case 'line':
        toolType = InkToolType.line;
        shapeType = 'line';
        break;
      case 'text':
        toolType = InkToolType.text;
        shapeType = 'text';
        break;
      case 'note':
        toolType = InkToolType.stickyNote;
        shapeType = 'stickyNote';
        break;
      case 'frame':
        toolType = InkToolType.frame;
        shapeType = 'frame';
        break;
      default:
        toolType = InkToolType.ballpointPen;
        break;
    }

    return InkStroke(
      id: id,
      tool: toolType,
      color: strokeColor,
      baseWidth: strokeWidth,
      opacity: opacity,
      points: points,
      bounds: Rect.fromLTWH(x, y, w, h),
      shapeType: shapeType,
      fillStyle: fillStyle,
      fillColor: fillColor,
      roughness: roughness,
      strokeStyle: strokeStyle,
      roundness: roundness,
      startArrowhead: startArrow,
      endArrowhead: endArrow,
      angle: angle,
      fontFamily: fontFamily,
      textAlign: textAlign,
      isLocked: locked,
      groupId: groupId,
      isCurved: toolType == InkToolType.curvedArrow || raw['roundness'] != null,
      text: (type == 'frame' ? raw['name'] : raw['text']) as String?,
      fontSize:
          (raw['fontSize'] as num?)?.toDouble() ??
          (type == 'note' ? 16.0 : 20.0),
      seed: seed,
    );
  }

  static String _intToHexColor(int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  static int _hexColorToInt(String hex) {
    var clean = hex.replaceAll('#', '').trim();
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (clean.length == 6) {
      return int.parse('FF$clean', radix: 16);
    } else if (clean.length == 8) {
      return int.parse(clean, radix: 16);
    }
    return 0xFF18181B;
  }
}
