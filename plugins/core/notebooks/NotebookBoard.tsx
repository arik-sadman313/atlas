import React, { useState, useRef, useCallback, useEffect } from "react"
import { useZoomTarget } from "@vaultite"
import "@excalidraw/excalidraw/index.css"
import type { ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import { DocumentNavigationDrawer } from "./DocumentNavigationDrawer"
import { GoodNotesToolbar } from "./GoodNotesToolbar"
import { GoodNotesPaperSettings } from "./GoodNotesPaperSettings"
import { GoodNotesDeskSheet } from "./GoodNotesDeskSheet"
import { useNotebookDocument } from "./useNotebookDocument"
import {
  applyToolToScene, applySceneZoom, updateSelectedColor, updateSelectedWidth, triggerShortcutsHelp
} from "./notebookActions"
import {
  exportSceneToPng, exportSceneToSvg, copySceneToClipboard
} from "./notebookExport"

declare global {
  interface Window {
    __excalidrawAPI?: ExcalidrawImperativeAPI
  }
}

export interface NotebookBoardProps {
  text: string
  path?: string
  editable?: boolean
  place?: string
  onChange?: (newText: string) => void
}

export const NotebookBoard: React.FC<NotebookBoardProps> = ({
  text,
  editable = true,
  onChange,
}) => {
  const {
    doc, setDoc, docRef, currentPageIndex, currentPage, switchPage,
    addPage, duplicatePage, deletePage, setPaperTemplate, setPaperColor,
    updatePageData, saveCurrentScene,
  } = useNotebookDocument({ text, onChange })

  const [activeTool, setActiveTool] = useState<string>("pen")
  const [color, setColor] = useState<string>("#1e293b")
  const [strokeWidth, setStrokeWidth] = useState<number>(1.5)
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false)
  const [isPaperSettingsOpen, setIsPaperSettingsOpen] = useState<boolean>(false)
  const [isLibraryOpen, setIsLibraryOpen] = useState<boolean>(false)
  const [gridMode, setGridMode] = useState<boolean>(false)
  const [snapToObjects, setSnapToObjects] = useState<boolean>(true)
  const [zoom, setZoom] = useState<number>(1)
  const [readOnly, setReadOnly] = useState<boolean>(!editable)
  const [hasSelectedElements, setHasSelectedElements] = useState<boolean>(false)
  const excalidrawAPIRef = useRef<ExcalidrawImperativeAPI | null>(null)
  const containerRef = useRef<HTMLDivElement | null>(null)
  const deskRef = useRef<HTMLDivElement | null>(null)
  const sheetRef = useRef<HTMLDivElement | null>(null)

  const updatePanelPosition = useCallback(() => {
    const root = containerRef.current
    const sheet = sheetRef.current
    if (!root || !sheet) return
    const rootRect = root.getBoundingClientRect()
    const sheetRect = sheet.getBoundingClientRect()
    const idealLeft = sheetRect.left - rootRect.left - 215
    const safeLeft = Math.max(16, idealLeft)
    const top = Math.max(60, sheetRect.top - rootRect.top)
    root.style.setProperty("--desk-panel-left", `${Math.round(rootRect.left + safeLeft)}px`)
    root.style.setProperty("--desk-panel-top", `${Math.round(rootRect.top + top)}px`)
  }, [])

  useEffect(() => {
    updatePanelPosition()
    window.addEventListener("resize", updatePanelPosition)
    const d = deskRef.current
    d?.addEventListener("scroll", updatePanelPosition)
    return () => {
      window.removeEventListener("resize", updatePanelPosition)
      d?.removeEventListener("scroll", updatePanelPosition)
    }
  }, [updatePanelPosition, zoom])

  const handleSelectTool = useCallback((tool: string) => {
    setActiveTool(tool)
    if (excalidrawAPIRef.current) {
      applyToolToScene(excalidrawAPIRef.current, tool, color, strokeWidth)
    }
  }, [color, strokeWidth])

  const handleZoomIn = useCallback(() => {
    setZoom((prev) => Math.min(3, Math.round((prev + 0.15) * 100) / 100))
  }, [])

  const handleZoomOut = useCallback(() => {
    setZoom((prev) => Math.max(0.5, Math.round((prev - 0.15) * 100) / 100))
  }, [])

  const handleResetZoom = useCallback(() => {
    setZoom(1)
  }, [])

  useZoomTarget(containerRef, (step) => {
    if (step === 1) handleZoomIn()
    else if (step === -1) handleZoomOut()
    else if (step === 0) handleResetZoom()
    return null
  })

  useEffect(() => {
    void window.vaultite?.interfaceSize?.step(0)
  }, [])

  const handleSwitchPage = useCallback((idx: number) => {
    switchPage(idx, excalidrawAPIRef.current)
    if (deskRef.current) deskRef.current.scrollTop = 0
  }, [switchPage])

  useEffect(() => {
    if (excalidrawAPIRef.current) {
      applySceneZoom(excalidrawAPIRef.current, zoom)
    }
  }, [zoom])

  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    const onWheel = (e: WheelEvent) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault()
        e.stopPropagation()
        const delta = -e.deltaY * 0.003
        setZoom((prev) => Math.min(3, Math.max(0.5, Math.round((prev + delta) * 100) / 100)))
        return
      }
      if (deskRef.current) {
        deskRef.current.scrollTop += e.deltaY
        deskRef.current.scrollLeft += e.deltaX
      }
      e.stopPropagation()
      e.preventDefault()
    }
    el.addEventListener("wheel", onWheel, { capture: true, passive: false })
    return () => el.removeEventListener("wheel", onWheel, { capture: true })
  }, [])

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (!(e.ctrlKey || e.metaKey)) return
      if (e.key === "=" || e.key === "+") {
        e.preventDefault()
        handleZoomIn()
      } else if (e.key === "-") {
        e.preventDefault()
        handleZoomOut()
      } else if (e.key === "0") {
        e.preventDefault()
        handleResetZoom()
      }
    }
    window.addEventListener("keydown", onKeyDown)
    return () => window.removeEventListener("keydown", onKeyDown)
  }, [handleZoomIn, handleZoomOut, handleResetZoom])

  useEffect(() => {
    return () => { saveCurrentScene(excalidrawAPIRef.current) }
  }, [saveCurrentScene])

  const isPen = activeTool === "pen" || activeTool === "highlighter" || activeTool === "eraser" || activeTool === "laser"
  const hideProperties = isPen && !hasSelectedElements

  return (
    <div
      ref={containerRef}
      className={`goodnotes-canvas-root absolute inset-0 flex flex-col bg-slate-100 dark:bg-[#12151a] overflow-hidden select-none ${
        hideProperties ? "hide-properties-panel" : ""
      }`}
    >
      <style>{`
        .goodnotes-canvas-root .App-toolbar-container { display: none !important; }
        .goodnotes-canvas-root .main-menu-trigger { display: none !important; }
        .goodnotes-canvas-root .sidebar-trigger { display: none !important; }
        .goodnotes-canvas-root .hint { display: none !important; }
        .goodnotes-canvas-root .layer-ui__wrapper__footer { display: none !important; }
        .goodnotes-canvas-root .excalidraw { background: transparent !important; overflow: visible !important; }
        .goodnotes-canvas-root .layer-ui__wrapper { overflow: visible !important; }
        .goodnotes-canvas-root .selected-shape-actions {
          position: fixed !important;
          left: var(--desk-panel-left, 60px) !important;
          top: var(--desk-panel-top, 125px) !important;
          z-index: 50 !important;
          width: 200px !important;
          pointer-events: auto !important;
          overflow: visible !important;
        }
        .goodnotes-canvas-root .selected-shape-actions .App-menu__left {
          position: relative !important;
          max-height: calc(100vh - 145px) !important;
          overflow-y: auto !important;
          box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.25), 0 8px 10px -6px rgba(0, 0, 0, 0.25) !important;
          border-radius: 12px !important;
        }
        .goodnotes-canvas-root.hide-properties-panel .selected-shape-actions {
          display: none !important;
        }
      `}</style>

      <GoodNotesToolbar
        activeTool={activeTool}
        onSelectTool={handleSelectTool}
        color={color}
        onChangeColor={(c) => { setColor(c); updateSelectedColor(excalidrawAPIRef.current, c) }}
        strokeWidth={strokeWidth}
        onChangeStrokeWidth={(w) => { setStrokeWidth(w); updateSelectedWidth(excalidrawAPIRef.current, w) }}
        currentPageIndex={currentPageIndex}
        totalPages={doc.pages.length}
        onPrevPage={() => handleSwitchPage(currentPageIndex - 1)}
        onNextPage={() => handleSwitchPage(currentPageIndex + 1)}
        onAddPage={() => addPage(currentPageIndex, excalidrawAPIRef.current)}
        onToggleDrawer={() => setIsDrawerOpen(!isDrawerOpen)}
        isDrawerOpen={isDrawerOpen}
        onTogglePaperSettings={() => setIsPaperSettingsOpen(!isPaperSettingsOpen)}
        onUndo={() => document.querySelector(".goodnotes-canvas-root .excalidraw")?.dispatchEvent(new KeyboardEvent("keydown", { key: "z", ctrlKey: true, metaKey: true, bubbles: true }))}
        onRedo={() => document.querySelector(".goodnotes-canvas-root .excalidraw")?.dispatchEvent(new KeyboardEvent("keydown", { key: "y", ctrlKey: true, metaKey: true, bubbles: true }))}
        onInsertImage={() => excalidrawAPIRef.current?.setActiveTool({ type: "image" })}
        onToggleLibrary={() => excalidrawAPIRef.current?.toggleSidebar({ name: "default" })}
        isLibraryOpen={isLibraryOpen}
        gridMode={gridMode}
        onToggleGridMode={() => setGridMode(!gridMode)}
        snapToObjects={snapToObjects}
        onToggleSnapToObjects={() => setSnapToObjects(!snapToObjects)}
        zoom={zoom}
        onZoomIn={handleZoomIn}
        onZoomOut={handleZoomOut}
        onResetZoom={handleResetZoom}
        onHelp={triggerShortcutsHelp}
        onExportPng={() => excalidrawAPIRef.current && exportSceneToPng(excalidrawAPIRef.current, `page-${currentPageIndex + 1}`)}
        onExportSvg={() => excalidrawAPIRef.current && exportSceneToSvg(excalidrawAPIRef.current, `page-${currentPageIndex + 1}`)}
        onCopyPng={() => excalidrawAPIRef.current && copySceneToClipboard(excalidrawAPIRef.current, "png")}
        onCopySvg={() => excalidrawAPIRef.current && copySceneToClipboard(excalidrawAPIRef.current, "svg")}
      />

      <GoodNotesPaperSettings
        isOpen={isPaperSettingsOpen}
        onClose={() => setIsPaperSettingsOpen(false)}
        template={currentPage.template} paperColor={currentPage.paperColor || "white"}
        onChangeTemplate={setPaperTemplate} onChangeColor={setPaperColor}
      />

      <DocumentNavigationDrawer
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        pages={doc.pages}
        currentPageIndex={currentPageIndex}
        onSelectPage={(idx) => { handleSwitchPage(idx); setIsDrawerOpen(false) }}
        onAddPage={(idx) => addPage(idx, excalidrawAPIRef.current)}
        onDuplicatePage={(idx) => duplicatePage(idx, excalidrawAPIRef.current)}
        onDeletePage={(idx) => deletePage(idx, excalidrawAPIRef.current)}
        onRotatePage={(idx) => {
          const p = docRef.current.pages[idx]
          if (p) setDoc({ ...docRef.current, pages: docRef.current.pages.map((pg, i) => i === idx ? { ...pg, rotation: ((pg.rotation || 0) + 90) % 360 } : pg) })
        }}
        onToggleBookmark={(idx) => {
          setDoc({ ...docRef.current, pages: docRef.current.pages.map((pg, i) => i === idx ? { ...pg, bookmarked: !pg.bookmarked } : pg) })
        }}
        readOnly={readOnly}
        onToggleReadOnly={() => setReadOnly(!readOnly)}
      />

      <GoodNotesDeskSheet
        deskRef={deskRef}
        sheetRef={sheetRef}
        currentPage={currentPage}
        readOnly={readOnly}
        gridMode={gridMode}
        snapToObjects={snapToObjects}
        zoom={zoom}
        onApiReady={(api) => {
          excalidrawAPIRef.current = api
          window.__excalidrawAPI = api
          applyToolToScene(api, activeTool, color, strokeWidth)
        }}
        onElementsChange={(elements, appState, files) => {
          updatePageData(elements, files)
          const libOpen = appState.openSidebar?.name === "default"
          if (libOpen !== isLibraryOpen) setIsLibraryOpen(libOpen)
          const toolType = appState.activeTool?.type
          if (toolType === "selection" && activeTool !== "lasso") setActiveTool("lasso")
          const hasSelected = Object.values(appState.selectedElementIds || {}).some(Boolean)
          if (hasSelected !== hasSelectedElements) setHasSelectedElements(hasSelected)
          updatePanelPosition()
        }}
      />
    </div>
  )
}

export default NotebookBoard
