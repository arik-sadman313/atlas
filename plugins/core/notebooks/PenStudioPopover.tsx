import { Pen, Minus, Feather, Sparkles, Sliders } from "lucide-react"
import type { InkToolType, PenStudioSettings, PenToolConfig } from "./types"
import { renderStrokeToPath } from "./stroke"

interface PenStudioPopoverProps {
  activeTool: InkToolType
  onSelectTool: (tool: "fountain" | "ballpoint" | "brush") => void
  penSettings: PenStudioSettings
  onChangePenSettings: (tool: "fountain" | "ballpoint" | "brush", config: Partial<PenToolConfig>) => void
  activeColor: string
  activeSize: number
  onChangeSize: (size: number) => void
  autoShapeDetection: boolean
  onToggleAutoShape: () => void
  onClose: () => void
}

export function PenStudioPopover({
  activeTool,
  onSelectTool,
  penSettings,
  onChangePenSettings,
  activeColor,
  activeSize,
  onChangeSize,
  autoShapeDetection,
  onToggleAutoShape,
  onClose,
}: PenStudioPopoverProps) {
  const currentPenType =
    activeTool === "brush" ? "brush" : activeTool === "ballpoint" ? "ballpoint" : "fountain"

  const currentConfig = penSettings[currentPenType]

  // Render a sample S-curve preview based on current settings
  const previewPoints = [
    { x: 20, y: 35, pressure: 0.2 },
    { x: 50, y: 15, pressure: 0.4 },
    { x: 90, y: 45, pressure: 0.85 },
    { x: 130, y: 20, pressure: 0.95 },
    { x: 170, y: 45, pressure: 0.6 },
    { x: 210, y: 25, pressure: 0.15 },
  ]

  const previewPath = renderStrokeToPath({
    id: "preview_stroke",
    tool: currentPenType,
    color: activeColor,
    size: activeSize,
    points: previewPoints,
    createdAt: Date.now(),
    penSettings: currentConfig,
  })

  const standardSizes = [
    { label: "0.25mm", size: 2 },
    { label: "0.35mm", size: 3 },
    { label: "0.5mm", size: 4 },
    { label: "0.7mm", size: 6 },
    { label: "1.0mm", size: 8 },
    { label: "1.5mm", size: 12 },
    { label: "2.0mm", size: 16 },
  ]

  return (
    <div className="w-80 bg-white dark:bg-[#1a1e26] rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 backdrop-blur-xl p-4 flex flex-col gap-4 animate-in fade-in zoom-in-95 duration-150">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800/60 pb-2.5">
        <div className="flex items-center gap-1.5 text-xs font-bold text-slate-800 dark:text-slate-100 uppercase tracking-wider">
          <Sliders className="w-3.5 h-3.5 text-blue-500" />
          <span>Pen Studio</span>
        </div>
        <button
          onClick={onClose}
          className="text-xs font-medium text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
        >
          Done
        </button>
      </div>

      {/* 3 Distinct Pen Engines */}
      <div className="grid grid-cols-3 gap-1.5 bg-slate-100 dark:bg-slate-800/60 p-1 rounded-xl">
        {/* Fountain Pen */}
        <button
          onClick={() => onSelectTool("fountain")}
          className={`flex flex-col items-center gap-1 py-2 px-1 rounded-lg text-xs font-semibold transition-all ${
            currentPenType === "fountain"
              ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
              : "text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200"
          }`}
        >
          <Pen className="w-4 h-4" />
          <span className="text-[11px]">Fountain</span>
        </button>

        {/* Ballpoint Pen */}
        <button
          onClick={() => onSelectTool("ballpoint")}
          className={`flex flex-col items-center gap-1 py-2 px-1 rounded-lg text-xs font-semibold transition-all ${
            currentPenType === "ballpoint"
              ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
              : "text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200"
          }`}
        >
          <Minus className="w-4 h-4 rotate-45 stroke-[2.5]" />
          <span className="text-[11px]">Ballpoint</span>
        </button>

        {/* Brush Pen */}
        <button
          onClick={() => onSelectTool("brush")}
          className={`flex flex-col items-center gap-1 py-2 px-1 rounded-lg text-xs font-semibold transition-all ${
            currentPenType === "brush"
              ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
              : "text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200"
          }`}
        >
          <Feather className="w-4 h-4" />
          <span className="text-[11px]">Brush Pen</span>
        </button>
      </div>

      {/* Real-time Ink Stroke Preview Box */}
      <div className="relative bg-slate-50 dark:bg-slate-900/60 border border-slate-200/70 dark:border-slate-800 rounded-xl h-16 flex items-center justify-center overflow-hidden">
        <svg viewBox="0 0 230 60" className="w-full h-full">
          <path d={previewPath} fill={activeColor} />
        </svg>
        <span className="absolute bottom-1 right-2 text-[9px] uppercase tracking-wider text-slate-400 font-mono">
          {currentPenType} • {activeSize}px
        </span>
      </div>

      {/* Tip Sharpness Slider */}
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center justify-between text-xs">
          <span className="font-medium text-slate-700 dark:text-slate-300">Tip Sharpness</span>
          <span className="font-mono text-slate-400 text-[11px]">{currentConfig.tipSharpness}%</span>
        </div>
        <input
          type="range"
          min="0"
          max="100"
          value={currentConfig.tipSharpness}
          onChange={(e) =>
            onChangePenSettings(currentPenType, { tipSharpness: parseInt(e.target.value, 10) })
          }
          className="w-full h-1.5 bg-slate-200 dark:bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-600"
        />
        <div className="flex justify-between text-[10px] text-slate-400">
          <span>Round</span>
          <span>Sharp Needle</span>
        </div>
      </div>

      {/* Pressure Sensitivity Slider (Fountain & Brush) */}
      {currentPenType !== "ballpoint" ? (
        <div className="flex flex-col gap-1.5">
          <div className="flex items-center justify-between text-xs">
            <span className="font-medium text-slate-700 dark:text-slate-300">Pressure Sensitivity</span>
            <span className="font-mono text-slate-400 text-[11px]">{currentConfig.pressureSensitivity}%</span>
          </div>
          <input
            type="range"
            min="0"
            max="100"
            value={currentConfig.pressureSensitivity}
            onChange={(e) =>
              onChangePenSettings(currentPenType, { pressureSensitivity: parseInt(e.target.value, 10) })
            }
            className="w-full h-1.5 bg-slate-200 dark:bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-600"
          />
          <div className="flex justify-between text-[10px] text-slate-400">
            <span>Light Touch</span>
            <span>Firm Pressure</span>
          </div>
        </div>
      ) : (
        <div className="p-2 bg-slate-100 dark:bg-slate-800/40 rounded-lg text-[11px] text-slate-500">
          Ballpoint pen maintains an even, uniform line thickness regardless of stylus pressure.
        </div>
      )}

      {/* Stroke Stabilization (Smoothing) */}
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center justify-between text-xs">
          <span className="font-medium text-slate-700 dark:text-slate-300">Stroke Stabilization</span>
          <span className="font-mono text-slate-400 text-[11px]">{currentConfig.stabilization}%</span>
        </div>
        <input
          type="range"
          min="0"
          max="100"
          value={currentConfig.stabilization}
          onChange={(e) =>
            onChangePenSettings(currentPenType, { stabilization: parseInt(e.target.value, 10) })
          }
          className="w-full h-1.5 bg-slate-200 dark:bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-600"
        />
        <div className="flex justify-between text-[10px] text-slate-400">
          <span>Raw Hand</span>
          <span>Ultra Smooth</span>
        </div>
      </div>

      {/* Preset Tip Sizes */}
      <div className="flex flex-col gap-1.5">
        <div className="text-xs font-medium text-slate-700 dark:text-slate-300">Tip Thickness</div>
        <div className="flex items-center justify-between gap-1">
          {standardSizes.map((item) => (
            <button
              key={item.size}
              onClick={() => onChangeSize(item.size)}
              className={`flex-1 py-1 rounded text-[10px] font-semibold border transition-all ${
                activeSize === item.size
                  ? "bg-blue-600 border-blue-600 text-white shadow-sm"
                  : "bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-100"
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      {/* Auto-Shape Detection Toggle */}
      <div className="pt-2 border-t border-slate-100 dark:border-slate-800/60 flex items-center justify-between">
        <div className="flex flex-col">
          <div className="text-xs font-semibold text-slate-700 dark:text-slate-200 flex items-center gap-1">
            <Sparkles className="w-3 h-3 text-amber-500" />
            <span>Draw and Hold Shape</span>
          </div>
          <span className="text-[10px] text-slate-400">
            Hold stylus still at stroke end to snap into clean geometry
          </span>
        </div>
        <button
          onClick={onToggleAutoShape}
          className={`w-9 h-5 rounded-full p-0.5 transition-colors ${
            autoShapeDetection ? "bg-blue-600" : "bg-slate-300 dark:bg-slate-700"
          }`}
        >
          <div
            className={`w-4 h-4 rounded-full bg-white shadow-md transform transition-transform ${
              autoShapeDetection ? "translate-x-4" : "translate-x-0"
            }`}
          />
        </button>
      </div>
    </div>
  )
}
