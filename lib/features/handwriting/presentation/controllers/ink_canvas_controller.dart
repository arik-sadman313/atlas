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

  // Lasso / Box selection state
  final List<Offset> _lassoPolygon = [];
  Set<String> _selectedStrokeIds = {};
  Rect? _selectionBounds;

  // Grid & Snapping
  bool _snapToGrid = false;
  final double _gridSize = 20.0;

  bool get snapToGrid => _snapToGrid;
  double get gridSize => _gridSize;

  void toggleSnapToGrid() {
    _snapToGrid = !_snapToGrid;
    notifyListeners();
  }

  Offset snapPoint(Offset pt) {
    if (!_snapToGrid) return pt;
    return Offset(
      (pt.dx / _gridSize).round() * _gridSize,
      (pt.dy / _gridSize).round() * _gridSize,
    );
  }

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
    if (!tool.type.isSelection &&
        !tool.type.isLasso &&
        _selectedStrokeIds.isNotEmpty) {
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
    if (_activeTool.type.isPan) return;

    if (_activeTool.type.isEraser) {
      _recordUndoSnapshot();
      eraseAt(position, _activeTool.baseWidth * 3);
      return;
    }

    if (_activeTool.type.isSelection || _activeTool.type.isLasso) {
      final hitId = hitTestStroke(position);
      if (hitId != null) {
        if (!_selectedStrokeIds.contains(hitId)) {
          _selectedStrokeIds = {hitId};
          _recomputeSelectionBounds();
          notifyListeners();
        }
        return;
      }

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
    final startPt = snapPoint(position);
    _activePoints.clear();
    _activePoints.add(
      InkPoint(
        x: startPt.dx,
        y: startPt.dy,
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
    if (_activeTool.type.isPan) return;

    if (_activeTool.type.isEraser) {
      eraseAt(position, _activeTool.baseWidth * 3);
      return;
    }

    if (_activeTool.type.isSelection || _activeTool.type.isLasso) {
      if (!_isDrawing) return;
      _lassoPolygon.add(position);
      notifyListeners();
      return;
    }

    if (!_isDrawing) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final curPt = _activeTool.type.isShape ? snapPoint(position) : position;
    _activePoints.add(
      InkPoint(
        x: curPt.dx,
        y: curPt.dy,
        pressure: pressure,
        tiltAzimuth: tiltAzimuth,
        tiltAltitude: tiltAltitude,
        timeOffsetMs: now - _strokeStartTime,
      ),
    );
    notifyListeners();
  }

  void endStroke() {
    if (_activeTool.type.isSelection || _activeTool.type.isLasso) {
      if (!_isDrawing) return;
      _isDrawing = false;
      if (_lassoPolygon.length >= 2) {
        final selected = <String>{};
        if (_lassoPolygon.length >= 3) {
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
        } else {
          final box = Rect.fromPoints(_lassoPolygon.first, _lassoPolygon.last);
          for (final layer in _document.layers) {
            for (final stroke in layer.strokes) {
              if (stroke.computedBounds.overlaps(box)) {
                selected.add(stroke.id);
              }
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
        roundness: _activeTool.roundness,
        startArrowhead: _activeTool.startArrowhead,
        endArrowhead: _activeTool.endArrowhead,
        isCurved:
            _activeTool.isCurved || _activeTool.type == InkToolType.curvedArrow,
        fontFamily: _activeTool.fontFamily,
        textAlign: _activeTool.textAlign,
        fontSize: _activeTool.fontSize,
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

  String? hitTestStroke(Offset position) {
    for (final layer in _document.layers.reversed) {
      if (!layer.visible) continue;
      for (final stroke in layer.strokes.reversed) {
        if (stroke.computedBounds.inflate(10.0).contains(position)) {
          return stroke.id;
        }
      }
    }
    return null;
  }

  void selectStroke(String strokeId, {bool multiSelect = false}) {
    if (multiSelect) {
      if (_selectedStrokeIds.contains(strokeId)) {
        _selectedStrokeIds.remove(strokeId);
      } else {
        _selectedStrokeIds.add(strokeId);
      }
    } else {
      _selectedStrokeIds = {strokeId};
    }
    _recomputeSelectionBounds();
    notifyListeners();
  }

  void selectAll() {
    final allIds = <String>{};
    for (final layer in _document.layers) {
      for (final s in layer.strokes) {
        allIds.add(s.id);
      }
    }
    _selectedStrokeIds = allIds;
    _recomputeSelectionBounds();
    notifyListeners();
  }

  void resizeSelectedStrokes(Rect newBounds, {bool recordUndo = false}) {
    if (_selectionBounds == null || _selectedStrokeIds.isEmpty) return;
    if (_selectionBounds!.width <= 0 || _selectionBounds!.height <= 0) return;
    if (recordUndo) _recordUndoSnapshot();

    final scaleX = newBounds.width / _selectionBounds!.width;
    final scaleY = newBounds.height / _selectionBounds!.height;
    final origin = _selectionBounds!.topLeft;
    final delta = newBounds.topLeft - origin;

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return StrokeTessellator.transformStroke(
            stroke,
            scaleX: scaleX,
            scaleY: scaleY,
            delta: delta,
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

  void rotateSelectedStrokes(
    double deltaAngle,
    Offset origin, {
    bool recordUndo = false,
  }) {
    if (_selectedStrokeIds.isEmpty) return;
    if (recordUndo) _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return StrokeTessellator.transformStroke(
            stroke,
            deltaAngle: deltaAngle,
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

  void bringToFront() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final unselected = <InkStroke>[];
      final selected = <InkStroke>[];
      for (final s in layer.strokes) {
        if (_selectedStrokeIds.contains(s.id)) {
          selected.add(s);
        } else {
          unselected.add(s);
        }
      }
      return layer.copyWith(strokes: [...unselected, ...selected]);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void sendToBack() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final unselected = <InkStroke>[];
      final selected = <InkStroke>[];
      for (final s in layer.strokes) {
        if (_selectedStrokeIds.contains(s.id)) {
          selected.add(s);
        } else {
          unselected.add(s);
        }
      }
      return layer.copyWith(strokes: [...selected, ...unselected]);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void bringForward() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final list = List<InkStroke>.from(layer.strokes);
      for (int i = list.length - 2; i >= 0; i--) {
        if (_selectedStrokeIds.contains(list[i].id) &&
            !_selectedStrokeIds.contains(list[i + 1].id)) {
          final temp = list[i];
          list[i] = list[i + 1];
          list[i + 1] = temp;
        }
      }
      return layer.copyWith(strokes: list);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void sendBackward() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final list = List<InkStroke>.from(layer.strokes);
      for (int i = 1; i < list.length; i++) {
        if (_selectedStrokeIds.contains(list[i].id) &&
            !_selectedStrokeIds.contains(list[i - 1].id)) {
          final temp = list[i];
          list[i] = list[i - 1];
          list[i - 1] = temp;
        }
      }
      return layer.copyWith(strokes: list);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void groupSelectedStrokes() {
    if (_selectedStrokeIds.length < 2) return;
    _recordUndoSnapshot();

    final newGroupId = 'grp_${DateTime.now().microsecondsSinceEpoch}';
    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return stroke.copyWith(groupId: newGroupId);
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void ungroupSelectedStrokes() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return stroke.copyWith(clearGroupId: true);
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void alignSelectedStrokes(String alignment) {
    if (_selectedStrokeIds.length < 2 || _selectionBounds == null) return;
    _recordUndoSnapshot();

    final targetBounds = _selectionBounds!;
    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (!_selectedStrokeIds.contains(stroke.id)) return stroke;
        final b = stroke.computedBounds;
        Offset delta = Offset.zero;

        switch (alignment) {
          case 'left':
            delta = Offset(targetBounds.left - b.left, 0);
            break;
          case 'center':
            delta = Offset(targetBounds.center.dx - b.center.dx, 0);
            break;
          case 'right':
            delta = Offset(targetBounds.right - b.right, 0);
            break;
          case 'top':
            delta = Offset(0, targetBounds.top - b.top);
            break;
          case 'middle':
            delta = Offset(0, targetBounds.center.dy - b.center.dy);
            break;
          case 'bottom':
            delta = Offset(0, targetBounds.bottom - b.bottom);
            break;
        }

        return StrokeTessellator.transformStroke(stroke, delta: delta);
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _recomputeSelectionBounds();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void distributeSelectedStrokes(String direction) {
    if (_selectedStrokeIds.length < 3) return;
    _recordUndoSnapshot();

    final selected = selectedStrokes;
    if (direction == 'horizontal') {
      selected.sort(
        (a, b) => a.computedBounds.left.compareTo(b.computedBounds.left),
      );
      final minX = selected.first.computedBounds.left;
      final maxX = selected.last.computedBounds.left;
      final step = (maxX - minX) / (selected.length - 1);

      final deltaMap = <String, Offset>{};
      for (int i = 0; i < selected.length; i++) {
        final targetX = minX + i * step;
        final curX = selected[i].computedBounds.left;
        deltaMap[selected[i].id] = Offset(targetX - curX, 0);
      }

      final updatedLayers = _document.layers.map((layer) {
        final updatedStrokes = layer.strokes.map((stroke) {
          if (deltaMap.containsKey(stroke.id)) {
            return StrokeTessellator.transformStroke(
              stroke,
              delta: deltaMap[stroke.id]!,
            );
          }
          return stroke;
        }).toList();
        return layer.copyWith(strokes: updatedStrokes);
      }).toList();

      _document = _document.copyWith(layers: updatedLayers);
    } else {
      selected.sort(
        (a, b) => a.computedBounds.top.compareTo(b.computedBounds.top),
      );
      final minY = selected.first.computedBounds.top;
      final maxY = selected.last.computedBounds.top;
      final step = (maxY - minY) / (selected.length - 1);

      final deltaMap = <String, Offset>{};
      for (int i = 0; i < selected.length; i++) {
        final targetY = minY + i * step;
        final curY = selected[i].computedBounds.top;
        deltaMap[selected[i].id] = Offset(0, targetY - curY);
      }

      final updatedLayers = _document.layers.map((layer) {
        final updatedStrokes = layer.strokes.map((stroke) {
          if (deltaMap.containsKey(stroke.id)) {
            return StrokeTessellator.transformStroke(
              stroke,
              delta: deltaMap[stroke.id]!,
            );
          }
          return stroke;
        }).toList();
        return layer.copyWith(strokes: updatedStrokes);
      }).toList();

      _document = _document.copyWith(layers: updatedLayers);
    }

    _recomputeSelectionBounds();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void flipSelectedStrokesHorizontal() {
    if (_selectedStrokeIds.isEmpty || _selectionBounds == null) return;
    _recordUndoSnapshot();

    final center = _selectionBounds!.center;
    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return StrokeTessellator.transformStroke(
            stroke,
            scaleX: -1.0,
            origin: center,
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

  void flipSelectedStrokesVertical() {
    if (_selectedStrokeIds.isEmpty || _selectionBounds == null) return;
    _recordUndoSnapshot();

    final center = _selectionBounds!.center;
    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return StrokeTessellator.transformStroke(
            stroke,
            scaleY: -1.0,
            origin: center,
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

  void toggleLockSelectedStrokes() {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return stroke.copyWith(isLocked: !stroke.isLocked);
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void addStickyNote(Offset position, String text, {int? bgColor}) {
    _recordUndoSnapshot();
    final strokeId = 'note_${DateTime.now().microsecondsSinceEpoch}';
    final snapped = snapPoint(position);
    final bounds = Rect.fromLTWH(snapped.dx, snapped.dy, 180, 180);

    final stroke = InkStroke(
      id: strokeId,
      tool: InkToolType.stickyNote,
      color: 0xFF18181B,
      baseWidth: 1.5,
      opacity: 1.0,
      points: [
        InkPoint(x: bounds.left, y: bounds.top),
        InkPoint(x: bounds.right, y: bounds.bottom),
      ],
      bounds: bounds,
      shapeType: 'stickyNote',
      fillColor: bgColor ?? 0xFFFFF9B1,
      fillStyle: 'solid',
      roughness: 1.0,
      text: text,
      fontSize: 16.0,
      seed: DateTime.now().microsecondsSinceEpoch % 10000,
    );

    _addStrokeToDocument(stroke);
    _selectedStrokeIds = {strokeId};
    _recomputeSelectionBounds();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void addFrame(Rect bounds, String title) {
    _recordUndoSnapshot();
    final strokeId = 'frame_${DateTime.now().microsecondsSinceEpoch}';

    final stroke = InkStroke(
      id: strokeId,
      tool: InkToolType.frame,
      color: 0xFF6366F1,
      baseWidth: 2.0,
      opacity: 1.0,
      points: [
        InkPoint(x: bounds.left, y: bounds.top),
        InkPoint(x: bounds.right, y: bounds.bottom),
      ],
      bounds: bounds,
      shapeType: 'frame',
      strokeStyle: 'dashed',
      roughness: 0.5,
      text: title,
      seed: 888,
    );

    _addStrokeToDocument(stroke);
    _selectedStrokeIds = {strokeId};
    _recomputeSelectionBounds();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void updateSelectedStrokesStyle({
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
  }) {
    if (_selectedStrokeIds.isEmpty) return;
    _recordUndoSnapshot();

    final updatedLayers = _document.layers.map((layer) {
      final updatedStrokes = layer.strokes.map((stroke) {
        if (_selectedStrokeIds.contains(stroke.id)) {
          return stroke.copyWith(
            color: color ?? stroke.color,
            baseWidth: baseWidth ?? stroke.baseWidth,
            opacity: opacity ?? stroke.opacity,
            fillStyle: fillStyle ?? stroke.fillStyle,
            fillColor: fillColor ?? stroke.fillColor,
            roughness: roughness ?? stroke.roughness,
            strokeStyle: strokeStyle ?? stroke.strokeStyle,
            roundness: roundness ?? stroke.roundness,
            startArrowhead: startArrowhead ?? stroke.startArrowhead,
            endArrowhead: endArrowhead ?? stroke.endArrowhead,
            fontFamily: fontFamily ?? stroke.fontFamily,
            textAlign: textAlign ?? stroke.textAlign,
            fontSize: fontSize ?? stroke.fontSize,
          );
        }
        return stroke;
      }).toList();
      return layer.copyWith(strokes: updatedStrokes);
    }).toList();

    _document = _document.copyWith(layers: updatedLayers);
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
    updateSelectedStrokesStyle(
      fillStyle: fillStyle,
      fillColor: fillColor,
      roughness: roughness,
      strokeStyle: strokeStyle,
    );
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
