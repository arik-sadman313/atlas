import { getStroke } from "perfect-freehand"
import type { InkPoint, InkStroke, ShapePrimitive, RulerState, TapeStrip } from "./types"

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
 * Smooths out hand tremor using a moving-average stabilization window.
 */
export function stabilizePoints(points: InkPoint[], windowSize = 3): InkPoint[] {
  if (points.length <= windowSize) return points
  const stabilized: InkPoint[] = []

  for (let i = 0; i < points.length; i++) {
    const start = Math.max(0, i - windowSize + 1)
    const window = points.slice(start, i + 1)
    const avgX = window.reduce((sum, p) => sum + p.x, 0) / window.length
    const avgY = window.reduce((sum, p) => sum + p.y, 0) / window.length
    stabilized.push({
      ...points[i],
      x: avgX,
      y: avgY,
    })
  }

  return stabilized
}

/**
 * Snaps freehand highlighter points into a straight horizontal or vertical line.
 */
export function snapToStraightLine(points: InkPoint[]): InkPoint[] {
  if (points.length < 2) return points
  const first = points[0]
  const last = points[points.length - 1]
  const dx = Math.abs(last.x - first.x)
  const dy = Math.abs(last.y - first.y)

  // Horizontal snap
  if (dx >= dy) {
    return points.map((p) => ({ ...p, y: first.y }))
  }
  // Vertical snap
  return points.map((p) => ({ ...p, x: first.x }))
}

/**
 * Snaps a point to the straight edge of an on-screen interactive ruler.
 */
export function snapPointToRuler(
  pt: { x: number; y: number },
  ruler: RulerState,
  threshold = 28
): { x: number; y: number } | null {
  if (!ruler.active) return null

  const rad = (ruler.angle * Math.PI) / 180
  const dirX = Math.cos(rad)
  const dirY = Math.sin(rad)

  // Vector from ruler center to point
  const vx = pt.x - ruler.x
  const vy = pt.y - ruler.y

  // Distance along ruler length
  const rulerHalfWidth = (ruler.length || 500) / 2
  const along = vx * dirX + vy * dirY
  if (Math.abs(along) > rulerHalfWidth + 20) return null

  // Normal vector perpendicular to ruler
  const normX = -dirY
  const normY = dirX

  // Distance along perpendicular from centerline
  const perp = vx * normX + vy * normY

  // Straightedge ruler has thickness 70 (edges at -35 and +35)
  const halfH = 35
  const distToTop = Math.abs(perp - (-halfH))
  const distToBottom = Math.abs(perp - halfH)

  if (distToTop <= threshold) {
    const diff = perp - (-halfH)
    return {
      x: pt.x - diff * normX,
      y: pt.y - diff * normY,
    }
  }

  if (distToBottom <= threshold) {
    const diff = perp - halfH
    return {
      x: pt.x - diff * normX,
      y: pt.y - diff * normY,
    }
  }

  return null
}

/**
 * Tests whether a point is within threshold of a study tape strip.
 */
export function isPointNearTape(pt: { x: number; y: number }, tape: TapeStrip, threshold = 16): boolean {
  if (!tape.points || tape.points.length < 2) return false
  const p1 = tape.points[0]
  const p2 = tape.points[tape.points.length - 1]

  const l2 = (p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2
  if (l2 === 0) {
    return Math.hypot(pt.x - p1.x, pt.y - p1.y) <= (tape.width / 2 + threshold)
  }

  let t = ((pt.x - p1.x) * (p2.x - p1.x) + (pt.y - p1.y) * (p2.y - p1.y)) / l2
  t = Math.max(0, Math.min(1, t))
  const projX = p1.x + t * (p2.x - p1.x)
  const projY = p1.y + t * (p2.y - p1.y)

  return Math.hypot(pt.x - projX, pt.y - projY) <= (tape.width / 2 + threshold)
}

/**
 * Snaps a line's endpoint to vertices of existing shapes for flowchart connections.
 */
export function snapPointToShapeVertices(
  pt: { x: number; y: number },
  strokes: InkStroke[],
  threshold = 24
): { x: number; y: number } | null {
  let nearest: { x: number; y: number } | null = null
  let minDist = threshold

  for (const s of strokes) {
    if (!s.shapeType || s.points.length < 2) continue
    const first = s.points[0]
    const last = s.points[s.points.length - 1]

    const vertices: { x: number; y: number }[] = [
      first,
      last,
      { x: first.x, y: last.y },
      { x: last.x, y: first.y },
      { x: (first.x + last.x) / 2, y: first.y },
      { x: (first.x + last.x) / 2, y: last.y },
      { x: first.x, y: (first.y + last.y) / 2 },
      { x: last.x, y: (first.y + last.y) / 2 },
    ]

    for (const v of vertices) {
      const d = Math.hypot(pt.x - v.x, pt.y - v.y)
      if (d < minDist) {
        minDist = d
        nearest = v
      }
    }
  }

  return nearest
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

  // GoodNotes style pen physics tuning & configuration
  const isFountain = stroke.tool === "fountain"
  const isBrush = stroke.tool === "brush"
  const isHighlighter = stroke.tool === "highlighter"
  const isBallpoint = stroke.tool === "ballpoint" || stroke.tool === "pen"

  const tipSharpness = stroke.penSettings?.tipSharpness ?? (isFountain ? 75 : isBrush ? 85 : 10)
  const pressureSensitivity = stroke.penSettings?.pressureSensitivity ?? (isFountain ? 60 : isBrush ? 90 : 0)
  const stabilization = stroke.penSettings?.stabilization ?? (isFountain ? 45 : isBrush ? 35 : 50)

  const rawPoints = stroke.points.map((p) => {
    let pressure = p.pressure !== undefined && p.pressure > 0 ? p.pressure : 0.5
    if (isFountain) {
      const curve = Math.max(0.2, pressureSensitivity / 50)
      pressure = Math.min(1, Math.max(0.1, Math.pow(pressure, 1 / curve)))
    } else if (isBrush) {
      const curve = Math.max(0.2, pressureSensitivity / 50)
      pressure = Math.min(1, Math.max(0.05, Math.pow(pressure, 1 / curve)))
    } else if (isBallpoint || isHighlighter) {
      pressure = 0.5 // Constant pressure for uniform line weight
    }
    return [p.x, p.y, pressure]
  })

  let thinning = 0.35
  let smoothing = 0.55
  let streamline = 0.45
  let taperStart = 0
  let taperEnd = 0
  let simulatePressure = false
  let cap = true

  if (isBallpoint) {
    // Ballpoint Pen: uniform line weight, perfectly round tip, no pressure thinning
    thinning = 0
    smoothing = 0.65
    streamline = 0.35 + (stabilization / 100) * 0.4
    taperStart = 0
    taperEnd = 0
    simulatePressure = false
    cap = true
  } else if (isFountain) {
    // Fountain Pen: calligraphic pressure taper, sharp ends, responsive dynamic thinning
    thinning = 0.35 + (tipSharpness / 100) * 0.45
    smoothing = 0.5
    streamline = 0.3 + (stabilization / 100) * 0.45
    taperStart = (tipSharpness / 100) * stroke.size * 0.6
    taperEnd = (tipSharpness / 100) * stroke.size * 0.9
    simulatePressure = stroke.points.every((p) => p.pressure === undefined || p.pressure === 0.5)
    cap = true
  } else if (isBrush) {
    // Brush Pen: dynamic pressure sweep, calligraphic thicks and thins
    thinning = 0.7 + (pressureSensitivity / 100) * 0.25
    smoothing = 0.6
    streamline = 0.25 + (stabilization / 100) * 0.45
    taperStart = stroke.size * 0.8
    taperEnd = stroke.size * 1.5
    simulatePressure = true
    cap = true
  } else if (isHighlighter) {
    // Highlighter: uniform broad stroke underneath text
    thinning = 0
    smoothing = 0.65
    streamline = 0.5
    taperStart = 0
    taperEnd = 0
    simulatePressure = false
    cap = false
  }

  const strokeOptions = {
    size: stroke.size,
    thinning,
    smoothing,
    streamline,
    simulatePressure,
    easing: (t: number) => t,
    start: {
      cap,
      taper: taperStart,
    },
    end: {
      cap,
      taper: taperEnd,
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
    case "arc": {
      const dx = last.x - first.x
      const dy = last.y - first.y
      const r = Math.hypot(dx, dy)
      return `M${first.x},${first.y} A${r},${r} 0 0,1 ${last.x},${last.y}`
    }
    case "polygon": {
      // Hexagonal polygon bounding box
      const minX = Math.min(first.x, last.x)
      const minY = Math.min(first.y, last.y)
      const w = Math.abs(last.x - first.x)
      const h = Math.abs(last.y - first.y)
      const p1 = `${minX + w * 0.25},${minY}`
      const p2 = `${minX + w * 0.75},${minY}`
      const p3 = `${minX + w},${minY + h * 0.5}`
      const p4 = `${minX + w * 0.75},${minY + h}`
      const p5 = `${minX + w * 0.25},${minY + h}`
      const p6 = `${minX},${minY + h * 0.5}`
      return `M${p1} L${p2} L${p3} L${p4} L${p5} L${p6} Z`
    }
    default:
      return ""
  }
}

/**
 * Detects if drawn freehand points approximate a geometric shape (Line, Circle, Rectangle, Triangle, Arrow, Polygon).
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

      // Check if top is narrow (triangle)
      const topPoints = points.filter((p) => p.y < minY + h * 0.3)
      const topWidth = topPoints.length > 0 ? Math.max(...topPoints.map((p) => p.x)) - Math.min(...topPoints.map((p) => p.x)) : w
      if (topWidth < w * 0.45) {
        return "triangle"
      }

      return "rect"
    }
  }

  return null
}

/**
 * Checks whether given pointer coordinates hit or pass near a stroke.
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
 * Tests if a stroke's centroid lies inside a lasso polygon or rectangle.
 */
function isPointInPolygon(pt: { x: number; y: number }, polygon: { x: number; y: number }[]): boolean {
  let inside = false
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].x, yi = polygon[i].y
    const xj = polygon[j].x, yj = polygon[j].y
    const intersect = ((yi > pt.y) !== (yj > pt.y)) && (pt.x < ((xj - xi) * (pt.y - yi)) / (yj - yi) + xi)
    if (intersect) inside = !inside
  }
  return inside
}

/**
 * Tests if a stroke's centroid or any of its points lies inside a lasso polygon.
 */
export function isStrokeInLasso(lassoPoints: { x: number; y: number }[], stroke: InkStroke): boolean {
  if (lassoPoints.length < 3 || stroke.points.length === 0) return false

  let sumX = 0, sumY = 0
  for (const p of stroke.points) {
    sumX += p.x
    sumY += p.y
  }
  const centroid = { x: sumX / stroke.points.length, y: sumY / stroke.points.length }
  if (isPointInPolygon(centroid, lassoPoints)) return true

  for (const p of stroke.points) {
    if (isPointInPolygon(p, lassoPoints)) return true
  }

  return false
}

export function isBoxInLasso(lassoPoints: { x: number; y: number }[], box: { x: number; y: number; width: number; height: number }): boolean {
  if (lassoPoints.length < 3) return false
  const cx = box.x + box.width / 2
  const cy = box.y + box.height / 2

  if (isPointInPolygon({ x: cx, y: cy }, lassoPoints)) return true

  const corners = [
    { x: box.x, y: box.y },
    { x: box.x + box.width, y: box.y },
    { x: box.x + box.width, y: box.y + box.height },
    { x: box.x, y: box.y + box.height },
  ]
  for (const c of corners) {
    if (isPointInPolygon(c, lassoPoints)) return true
  }

  return false
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

/**
 * Scales strokes relative to an origin point.
 */
export function scaleStroke(stroke: InkStroke, sx: number, sy: number, origin: { x: number; y: number }): InkStroke {
  return {
    ...stroke,
    size: Math.max(1, stroke.size * Math.sqrt(Math.abs(sx * sy))),
    points: stroke.points.map((p) => ({
      ...p,
      x: origin.x + (p.x - origin.x) * sx,
      y: origin.y + (p.y - origin.y) * sy,
    })),
  }
}

/**
 * Rotates strokes around an origin point.
 */
export function rotateStroke(stroke: InkStroke, angleRad: number, origin: { x: number; y: number }): InkStroke {
  const cos = Math.cos(angleRad)
  const sin = Math.sin(angleRad)
  return {
    ...stroke,
    points: stroke.points.map((p) => {
      const dx = p.x - origin.x
      const dy = p.y - origin.y
      return {
        ...p,
        x: origin.x + dx * cos - dy * sin,
        y: origin.y + dx * sin + dy * cos,
      }
    }),
  }
}

/**
 * Simulated OCR Transcription for handwriting to text conversion.
 */
export function convertStrokesToText(strokes: InkStroke[]): string {
  if (strokes.length === 0) return ""
  return `Handwritten note transcribed on ${new Date().toLocaleDateString()}:\n` +
    strokes.map((s, idx) => `[Stroke ${idx + 1}: ${s.tool} in ${s.color}]`).join(" ")
}

/**
 * Simulated Math formula parser for handwriting to LaTeX conversion.
 */
export function convertStrokesToMath(strokes: InkStroke[]): string {
  if (strokes.length === 0) return ""
  const samples = [
    "f(x) = \\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}",
    "E = mc^2",
    "\\sum_{k=1}^{n} k = \\frac{n(n+1)}{2}",
    "\\lim_{x \\to 0} \\frac{\\sin x}{x} = 1",
    "\\nabla \\times \\mathbf{B} = \\mu_0 \\mathbf{J} + \\mu_0 \\varepsilon_0 \\frac{\\partial \\mathbf{E}}{\\partial t}",
  ]
  return samples[strokes.length % samples.length]
}
