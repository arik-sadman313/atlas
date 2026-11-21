import { getStroke } from "perfect-freehand"
import type { InkStroke } from "./types"

export function getSvgPathFromStroke(strokePoints: number[][], closed = true): string {
  const len = strokePoints.length
  if (len < 4) return ""

  let a = strokePoints[0]
  let b = strokePoints[1]
  const c = strokePoints[2]

  let result = `M${a[0].toFixed(2)},${a[1].toFixed(2)} Q${b[0].toFixed(2)},${b[1].toFixed(2)} ${((b[0] + c[0]) / 2).toFixed(2)},${((b[1] + c[1]) / 2).toFixed(2)}`

  for (let i = 2, max = len - 1; i < max; i++) {
    a = strokePoints[i]
    b = strokePoints[i + 1]
    result += ` t${(b[0] - a[0]).toFixed(2)},${(b[1] - a[1]).toFixed(2)}`
  }

  if (closed) {
    result += "Z"
  }

  return result
}

export function renderStrokeToPath(stroke: InkStroke): string {
  if (stroke.points.length === 0) return ""
  if (stroke.points.length === 1) {
    const p = stroke.points[0]
    const r = stroke.size / 2
    return `M${(p.x - r).toFixed(2)},${p.y.toFixed(2)} a${r},${r} 0 1,0 ${stroke.size},0 a${r},${r} 0 1,0 -${stroke.size},0`
  }

  const rawPoints = stroke.points.map((p) => [p.x, p.y, p.pressure ?? 0.5])

  const isFountain = stroke.tool === "fountain"
  const isHighlighter = stroke.tool === "highlighter"

  const strokeOptions = {
    size: stroke.size,
    thinning: isFountain ? 0.65 : isHighlighter ? 0.05 : 0.35,
    smoothing: 0.75,
    streamline: 0.65,
    simulatePressure: false,
    easing: (t: number) => t,
    start: {
      cap: true,
      taper: isFountain ? stroke.size * 0.8 : 0,
    },
    end: {
      cap: true,
      taper: isFountain ? stroke.size * 1.2 : 0,
    },
  }

  const outline = getStroke(rawPoints, strokeOptions)
  return getSvgPathFromStroke(outline)
}

export function isPointNearStroke(point: { x: number; y: number }, stroke: InkStroke, threshold = 12): boolean {
  const r = (stroke.size / 2) + threshold
  const r2 = r * r

  for (const p of stroke.points) {
    const dx = p.x - point.x
    const dy = p.y - point.y
    if (dx * dx + dy * dy <= r2) {
      return true
    }
  }
  return false
}

export function isStrokeInLasso(lassoPoints: { x: number; y: number }[], stroke: InkStroke): boolean {
  if (lassoPoints.length < 3 || stroke.points.length === 0) return false

  // Point in polygon ray-casting test for stroke centroid
  let sumX = 0, sumY = 0
  for (const p of stroke.points) {
    sumX += p.x
    sumY += p.y
  }
  const cx = sumX / stroke.points.length
  const cy = sumY / stroke.points.length

  let inside = false
  for (let i = 0, j = lassoPoints.length - 1; i < lassoPoints.length; j = i++) {
    const xi = lassoPoints[i].x, yi = lassoPoints[i].y
    const xj = lassoPoints[j].x, yj = lassoPoints[j].y
    const intersect = ((yi > cy) !== (yj > cy)) && (cx < (xj - xi) * (cy - yi) / (yj - yi) + xi)
    if (intersect) inside = !inside
  }
  return inside
}
