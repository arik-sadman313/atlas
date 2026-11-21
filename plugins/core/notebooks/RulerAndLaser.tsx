import React, { useState, useRef, useEffect } from "react"
import type { RulerState, LaserState } from "./types"

interface RulerAndLaserProps {
  ruler: RulerState
  onChangeRuler: (updated: RulerState) => void
  laser: LaserState
  onChangeLaser?: (updated: LaserState) => void
  zoomLevel: number
}

export const RulerOverlay: React.FC<RulerAndLaserProps> = ({
  ruler,
  onChangeRuler,
  laser,
  onChangeLaser,
  zoomLevel,
}) => {
  const [isDraggingRuler, setIsDraggingRuler] = useState(false)
  const [isRotatingRuler, setIsRotatingRuler] = useState(false)
  const [resizingSide, setResizingSide] = useState<"left" | "right" | null>(null)
  const dragStartRef = useRef<{ clientX: number; clientY: number; startLength: number; startAngle: number; startX: number; startY: number }>({
    clientX: 0,
    clientY: 0,
    startLength: 500,
    startAngle: 0,
    startX: 0,
    startY: 0,
  })

  // Laser fading animation loop
  useEffect(() => {
    if (!laser.active && (!laser.trail || laser.trail.length === 0)) return

    const interval = setInterval(() => {
      const now = Date.now()
      // Retain points younger than 1200ms
      const freshTrail = laser.trail.filter((p) => now - (p.time || 0) < 1200)
      if (freshTrail.length !== laser.trail.length) {
        onChangeLaser?.({
          ...laser,
          trail: freshTrail,
        })
      }
    }, 50)

    return () => clearInterval(interval)
  }, [laser, onChangeLaser])

  if (!ruler.active && !laser.active && (!laser.trail || laser.trail.length === 0)) return null

  // Laser Pointer rendering
  const renderLaser = () => {
    const laserColor = laser.color || "#ef4444"
    const now = Date.now()

    return (
      <g className="laser-pointer-layer pointer-events-none select-none">
        {/* Fading segmented trail with progressive decay */}
        {laser.mode === "trail" && laser.trail && laser.trail.length > 1 && (
          <g>
            {laser.trail.map((p, idx) => {
              if (idx === 0) return null
              const prev = laser.trail[idx - 1]
              const age = now - (p.time || now)
              const opacity = Math.max(0, 1 - age / 1200) * 0.85
              const width = Math.max(2, 6 * (1 - age / 1200))
              return (
                <line
                  key={idx}
                  x1={prev.x}
                  y1={prev.y}
                  x2={p.x}
                  y2={p.y}
                  stroke={laserColor}
                  strokeWidth={width}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  opacity={opacity}
                />
              )
            })}
          </g>
        )}

        {/* Laser Dot Indicator */}
        {laser.active && laser.current && (
          <g transform={`translate(${laser.current.x}, ${laser.current.y})`}>
            <circle cx={0} cy={0} r={12} fill={laserColor} opacity={0.25} className="animate-ping" />
            <circle cx={0} cy={0} r={5} fill={laserColor} stroke="#ffffff" strokeWidth={2} />
          </g>
        )}
      </g>
    )
  }

  // Interactive Straightedge Ruler rendering
  const renderRuler = () => {
    if (!ruler.active) return null

    const width = Math.max(160, Math.min(1800, ruler.length || 500))
    const height = 70
    const angle = ruler.angle || 0
    const rad = (angle * Math.PI) / 180

    // Handle Ruler Dragging
    const handleRulerPointerDown = (e: React.PointerEvent) => {
      e.stopPropagation()
      try {
        e.currentTarget.setPointerCapture(e.pointerId)
      } catch {}
      setIsDraggingRuler(true)
      dragStartRef.current = {
        clientX: e.clientX,
        clientY: e.clientY,
        startLength: width,
        startAngle: angle,
        startX: ruler.x,
        startY: ruler.y,
      }
    }

    const handleRulerPointerMove = (e: React.PointerEvent) => {
      if (!isDraggingRuler) return
      const dx = (e.clientX - dragStartRef.current.clientX) / zoomLevel
      const dy = (e.clientY - dragStartRef.current.clientY) / zoomLevel
      onChangeRuler({
        ...ruler,
        x: dragStartRef.current.startX + dx,
        y: dragStartRef.current.startY + dy,
      })
    }

    const handleRulerPointerUp = (e: React.PointerEvent) => {
      try {
        e.currentTarget.releasePointerCapture(e.pointerId)
      } catch {}
      setIsDraggingRuler(false)
    }

    // Handle Ruler Length Resizing (left or right handle)
    const handleResizePointerDown = (e: React.PointerEvent, side: "left" | "right") => {
      e.stopPropagation()
      try {
        e.currentTarget.setPointerCapture(e.pointerId)
      } catch {}
      setResizingSide(side)
      dragStartRef.current = {
        clientX: e.clientX,
        clientY: e.clientY,
        startLength: width,
        startAngle: angle,
        startX: ruler.x,
        startY: ruler.y,
      }
    }

    const handleResizePointerMove = (e: React.PointerEvent) => {
      if (!resizingSide) return
      // Vector from ruler center to pointer in canvas coords
      // Project pointer displacement along ruler orientation vector
      const dx = (e.clientX - dragStartRef.current.clientX) / zoomLevel
      const dy = (e.clientY - dragStartRef.current.clientY) / zoomLevel
      const dirX = Math.cos(rad)
      const dirY = Math.sin(rad)
      const along = dx * dirX + dy * dirY

      let newLen = width
      if (resizingSide === "right") {
        newLen = Math.max(180, Math.min(1800, dragStartRef.current.startLength + along * 2))
      } else {
        newLen = Math.max(180, Math.min(1800, dragStartRef.current.startLength - along * 2))
      }

      onChangeRuler({
        ...ruler,
        length: Math.round(newLen),
      })
    }

    const handleResizePointerUp = (e: React.PointerEvent) => {
      try {
        e.currentTarget.releasePointerCapture(e.pointerId)
      } catch {}
      setResizingSide(null)
    }

    // Handle Circular Rotation
    const handleRotatePointerDown = (e: React.PointerEvent) => {
      e.stopPropagation()
      try {
        e.currentTarget.setPointerCapture(e.pointerId)
      } catch {}
      setIsRotatingRuler(true)
      dragStartRef.current = {
        clientX: e.clientX,
        clientY: e.clientY,
        startLength: width,
        startAngle: angle,
        startX: ruler.x,
        startY: ruler.y,
      }
    }

    const handleRotatePointerMove = (e: React.PointerEvent) => {
      if (!isRotatingRuler) return
      const dx = e.clientX - dragStartRef.current.clientX
      // Compute delta angle
      let newAngle = (dragStartRef.current.startAngle + dx * 0.4) % 360
      if (newAngle < 0) newAngle += 360

      // Snap to common angles (0, 45, 90, 135, 180, 225, 270, 315)
      const snaps = [0, 45, 90, 135, 180, 225, 270, 315, 360]
      for (const snap of snaps) {
        if (Math.abs(newAngle - snap) <= 2.5) {
          newAngle = snap % 360
          break
        }
      }

      onChangeRuler({
        ...ruler,
        angle: Math.round(newAngle),
      })
    }

    const handleRotatePointerUp = (e: React.PointerEvent) => {
      try {
        e.currentTarget.releasePointerCapture(e.pointerId)
      } catch {}
      setIsRotatingRuler(false)
    }

    return (
      <g
        transform={`translate(${ruler.x}, ${ruler.y}) rotate(${angle})`}
        className="ruler-group select-none"
      >
        {/* Semi-transparent acrylic straightedge visual body (pointer-events-none so edges allow drawing) */}
        <rect
          x={-width / 2}
          y={-height / 2}
          width={width}
          height={height}
          rx={8}
          fill="rgba(241, 245, 249, 0.88)"
          stroke="#94a3b8"
          strokeWidth={1.5}
          className="backdrop-blur-md shadow-2xl pointer-events-none"
        />

        {/* Central Drag Handle Strip (Touch/Click here to move the ruler across the canvas) */}
        <rect
          x={-width / 2 + 26}
          y={-18}
          width={width - 52}
          height={36}
          rx={6}
          fill="rgba(226, 232, 240, 0.35)"
          stroke="rgba(148, 163, 184, 0.4)"
          strokeDasharray="4,4"
          className="cursor-grab active:cursor-grabbing hover:fill-blue-100/40 transition-colors"
          onPointerDown={handleRulerPointerDown}
          onPointerMove={handleRulerPointerMove}
          onPointerUp={handleRulerPointerUp}
          onPointerCancel={handleRulerPointerUp}
        >
          <title>Drag center to move ruler (Draw along top or bottom edge)</title>
        </rect>

        {/* Subtle grip indicators on left and right of degree readout */}
        <g className="pointer-events-none opacity-40">
          <circle cx={-60} cy={0} r={2} fill="#64748b" />
          <circle cx={-50} cy={0} r={2} fill="#64748b" />
          <circle cx={50} cy={0} r={2} fill="#64748b" />
          <circle cx={60} cy={0} r={2} fill="#64748b" />
        </g>

        {/* Center Live Degree Readout Pill (Draggable for Smooth Rotation) */}
        <g
          transform="translate(0, 0)"
          className="cursor-ew-resize"
          onPointerDown={handleRotatePointerDown}
          onPointerMove={handleRotatePointerMove}
          onPointerUp={handleRotatePointerUp}
          onPointerCancel={handleRotatePointerUp}
        >
          <rect
            x={-38}
            y={-14}
            width={76}
            height={28}
            rx={14}
            fill="#1e293b"
            stroke="#38bdf8"
            strokeWidth={1.5}
            className="hover:stroke-blue-400 transition-colors"
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

        {/* Left Length Resizer Handle */}
        <g
          transform={`translate(${-width / 2}, 0)`}
          className="cursor-ew-resize group/resizer"
          onPointerDown={(e) => handleResizePointerDown(e, "left")}
          onPointerMove={handleResizePointerMove}
          onPointerUp={handleResizePointerUp}
          onPointerCancel={handleResizePointerUp}
        >
          <circle
            cx={0}
            cy={0}
            r={13}
            fill="#3b82f6"
            stroke="#ffffff"
            strokeWidth={2}
            className="group-hover/resizer:scale-115 transition-transform shadow-md"
          />
          {/* Visual double arrow inside handle */}
          <path
            d="M-4,0 L-1,-3 M-4,0 L-1,3 M4,0 L1,-3 M4,0 L1,3"
            stroke="#ffffff"
            strokeWidth={1.5}
            strokeLinecap="round"
          />
        </g>

        {/* Right Length Resizer Handle */}
        <g
          transform={`translate(${width / 2}, 0)`}
          className="cursor-ew-resize group/resizer"
          onPointerDown={(e) => handleResizePointerDown(e, "right")}
          onPointerMove={handleResizePointerMove}
          onPointerUp={handleResizePointerUp}
          onPointerCancel={handleResizePointerUp}
        >
          <circle
            cx={0}
            cy={0}
            r={13}
            fill="#3b82f6"
            stroke="#ffffff"
            strokeWidth={2}
            className="group-hover/resizer:scale-115 transition-transform shadow-md"
          />
          {/* Visual double arrow inside handle */}
          <path
            d="M-4,0 L-1,-3 M-4,0 L-1,3 M4,0 L1,-3 M4,0 L1,3"
            stroke="#ffffff"
            strokeWidth={1.5}
            strokeLinecap="round"
          />
        </g>

        {/* Quick 45° Snap Button on top right */}
        <g
          transform={`translate(${width / 2 - 28}, 0)`}
          className="cursor-pointer hover:scale-110 transition-transform"
          onPointerDown={(e) => {
            e.stopPropagation()
            onChangeRuler({ ...ruler, angle: (ruler.angle + 45) % 360 })
          }}
          onClick={(e) => {
            e.stopPropagation()
            onChangeRuler({ ...ruler, angle: (ruler.angle + 45) % 360 })
          }}
        >
          <title>Rotate 45°</title>
          <circle cx={0} cy={0} r={10} fill="#64748b" opacity={0.6} />
          <path
            d="M-3,-3 L3,-3 L3,3"
            fill="none"
            stroke="#ffffff"
            strokeWidth={1.2}
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
