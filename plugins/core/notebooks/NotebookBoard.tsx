import { useState, useRef, useCallback, useEffect, useMemo } from "react"
import {
  Pen,
  Highlighter,
  Eraser,
  Lasso,
  Type,
  StickyNote,
  Square,
  Circle,
  Minus,
  ArrowUpRight,
  Image as ImageIcon,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  ChevronDown,
  GripHorizontal,
  Plus,
  Copy,
  Trash2,
  Undo2,
  Redo2,
  Hand,
  ZoomIn,
  ZoomOut,
  Star,
  Layers,
  Maximize2,
  Minimize2,
  Download,
  Eye,
  Edit3,
  Sparkles,
  Compass,
  Radio,
  Palette,
  Feather,
  Triangle,
  RotateCw,
  Camera,
  X,
} from "lucide-react"
import {
  type NotebookDocument,
  type NotebookPage,
  type InkStroke,
  type InkTextBox,
  type NotebookImage,
  type TapeStrip,
  type ShapePrimitive,
  type InkToolType,
  type EraserMode,
  type LassoFilter,
  type RulerState,
  type LaserState,
  type ZoomWindowState,
  type NotebookElement,
  type AudioRecording,
  type AudioEvent,
  type PenStudioSettings,
  DEFAULT_PEN_SETTINGS,
  createEmptyNotebook,
  createEmptyPage,
} from "./types"
import {
  renderStrokeToPath,
  isPointNearStroke,
  isSegmentNearStroke,
  eraseStrokeAtPoint,
  isPointNearTape,
  isStrokeInLasso,
  isBoxInLasso,
  isStrokeInRect,
  isBoxInRect,
  translateStroke,
  scaleStroke,
  rotateStroke,
  detectGeometricShape,
  snapToStraightLine,
  snapPointToRuler,
  snapPointToShapeVertices,
  convertStrokesToText,
  convertStrokesToMath,
} from "./stroke"
import { TapeLayer } from "./TapeLayer"
import { AudioSyncEngine } from "./AudioSyncEngine"
import { RulerOverlay } from "./RulerAndLaser"
import { ZoomWindow } from "./ZoomWindow"
import { ElementsDrawer } from "./ElementsDrawer"
import { DocumentNavigationDrawer } from "./DocumentNavigationDrawer"
import { PenStudioPopover } from "./PenStudioPopover"
import { ColorStudioPopover } from "./ColorStudioPopover"

interface NotebookBoardProps {
  text: string
  path?: string
  editable?: boolean
  place?: string
  onChange?: (newText: string) => void
}

// Stroke path cache for 60-120fps fluid iPad rendering without quadratic bezier recalculation
const strokePathCache = new Map<string, string>()

function getCachedStrokePath(stroke: InkStroke): string {
  if (!stroke.id) return renderStrokeToPath(stroke)
  const key = `${stroke.id}_${stroke.points.length}_${stroke.size}_${stroke.color}`
  let path = strokePathCache.get(key)
  if (!path) {
    path = renderStrokeToPath(stroke)
    strokePathCache.set(key, path)
    if (strokePathCache.size > 2000) {
      const firstKey = strokePathCache.keys().next().value
      if (firstKey) strokePathCache.delete(firstKey)
    }
  }
  return path
}

function getStrokeStyle(s: InkStroke) {
  if (s.shapeType) {
    const isLineLike = s.shapeType === "line" || s.shapeType === "arrow" || s.shapeType === "arc"
    return {
      fill: isLineLike ? "none" : (s.fill || "none"),
      stroke: s.color,
      strokeWidth: s.size,
      strokeLinecap: "round" as const,
      strokeLinejoin: "round" as const,
    }
  }
  return {
    fill: s.color,
    stroke: "none",
    strokeWidth: 0,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  }
}

const STICKY_COLORS = [
  { bg: "#fef08a", border: "#facc15", text: "#713f12" }, // yellow
  { bg: "#fed7aa", border: "#fb923c", text: "#7c2d12" }, // orange
  { bg: "#bbf7d0", border: "#4ade80", text: "#14532d" }, // green
  { bg: "#bfdbfe", border: "#60a5fa", text: "#1e3a8a" }, // blue
  { bg: "#fbcfe8", border: "#f472b6", text: "#831843" }, // pink
]

export default function NotebookBoard({
  text,
  path,
  editable = true,
  place: _place = "pane",
  onChange,
}: NotebookBoardProps) {
  // Parse document
  const [doc, setDoc] = useState<NotebookDocument>(() => {
    try {
      if (text.trim()) {
        const parsed = JSON.parse(text)
        if (parsed.pages && Array.isArray(parsed.pages)) {
          return parsed as NotebookDocument
        }
      }
    } catch {
      // Fallback
    }
    return createEmptyNotebook(path ? path.split("/").pop()?.replace(".notebook", "") : "Untitled Notebook")
  })

  const [currentPageIndex, setCurrentPageIndex] = useState(0)

  // Read-Only View Lock (disables editing inputs, allows hyperlinking & study tape peeling)
  const [readOnly, setReadOnly] = useState(!editable)

  // Primary Tool Modes
  const [activeTool, setActiveTool] = useState<InkToolType>("fountain")
  const [previousTool, setPreviousTool] = useState<InkToolType>("fountain")

  // Pen Studio & Configurable Physics
  const [isPenStudioOpen, setIsPenStudioOpen] = useState(false)
  const [penSettings, setPenSettings] = useState<PenStudioSettings>(DEFAULT_PEN_SETTINGS)

  // Eraser Settings
  const [eraserMode, setEraserMode] = useState<EraserMode>("standard")
  const [eraseHighlighterOnly, setEraseHighlighterOnly] = useState(false)
  const [autoDeselectEraser, setAutoDeselectEraser] = useState(false)

  // Shape Settings
  const [shapeToolPrimitive, setShapeToolPrimitive] = useState<ShapePrimitive>("rect")
  const [autoShapeDetection, setAutoShapeDetection] = useState(true)
  const [shapeFill, setShapeFill] = useState(false)
  const [snapToOtherShapes, setSnapToOtherShapes] = useState(true)

  // Highlighter Settings
  const [straightLineHighlighter, setStraightLineHighlighter] = useState(false)

  // Tape Settings
  const [tapePattern, setTapePattern] = useState<"solid" | "stripes" | "dots">("stripes")
  const [tapeColor, setTapeColor] = useState("#f59e0b")

  // Color Studio & 3 Quick Color Slots
  const [isColorStudioOpen, setIsColorStudioOpen] = useState(false)
  const [activeQuickSlot, setActiveQuickSlot] = useState(0)
  const [quickColors, setQuickColors] = useState(["#1e293b", "#2563eb", "#dc2626"])
  const [activeColor, setActiveColor] = useState("#1e293b")
  const quickSizes = [2, 4, 8]
  const [activeSize, setActiveSize] = useState(4)

  // Stylus Palm Rejection Mode & iPad Auto-detection
  const [drawWithFinger, setDrawWithFinger] = useState(true)
  const [stylusDetected, setStylusDetected] = useState(false)

  // Viewport & Chrome
  const [zoomLevel, setZoomLevel] = useState(1.0)
  const [zenMode, setZenMode] = useState(false)
  const [isNavDrawerOpen, setIsNavDrawerOpen] = useState(false)
  const [isElementsDrawerOpen, setIsElementsDrawerOpen] = useState(false)

  // Multi-Touch Gesture Reference for iPad Pinch-to-Zoom and Pan
  const containerRef = useRef<HTMLDivElement | null>(null)
  const touchStateRef = useRef<{
    initialDist: number
    initialZoom: number
    initialCenter: { x: number; y: number }
    initialScroll: { left: number; top: number }
  } | null>(null)

  // Ruler & Laser Pointer States
  const [rulerState, setRulerState] = useState<RulerState>({
    active: false,
    x: 400,
    y: 550,
    angle: 0,
    length: 500,
  })
  const [laserState, setLaserState] = useState<LaserState>({
    active: false,
    mode: "trail",
    current: null,
    trail: [],
  })

  // Zoom Window State
  const [zoomWindowState, setZoomWindowState] = useState<ZoomWindowState>({
    active: false,
    scale: 2.5,
    x: 0,
    y: 0,
    width: 560,
    height: 220,
    targetX: 100,
    targetY: 200,
  })

  // Reusable Elements (Custom Saved Stickers)
  const [customElements, setCustomElements] = useState<NotebookElement[]>([])

  // Audio Sync State
  const [audioEvents, setAudioEvents] = useState<AudioEvent[]>([])
  const [activeRecording, setActiveRecording] = useState<AudioRecording | null>(
    doc.audioRecordings?.[0] || null
  )
  const [playbackTimeMs, setPlaybackTimeMs] = useState(0)
  const [isPlaybackActive, setIsPlaybackActive] = useState(false)
  const recordingStartTimeRef = useRef(0)
  const playbackTimerRef = useRef<number | null>(null)

  // Stroke in-progress
  const [currentStroke, setCurrentStroke] = useState<InkStroke | null>(null)
  const strokeStartTimeRef = useRef(0)

  // Lasso Selection & Granular Filters
  const [lassoMode, setLassoMode] = useState<"freehand" | "rect">("freehand")
  const [lassoPoints, setLassoPoints] = useState<{ x: number; y: number }[]>([])
  const [selectedStrokeIds, setSelectedStrokeIds] = useState<Set<string>>(new Set())
  const [selectedBoxIds, setSelectedBoxIds] = useState<Set<string>>(new Set())
  const [selectedImageIds, setSelectedImageIds] = useState<Set<string>>(new Set())
  const [activeImageId, setActiveImageId] = useState<string | null>(null)
  const [isDraggingSelection, setIsDraggingSelection] = useState(false)
  const dragStartPointRef = useRef<{ x: number; y: number } | null>(null)
  const lassoPointsRef = useRef<{ x: number; y: number }[]>([])
  const lassoRafIdRef = useRef<number | null>(null)
  const dragRafIdRef = useRef<number | null>(null)
  const deleteSelectedRef = useRef<() => void>(() => {})
  const duplicateSelectedRef = useRef<() => void>(() => {})
  const [lassoFilter, setLassoFilter] = useState<LassoFilter>({
    handwriting: true,
    images: true,
    textBoxes: true,
    stickyNotes: true,
  })

  // Study Tape Draft (in-progress dragging)
  const [activeTapeDraft, setActiveTapeDraft] = useState<{ start: { x: number; y: number }; current: { x: number; y: number } } | null>(null)
  const activeTapeDraftRef = useRef<{ start: { x: number; y: number }; current: { x: number; y: number } } | null>(null)

  // Canvas pointer position (for Eraser cursor circle indicator)
  const [canvasPointerPos, setCanvasPointerPos] = useState<{ x: number; y: number } | null>(null)

  // Shape Draw-and-Hold timer & lock ref
  const shapeHoldTimerRef = useRef<any>(null)
  const isShapeLockedRef = useRef(false)
  const currentStrokeRef = useRef<InkStroke | null>(null)
  currentStrokeRef.current = currentStroke

  // Advanced selection and tool state refs
  const initialSelectionSnapshotRef = useRef<{
    strokes: Map<string, InkStroke>
    boxes: Map<string, InkTextBox>
    images: Map<string, NotebookImage>
    startPt: { x: number; y: number }
  } | null>(null)
  const lastEraserPointRef = useRef<{ x: number; y: number } | null>(null)
  const rulerLockedEdgeRef = useRef<"top" | "bottom" | null>(null)
  const [laserPopoverOpen, setLaserPopoverOpen] = useState(false)

  // Undo / Redo history stacks
  const [history, setHistory] = useState<NotebookPage[]>([])
  const [redoStack, setRedoStack] = useState<NotebookPage[]>([])

  // Active editing text box
  const [editingBoxId, setEditingBoxId] = useState<string | null>(null)

  const svgRef = useRef<SVGSVGElement | null>(null)
  const isDrawingRef = useRef(false)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  const docRef = useRef<NotebookDocument>(doc)
  docRef.current = doc

  const currentPage = doc.pages[currentPageIndex] || doc.pages[0]

  // Persist helper
  const commitDoc = useCallback(
    (newDoc: NotebookDocument) => {
      docRef.current = newDoc
      setDoc(newDoc)
      if (onChange) {
        onChange(JSON.stringify(newDoc, null, "\t") + "\n")
      }
    },
    [onChange]
  )

  const pushHistory = useCallback(() => {
    setHistory((prev) => [...prev.slice(-30), JSON.parse(JSON.stringify(currentPage))])
    setRedoStack([])
  }, [currentPage])

  const undo = useCallback(() => {
    if (history.length === 0) return
    const prevPage = history[history.length - 1]
    const updatedHistory = history.slice(0, -1)

    setRedoStack((prev) => [JSON.parse(JSON.stringify(currentPage)), ...prev])
    setHistory(updatedHistory)

    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = prevPage
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }, [currentPage, currentPageIndex, doc, history, commitDoc])

  const redo = useCallback(() => {
    if (redoStack.length === 0) return
    const next = redoStack[0]
    setRedoStack((prev) => prev.slice(1))
    setHistory((prev) => [...prev, JSON.parse(JSON.stringify(currentPage))])

    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = next
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }, [currentPage, currentPageIndex, doc, redoStack, commitDoc])

  // Keyboard Shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return

      if ((e.ctrlKey || e.metaKey) && (e.key === "z" || e.key === "Z")) {
        if (e.shiftKey) redo()
        else undo()
        e.preventDefault()
      } else if ((e.ctrlKey || e.metaKey) && (e.key === "y" || e.key === "Y")) {
        redo()
        e.preventDefault()
      } else if (e.key === "p" || e.key === "P") {
        setActiveTool("fountain")
      } else if (e.key === "h" || e.key === "H") {
        setActiveTool("highlighter")
      } else if (e.key === "e" || e.key === "E") {
        setActiveTool("eraser")
      } else if (e.key === "l" || e.key === "L") {
        setActiveTool("lasso")
      } else if (e.key === "t" || e.key === "T") {
        setActiveTool("textbox")
      } else if (e.key === "s" || e.key === "S") {
        setActiveTool("stickynote")
      } else if (e.key === "Escape") {
        setZenMode(false)
        setIsNavDrawerOpen(false)
        setIsElementsDrawerOpen(false)
        setSelectedStrokeIds(new Set())
        setSelectedBoxIds(new Set())
        setSelectedImageIds(new Set())
      } else if (e.key === "Delete" || e.key === "Backspace") {
        deleteSelectedRef.current?.()
      } else if ((e.ctrlKey || e.metaKey) && (e.key === "d" || e.key === "D")) {
        duplicateSelectedRef.current?.()
        e.preventDefault()
      }
    }

    const handlePaste = (e: ClipboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
      const items = e.clipboardData?.items
      if (!items) return
      for (let i = 0; i < items.length; i++) {
        if (items[i].type.startsWith("image/")) {
          const file = items[i].getAsFile()
          if (file) {
            const reader = new FileReader()
            reader.onload = () => {
              const url = reader.result as string
              const newImg: NotebookImage = {
                id: `img_${Date.now()}`,
                url,
                x: 100,
                y: 100,
                width: 320,
                height: 240,
              }
              pushHistory()
              const updatedPages = [...docRef.current.pages]
              const curP = updatedPages[currentPageIndex] || updatedPages[0]
              updatedPages[currentPageIndex] = {
                ...curP,
                images: [...(curP.images || []), newImg],
              }
              commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
            }
            reader.readAsDataURL(file)
            e.preventDefault()
            break
          }
        }
      }
    }

    window.addEventListener("keydown", handleKeyDown)
    window.addEventListener("paste", handlePaste)
    return () => {
      window.removeEventListener("keydown", handleKeyDown)
      window.removeEventListener("paste", handlePaste)
    }
  }, [undo, redo, pushHistory, commitDoc, currentPageIndex])

  // Touch gesture arbitration for iPadOS / multi-touch devices (Pinch-to-zoom & two-finger pan)
  const handleTouchStart = (e: React.TouchEvent<HTMLDivElement>) => {
    if (e.touches.length === 2) {
      const t1 = e.touches[0]
      const t2 = e.touches[1]
      const dist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY)
      const center = {
        x: (t1.clientX + t2.clientX) / 2,
        y: (t1.clientY + t2.clientY) / 2,
      }
      touchStateRef.current = {
        initialDist: dist,
        initialZoom: zoomLevel,
        initialCenter: center,
        initialScroll: {
          left: containerRef.current?.scrollLeft || 0,
          top: containerRef.current?.scrollTop || 0,
        },
      }
    }
  }

  const handleTouchMove = (e: React.TouchEvent<HTMLDivElement>) => {
    if (e.touches.length === 2 && touchStateRef.current) {
      e.preventDefault()
      const t1 = e.touches[0]
      const t2 = e.touches[1]
      const currentDist = Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY)
      const currentCenter = {
        x: (t1.clientX + t2.clientX) / 2,
        y: (t1.clientY + t2.clientY) / 2,
      }

      // Smooth Pinch Zoom
      if (touchStateRef.current.initialDist > 0) {
        const factor = currentDist / touchStateRef.current.initialDist
        const newZoom = Math.min(3.0, Math.max(0.5, touchStateRef.current.initialZoom * factor))
        setZoomLevel(parseFloat(newZoom.toFixed(2)))
      }

      // Two-Finger Pan Scroll
      if (containerRef.current) {
        const dx = currentCenter.x - touchStateRef.current.initialCenter.x
        const dy = currentCenter.y - touchStateRef.current.initialCenter.y
        containerRef.current.scrollLeft = touchStateRef.current.initialScroll.left - dx
        containerRef.current.scrollTop = touchStateRef.current.initialScroll.top - dy
      }
    }
  }

  const handleTouchEnd = (e: React.TouchEvent<HTMLDivElement>) => {
    if (e.touches.length < 2) {
      touchStateRef.current = null
    }
  }

  // Coordinate conversion taking into account SVG CTM (transforms, zoom, rotation, scroll)
  const getCanvasPoint = (e: React.PointerEvent<SVGSVGElement>): { x: number; y: number; pressure: number } | null => {
    if (!svgRef.current) return null
    let x = 0
    let y = 0

    const svg = svgRef.current
    const ctm = svg.getScreenCTM()
    if (ctm) {
      const svgPoint = svg.createSVGPoint()
      svgPoint.x = e.clientX
      svgPoint.y = e.clientY
      const matrixPt = svgPoint.matrixTransform(ctm.inverse())
      x = matrixPt.x
      y = matrixPt.y
    } else {
      const rect = svg.getBoundingClientRect()
      const scaleX = currentPage.width / rect.width
      const scaleY = currentPage.height / rect.height
      x = (e.clientX - rect.left) * scaleX
      y = (e.clientY - rect.top) * scaleY
    }

    // Hardware Apple Pencil pressure
    const pressure = e.pointerType === "pen" && e.pressure > 0 ? e.pressure : 0.5
    return { x, y, pressure }
  }

  // Pointer Down
  const handlePointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    if (readOnly) return

    if (isPenStudioOpen) setIsPenStudioOpen(false)
    if (isColorStudioOpen) setIsColorStudioOpen(false)

    // Auto-detect Apple Pencil or Active Stylus
    if (e.pointerType === "pen") {
      setStylusDetected(true)
    }

    // Palm Rejection: reject finger touch drawing when finger drawing is toggled off
    if (e.pointerType === "touch" && !drawWithFinger) {
      return
    }

    const pt = getCanvasPoint(e)
    if (!pt) return

    // Ruler edge lock for inking tools: snap start point and lock edge direction
    const isInkingTool = ["fountain", "ballpoint", "brush", "highlighter"].includes(activeTool)
    if (rulerState.active && isInkingTool) {
      const snapped = snapPointToRuler(pt, rulerState, 45)
      if (snapped) {
        pt.x = snapped.x
        pt.y = snapped.y
        rulerLockedEdgeRef.current = snapped.edge
      } else {
        rulerLockedEdgeRef.current = null
      }
    } else {
      rulerLockedEdgeRef.current = null
    }

    try {
      svgRef.current?.setPointerCapture(e.pointerId)
    } catch {}
    isDrawingRef.current = true
    strokeStartTimeRef.current = Date.now()

    // 1. Laser Pointer Mode
    if (activeTool === "laser") {
      setLaserState((prev) => ({
        ...prev,
        active: true,
        current: pt,
        trail: [...(prev.trail || []).slice(-30), { x: pt.x, y: pt.y, time: Date.now() }],
      }))
      return
    }

    // 2. Eraser Tool
    if (activeTool === "eraser") {
      pushHistory()
      lastEraserPointRef.current = pt
      const threshold = eraserMode === "precision" ? 8 : eraserMode === "standard" ? 18 : 28

      let changed = false
      let newStrokes: InkStroke[] = []

      for (const s of currentPage.strokes) {
        if (eraseHighlighterOnly && s.tool !== "highlighter") {
          newStrokes.push(s)
          continue
        }
        if (isPointNearStroke(pt, s, threshold)) {
          changed = true
          const result = eraseStrokeAtPoint(s, pt, threshold, eraserMode)
          newStrokes.push(...result)
        } else {
          newStrokes.push(s)
        }
      }

      let tapeFiltered = currentPage.tapeStrips || []
      if (!eraseHighlighterOnly && tapeFiltered.length > 0) {
        tapeFiltered = tapeFiltered.filter((tape) => !isPointNearTape(pt, tape, threshold))
        if (tapeFiltered.length !== (currentPage.tapeStrips || []).length) {
          changed = true
        }
      }

      if (changed) {
        const updatedPages = [...doc.pages]
        updatedPages[currentPageIndex] = { ...currentPage, strokes: newStrokes, tapeStrips: tapeFiltered }
        commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      }
      return
    }

    // 3. Lasso Tool
    if (activeTool === "lasso") {
      if (
        (selectedStrokeIds.size > 0 || selectedBoxIds.size > 0 || selectedImageIds.size > 0) &&
        computedSelectionBounds
      ) {
        if (
          pt.x >= computedSelectionBounds.minX - 15 &&
          pt.x <= computedSelectionBounds.maxX + 15 &&
          pt.y >= computedSelectionBounds.minY - 15 &&
          pt.y <= computedSelectionBounds.maxY + 15
        ) {
          const strokeMap = new Map<string, InkStroke>()
          currentPage.strokes.forEach((s) => {
            if (selectedStrokeIds.has(s.id)) strokeMap.set(s.id, s)
          })
          const boxMap = new Map<string, InkTextBox>()
          ;(currentPage.textBoxes || []).forEach((b) => {
            if (selectedBoxIds.has(b.id)) boxMap.set(b.id, b)
          })
          const imageMap = new Map<string, NotebookImage>()
          ;(currentPage.images || []).forEach((img) => {
            if (selectedImageIds.has(img.id)) imageMap.set(img.id, img)
          })
          initialSelectionSnapshotRef.current = {
            strokes: strokeMap,
            boxes: boxMap,
            images: imageMap,
            startPt: pt,
          }
          setIsDraggingSelection(true)
          dragStartPointRef.current = { x: pt.x, y: pt.y }
          pushHistory()
          return
        }
      }

      lassoPointsRef.current = [{ x: pt.x, y: pt.y }]
      setLassoPoints([{ x: pt.x, y: pt.y }])
      setSelectedStrokeIds(new Set())
      setSelectedBoxIds(new Set())
      setSelectedImageIds(new Set())
      initialSelectionSnapshotRef.current = null
      return
    }

    // 4. Study Tape Tool (Interactive Drag Painting)
    if (activeTool === "tape") {
      activeTapeDraftRef.current = { start: pt, current: pt }
      setActiveTapeDraft({ start: pt, current: pt })
      return
    }

    // 5. Text Box & Sticky Notes
    if (activeTool === "textbox" || activeTool === "stickynote") {
      pushHistory()
      const isSticky = activeTool === "stickynote"
      const stickyTheme = STICKY_COLORS[Math.floor(Math.random() * STICKY_COLORS.length)]

      const newBox: InkTextBox = {
        id: `box_${Date.now()}`,
        x: pt.x,
        y: pt.y,
        width: isSticky ? 180 : 240,
        height: isSticky ? 140 : 50,
        text: isSticky ? "Sticky Note..." : "Double-click to type...",
        fontSize: isSticky ? 14 : 16,
        color: isSticky ? stickyTheme.text : activeColor,
        backgroundColor: isSticky ? stickyTheme.bg : "transparent",
        isStickyNote: isSticky,
        bold: false,
        italic: false,
        fontFamily: "sans",
      }

      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        textBoxes: [...(currentPage.textBoxes || []), newBox],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      setEditingBoxId(newBox.id)
      setActiveTool(
        previousTool && previousTool !== "textbox" && previousTool !== "stickynote"
          ? previousTool
          : "fountain"
      )
      return
    }

    // 6. Geometric Shape Tool
    if (activeTool === "shape") {
      const newStroke: InkStroke = {
        id: `shape_${Date.now()}`,
        tool: "shape",
        shapeType: shapeToolPrimitive,
        color: activeColor,
        size: activeSize,
        fill: shapeFill ? activeColor + "33" : undefined,
        points: [
          { x: pt.x, y: pt.y, pressure: 0.5, time: Date.now() },
          { x: pt.x, y: pt.y, pressure: 0.5, time: Date.now() },
        ],
        createdAt: Date.now(),
      }
      setCurrentStroke(newStroke)
      return
    }

    // 7. Standard Inking (Fountain, Ballpoint, Brush, Highlighter)
    if (
      activeTool !== "fountain" &&
      activeTool !== "ballpoint" &&
      activeTool !== "brush" &&
      activeTool !== "highlighter"
    ) {
      return
    }

    const isHighlighter = activeTool === "highlighter"
    const audioOffset = recordingStartTimeRef.current > 0 ? Date.now() - recordingStartTimeRef.current : undefined

    const currentPenConfig =
      activeTool === "brush"
        ? penSettings.brush
        : activeTool === "ballpoint"
        ? penSettings.ballpoint
        : penSettings.fountain

    const newStroke: InkStroke = {
      id: `stroke_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
      tool: activeTool,
      color: isHighlighter ? activeColor + "77" : activeColor,
      size: isHighlighter ? Math.max(activeSize * 3, 20) : activeSize,
      audioTimeOffset: audioOffset,
      penSettings: currentPenConfig,
      points: [
        {
          x: pt.x,
          y: pt.y,
          pressure: pt.pressure,
          tiltX: e.tiltX,
          tiltY: e.tiltY,
          time: Date.now(),
        },
      ],
      createdAt: Date.now(),
    }

    setCurrentStroke(newStroke)
  }

  // Pointer Move
  const handlePointerMove = (e: React.PointerEvent<SVGSVGElement>) => {
    if (readOnly) return
    const pt = getCanvasPoint(e)
    if (!pt) return

    setCanvasPointerPos(pt)

    // Laser pointer movement
    if (activeTool === "laser") {
      setLaserState((prev) => ({
        ...prev,
        current: pt,
        trail: isDrawingRef.current
          ? [...(prev.trail || []).slice(-30), { x: pt.x, y: pt.y, time: Date.now() }]
          : prev.trail,
      }))
      if (!isDrawingRef.current) return
    }

    if (!isDrawingRef.current) return

    // Eraser dragging (Strokes and Study Tape)
    if (activeTool === "eraser") {
      const threshold = eraserMode === "precision" ? 8 : eraserMode === "standard" ? 18 : 28
      const p1 = lastEraserPointRef.current || pt
      const p2 = pt
      lastEraserPointRef.current = pt

      let changed = false
      let newStrokes: InkStroke[] = []

      for (const s of currentPage.strokes) {
        if (eraseHighlighterOnly && s.tool !== "highlighter") {
          newStrokes.push(s)
          continue
        }
        if (isSegmentNearStroke(p1, p2, s, threshold)) {
          changed = true
          const result = eraseStrokeAtPoint(s, pt, threshold, eraserMode)
          newStrokes.push(...result)
        } else {
          newStrokes.push(s)
        }
      }

      let tapeFiltered = currentPage.tapeStrips || []
      if (!eraseHighlighterOnly && tapeFiltered.length > 0) {
        tapeFiltered = tapeFiltered.filter((tape) => !isPointNearTape(pt, tape, threshold))
        if (tapeFiltered.length !== (currentPage.tapeStrips || []).length) {
          changed = true
        }
      }

      if (changed) {
        const updatedPages = [...doc.pages]
        updatedPages[currentPageIndex] = { ...currentPage, strokes: newStrokes, tapeStrips: tapeFiltered }
        commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      }
      return
    }

    // Study Tape dragging
    if (activeTool === "tape" && activeTapeDraftRef.current) {
      activeTapeDraftRef.current.current = pt
      setActiveTapeDraft({ ...activeTapeDraftRef.current })
      return
    }

    // Lasso loop dragging
    if (activeTool === "lasso") {
      if (isDraggingSelection && initialSelectionSnapshotRef.current) {
        const { strokes: origStrokes, boxes: origBoxes, images: origImages, startPt } = initialSelectionSnapshotRef.current
        const totalDx = pt.x - startPt.x
        const totalDy = pt.y - startPt.y

        if (!dragRafIdRef.current) {
          dragRafIdRef.current = requestAnimationFrame(() => {
            dragRafIdRef.current = null
            const curPage = docRef.current.pages[currentPageIndex] || currentPage
            const updatedStrokes = curPage.strokes.map((s) => {
              const orig = origStrokes.get(s.id)
              return orig ? translateStroke(orig, totalDx, totalDy) : s
            })
            const updatedBoxes = (curPage.textBoxes || []).map((b) => {
              const orig = origBoxes.get(b.id)
              return orig ? { ...orig, x: orig.x + totalDx, y: orig.y + totalDy } : b
            })
            const updatedImages = (curPage.images || []).map((img) => {
              const orig = origImages.get(img.id)
              return orig ? { ...orig, x: orig.x + totalDx, y: orig.y + totalDy } : img
            })

            const updatedPages = [...docRef.current.pages]
            updatedPages[currentPageIndex] = {
              ...curPage,
              strokes: updatedStrokes,
              textBoxes: updatedBoxes,
              images: updatedImages,
            }
            docRef.current = { ...docRef.current, pages: updatedPages }
            setDoc(docRef.current)
          })
        }
        return
      }

      if (lassoMode === "rect") {
        const startPt = lassoPointsRef.current[0] || pt
        lassoPointsRef.current = [startPt, { x: pt.x, y: pt.y }]
        if (!lassoRafIdRef.current) {
          lassoRafIdRef.current = requestAnimationFrame(() => {
            lassoRafIdRef.current = null
            setLassoPoints([startPt, { x: pt.x, y: pt.y }])
          })
        }
      } else {
        lassoPointsRef.current.push({ x: pt.x, y: pt.y })
        if (!lassoRafIdRef.current) {
          lassoRafIdRef.current = requestAnimationFrame(() => {
            lassoRafIdRef.current = null
            setLassoPoints([...lassoPointsRef.current])
          })
        }
      }
      return
    }

    // Shape drawing preview
    if (activeTool === "shape" && currentStroke) {
      let targetX = pt.x
      let targetY = pt.y

      // Snap line endpoint to other shape vertices
      if (snapToOtherShapes) {
        const snapped = snapPointToShapeVertices({ x: targetX, y: targetY }, currentPage.strokes)
        if (snapped) {
          targetX = snapped.x
          targetY = snapped.y
        }
      }

      setCurrentStroke({
        ...currentStroke,
        points: [currentStroke.points[0], { x: targetX, y: targetY, pressure: 0.5, time: Date.now() }],
      })
      return
    }

    // Regular inking
    if (currentStroke) {
      let inkingX = pt.x
      let inkingY = pt.y

      // Constrain strictly along ruler edge if drawing against ruler
      if (rulerState.active) {
        if (!rulerLockedEdgeRef.current) {
          const snapCheck = snapPointToRuler(pt, rulerState, 45)
          if (snapCheck) {
            rulerLockedEdgeRef.current = snapCheck.edge
          }
        }

        if (rulerLockedEdgeRef.current) {
          const rad = (rulerState.angle * Math.PI) / 180
          const dirX = Math.cos(rad)
          const dirY = Math.sin(rad)
          const normX = -dirY
          const normY = dirX
          const edgeY = rulerLockedEdgeRef.current === "top" ? -35 : 35
          const rulerHalfWidth = (rulerState.length || 500) / 2

          // Vector from ruler center to pointer
          const vx = pt.x - rulerState.x
          const vy = pt.y - rulerState.y
          const along = vx * dirX + vy * dirY

          // Constrain strictly along the ruler edge (with small overhang)
          const clampedAlong = Math.max(-rulerHalfWidth - 15, Math.min(rulerHalfWidth + 15, along))

          inkingX = rulerState.x + clampedAlong * dirX + edgeY * normX
          inkingY = rulerState.y + clampedAlong * dirY + edgeY * normY
        }
      }

      let nextPoints = [
        ...currentStroke.points,
        {
          x: inkingX,
          y: inkingY,
          pressure: pt.pressure,
          tiltX: e.tiltX,
          tiltY: e.tiltY,
          time: Date.now(),
        },
      ]

      // Straight line highlighter snap
      if (activeTool === "highlighter" && straightLineHighlighter) {
        nextPoints = snapToStraightLine(nextPoints)
      }

      const updated = {
        ...currentStroke,
        points: nextPoints,
      }
      setCurrentStroke(updated)

      // Draw and Hold geometric shape recognition
      if (
        activeTool !== "shape" &&
        activeTool !== "highlighter" &&
        autoShapeDetection &&
        !isShapeLockedRef.current &&
        nextPoints.length > 8
      ) {
        if (shapeHoldTimerRef.current) clearTimeout(shapeHoldTimerRef.current)
        shapeHoldTimerRef.current = setTimeout(() => {
          if (!isDrawingRef.current || !currentStrokeRef.current) return
          const detected = detectGeometricShape(currentStrokeRef.current.points)
          if (detected) {
            isShapeLockedRef.current = true
            const morphed: InkStroke = {
              ...currentStrokeRef.current,
              tool: "shape",
              shapeType: detected,
              fill: shapeFill ? currentStrokeRef.current.color + "33" : undefined,
              points: currentStrokeRef.current.points,
            }
            setCurrentStroke(morphed)
          }
        }, 420)
      }
    }
  }

  // Pointer Up
  const handlePointerUp = () => {
    isDrawingRef.current = false
    lastEraserPointRef.current = null
    if (shapeHoldTimerRef.current) clearTimeout(shapeHoldTimerRef.current)

    // Laser deactivation (keep trail for progressive decay!)
    if (activeTool === "laser") {
      setLaserState((prev) => ({ ...prev, active: false, current: null }))
      return
    }

    // Study Tape completion
    if (activeTool === "tape" && activeTapeDraftRef.current) {
      const { start, current } = activeTapeDraftRef.current
      activeTapeDraftRef.current = null
      setActiveTapeDraft(null)

      const dist = Math.hypot(current.x - start.x, current.y - start.y)
      const p2 = dist >= 6 ? current : { x: start.x + 80, y: start.y }

      pushHistory()
      const newTape: TapeStrip = {
        id: `tape_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
        points: [start, p2],
        width: Math.max(16, activeSize * 4),
        color: tapeColor,
        pattern: tapePattern,
        revealed: false,
        createdAt: Date.now(),
      }
      const updatedTapeStrips = [...(currentPage.tapeStrips || []), newTape]
      const updatedPages = [...docRef.current.pages]
      updatedPages[currentPageIndex] = { ...currentPage, tapeStrips: updatedTapeStrips }
      commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
      return
    }

    // Auto-deselect eraser
    if (activeTool === "eraser" && autoDeselectEraser) {
      setActiveTool(previousTool !== "eraser" ? previousTool : "fountain")
    }

    // Lasso completion
    if (activeTool === "lasso") {
      if (dragRafIdRef.current) {
        cancelAnimationFrame(dragRafIdRef.current)
        dragRafIdRef.current = null
      }
      if (lassoRafIdRef.current) {
        cancelAnimationFrame(lassoRafIdRef.current)
        lassoRafIdRef.current = null
      }

      if (isDraggingSelection) {
        setIsDraggingSelection(false)
        if (initialSelectionSnapshotRef.current) {
          commitDoc(docRef.current)
          initialSelectionSnapshotRef.current = null
        }
        return
      }

      const curPage = docRef.current.pages[currentPageIndex] || currentPage
      const selectedStrokes = new Set<string>()
      const selectedBoxes = new Set<string>()
      const selectedImages = new Set<string>()

      if (lassoMode === "rect") {
        const p0 = lassoPointsRef.current[0]
        const p1 = lassoPointsRef.current[lassoPointsRef.current.length - 1]
        if (p0 && p1) {
          const minX = Math.min(p0.x, p1.x)
          const maxX = Math.max(p0.x, p1.x)
          const minY = Math.min(p0.y, p1.y)
          const maxY = Math.max(p0.y, p1.y)
          if (maxX - minX > 4 || maxY - minY > 4) {
            const rect = { minX, minY, maxX, maxY }
            if (lassoFilter.handwriting) {
              curPage.strokes.forEach((s) => {
                if (isStrokeInRect(rect, s)) selectedStrokes.add(s.id)
              })
            }
            if (lassoFilter.textBoxes || lassoFilter.stickyNotes) {
              (curPage.textBoxes || []).forEach((b) => {
                if (b.isStickyNote && !lassoFilter.stickyNotes) return
                if (!b.isStickyNote && !lassoFilter.textBoxes) return
                if (isBoxInRect(rect, b)) selectedBoxes.add(b.id)
              })
            }
            if (lassoFilter.images && curPage.images) {
              curPage.images.forEach((img) => {
                if (isBoxInRect(rect, { x: img.x, y: img.y, width: img.width, height: img.height })) {
                  selectedImages.add(img.id)
                }
              })
            }
          }
        }
      } else {
        const pts = lassoPointsRef.current.length > 2 ? lassoPointsRef.current : lassoPoints
        if (pts.length > 2) {
          if (lassoFilter.handwriting) {
            curPage.strokes.forEach((s) => {
              if (isStrokeInLasso(pts, s)) selectedStrokes.add(s.id)
            })
          }
          if (lassoFilter.textBoxes || lassoFilter.stickyNotes) {
            (curPage.textBoxes || []).forEach((b) => {
              if (b.isStickyNote && !lassoFilter.stickyNotes) return
              if (!b.isStickyNote && !lassoFilter.textBoxes) return
              if (isBoxInLasso(pts, b)) selectedBoxes.add(b.id)
            })
          }
          if (lassoFilter.images && curPage.images) {
            curPage.images.forEach((img) => {
              if (isBoxInLasso(pts, { x: img.x, y: img.y, width: img.width, height: img.height })) {
                selectedImages.add(img.id)
              }
            })
          }
        }
      }

      setSelectedStrokeIds(selectedStrokes)
      setSelectedBoxIds(selectedBoxes)
      setSelectedImageIds(selectedImages)
      lassoPointsRef.current = []
      setLassoPoints([])
      return
    }

    const wasRulerDrawn = Boolean(rulerLockedEdgeRef.current)
    rulerLockedEdgeRef.current = null

    // Inking stroke completion
    if (currentStroke && currentStroke.points.length > 0) {
      let finalStroke = currentStroke
      // Auto-Shape on release if auto-shape is active or dedicated shape tool (skip if ruler-drawn)
      if (!wasRulerDrawn && (activeTool === "shape" || autoShapeDetection) && !finalStroke.shapeType && finalStroke.points.length > 8) {
        const detected = detectGeometricShape(finalStroke.points)
        if (detected) {
          finalStroke = {
            ...finalStroke,
            tool: "shape",
            shapeType: detected,
            fill: shapeFill ? finalStroke.color + "33" : undefined,
          }
        }
      }

      pushHistory()
      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        strokes: [...currentPage.strokes, finalStroke],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      setCurrentStroke(null)
      isShapeLockedRef.current = false
    }
  }

  // Duplicate Lasso Selection
  const duplicateSelected = () => {
    if (selectedStrokeIds.size === 0 && selectedBoxIds.size === 0 && selectedImageIds.size === 0) return
    pushHistory()
    const curPage = docRef.current.pages[currentPageIndex] || currentPage
    const duplicatedStrokes = curPage.strokes
      .filter((s) => selectedStrokeIds.has(s.id))
      .map((s) => translateStroke({ ...s, id: `stroke_${Date.now()}_${Math.random().toString(36).slice(2, 6)}` }, 25, 25))

    const duplicatedBoxes = (curPage.textBoxes || [])
      .filter((b) => selectedBoxIds.has(b.id))
      .map((b) => ({ ...b, id: `box_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`, x: b.x + 25, y: b.y + 25 }))

    const duplicatedImages = (curPage.images || [])
      .filter((img) => selectedImageIds.has(img.id))
      .map((img) => ({
        ...img,
        id: `img_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
        x: img.x + 25,
        y: img.y + 25,
      }))

    const updatedPages = [...docRef.current.pages]
    updatedPages[currentPageIndex] = {
      ...curPage,
      strokes: [...curPage.strokes, ...duplicatedStrokes],
      textBoxes: [...(curPage.textBoxes || []), ...duplicatedBoxes],
      images: [...(curPage.images || []), ...duplicatedImages],
    }
    commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })

    setSelectedStrokeIds(new Set(duplicatedStrokes.map((s) => s.id)))
    setSelectedBoxIds(new Set(duplicatedBoxes.map((b) => b.id)))
    setSelectedImageIds(new Set(duplicatedImages.map((img) => img.id)))
  }

  // Recolor Lasso Selection
  const recolorSelected = (color: string) => {
    if (selectedStrokeIds.size === 0 && selectedBoxIds.size === 0) return
    pushHistory()
    const curPage = docRef.current.pages[currentPageIndex] || currentPage
    const updatedStrokes = curPage.strokes.map((s) =>
      selectedStrokeIds.has(s.id) ? { ...s, color } : s
    )
    const updatedBoxes = (curPage.textBoxes || []).map((b) =>
      selectedBoxIds.has(b.id) ? { ...b, color } : b
    )
    const updatedPages = [...docRef.current.pages]
    updatedPages[currentPageIndex] = {
      ...curPage,
      strokes: updatedStrokes,
      textBoxes: updatedBoxes,
    }
    commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
  }

  // Delete Lasso Selection
  const deleteSelected = () => {
    if (selectedStrokeIds.size === 0 && selectedBoxIds.size === 0 && selectedImageIds.size === 0) return
    pushHistory()
    const curPage = docRef.current.pages[currentPageIndex] || currentPage
    const updatedStrokes = curPage.strokes.filter((s) => !selectedStrokeIds.has(s.id))
    const updatedBoxes = (curPage.textBoxes || []).filter((b) => !selectedBoxIds.has(b.id))
    const updatedImages = (curPage.images || []).filter((img) => !selectedImageIds.has(img.id))
    const updatedPages = [...docRef.current.pages]
    updatedPages[currentPageIndex] = {
      ...curPage,
      strokes: updatedStrokes,
      textBoxes: updatedBoxes,
      images: updatedImages,
    }
    commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
    setSelectedStrokeIds(new Set())
    setSelectedBoxIds(new Set())
    setSelectedImageIds(new Set())
  }

  deleteSelectedRef.current = deleteSelected
  duplicateSelectedRef.current = duplicateSelected

  // Delete specific placed image
  const deleteImage = (imgId: string) => {
    pushHistory()
    const updatedImages = (currentPage.images || []).filter((img) => img.id !== imgId)
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = { ...currentPage, images: updatedImages }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    if (activeImageId === imgId) setActiveImageId(null)
  }

  // Start dragging / moving placed images
  const startImageDrag = (e: React.PointerEvent, img: NotebookImage) => {
    if (readOnly) return
    e.stopPropagation()
    setActiveImageId(img.id)
    const startX = e.clientX
    const startY = e.clientY
    const origX = img.x
    const origY = img.y
    let hasMoved = false
    let latestPages = docRef.current.pages

    const onMove = (moveEv: PointerEvent) => {
      hasMoved = true
      const dx = (moveEv.clientX - startX) / zoomLevel
      const dy = (moveEv.clientY - startY) / zoomLevel
      const newX = Math.round(origX + dx)
      const newY = Math.round(origY + dy)

      const updated = (currentPage.images || []).map((i) =>
        i.id === img.id ? { ...i, x: newX, y: newY } : i
      )
      latestPages = [...docRef.current.pages]
      latestPages[currentPageIndex] = { ...currentPage, images: updated }
      docRef.current = { ...docRef.current, pages: latestPages }
      setDoc(docRef.current)
    }

    const onUp = () => {
      window.removeEventListener("pointermove", onMove)
      window.removeEventListener("pointerup", onUp)
      if (hasMoved) {
        pushHistory()
        commitDoc({ ...docRef.current, pages: latestPages, updatedAt: Date.now() })
      }
    }

    window.addEventListener("pointermove", onMove)
    window.addEventListener("pointerup", onUp)
  }

  // Start corner resizing for placed images
  const startImageResize = (
    e: React.PointerEvent,
    img: NotebookImage,
    corner: "tl" | "tr" | "bl" | "br"
  ) => {
    e.stopPropagation()
    const startX = e.clientX
    const startY = e.clientY
    const origW = img.width
    const origH = img.height
    const origX = img.x
    const origY = img.y
    let latestPages = docRef.current.pages

    const onMove = (moveEv: PointerEvent) => {
      const dx = (moveEv.clientX - startX) / zoomLevel
      const dy = (moveEv.clientY - startY) / zoomLevel
      let newW = origW
      let newH = origH
      let newX = origX
      let newY = origY

      if (corner === "br") {
        newW = Math.max(40, origW + dx)
        newH = Math.max(40, origH + dy)
      } else if (corner === "bl") {
        newW = Math.max(40, origW - dx)
        newH = Math.max(40, origH + dy)
        newX = origX + (origW - newW)
      } else if (corner === "tr") {
        newW = Math.max(40, origW + dx)
        newH = Math.max(40, origH - dy)
        newY = origY + (origH - newH)
      } else if (corner === "tl") {
        newW = Math.max(40, origW - dx)
        newH = Math.max(40, origH - dy)
        newX = origX + (origW - newW)
        newY = origY + (origH - newH)
      }

      const updated = (currentPage.images || []).map((i) =>
        i.id === img.id ? { ...i, width: Math.round(newW), height: Math.round(newH), x: Math.round(newX), y: Math.round(newY) } : i
      )
      latestPages = [...docRef.current.pages]
      latestPages[currentPageIndex] = { ...currentPage, images: updated }
      docRef.current = { ...docRef.current, pages: latestPages }
      setDoc(docRef.current)
    }

    const onUp = () => {
      window.removeEventListener("pointermove", onMove)
      window.removeEventListener("pointerup", onUp)
      pushHistory()
      commitDoc({ ...docRef.current, pages: latestPages, updatedAt: Date.now() })
    }

    window.addEventListener("pointermove", onMove)
    window.addEventListener("pointerup", onUp)
  }

  // Rotate Lasso Selection (Strokes, Text Boxes, Images)
  const rotateSelected = (angleDeg: number = 90) => {
    if (!computedSelectionBounds) return
    pushHistory()
    const origin = {
      x: (computedSelectionBounds.minX + computedSelectionBounds.maxX) / 2,
      y: (computedSelectionBounds.minY + computedSelectionBounds.maxY) / 2,
    }
    const rad = (angleDeg * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)

    const updatedStrokes = currentPage.strokes.map((s) => {
      if (selectedStrokeIds.has(s.id)) {
        return rotateStroke(s, rad, origin)
      }
      return s
    })

    const updatedBoxes = (currentPage.textBoxes || []).map((b) => {
      if (selectedBoxIds.has(b.id)) {
        const bcx = b.x + b.width / 2
        const bcy = b.y + b.height / 2
        const dx = bcx - origin.x
        const dy = bcy - origin.y
        const ncx = origin.x + dx * cos - dy * sin
        const ncy = origin.y + dx * sin + dy * cos
        return {
          ...b,
          x: Math.round(ncx - b.width / 2),
          y: Math.round(ncy - b.height / 2),
        }
      }
      return b
    })

    const updatedImages = (currentPage.images || []).map((img) => {
      if (selectedImageIds.has(img.id)) {
        const icx = img.x + img.width / 2
        const icy = img.y + img.height / 2
        const dx = icx - origin.x
        const dy = icy - origin.y
        const ncx = origin.x + dx * cos - dy * sin
        const ncy = origin.y + dx * sin + dy * cos
        return {
          ...img,
          x: Math.round(ncx - img.width / 2),
          y: Math.round(ncy - img.height / 2),
        }
      }
      return img
    })

    const updatedPages = [...docRef.current.pages]
    updatedPages[currentPageIndex] = {
      ...currentPage,
      strokes: updatedStrokes,
      textBoxes: updatedBoxes,
      images: updatedImages,
    }
    commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
  }

  // Capture selection as screenshot to clipboard
  const captureSelectionScreenshot = async () => {
    if (!computedSelectionBounds || !svgRef.current) return
    const bounds = computedSelectionBounds
    const pad = 16
    const x = Math.max(0, bounds.minX - pad)
    const y = Math.max(0, bounds.minY - pad)
    const w = Math.max(20, bounds.maxX - bounds.minX + pad * 2)
    const h = Math.max(20, bounds.maxY - bounds.minY + pad * 2)

    try {
      const svgClone = svgRef.current.cloneNode(true) as SVGSVGElement
      svgClone.setAttribute("viewBox", `${x} ${y} ${w} ${h}`)
      svgClone.setAttribute("width", `${w}`)
      svgClone.setAttribute("height", `${h}`)

      const toRemove = svgClone.querySelectorAll(
        ".lasso-selection-box, .laser-pointer-layer, .zoom-target-indicator, .image-selection-overlay"
      )
      toRemove.forEach((el) => el.remove())

      const svgData = new XMLSerializer().serializeToString(svgClone)
      const svgBlob = new Blob([svgData], { type: "image/svg+xml;charset=utf-8" })
      const url = URL.createObjectURL(svgBlob)

      const img = new Image()
      img.onload = () => {
        const canvas = document.createElement("canvas")
        canvas.width = Math.round(w * 2)
        canvas.height = Math.round(h * 2)
        const ctx = canvas.getContext("2d")
        if (ctx) {
          ctx.fillStyle =
            currentPage.paperColor === "dark"
              ? "#1e232a"
              : currentPage.paperColor === "cream"
              ? "#fefae0"
              : "#ffffff"
          ctx.fillRect(0, 0, canvas.width, canvas.height)
          ctx.scale(2, 2)
          ctx.drawImage(img, 0, 0)
          canvas.toBlob((blob) => {
            if (blob) {
              try {
                navigator.clipboard?.write([new ClipboardItem({ "image/png": blob })])
                alert("Selection screenshot copied to clipboard!")
              } catch {
                const a = document.createElement("a")
                a.href = URL.createObjectURL(blob)
                a.download = `notebook_selection_${Date.now()}.png`
                a.click()
              }
            }
          }, "image/png")
        }
        URL.revokeObjectURL(url)
      }
      img.src = url
    } catch (err) {
      console.warn("Screenshot capture failed:", err)
    }
  }

  // Convert Selected Handwriting to Text
  const convertSelectedToText = () => {
    const selectedStrokes = currentPage.strokes.filter((s) => selectedStrokeIds.has(s.id))
    const selectedBoxes = (currentPage.textBoxes || []).filter((b) => selectedBoxIds.has(b.id))
    let text = convertStrokesToText(selectedStrokes)
    if (selectedBoxes.length > 0) {
      const boxText = selectedBoxes.map((b) => b.text).join("\n\n")
      text = text ? `${text}\n\n${boxText}` : boxText
    }
    navigator.clipboard?.writeText(text)
    alert(`Converted Text copied to clipboard:\n\n${text}`)
  }

  // Convert Selected Handwriting to Math
  const convertSelectedToMath = () => {
    const selectedStrokes = currentPage.strokes.filter((s) => selectedStrokeIds.has(s.id))
    const math = convertStrokesToMath(selectedStrokes)
    navigator.clipboard?.writeText(math)
    alert(`LaTeX Math copied to clipboard:\n\n${math}`)
  }

  // Save Selected Handwriting as Reusable Element
  const saveSelectedAsElement = () => {
    const selectedStrokes = currentPage.strokes.filter((s) => selectedStrokeIds.has(s.id))
    const selectedBoxes = (currentPage.textBoxes || []).filter((b) => selectedBoxIds.has(b.id))
    const newElem: NotebookElement = {
      id: `elem_${Date.now()}`,
      name: `Sticker ${customElements.length + 1}`,
      collectionId: "custom",
      strokes: selectedStrokes,
      textBoxes: selectedBoxes,
    }
    setCustomElements((prev) => [...prev, newElem])
    setIsElementsDrawerOpen(true)
  }

  // Image Upload
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      const url = reader.result as string
      const newImg: NotebookImage = {
        id: `img_${Date.now()}`,
        url,
        x: 100,
        y: 100,
        width: 320,
        height: 240,
      }
      pushHistory()
      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        images: [...(currentPage.images || []), newImg],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    }
    reader.readAsDataURL(file)
  }

  // Page Operations
  const addPage = (afterIndex = currentPageIndex) => {
    pushHistory()
    const newPage = createEmptyPage(
      doc.pages.length + 1,
      currentPage.template,
      currentPage.paperColor || "white",
      currentPage.pageSize || "Standard",
      currentPage.orientation || "portrait"
    )
    const updatedPages = [
      ...doc.pages.slice(0, afterIndex + 1),
      newPage,
      ...doc.pages.slice(afterIndex + 1),
    ].map((p, idx) => ({ ...p, pageNumber: idx + 1 }))

    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setCurrentPageIndex(afterIndex + 1)
  }

  const duplicatePage = (targetIndex = currentPageIndex) => {
    pushHistory()
    const target = doc.pages[targetIndex] || currentPage
    const copy: NotebookPage = {
      ...JSON.parse(JSON.stringify(target)),
      id: `page_${Date.now()}`,
      pageNumber: targetIndex + 2,
    }
    const updatedPages = [
      ...doc.pages.slice(0, targetIndex + 1),
      copy,
      ...doc.pages.slice(targetIndex + 1),
    ].map((p, idx) => ({ ...p, pageNumber: idx + 1 }))

    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setCurrentPageIndex(targetIndex + 1)
  }

  const deletePage = (targetIndex = currentPageIndex) => {
    if (doc.pages.length <= 1) return
    pushHistory()
    const updatedPages = doc.pages
      .filter((_, idx) => idx !== targetIndex)
      .map((p, idx) => ({ ...p, pageNumber: idx + 1 }))
    const nextIndex = Math.min(targetIndex, updatedPages.length - 1)
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setCurrentPageIndex(nextIndex)
  }

  const rotatePage = (targetIndex = currentPageIndex) => {
    pushHistory()
    const updatedPages = doc.pages.map((p, idx) =>
      idx === targetIndex ? { ...p, rotation: ((p.rotation || 0) + 90) % 360 } : p
    )
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const toggleBookmark = (targetIndex = currentPageIndex) => {
    const updatedPages = doc.pages.map((p, idx) =>
      idx === targetIndex ? { ...p, bookmarked: !p.bookmarked } : p
    )
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const exportPageSvg = () => {
    if (!svgRef.current) return
    const svgClone = svgRef.current.cloneNode(true) as SVGSVGElement
    const serializer = new XMLSerializer()
    const svgString = serializer.serializeToString(svgClone)
    const blob = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" })
    const url = URL.createObjectURL(blob)
    const link = document.createElement("a")
    link.href = url
    link.download = `${doc.title || "notebook"}_page_${currentPageIndex + 1}.svg`
    link.click()
    URL.revokeObjectURL(url)
  }

  const clearCurrentPage = () => {
    if (!confirm("Clear all handwriting and notes from this page?")) return
    pushHistory()
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = {
      ...currentPage,
      strokes: [],
      textBoxes: [],
      images: [],
      tapeStrips: [],
    }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  // Toggle study tape reveal
  const toggleTapeReveal = (tapeId: string) => {
    const updatedStrips = (currentPage.tapeStrips || []).map((t) =>
      t.id === tapeId ? { ...t, revealed: !t.revealed } : t
    )
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = { ...currentPage, tapeStrips: updatedStrips }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  // Audio Playback Animation
  const toggleAudioPlayback = () => {
    if (isPlaybackActive) {
      if (playbackTimerRef.current) clearInterval(playbackTimerRef.current)
      setIsPlaybackActive(false)
    } else {
      setIsPlaybackActive(true)
      const maxDuration = activeRecording?.durationMs || 10000
      playbackTimerRef.current = window.setInterval(() => {
        setPlaybackTimeMs((prev) => {
          if (prev >= maxDuration) {
            clearInterval(playbackTimerRef.current!)
            setIsPlaybackActive(false)
            return 0
          }
          return prev + 100
        })
      }, 100)
    }
  }

  // Background Pattern Renderer
  const renderBackgroundPattern = () => {
    const isDark = currentPage.paperColor === "dark"
    const lineColor = isDark ? "#334155" : "#cbd5e1"
    const dotColor = isDark ? "#475569" : "#94a3b8"

    switch (currentPage.template) {
      case "ruled":
        return (
          <pattern id="notebook-ruled" width="100" height="32" patternUnits="userSpaceOnUse">
            <line x1="0" y1="31" x2="100" y2="31" stroke={lineColor} strokeWidth="0.8" />
          </pattern>
        )
      case "ruled-wide":
        return (
          <pattern id="notebook-ruled-wide" width="100" height="46" patternUnits="userSpaceOnUse">
            <line x1="0" y1="45" x2="100" y2="45" stroke={lineColor} strokeWidth="0.8" />
          </pattern>
        )
      case "grid":
        return (
          <pattern id="notebook-grid" width="24" height="24" patternUnits="userSpaceOnUse">
            <path d="M 24 0 L 0 0 0 24" fill="none" stroke={lineColor} strokeWidth="0.8" />
          </pattern>
        )
      case "dotted":
        return (
          <pattern id="notebook-dotted" width="24" height="24" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1" fill={dotColor} />
          </pattern>
        )
      case "cornell":
        return (
          <pattern id="notebook-cornell" width="100" height="32" patternUnits="userSpaceOnUse">
            <line x1="0" y1="31" x2="100" y2="31" stroke={lineColor} strokeWidth="0.8" />
          </pattern>
        )
      case "music-staff":
        return (
          <pattern id="notebook-music" width="100" height="60" patternUnits="userSpaceOnUse">
            <line x1="0" y1="10" x2="100" y2="10" stroke={lineColor} strokeWidth="0.8" />
            <line x1="0" y1="18" x2="100" y2="18" stroke={lineColor} strokeWidth="0.8" />
            <line x1="0" y1="26" x2="100" y2="26" stroke={lineColor} strokeWidth="0.8" />
            <line x1="0" y1="34" x2="100" y2="34" stroke={lineColor} strokeWidth="0.8" />
            <line x1="0" y1="42" x2="100" y2="42" stroke={lineColor} strokeWidth="0.8" />
          </pattern>
        )
      default:
        return null
    }
  }

  const getBackgroundFill = () => {
    switch (currentPage.template) {
      case "ruled":
        return "url(#notebook-ruled)"
      case "ruled-wide":
        return "url(#notebook-ruled-wide)"
      case "grid":
        return "url(#notebook-grid)"
      case "dotted":
        return "url(#notebook-dotted)"
      case "cornell":
        return "url(#notebook-cornell)"
      case "music-staff":
        return "url(#notebook-music)"
      default:
        return "none"
    }
  }

  const computedSelectionBounds = useMemo(() => {
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity

    for (const s of currentPage.strokes) {
      if (selectedStrokeIds.has(s.id)) {
        for (const p of s.points) {
          if (p.x < minX) minX = p.x
          if (p.y < minY) minY = p.y
          if (p.x > maxX) maxX = p.x
          if (p.y > maxY) maxY = p.y
        }
      }
    }

    for (const b of (currentPage.textBoxes || [])) {
      if (selectedBoxIds.has(b.id)) {
        if (b.x < minX) minX = b.x
        if (b.y < minY) minY = b.y
        if (b.x + b.width > maxX) maxX = b.x + b.width
        if (b.y + b.height > maxY) maxY = b.y + b.height
      }
    }

    if (currentPage.images) {
      for (const img of currentPage.images) {
        if (selectedImageIds.has(img.id)) {
          if (img.x < minX) minX = img.x
          if (img.y < minY) minY = img.y
          if (img.x + img.width > maxX) maxX = img.x + img.width
          if (img.y + img.height > maxY) maxY = img.y + img.height
        }
      }
    }

    if (minX === Infinity) return null
    return { minX, minY, maxX, maxY }
  }, [currentPage.strokes, currentPage.textBoxes, currentPage.images, selectedStrokeIds, selectedBoxIds, selectedImageIds])

  // Separate strokes by layer so highlighters always sit under pens
  const highlighterStrokes = currentPage.strokes.filter((s) => s.tool === "highlighter")
  const penStrokes = currentPage.strokes.filter((s) => s.tool !== "highlighter")

  return (
    <div
      className={`relative flex flex-col ${
        zenMode ? "fixed inset-0 z-50 shadow-2xl" : "h-full w-full"
      } bg-slate-100 dark:bg-[#121418] select-none overflow-hidden font-sans`}
    >
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={handleImageUpload}
      />

      {/* Primary GoodNotes Top Bar */}
      <div className="relative z-30 flex-shrink-0 select-none">
        <header className="h-12 px-3 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md border-b border-slate-200/80 dark:border-slate-800/80 shadow-sm flex items-center justify-between gap-2 overflow-x-auto">
          {/* Left: Document Drawer, Bookmark, Read-Only Toggle, Navigation, Undo/Redo */}
          <div className="flex items-center gap-1 flex-shrink-0">
            <button
              onClick={() => setIsNavDrawerOpen(!isNavDrawerOpen)}
              className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors ${
                isNavDrawerOpen
                  ? "bg-blue-100 text-blue-600 dark:bg-blue-900/50 dark:text-blue-400 font-semibold"
                  : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Thumbnails, Outlines & Bookmarks Drawer"
            >
              <Layers className="w-4 h-4" />
            </button>

            <button
              onClick={() => setReadOnly(!readOnly)}
              className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors ${
                readOnly
                  ? "bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300 font-bold"
                  : "text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
              }`}
              title="Read-Only Mode: Disable drawing to tap hyperlinks and peel study tape"
            >
              {readOnly ? <Eye className="w-4 h-4" /> : <Edit3 className="w-4 h-4" />}
            </button>

            <button
              onClick={() => toggleBookmark(currentPageIndex)}
              className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors ${
                currentPage.bookmarked
                  ? "text-amber-500 hover:text-amber-600"
                  : "text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
              }`}
              title={currentPage.bookmarked ? "Bookmarked Page" : "Bookmark this Page"}
            >
              <Star className={`w-4 h-4 ${currentPage.bookmarked ? "fill-amber-400 text-amber-400" : ""}`} />
            </button>

            <div className="w-px h-5 bg-slate-200 dark:bg-slate-700 mx-0.5" />

            {/* Page Navigation */}
            <div className="flex items-center gap-0.5 bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 rounded-lg border border-slate-200/80 dark:border-slate-700/80 text-xs text-slate-700 dark:text-slate-300 font-medium">
              <button
                onClick={() => setCurrentPageIndex((prev) => Math.max(0, prev - 1))}
                disabled={currentPageIndex === 0}
                className="p-1 disabled:opacity-30 hover:text-blue-500 rounded transition-colors"
                title="Previous Page"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <span className="font-semibold px-1 text-[11px] tabular-nums">
                {currentPageIndex + 1} / {doc.pages.length}
              </span>
              <button
                onClick={() => setCurrentPageIndex((prev) => Math.min(doc.pages.length - 1, prev + 1))}
                disabled={currentPageIndex === doc.pages.length - 1}
                className="p-1 disabled:opacity-30 hover:text-blue-500 rounded transition-colors"
                title="Next Page"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="w-px h-5 bg-slate-200 dark:bg-slate-700 mx-0.5" />

            {/* Undo / Redo */}
            <button
              onClick={undo}
              disabled={history.length === 0 || readOnly}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-slate-600 dark:text-slate-400 disabled:opacity-30 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              title="Undo (Ctrl+Z)"
            >
              <Undo2 className="w-4 h-4" />
            </button>
            <button
              onClick={redo}
              disabled={redoStack.length === 0 || readOnly}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-slate-600 dark:text-slate-400 disabled:opacity-30 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              title="Redo (Ctrl+Y)"
            >
              <Redo2 className="w-4 h-4" />
            </button>
          </div>

          {/* Center: Rock-Solid GoodNotes Inking & Toolset Island (Never shifts!) */}
          <div className="flex items-center gap-1 bg-slate-100/90 dark:bg-slate-800/90 p-1 rounded-2xl border border-slate-200/60 dark:border-slate-700/60 shadow-inner flex-shrink-0">
            {/* Pens Group */}
            <div className="flex items-center gap-0.5">
              {/* Fountain Pen */}
              <button
                onClick={() => {
                  if (activeTool === "fountain") {
                    setIsColorStudioOpen(false)
                    setIsPenStudioOpen((prev) => !prev)
                  } else {
                    setPreviousTool(activeTool)
                    setActiveTool("fountain")
                  }
                }}
                className={`relative w-8 h-8 rounded-xl flex flex-col items-center justify-center transition-all ${
                  activeTool === "fountain"
                    ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Fountain Pen (Calligraphic dynamic taper - Tap again for Pen Studio)"
              >
                <Pen className="w-4 h-4" />
                {activeTool === "fountain" && (
                  <span
                    className="w-1.5 h-1.5 rounded-full absolute bottom-1 shadow-sm"
                    style={{ backgroundColor: activeColor }}
                  />
                )}
              </button>

              {/* Ballpoint Pen */}
              <button
                onClick={() => {
                  if (activeTool === "ballpoint") {
                    setIsColorStudioOpen(false)
                    setIsPenStudioOpen((prev) => !prev)
                  } else {
                    setPreviousTool(activeTool)
                    setActiveTool("ballpoint")
                  }
                }}
                className={`relative w-8 h-8 rounded-xl flex flex-col items-center justify-center transition-all ${
                  activeTool === "ballpoint"
                    ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Ballpoint Pen (Uniform line weight - Tap again for Pen Studio)"
              >
                <Minus className="w-4 h-4 rotate-45 stroke-[2.5]" />
                {activeTool === "ballpoint" && (
                  <span
                    className="w-1.5 h-1.5 rounded-full absolute bottom-1 shadow-sm"
                    style={{ backgroundColor: activeColor }}
                  />
                )}
              </button>

              {/* Brush Pen */}
              <button
                onClick={() => {
                  if (activeTool === "brush") {
                    setIsColorStudioOpen(false)
                    setIsPenStudioOpen((prev) => !prev)
                  } else {
                    setPreviousTool(activeTool)
                    setActiveTool("brush")
                  }
                }}
                className={`relative w-8 h-8 rounded-xl flex flex-col items-center justify-center transition-all ${
                  activeTool === "brush"
                    ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Brush Pen (High dynamic pressure & tilt - Tap again for Pen Studio)"
              >
                <Feather className="w-4 h-4" />
                {activeTool === "brush" && (
                  <span
                    className="w-1.5 h-1.5 rounded-full absolute bottom-1 shadow-sm"
                    style={{ backgroundColor: activeColor }}
                  />
                )}
              </button>

              {/* Highlighter */}
              <button
                onClick={() => {
                  setPreviousTool(activeTool)
                  setActiveTool("highlighter")
                }}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "highlighter"
                    ? "bg-white dark:bg-slate-700 text-amber-500 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Highlighter (Draws beneath dark text ink)"
              >
                <Highlighter className="w-4 h-4" />
              </button>
            </div>

            <div className="w-px h-5 bg-slate-200 dark:bg-slate-700 mx-0.5" />

            {/* Eraser & Lasso Group */}
            <div className="flex items-center gap-0.5">
              {/* Eraser */}
              <button
                onClick={() => {
                  setPreviousTool(activeTool)
                  setActiveTool("eraser")
                }}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "eraser"
                    ? "bg-white dark:bg-slate-700 text-rose-500 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Eraser (Tap to select; options float below)"
              >
                <Eraser className="w-4 h-4" />
              </button>

              {/* Lasso */}
              <button
                onClick={() => {
                  setPreviousTool(activeTool)
                  setActiveTool("lasso")
                }}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "lasso"
                    ? "bg-white dark:bg-slate-700 text-purple-600 dark:text-purple-400 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Lasso Selection (Move, Duplicate, Recolor, OCR)"
              >
                <Lasso className="w-4 h-4" />
              </button>
            </div>

            <div className="w-px h-5 bg-slate-200 dark:bg-slate-700 mx-0.5" />

            {/* Shape & Tape Group */}
            <div className="flex items-center gap-0.5">
              {/* Shape Tool */}
              <button
                onClick={() => {
                  setPreviousTool(activeTool)
                  setActiveTool("shape")
                }}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "shape"
                    ? "bg-white dark:bg-slate-700 text-emerald-600 dark:text-emerald-400 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Shape Tool (Geometric Primitives)"
              >
                {shapeToolPrimitive === "rect" && <Square className="w-4 h-4" />}
                {shapeToolPrimitive === "ellipse" && <Circle className="w-4 h-4" />}
                {shapeToolPrimitive === "line" && <Minus className="w-4 h-4" />}
                {shapeToolPrimitive === "arrow" && <ArrowUpRight className="w-4 h-4" />}
                {shapeToolPrimitive === "triangle" && <Triangle className="w-4 h-4" />}
              </button>

              {/* Study Tape */}
              <button
                onClick={() => {
                  setPreviousTool(activeTool)
                  setActiveTool("tape")
                }}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "tape"
                    ? "bg-white dark:bg-slate-700 text-amber-500 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Study Tape Tool: Paint opaque strips over answers, tap in read-only mode to reveal"
              >
                <Minus className="w-4 h-4 stroke-[4]" />
              </button>
            </div>

            <div className="w-px h-5 bg-slate-200 dark:bg-slate-700 mx-0.5" />

            {/* Objects & Stickers Group */}
            <div className="flex items-center gap-0.5">
              {/* Text Box */}
              <button
                onClick={() => setActiveTool("textbox")}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "textbox"
                    ? "bg-white dark:bg-slate-700 text-blue-600 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Rich Text Box"
              >
                <Type className="w-4 h-4" />
              </button>

              {/* Sticky Note */}
              <button
                onClick={() => setActiveTool("stickynote")}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all ${
                  activeTool === "stickynote"
                    ? "bg-white dark:bg-slate-700 text-amber-500 shadow-sm font-semibold scale-105 ring-1 ring-black/5 dark:ring-white/10"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Collapsible Sticky Note"
              >
                <StickyNote className="w-4 h-4" />
              </button>

              {/* Insert Image */}
              <button
                onClick={() => fileInputRef.current?.click()}
                className="w-8 h-8 rounded-xl flex items-center justify-center text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50 transition-colors"
                title="Insert Image / Diagram"
              >
                <ImageIcon className="w-4 h-4" />
              </button>

              {/* Elements / Stickers Drawer */}
              <button
                onClick={() => setIsElementsDrawerOpen(!isElementsDrawerOpen)}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                  isElementsDrawerOpen
                    ? "bg-amber-100 text-amber-600 dark:bg-amber-950 dark:text-amber-400 font-semibold shadow-sm"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Elements & Reusable Stickers"
              >
                <Sparkles className="w-4 h-4" />
              </button>
            </div>

            <div className="w-px h-5 bg-slate-200 dark:bg-slate-700 mx-0.5" />

            {/* Precision & Presentation Utilities Group */}
            <div className="flex items-center gap-0.5">
              {/* Interactive Straightedge Ruler */}
              <button
                onClick={() => setRulerState((prev) => ({ ...prev, active: !prev.active }))}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                  rulerState.active
                    ? "bg-blue-600 text-white shadow-sm font-semibold"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Straightedge Ruler with Live Degree Readout (Lock straight lines at any angle)"
              >
                <Compass className="w-4 h-4" />
              </button>

              {/* Laser Pointer */}
              <div className="relative">
                <button
                  onClick={() => {
                    if (activeTool === "laser") {
                      setLaserPopoverOpen(!laserPopoverOpen)
                    } else {
                      setPreviousTool(activeTool)
                      setActiveTool("laser")
                      setLaserState((prev) => ({ ...prev, active: true }))
                      setLaserPopoverOpen(true)
                    }
                  }}
                  className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                    activeTool === "laser"
                      ? "bg-rose-600 text-white shadow-sm font-semibold"
                      : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                  }`}
                  title="Laser Pointer (Live Presentations)"
                >
                  <Radio className="w-4 h-4" />
                </button>

                {/* Laser Popover */}
                {activeTool === "laser" && laserPopoverOpen && (
                  <div className="absolute top-10 left-0 bg-white dark:bg-[#1a1d24] rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 p-2 z-50 flex flex-col gap-2 w-44 animate-in fade-in select-none">
                    <div className="flex items-center justify-between text-[11px] font-semibold text-slate-700 dark:text-slate-200">
                      <span>Laser Mode</span>
                      <button onClick={() => setLaserPopoverOpen(false)} className="text-slate-400 hover:text-slate-600">
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                    <div className="grid grid-cols-2 gap-1">
                      <button
                        onClick={() => setLaserState((prev) => ({ ...prev, mode: "trail" }))}
                        className={`px-2 py-1 rounded text-[11px] font-medium ${
                          laserState.mode === "trail"
                            ? "bg-rose-100 dark:bg-rose-950 text-rose-600 font-bold"
                            : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                        }`}
                      >
                        Trail
                      </button>
                      <button
                        onClick={() => setLaserState((prev) => ({ ...prev, mode: "dot", trail: [] }))}
                        className={`px-2 py-1 rounded text-[11px] font-medium ${
                          laserState.mode === "dot"
                            ? "bg-rose-100 dark:bg-rose-950 text-rose-600 font-bold"
                            : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                        }`}
                      >
                        Dot
                      </button>
                    </div>
                    <div className="flex items-center justify-between pt-1 border-t border-slate-100 dark:border-slate-800">
                      <span className="text-[10px] text-slate-500 font-medium">Color</span>
                      <div className="flex items-center gap-1.5">
                        {["#ef4444", "#10b981", "#06b6d4", "#ec4899"].map((col) => (
                          <button
                            key={col}
                            onClick={() => setLaserState((prev) => ({ ...prev, color: col }))}
                            className={`w-4 h-4 rounded-full border ${
                              (laserState.color || "#ef4444") === col ? "ring-2 ring-rose-400 scale-110" : ""
                            }`}
                            style={{ backgroundColor: col }}
                          />
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Zoom Window Magnifier */}
              <button
                onClick={() => setZoomWindowState((prev) => ({ ...prev, active: !prev.active }))}
                className={`w-8 h-8 rounded-xl flex items-center justify-center transition-colors ${
                  zoomWindowState.active
                    ? "bg-blue-600 text-white shadow-sm font-semibold"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200/50"
                }`}
                title="Handwriting Magnifier Zoom Window with Auto-Advance"
              >
                <ZoomIn className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Right: Quick Colors, Sizes, Palm Rejection, Audio & Export */}
          <div className="flex items-center gap-1.5 flex-shrink-0">
            {/* Audio Sync Engine Recording & Playback */}
            <AudioSyncEngine
              onRecordingStart={() => {
                recordingStartTimeRef.current = Date.now()
                setAudioEvents([])
              }}
              onRecordingStop={(recording) => {
                recordingStartTimeRef.current = 0
                setActiveRecording(recording)
                const updatedDoc = {
                  ...doc,
                  audioRecordings: [...(doc.audioRecordings || []), recording],
                }
                commitDoc(updatedDoc)
              }}
              currentEvents={audioEvents}
              activeRecording={activeRecording}
              playbackTimeMs={playbackTimeMs}
              isPlaybackActive={isPlaybackActive}
              onSeekPlayback={(timeMs) => setPlaybackTimeMs(timeMs)}
              onTogglePlayback={toggleAudioPlayback}
            />

            {/* 3 Quick Color Slots & Comprehensive Color Studio */}
            <div className="flex items-center gap-1 bg-slate-100 dark:bg-slate-800 px-1.5 py-1 rounded-full border border-slate-200 dark:border-slate-700">
              {quickColors.map((c, i) => (
                <button
                  key={i}
                  onClick={() => {
                    if (activeQuickSlot === i) {
                      setIsPenStudioOpen(false)
                      setIsColorStudioOpen((prev) => !prev)
                    } else {
                      setActiveQuickSlot(i)
                      setActiveColor(c)
                    }
                  }}
                  className={`w-5 h-5 rounded-full border-2 transition-transform ${
                    activeQuickSlot === i
                      ? "scale-115 border-blue-500 shadow-md ring-2 ring-blue-300/50"
                      : "border-white dark:border-slate-700 hover:scale-110"
                  }`}
                  style={{ backgroundColor: c }}
                  title={`Quick Color Slot ${i + 1} (Tap again to open Color Studio)`}
                />
              ))}

              {/* Color Studio Palette Trigger Button */}
              <button
                onClick={() => {
                  setIsPenStudioOpen(false)
                  setIsColorStudioOpen((prev) => !prev)
                }}
                className={`p-1 rounded-full transition-colors ml-0.5 ${
                  isColorStudioOpen
                    ? "bg-purple-100 text-purple-600 dark:bg-purple-900/60 dark:text-purple-300 shadow-sm"
                    : "text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700"
                }`}
                title="Open Color Studio (Curated Palettes, Custom Spectrum & Hex)"
              >
                <Palette className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* 3 Quick Sizes */}
            <div className="flex items-center gap-0.5 bg-slate-100 dark:bg-slate-800 px-1.5 py-1 rounded-full border border-slate-200 dark:border-slate-700">
              {quickSizes.map((s, i) => (
                <button
                  key={i}
                  onClick={() => setActiveSize(s)}
                  className={`w-5 h-5 flex items-center justify-center rounded-full transition-colors ${
                    activeSize === s ? "bg-white dark:bg-slate-700 shadow-sm" : "hover:bg-slate-200 dark:hover:bg-slate-700"
                  }`}
                  title={`Size: ${s}px`}
                >
                  <div
                    className="rounded-full bg-slate-800 dark:bg-slate-200"
                    style={{ width: Math.min(s + 2, 12), height: Math.min(s + 2, 12) }}
                  />
                </button>
              ))}
            </div>

            {/* Hardware Stylus & Palm Rejection Mode */}
            <button
              onClick={() => setDrawWithFinger(!drawWithFinger)}
              className={`flex items-center gap-1 px-2 py-1 text-xs rounded-full font-medium transition-all ${
                drawWithFinger
                  ? "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300 border border-amber-300 dark:border-amber-700"
                  : "bg-blue-50 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300 border border-blue-200 dark:border-blue-800"
              }`}
              title={
                drawWithFinger
                  ? "Finger Draw Active (Touch anywhere to draw or write)"
                  : "Apple Pencil Mode (100% Palm Rejection - Only stylus draws)"
              }
            >
              <Hand className="w-3.5 h-3.5" />
              <span className="text-[11px] hidden sm:inline">{drawWithFinger ? "Finger" : "Pencil"}</span>
              {stylusDetected && (
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" title="Apple Pencil Active" />
              )}
            </button>

            {/* Zoom Controls */}
            <div className="flex items-center gap-0.5 text-slate-600 dark:text-slate-400 bg-slate-100 dark:bg-slate-800 px-1 py-0.5 rounded-lg border border-slate-200/80 dark:border-slate-700/80 text-[11px]">
              <button
                onClick={() => setZoomLevel((z) => Math.max(0.6, z - 0.15))}
                className="p-1 hover:text-slate-900 dark:hover:text-white rounded"
                title="Zoom Out"
              >
                <ZoomOut className="w-3 h-3" />
              </button>
              <button
                onClick={() => setZoomLevel(1.0)}
                className="font-semibold px-1 hover:text-blue-500 tabular-nums"
                title="Reset Zoom"
              >
                {Math.round(zoomLevel * 100)}%
              </button>
              <button
                onClick={() => setZoomLevel((z) => Math.min(2.0, z + 0.15))}
                className="p-1 hover:text-slate-900 dark:hover:text-white rounded"
                title="Zoom In"
              >
                <ZoomIn className="w-3 h-3" />
              </button>
            </div>

            {/* Add Page Button */}
            <button
              onClick={() => addPage(currentPageIndex)}
              className="flex items-center gap-1 px-2.5 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm transition-colors"
              title="Add Page After"
            >
              <Plus className="w-3.5 h-3.5" />
              <span className="hidden md:inline">Add Page</span>
            </button>

            {/* Export SVG */}
            <button
              onClick={exportPageSvg}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              title="Export Page as Vector SVG"
            >
              <Download className="w-4 h-4" />
            </button>

            {/* Clear Page */}
            <button
              onClick={clearCurrentPage}
              className="w-8 h-8 rounded-lg flex items-center justify-center text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-lg transition-colors"
              title="Clear Current Page"
            >
              <Trash2 className="w-4 h-4" />
            </button>

            {/* Zen Fullscreen Mode Toggle */}
            <button
              onClick={() => setZenMode(!zenMode)}
              className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors ${
                zenMode
                  ? "bg-blue-600 text-white shadow-sm"
                  : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title={zenMode ? "Exit Fullscreen (Esc)" : "Zen Fullscreen Mode (Hide Sidebars)"}
            >
              {zenMode ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
            </button>
          </div>
        </header>

        {/* SECONDARY FLOATING CONTEXT SUB-BAR (Directly under toolbar when active tool has options) */}
        {activeTool === "eraser" && (
          <div className="absolute top-[52px] left-1/2 -translate-x-1/2 z-40 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md px-3 py-1 rounded-full shadow-xl border border-slate-200 dark:border-slate-700 flex items-center gap-1.5 text-xs animate-in fade-in slide-in-from-top-1 select-none">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mr-0.5">Mode</span>
            {(["precision", "standard", "stroke"] as const).map((m) => (
              <button
                key={m}
                onClick={() => setEraserMode(m)}
                className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                  eraserMode === m
                    ? "bg-rose-500 text-white shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                }`}
              >
                {m === "precision" ? "Precision (8px)" : m === "standard" ? "Standard (18px)" : "Entire Stroke"}
              </button>
            ))}
            <div className="w-px h-4 bg-slate-200 dark:bg-slate-700 mx-1" />
            <button
              onClick={() => setEraseHighlighterOnly(!eraseHighlighterOnly)}
              className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                eraseHighlighterOnly
                  ? "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300 border border-amber-300"
                  : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
              }`}
            >
              Highlighter Only
            </button>
            <button
              onClick={() => setAutoDeselectEraser(!autoDeselectEraser)}
              className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                autoDeselectEraser
                  ? "bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300 border border-rose-300"
                  : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
              }`}
            >
              Auto-Switch to Pen
            </button>
          </div>
        )}

        {activeTool === "shape" && (
          <div className="absolute top-[52px] left-1/2 -translate-x-1/2 z-40 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md px-3 py-1 rounded-full shadow-xl border border-slate-200 dark:border-slate-700 flex items-center gap-1.5 text-xs animate-in fade-in slide-in-from-top-1 select-none">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mr-0.5">Shape</span>
            {(
              [
                { id: "rect", label: "Box", icon: Square },
                { id: "ellipse", label: "Circle", icon: Circle },
                { id: "line", label: "Line", icon: Minus },
                { id: "arrow", label: "Arrow", icon: ArrowUpRight },
                { id: "triangle", label: "Triangle", icon: Triangle },
              ] as const
            ).map((item) => {
              const Icon = item.icon
              return (
                <button
                  key={item.id}
                  onClick={() => setShapeToolPrimitive(item.id as ShapePrimitive)}
                  className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                    shapeToolPrimitive === item.id
                      ? "bg-emerald-600 text-white shadow-sm"
                      : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span>{item.label}</span>
                </button>
              )
            })}
            <div className="w-px h-4 bg-slate-200 dark:bg-slate-700 mx-1" />
            <button
              onClick={() => setShapeFill(!shapeFill)}
              className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                shapeFill
                  ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300 border border-emerald-300"
                  : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
              }`}
            >
              Fill Shape
            </button>
            <button
              onClick={() => setSnapToOtherShapes(!snapToOtherShapes)}
              className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                snapToOtherShapes
                  ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300 border border-emerald-300"
                  : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
              }`}
            >
              Snap Endpoints
            </button>
            <button
              onClick={() => setAutoShapeDetection(!autoShapeDetection)}
              className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                autoShapeDetection
                  ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300 border border-emerald-300"
                  : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
              }`}
            >
              Auto-Snap (Draw & Hold)
            </button>
          </div>
        )}

        {activeTool === "lasso" && (
          <div className="absolute top-[52px] left-1/2 -translate-x-1/2 z-40 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md px-3 py-1 rounded-full shadow-xl border border-slate-200 dark:border-slate-700 flex items-center gap-2 text-xs animate-in fade-in slide-in-from-top-1 select-none">
            {/* Mode Selector */}
            <div className="flex items-center bg-slate-100 dark:bg-slate-800 rounded-full p-0.5 mr-1">
              <button
                data-testid="lasso-mode-freehand"
                onClick={() => setLassoMode("freehand")}
                className={`px-2.5 py-0.5 rounded-full text-xs font-semibold flex items-center gap-1 transition-all ${
                  lassoMode === "freehand"
                    ? "bg-white dark:bg-slate-700 text-purple-600 dark:text-purple-300 shadow-sm"
                    : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
                }`}
                title="Freehand Lasso Selection"
              >
                <Lasso className="w-3.5 h-3.5" />
                <span>Freehand</span>
              </button>
              <button
                data-testid="lasso-mode-rect"
                onClick={() => setLassoMode("rect")}
                className={`px-2.5 py-0.5 rounded-full text-xs font-semibold flex items-center gap-1 transition-all ${
                  lassoMode === "rect"
                    ? "bg-white dark:bg-slate-700 text-purple-600 dark:text-purple-300 shadow-sm"
                    : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
                }`}
                title="Rectangular Marquee Selection"
              >
                <Square className="w-3.5 h-3.5" />
                <span>Rectangle</span>
              </button>
            </div>

            <div className="w-px h-3.5 bg-slate-200 dark:bg-slate-700 mx-0.5" />
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mr-0.5">Filter</span>
            {(
              [
                { key: "handwriting", label: "Ink Handwriting" },
                { key: "images", label: "Images" },
                { key: "textBoxes", label: "Text Boxes" },
                { key: "stickyNotes", label: "Sticky Notes" },
              ] as const
            ).map((f) => (
              <button
                key={f.key}
                onClick={() => setLassoFilter((prev) => ({ ...prev, [f.key]: !prev[f.key] }))}
                className={`px-2.5 py-1 rounded-full text-xs font-semibold transition-all ${
                  lassoFilter[f.key]
                    ? "bg-purple-600 text-white shadow-sm"
                    : "text-slate-400 hover:text-slate-600 dark:hover:text-slate-300"
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
        )}

        {activeTool === "tape" && (
          <div className="absolute top-[52px] left-1/2 -translate-x-1/2 z-40 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md px-3 py-1 rounded-full shadow-xl border border-slate-200 dark:border-slate-700 flex items-center gap-2 text-xs animate-in fade-in slide-in-from-top-1 select-none">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mr-0.5">Pattern</span>
            {(["stripes", "dots", "solid"] as const).map((p) => (
              <button
                key={p}
                onClick={() => setTapePattern(p)}
                className={`px-2.5 py-1 rounded-full text-xs font-semibold capitalize transition-all ${
                  tapePattern === p
                    ? "bg-amber-500 text-white shadow-sm"
                    : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                }`}
              >
                {p}
              </button>
            ))}
            <div className="w-px h-4 bg-slate-200 dark:bg-slate-700 mx-1" />
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Color</span>
            <div className="flex items-center gap-1.5">
              {["#f59e0b", "#3b82f6", "#ec4899", "#10b981"].map((c) => (
                <button
                  key={c}
                  onClick={() => setTapeColor(c)}
                  className={`w-4 h-4 rounded-full border transition-transform ${
                    tapeColor === c ? "ring-2 ring-blue-500 scale-125" : "hover:scale-110"
                  }`}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>
        )}

        {activeTool === "highlighter" && (
          <div className="absolute top-[52px] left-1/2 -translate-x-1/2 z-40 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md px-3 py-1 rounded-full shadow-xl border border-slate-200 dark:border-slate-700 flex items-center gap-2 text-xs animate-in fade-in slide-in-from-top-1 select-none">
            <button
              onClick={() => setStraightLineHighlighter(!straightLineHighlighter)}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold transition-all ${
                straightLineHighlighter
                  ? "bg-amber-400 text-slate-900 shadow-sm"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
            >
              <Minus className="w-3.5 h-3.5 stroke-[2.5]" />
              <span>Snap Straight Horizontal/Vertical Line</span>
            </button>
          </div>
        )}

        {/* Backdrop to dismiss popovers when clicking outside */}
        {(isPenStudioOpen || isColorStudioOpen) && (
          <div
            className="fixed inset-0 z-40 bg-transparent"
            onClick={() => {
              setIsPenStudioOpen(false)
              setIsColorStudioOpen(false)
            }}
          />
        )}

        {/* Floating Pen Studio Popover (Positioned directly below toolbar) */}
        {isPenStudioOpen && (
          <div className="absolute top-full left-48 mt-1.5 z-50">
            <PenStudioPopover
              activeTool={activeTool}
              onSelectTool={(tool) => {
                setActiveTool(tool)
              }}
              penSettings={penSettings}
              onChangePenSettings={(tool, cfg) => {
                setPenSettings((prev) => ({
                  ...prev,
                  [tool]: { ...prev[tool], ...cfg },
                }))
              }}
              activeColor={activeColor}
              activeSize={activeSize}
              onChangeSize={(size) => setActiveSize(size)}
              autoShapeDetection={autoShapeDetection}
              onToggleAutoShape={() => setAutoShapeDetection(!autoShapeDetection)}
              onClose={() => setIsPenStudioOpen(false)}
            />
          </div>
        )}

        {/* Floating Color Studio Popover (Positioned directly below toolbar) */}
        {isColorStudioOpen && (
          <div className="absolute top-full right-44 mt-1.5 z-50">
            <ColorStudioPopover
              quickColors={quickColors}
              activeColorIndex={activeQuickSlot}
              onSelectQuickSlot={(idx) => {
                setActiveQuickSlot(idx)
                setActiveColor(quickColors[idx] || "#1e293b")
              }}
              onChangeQuickColor={(idx, newColor) => {
                const updated = [...quickColors]
                updated[idx] = newColor
                setQuickColors(updated)
                if (activeQuickSlot === idx) {
                  setActiveColor(newColor)
                }
              }}
              onClose={() => setIsColorStudioOpen(false)}
            />
          </div>
        )}
      </div>

      {/* Main Workspace Area with Drawers */}
      <div className="flex-1 flex overflow-hidden relative">
        {/* Document Navigation Drawer (Thumbnails, Outlines, Bookmarks) */}
        <DocumentNavigationDrawer
          isOpen={isNavDrawerOpen}
          onClose={() => setIsNavDrawerOpen(false)}
          pages={doc.pages}
          currentPageIndex={currentPageIndex}
          onSelectPage={(idx) => setCurrentPageIndex(idx)}
          onAddPage={addPage}
          onDuplicatePage={duplicatePage}
          onDeletePage={deletePage}
          onRotatePage={rotatePage}
          onToggleBookmark={toggleBookmark}
          outlines={doc.outlines}
          readOnly={readOnly}
          onToggleReadOnly={() => setReadOnly(!readOnly)}
        />

        {/* Elements / Stickers Drawer */}
        <ElementsDrawer
          isOpen={isElementsDrawerOpen}
          onClose={() => setIsElementsDrawerOpen(false)}
          customElements={customElements}
          onInsertElement={(element) => {
            const translatedStrokes = element.strokes.map((s) =>
              translateStroke(
                { ...s, id: `elem_stroke_${Date.now()}_${Math.random().toString(36).slice(2, 6)}` },
                150,
                150
              )
            )
            pushHistory()
            const updatedPages = [...doc.pages]
            updatedPages[currentPageIndex] = {
              ...currentPage,
              strokes: [...currentPage.strokes, ...translatedStrokes],
            }
            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
            setIsElementsDrawerOpen(false)
          }}
          onDeleteCustomElement={(id) => {
            setCustomElements((prev) => prev.filter((el) => el.id !== id))
          }}
        />

        {/* Scrollable Canvas Viewport with Native Multi-Touch Gesture Handling */}
        <div
          ref={containerRef}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
          onDragOver={(e) => {
            e.preventDefault()
            e.dataTransfer.dropEffect = "copy"
          }}
          onDrop={(e) => {
            e.preventDefault()
            const files = e.dataTransfer.files
            if (files && files.length > 0) {
              for (let i = 0; i < files.length; i++) {
                if (files[i].type.startsWith("image/")) {
                  const file = files[i]
                  const reader = new FileReader()
                  reader.onload = () => {
                    const url = reader.result as string
                    const newImg: NotebookImage = {
                      id: `img_${Date.now()}_${i}`,
                      url,
                      x: 100 + i * 20,
                      y: 100 + i * 20,
                      width: 320,
                      height: 240,
                    }
                    pushHistory()
                    const updatedPages = [...docRef.current.pages]
                    const curP = updatedPages[currentPageIndex] || updatedPages[0]
                    updatedPages[currentPageIndex] = {
                      ...curP,
                      images: [...(curP.images || []), newImg],
                    }
                    commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
                  }
                  reader.readAsDataURL(file)
                  break
                }
              }
            }
          }}
          className="flex-1 overflow-auto flex items-center justify-center p-8 relative touch-none"
        >
          {/* Scaled Notebook Page Canvas Wrapper */}
          <div
            className="relative shadow-2xl transition-transform origin-top-left"
            style={{
              width: `${currentPage.width * zoomLevel}px`,
              height: `${currentPage.height * zoomLevel}px`,
              transform: `rotate(${currentPage.rotation || 0}deg)`,
            }}
          >
            {/* Lasso Floating Action Menu inside Page coordinate system */}
            {(selectedStrokeIds.size > 0 || selectedBoxIds.size > 0 || selectedImageIds.size > 0) &&
              computedSelectionBounds && (
                <div
                  className="absolute z-50 bg-white dark:bg-[#1a1d24] px-3 py-1.5 rounded-full shadow-2xl border border-slate-200 dark:border-slate-700 flex items-center gap-2 animate-in fade-in select-none"
                  style={{
                    left: `${Math.max(10, Math.min(currentPage.width * zoomLevel - 440, computedSelectionBounds.minX * zoomLevel))}px`,
                    top: `${
                      computedSelectionBounds.minY * zoomLevel - 52 < 70
                        ? Math.min(currentPage.height * zoomLevel - 50, computedSelectionBounds.maxY * zoomLevel + 16)
                        : computedSelectionBounds.minY * zoomLevel - 52
                    }px`,
                  }}
                >
                  <span className="text-xs font-semibold text-slate-700 dark:text-slate-200">
                    {selectedStrokeIds.size + selectedBoxIds.size + selectedImageIds.size} Selected
                  </span>
                  <div className="h-3 w-px bg-slate-300 dark:bg-slate-700" />
                  <button
                    onClick={duplicateSelected}
                    className="flex items-center gap-1 text-xs text-blue-600 dark:text-blue-400 font-semibold hover:underline"
                  >
                    <Copy className="w-3.5 h-3.5" />
                    <span>Duplicate</span>
                  </button>
                  <button
                    onClick={() => rotateSelected(90)}
                    className="flex items-center gap-1 text-xs text-blue-600 dark:text-blue-400 font-semibold hover:underline"
                    title="Rotate selected group 90 degrees"
                  >
                    <RotateCw className="w-3.5 h-3.5" />
                    <span>Rotate</span>
                  </button>
                  <button
                    onClick={captureSelectionScreenshot}
                    className="flex items-center gap-1 text-xs text-slate-600 dark:text-slate-300 font-semibold hover:underline"
                    title="Capture screenshot of selected area to clipboard"
                  >
                    <Camera className="w-3.5 h-3.5" />
                    <span>Screenshot</span>
                  </button>
                  <button
                    onClick={convertSelectedToText}
                    className="text-xs text-slate-600 dark:text-slate-300 font-semibold hover:underline"
                    title="Transcribe handwriting to text"
                  >
                    To Text
                  </button>
                  <button
                    onClick={convertSelectedToMath}
                    className="text-xs text-slate-600 dark:text-slate-300 font-semibold hover:underline"
                    title="Convert handwriting to LaTeX math formula"
                  >
                    To Math
                  </button>
                  <button
                    onClick={saveSelectedAsElement}
                    className="text-xs text-amber-600 dark:text-amber-400 font-semibold hover:underline flex items-center gap-1"
                    title="Save as Reusable Element / Sticker"
                  >
                    <Sparkles className="w-3 h-3" />
                    <span>Save Element</span>
                  </button>
                  <div className="flex items-center gap-1">
                    {["#1e293b", "#2563eb", "#059669", "#dc2626", "#7c3aed"].map((c) => (
                      <button
                        key={c}
                        onClick={() => recolorSelected(c)}
                        className="w-4 h-4 rounded-full border border-slate-300"
                        style={{ backgroundColor: c }}
                      />
                    ))}
                  </div>
                  <button
                    onClick={deleteSelected}
                    className="p-1 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-full"
                    title="Delete Selection"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => {
                      setSelectedStrokeIds(new Set())
                      setSelectedBoxIds(new Set())
                      setSelectedImageIds(new Set())
                      initialSelectionSnapshotRef.current = null
                    }}
                    className="p-1 text-slate-400 hover:text-slate-600 rounded-full"
                    title="Clear Selection"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
              )}

            <svg
              ref={svgRef}
              viewBox={`0 0 ${currentPage.width} ${currentPage.height}`}
              className="w-full h-full touch-none select-none overflow-visible rounded-sm"
              style={{
                backgroundColor:
                  currentPage.paperColor === "dark"
                    ? "#1a1e24"
                    : currentPage.paperColor === "cream"
                    ? "#fefae0"
                    : "#ffffff",
              }}
              onPointerDown={handlePointerDown}
              onPointerMove={handlePointerMove}
              onPointerUp={handlePointerUp}
              onPointerCancel={() => {
                handlePointerUp()
                setCanvasPointerPos(null)
                lastEraserPointRef.current = null
                setLaserState((prev) => ({ ...prev, current: null, active: false }))
              }}
              onPointerLeave={() => {
                setCanvasPointerPos(null)
                lastEraserPointRef.current = null
                setLaserState((prev) => ({ ...prev, current: null }))
              }}
            >
              <defs>{renderBackgroundPattern()}</defs>

              {/* Page Background Template */}
              <rect
                x="0"
                y="0"
                width={currentPage.width}
                height={currentPage.height}
                fill={getBackgroundFill()}
              />

              {/* Layer 1: Placed Images with Drag, Selection, Resize & Crop */}
              {(currentPage.images || []).map((img) => {
                const isSelected = activeImageId === img.id || selectedImageIds.has(img.id)
                return (
                  <g
                    key={img.id}
                    onClick={(e) => {
                      if (readOnly) return
                      e.stopPropagation()
                      setActiveImageId(img.id)
                    }}
                    onPointerDown={(e) => {
                      if (readOnly) return
                      if (activeTool === "image" || activeImageId === img.id) {
                        startImageDrag(e, img)
                      }
                    }}
                    className={isSelected ? "cursor-move" : "cursor-pointer"}
                  >
                    <image
                      href={img.url}
                      x={img.x}
                      y={img.y}
                      width={img.width}
                      height={img.height}
                      className="select-none"
                    />
                    {isSelected && !readOnly && (
                      <g className="image-selection-overlay">
                        <rect
                          x={img.x - 2}
                          y={img.y - 2}
                          width={img.width + 4}
                          height={img.height + 4}
                          fill="none"
                          stroke="#3b82f6"
                          strokeWidth={2}
                          strokeDasharray="4,4"
                        />
                        {/* 4 Corner handles for resizing */}
                        {([
                          { cx: img.x, cy: img.y, cursor: "nwse-resize", corner: "tl" },
                          { cx: img.x + img.width, cy: img.y, cursor: "nesw-resize", corner: "tr" },
                          { cx: img.x, cy: img.y + img.height, cursor: "nesw-resize", corner: "bl" },
                          { cx: img.x + img.width, cy: img.y + img.height, cursor: "nwse-resize", corner: "br" },
                        ] as const).map((h, i) => (
                          <circle
                            key={i}
                            cx={h.cx}
                            cy={h.cy}
                            r={6}
                            fill="#ffffff"
                            stroke="#3b82f6"
                            strokeWidth={2}
                            style={{ cursor: h.cursor }}
                            onPointerDown={(e) => {
                              e.stopPropagation()
                              startImageResize(e, img, h.corner)
                            }}
                          />
                        ))}
                        {/* Delete button on top right */}
                        <g
                          transform={`translate(${img.x + img.width + 12}, ${img.y - 6})`}
                          className="cursor-pointer hover:scale-110 transition-transform"
                          onClick={(e) => {
                            e.stopPropagation()
                            deleteImage(img.id)
                          }}
                        >
                          <circle cx={0} cy={0} r={10} fill="#ef4444" />
                          <line x1={-4} y1={-4} x2={4} y2={4} stroke="#ffffff" strokeWidth={2} />
                          <line x1={4} y1={-4} x2={-4} y2={4} stroke="#ffffff" strokeWidth={2} />
                        </g>
                        {/* Quick Crop button on right */}
                        <g
                          transform={`translate(${img.x + img.width + 12}, ${img.y + 18})`}
                          className="cursor-pointer hover:scale-110 transition-transform"
                          onClick={(e) => {
                            e.stopPropagation()
                            pushHistory()
                            const insetX = Math.round(img.width * 0.08)
                            const insetY = Math.round(img.height * 0.08)
                            const updated = (currentPage.images || []).map((i) =>
                              i.id === img.id
                                ? {
                                    ...i,
                                    x: i.x + insetX,
                                    y: i.y + insetY,
                                    width: Math.max(40, i.width - insetX * 2),
                                    height: Math.max(40, i.height - insetY * 2),
                                  }
                                : i
                            )
                            const updatedPages = [...docRef.current.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, images: updated }
                            commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
                          }}
                        >
                          <title>Crop margins (8%)</title>
                          <circle cx={0} cy={0} r={10} fill="#3b82f6" />
                          <path d="M-4,-2 L2,-2 L2,4 M4,2 L-2,2 L-2,-4" stroke="#ffffff" strokeWidth={1.5} fill="none" strokeLinecap="round" />
                        </g>
                      </g>
                    )}
                  </g>
                )
              })}

              {/* Layer 2: Highlighters (Layered underneath handwriting) */}
              <g
                className="highlighter-layer"
                style={{ mixBlendMode: currentPage.paperColor === "dark" ? "screen" : "multiply" }}
              >
                {highlighterStrokes.map((s) => {
                  const isDimmed = isPlaybackActive && s.audioTimeOffset && s.audioTimeOffset > playbackTimeMs
                  return (
                    <path
                      key={s.id}
                      d={getCachedStrokePath(s)}
                      fill={s.color}
                      stroke="none"
                      strokeWidth={0}
                      opacity={isDimmed ? 0.2 : 0.75}
                      className="transition-opacity cursor-pointer"
                      onClick={() => {
                        if (s.audioTimeOffset !== undefined) {
                          setPlaybackTimeMs(s.audioTimeOffset)
                        }
                      }}
                    />
                  )
                })}
              </g>

              {/* Layer 3: Dark Handwriting Pens & Geometric Shapes */}
              <g className="pen-strokes-layer">
                {penStrokes.map((s) => {
                  const isDimmed = isPlaybackActive && s.audioTimeOffset && s.audioTimeOffset > playbackTimeMs
                  return (
                    <path
                      key={s.id}
                      d={getCachedStrokePath(s)}
                      {...getStrokeStyle(s)}
                      opacity={isDimmed ? 0.2 : 1}
                      className="cursor-pointer transition-opacity duration-150"
                      onClick={() => {
                        if (s.audioTimeOffset !== undefined) {
                          setPlaybackTimeMs(s.audioTimeOffset)
                        }
                      }}
                    />
                  )
                })}
              </g>

              {/* Layer 4: Interactive Study Tape Strips */}
              <TapeLayer
                tapeStrips={currentPage.tapeStrips || []}
                isStudyMode={readOnly}
                onToggleReveal={toggleTapeReveal}
              />

              {/* In-progress Active Tape Dragging Draft */}
              {activeTapeDraft && (
                <TapeLayer
                  tapeStrips={[{
                    id: "tape_draft",
                    points: [activeTapeDraft.start, activeTapeDraft.current],
                    width: Math.max(16, activeSize * 4),
                    color: tapeColor,
                    pattern: tapePattern,
                    revealed: false,
                    createdAt: Date.now(),
                  }]}
                  isStudyMode={false}
                />
              )}

              {/* In-progress Live Stroke */}
              {currentStroke && (
                <path
                  d={renderStrokeToPath(currentStroke)}
                  {...getStrokeStyle(currentStroke)}
                  opacity={activeTool === "highlighter" ? 0.65 : 1}
                />
              )}

              {/* Lasso Selection Loop Path */}
              {activeTool === "lasso" && lassoPoints.length > 1 && (
                lassoMode === "rect" ? (
                  <rect
                    x={Math.min(lassoPoints[0].x, lassoPoints[lassoPoints.length - 1].x)}
                    y={Math.min(lassoPoints[0].y, lassoPoints[lassoPoints.length - 1].y)}
                    width={Math.abs(lassoPoints[lassoPoints.length - 1].x - lassoPoints[0].x)}
                    height={Math.abs(lassoPoints[lassoPoints.length - 1].y - lassoPoints[0].y)}
                    fill="rgba(147, 51, 234, 0.1)"
                    stroke="#9333ea"
                    strokeWidth={1.5}
                    strokeDasharray="4,4"
                  />
                ) : (
                  <path
                    d={`M${lassoPoints.map((p) => `${p.x},${p.y}`).join(" L")}${lassoPoints.length > 2 ? " Z" : ""}`}
                    fill="rgba(147, 51, 234, 0.1)"
                    stroke="#9333ea"
                    strokeWidth={1.5}
                    strokeDasharray="4,4"
                  />
                )
              )}

              {/* Selected Group Bounding Box Indicator with Corner Resize Handles */}
              {computedSelectionBounds &&
                (selectedStrokeIds.size > 0 || selectedBoxIds.size > 0 || selectedImageIds.size > 0) && (
                  <g className="lasso-selection-box">
                    <rect
                      x={computedSelectionBounds.minX - 6}
                      y={computedSelectionBounds.minY - 6}
                      width={computedSelectionBounds.maxX - computedSelectionBounds.minX + 12}
                      height={computedSelectionBounds.maxY - computedSelectionBounds.minY + 12}
                      fill="rgba(59, 130, 246, 0.05)"
                      stroke="#3b82f6"
                      strokeWidth={1.5}
                      strokeDasharray="4,4"
                      className="cursor-move"
                    />

                    {/* Top Rotation Handle Stem and Circular Pin */}
                    <line
                      x1={(computedSelectionBounds.minX + computedSelectionBounds.maxX) / 2}
                      y1={computedSelectionBounds.minY - 6}
                      x2={(computedSelectionBounds.minX + computedSelectionBounds.maxX) / 2}
                      y2={computedSelectionBounds.minY - 24}
                      stroke="#3b82f6"
                      strokeWidth={1.5}
                    />
                    <circle
                      cx={(computedSelectionBounds.minX + computedSelectionBounds.maxX) / 2}
                      cy={computedSelectionBounds.minY - 24}
                      r={7}
                      fill="#3b82f6"
                      stroke="#ffffff"
                      strokeWidth={2}
                      className="cursor-pointer hover:scale-125 transition-transform"
                      onPointerDown={(e) => {
                        e.stopPropagation()
                        rotateSelected(90)
                      }}
                    >
                      <title>Rotate Selection 90°</title>
                    </circle>

                    {/* Bottom-right Corner Scale Handle */}
                    <circle
                      cx={computedSelectionBounds.maxX + 6}
                      cy={computedSelectionBounds.maxY + 6}
                      r={7}
                      fill="#3b82f6"
                      stroke="#ffffff"
                      strokeWidth={2}
                      className="cursor-nwse-resize"
                      onPointerDown={(e) => {
                        e.stopPropagation()
                        const startX = e.clientX
                        const startY = e.clientY
                        const origW = computedSelectionBounds.maxX - computedSelectionBounds.minX
                        const origH = computedSelectionBounds.maxY - computedSelectionBounds.minY
                        const origin = { x: computedSelectionBounds.minX, y: computedSelectionBounds.minY }
                        const strokeSnapshot = currentPage.strokes.filter((s) => selectedStrokeIds.has(s.id))
                        const boxSnapshot = (currentPage.textBoxes || []).filter((b) => selectedBoxIds.has(b.id))
                        const imgSnapshot = (currentPage.images || []).filter((i) => selectedImageIds.has(i.id))
                        let latestPages = docRef.current.pages

                        const onMove = (moveEv: PointerEvent) => {
                          const dw = (moveEv.clientX - startX) / zoomLevel
                          const dh = (moveEv.clientY - startY) / zoomLevel
                          const sx = Math.max(0.2, (origW + dw) / Math.max(10, origW))
                          const sy = Math.max(0.2, (origH + dh) / Math.max(10, origH))

                          const updatedStrokes = currentPage.strokes.map((s) => {
                            if (selectedStrokeIds.has(s.id)) {
                              const orig = strokeSnapshot.find((x) => x.id === s.id)
                              return orig ? scaleStroke(orig, sx, sy, origin) : s
                            }
                            return s
                          })

                          const updatedBoxes = (currentPage.textBoxes || []).map((b) => {
                            if (selectedBoxIds.has(b.id)) {
                              const orig = boxSnapshot.find((x) => x.id === b.id)
                              if (!orig) return b
                              const newX = Math.round(origin.x + (orig.x - origin.x) * sx)
                              const newY = Math.round(origin.y + (orig.y - origin.y) * sy)
                              const newW = Math.max(30, Math.round(orig.width * sx))
                              const newH = Math.max(20, Math.round(orig.height * sy))
                              const newFontSize = Math.max(8, Math.round((orig.fontSize || 16) * Math.min(sx, sy)))
                              return { ...orig, x: newX, y: newY, width: newW, height: newH, fontSize: newFontSize }
                            }
                            return b
                          })

                          const updatedImages = (currentPage.images || []).map((img) => {
                            if (selectedImageIds.has(img.id)) {
                              const orig = imgSnapshot.find((x) => x.id === img.id)
                              if (!orig) return img
                              const newX = Math.round(origin.x + (orig.x - origin.x) * sx)
                              const newY = Math.round(origin.y + (orig.y - origin.y) * sy)
                              const newW = Math.max(20, Math.round(orig.width * sx))
                              const newH = Math.max(20, Math.round(orig.height * sy))
                              return { ...orig, x: newX, y: newY, width: newW, height: newH }
                            }
                            return img
                          })

                          latestPages = [...docRef.current.pages]
                          latestPages[currentPageIndex] = {
                            ...currentPage,
                            strokes: updatedStrokes,
                            textBoxes: updatedBoxes,
                            images: updatedImages,
                          }
                          docRef.current = { ...docRef.current, pages: latestPages }
                          setDoc(docRef.current)
                        }

                        const onUp = () => {
                          window.removeEventListener("pointermove", onMove)
                          window.removeEventListener("pointerup", onUp)
                          pushHistory()
                          commitDoc({ ...docRef.current, pages: latestPages, updatedAt: Date.now() })
                        }
                        window.addEventListener("pointermove", onMove)
                        window.addEventListener("pointerup", onUp)
                      }}
                    />
                  </g>
                )}

              {/* Eraser radius visual indicator cursor */}
              {activeTool === "eraser" && canvasPointerPos && (
                <circle
                  cx={canvasPointerPos.x}
                  cy={canvasPointerPos.y}
                  r={eraserMode === "precision" ? 8 : eraserMode === "standard" ? 18 : 28}
                  fill="rgba(244, 63, 94, 0.15)"
                  stroke="#f43f5e"
                  strokeWidth={1.5}
                  strokeDasharray="3,3"
                  className="pointer-events-none"
                />
              )}

              {/* Zoom Window Target Magnification Indicator Box (Draggable) */}
              {zoomWindowState.active && (
                <g
                  className="zoom-target-indicator cursor-move"
                  onPointerDown={(e) => {
                    e.stopPropagation()
                    try {
                      e.currentTarget.setPointerCapture(e.pointerId)
                    } catch {}
                    const startClientX = e.clientX
                    const startClientY = e.clientY
                    const startTargetX = zoomWindowState.targetX
                    const startTargetY = zoomWindowState.targetY

                    const onMove = (moveEv: PointerEvent) => {
                      const dx = (moveEv.clientX - startClientX) / zoomLevel
                      const dy = (moveEv.clientY - startClientY) / zoomLevel
                      setZoomWindowState((prev) => ({
                        ...prev,
                        targetX: Math.max(0, Math.min(currentPage.width - 100, startTargetX + dx)),
                        targetY: Math.max(0, Math.min(currentPage.height - 100, startTargetY + dy)),
                      }))
                    }
                    const onUp = () => {
                      window.removeEventListener("pointermove", onMove)
                      window.removeEventListener("pointerup", onUp)
                    }
                    window.addEventListener("pointermove", onMove)
                    window.addEventListener("pointerup", onUp)
                  }}
                >
                  <rect
                    x={zoomWindowState.targetX}
                    y={zoomWindowState.targetY}
                    width={zoomWindowState.width / zoomWindowState.scale}
                    height={zoomWindowState.height / zoomWindowState.scale}
                    fill="rgba(59, 130, 246, 0.12)"
                    stroke="#3b82f6"
                    strokeWidth={2}
                    strokeDasharray="4,4"
                  />
                  <rect
                    x={zoomWindowState.targetX}
                    y={zoomWindowState.targetY - 20}
                    width={100}
                    height={20}
                    rx={4}
                    fill="#3b82f6"
                  />
                  <text
                    x={zoomWindowState.targetX + 50}
                    y={zoomWindowState.targetY - 6}
                    textAnchor="middle"
                    fontSize={10}
                    fill="#ffffff"
                    fontWeight="bold"
                    className="select-none pointer-events-none"
                  >
                    Magnifier ⠿ Drag
                  </text>
                </g>
              )}

              {/* Interactive Straightedge Ruler & Laser Overlays */}
              <RulerOverlay
                ruler={rulerState}
                onChangeRuler={setRulerState}
                laser={laserState}
                onChangeLaser={setLaserState}
                zoomLevel={zoomLevel}
              />
            </svg>

            {/* Layer 5: Interactive Text Boxes & Collapsible Sticky Notes with Drag Handles */}
            {(currentPage.textBoxes || []).map((box) => {
              const isEditing = editingBoxId === box.id
              return (
                <div
                  key={box.id}
                  className={`absolute group select-none transition-shadow ${
                    box.isStickyNote ? "shadow-lg rounded-xl p-3 border-t-4" : "p-1.5 rounded-lg border border-transparent hover:border-slate-300"
                  }`}
                  style={{
                    left: `${box.x * zoomLevel}px`,
                    top: `${box.y * zoomLevel}px`,
                    width: `${box.width * zoomLevel}px`,
                    height: box.collapsed ? "38px" : `${box.height * zoomLevel}px`,
                    backgroundColor: box.backgroundColor || "transparent",
                    color: box.color,
                  }}
                  onDoubleClick={() => !readOnly && setEditingBoxId(box.id)}
                >
                  {/* Top Bar for dragging, collapsing, and actions */}
                  <div
                    className="flex items-center justify-between pb-1 mb-1 border-b border-black/10 cursor-move text-xs select-none"
                    onPointerDown={(e) => {
                      if (readOnly) return
                      e.stopPropagation()
                      const startX = e.clientX
                      const startY = e.clientY
                      const origX = box.x
                      const origY = box.y
                      let latestPages = docRef.current.pages
                      const onMove = (moveEv: PointerEvent) => {
                        const dx = (moveEv.clientX - startX) / zoomLevel
                        const dy = (moveEv.clientY - startY) / zoomLevel
                        const updatedBoxes = currentPage.textBoxes.map((b) =>
                          b.id === box.id ? { ...b, x: Math.round(origX + dx), y: Math.round(origY + dy) } : b
                        )
                        latestPages = [...docRef.current.pages]
                        latestPages[currentPageIndex] = { ...currentPage, textBoxes: updatedBoxes }
                        docRef.current = { ...docRef.current, pages: latestPages }
                        setDoc(docRef.current)
                      }
                      const onUp = () => {
                        window.removeEventListener("pointermove", onMove)
                        window.removeEventListener("pointerup", onUp)
                        pushHistory()
                        commitDoc({ ...docRef.current, pages: latestPages, updatedAt: Date.now() })
                      }
                      window.addEventListener("pointermove", onMove)
                      window.addEventListener("pointerup", onUp)
                    }}
                  >
                    <div className="flex items-center gap-1 font-semibold text-[10px] opacity-75">
                      <GripHorizontal className="w-3.5 h-3.5" />
                      <span>{box.isStickyNote ? "Sticky Note" : "Text"}</span>
                    </div>

                    <div className="flex items-center gap-1">
                      {box.isStickyNote && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, collapsed: !b.collapsed } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="p-0.5 hover:bg-black/10 rounded"
                          title={box.collapsed ? "Expand note" : "Collapse note"}
                        >
                          {box.collapsed ? (
                            <ChevronDown className="w-3 h-3" />
                          ) : (
                            <ChevronUp className="w-3 h-3" />
                          )}
                        </button>
                      )}
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          pushHistory()
                          const updated = currentPage.textBoxes.filter((b) => b.id !== box.id)
                          const updatedPages = [...doc.pages]
                          updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                          commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                        }}
                        className="p-0.5 hover:bg-rose-500/20 text-rose-600 rounded"
                        title="Delete box"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </div>

                  {isEditing ? (
                    <div className="w-full h-[calc(100%-28px)] flex flex-col">
                      <div
                        className="flex items-center gap-1 mb-1 p-1 bg-white/95 dark:bg-slate-800/95 rounded shadow-sm text-xs flex-wrap"
                        onPointerDown={(e) => e.preventDefault()}
                      >
                        <button
                          onPointerDown={(e) => e.preventDefault()}
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, bold: !b.bold } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className={`px-1.5 py-0.5 rounded font-bold ${box.bold ? "bg-slate-200" : ""}`}
                        >
                          B
                        </button>
                        <button
                          onPointerDown={(e) => e.preventDefault()}
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, italic: !b.italic } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className={`px-1.5 py-0.5 rounded italic ${box.italic ? "bg-slate-200" : ""}`}
                        >
                          I
                        </button>
                        <button
                          onPointerDown={(e) => e.preventDefault()}
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, fontSize: Math.max(10, b.fontSize - 2) } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="px-1 text-slate-600 rounded"
                        >
                          A-
                        </button>
                        <button
                          onPointerDown={(e) => e.preventDefault()}
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, fontSize: Math.min(48, b.fontSize + 2) } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="px-1 text-slate-600 rounded"
                        >
                          A+
                        </button>
                        <select
                          value={box.fontFamily || "sans"}
                          onPointerDown={(e) => e.stopPropagation()}
                          onChange={(e) => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, fontFamily: e.target.value as any } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="text-[10px] bg-slate-100 dark:bg-slate-700 rounded px-1 py-0.5 outline-none"
                        >
                          <option value="sans">Sans</option>
                          <option value="serif">Serif</option>
                          <option value="mono">Mono</option>
                          <option value="handwriting">Handwriting</option>
                        </select>
                      </div>

                      <textarea
                        autoFocus
                        defaultValue={box.text}
                        className={`w-full h-full bg-transparent resize-none border-none outline-none ${
                          box.fontFamily === "serif"
                            ? "font-serif"
                            : box.fontFamily === "mono"
                            ? "font-mono"
                            : "font-sans"
                        }`}
                        style={{
                          fontSize: `${box.fontSize * zoomLevel}px`,
                          color: box.color,
                          fontWeight: box.bold ? "bold" : "normal",
                          fontStyle: box.italic ? "italic" : "normal",
                        }}
                        onBlur={(e) => {
                          setEditingBoxId(null)
                          const updatedBoxes = currentPage.textBoxes.map((b) =>
                            b.id === box.id ? { ...b, text: e.target.value } : b
                          )
                          const updatedPages = [...doc.pages]
                          updatedPages[currentPageIndex] = {
                            ...currentPage,
                            textBoxes: updatedBoxes,
                          }
                          commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                        }}
                      />
                    </div>
                  ) : (
                    <div
                      onClick={() => !readOnly && setEditingBoxId(box.id)}
                      className={`w-full h-[calc(100%-28px)] overflow-hidden whitespace-pre-wrap cursor-text ${
                        box.fontFamily === "serif"
                          ? "font-serif"
                          : box.fontFamily === "mono"
                          ? "font-mono"
                          : "font-sans"
                      }`}
                      style={{
                        fontSize: `${box.fontSize * zoomLevel}px`,
                        fontWeight: box.bold ? "bold" : "normal",
                        fontStyle: box.italic ? "italic" : "normal",
                      }}
                      title="Click to edit text"
                    >
                      {box.collapsed ? (box.text.split("\n")[0] || "Note...") : box.text}
                    </div>
                  )}

                  {/* Corner Resize Handle */}
                  {!readOnly && !box.collapsed && (
                    <div
                      className="absolute bottom-1 right-1 w-3.5 h-3.5 cursor-nwse-resize opacity-40 hover:opacity-100 flex items-center justify-center select-none"
                      onPointerDown={(e) => {
                        e.stopPropagation()
                        const startX = e.clientX
                        const startY = e.clientY
                        const origW = box.width
                        const origH = box.height
                        let latestPages = docRef.current.pages

                        const onMove = (moveEv: PointerEvent) => {
                          const dw = (moveEv.clientX - startX) / zoomLevel
                          const dh = (moveEv.clientY - startY) / zoomLevel
                          const updatedBoxes = currentPage.textBoxes.map((b) =>
                            b.id === box.id
                              ? { ...b, width: Math.max(100, Math.round(origW + dw)), height: Math.max(40, Math.round(origH + dh)) }
                              : b
                          )
                          latestPages = [...docRef.current.pages]
                          latestPages[currentPageIndex] = { ...currentPage, textBoxes: updatedBoxes }
                          docRef.current = { ...docRef.current, pages: latestPages }
                          setDoc(docRef.current)
                        }
                        const onUp = () => {
                          window.removeEventListener("pointermove", onMove)
                          window.removeEventListener("pointerup", onUp)
                          pushHistory()
                          commitDoc({ ...docRef.current, pages: latestPages, updatedAt: Date.now() })
                        }
                        window.addEventListener("pointermove", onMove)
                        window.addEventListener("pointerup", onUp)
                      }}
                    >
                      <svg width="8" height="8" viewBox="0 0 8 8" fill="none">
                        <path d="M7 1L1 7M7 4L4 7M7 7L7 7" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
                      </svg>
                    </div>
                  )}
                </div>
              )
            })}
          </div>

          {/* Floating Zoom Window (Magnifier) */}
          <ZoomWindow
            state={zoomWindowState}
            onClose={() => setZoomWindowState((prev) => ({ ...prev, active: false }))}
            onChangeTarget={(tx, ty) =>
              setZoomWindowState((prev) => ({ ...prev, targetX: tx, targetY: ty }))
            }
            onChangeScale={(s) => setZoomWindowState((prev) => ({ ...prev, scale: s }))}
            strokes={currentPage.strokes}
            activeColor={activeColor}
            activeSize={activeSize}
            activeTool={activeTool}
            onAddStroke={(s) => {
              pushHistory()
              const audioOffset =
                recordingStartTimeRef.current > 0 ? Date.now() - recordingStartTimeRef.current : undefined
              const strokeWithAudio = audioOffset !== undefined ? { ...s, audioTimeOffset: audioOffset } : s
              const updatedPages = [...docRef.current.pages]
              updatedPages[currentPageIndex] = {
                ...currentPage,
                strokes: [...currentPage.strokes, strokeWithAudio],
              }
              commitDoc({ ...docRef.current, pages: updatedPages, updatedAt: Date.now() })
            }}
          />
        </div>
      </div>
    </div>
  )
}
