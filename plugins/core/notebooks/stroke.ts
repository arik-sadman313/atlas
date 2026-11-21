import { getStroke } from "perfect-freehand"
import type { InkStroke, ShapePrimitive } from "./types"

/**
 * Converts outline polygon points from perfect-freehand into a smooth SVG path.
 * Uses exact Quadratic Bezier Spline interpolation.
 */
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
    result += ` Q${a[0].toFixed(2)},${a[1].toFixed(2)} ${((a[0] + b[0]) / 2).toFixed(2)},${((a[1] + b[1]) / 2).toFixed(2)}`
  }

  if (closed) {
    result += "Z"
  }

  return result
}

/**
 * Renders an InkStroke into an SVG path or geometric shape.
 */
export function renderStrokeToPath(stroke: InkStroke): string {
  if (stroke.points.length === 0) return ""

  // Geometric primitive handling
  if (stroke.shapeType) {
    return renderShapePrimitive(stroke)
  }

  // Single point (dot / tap)
  if (stroke.points.length === 1) {
    const p = stroke.points[0]
    const r = stroke.size / 2
    return `M${(p.x - r).toFixed(2)},${p.y.toFixed(2)} a${r},${r} 0 1,0 ${stroke.size},0 a${r},${r} 0 1,0 -${stroke.size},0`
  }

  const rawPoints = stroke.points.map((p) => [
    p.x,
    p.y,
    p.pressure !== undefined && p.pressure > 0 ? p.pressure : 0.5,
  ])

  // GoodNotes style pen physics tuning
  const isFountain = stroke.tool === "fountain"
  const isBrush = stroke.tool === "brush"
  const isHighlighter = stroke.tool === "highlighter"
  const isBallpoint = stroke.tool === "ballpoint" || stroke.tool === "pen"

  const strokeOptions = {
    size: stroke.size,
    thinning: isBrush ? 0.85 : isFountain ? 0.6 : isHighlighter ? 0 : isBallpoint ? 0.05 : 0.35,
    smoothing: 0.55,
    streamline: 0.45,
    simulatePressure: stroke.points.every((p) => p.pressure === undefined || p.pressure === 0.5),
    easing: (t: number) => t,
    start: {
      cap: true,
      taper: isBrush ? stroke.size * 0.8 : isFountain ? stroke.size * 0.4 : 0,
    },
    end: {
      cap: true,
      taper: isBrush ? stroke.size * 1.2 : isFountain ? stroke.size * 0.6 : 0,
    },
  }

  const outline = getStroke(rawPoints, strokeOptions)
  return getSvgPathFromStroke(outline)
}

function renderShapePrimitive(stroke: InkStroke): string {
  const pts = stroke.points
  if (pts.length < 2) return ""
  const first = pts[0]
  const last = pts[pts.length - 1]

  switch (stroke.shapeType) {
    case "line": {
      return `M${first.x.toFixed(2)},${first.y.toFixed(2)} L${last.x.toFixed(2)},${last.y.toFixed(2)}`
    }
    case "arrow": {
      const dx = last.x - first.x
      const dy = last.y - first.y
      const angle = Math.atan2(dy, dx)
      const headLen = Math.max(16, stroke.size * 3)
      const a1 = angle - Math.PI / 6
      const a2 = angle + Math.PI / 6
      const x1 = last.x - headLen * Math.cos(a1)
      const y1 = last.y - headLen * Math.sin(a1)
      const x2 = last.x - headLen * Math.cos(a2)
      const y2 = last.y - headLen * Math.sin(a2)
      return `M${first.x.toFixed(2)},${first.y.toFixed(2)} L${last.x.toFixed(2)},${last.y.toFixed(2)} M${x1.toFixed(2)},${y1.toFixed(2)} L${last.x.toFixed(2)},${last.y.toFixed(2)} L${x2.toFixed(2)},${y2.toFixed(2)}`
    }
    case "rect": {
      const minX = Math.min(first.x, last.x)
      const minY = Math.min(first.y, last.y)
      const width = Math.abs(last.x - first.x)
      const height = Math.abs(last.y - first.y)
      return `M${minX},${minY} H${minX + width} V${minY + height} H${minX} Z`
    }
    case "ellipse": {
      const cx = (first.x + last.x) / 2
      const cy = (first.y + last.y) / 2
      const rx = Math.abs(last.x - first.x) / 2
      const ry = Math.abs(last.y - first.y) / 2
      return `M${cx - rx},${cy} a${rx},${ry} 0 1,0 ${rx * 2},0 a${rx},${ry} 0 1,0 -${rx * 2},0`
    }
    case "triangle": {
      const topX = (first.x + last.x) / 2
      const topY = Math.min(first.y, last.y)
      const bottomY = Math.max(first.y, last.y)
      const leftX = Math.min(first.x, last.x)
      const rightX = Math.max(first.x, last.x)
      return `M${topX},${topY} L${rightX},${bottomY} L${leftX},${bottomY} Z`
    }
    default:
      return ""
  }
}

/**
 * Detects if drawn freehand points approximate a geometric shape (Line, Circle, Rectangle, Triangle).
 */
export function detectGeometricShape(points: { x: number; y: number }[]): ShapePrimitive | null {
  if (points.length < 8) return null

  const first = points[0]
  const last = points[points.length - 1]
  const totalDist = Math.hypot(last.x - first.x, last.y - first.y)

  let pathLen = 0
  for (let i = 1; i < points.length; i++) {
    pathLen += Math.hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y)
  }

  // 1. Straight Line Check: path length close to direct Euclidean distance
  if (pathLen > 40 && totalDist / pathLen > 0.94) {
    return "line"
  }

  // 2. Closed Shape Check: start and end are close
  const isClosed = totalDist < Math.max(35, pathLen * 0.15)
  if (isClosed && points.length > 15) {
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
    for (const p of points) {
      if (p.x < minX) minX = p.x
      if (p.y < minY) minY = p.y
      if (p.x > maxX) maxX = p.x
      if (p.y > maxY) maxY = p.y
    }
    const w = maxX - minX
    const h = maxY - minY
    if (w > 30 && h > 30) {
      const cx = (minX + maxX) / 2
      const cy = (minY + maxY) / 2
      const avgR = (w + h) / 4

      // Check distance variance from center for circle/ellipse
      let radiusVariance = 0
      for (const p of points) {
        const d = Math.hypot(p.x - cx, p.y - cy)
        radiusVariance += Math.abs(d - avgR)
      }
      radiusVariance /= points.length

      if (radiusVariance / avgR < 0.22) {
        return "ellipse"
      }

      return "rect"
    }
  }

  return null
}

/**
 * Checks whether a given pointer coordinates hit or pass near a stroke.
 */
export function isPointNearStroke(point: { x: number; y: number }, stroke: InkStroke, threshold = 12): boolean {
  const r = stroke.size / 2 + threshold
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

/**
 * Tests if a stroke's centroid lies inside a freehand lasso polygon.
 */
export function isStrokeInLasso(lassoPoints: { x: number; y: number }[], stroke: InkStroke): boolean {
  if (lassoPoints.length < 3 || stroke.points.length === 0) return false

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
    const intersect = ((yi > cy) !== (yj > cy)) && (cx < ((xj - xi) * (cy - yi)) / (yj - yi) + xi)
    if (intersect) inside = !inside
  }
  return inside
}

export function isBoxInLasso(lassoPoints: { x: number; y: number }[], box: { x: number; y: number; width: number; height: number }): boolean {
  if (lassoPoints.length < 3) return false
  const cx = box.x + box.width / 2
  const cy = box.y + box.height / 2

  let inside = false
  for (let i = 0, j = lassoPoints.length - 1; i < lassoPoints.length; j = i++) {
    const xi = lassoPoints[i].x, yi = lassoPoints[i].y
    const xj = lassoPoints[j].x, yj = lassoPoints[j].y
    const intersect = ((yi > cy) !== (yj > cy)) && (cx < ((xj - xi) * (cy - yi)) / (yj - yi) + xi)
    if (intersect) inside = !inside
  }
  return inside
}

/**
 * Computes bounding rectangle of a set of strokes.
 */
export function getStrokesBounds(strokes: InkStroke[]): { minX: number; minY: number; maxX: number; maxY: number } | null {
  if (strokes.length === 0) return null

  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
  for (const s of strokes) {
    for (const p of s.points) {
      if (p.x < minX) minX = p.x
      if (p.y < minY) minY = p.y
      if (p.x > maxX) maxX = p.x
      if (p.y > maxY) maxY = p.y
    }
  }

  if (minX === Infinity) return null
  return { minX, minY, maxX, maxY }
}

/**
 * Translates stroke points by delta X and delta Y.
 */
export function translateStroke(stroke: InkStroke, dx: number, dy: number): InkStroke {
  return {
    ...stroke,
    points: stroke.points.map((p) => ({
      ...p,
      x: p.x + dx,
      y: p.y + dy,
    })),
  }
}
