import { useState, useRef, useCallback, useEffect } from "react"
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
  X,
  Maximize2,
  Minimize2,
  Download,
} from "lucide-react"
import {
  type NotebookDocument,
  type NotebookPage,
  type InkStroke,
  type InkTextBox,
  type NotebookImage,
  type PageTemplate,
  type PaperColor,
  type ShapePrimitive,
  type InkToolType,
  createEmptyNotebook,
  createEmptyPage,
} from "./types"
import {
  renderStrokeToPath,
  isPointNearStroke,
  isStrokeInLasso,
  isBoxInLasso,
  getStrokesBounds,
  translateStroke,
  detectGeometricShape,
} from "./stroke"

interface NotebookBoardProps {
  text: string
  path?: string
  editable?: boolean
  place?: string
  onChange?: (newText: string) => void
}

const PRESET_COLORS = [
  "#1e293b", // Slate Black
  "#2563eb", // Royal Blue
  "#059669", // Emerald Green
  "#dc2626", // Crimson Red
  "#7c3aed", // Royal Purple
  "#d97706", // Amber
  "#0891b2", // Teal
  "#db2777", // Rose Pink
  "#f8fafc", // White (for dark paper)
]

const STICKY_COLORS = [
  { bg: "#fef3c7", text: "#78350f", border: "#fde68a" }, // Amber/Yellow
  { bg: "#e0f2fe", text: "#0369a1", border: "#bae6fd" }, // Sky Blue
  { bg: "#dcfce7", text: "#15803d", border: "#bbf7d0" }, // Mint Green
  { bg: "#fce7f3", text: "#be185d", border: "#fbcfe8" }, // Rose Pink
  { bg: "#f3e8ff", text: "#6b21a8", border: "#e9d5ff" }, // Purple
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
      // Fallback to fresh notebook
    }
    return createEmptyNotebook(path ? path.split("/").pop()?.replace(".notebook", "") : "Untitled Notebook")
  })

  const [currentPageIndex, setCurrentPageIndex] = useState(0)

  // GoodNotes Tool Modes
  const [activeTool, setActiveTool] = useState<InkToolType>("fountain")
  const [eraserMode, setEraserMode] = useState<"stroke" | "highlighterOnly">("stroke")
  const [shapeToolPrimitive, setShapeToolPrimitive] = useState<ShapePrimitive>("rect")
  const [autoShapeDetection, setAutoShapeDetection] = useState(true)

  // Quick Colors & Sizes
  const [quickColors, setQuickColors] = useState(["#1e293b", "#2563eb", "#dc2626"])
  const [activeColor, setActiveColor] = useState("#1e293b")
  const [showColorPicker, setShowColorPicker] = useState(false)

  const quickSizes = [2, 5, 10]
  const [activeSize, setActiveSize] = useState(4)

  // Hardware Apple Pencil palm rejection toggle
  const [drawWithFinger, setDrawWithFinger] = useState(false)

  // Zoom & Pan
  const [zoomLevel, setZoomLevel] = useState(1.0)

  // Side Drawer for Page Thumbnails & Bookmarks filter
  const [showThumbnails, setShowThumbnails] = useState(false)
  const [thumbnailTab, setThumbnailTab] = useState<"all" | "bookmarks">("all")

  // Zen Fullscreen Mode (collapses all sidebars & chrome for maximized writing space)
  const [zenMode, setZenMode] = useState(false)

  // In-progress stroke
  const [currentStroke, setCurrentStroke] = useState<InkStroke | null>(null)
  const strokeStartTimeRef = useRef(0)

  // Lasso Selection & Transformation
  const [lassoPoints, setLassoPoints] = useState<{ x: number; y: number }[]>([])
  const [selectedStrokeIds, setSelectedStrokeIds] = useState<Set<string>>(new Set())
  const [selectedBoxIds, setSelectedBoxIds] = useState<Set<string>>(new Set())
  const [isDraggingSelection, setIsDraggingSelection] = useState(false)
  const dragStartPointRef = useRef<{ x: number; y: number } | null>(null)

  // Undo / Redo history stacks
  const [history, setHistory] = useState<NotebookPage[]>([])
  const [redoStack, setRedoStack] = useState<NotebookPage[]>([])

  // Active editing text box
  const [editingBoxId, setEditingBoxId] = useState<string | null>(null)

  const svgRef = useRef<SVGSVGElement | null>(null)
  const isDrawingRef = useRef(false)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  const currentPage = doc.pages[currentPageIndex] || doc.pages[0]

  // Persist helper
  const commitDoc = useCallback(
    (newDoc: NotebookDocument) => {
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

  // Keyboard Shortcuts (Undo/Redo and Tool Switching)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return

      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "z") {
        e.preventDefault()
        if (e.shiftKey) {
          redo()
        } else {
          undo()
        }
      } else if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "y") {
        e.preventDefault()
        redo()
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
        setShowThumbnails(false)
        setSelectedStrokeIds(new Set())
        setSelectedBoxIds(new Set())
      }
    }
    window.addEventListener("keydown", handleKeyDown)
    return () => window.removeEventListener("keydown", handleKeyDown)
  }, [undo, redo])

  // Coordinate conversion taking into account SVG viewBox and scaling
  const getCanvasPoint = (e: React.PointerEvent<SVGSVGElement>): { x: number; y: number; pressure: number } | null => {
    if (!svgRef.current) return null
    const rect = svgRef.current.getBoundingClientRect()
    const scaleX = currentPage.width / rect.width
    const scaleY = currentPage.height / rect.height

    const x = (e.clientX - rect.left) * scaleX
    const y = (e.clientY - rect.top) * scaleY

    // Apple Pencil real hardware pressure telemetry
    const pressure = e.pointerType === "pen" && e.pressure > 0 ? e.pressure : 0.5
    return { x, y, pressure }
  }

  // Pointer Down
  const handlePointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!editable) return

    // 100% Hardware Palm Rejection: If Apple Pencil mode is active, reject touch drawing
    if (e.pointerType === "touch" && !drawWithFinger) {
      return
    }

    const pt = getCanvasPoint(e)
    if (!pt) return

    svgRef.current?.setPointerCapture(e.pointerId)
    isDrawingRef.current = true
    strokeStartTimeRef.current = Date.now()

    // 1. Eraser Tool
    if (activeTool === "eraser") {
      pushHistory()
      const filtered = currentPage.strokes.filter((s) => {
        if (eraserMode === "highlighterOnly" && s.tool !== "highlighter") return true
        return !isPointNearStroke(pt, s, 16)
      })
      if (filtered.length !== currentPage.strokes.length) {
        const updatedPages = [...doc.pages]
        updatedPages[currentPageIndex] = { ...currentPage, strokes: filtered }
        commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      }
      return
    }

    // 2. Lasso Tool
    if (activeTool === "lasso") {
      // Check if clicking inside active selection to begin drag
      if (selectedStrokeIds.size > 0 || selectedBoxIds.size > 0) {
        const selectedStrokes = currentPage.strokes.filter((s) => selectedStrokeIds.has(s.id))
        const bounds = getStrokesBounds(selectedStrokes)
        if (
          bounds &&
          pt.x >= bounds.minX - 10 &&
          pt.x <= bounds.maxX + 10 &&
          pt.y >= bounds.minY - 10 &&
          pt.y <= bounds.maxY + 10
        ) {
          setIsDraggingSelection(true)
          dragStartPointRef.current = { x: pt.x, y: pt.y }
          pushHistory()
          return
        }
      }

      // Start new lasso loop
      setLassoPoints([{ x: pt.x, y: pt.y }])
      setSelectedStrokeIds(new Set())
      setSelectedBoxIds(new Set())
      return
    }

    // 3. Text Box & Sticky Notes
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
        textBoxes: [...currentPage.textBoxes, newBox],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      setEditingBoxId(newBox.id)
      setActiveTool("fountain")
      return
    }

    // 4. Shape Tool
    if (activeTool === "shape") {
      const newStroke: InkStroke = {
        id: `shape_${Date.now()}`,
        tool: "shape",
        shapeType: shapeToolPrimitive,
        color: activeColor,
        size: activeSize,
        points: [
          { x: pt.x, y: pt.y, pressure: 0.5, time: Date.now() },
          { x: pt.x, y: pt.y, pressure: 0.5, time: Date.now() },
        ],
        createdAt: Date.now(),
      }
      setCurrentStroke(newStroke)
      return
    }

    // 5. Standard Drawing (Fountain, Ballpoint, Brush, Highlighter)
    if (
      activeTool !== "fountain" &&
      activeTool !== "ballpoint" &&
      activeTool !== "brush" &&
      activeTool !== "highlighter"
    ) {
      return
    }

    const isHighlighter = activeTool === "highlighter"
    const newStroke: InkStroke = {
      id: `stroke_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
      tool: activeTool,
      color: isHighlighter ? activeColor + "77" : activeColor,
      size: isHighlighter ? Math.max(activeSize * 3, 20) : activeSize,
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
    if (!isDrawingRef.current) return
    if (e.pointerType === "touch" && !drawWithFinger) return

    const pt = getCanvasPoint(e)
    if (!pt) return

    // Dragging Lasso Selection
    if (isDraggingSelection && dragStartPointRef.current) {
      const dx = pt.x - dragStartPointRef.current.x
      const dy = pt.y - dragStartPointRef.current.y
      dragStartPointRef.current = { x: pt.x, y: pt.y }

      const updatedStrokes = currentPage.strokes.map((s) =>
        selectedStrokeIds.has(s.id) ? translateStroke(s, dx, dy) : s
      )
      const updatedBoxes = currentPage.textBoxes.map((b) =>
        selectedBoxIds.has(b.id) ? { ...b, x: b.x + dx, y: b.y + dy } : b
      )

      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        strokes: updatedStrokes,
        textBoxes: updatedBoxes,
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      return
    }

    // Eraser Tool Drag
    if (activeTool === "eraser") {
      const filtered = currentPage.strokes.filter((s) => {
        if (eraserMode === "highlighterOnly" && s.tool !== "highlighter") return true
        return !isPointNearStroke(pt, s, 16)
      })
      if (filtered.length !== currentPage.strokes.length) {
        const updatedPages = [...doc.pages]
        updatedPages[currentPageIndex] = { ...currentPage, strokes: filtered }
        commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      }
      return
    }

    // Lasso Freehand Loop
    if (activeTool === "lasso") {
      setLassoPoints((prev) => [...prev, { x: pt.x, y: pt.y }])
      return
    }

    // Shape Tool Drag
    if (activeTool === "shape" && currentStroke) {
      setCurrentStroke((prev) => {
        if (!prev) return null
        return {
          ...prev,
          points: [prev.points[0], { x: pt.x, y: pt.y, pressure: 0.5, time: Date.now() }],
        }
      })
      return
    }

    // Standard Stroke Drawing
    if (currentStroke) {
      setCurrentStroke((prev) => {
        if (!prev) return null
        return {
          ...prev,
          points: [
            ...prev.points,
            {
              x: pt.x,
              y: pt.y,
              pressure: pt.pressure,
              tiltX: e.tiltX,
              tiltY: e.tiltY,
              time: Date.now(),
            },
          ],
        }
      })
    }
  }

  // Pointer Up
  const handlePointerUp = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!isDrawingRef.current) return
    isDrawingRef.current = false
    svgRef.current?.releasePointerCapture(e.pointerId)

    if (isDraggingSelection) {
      setIsDraggingSelection(false)
      dragStartPointRef.current = null
      return
    }

    // Finalize Lasso Selection
    if (activeTool === "lasso") {
      if (lassoPoints.length > 3) {
        const selectedStrokes = new Set<string>()
        const selectedBoxes = new Set<string>()

        for (const stroke of currentPage.strokes) {
          if (isStrokeInLasso(lassoPoints, stroke)) {
            selectedStrokes.add(stroke.id)
          }
        }
        for (const box of currentPage.textBoxes) {
          if (isBoxInLasso(lassoPoints, box)) {
            selectedBoxes.add(box.id)
          }
        }

        setSelectedStrokeIds(selectedStrokes)
        setSelectedBoxIds(selectedBoxes)
      }
      setLassoPoints([])
      return
    }

    // Finalize Stroke
    if (currentStroke && currentStroke.points.length > 0) {
      pushHistory()
      let strokeToCommit = currentStroke

      // Auto-Shape Detection (GoodNotes Draw & Hold)
      if (autoShapeDetection && activeTool !== "shape" && activeTool !== "highlighter") {
        const detected = detectGeometricShape(currentStroke.points)
        if (detected) {
          const first = currentStroke.points[0]
          const last = currentStroke.points[currentStroke.points.length - 1]
          strokeToCommit = {
            ...currentStroke,
            tool: "shape",
            shapeType: detected,
            points: [first, last],
          }
        }
      }

      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        strokes: [...currentPage.strokes, strokeToCommit],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      setCurrentStroke(null)
    }
  }

  // Lasso Actions: Recolor, Duplicate, Delete
  const recolorSelected = (color: string) => {
    pushHistory()
    const updatedStrokes = currentPage.strokes.map((s) =>
      selectedStrokeIds.has(s.id) ? { ...s, color } : s
    )
    const updatedBoxes = currentPage.textBoxes.map((b) =>
      selectedBoxIds.has(b.id) ? { ...b, color } : b
    )
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = {
      ...currentPage,
      strokes: updatedStrokes,
      textBoxes: updatedBoxes,
    }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const duplicateSelected = () => {
    pushHistory()
    const newStrokes: InkStroke[] = []
    for (const s of currentPage.strokes) {
      if (selectedStrokeIds.has(s.id)) {
        newStrokes.push(translateStroke({ ...s, id: `stroke_${Date.now()}_${Math.random().toString(36).slice(2, 6)}` }, 25, 25))
      }
    }
    const newBoxes: InkTextBox[] = []
    for (const b of currentPage.textBoxes) {
      if (selectedBoxIds.has(b.id)) {
        newBoxes.push({ ...b, id: `box_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`, x: b.x + 25, y: b.y + 25 })
      }
    }

    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = {
      ...currentPage,
      strokes: [...currentPage.strokes, ...newStrokes],
      textBoxes: [...currentPage.textBoxes, ...newBoxes],
    }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setSelectedStrokeIds(new Set(newStrokes.map((s) => s.id)))
    setSelectedBoxIds(new Set(newBoxes.map((b) => b.id)))
  }

  const deleteSelected = () => {
    pushHistory()
    const filteredStrokes = currentPage.strokes.filter((s) => !selectedStrokeIds.has(s.id))
    const filteredBoxes = currentPage.textBoxes.filter((b) => !selectedBoxIds.has(b.id))

    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = {
      ...currentPage,
      strokes: filteredStrokes,
      textBoxes: filteredBoxes,
    }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setSelectedStrokeIds(new Set())
    setSelectedBoxIds(new Set())
  }

  // Image Insertion
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (loadEvt) => {
      const url = loadEvt.target?.result as string
      if (!url) return

      pushHistory()
      const newImg: NotebookImage = {
        id: `img_${Date.now()}`,
        url,
        x: 150,
        y: 200,
        width: 350,
        height: 250,
      }

      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        images: [...(currentPage.images || []), newImg],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    }
    reader.readAsDataURL(file)
    e.target.value = ""
  }

  // Page Operations
  const addPage = (afterIndex = currentPageIndex) => {
    pushHistory()
    const newPage = createEmptyPage(doc.pages.length + 1, currentPage.template, currentPage.paperColor || "white")
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
    }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const toggleBookmark = () => {
    pushHistory()
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = { ...currentPage, bookmarked: !currentPage.bookmarked }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const setPageTemplate = (template: PageTemplate) => {
    pushHistory()
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = { ...currentPage, template }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const setPaperColor = (paperColor: PaperColor) => {
    pushHistory()
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = { ...currentPage, paperColor }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  // Background Paper Color
  const getPaperBgColor = () => {
    switch (currentPage.paperColor) {
      case "cream":
        return "#fefae0"
      case "dark":
        return "#1e232a"
      default:
        return "#ffffff"
    }
  }

  // Render Background Grid / Ruled / Cornell Patterns
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
      default:
        return "none"
    }
  }

  // Selected Bounding Box for Lasso Drag
  const selectedStrokes = currentPage.strokes.filter((s) => selectedStrokeIds.has(s.id))
  const selectionBounds = getStrokesBounds(selectedStrokes)

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

      {/* GoodNotes Professional Top Toolbar */}
      {editable && (
        <div className="flex flex-wrap items-center justify-between px-3 py-1.5 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 shadow-sm z-30 gap-y-1">
          {/* Left: Thumbnails, Bookmark, Page Navigation & Undo/Redo */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => setShowThumbnails(!showThumbnails)}
              className={`p-1.5 rounded-lg transition-colors ${
                showThumbnails
                  ? "bg-blue-100 text-blue-600 dark:bg-blue-900/50 dark:text-blue-400"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Page Thumbnails & Grid View"
            >
              <Layers className="w-4 h-4" />
            </button>

            <button
              onClick={toggleBookmark}
              className={`p-1.5 rounded-lg transition-colors ${
                currentPage.bookmarked
                  ? "text-amber-500 hover:text-amber-600"
                  : "text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
              }`}
              title={currentPage.bookmarked ? "Bookmarked Page" : "Bookmark this Page"}
            >
              <Star className={`w-4 h-4 ${currentPage.bookmarked ? "fill-amber-400" : ""}`} />
            </button>

            {/* Page Navigation */}
            <div className="flex items-center gap-0.5 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded-md border border-slate-200 dark:border-slate-700 text-xs text-slate-700 dark:text-slate-300">
              <button
                onClick={() => setCurrentPageIndex((prev) => Math.max(0, prev - 1))}
                disabled={currentPageIndex === 0}
                className="p-0.5 disabled:opacity-30 hover:text-blue-500"
                title="Previous Page"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <span className="font-semibold mx-1">
                {currentPageIndex + 1} / {doc.pages.length}
              </span>
              <button
                onClick={() => setCurrentPageIndex((prev) => Math.min(doc.pages.length - 1, prev + 1))}
                disabled={currentPageIndex === doc.pages.length - 1}
                className="p-0.5 disabled:opacity-30 hover:text-blue-500"
                title="Next Page"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Undo / Redo */}
            <button
              onClick={undo}
              disabled={history.length === 0}
              className="p-1.5 text-slate-600 dark:text-slate-400 disabled:opacity-30 hover:bg-slate-100 dark:hover:bg-slate-800 rounded"
              title="Undo (Ctrl+Z)"
            >
              <Undo2 className="w-4 h-4" />
            </button>
            <button
              onClick={redo}
              disabled={redoStack.length === 0}
              className="p-1.5 text-slate-600 dark:text-slate-400 disabled:opacity-30 hover:bg-slate-100 dark:hover:bg-slate-800 rounded"
              title="Redo (Ctrl+Y)"
            >
              <Redo2 className="w-4 h-4" />
            </button>
          </div>

          {/* Center: Primary GoodNotes Toolset */}
          <div className="flex items-center gap-1 bg-slate-100/80 dark:bg-slate-800/80 p-0.5 rounded-xl border border-slate-200/60 dark:border-slate-700/60">
            {/* Fountain Pen */}
            <button
              onClick={() => setActiveTool("fountain")}
              className={`p-1.5 rounded-lg transition-all ${
                activeTool === "fountain"
                  ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm font-semibold scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Fountain Pen (Calligraphic pressure taper)"
            >
              <Pen className="w-4 h-4" />
            </button>

            {/* Ballpoint Pen */}
            <button
              onClick={() => setActiveTool("ballpoint")}
              className={`p-1.5 rounded-lg transition-all ${
                activeTool === "ballpoint"
                  ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm font-semibold scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Ballpoint Pen (Smooth uniform lines)"
            >
              <Minus className="w-4 h-4 stroke-[3]" />
            </button>

            {/* Brush Pen */}
            <button
              onClick={() => setActiveTool("brush")}
              className={`p-1.5 rounded-lg transition-all text-xs font-bold px-2 py-1 ${
                activeTool === "brush"
                  ? "bg-white dark:bg-slate-700 text-purple-600 dark:text-purple-400 shadow-sm scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Brush Pen (Ultra expressive calligraphy)"
            >
              Brush
            </button>

            {/* Highlighter */}
            <button
              onClick={() => setActiveTool("highlighter")}
              className={`p-1.5 rounded-lg transition-all ${
                activeTool === "highlighter"
                  ? "bg-white dark:bg-slate-700 text-amber-500 dark:text-amber-400 shadow-sm font-semibold scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Highlighter (Draws behind text)"
            >
              <Highlighter className="w-4 h-4" />
            </button>

            {/* Eraser with mode toggle */}
            <div className="relative flex items-center">
              <button
                onClick={() => {
                  if (activeTool === "eraser") {
                    setEraserMode((prev) => (prev === "stroke" ? "highlighterOnly" : "stroke"))
                  } else {
                    setActiveTool("eraser")
                  }
                }}
                className={`p-1.5 rounded-lg transition-all ${
                  activeTool === "eraser"
                    ? "bg-white dark:bg-slate-700 text-rose-500 dark:text-rose-400 shadow-sm font-semibold scale-105"
                    : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
                }`}
                title={
                  activeTool === "eraser"
                    ? `Eraser Mode: ${eraserMode === "stroke" ? "Entire Stroke (Click to switch to Highlighter Only)" : "Highlighter Only"}`
                    : "Eraser"
                }
              >
                <Eraser className="w-4 h-4" />
              </button>
              {activeTool === "eraser" && eraserMode === "highlighterOnly" && (
                <span className="absolute -top-1 -right-1 px-1 bg-amber-500 text-white text-[9px] font-bold rounded-full">
                  HL
                </span>
              )}
            </div>

            {/* Lasso Tool */}
            <button
              onClick={() => setActiveTool("lasso")}
              className={`p-1.5 rounded-lg transition-all ${
                activeTool === "lasso"
                  ? "bg-white dark:bg-slate-700 text-indigo-600 dark:text-indigo-400 shadow-sm font-semibold scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Lasso Selection (Move, recolor, duplicate, delete)"
            >
              <Lasso className="w-4 h-4" />
            </button>

            {/* Shape Tool with sub-types */}
            <div className="flex items-center gap-0.5">
              <button
                onClick={() => setActiveTool("shape")}
                className={`p-1.5 rounded-lg transition-all ${
                  activeTool === "shape"
                    ? "bg-white dark:bg-slate-700 text-emerald-600 dark:text-emerald-400 shadow-sm font-semibold scale-105"
                    : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
                }`}
                title="Shape Tool (Geometric Primitives)"
              >
                {shapeToolPrimitive === "rect" && <Square className="w-4 h-4" />}
                {shapeToolPrimitive === "ellipse" && <Circle className="w-4 h-4" />}
                {shapeToolPrimitive === "line" && <Minus className="w-4 h-4" />}
                {shapeToolPrimitive === "arrow" && <ArrowUpRight className="w-4 h-4" />}
              </button>
              {activeTool === "shape" && (
                <select
                  value={shapeToolPrimitive}
                  onChange={(e) => setShapeToolPrimitive(e.target.value as ShapePrimitive)}
                  className="text-[11px] bg-white dark:bg-slate-700 border-none rounded py-0.5 px-1 text-slate-700 dark:text-slate-200 outline-none"
                >
                  <option value="rect">Box</option>
                  <option value="ellipse">Circle</option>
                  <option value="line">Line</option>
                  <option value="arrow">Arrow</option>
                  <option value="triangle">Triangle</option>
                </select>
              )}
            </div>

            {/* Text Box */}
            <button
              onClick={() => setActiveTool("textbox")}
              className={`p-1.5 rounded-lg transition-all ${
                activeTool === "textbox"
                  ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Text Box (Click anywhere to type)"
            >
              <Type className="w-4 h-4" />
            </button>

            {/* Sticky Notes */}
            <button
              onClick={() => setActiveTool("stickynote")}
              className={`p-1.5 rounded-lg transition-all ${
                activeTool === "stickynote"
                  ? "bg-white dark:bg-slate-700 text-amber-500 dark:text-amber-400 shadow-sm scale-105"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900"
              }`}
              title="Sticky Note"
            >
              <StickyNote className="w-4 h-4" />
            </button>

            {/* Insert Image */}
            <button
              onClick={() => fileInputRef.current?.click()}
              className="p-1.5 text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white rounded-lg transition-colors"
              title="Insert Image / Diagram"
            >
              <ImageIcon className="w-4 h-4" />
            </button>
          </div>

          {/* Right: GoodNotes Quick-Colors, Quick-Sizes, Palm Rejection & Templates */}
          <div className="flex items-center gap-2">
            {/* 3 Quick Color Slots */}
            <div className="flex items-center gap-1.5 bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded-full border border-slate-200 dark:border-slate-700">
              {quickColors.map((c, i) => (
                <button
                  key={i}
                  onClick={() => {
                    setActiveColor(c)
                    if (activeColor === c) {
                      setShowColorPicker(!showColorPicker)
                    }
                  }}
                  className={`w-5 h-5 rounded-full border-2 transition-transform ${
                    activeColor === c ? "scale-125 border-blue-500 shadow-md ring-2 ring-blue-300/50" : "border-white dark:border-slate-700"
                  }`}
                  style={{ backgroundColor: c }}
                  title={`Quick Color ${i + 1} (Tap again to customize)`}
                />
              ))}
            </div>

            {/* Color Palette Popover */}
            {showColorPicker && (
              <div className="absolute top-12 right-64 bg-white dark:bg-[#1a1d24] p-2.5 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 flex flex-col gap-2 z-50">
                <div className="text-[11px] font-semibold text-slate-500">Pick Active Color</div>
                <div className="grid grid-cols-5 gap-1.5">
                  {PRESET_COLORS.map((c) => (
                    <button
                      key={c}
                      onClick={() => {
                        setActiveColor(c)
                        const updated = [...quickColors]
                        const idx = updated.indexOf(activeColor)
                        if (idx >= 0) updated[idx] = c
                        else updated[0] = c
                        setQuickColors(updated)
                        setShowColorPicker(false)
                      }}
                      className="w-6 h-6 rounded-full border border-slate-300 hover:scale-110 transition-transform"
                      style={{ backgroundColor: c }}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* 3 Quick Sizes */}
            <div className="flex items-center gap-1 bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded-full border border-slate-200 dark:border-slate-700">
              {quickSizes.map((s, i) => (
                <button
                  key={i}
                  onClick={() => setActiveSize(s)}
                  className={`w-6 h-6 flex items-center justify-center rounded-full transition-colors ${
                    activeSize === s ? "bg-white dark:bg-slate-700 shadow-sm" : "hover:bg-slate-200 dark:hover:bg-slate-700/50"
                  }`}
                  title={`Size preset: ${s}px`}
                >
                  <div
                    className="rounded-full bg-slate-800 dark:bg-slate-200"
                    style={{ width: Math.min(s + 2, 14), height: Math.min(s + 2, 14) }}
                  />
                </button>
              ))}
            </div>

            {/* Hardware Palm Rejection Toggle */}
            <button
              onClick={() => setDrawWithFinger(!drawWithFinger)}
              className={`flex items-center gap-1 px-2.5 py-1 text-xs rounded-full font-medium transition-all ${
                drawWithFinger
                  ? "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300 border border-amber-300"
                  : "bg-blue-50 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300 border border-blue-200 dark:border-blue-800"
              }`}
              title={
                drawWithFinger
                  ? "Draw with Finger enabled"
                  : "Apple Pencil Only (Touches scroll/pan, 100% palm rejection)"
              }
            >
              <Hand className="w-3.5 h-3.5" />
              <span>{drawWithFinger ? "Draw with Finger" : "Pencil Only"}</span>
            </button>

            {/* Auto-Shape Toggle */}
            <button
              onClick={() => setAutoShapeDetection(!autoShapeDetection)}
              className={`px-2 py-1 text-[11px] rounded-md font-semibold transition-colors ${
                autoShapeDetection
                  ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300"
                  : "text-slate-400 hover:text-slate-600"
              }`}
              title="Auto-Shape Recognition: Draw a line/circle/box and hold to snap"
            >
              Auto-Shape
            </button>

            {/* Zoom Controls */}
            <div className="flex items-center gap-0.5 text-slate-600 dark:text-slate-300">
              <button
                onClick={() => setZoomLevel((z) => Math.max(0.6, z - 0.15))}
                className="p-1 hover:bg-slate-200 dark:hover:bg-slate-800 rounded"
                title="Zoom Out"
              >
                <ZoomOut className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => setZoomLevel(1.0)}
                className="text-[11px] font-semibold px-1 py-0.5 hover:bg-slate-200 dark:hover:bg-slate-800 rounded"
                title="Reset Zoom to 100%"
              >
                {Math.round(zoomLevel * 100)}%
              </button>
              <button
                onClick={() => setZoomLevel((z) => Math.min(2.0, z + 0.15))}
                className="p-1 hover:bg-slate-200 dark:hover:bg-slate-800 rounded"
                title="Zoom In"
              >
                <ZoomIn className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Page Template & Paper Color */}
            <select
              value={currentPage.template}
              onChange={(e) => setPageTemplate(e.target.value as PageTemplate)}
              className="text-xs bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg px-2 py-1 text-slate-700 dark:text-slate-300 outline-none"
              title="Page Template"
            >
              <option value="ruled">Ruled (Standard)</option>
              <option value="ruled-wide">Ruled (Wide)</option>
              <option value="grid">Grid (Math)</option>
              <option value="dotted">Dotted (Journal)</option>
              <option value="cornell">Cornell Notes</option>
              <option value="blank">Blank Paper</option>
            </select>

            <select
              value={currentPage.paperColor || "white"}
              onChange={(e) => setPaperColor(e.target.value as PaperColor)}
              className="text-xs bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded-lg px-2 py-1 text-slate-700 dark:text-slate-300 outline-none"
              title="Paper Tone"
            >
              <option value="white">White</option>
              <option value="cream">Cream</option>
              <option value="dark">Dark Slate</option>
            </select>

            {/* Add Page Button */}
            <button
              onClick={() => addPage(currentPageIndex)}
              className="flex items-center gap-1 px-2 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg shadow-sm"
              title="Add Page After"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Add Page</span>
            </button>

            {/* Export SVG */}
            <button
              onClick={exportPageSvg}
              className="p-1.5 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800 rounded-lg transition-colors"
              title="Export Page as Vector SVG"
            >
              <Download className="w-4 h-4" />
            </button>

            {/* Clear Page */}
            <button
              onClick={clearCurrentPage}
              className="p-1.5 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-lg transition-colors"
              title="Clear Current Page"
            >
              <Trash2 className="w-4 h-4" />
            </button>

            {/* Zen Fullscreen Mode Toggle */}
            <button
              onClick={() => setZenMode(!zenMode)}
              className={`p-1.5 rounded-lg transition-colors ${
                zenMode
                  ? "bg-blue-600 text-white shadow-sm"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800"
              }`}
              title={zenMode ? "Exit Fullscreen (Esc)" : "Zen Fullscreen Mode (Hide Sidebars)"}
            >
              {zenMode ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
            </button>
          </div>
        </div>
      )}

      {/* Main Workspace Area with Optional Side Thumbnails Drawer */}
      <div className="flex-1 flex overflow-hidden relative">
        {/* GoodNotes Page Thumbnails Drawer */}
        {showThumbnails && (
          <div className="w-64 bg-white dark:bg-[#181b22] border-r border-slate-200 dark:border-slate-800 flex flex-col z-20 shadow-lg">
            <div className="flex items-center justify-between p-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-3">
                <button
                  onClick={() => setThumbnailTab("all")}
                  className={`text-xs font-bold pb-0.5 border-b-2 transition-colors ${
                    thumbnailTab === "all"
                      ? "border-blue-600 text-blue-600 dark:text-blue-400"
                      : "border-transparent text-slate-500 hover:text-slate-700"
                  }`}
                >
                  Pages ({doc.pages.length})
                </button>
                <button
                  onClick={() => setThumbnailTab("bookmarks")}
                  className={`text-xs font-bold pb-0.5 border-b-2 transition-colors ${
                    thumbnailTab === "bookmarks"
                      ? "border-amber-500 text-amber-600 dark:text-amber-400"
                      : "border-transparent text-slate-500 hover:text-slate-700"
                  }`}
                >
                  Favorites ({doc.pages.filter((p) => p.bookmarked).length})
                </button>
              </div>
              <button
                onClick={() => setShowThumbnails(false)}
                className="p-1 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-3 flex flex-col gap-3">
              {doc.pages
                .map((p, idx) => ({ page: p, idx }))
                .filter(({ page }) => (thumbnailTab === "bookmarks" ? page.bookmarked : true))
                .map(({ page: p, idx }) => (
                <div
                  key={p.id}
                  onClick={() => setCurrentPageIndex(idx)}
                  className={`group relative flex flex-col items-center p-2 rounded-lg cursor-pointer border transition-all ${
                    idx === currentPageIndex
                      ? "border-blue-500 bg-blue-50/50 dark:bg-blue-950/30 shadow-md ring-2 ring-blue-400/30"
                      : "border-slate-200 dark:border-slate-700 hover:border-slate-300 bg-slate-50 dark:bg-slate-800/40"
                  }`}
                >
                  <div
                    className="w-full h-32 bg-white rounded shadow-sm border border-slate-200 overflow-hidden relative flex items-center justify-center"
                    style={{ backgroundColor: p.paperColor === "dark" ? "#1e232a" : p.paperColor === "cream" ? "#fefae0" : "#ffffff" }}
                  >
                    <span className="text-[10px] text-slate-400 font-mono">
                      {p.strokes.length} strokes • {p.template}
                    </span>
                    {p.bookmarked && (
                      <Star className="absolute top-1 right-1 w-3.5 h-3.5 fill-amber-400 text-amber-500" />
                    )}
                  </div>
                  <div className="flex items-center justify-between w-full mt-1.5 px-1 text-xs text-slate-600 dark:text-slate-400">
                    <span className="font-semibold">Page {idx + 1}</span>
                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          duplicatePage(idx)
                        }}
                        className="p-0.5 hover:text-blue-500"
                        title="Duplicate Page"
                      >
                        <Copy className="w-3 h-3" />
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          addPage(idx)
                        }}
                        className="p-0.5 hover:text-blue-500"
                        title="Add Page After"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          deletePage(idx)
                        }}
                        disabled={doc.pages.length <= 1}
                        className="p-0.5 hover:text-rose-500 disabled:opacity-20"
                        title="Delete Page"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
              {thumbnailTab === "bookmarks" && doc.pages.filter((p) => p.bookmarked).length === 0 && (
                <div className="text-center text-xs text-slate-400 py-12 flex flex-col items-center gap-2 px-4">
                  <Star className="w-6 h-6 text-slate-300 stroke-[1.5]" />
                  <span>No favorites yet. Tap the star in the toolbar to bookmark pages.</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Scrollable Canvas Viewport */}
        <div className="flex-1 overflow-auto flex items-center justify-center p-8 touch-pan-x touch-pan-y relative">
          {/* Lasso Floating Action Menu */}
          {(selectedStrokeIds.size > 0 || selectedBoxIds.size > 0) && selectionBounds && (
            <div
              className="absolute z-40 bg-white dark:bg-[#1a1d24] px-3 py-1.5 rounded-full shadow-2xl border border-slate-200 dark:border-slate-700 flex items-center gap-2 transform -translate-y-12 animate-in fade-in"
              style={{
                left: `${selectionBounds.minX * zoomLevel + 60}px`,
                top: `${selectionBounds.minY * zoomLevel + 20}px`,
              }}
            >
              <span className="text-xs font-semibold text-slate-700 dark:text-slate-200">
                {selectedStrokeIds.size + selectedBoxIds.size} Selected
              </span>
              <div className="h-3 w-px bg-slate-300 dark:bg-slate-700" />
              <button
                onClick={duplicateSelected}
                className="flex items-center gap-1 text-xs text-blue-600 dark:text-blue-400 font-semibold hover:underline"
              >
                <Copy className="w-3.5 h-3.5" />
                <span>Duplicate</span>
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
                className="p-1 text-rose-600 dark:text-rose-400 hover:bg-rose-50 rounded"
                title="Delete Selection"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => {
                  setSelectedStrokeIds(new Set())
                  setSelectedBoxIds(new Set())
                }}
                className="p-1 text-slate-400 hover:text-slate-600"
                title="Deselect"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          )}

          {/* Scaled Notebook Page Container */}
          <div
            className="relative shadow-2xl rounded-sm transition-transform duration-75 border border-slate-200 dark:border-slate-700"
            style={{
              width: currentPage.width * zoomLevel,
              height: currentPage.height * zoomLevel,
              backgroundColor: getPaperBgColor(),
            }}
          >
            {/* SVG Vector Drawing Layer */}
            <svg
              ref={svgRef}
              viewBox={`0 0 ${currentPage.width} ${currentPage.height}`}
              className="absolute inset-0 w-full h-full cursor-crosshair touch-none"
              onPointerDown={handlePointerDown}
              onPointerMove={handlePointerMove}
              onPointerUp={handlePointerUp}
              onPointerCancel={handlePointerUp}
            >
              <defs>{renderBackgroundPattern()}</defs>

              {/* Page Background Pattern */}
              <rect
                width={currentPage.width}
                height={currentPage.height}
                fill={getBackgroundFill()}
                className="pointer-events-none"
              />

              {/* Cornell Notes Structural Layout Lines */}
              {currentPage.template === "cornell" && (
                <g stroke="#94a3b8" strokeWidth="1.5" className="pointer-events-none">
                  {/* Top Cue/Header divider */}
                  <line x1="0" y1="120" x2={currentPage.width} y2="120" />
                  {/* Left Cue Column divider */}
                  <line x1="220" y1="120" x2="220" y2={currentPage.height - 180} />
                  {/* Bottom Summary block divider */}
                  <line x1="0" y1={currentPage.height - 180} x2={currentPage.width} y2={currentPage.height - 180} />
                </g>
              )}

              {/* LAYER 1: Inserted Images */}
              {currentPage.images?.map((img) => (
                <image
                  key={img.id}
                  href={img.url}
                  x={img.x}
                  y={img.y}
                  width={img.width}
                  height={img.height}
                  preserveAspectRatio="xMidYMid meet"
                  className="pointer-events-none"
                />
              ))}

              {/* LAYER 2: Highlighters (Rendered under pen strokes with multiply blend) */}
              {highlighterStrokes.map((stroke) => {
                const isSelected = selectedStrokeIds.has(stroke.id)
                const pathD = renderStrokeToPath(stroke)
                return (
                  <path
                    key={stroke.id}
                    d={pathD}
                    fill={stroke.color}
                    className="mix-blend-multiply"
                    style={{
                      filter: isSelected ? "drop-shadow(0 0 6px #3b82f6)" : undefined,
                    }}
                  />
                )
              })}

              {/* LAYER 3: Dark Ink Pen Strokes (Fountain, Ballpoint, Brush, Shapes) */}
              {penStrokes.map((stroke) => {
                const isSelected = selectedStrokeIds.has(stroke.id)
                const pathD = renderStrokeToPath(stroke)
                const isShape = stroke.tool === "shape"

                return (
                  <path
                    key={stroke.id}
                    d={pathD}
                    fill={isShape ? stroke.fill || "none" : stroke.color}
                    stroke={isShape ? stroke.color : undefined}
                    strokeWidth={isShape ? stroke.size : undefined}
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    style={{
                      filter: isSelected ? "drop-shadow(0 0 6px #3b82f6)" : undefined,
                    }}
                  />
                )
              })}

              {/* Active In-Progress Stroke */}
              {currentStroke && (
                <path
                  d={renderStrokeToPath(currentStroke)}
                  fill={currentStroke.tool === "shape" ? "none" : currentStroke.color}
                  stroke={currentStroke.tool === "shape" ? currentStroke.color : undefined}
                  strokeWidth={currentStroke.tool === "shape" ? currentStroke.size : undefined}
                  className={currentStroke.tool === "highlighter" ? "mix-blend-multiply" : ""}
                />
              )}

              {/* Lasso Selection Loop */}
              {lassoPoints.length > 1 && (
                <polyline
                  points={lassoPoints.map((p) => `${p.x},${p.y}`).join(" ")}
                  fill="none"
                  stroke="#3b82f6"
                  strokeWidth="2"
                  strokeDasharray="5 5"
                />
              )}

              {/* Lasso Selection Bounding Box */}
              {selectionBounds && selectedStrokeIds.size > 0 && (
                <rect
                  x={selectionBounds.minX - 6}
                  y={selectionBounds.minY - 6}
                  width={selectionBounds.maxX - selectionBounds.minX + 12}
                  height={selectionBounds.maxY - selectionBounds.minY + 12}
                  fill="rgba(59, 130, 246, 0.08)"
                  stroke="#3b82f6"
                  strokeWidth="1.5"
                  strokeDasharray="4 4"
                  rx="4"
                  className="cursor-move"
                />
              )}
            </svg>

            {/* LAYER 4: Re-editable Floating Text Boxes & Sticky Notes */}
            {currentPage.textBoxes.map((box) => {
              const isEditing = editingBoxId === box.id
              const isSelected = selectedBoxIds.has(box.id)

              return (
                <div
                  key={box.id}
                  className={`absolute rounded-md p-2 transition-all select-text ${
                    box.isStickyNote
                      ? "shadow-lg border"
                      : "border border-dashed border-transparent hover:border-slate-300"
                  } ${isSelected ? "ring-2 ring-blue-500 shadow-xl" : ""}`}
                  style={{
                    left: box.x * zoomLevel,
                    top: box.y * zoomLevel,
                    width: box.width * zoomLevel,
                    minHeight: box.height * zoomLevel,
                    backgroundColor: box.backgroundColor || "transparent",
                    color: box.color,
                    fontSize: `${box.fontSize * zoomLevel}px`,
                    fontWeight: box.bold ? "bold" : "normal",
                    fontStyle: box.italic ? "italic" : "normal",
                  }}
                  onDoubleClick={() => setEditingBoxId(box.id)}
                >
                  {isEditing ? (
                    <div className="flex flex-col gap-1 w-full h-full">
                      {/* Rich Text Format Bar */}
                      <div className="flex items-center gap-1 bg-white dark:bg-slate-800 p-1 rounded shadow border border-slate-200 dark:border-slate-700 text-xs">
                        <button
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, bold: !b.bold } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className={`px-1.5 py-0.5 rounded font-bold ${box.bold ? "bg-slate-200 dark:bg-slate-700" : ""}`}
                        >
                          B
                        </button>
                        <button
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, italic: !b.italic } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className={`px-1.5 py-0.5 rounded italic ${box.italic ? "bg-slate-200 dark:bg-slate-700" : ""}`}
                        >
                          I
                        </button>
                        <button
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, fontSize: Math.max(10, b.fontSize - 2) } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="px-1 text-slate-600 hover:bg-slate-100 rounded"
                        >
                          A-
                        </button>
                        <button
                          onClick={() => {
                            const updated = currentPage.textBoxes.map((b) =>
                              b.id === box.id ? { ...b, fontSize: Math.min(48, b.fontSize + 2) } : b
                            )
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: updated }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="px-1 text-slate-600 hover:bg-slate-100 rounded"
                        >
                          A+
                        </button>
                        <button
                          onClick={() => {
                            const filtered = currentPage.textBoxes.filter((b) => b.id !== box.id)
                            const updatedPages = [...doc.pages]
                            updatedPages[currentPageIndex] = { ...currentPage, textBoxes: filtered }
                            commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
                          }}
                          className="p-1 text-rose-500 hover:bg-rose-50 rounded ml-auto"
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      </div>

                      <textarea
                        autoFocus
                        defaultValue={box.text}
                        className="w-full h-full bg-transparent resize-none border-none outline-none font-sans"
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
                      className="w-full h-full whitespace-pre-wrap cursor-pointer"
                      title="Double-click to edit text"
                    >
                      {box.text}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        </div>
      </div>
    </div>
  )
}
