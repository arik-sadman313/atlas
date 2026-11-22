import React, { useState, useRef, useCallback, useEffect } from "react"
import "@excalidraw/excalidraw/index.css"
import type { ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import { DocumentNavigationDrawer } from "./DocumentNavigationDrawer"
import { GoodNotesToolbar } from "./GoodNotesToolbar"
import { GoodNotesPaperSettings } from "./GoodNotesPaperSettings"
import { GoodNotesDeskSheet } from "./GoodNotesDeskSheet"
import { useNotebookDocument } from "./useNotebookDocument"
import {
  applyToolToScene,
  updateSelectedColor,
  updateSelectedWidth,
  zoomIn,
  zoomOut,
  resetZoom,
  triggerShortcutsHelp,
} from "./notebookActions"
import {
  exportSceneToPng,
  exportSceneToSvg,
  copySceneToClipboard,
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
    doc,
    setDoc,
    docRef,
    currentPageIndex,
    currentPage,
    switchPage,
    addPage,
    duplicatePage,
    deletePage,
    setPaperTemplate,
    setPaperColor,
    updatePageData,
    saveCurrentScene,
  } = useNotebookDocument({ text, onChange })

  const [activeTool, setActiveTool] = useState<string>("pen")
  const [color, setColor] = useState<string>("#1e293b")
  const [strokeWidth, setStrokeWidth] = useState<number>(1.5)
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false)
  const [isPaperSettingsOpen, setIsPaperSettingsOpen] = useState<boolean>(false)
  const [isLibraryOpen, setIsLibraryOpen] = useState<boolean>(false)
  const [gridMode, setGridMode] = useState<boolean>(false)
  const [snapToObjects, setSnapToObjects] = useState<boolean>(true)
  const [readOnly, setReadOnly] = useState<boolean>(!editable)
  const excalidrawAPIRef = useRef<ExcalidrawImperativeAPI | null>(null)
  const deskRef = useRef<HTMLDivElement | null>(null)
  const sheetRef = useRef<HTMLDivElement | null>(null)

  const handleSelectTool = useCallback((tool: string) => {
    setActiveTool(tool)
    if (excalidrawAPIRef.current) {
      applyToolToScene(excalidrawAPIRef.current, tool, color, strokeWidth)
    }
  }, [color, strokeWidth])

  const handleChangeColor = useCallback((c: string) => {
    setColor(c)
    updateSelectedColor(excalidrawAPIRef.current, c)
  }, [])

  const handleChangeStrokeWidth = useCallback((w: number) => {
    setStrokeWidth(w)
    updateSelectedWidth(excalidrawAPIRef.current, w)
  }, [])

  const handleUndo = useCallback(() => {
    document.querySelector(".goodnotes-canvas-root .excalidraw")
      ?.dispatchEvent(new KeyboardEvent("keydown", { key: "z", ctrlKey: true, metaKey: true, bubbles: true }))
  }, [])

  const handleRedo = useCallback(() => {
    document.querySelector(".goodnotes-canvas-root .excalidraw")
      ?.dispatchEvent(new KeyboardEvent("keydown", { key: "y", ctrlKey: true, metaKey: true, bubbles: true }))
  }, [])

  const handleSwitchPage = useCallback((idx: number) => {
    switchPage(idx, excalidrawAPIRef.current)
    if (deskRef.current) deskRef.current.scrollTop = 0
  }, [switchPage])

  useEffect(() => {
    const sheet = sheetRef.current
    if (!sheet) return
    const onWheel = (e: WheelEvent) => {
      if (deskRef.current) {
        deskRef.current.scrollTop += e.deltaY
        deskRef.current.scrollLeft += e.deltaX
      }
      e.stopPropagation()
      e.preventDefault()
    }
    sheet.addEventListener("wheel", onWheel, { capture: true, passive: false })
    return () => sheet.removeEventListener("wheel", onWheel, { capture: true })
  }, [currentPageIndex])

  useEffect(() => {
    return () => { saveCurrentScene(excalidrawAPIRef.current) }
  }, [saveCurrentScene])

  return (
    <div className="goodnotes-canvas-root absolute inset-0 flex flex-col bg-slate-100 dark:bg-[#12151a] overflow-hidden select-none">
      <style>{`
        .goodnotes-canvas-root .App-toolbar-container { display: none !important; }
        .goodnotes-canvas-root .main-menu-trigger { display: none !important; }
        .goodnotes-canvas-root .sidebar-trigger { display: none !important; }
        .goodnotes-canvas-root .hint { display: none !important; }
        .goodnotes-canvas-root .layer-ui__wrapper__footer { display: none !important; }
        .goodnotes-canvas-root .excalidraw { background: transparent !important; overflow: visible !important; }
        .goodnotes-canvas-root .layer-ui__wrapper { overflow: visible !important; }
        .goodnotes-canvas-root .selected-shape-actions {
          position: absolute !important;
          left: -245px !important;
          top: 10px !important;
          z-index: 50 !important;
          width: 200px !important;
          pointer-events: auto !important;
          overflow: visible !important;
        }
        .goodnotes-canvas-root .selected-shape-actions .App-menu__left {
          position: relative !important;
          max-height: calc(100vh - 140px) !important;
          overflow-y: auto !important;
          box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.25), 0 8px 10px -6px rgba(0, 0, 0, 0.25) !important;
          border-radius: 12px !important;
        }
      `}</style>

      <GoodNotesToolbar
        activeTool={activeTool}
        onSelectTool={handleSelectTool}
        color={color}
        onChangeColor={handleChangeColor}
        strokeWidth={strokeWidth}
        onChangeStrokeWidth={handleChangeStrokeWidth}
        currentPageIndex={currentPageIndex}
        totalPages={doc.pages.length}
        onPrevPage={() => handleSwitchPage(currentPageIndex - 1)}
        onNextPage={() => handleSwitchPage(currentPageIndex + 1)}
        onAddPage={() => addPage(currentPageIndex, excalidrawAPIRef.current)}
        onToggleDrawer={() => setIsDrawerOpen(!isDrawerOpen)}
        isDrawerOpen={isDrawerOpen}
        onTogglePaperSettings={() => setIsPaperSettingsOpen(!isPaperSettingsOpen)}
        onUndo={handleUndo}
        onRedo={handleRedo}
        onInsertImage={() => excalidrawAPIRef.current?.setActiveTool({ type: "image" })}
        onToggleLibrary={() => excalidrawAPIRef.current?.toggleSidebar({ name: "default" })}
        isLibraryOpen={isLibraryOpen}
        gridMode={gridMode}
        onToggleGridMode={() => setGridMode(!gridMode)}
        snapToObjects={snapToObjects}
        onToggleSnapToObjects={() => setSnapToObjects(!snapToObjects)}
        onZoomIn={() => excalidrawAPIRef.current && zoomIn(excalidrawAPIRef.current)}
        onZoomOut={() => excalidrawAPIRef.current && zoomOut(excalidrawAPIRef.current)}
        onResetZoom={() => excalidrawAPIRef.current && resetZoom(excalidrawAPIRef.current)}
        onHelp={triggerShortcutsHelp}
        onExportPng={() => excalidrawAPIRef.current && exportSceneToPng(excalidrawAPIRef.current, `page-${currentPageIndex + 1}`)}
        onExportSvg={() => excalidrawAPIRef.current && exportSceneToSvg(excalidrawAPIRef.current, `page-${currentPageIndex + 1}`)}
        onCopyPng={() => excalidrawAPIRef.current && copySceneToClipboard(excalidrawAPIRef.current, "png")}
        onCopySvg={() => excalidrawAPIRef.current && copySceneToClipboard(excalidrawAPIRef.current, "svg")}
      />

      <GoodNotesPaperSettings
        isOpen={isPaperSettingsOpen}
        onClose={() => setIsPaperSettingsOpen(false)}
        template={currentPage.template}
        paperColor={currentPage.paperColor || "white"}
        onChangeTemplate={setPaperTemplate}
        onChangeColor={setPaperColor}
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
          if (p) { p.rotation = ((p.rotation || 0) + 90) % 360; setDoc({ ...docRef.current }) }
        }}
        onToggleBookmark={(idx) => {
          const p = docRef.current.pages[idx]
          if (p) { p.bookmarked = !p.bookmarked; setDoc({ ...docRef.current }) }
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
          if (toolType === "selection" && activeTool !== "lasso") {
            setActiveTool("lasso")
          }
        }}
      />
    </div>
  )
}

export default NotebookBoard
