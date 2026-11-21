import React, { useState, useRef } from "react"
import type { RulerState, LaserState } from "./types"

interface RulerAndLaserProps {
  ruler: RulerState
  onChangeRuler: (updated: RulerState) => void
  laser: LaserState
  zoomLevel: number
}

export const RulerOverlay: React.FC<RulerAndLaserProps> = ({
  ruler,
  onChangeRuler,
  laser,
  zoomLevel,
}) => {
  const [isDraggingRuler, setIsDraggingRuler] = useState(false)
  const [isRotatingRuler, setIsRotatingRuler] = useState(false)
  const dragStartRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 })

  if (!ruler.active && !laser.active) return null

  // Laser Pointer rendering
  const renderLaser = () => {
    if (!laser.active) return null

    return (
      <g className="laser-pointer-layer pointer-events-none">
        {/* Fading trail */}
        {laser.mode === "trail" && laser.trail.length > 1 && (
          <path
            d={`M${laser.trail.map((p) => `${p.x},${p.y}`).join(" L")}`}
            fill="none"
            stroke="#ef4444"
            strokeWidth={4}
            strokeLinecap="round"
            strokeLinejoin="round"
            opacity={0.8}
            className="transition-opacity duration-1000"
          />
        )}

        {/* Laser Dot */}
        {laser.current && (
          <g transform={`translate(${laser.current.x}, ${laser.current.y})`}>
            <circle cx={0} cy={0} r={10} fill="rgba(239, 68, 68, 0.35)" className="animate-ping" />
            <circle cx={0} cy={0} r={5} fill="#ef4444" stroke="#ffffff" strokeWidth={2} />
          </g>
        )}
      </g>
    )
  }

  // Interactive Straightedge Ruler rendering
  const renderRuler = () => {
    if (!ruler.active) return null

    const width = ruler.length || 500
    const height = 70
    const angle = ruler.angle || 0

    return (
      <g
        transform={`translate(${ruler.x}, ${ruler.y}) rotate(${angle})`}
        className="ruler-group select-none"
      >
        {/* Semi-transparent acrylic straightedge body */}
        <rect
          x={-width / 2}
          y={-height / 2}
          width={width}
          height={height}
          rx={8}
          fill="rgba(241, 245, 249, 0.85)"
          stroke="#94a3b8"
          strokeWidth={1.5}
          className="backdrop-blur-md shadow-2xl cursor-grab active:cursor-grabbing"
          onPointerDown={(e) => {
            e.stopPropagation()
            setIsDraggingRuler(true)
            dragStartRef.current = { x: e.clientX, y: e.clientY }
          }}
          onPointerMove={(e) => {
            if (!isDraggingRuler) return
            const dx = (e.clientX - dragStartRef.current.x) / zoomLevel
            const dy = (e.clientY - dragStartRef.current.y) / zoomLevel
            dragStartRef.current = { x: e.clientX, y: e.clientY }
            onChangeRuler({
              ...ruler,
              x: ruler.x + dx,
              y: ruler.y + dy,
            })
          }}
          onPointerUp={() => setIsDraggingRuler(false)}
        />

        {/* Center Live Degree Readout Pill */}
        <g
          transform={`translate(0, 0)`}
          className="cursor-pointer"
          onPointerDown={(e) => {
            e.stopPropagation()
            setIsRotatingRuler(true)
            dragStartRef.current = { x: e.clientX, y: e.clientY }
          }}
          onPointerMove={(e) => {
            if (!isRotatingRuler) return
            const delta = (e.clientX - dragStartRef.current.x) * 0.5
            dragStartRef.current = { x: e.clientX, y: e.clientY }
            onChangeRuler({
              ...ruler,
              angle: Math.round((ruler.angle + delta) % 360),
            })
          }}
          onPointerUp={() => setIsRotatingRuler(false)}
        >
          <rect
            x={-35}
            y={-14}
            width={70}
            height={28}
            rx={14}
            fill="#1e293b"
            stroke="#38bdf8"
            strokeWidth={1.5}
          />
          <text
            x={0}
            y={4}
            textAnchor="middle"
            fill="#ffffff"
            fontSize={12}
            fontWeight="bold"
            className="pointer-events-none font-mono"
          >
            {Math.round(ruler.angle)}°
          </text>
        </g>

        {/* Measurement tick marks along top & bottom straight edges */}
        {Array.from({ length: Math.floor(width / 10) }).map((_, i) => {
          const x = -width / 2 + 10 + i * 10
          const isMajor = i % 5 === 0
          const isNumbered = i % 10 === 0
          return (
            <g key={i}>
              {/* Top edge ticks */}
              <line
                x1={x}
                y1={-height / 2}
                x2={x}
                y2={-height / 2 + (isMajor ? 14 : 7)}
                stroke="#64748b"
                strokeWidth={isMajor ? 1.5 : 0.8}
              />
              {/* Bottom edge ticks */}
              <line
                x1={x}
                y1={height / 2}
                x2={x}
                y2={height / 2 - (isMajor ? 14 : 7)}
                stroke="#64748b"
                strokeWidth={isMajor ? 1.5 : 0.8}
              />
              {isNumbered && (
                <text
                  x={x}
                  y={-height / 2 + 24}
                  textAnchor="middle"
                  fontSize={8}
                  fill="#64748b"
                  className="font-mono pointer-events-none select-none"
                >
                  {i / 10}
                </text>
              )}
            </g>
          )
        })}

        {/* Rotate handle icon on right */}
        <g
          transform={`translate(${width / 2 - 20}, 0)`}
          className="cursor-ew-resize hover:scale-110 transition-transform"
          onClick={(e) => {
            e.stopPropagation()
            onChangeRuler({ ...ruler, angle: (ruler.angle + 45) % 360 })
          }}
        >
          <circle cx={0} cy={0} r={12} fill="#3b82f6" opacity={0.8} />
          <path
            d="M-4,-4 L4,-4 L4,4"
            fill="none"
            stroke="#ffffff"
            strokeWidth={1.5}
            strokeLinecap="round"
          />
        </g>
      </g>
    )
  }

  return (
    <>
      {renderLaser()}
      {renderRuler()}
    </>
  )
}
