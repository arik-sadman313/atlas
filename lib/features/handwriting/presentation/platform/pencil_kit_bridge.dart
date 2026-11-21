import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pencil_kit/pencil_kit.dart';

import '../../domain/interop/pencil_kit_converter.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';
import 'ink_platform_service.dart';

/// Platform bridge connecting ATLAS ink architecture to native Apple PencilKit.
class PencilKitBridge implements InkPlatformService {
  static const MethodChannel _interopChannel = MethodChannel(
    'com.atlas/pencil_kit_interop',
  );

  PencilKitController? _pencilKitController;
  InkCanvasController? _atlasController;
  InkToolConfig? _toolBeforeEraser;

  @override
  bool get isNativePencilKitAvailable =>
      defaultTargetPlatform == TargetPlatform.iOS;

  PencilKitController? get pencilKitController => _pencilKitController;

  void initializeMethodChannel() {
    _interopChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onApplePencilDoubleTap':
      case 'onApplePencilSqueeze':
        _handlePencilDoubleTap();
        break;
    }
  }

  void _handlePencilDoubleTap() {
    if (_atlasController == null) return;
    final active = _atlasController!.activeTool;
    if (active.type.isEraser) {
      final restore =
          _toolBeforeEraser ??
          active.copyWith(
            type: InkToolType.ballpointPen,
            baseWidth: 3.0,
            opacity: 1.0,
          );
      _atlasController!.setTool(restore);
    } else {
      _toolBeforeEraser = active;
      _atlasController!.setTool(
        active.copyWith(type: InkToolType.vectorEraser, baseWidth: 16.0),
      );
    }
  }

  void attachPencilKitController(PencilKitController controller) {
    _pencilKitController = controller;
  }

  @override
  void attachController(InkCanvasController controller) {
    _atlasController = controller;
  }

  @override
  void setTool(InkToolConfig tool) {
    if (_atlasController != null && _atlasController!.activeTool != tool) {
      _atlasController!.setTool(tool);
    }
    if (!isNativePencilKitAvailable || _pencilKitController == null) return;

    final toolColor = Color(tool.color);

    if (tool.type == InkToolType.highlighter) {
      _pencilKitController?.setPKTool(
        toolType: ToolType.marker,
        width: tool.baseWidth,
        color: toolColor,
      );
    } else if (tool.type == InkToolType.fountainPen) {
      _pencilKitController?.setPKTool(
        toolType: ToolType.fountainPen,
        width: tool.baseWidth,
        color: toolColor,
      );
    } else if (tool.type == InkToolType.pencil) {
      _pencilKitController?.setPKTool(
        toolType: ToolType.pencil,
        width: tool.baseWidth,
        color: toolColor,
      );
    } else if (tool.type.isEraser) {
      _pencilKitController?.setPKTool(toolType: ToolType.eraserVector);
    } else {
      _pencilKitController?.setPKTool(
        toolType: ToolType.pen,
        width: tool.baseWidth,
        color: toolColor,
      );
    }
  }

  @override
  void undo() {
    if (isNativePencilKitAvailable && _pencilKitController != null) {
      _pencilKitController?.undo();
    } else {
      _atlasController?.undo();
    }
  }

  @override
  void redo() {
    if (isNativePencilKitAvailable && _pencilKitController != null) {
      _pencilKitController?.redo();
    } else {
      _atlasController?.redo();
    }
  }

  @override
  void clear() {
    if (isNativePencilKitAvailable && _pencilKitController != null) {
      _pencilKitController?.clear();
    } else {
      _atlasController?.clear();
    }
  }

  /// Exports the native PKDrawing binary representation as base64.
  Future<String?> getBase64Data() async {
    if (!isNativePencilKitAvailable || _pencilKitController == null) {
      return null;
    }
    return await _pencilKitController?.getBase64Data();
  }

  /// Exports the native PKDrawing binary representation as raw bytes.
  Future<Uint8List?> exportRawPencilKitBytes() async {
    final b64 = await getBase64Data();
    if (b64 == null || b64.isEmpty) return null;
    return base64Decode(b64);
  }

  /// Exports a 2.0x high-resolution raster PNG preview.
  Future<String?> exportBase64Png({double scale = 2.0}) async {
    if (!isNativePencilKitAvailable || _pencilKitController == null) {
      return null;
    }
    return await _pencilKitController?.getBase64PngData(scale: scale);
  }

  /// Exports the raster PNG preview as raw bytes.
  Future<Uint8List?> exportPngBytes({double scale = 2.0}) async {
    final b64 = await exportBase64Png(scale: scale);
    if (b64 == null || b64.isEmpty) return null;
    return base64Decode(b64);
  }

  /// Loads an existing PKDrawing into the canvas from base64 string.
  Future<void> loadBase64Data(String base64Data) async {
    if (!isNativePencilKitAvailable || _pencilKitController == null) return;
    await _pencilKitController?.loadBase64Data(base64Data);
  }

  /// Loads an existing PKDrawing into the canvas from raw bytes.
  Future<void> loadRawPencilKitBytes(Uint8List bytes) async {
    final b64 = base64Encode(bytes);
    await loadBase64Data(b64);
  }

  /// Converts ATLAS portable ink document strokes to native Apple PKDrawing bytes via the Swift bridge.
  Future<Uint8List?> convertPortableDocToPkDrawing(AtlasInkDocument doc) async {
    if (!isNativePencilKitAvailable) return null;
    try {
      final strokes = PencilKitConverter.documentToPencilKitStrokes(doc);
      final result = await _interopChannel.invokeMethod<Uint8List>(
        'convertPortableToPkData',
        {'portableStrokes': strokes},
      );
      return result;
    } catch (e) {
      debugPrint('Error converting portable ink to PKDrawing: $e');
      return null;
    }
  }

  /// Converts native Apple PKDrawing bytes to ATLAS portable ink document via the Swift bridge.
  Future<AtlasInkDocument?> convertPkDrawingToPortableDoc({
    required Uint8List pkBytes,
    required String documentId,
    required int pageNumber,
    double width = 1600.0,
    double height = 2200.0,
    String backgroundTemplate = 'ruled',
    int backgroundColor = 0xFFFFFFFF,
  }) async {
    if (!isNativePencilKitAvailable) return null;
    try {
      final rawStrokes = await _interopChannel.invokeListMethod<dynamic>(
        'convertPkDataToPortable',
        {'pkDrawingBytes': pkBytes},
      );
      if (rawStrokes == null) return null;
      final strokesList = rawStrokes
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      return PencilKitConverter.pencilKitStrokesToDocument(
        strokesList,
        documentId: documentId,
        pageNumber: pageNumber,
        width: width,
        height: height,
        backgroundTemplate: backgroundTemplate,
        backgroundColor: backgroundColor,
      );
    } catch (e) {
      debugPrint('Error converting PKDrawing to portable ink: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _pencilKitController = null;
    _atlasController = null;
  }
}
