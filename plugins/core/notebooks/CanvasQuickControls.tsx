import React from "react"
import { Grid, Magnet, ZoomIn, ZoomOut, HelpCircle } from "lucide-react"

export interface CanvasQuickControlsProps {
  gridMode: boolean
  onToggleGridMode: () => void
  snapToObjects: boolean
  onToggleSnapToObjects: () => void
  zoom: number
  onZoomIn: () => void
  onZoomOut: () => void
  onResetZoom: () => void
  onHelp: () => void
}

const SnapButtons: React.FC<{
  gridMode: boolean
  onToggleGridMode: () => void
  snapToObjects: boolean
  onToggleSnapToObjects: () => void
}> = ({ gridMode, onToggleGridMode, snapToObjects, onToggleSnapToObjects }) => (
  <>
    <button
      onClick={onToggleGridMode}
      className={`p-1.5 rounded-lg transition-colors ${
        gridMode
          ? "bg-blue-100 text-blue-600 dark:bg-blue-950 dark:text-blue-400 font-semibold"
          : "text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
      }`}
      data-tip="Grid Snapping"
    >
      <Grid className="size-4" />
    </button>
    <button
      onClick={onToggleSnapToObjects}
      className={`p-1.5 rounded-lg transition-colors ${
        snapToObjects
          ? "bg-blue-100 text-blue-600 dark:bg-blue-950 dark:text-blue-400 font-semibold"
          : "text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
      }`}
      data-tip="Snap to Objects"
    >
      <Magnet className="size-4" />
    </button>
  </>
)

const ZoomButtons: React.FC<{
  zoom: number
  onZoomIn: () => void
  onZoomOut: () => void
  onResetZoom: () => void
}> = ({ zoom, onZoomIn, onZoomOut, onResetZoom }) => (
  <>
    <button
      onClick={onZoomOut}
      className="p-1.5 text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
      data-tip="Zoom Out (Ctrl+-)"
    >
      <ZoomOut className="size-4" />
    </button>
    <button
      onClick={onResetZoom}
      className="px-1.5 py-0.5 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 rounded transition-colors select-none tabular-nums"
      data-tip="Reset Zoom (Ctrl+0)"
    >
      {Math.round(zoom * 100)}%
    </button>
    <button
      onClick={onZoomIn}
      className="p-1.5 text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
      data-tip="Zoom In (Ctrl++)"
    >
      <ZoomIn className="size-4" />
    </button>
  </>
)

export const CanvasQuickControls: React.FC<CanvasQuickControlsProps> = (props) => (
  <div className="flex items-center gap-0.5 shrink-0">
    <SnapButtons
      gridMode={props.gridMode}
      onToggleGridMode={props.onToggleGridMode}
      snapToObjects={props.snapToObjects}
      onToggleSnapToObjects={props.onToggleSnapToObjects}
    />
    <div className="w-[1px] h-4 bg-slate-200 dark:bg-slate-800 mx-0.5" />
    <ZoomButtons
      zoom={props.zoom}
      onZoomIn={props.onZoomIn}
      onZoomOut={props.onZoomOut}
      onResetZoom={props.onResetZoom}
    />
    <div className="w-[1px] h-4 bg-slate-200 dark:bg-slate-800 mx-0.5" />
    <button
      onClick={props.onHelp}
      className="p-1.5 text-slate-500 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
      data-tip="Shortcuts & Help"
    >
      <HelpCircle className="size-4" />
    </button>
  </div>
)
