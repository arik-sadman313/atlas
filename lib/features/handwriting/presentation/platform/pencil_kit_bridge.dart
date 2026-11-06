import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pencil_kit/pencil_kit.dart';

import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';
import 'ink_platform_service.dart';

class PencilKitBridge implements InkPlatformService {
  PencilKitController? _pencilKitController;
  InkCanvasController? _atlasController;

  @override
  bool get isNativePencilKitAvailable => Platform.isIOS;

  void attachPencilKitController(PencilKitController controller) {
    _pencilKitController = controller;
  }

  @override
  void attachController(InkCanvasController controller) {
    _atlasController = controller;
  }

  @override
  void setTool(InkToolConfig tool) {
    _atlasController?.setTool(tool);
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

  Future<String?> exportBase64Png() async {
    if (!isNativePencilKitAvailable || _pencilKitController == null) {
      return null;
    }
    return await _pencilKitController?.getBase64PngData();
  }

  @override
  void dispose() {
    _pencilKitController = null;
    _atlasController = null;
  }
}
