import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';
import 'ink_platform_service.dart';

class DartVectorInkService implements InkPlatformService {
  InkCanvasController? _controller;

  @override
  bool get isNativePencilKitAvailable => false;

  @override
  void attachController(InkCanvasController controller) {
    _controller = controller;
  }

  @override
  void setTool(InkToolConfig tool) {
    _controller?.setTool(tool);
  }

  @override
  void undo() {
    _controller?.undo();
  }

  @override
  void redo() {
    _controller?.redo();
  }

  @override
  void clear() {
    _controller?.clear();
  }

  @override
  void dispose() {
    _controller = null;
  }
}
