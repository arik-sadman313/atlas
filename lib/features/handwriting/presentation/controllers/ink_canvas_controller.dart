import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../domain/math/smart_shape_detector.dart';
import '../../domain/math/stroke_tessellator.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_layer.dart';
import '../../domain/models/ink_point.dart';
import '../../domain/models/ink_stroke.dart';
import '../../domain/models/ink_tool.dart';
import '../widgets/ink_render_cache.dart';

class InkCanvasController extends ChangeNotifier {
  late AtlasInkDocument _document;
  InkToolConfig _activeTool;
  final List<AtlasInkDocument> _undoStack = [];
  final List<AtlasInkDocument> _redoStack = [];

  // Static stroke picture render cache (Milestone 9 optimization)
  final InkRenderCache _renderCache = InkRenderCache();
  int _revision = 0;

  // Active in-flight stroke
  final List<InkPoint> _activePoints = [];
  int _strokeStartTime = 0;
  bool _isDrawing = false;

  // Lasso selection state
  final List<Offset> _lassoPolygon = [];
  Set<String> _selectedStrokeIds = {};
  Rect? _selectionBounds;

  InkCanvasController({
    required AtlasInkDocument document,
    InkToolConfig? initialTool,
  }) : _activeTool =
           initialTool ??
           const InkToolConfig(
             type: InkToolType.ballpointPen,
             color: 0xFF18181B,
             baseWidth: 3.0,
           ) {
    _document = document;
  }

  AtlasInkDocument get document => _document;
  InkToolConfig get activeTool => _activeTool;
  List<InkPoint> get activePoints => List.unmodifiable(_activePoints);
  bool get isDrawing => _isDrawing;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  InkRenderCache get renderCache => _renderCache;
  int get revision => _revision;

  // Lasso getters
  List<Offset> get lassoPolygon => List.unmodifiable(_lassoPolygon);
  Set<String> get selectedStrokeIds => Set.unmodifiable(_selectedStrokeIds);
  Rect? get selectionBounds => _selectionBounds;
  bool get hasSelection => _selectedStrokeIds.isNotEmpty;

  List<InkStroke> get selectedStrokes {
    if (_selectedStrokeIds.isEmpty) return const [];
    final list = <InkStroke>[];
    for (final layer in _document.layers) {
      for (final stroke in layer.strokes) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          list.add(stroke);
        }
      }
    }
    return list;
  }

  void loadDocument(AtlasInkDocument doc) {
    _document = doc;
    _undoStack.clear();
    _redoStack.clear();
    _activePoints.clear();
    _lassoPolygon.clear();
    _selectedStrokeIds = {};
    _selectionBounds = null;
    _isDrawing = false;
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void setTool(InkToolConfig tool) {
    _activeTool = tool;
    if (!tool.type.isLasso && _selectedStrokeIds.isNotEmpty) {
      clearSelection();
    } else {
      notifyListeners();
    }
  }

  void startStroke(
    Offset position, {
    double pressure = 0.5,
    double tiltAzimuth = 0.0,
    double tiltAltitude = 1.5707963,
  }) {
    if (_activeTool.type.isEraser) {
      _recordUndoSnapshot();
      eraseAt(position, _activeTool.baseWidth * 3);
      return;
    }

    if (_activeTool.type.isLasso) {
      _selectedStrokeIds = {};
      _selectionBounds = null;
      _isDrawing = true;
      _lassoPolygon.clear();
      _lassoPolygon.add(position);
      notifyListeners();
      return;
    }

    _isDrawing = true;
    _strokeStartTime = DateTime.now().millisecondsSinceEpoch;
    _activePoints.clear();
    _activePoints.add(
      InkPoint(
        x: position.dx,
        y: position.dy,
        pressure: pressure,
        tiltAzimuth: tiltAzimuth,
        tiltAltitude: tiltAltitude,
        timeOffsetMs: 0,
      ),
    );
    notifyListeners();
  }

  void updateStroke(
    Offset position, {
    double pressure = 0.5,
    double tiltAzimuth = 0.0,
    double tiltAltitude = 1.5707963,
  }) {
    if (_activeTool.type.isEraser) {
      eraseAt(position, _activeTool.baseWidth * 3);
      return;
    }

    if (_activeTool.type.isLasso) {
      if (!_isDrawing) return;
      _lassoPolygon.add(position);
      notifyListeners();
      return;
    }

    if (!_isDrawing) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _activePoints.add(
      InkPoint(
        x: position.dx,
        y: position.dy,
        pressure: pressure,
        tiltAzimuth: tiltAzimuth,
        tiltAltitude: tiltAltitude,
        timeOffsetMs: now - _strokeStartTime,
      ),
    );
    notifyListeners();
  }

  void endStroke() {
    if (_activeTool.type.isLasso) {
      if (!_isDrawing) return;
      _isDrawing = false;
      if (_lassoPolygon.length >= 3) {
        final selected = <String>{};
        for (final layer in _document.layers) {
          for (final stroke in layer.strokes) {
            if (StrokeTessellator.isStrokeSelectedByLasso(
              stroke,
              _lassoPolygon,
            )) {
              selected.add(stroke.id);
            }
          }
        }
        _selectedStrokeIds = selected;
        _recomputeSelectionBounds();
      }
      _lassoPolygon.clear();
      notifyListeners();
      return;
    }

    if (!_isDrawing || _activePoints.isEmpty) {
      _isDrawing = false;
      _activePoints.clear();
      return;
    }

    _recordUndoSnapshot();

    final strokeId = 's_${DateTime.now().microsecondsSinceEpoch}';
    final isHighlighter = _activeTool.type.isHighlighter;

    if (_activeTool.type.isShape && _activePoints.length >= 2) {
      // Commit Excalidraw Shape
      final p1 = _activePoints.first;
      final p2 = _activePoints.last;
      final shapeBounds = Rect.fromPoints(
        Offset(p1.x, p1.y),
        Offset(p2.x, p2.y),
      );

      final shapeStroke = InkStroke(
        id: strokeId,
        tool: _activeTool.type,
        color: _activeTool.color,
        baseWidth: _activeTool.baseWidth,
        opacity: _activeTool.opacity,
        blendMode: 'srcOver',
        points: [
          InkPoint(x: p1.x, y: p1.y),
          InkPoint(x: p2.x, y: p2.y),
        ],
        bounds: shapeBounds,
        shapeType: _activeTool.type.name,
        fillStyle: _activeTool.fillStyle,
        fillColor: _activeTool.fillColor,
        roughness: _activeTool.roughness,
        strokeStyle: _activeTool.strokeStyle,
        seed: DateTime.now().microsecondsSinceEpoch % 10000,
      );

      _addStrokeToDocument(shapeStroke);
    } else {
      // Commit Standard Freehand Ink Stroke
      final strokeBounds = StrokeTessellator.computeBoundsFromPoints(
        _activePoints,
        _activeTool.baseWidth,
      );

      final stroke = InkStroke(
        id: strokeId,
        tool: _activeTool.type,
        color: _activeTool.color,
        baseWidth: _activeTool.baseWidth,
        opacity: isHighlighter ? 0.4 : _activeTool.opacity,
        blendMode: isHighlighter ? 'multiply' : 'srcOver',
        points: List.of(_activePoints),
        bounds: strokeBounds,
      );

      _addStrokeToDocument(stroke, isHighlighter: isHighlighter);
    }

    _isDrawing = false;
    _activePoints.clear();
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  /// Snaps the current in-flight freehand stroke to an Excalidraw sketchy
  /// vector shape (iPad draw-and-hold feature).
  void snapInFlightStrokeToShape(DetectedShape shape) {
    if (!_isDrawing || _activePoints.isEmpty) return;
    _recordUndoSnapshot();

    final strokeId = 'shape_${DateTime.now().microsecondsSinceEpoch}';
    final stroke = InkStroke(
      id: strokeId,
      tool: shape.type,
      color: _activeTool.color,
      baseWidth: _activeTool.baseWidth,
      opacity: _activeTool.opacity,
      blendMode: 'srcOver',
      points: [
        InkPoint(x: shape.start.dx, y: shape.start.dy),
        InkPoint(x: shape.end.dx, y: shape.end.dy),
      ],
      bounds: shape.bounds,
      shapeType: shape.type.name,
      fillStyle: _activeTool.fillStyle,
      fillColor: _activeTool.fillColor,
      roughness: _activeTool.roughness,
      seed: DateTime.now().microsecondsSinceEpoch % 10000,
    );

    _addStrokeToDocument(stroke);
    _isDrawing = false;
    _activePoints.clear();
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  /// Adds a standalone handwritten-style text element to the notebook page.
  void addTextElement(
    Offset position,
    String text, {
    double fontSize = 18.0,
    int? color,
  }) {
    if (text.trim().isEmpty) return;
    _recordUndoSnapshot();

    final strokeId = 'text_${DateTime.now().microsecondsSinceEpoch}';
    final stroke = InkStroke(
      id: strokeId,
      tool: InkToolType.text,
      color: color ?? _activeTool.color,
      baseWidth: 1.5,
      opacity: _activeTool.opacity,
      blendMode: 'srcOver',
      points: [InkPoint(x: position.dx, y: position.dy)],
      bounds: Rect.fromLTWH(position.dx, position.dy, 240, 40),
      shapeType: 'text',
      text: text,
      fontSize: fontSize,
      roughness: 0.0,
      seed: 123,
    );

    _addStrokeToDocument(stroke);
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void _addStrokeToDocument(InkStroke stroke, {bool isHighlighter = false}) {
    final targetLayerId = isHighlighter ? 'layer_highlighter' : 'layer_default';

    var layerFound = false;
    final updatedLayers = _document.layers.map((layer) {
      if (layer.id == targetLayerId) {
        layerFound = true;
        return layer.copyWith(strokes: [...layer.strokes, stroke]);
      }
      return layer;
    }).toList();

    if (!layerFound) {
      updatedLayers.add(
        InkLayer(
          id: targetLayerId,
          name: isHighlighter ? 'Highlighters' : 'Main Ink',
          blendMode: isHighlighter ? 'multiply' : 'srcOver',
          strokes: [stroke],
        ),
      );
    }

    _document = _document.copyWith(layers: updatedLayers);
  }

  void setBackgroundTemplate(String template) {
    if (_document.backgroundTemplate == template) return;
    _recordUndoSnapshot();
    _document = _document.copyWith(backgroundTemplate: template);
    _revision++;
    notifyListeners();
  }

  void eraseAt(Offset position, double radius) {
    bool mutated = false;
    final eraserRect = Rect.fromCircle(center: position, radius: radius);

    final updatedLayers = _document.layers.map((layer) {
      final remainingStrokes = <InkStroke>[];
      for (final stroke in layer.strokes) {
        if (stroke.computedBounds.overlaps(eraserRect)) {
          // Check proximity to any point in the stroke
          bool hit = false;
          for (final pt in stroke.points) {
            final dx = pt.x - position.dx;
            final dy = pt.y - position.dy;
            if (dx * dx + dy * dy <= radius * radius) {
              hit = true;
              mutated = true;
              break;
            }
          }
          if (!hit) {
            remainingStrokes.add(stroke);
          }
        } else {
          remainingStrokes.add(stroke);
        }
      }
      return layer.copyWith(strokes: remainingStrokes);
    }).toList();

    if (mutated) {
      _document = _document.copyWith(layers: updatedLayers);
      _revision++;
      _renderCache.invalidate();
      notifyListeners();
    }
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_document);
    _document = _undoStack.removeLast();
    _activePoints.clear();
    _lassoPolygon.clear();
    _selectedStrokeIds = {};
    _selectionBounds = null;
    _isDrawing = false;
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_document);
    _document = _redoStack.removeLast();
    _activePoints.clear();
    _lassoPolygon.clear();
    _selectedStrokeIds = {};
    _selectionBounds = null;
    _isDrawing = false;
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void clear() {
    _recordUndoSnapshot();
    final clearedLayers = _document.layers.map((layer) {
      return layer.copyWith(strokes: []);
    }).toList();
    _document = _document.copyWith(layers: clearedLayers);
    _activePoints.clear();
    _lassoPolygon.clear();
    _selectedStrokeIds = {};
    _selectionBounds = null;
    _isDrawing = false;
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  // --- Lasso Stroke Transformation Actions ---

  void clearSelection() {
    if (_selectedStrokeIds.isEmpty && _selectionBounds == null) return;
    _selectedStrokeIds = {};
    _selectionBounds = null;
    _lassoPolygon.clear();
    notifyListeners();
  }

  void recordSelectionUndoSnapshot() {
    _recordUndoSnapshot();
  }

  void translateSelectedStrokes(Offset delta, {bool recordUndo = false}) {
    if (_selectedStrokeIds.isEmpty || delta == Offset.zero) return;
    if (recordUndo) {
      _recordUndoSnapshot();
    }

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return StrokeTessellator.transformStroke(stroke, delta: delta);
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    if (_selectionBounds != null) {
      _selectionBounds = _selectionBounds!.shift(delta);
    }
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void scaleSelectedStrokes(
    double scaleX,
    double scaleY,
    Offset origin, {
    bool recordUndo = false,
  }) {
    if (_selectedStrokeIds.isEmpty) return;
    if (recordUndo) {
      _recordUndoSnapshot();
    }

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return StrokeTessellator.transformStroke(
            stroke,
            scaleX: scaleX,
            scaleY: scaleY,
            origin: origin,
          );
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _recomputeSelectionBounds();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void duplicateSelectedStrokes({Offset offset = const Offset(20, 20)}) {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final newSelectedIds = <String>{};
    int counter = 0;
    final nowMicro = DateTime.now().microsecondsSinceEpoch;

    final updatedLayers = _document.layers.map((layer) {
      final newStrokesInLayer = <InkStroke>[];
      for (final stroke in layer.strokes) {
        newStrokesInLayer.add(stroke);
        if (_selectedStrokeIds.contains(stroke.id)) {
          counter++;
          final newId = 's_${nowMicro}_dup_$counter';
          final dup = StrokeTessellator.transformStroke(
            stroke.copyWith(id: newId),
            delta: offset,
          );
          newStrokesInLayer.add(dup);
          newSelectedIds.add(newId);
        }
      }
      return layer.copyWith(strokes: newStrokesInLayer);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _selectedStrokeIds = newSelectedIds;
    _recomputeSelectionBounds();
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void recolorSelectedStrokes(int newColor) {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return stroke.copyWith(color: newColor);
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void updateSelectedShapesStyle({
    String? fillStyle,
    int? fillColor,
    double? roughness,
    String? strokeStyle,
  }) {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return stroke.copyWith(
            fillStyle: fillStyle ?? stroke.fillStyle,
            fillColor: fillColor ?? stroke.fillColor,
            roughness: roughness ?? stroke.roughness,
            strokeStyle: strokeStyle ?? stroke.strokeStyle,
          );
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void deleteSelectedStrokes() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final remaining = layer.strokes
          .where((s) => !_selectedStrokeIds.contains(s.id))
          .toList();
      return layer.copyWith(strokes: remaining);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _selectedStrokeIds = {};
    _selectionBounds = null;
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void _recomputeSelectionBounds() {
    if (_selectedStrokeIds.isEmpty) {
      _selectionBounds = null;
      return;
    }
    final selected = selectedStrokes;
    if (selected.isEmpty) {
      _selectionBounds = null;
    } else {
      _selectionBounds = StrokeTessellator.computeEnclosingBounds(selected);
    }
  }

  void _recordUndoSnapshot() {
    _undoStack.add(_document);
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0); // Cap history depth to 50 snapshots
    }
  }

  @override
  void dispose() {
    _renderCache.dispose();
    super.dispose();
  }
}
