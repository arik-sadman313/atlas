import Flutter
import UIKit
import PencilKit

/// Native iPadOS PencilKit bridge providing sub-10ms hardware latency,
/// Apple Pencil pressure/tilt/azimuth telemetry, and bidirectional
/// serialization between Apple PKDrawing and the ATLAS portable ink format.
@available(iOS 14.0, *)
public class AtlasPencilKitView: NSObject, FlutterPlatformView, PKCanvasViewDelegate {
    private var canvasView: PKCanvasView
    private var toolPicker: PKToolPicker?
    private var channel: FlutterMethodChannel
    
    public init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        self.canvasView = PKCanvasView(frame: frame)
        self.channel = FlutterMethodChannel(name: "com.atlas.pencilkit_\(viewId)", binaryMessenger: messenger)
        super.init()
        
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        toolPicker = PKToolPicker()
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        toolPicker?.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        setupMethodChannel()
        
        // Initial drawing rehydration if bytes were passed
        if let pkBytes = args?["pkDrawingBytes"] as? FlutterStandardTypedData {
            do {
                canvasView.drawing = try PKDrawing(data: pkBytes.data)
            } catch {
                print("AtlasPencilKitView: Failed to decode initial PKDrawing data: \(error)")
            }
        }
    }
    
    public func view() -> UIView {
        return canvasView
    }
    
    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "exportDrawing":
                self.exportDrawing(result: result)
            case "loadDrawing":
                if let args = call.arguments as? [String: Any],
                   let typedData = args["pkDrawingBytes"] as? FlutterStandardTypedData {
                    do {
                        self.canvasView.drawing = try PKDrawing(data: typedData.data)
                        result(true)
                    } catch {
                        result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                    }
                } else {
                    result(false)
                }
            case "undo":
                self.canvasView.undoManager?.undo()
                result(true)
            case "redo":
                self.canvasView.undoManager?.redo()
                result(true)
            case "clear":
                self.canvasView.drawing = PKDrawing()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func exportDrawing(result: @escaping FlutterResult) {
        let drawing = canvasView.drawing
        
        // 1. Apple native binary representation
        let pkData = drawing.dataRepresentation()
        
        // 2. High-resolution raster preview
        let bounds = canvasView.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 1600, height: 2200) : canvasView.bounds
        let image = drawing.image(from: bounds, scale: 2.0)
        let pngData = image.pngData() ?? Data()
        
        // 3. Extract portable vector strokes and point telemetry
        var portableStrokes: [[String: Any]] = []
        for stroke in drawing.strokes {
            var points: [[String: Any]] = []
            for pt in stroke.path {
                points.append([
                    "x": Double(pt.location.x),
                    "y": Double(pt.location.y),
                    "pressure": Double(pt.force),
                    "tiltAzimuth": Double(pt.azimuth),
                    "tiltAltitude": Double(pt.altitude),
                    "timeOffsetMs": Int((pt.timeOffset) * 1000.0)
                ])
            }
            
            let colorInt = stroke.ink.color.toArgbInt()
            let toolStr = mapInkTypeToString(stroke.ink.inkType)
            
            portableStrokes.append([
                "id": UUID().uuidString,
                "tool": toolStr,
                "color": colorInt,
                "baseWidth": Double(stroke.ink.weight),
                "opacity": 1.0,
                "blendMode": toolStr == "highlighter" ? "multiply" : "srcOver",
                "points": points
            ])
        }
        
        result([
            "pkDrawingBytes": FlutterStandardTypedData(bytes: pkData),
            "pngPreviewBytes": FlutterStandardTypedData(bytes: pngData),
            "portableStrokes": portableStrokes
        ])
    }
    
    private func mapInkTypeToString(_ inkType: PKInk.InkType) -> String {
        switch inkType {
        case .pen:
            return "ballpointPen"
        case .marker:
            return "highlighter"
        case .pencil:
            return "pencil"
        default:
            return "ballpointPen"
        }
    }
}

extension UIColor {
    func toArgbInt() -> Int64 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let a = Int64(alpha * 255.0) & 0xFF
        let r = Int64(red * 255.0) & 0xFF
        let g = Int64(green * 255.0) & 0xFF
        let b = Int64(blue * 255.0) & 0xFF
        
        return (a << 24) | (r << 16) | (g << 8) | b
    }
}
