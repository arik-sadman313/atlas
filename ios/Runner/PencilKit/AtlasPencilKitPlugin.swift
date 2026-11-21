import Flutter
import UIKit
import PencilKit

/// Native iPadOS PencilKit interop plugin providing bidirectional serialization
/// between Apple PKDrawing and the ATLAS portable ink format.
@available(iOS 14.0, *)
public class AtlasPencilKitPlugin: NSObject, FlutterPlugin, UIPencilInteractionDelegate {
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.atlas/pencil_kit_interop",
            binaryMessenger: registrar.messenger()
        )
        let instance = AtlasPencilKitPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Wire Apple Pencil 2 & Apple Pencil Pro hardware gestures
        DispatchQueue.main.async {
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                let interaction = UIPencilInteraction()
                interaction.delegate = instance
                rootVC.view.addInteraction(interaction)
            }
        }
    }

    public func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        channel?.invokeMethod("onApplePencilDoubleTap", arguments: [
            "preferredAction": UIPencilInteraction.preferredAction.rawValue
        ])
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "convertPortableToPkData":
            guard let args = call.arguments as? [String: Any],
                  let portableStrokes = args["portableStrokes"] as? [[String: Any]] else {
                result(FlutterError(code: "INVALID_ARGS", message: "portableStrokes expected", details: nil))
                return
            }
            let drawing = AtlasPencilKitInterop.constructDrawing(from: portableStrokes)
            let pkData = drawing.dataRepresentation()
            result(FlutterStandardTypedData(bytes: pkData))

        case "convertPkDataToPortable":
            guard let args = call.arguments as? [String: Any],
                  let pkBytes = args["pkDrawingBytes"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "pkDrawingBytes expected", details: nil))
                return
            }
            do {
                let drawing = try PKDrawing(data: pkBytes.data)
                let strokes = AtlasPencilKitInterop.extractPortableStrokes(from: drawing)
                result(strokes)
            } catch {
                result(FlutterError(code: "DECODE_ERROR", message: error.localizedDescription, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

/// Shared bidirectional serialization logic between PKDrawing and ATLAS portable ink.
@available(iOS 14.0, *)
public enum AtlasPencilKitInterop {
    /// Constructs a native PKDrawing from an array of ATLAS portable ink stroke dictionaries.
    public static func constructDrawing(from portableStrokes: [[String: Any]]) -> PKDrawing {
        var pkStrokes: [PKStroke] = []
        let now = Date()

        for strokeDict in portableStrokes {
            guard let pointsArray = strokeDict["points"] as? [[String: Any]], !pointsArray.isEmpty else {
                continue
            }

            let toolStr = strokeDict["tool"] as? String ?? "ballpointPen"
            let colorInt = strokeDict["color"] as? Int64 ?? 0xFF18181B
            let baseWidth = CGFloat(strokeDict["baseWidth"] as? Double ?? 3.0)
            let opacity = CGFloat(strokeDict["opacity"] as? Double ?? 1.0)

            let inkType: PKInk.InkType
            var effectiveWidth = baseWidth
            switch toolStr.lowercased() {
            case "highlighter", "marker":
                inkType = .marker
            case "pencil":
                inkType = .pencil
            case "fountainpen":
                inkType = .pen
                effectiveWidth = baseWidth * 1.2
            case "ballpointpen", "pen":
                inkType = .pen
            default:
                // Graceful fallback for unsupported or custom tool types
                inkType = .pen
            }

            let a = CGFloat((colorInt >> 24) & 0xFF) / 255.0 * opacity
            let r = CGFloat((colorInt >> 16) & 0xFF) / 255.0
            let g = CGFloat((colorInt >> 8) & 0xFF) / 255.0
            let b = CGFloat(colorInt & 0xFF) / 255.0
            let uiColor = UIColor(red: r, green: g, blue: b, alpha: a)

            var strokePoints: [PKStrokePoint] = []

            for ptDict in pointsArray {
                let x = CGFloat(ptDict["x"] as? Double ?? 0.0)
                let y = CGFloat(ptDict["y"] as? Double ?? 0.0)
                let pressure = CGFloat(ptDict["pressure"] as? Double ?? 0.5)
                let azimuth = CGFloat(ptDict["tiltAzimuth"] as? Double ?? 0.0)
                let altitude = CGFloat(ptDict["tiltAltitude"] as? Double ?? (Double.pi / 2.0))
                let timeOffsetMs = ptDict["timeOffsetMs"] as? Double ?? 0.0

                let pt = PKStrokePoint(
                    location: CGPoint(x: x, y: y),
                    timeOffset: TimeInterval(timeOffsetMs / 1000.0),
                    size: CGSize(width: effectiveWidth, height: effectiveWidth),
                    opacity: opacity,
                    force: max(0.01, min(1.0, pressure)),
                    azimuth: azimuth,
                    altitude: altitude
                )
                strokePoints.append(pt)
            }

            // Single-point strokes (dots): synthesize a tiny offset point to prevent PKStrokePath from discarding it
            if strokePoints.count == 1 {
                let first = strokePoints[0]
                let second = PKStrokePoint(
                    location: CGPoint(x: first.location.x + 0.1, y: first.location.y + 0.1),
                    timeOffset: first.timeOffset + 0.001,
                    size: first.size,
                    opacity: first.opacity,
                    force: first.force,
                    azimuth: first.azimuth,
                    altitude: first.altitude
                )
                strokePoints.append(second)
            }

            let strokePath = PKStrokePath(controlPoints: strokePoints, creationDate: now)
            let ink = PKInk(inkType, color: uiColor)
            let stroke = PKStroke(ink: ink, path: strokePath, transform: .identity, mask: nil)
            pkStrokes.append(stroke)
        }

        return PKDrawing(strokes: pkStrokes)
    }

    /// Extracts portable vector stroke dictionaries from a native PKDrawing.
    public static func extractPortableStrokes(from drawing: PKDrawing) -> [[String: Any]] {
        var portableStrokes: [[String: Any]] = []

        for stroke in drawing.strokes {
            var points: [[String: Any]] = []
            var detectedWidth: Double = 3.0
            for pt in stroke.path {
                detectedWidth = Double(pt.size.width)
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
                "baseWidth": detectedWidth,
                "opacity": 1.0,
                "blendMode": toolStr == "highlighter" ? "multiply" : "srcOver",
                "points": points
            ])
        }

        return portableStrokes
    }

    public static func mapInkTypeToString(_ inkType: PKInk.InkType) -> String {
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

/// Native iPadOS PKCanvasView platform view.
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

        // 1. Initial native drawing rehydration if raw bytes were passed
        if let pkBytes = args?["pkDrawingBytes"] as? FlutterStandardTypedData {
            do {
                canvasView.drawing = try PKDrawing(data: pkBytes.data)
            } catch {
                print("AtlasPencilKitView: Failed to decode initial PKDrawing data: \(error)")
            }
        } else if let portableStrokes = args?["portableStrokes"] as? [[String: Any]], !portableStrokes.isEmpty {
            // 2. Fallback: reconstruct PKDrawing from portable ink strokes
            canvasView.drawing = AtlasPencilKitInterop.constructDrawing(from: portableStrokes)
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
                if let args = call.arguments as? [String: Any] {
                    if let typedData = args["pkDrawingBytes"] as? FlutterStandardTypedData {
                        do {
                            self.canvasView.drawing = try PKDrawing(data: typedData.data)
                            result(true)
                            return
                        } catch {
                            result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
                            return
                        }
                    } else if let portableStrokes = args["portableStrokes"] as? [[String: Any]] {
                        self.canvasView.drawing = AtlasPencilKitInterop.constructDrawing(from: portableStrokes)
                        result(true)
                        return
                    }
                }
                result(false)

            case "loadPortableStrokes":
                if let args = call.arguments as? [String: Any],
                   let portableStrokes = args["portableStrokes"] as? [[String: Any]] {
                    self.canvasView.drawing = AtlasPencilKitInterop.constructDrawing(from: portableStrokes)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "portableStrokes array expected", details: nil))
                }

            case "convertPortableToPkData":
                if let args = call.arguments as? [String: Any],
                   let portableStrokes = args["portableStrokes"] as? [[String: Any]] {
                    let drawing = AtlasPencilKitInterop.constructDrawing(from: portableStrokes)
                    let pkData = drawing.dataRepresentation()
                    result(FlutterStandardTypedData(bytes: pkData))
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "portableStrokes array expected", details: nil))
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
        let portableStrokes = AtlasPencilKitInterop.extractPortableStrokes(from: drawing)

        result([
            "pkDrawingBytes": FlutterStandardTypedData(bytes: pkData),
            "pngPreviewBytes": FlutterStandardTypedData(bytes: pngData),
            "portableStrokes": portableStrokes
        ])
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
