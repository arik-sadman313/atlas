import 'dart:ui';

import 'package:flutter/foundation.dart';

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

  void loadDocument(AtlasInkDocument doc) {
    _document = doc;
    _undoStack.clear();
    _redoStack.clear();
    _activePoints.clear();
    _isDrawing = false;
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void setTool(InkToolConfig tool) {
    _activeTool = tool;
    notifyListeners();
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
    if (!_isDrawing || _activePoints.isEmpty) {
      _isDrawing = false;
      _activePoints.clear();
      return;
    }

    _recordUndoSnapshot();

    final strokeId = 's_${DateTime.now().microsecondsSinceEpoch}';
    final isHighlighter = _activeTool.type.isHighlighter;

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

    // Commit to appropriate layer (highlighters on highlighter layer)
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
    _isDrawing = false;
    _activePoints.clear();
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
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
          final hitsPoint = stroke.points.any((p) {
            final dx = p.x - position.dx;
            final dy = p.y - position.dy;
            return (dx * dx + dy * dy) <= (radius * radius);
          });

          if (hitsPoint) {
            mutated = true;
            continue; // Stroke erased!
          }
        }
        remainingStrokes.add(stroke);
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
    _isDrawing = false;
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
  }

  void clear() {
    if (_document.isEmpty) return;
    _recordUndoSnapshot();
    final clearedLayers = _document.layers
        .map((layer) => layer.copyWith(strokes: const []))
        .toList();
    _document = _document.copyWith(layers: clearedLayers);
    _activePoints.clear();
    _isDrawing = false;
    _redoStack.clear();
    _revision++;
    _renderCache.invalidate();
    notifyListeners();
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
