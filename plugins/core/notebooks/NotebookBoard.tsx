import { useState, useRef, useCallback } from "react"
import {
  Pen,
  Highlighter,
  Eraser,
  Lasso,
  Type,
  StickyNote,
  ChevronLeft,
  ChevronRight,
  Plus,
  Copy,
  Trash2,
  Undo2,
  Redo2,
  Hand,
} from "lucide-react"
import {
  type NotebookDocument,
  type NotebookPage,
  type InkStroke,
  type InkTextBox,
  type PageTemplate,
  createEmptyNotebook,
  createEmptyPage,
} from "./types"
import { renderStrokeToPath, isPointNearStroke, isStrokeInLasso } from "./stroke"

interface NotebookBoardProps {
  text: string
  path?: string
  editable?: boolean
  place?: string
  onChange?: (newText: string) => void
}

const COLORS = [
  "#1e293b", // Slate Black
  "#2563eb", // Royal Blue
  "#059669", // Emerald Green
  "#dc2626", // Crimson Red
  "#7c3aed", // Royal Purple
  "#d97706", // Amber
  "#0891b2", // Teal
  "#db2777", // Rose Pink
]

const SIZES = [2, 4, 8, 16]

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
  const [activeTool, setActiveTool] = useState<"pen" | "fountain" | "highlighter" | "eraser" | "lasso" | "textbox" | "stickynote">("fountain")
  const [activeColor, setActiveColor] = useState(COLORS[0])
  const [activeSize, setActiveSize] = useState(SIZES[1])
  const [drawWithFinger, setDrawWithFinger] = useState(false)

  // In-progress stroke
  const [currentStroke, setCurrentStroke] = useState<InkStroke | null>(null)
  const [lassoPoints, setLassoPoints] = useState<{ x: number; y: number }[]>([])
  const [selectedStrokeIds, setSelectedStrokeIds] = useState<Set<string>>(new Set())

  // Undo / Redo history stacks
  const [history, setHistory] = useState<NotebookPage[]>([])
  const [redoStack, setRedoStack] = useState<NotebookPage[]>([])

  // Active editing text box
  const [editingBoxId, setEditingBoxId] = useState<string | null>(null)

  const svgRef = useRef<SVGSVGElement | null>(null)
  const isDrawingRef = useRef(false)

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

  const undo = () => {
    if (history.length === 0) return
    const prevPage = history[history.length - 1]
    const updatedHistory = history.slice(0, -1)

    setRedoStack((prev) => [JSON.parse(JSON.stringify(currentPage)), ...prev])
    setHistory(updatedHistory)

    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = prevPage
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  const redo = () => {
    if (redoStack.length === 0) return
    const next = redoStack[0]
    setRedoStack((prev) => prev.slice(1))
    setHistory((prev) => [...prev, JSON.parse(JSON.stringify(currentPage))])

    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = next
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  // Pointer event handlers with hardware Apple Pencil vs Finger touch differentiation
  const getCanvasPoint = (e: React.PointerEvent<SVGSVGElement>): { x: number; y: number; pressure: number } | null => {
    if (!svgRef.current) return null
    const rect = svgRef.current.getBoundingClientRect()
    const scaleX = currentPage.width / rect.width
    const scaleY = currentPage.height / rect.height

    const x = (e.clientX - rect.left) * scaleX
    const y = (e.clientY - rect.top) * scaleY

    // Stylus pressure telemetry
    const pressure = e.pointerType === "pen" && e.pressure > 0 ? e.pressure : 0.5
    return { x, y, pressure }
  }

  const handlePointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!editable) return

    // Hardware Palm Rejection & Draw with Finger Guard
    if (e.pointerType === "touch" && !drawWithFinger) {
      // Touch is reserved for panning/scrolling; ignore drawing
      return
    }

    const pt = getCanvasPoint(e)
    if (!pt) return

    svgRef.current?.setPointerCapture(e.pointerId)
    isDrawingRef.current = true

    if (activeTool === "eraser") {
      pushHistory()
      const filtered = currentPage.strokes.filter((s) => !isPointNearStroke(pt, s, 14))
      if (filtered.length !== currentPage.strokes.length) {
        const updatedPages = [...doc.pages]
        updatedPages[currentPageIndex] = { ...currentPage, strokes: filtered }
        commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      }
      return
    }

    if (activeTool === "lasso") {
      setLassoPoints([{ x: pt.x, y: pt.y }])
      setSelectedStrokeIds(new Set())
      return
    }

    if (activeTool === "textbox" || activeTool === "stickynote") {
      pushHistory()
      const isSticky = activeTool === "stickynote"
      const newBox: InkTextBox = {
        id: `box_${Date.now()}`,
        x: pt.x,
        y: pt.y,
        width: isSticky ? 180 : 220,
        height: isSticky ? 140 : 60,
        text: isSticky ? "Sticky Note..." : "Double-click to type...",
        fontSize: isSticky ? 14 : 16,
        color: isSticky ? "#78350f" : activeColor,
        backgroundColor: isSticky ? "#fef3c7" : "transparent",
        isStickyNote: isSticky,
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

    // New Stroke
    const newStroke: InkStroke = {
      id: `stroke_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
      tool: activeTool,
      color: activeTool === "highlighter" ? activeColor + "88" : activeColor,
      size: activeTool === "highlighter" ? Math.max(activeSize * 2.5, 16) : activeSize,
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

  const handlePointerMove = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!isDrawingRef.current) return
    if (e.pointerType === "touch" && !drawWithFinger) return

    const pt = getCanvasPoint(e)
    if (!pt) return

    if (activeTool === "eraser") {
      const filtered = currentPage.strokes.filter((s) => !isPointNearStroke(pt, s, 14))
      if (filtered.length !== currentPage.strokes.length) {
        const updatedPages = [...doc.pages]
        updatedPages[currentPageIndex] = { ...currentPage, strokes: filtered }
        commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      }
      return
    }

    if (activeTool === "lasso") {
      setLassoPoints((prev) => [...prev, { x: pt.x, y: pt.y }])
      return
    }

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

  const handlePointerUp = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!isDrawingRef.current) return
    isDrawingRef.current = false
    svgRef.current?.releasePointerCapture(e.pointerId)

    if (activeTool === "lasso") {
      if (lassoPoints.length > 3) {
        const selected = new Set<string>()
        for (const stroke of currentPage.strokes) {
          if (isStrokeInLasso(lassoPoints, stroke)) {
            selected.add(stroke.id)
          }
        }
        setSelectedStrokeIds(selected)
      }
      setLassoPoints([])
      return
    }

    if (currentStroke && currentStroke.points.length > 0) {
      pushHistory()
      const updatedPages = [...doc.pages]
      updatedPages[currentPageIndex] = {
        ...currentPage,
        strokes: [...currentPage.strokes, currentStroke],
      }
      commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
      setCurrentStroke(null)
    }
  }

  // Page Operations
  const addPage = () => {
    pushHistory()
    const newPage = createEmptyPage(doc.pages.length + 1, currentPage.template)
    const updatedPages = [...doc.pages, newPage]
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setCurrentPageIndex(updatedPages.length - 1)
  }

  const duplicatePage = () => {
    pushHistory()
    const copy: NotebookPage = {
      ...JSON.parse(JSON.stringify(currentPage)),
      id: `page_${Date.now()}`,
      pageNumber: currentPageIndex + 2,
    }
    const updatedPages = [
      ...doc.pages.slice(0, currentPageIndex + 1),
      copy,
      ...doc.pages.slice(currentPageIndex + 1),
    ].map((p, idx) => ({ ...p, pageNumber: idx + 1 }))

    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setCurrentPageIndex(currentPageIndex + 1)
  }

  const deletePage = () => {
    if (doc.pages.length <= 1) return
    pushHistory()
    const updatedPages = doc.pages
      .filter((_, idx) => idx !== currentPageIndex)
      .map((p, idx) => ({ ...p, pageNumber: idx + 1 }))
    const nextIndex = Math.min(currentPageIndex, updatedPages.length - 1)
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
    setCurrentPageIndex(nextIndex)
  }

  const setPageTemplate = (template: PageTemplate) => {
    pushHistory()
    const updatedPages = [...doc.pages]
    updatedPages[currentPageIndex] = { ...currentPage, template }
    commitDoc({ ...doc, pages: updatedPages, updatedAt: Date.now() })
  }

  // Render Background Grid / Ruled Template
  const renderBackgroundPattern = () => {
    switch (currentPage.template) {
      case "ruled":
        return (
          <pattern id="notebook-ruled" width="100" height="32" patternUnits="userSpaceOnUse">
            <line x1="0" y1="31" x2="100" y2="31" stroke="#cbd5e1" strokeWidth="0.8" />
          </pattern>
        )
      case "grid":
        return (
          <pattern id="notebook-grid" width="24" height="24" patternUnits="userSpaceOnUse">
            <path d="M 24 0 L 0 0 0 24" fill="none" stroke="#e2e8f0" strokeWidth="0.8" />
          </pattern>
        )
      case "dotted":
        return (
          <pattern id="notebook-dotted" width="24" height="24" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1" fill="#94a3b8" />
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
      case "grid":
        return "url(#notebook-grid)"
      case "dotted":
        return "url(#notebook-dotted)"
      default:
        return "none"
    }
  }

  return (
    <div className="relative flex flex-col h-full w-full bg-slate-100 dark:bg-[#121418] select-none overflow-hidden">
      {/* GoodNotes Floating Top Toolbar */}
      {editable && (
        <div className="flex items-center justify-between px-3 py-1.5 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 shadow-sm z-20">
          {/* Tool Palette */}
          <div className="flex items-center gap-1">
            <button
              onClick={() => setActiveTool("fountain")}
              className={`p-1.5 rounded-lg transition-colors ${
                activeTool === "fountain"
                  ? "bg-blue-100 text-blue-600 dark:bg-blue-900/40 dark:text-blue-400 font-semibold"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Fountain Pen (Pressure sensitive)"
            >
              <Pen className="w-4 h-4" />
            </button>

            <button
              onClick={() => setActiveTool("highlighter")}
              className={`p-1.5 rounded-lg transition-colors ${
                activeTool === "highlighter"
                  ? "bg-amber-100 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400 font-semibold"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Highlighter"
            >
              <Highlighter className="w-4 h-4" />
            </button>

            <button
              onClick={() => setActiveTool("eraser")}
              className={`p-1.5 rounded-lg transition-colors ${
                activeTool === "eraser"
                  ? "bg-rose-100 text-rose-600 dark:bg-rose-900/40 dark:text-rose-400 font-semibold"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Vector Stroke Eraser"
            >
              <Eraser className="w-4 h-4" />
            </button>

            <button
              onClick={() => setActiveTool("lasso")}
              className={`p-1.5 rounded-lg transition-colors ${
                activeTool === "lasso"
                  ? "bg-indigo-100 text-indigo-600 dark:bg-indigo-900/40 dark:text-indigo-400 font-semibold"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Lasso Selection Tool"
            >
              <Lasso className="w-4 h-4" />
            </button>

            <div className="h-4 w-px bg-slate-300 dark:bg-slate-700 mx-1" />

            {/* Re-editable Text Box & Sticky Notes */}
            <button
              onClick={() => setActiveTool("textbox")}
              className={`p-1.5 rounded-lg transition-colors ${
                activeTool === "textbox"
                  ? "bg-blue-100 text-blue-600 dark:bg-blue-900/40 dark:text-blue-400"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Text Box (Re-editable anywhere)"
            >
              <Type className="w-4 h-4" />
            </button>

            <button
              onClick={() => setActiveTool("stickynote")}
              className={`p-1.5 rounded-lg transition-colors ${
                activeTool === "stickynote"
                  ? "bg-amber-100 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400"
                  : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
              }`}
              title="Sticky Note (Re-editable)"
            >
              <StickyNote className="w-4 h-4" />
            </button>

            <div className="h-4 w-px bg-slate-300 dark:bg-slate-700 mx-1" />

            {/* Colors */}
            <div className="flex items-center gap-1">
              {COLORS.map((c) => (
                <button
                  key={c}
                  onClick={() => setActiveColor(c)}
                  className={`w-5 h-5 rounded-full border transition-transform ${
                    activeColor === c ? "scale-125 border-blue-500 shadow-sm" : "border-transparent"
                  }`}
                  style={{ backgroundColor: c }}
                  title={`Color: ${c}`}
                />
              ))}
            </div>

            <div className="h-4 w-px bg-slate-300 dark:bg-slate-700 mx-1" />

            {/* Stroke Sizes */}
            <div className="flex items-center gap-1">
              {SIZES.map((s) => (
                <button
                  key={s}
                  onClick={() => setActiveSize(s)}
                  className={`w-6 h-6 flex items-center justify-center rounded transition-colors ${
                    activeSize === s ? "bg-slate-200 dark:bg-slate-700" : "hover:bg-slate-100 dark:hover:bg-slate-800"
                  }`}
                  title={`Size: ${s}px`}
                >
                  <div
                    className="rounded-full bg-slate-800 dark:bg-slate-200"
                    style={{ width: Math.min(s + 2, 14), height: Math.min(s + 2, 14) }}
                  />
                </button>
              ))}
            </div>
          </div>

          {/* Right Controls: Apple Pencil Finger Lock, Templates, Undo/Redo & Page Controls */}
          <div className="flex items-center gap-2">
            {/* Draw with Finger Toggle (Hardware Palm Rejection) */}
            <button
              onClick={() => setDrawWithFinger(!drawWithFinger)}
              className={`flex items-center gap-1 px-2 py-1 text-xs rounded-md transition-colors ${
                drawWithFinger
                  ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300 border border-emerald-300"
                  : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300 border border-slate-300 dark:border-slate-700"
              }`}
              title={
                drawWithFinger
                  ? "Finger Drawing Enabled (Touch draws strokes)"
                  : "Apple Pencil Only (Touches scroll/pan, 100% palm rejection)"
              }
            >
              <Hand className="w-3.5 h-3.5" />
              <span>{drawWithFinger ? "Draw with Finger" : "Pencil Only"}</span>
            </button>

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

            <div className="h-4 w-px bg-slate-300 dark:bg-slate-700 mx-0.5" />

            {/* Template Selector */}
            <select
              value={currentPage.template}
              onChange={(e) => setPageTemplate(e.target.value as PageTemplate)}
              className="text-xs bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 rounded px-1.5 py-1 text-slate-700 dark:text-slate-300"
              title="Page Template"
            >
              <option value="ruled">Ruled</option>
              <option value="grid">Grid</option>
              <option value="dotted">Dotted</option>
              <option value="blank">Blank</option>
            </select>

            {/* Page Navigation */}
            <div className="flex items-center gap-1 bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded border border-slate-200 dark:border-slate-700 text-xs text-slate-700 dark:text-slate-300">
              <button
                onClick={() => setCurrentPageIndex((prev) => Math.max(0, prev - 1))}
                disabled={currentPageIndex === 0}
                className="p-0.5 disabled:opacity-30 hover:text-blue-500"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <span className="font-medium">
                {currentPageIndex + 1} / {doc.pages.length}
              </span>
              <button
                onClick={() => setCurrentPageIndex((prev) => Math.min(doc.pages.length - 1, prev + 1))}
                disabled={currentPageIndex === doc.pages.length - 1}
                className="p-0.5 disabled:opacity-30 hover:text-blue-500"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Page Actions */}
            <button
              onClick={addPage}
              className="p-1.5 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-950/50 rounded"
              title="Add New Page"
            >
              <Plus className="w-4 h-4" />
            </button>
            <button
              onClick={duplicatePage}
              className="p-1.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded"
              title="Duplicate Page"
            >
              <Copy className="w-4 h-4" />
            </button>
            <button
              onClick={deletePage}
              disabled={doc.pages.length <= 1}
              className="p-1.5 text-rose-600 dark:text-rose-400 disabled:opacity-30 hover:bg-rose-50 dark:hover:bg-rose-950/50 rounded"
              title="Delete Page"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Main Canvas Scroll Viewport */}
      <div className="flex-1 overflow-auto flex items-center justify-center p-6 touch-pan-x touch-pan-y">
        <div
          className="relative bg-white shadow-xl rounded-sm transition-shadow border border-slate-200 dark:border-slate-700"
          style={{
            width: currentPage.width,
            height: currentPage.height,
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

            {/* Committed Strokes */}
            {currentPage.strokes.map((stroke) => {
              const isSelected = selectedStrokeIds.has(stroke.id)
              const pathD = renderStrokeToPath(stroke)
              return (
                <path
                  key={stroke.id}
                  d={pathD}
                  fill={stroke.color}
                  className={`transition-opacity ${stroke.tool === "highlighter" ? "mix-blend-multiply" : ""}`}
                  style={{
                    filter: isSelected ? "drop-shadow(0 0 4px #3b82f6)" : undefined,
                  }}
                />
              )
            })}

            {/* Current Active Stroke */}
            {currentStroke && (
              <path
                d={renderStrokeToPath(currentStroke)}
                fill={currentStroke.color}
                className={currentStroke.tool === "highlighter" ? "mix-blend-multiply" : ""}
              />
            )}

            {/* Lasso Selection Path */}
            {lassoPoints.length > 1 && (
              <polyline
                points={lassoPoints.map((p) => `${p.x},${p.y}`).join(" ")}
                fill="none"
                stroke="#3b82f6"
                strokeWidth="1.5"
                strokeDasharray="4 4"
              />
            )}
          </svg>

          {/* Re-editable Text Boxes & Sticky Notes Layer */}
          {currentPage.textBoxes.map((box) => {
            const isEditing = editingBoxId === box.id

            return (
              <div
                key={box.id}
                className={`absolute rounded p-2 transition-shadow select-text ${
                  box.isStickyNote ? "shadow-md border border-amber-300" : "border border-dashed border-transparent hover:border-slate-300"
                }`}
                style={{
                  left: box.x,
                  top: box.y,
                  width: box.width,
                  minHeight: box.height,
                  backgroundColor: box.backgroundColor || "transparent",
                  color: box.color,
                  fontSize: `${box.fontSize}px`,
                }}
                onDoubleClick={() => setEditingBoxId(box.id)}
              >
                {isEditing ? (
                  <textarea
                    autoFocus
                    defaultValue={box.text}
                    className="w-full h-full bg-transparent resize-none border-none outline-none font-sans"
                    style={{ fontSize: `${box.fontSize}px`, color: box.color }}
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
                ) : (
                  <div
                    className="w-full h-full whitespace-pre-wrap font-sans cursor-pointer"
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
  )
}
