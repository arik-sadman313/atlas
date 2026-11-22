import React, { useState, useRef, useCallback, useEffect } from "react"
import { Excalidraw } from "@excalidraw/excalidraw"
import "@excalidraw/excalidraw/index.css"
import type { ExcalidrawElement } from "@excalidraw/excalidraw/element/types"
import type { AppState, BinaryFiles, ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import { DocumentNavigationDrawer } from "./DocumentNavigationDrawer"
import { GoodNotesToolbar } from "./GoodNotesToolbar"
import { GoodNotesPaperSettings } from "./GoodNotesPaperSettings"
import { GoodNotesPaperSheet } from "./GoodNotesPaperSheet"
import { useNotebookDocument } from "./useNotebookDocument"
import { migrateLegacyPageToExcalidraw } from "./legacyMigration"
import type { NotebookPage } from "./types"

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

type FormToolType = "rectangle" | "diamond" | "ellipse" | "arrow" | "line"

function isFormTool(tool: string): tool is FormToolType {
  return tool === "rectangle" || tool === "diamond" || tool === "ellipse" || tool === "arrow" || tool === "line"
}

const HIDE_DEFAULT_UI_OPTIONS = {
  canvasActions: {
    changeViewBackgroundColor: false,
    clearCanvas: false,
    loadScene: false,
    saveToActiveFile: false,
    toggleTheme: false,
    saveAsImage: false,
    export: false as const,
  },
  tools: {
    image: true,
  },
}

function applyFreedraw(
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

function applyForm(
  api: ExcalidrawImperativeAPI,
  form: FormToolType,
  color: string,
  strokeWidth: number
) {
  api.setActiveTool({ type: form, locked: true })
  api.updateScene({
    appState: {
      currentItemStrokeColor: color,
      currentItemStrokeWidth: strokeWidth,
      currentItemOpacity: 100,
      currentItemRoughness: 0,
    },
  })
}

function applyToolToScene(
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
  if (tool === "eraser" || tool === "laser" || tool === "text") {
    api.setActiveTool({ type: tool, locked: true })
    return
  }
  if (isFormTool(tool)) {
    applyForm(api, tool, color, strokeWidth)
  }
}

function updateSelectedColor(api: ExcalidrawImperativeAPI | null, c: string) {
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

function updateSelectedWidth(api: ExcalidrawImperativeAPI | null, w: number) {
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

interface DeskSheetProps {
  deskRef: React.RefObject<HTMLDivElement | null>
  sheetRef: React.RefObject<HTMLDivElement | null>
  currentPage: NotebookPage
  readOnly: boolean
  onApiReady: (api: ExcalidrawImperativeAPI) => void
  onElementsChange: (elements: readonly ExcalidrawElement[], appState: AppState, files: BinaryFiles) => void
}

const DeskSheet: React.FC<DeskSheetProps> = ({
  deskRef,
  sheetRef,
  currentPage,
  readOnly,
  onApiReady,
  onElementsChange,
}) => (
  <main
    ref={deskRef}
    className="goodnotes-desk flex-1 relative overflow-auto flex justify-center py-8 px-6 bg-slate-200/90 dark:bg-[#0c0e12] select-none"
  >
    <GoodNotesPaperSheet
      sheetRef={sheetRef}
      template={currentPage.template}
      paperColor={currentPage.paperColor || "white"}
      pageSize={currentPage.pageSize || "Standard"}
      orientation={currentPage.orientation || "portrait"}
    >
      <Excalidraw
        excalidrawAPI={onApiReady}
        initialData={{
          elements: migrateLegacyPageToExcalidraw(currentPage),
          files: currentPage.files,
          appState: {
            viewBackgroundColor: "transparent",
            currentItemRoughness: 0,
            theme: currentPage.paperColor === "dark" ? "dark" : "light",
            scrollX: 0,
            scrollY: 0,
          },
        }}
        onChange={onElementsChange}
        onScrollChange={(scrollX, scrollY) => {
          if (scrollX !== 0 || scrollY !== 0) {
            window.__excalidrawAPI?.updateScene({ appState: { scrollX: 0, scrollY: 0 } })
          }
        }}
        viewModeEnabled={readOnly}
        zenModeEnabled={false}
        UIOptions={HIDE_DEFAULT_UI_OPTIONS}
      />
    </GoodNotesPaperSheet>
  </main>
)

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

  const handleRotatePage = useCallback((index: number) => {
    const p = docRef.current.pages[index]
    if (p) { p.rotation = ((p.rotation || 0) + 90) % 360; setDoc({ ...docRef.current }) }
  }, [docRef, setDoc])

  const handleToggleBookmark = useCallback((index: number) => {
    const p = docRef.current.pages[index]
    if (p) { p.bookmarked = !p.bookmarked; setDoc({ ...docRef.current }) }
  }, [docRef, setDoc])

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
        onRotatePage={handleRotatePage}
        onToggleBookmark={handleToggleBookmark}
        readOnly={readOnly}
        onToggleReadOnly={() => setReadOnly(!readOnly)}
      />

      <DeskSheet
        deskRef={deskRef}
        sheetRef={sheetRef}
        currentPage={currentPage}
        readOnly={readOnly}
        onApiReady={(api) => {
          excalidrawAPIRef.current = api
          window.__excalidrawAPI = api
          applyToolToScene(api, activeTool, color, strokeWidth)
        }}
        onElementsChange={(elements, appState, files) => {
          updatePageData(elements, files)
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
