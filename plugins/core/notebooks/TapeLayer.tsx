import React from "react"
import type { TapeStrip } from "./types"

interface TapeLayerProps {
  tapeStrips: TapeStrip[]
  isStudyMode: boolean
  onToggleReveal?: (tapeId: string) => void
}

export const TapeLayer: React.FC<TapeLayerProps> = ({
  tapeStrips,
  isStudyMode,
  onToggleReveal,
}) => {
  if (!tapeStrips || tapeStrips.length === 0) return null

  return (
    <g className="notebook-tape-layer">
      <defs>
        {/* Diagonal stripes tape pattern */}
        <pattern id="tape-stripes" width="12" height="12" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse">
          <line x1="0" y1="0" x2="0" y2="12" stroke="rgba(255,255,255,0.45)" strokeWidth="4" />
        </pattern>
        {/* Dotted tape pattern */}
        <pattern id="tape-dots" width="10" height="10" patternUnits="userSpaceOnUse">
          <circle cx="5" cy="5" r="2" fill="rgba(255,255,255,0.5)" />
        </pattern>
      </defs>

      {tapeStrips.map((tape) => {
        if (tape.points.length < 2) return null
        const first = tape.points[0]
        const last = tape.points[tape.points.length - 1]

        // Calculate path for the tape strip
        const dx = last.x - first.x
        const dy = last.y - first.y
        const angle = Math.atan2(dy, dx)
        const halfWidth = tape.width / 2

        const perpX = -Math.sin(angle) * halfWidth
        const perpY = Math.cos(angle) * halfWidth

        const p1 = `${(first.x + perpX).toFixed(2)},${(first.y + perpY).toFixed(2)}`
        const p2 = `${(last.x + perpX).toFixed(2)},${(last.y + perpY).toFixed(2)}`
        const p3 = `${(last.x - perpX).toFixed(2)},${(last.y - perpY).toFixed(2)}`
        const p4 = `${(first.x - perpX).toFixed(2)},${(first.y - perpY).toFixed(2)}`

        const pathData = `M${p1} L${p2} L${p3} L${p4} Z`
        const isRevealed = tape.revealed

        return (
          <g
            key={tape.id}
            className={`transition-all duration-300 ${
              isStudyMode ? "cursor-pointer" : "cursor-default"
            }`}
            onPointerDown={(e) => {
              if (isStudyMode) {
                e.stopPropagation()
                onToggleReveal?.(tape.id)
              }
            }}
            onClick={(e) => {
              if (isStudyMode) {
                e.stopPropagation()
                onToggleReveal?.(tape.id)
              }
            }}
          >
            {/* Base Tape Strip (Solid Color) */}
            <path
              d={pathData}
              fill={tape.color || "#f59e0b"}
              opacity={isRevealed ? 0.08 : 0.95}
              stroke={isRevealed ? "rgba(0,0,0,0.15)" : "rgba(0,0,0,0.1)"}
              strokeWidth={1}
              strokeDasharray={isRevealed ? "4,4" : undefined}
              className="transition-all duration-300"
            />

            {/* Pattern Overlay */}
            {!isRevealed && tape.pattern === "stripes" && (
              <path d={pathData} fill="url(#tape-stripes)" opacity={0.8} />
            )}
            {!isRevealed && tape.pattern === "dots" && (
              <path d={pathData} fill="url(#tape-dots)" opacity={0.8} />
            )}

            {/* Tape serrated edges on ends */}
            {!isRevealed && (
              <>
                <circle cx={first.x} cy={first.y} r={2} fill="rgba(0,0,0,0.3)" />
                <circle cx={last.x} cy={last.y} r={2} fill="rgba(0,0,0,0.3)" />
              </>
            )}

            {/* Study Mode Tape Peel Indicator */}
            {isStudyMode && (
              <text
                x={(first.x + last.x) / 2}
                y={(first.y + last.y) / 2 + 3}
                textAnchor="middle"
                fontSize={tape.width * 0.4}
                fill={isRevealed ? "#64748b" : "#ffffff"}
                fontWeight="bold"
                className="select-none pointer-events-none"
              >
                {isRevealed ? "Peel: Revealed (Tap to hide)" : "Tap to reveal"}
              </text>
            )}
          </g>
        )
      })}
    </g>
  )
}
