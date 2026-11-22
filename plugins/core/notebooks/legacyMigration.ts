import { restoreElements } from "@excalidraw/excalidraw"
import type { ExcalidrawElement } from "@excalidraw/excalidraw/element/types"
import type { NotebookPage, InkStroke, InkTextBox } from "./types"

type FigureSkeleton = Partial<ExcalidrawElement> & {
  points?: readonly (readonly [number, number])[]
  pressures?: readonly number[]
  text?: string
}

function getStrokeBounds(stroke: InkStroke) {
  let minX = stroke.points[0]?.x ?? 0
  let minY = stroke.points[0]?.y ?? 0
  let maxX = minX
  let maxY = minY
  for (let i = 1; i < stroke.points.length; i++) {
    const pt = stroke.points[i]
    if (pt.x < minX) minX = pt.x
    if (pt.y < minY) minY = pt.y
    if (pt.x > maxX) maxX = pt.x
    if (pt.y > maxY) maxY = pt.y
  }
  return { minX, minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) }
}

function convertStrokeToEnclosure(
  stroke: InkStroke,
  form: string,
  minX: number,
  minY: number,
  width: number,
  height: number
): FigureSkeleton | null {
  if (form === "rect" || form === "ellipse") {
    return {
      id: stroke.id,
      type: form === "rect" ? "rectangle" : "ellipse",
      x: minX,
      y: minY,
      width,
      height,
      strokeColor: stroke.color,
      backgroundColor: stroke.fill || "transparent",
      strokeWidth: Math.max(1, stroke.size),
      roughness: 0,
    }
  }
  if (form === "line" || form === "arrow") {
    const p0 = stroke.points[0]
    const pN = stroke.points[stroke.points.length - 1]
    const linePoints: readonly (readonly [number, number])[] = [
      [0, 0],
      [pN.x - p0.x, pN.y - p0.y],
    ]
    return {
      id: stroke.id,
      type: form === "arrow" ? "arrow" : "line",
      x: p0.x,
      y: p0.y,
      width: Math.abs(pN.x - p0.x) || 1,
      height: Math.abs(pN.y - p0.y) || 1,
      points: linePoints,
      strokeColor: stroke.color,
      strokeWidth: Math.max(1, stroke.size),
      roughness: 0,
    }
  }
  return null
}

function convertStrokeToFreedraw(
  stroke: InkStroke,
  minX: number,
  minY: number,
  width: number,
  height: number
): FigureSkeleton {
  const isHighlighter = stroke.tool === "highlighter" || stroke.size >= 12
  const freePoints: readonly (readonly [number, number])[] = stroke.points.map(
    (p): readonly [number, number] => [p.x - minX, p.y - minY]
  )
  return {
    id: stroke.id,
    type: "freedraw",
    x: minX,
    y: minY,
    width,
    height,
    points: freePoints,
    pressures: stroke.points.map((p) => p.pressure ?? 0.5),
    simulatePressure: false,
    strokeColor: stroke.color,
    strokeWidth: isHighlighter ? Math.max(12, stroke.size) : Math.max(1, stroke.size),
    opacity: isHighlighter ? 45 : 100,
    roughness: 0,
  }
}

function convertStrokeToFigure(stroke: InkStroke): FigureSkeleton | null {
  if (!stroke.points || stroke.points.length < 2) return null
  const { minX, minY, width, height } = getStrokeBounds(stroke)
  const form = stroke.shapeType
  if (form) {
    const enclosure = convertStrokeToEnclosure(stroke, form, minX, minY, width, height)
    if (enclosure) return enclosure
  }
  return convertStrokeToFreedraw(stroke, minX, minY, width, height)
}

function convertBoxToFigure(box: InkTextBox): FigureSkeleton | null {
  if (!box.text) return null
  return {
    id: box.id,
    type: "text",
    x: box.x,
    y: box.y,
    width: box.width || 120,
    height: box.height || 36,
    text: box.text,
    fontSize: box.fontSize || 20,
    strokeColor: box.color || "#1e293b",
    textAlign: box.align || "left",
  }
}

export function migrateLegacyPageToExcalidraw(page: NotebookPage): readonly ExcalidrawElement[] {
  if (page.elements && page.elements.length > 0) {
    return page.elements
  }
  const skeletons: FigureSkeleton[] = []
  if (Array.isArray(page.strokes)) {
    for (const s of page.strokes) {
      const fig = convertStrokeToFigure(s)
      if (fig) skeletons.push(fig)
    }
  }
  if (Array.isArray(page.textBoxes)) {
    for (const b of page.textBoxes) {
      const fig = convertBoxToFigure(b)
      if (fig) skeletons.push(fig)
    }
  }
  if (skeletons.length === 0) return []
  // oxlint-disable-next-line vaultite/no-cast -- Excalidraw restoreElements normalizes partial element definitions
  return restoreElements(skeletons as ExcalidrawElement[], null)
}
