import React, { useRef, useState } from "react"
import { X, ZoomIn, ArrowRight, CornerDownLeft, GripHorizontal } from "lucide-react"
import type { ZoomWindowState, InkStroke } from "./types"
import { renderStrokeToPath } from "./stroke"

interface ZoomWindowProps {
  state: ZoomWindowState
  onClose: () => void
  onChangeTarget: (targetX: number, targetY: number) => void
  onChangeScale?: (scale: number) => void
  strokes: InkStroke[]
  activeColor: string
  activeSize: number
  activeTool: string
  onAddStroke: (stroke: InkStroke) => void
}

export const ZoomWindow: React.FC<ZoomWindowProps> = ({
  state,
  onClose,
  onChangeTarget,
  onChangeScale,
  strokes,
  activeColor,
  activeSize,
  activeTool,
  onAddStroke,
}) => {
  const [currentStroke, setCurrentStroke] = useState<InkStroke | null>(null)
  const isDrawingRef = useRef(false)
  const windowRef = useRef<HTMLDivElement>(null)
  const hasAdvancedForCurrentStrokeRef = useRef(false)

  // Zoom window window position offset (draggable by header)
  const [windowOffset, setWindowOffset] = useState<{ x: number; y: number }>({ x: 0, y: 0 })

  if (!state.active) return null

  const scale = state.scale || 2.5
  const boxWidth = 580
  const boxHeight = 230
  const returnZoneWidth = 90 // Shaded auto-advance return zone

  // Canvas bounds shown inside the zoom box
  const targetViewW = boxWidth / scale
  const targetViewH = boxHeight / scale

  const handlePointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    e.stopPropagation()
    try {
      e.currentTarget.setPointerCapture(e.pointerId)
    } catch {}

    const rect = e.currentTarget.getBoundingClientRect()
    const clickX = e.clientX - rect.left
    const clickY = e.clientY - rect.top

    // Check if clicked in auto-advance return zone
    if (clickX > boxWidth - returnZoneWidth) {
      onChangeTarget(state.targetX + targetViewW * 0.65, state.targetY)
      return
    }

    hasAdvancedForCurrentStrokeRef.current = false

    // Map screen click inside zoom window to notebook canvas coordinates
    const pageX = state.targetX + clickX / scale
    const pageY = state.targetY + clickY / scale

    isDrawingRef.current = true
    const stroke: InkStroke = {
      id: `zoom_stroke_${Date.now()}`,
      tool: activeTool as any,
      color: activeColor,
      size: activeSize,
      points: [{ x: pageX, y: pageY, pressure: e.pressure || 0.5, time: Date.now() }],
      createdAt: Date.now(),
    }
    setCurrentStroke(stroke)
  }

  const handlePointerMove = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!isDrawingRef.current || !currentStroke) return

    const rect = e.currentTarget.getBoundingClientRect()
    const clickX = e.clientX - rect.left
    const clickY = e.clientY - rect.top

    // Map to page coordinates
    const pageX = state.targetX + clickX / scale
    const pageY = state.targetY + clickY / scale

    const updatedPoints = [
      ...currentStroke.points,
      { x: pageX, y: pageY, pressure: e.pressure || 0.5, time: Date.now() },
    ]

    setCurrentStroke({
      ...currentStroke,
      points: updatedPoints,
    })

    // If writing enters the auto-advance return zone, trigger auto-shift ONCE per stroke
    if (clickX > boxWidth - returnZoneWidth * 0.7 && !hasAdvancedForCurrentStrokeRef.current) {
      hasAdvancedForCurrentStrokeRef.current = true
      onChangeTarget(state.targetX + targetViewW * 0.65, state.targetY)
    }
  }

  const handlePointerUp = (e: React.PointerEvent<SVGSVGElement>) => {
    try {
      e.currentTarget.releasePointerCapture(e.pointerId)
    } catch {}
    if (!isDrawingRef.current || !currentStroke) return
    isDrawingRef.current = false
    if (currentStroke.points.length > 1) {
      onAddStroke(currentStroke)
    }
    setCurrentStroke(null)
  }

  // Handle Dragging Zoom Window Position
  const handleHeaderPointerDown = (e: React.PointerEvent) => {
    e.stopPropagation()
    const startClientX = e.clientX
    const startClientY = e.clientY
    const startOffsetX = windowOffset.x
    const startOffsetY = windowOffset.y

    const onMove = (moveEv: PointerEvent) => {
      setWindowOffset({
        x: startOffsetX + (moveEv.clientX - startClientX),
        y: startOffsetY + (moveEv.clientY - startClientY),
      })
    }

    const onUp = () => {
      window.removeEventListener("pointermove", onMove)
      window.removeEventListener("pointerup", onUp)
    }

    window.addEventListener("pointermove", onMove)
    window.addEventListener("pointerup", onUp)
  }

  return (
    <div
      ref={windowRef}
      className="absolute bottom-4 left-1/2 transform -translate-x-1/2 bg-white dark:bg-[#1a1d24] rounded-2xl shadow-2xl border-2 border-blue-500/80 z-40 overflow-hidden flex flex-col animate-in fade-in slide-in-from-bottom-4 select-none"
      style={{
        width: `${boxWidth}px`,
        height: `${boxHeight}px`,
        transform: `translate(calc(-50% + ${windowOffset.x}px), ${windowOffset.y}px)`,
      }}
    >
      {/* Zoom Window Header (Draggable) */}
      <div
        className="flex items-center justify-between px-3 py-1.5 bg-slate-100 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 text-xs cursor-move select-none"
        onPointerDown={handleHeaderPointerDown}
      >
        <div className="flex items-center gap-1.5 font-semibold text-slate-700 dark:text-slate-200">
          <GripHorizontal className="w-3.5 h-3.5 text-slate-400" />
          <ZoomIn className="w-4 h-4 text-blue-500" />
          <span>Zoom Window</span>
          {/* Zoom scale selector */}
          <div
            className="flex items-center gap-0.5 ml-2 bg-slate-200 dark:bg-slate-700 rounded p-0.5"
            onPointerDown={(e) => e.stopPropagation()}
          >
            {[1.5, 2.0, 2.5, 3.0].map((s) => (
              <button
                key={s}
                onClick={() => onChangeScale?.(s)}
                className={`px-1.5 py-0.2 rounded text-[10px] font-bold ${
                  scale === s ? "bg-blue-600 text-white" : "text-slate-600 dark:text-slate-300 hover:bg-slate-300"
                }`}
              >
                {s}x
              </button>
            ))}
          </div>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-1.5" onPointerDown={(e) => e.stopPropagation()}>
          {/* Next line return */}
          <button
            onClick={() => onChangeTarget(100, state.targetY + 45)}
            className="flex items-center gap-1 px-2 py-0.5 bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 rounded text-[11px] font-medium"
            title="Return to New Line"
          >
            <CornerDownLeft className="w-3 h-3" />
            <span>New Line</span>
          </button>

          {/* Pan forward */}
          <button
            onClick={() => onChangeTarget(state.targetX + targetViewW * 0.65, state.targetY)}
            className="flex items-center gap-1 px-2 py-0.5 bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 rounded text-[11px] font-medium hover:bg-blue-200"
            title="Advance right"
          >
            <span>Advance</span>
            <ArrowRight className="w-3 h-3" />
          </button>

          <button
            onClick={onClose}
            className="p-1 text-slate-400 hover:text-slate-600 rounded"
            title="Close Zoom Window"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Magnified Drawing Viewport */}
      <div className="relative flex-1 bg-white dark:bg-[#181b22] overflow-hidden select-none">
        <svg
          className="w-full h-full cursor-crosshair touch-none"
          onPointerDown={handlePointerDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          onPointerCancel={handlePointerUp}
        >
          {/* Transform group representing scaled region */}
          <g transform={`scale(${scale}) translate(${-state.targetX}, ${-state.targetY})`}>
            {/* Background guide lines */}
            <line
              x1={state.targetX}
              y1={state.targetY + targetViewH * 0.75}
              x2={state.targetX + targetViewW}
              y2={state.targetY + targetViewH * 0.75}
              stroke="#93c5fd"
              strokeWidth={1 / scale}
              strokeDasharray="4,4"
            />

            {/* Existing strokes */}
            {strokes.map((s) => {
              const isLineLike = s.shapeType === "line" || s.shapeType === "arrow" || s.shapeType === "arc"
              return (
                <path
                  key={s.id}
                  d={renderStrokeToPath(s)}
                  fill={s.shapeType ? (isLineLike ? "none" : (s.fill || "none")) : s.color}
                  stroke={s.shapeType ? s.color : "none"}
                  strokeWidth={s.shapeType ? s.size : 0}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              )
            })}

            {/* Current in-progress stroke */}
            {currentStroke && (
              <path
                d={renderStrokeToPath(currentStroke)}
                fill={
                  currentStroke.shapeType
                    ? (currentStroke.shapeType === "line" || currentStroke.shapeType === "arrow" || currentStroke.shapeType === "arc"
                        ? "none"
                        : currentStroke.fill || "none")
                    : currentStroke.color
                }
                stroke={currentStroke.shapeType ? currentStroke.color : "none"}
                strokeWidth={currentStroke.shapeType ? currentStroke.size : 0}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            )}
          </g>

          {/* Shaded Auto-Advance Return Zone on right edge */}
          <rect
            x={boxWidth - returnZoneWidth}
            y={0}
            width={returnZoneWidth}
            height={boxHeight}
            fill="rgba(59, 130, 246, 0.08)"
            stroke="rgba(59, 130, 246, 0.25)"
            strokeDasharray="4,4"
            className="pointer-events-none"
          />
          <text
            x={boxWidth - returnZoneWidth / 2}
            y={boxHeight / 2 - 10}
            textAnchor="middle"
            fontSize={10}
            fill="#3b82f6"
            fontWeight="bold"
            className="pointer-events-none select-none"
          >
            Auto-Advance
          </text>
          <text
            x={boxWidth - returnZoneWidth / 2}
            y={boxHeight / 2 + 6}
            textAnchor="middle"
            fontSize={8}
            fill="#60a5fa"
            className="pointer-events-none select-none"
          >
            Zone
          </text>
        </svg>
      </div>
    </div>
  )
}
