import type { ExcalidrawImperativeAPI, NormalizedZoomValue } from "@excalidraw/excalidraw/types"

export type FormToolType = "rectangle" | "diamond" | "ellipse" | "arrow" | "line" | "frame"

export function isFormTool(tool: string): tool is FormToolType {
  return (
    tool === "rectangle" ||
    tool === "diamond" ||
    tool === "ellipse" ||
    tool === "arrow" ||
    tool === "line" ||
    tool === "frame"
  )
}

export function applyFreedraw(
  api: ExcalidrawImperativeAPI,
  tool: "pen" | "highlighter",
  color: string,
  strokeWidth: number
) {
  const isHighlighter = tool === "highlighter"
  api.setActiveTool({ type: "freedraw", locked: true })
  api.updateScene({
    appState: {
      currentItemStrokeColor: color,
      currentItemStrokeWidth: isHighlighter ? 18 : strokeWidth,
      currentItemOpacity: isHighlighter ? 45 : 100,
      currentItemRoughness: 0,
    },
  })
}

export function applyForm(
  api: ExcalidrawImperativeAPI,
  form: FormToolType,
  color: string,
  strokeWidth: number
) {
  api.setActiveTool({ type: form, locked: true })
  if (form === "frame") return
  api.updateScene({
    appState: {
      currentItemStrokeColor: color,
      currentItemStrokeWidth: strokeWidth,
      currentItemOpacity: 100,
      currentItemRoughness: 0,
    },
  })
}

export function applyToolToScene(
  api: ExcalidrawImperativeAPI,
  tool: string,
  color: string,
  strokeWidth: number
) {
  if (tool === "lasso") {
    api.setActiveTool({ type: "selection" })
    return
  }
  api.updateScene({ appState: { selectedElementIds: {} } })
  if (tool === "highlighter" || tool === "pen") {
    applyFreedraw(api, tool, color, strokeWidth)
    return
  }
  if (tool === "eraser" || tool === "laser" || tool === "text" || tool === "hand" || tool === "embeddable") {
    api.setActiveTool({ type: tool, locked: true })
    return
  }
  if (isFormTool(tool)) {
    applyForm(api, tool, color, strokeWidth)
  }
}

export function updateSelectedColor(api: ExcalidrawImperativeAPI | null, c: string) {
  if (!api) return
  const selectedIds = api.getAppState().selectedElementIds || {}
  if (Object.values(selectedIds).some(Boolean)) {
    const els = api.getSceneElements().map((el) => (
      selectedIds[el.id] ? { ...el, strokeColor: c } : el
    ))
    api.updateScene({ elements: els, appState: { currentItemStrokeColor: c } })
  } else {
    api.updateScene({ appState: { currentItemStrokeColor: c } })
  }
}

export function updateSelectedWidth(api: ExcalidrawImperativeAPI | null, w: number) {
  if (!api) return
  const selectedIds = api.getAppState().selectedElementIds || {}
  if (Object.values(selectedIds).some(Boolean)) {
    const els = api.getSceneElements().map((el) => (
      selectedIds[el.id] ? { ...el, strokeWidth: w } : el
    ))
    api.updateScene({ elements: els, appState: { currentItemStrokeWidth: w } })
  } else {
    api.updateScene({ appState: { currentItemStrokeWidth: w } })
  }
}

function isNormalizedZoom(v: number): v is NormalizedZoomValue {
  return Number.isFinite(v) && v > 0
}

export function toZoom(n: number): NormalizedZoomValue {
  let val = n
  if (isNormalizedZoom(val)) return val
  val = 1
  if (isNormalizedZoom(val)) return val
  throw new Error("Invalid zoom")
}

export function applySceneZoom(api: ExcalidrawImperativeAPI, zoom: number) {
  api.updateScene({
    appState: {
      zoom: { value: toZoom(zoom) },
      scrollX: 0,
      scrollY: 0,
    },
  })
  api.refresh()
}

export function triggerShortcutsHelp() {
  const el = document.querySelector(".goodnotes-canvas-root .excalidraw")
  el?.dispatchEvent(new KeyboardEvent("keydown", { key: "?", code: "Slash", shiftKey: true, bubbles: true }))
}
