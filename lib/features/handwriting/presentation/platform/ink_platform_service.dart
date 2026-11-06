import '../controllers/ink_canvas_controller.dart';
import '../../domain/models/ink_tool.dart';

abstract class InkPlatformService {
  bool get isNativePencilKitAvailable;

  void attachController(InkCanvasController controller);

  void setTool(InkToolConfig tool);

  void undo();

  void redo();

  void clear();

  void dispose();
}
