import React, { useRef } from "react"
import { Undo2, Redo2, Pipette } from "lucide-react"

export interface GoodNotesStyleControlsProps {
  color: string
  onChangeColor: (color: string) => void
  strokeWidth: number
  onChangeStrokeWidth: (width: number) => void
  onUndo: () => void
  onRedo: () => void
}

const PRESET_COLORS = ["#1e293b", "#1e3a8a", "#2563eb", "#059669", "#dc2626"]
const WIDTH_PRESETS = [
  { label: "Fine", width: 1.5, dotSize: "w-1 h-1" },
  { label: "Medium", width: 3, dotSize: "w-1.5 h-1.5" },
  { label: "Broad", width: 6, dotSize: "w-2.5 h-2.5" },
]

const ColorSwatchesGroup: React.FC<{
  color: string
  onChangeColor: (color: string) => void
}> = ({ color, onChangeColor }) => {
  const colorInputRef = useRef<HTMLInputElement>(null)
  return (
    <div className="flex items-center gap-1.5">
      {PRESET_COLORS.map((preset) => (
        <button
          key={preset}
          onClick={() => onChangeColor(preset)}
          className={`size-5 rounded-full transition-all border ${
            color === preset
              ? "ring-2 ring-blue-500 scale-125 border-white dark:border-slate-800"
              : "border-transparent hover:scale-110"
          }`}
          style={{ backgroundColor: preset }}
        />
      ))}
      <button
        onClick={() => colorInputRef.current?.click()}
        className="p-1 rounded-md text-slate-500 hover:text-slate-800 dark:hover:text-slate-200"
        data-tip="Custom Color"
      >
        <Pipette className="size-3.5" />
        <input
          ref={colorInputRef}
          type="color"
          value={color}
          onChange={(e) => onChangeColor(e.target.value)}
          className="sr-only"
        />
      </button>
    </div>
  )
}

const StrokeWidthGroup: React.FC<{
  strokeWidth: number
  onChangeStrokeWidth: (width: number) => void
}> = ({ strokeWidth, onChangeStrokeWidth }) => (
  <div className="flex items-center bg-slate-100 dark:bg-slate-800 rounded-lg p-0.5">
    {WIDTH_PRESETS.map((wp) => (
      <button
        key={wp.label}
        onClick={() => onChangeStrokeWidth(wp.width)}
        className={`p-1.5 rounded flex items-center justify-center transition-colors ${
          strokeWidth === wp.width
            ? "bg-white dark:bg-slate-700 shadow-sm"
            : "hover:bg-slate-200/50 dark:hover:bg-slate-700/50"
        }`}
        data-tip={`${wp.label} (${wp.width}px)`}
      >
        <div className={`${wp.dotSize} rounded-full bg-slate-800 dark:bg-slate-200`} />
      </button>
    ))}
  </div>
)

const UndoRedoGroup: React.FC<{
  onUndo: () => void
  onRedo: () => void
}> = ({ onUndo, onRedo }) => (
  <div className="flex items-center gap-0.5">
    <button
      onClick={onUndo}
      className="p-1.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
      data-tip="Undo (Ctrl+Z)"
    >
      <Undo2 className="size-4" />
    </button>
    <button
      onClick={onRedo}
      className="p-1.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg"
      data-tip="Redo (Ctrl+Y)"
    >
      <Redo2 className="size-4" />
    </button>
  </div>
)

export const GoodNotesStyleControls: React.FC<GoodNotesStyleControlsProps> = ({
  color,
  onChangeColor,
  strokeWidth,
  onChangeStrokeWidth,
  onUndo,
  onRedo,
}) => (
  <div className="flex items-center gap-2 shrink-0">
    <ColorSwatchesGroup color={color} onChangeColor={onChangeColor} />
    <div className="h-4 w-px bg-slate-200 dark:bg-slate-800" />
    <StrokeWidthGroup strokeWidth={strokeWidth} onChangeStrokeWidth={onChangeStrokeWidth} />
    <div className="h-4 w-px bg-slate-200 dark:bg-slate-800" />
    <UndoRedoGroup onUndo={onUndo} onRedo={onRedo} />
  </div>
)
