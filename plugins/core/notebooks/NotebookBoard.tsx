import React, { useState, useRef, useCallback, useEffect } from "react"
import { Excalidraw } from "@excalidraw/excalidraw"
import "@excalidraw/excalidraw/index.css"
import type { ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import { DocumentNavigationDrawer } from "./DocumentNavigationDrawer"
import { GoodNotesToolbar } from "./GoodNotesToolbar"
import { GoodNotesPaperSettings } from "./GoodNotesPaperSettings"
import { GoodNotesPaperSheet } from "./GoodNotesPaperSheet"
import { useNotebookDocument } from "./useNotebookDocument"
import { migrateLegacyPageToExcalidraw } from "./legacyMigration"

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

type FormToolType = "rectangle" | "ellipse" | "diamond" | "arrow" | "line"

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

function applyToolToScene(
  api: ExcalidrawImperativeAPI,
  tool: string,
  form: string,
  color: string,
  strokeWidth: number
) {
  if (tool === "highlighter") {
    api.setActiveTool({ type: "freedraw" })
    api.updateScene({ appState: { currentItemStrokeColor: color, currentItemStrokeWidth: 18, currentItemOpacity: 45, currentItemRoughness: 0 } })
    return
  }
  if (tool === "pen") {
    api.setActiveTool({ type: "freedraw" })
    api.updateScene({ appState: { currentItemStrokeColor: color, currentItemStrokeWidth: strokeWidth, currentItemOpacity: 100, currentItemRoughness: 0 } })
    return
  }
  if (tool === "eraser" || tool === "laser" || tool === "text") {
    api.setActiveTool({ type: tool })
    return
  }
  if (tool === "lasso") {
    api.setActiveTool({ type: "selection" })
    return
  }
  const formType: FormToolType = form === "ellipse" ? "ellipse" : form === "arrow" ? "arrow" : form === "line" ? "line" : "rectangle"
  api.setActiveTool({ type: formType })
  api.updateScene({ appState: { currentItemStrokeColor: color, currentItemStrokeWidth: strokeWidth, currentItemOpacity: 100, currentItemRoughness: 0 } })
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
  const [activeForm, setActiveForm] = useState<string>("rectangle")
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
      applyToolToScene(excalidrawAPIRef.current, tool, activeForm, color, strokeWidth)
    }
  }, [activeForm, color, strokeWidth])

  const handleSelectForm = useCallback((form: string) => {
    setActiveForm(form)
    setActiveTool("form")
    if (excalidrawAPIRef.current) {
      applyToolToScene(excalidrawAPIRef.current, "form", form, color, strokeWidth)
    }
  }, [color, strokeWidth])

  const handleChangeColor = useCallback((c: string) => {
    setColor(c)
    excalidrawAPIRef.current?.updateScene({ appState: { currentItemStrokeColor: c } })
  }, [])

  const handleChangeStrokeWidth = useCallback((w: number) => {
    setStrokeWidth(w)
    excalidrawAPIRef.current?.updateScene({ appState: { currentItemStrokeWidth: w } })
  }, [])

  const handleUndo = useCallback(() => {
    const el = document.querySelector(".goodnotes-canvas-root .excalidraw")
    el?.dispatchEvent(new KeyboardEvent("keydown", { key: "z", ctrlKey: true, metaKey: true, bubbles: true }))
  }, [])

  const handleRedo = useCallback(() => {
    const el = document.querySelector(".goodnotes-canvas-root .excalidraw")
    el?.dispatchEvent(new KeyboardEvent("keydown", { key: "y", ctrlKey: true, metaKey: true, bubbles: true }))
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
    if (deskRef.current) {
      deskRef.current.scrollTop = 0
    }
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
        .goodnotes-canvas-root .excalidraw { background: transparent !important; }
      `}</style>

      <GoodNotesToolbar
        activeTool={activeTool}
        activeForm={activeForm}
        onSelectTool={handleSelectTool}
        onSelectForm={handleSelectForm}
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
            excalidrawAPI={(api) => {
              excalidrawAPIRef.current = api
              window.__excalidrawAPI = api
              applyToolToScene(api, activeTool, activeForm, color, strokeWidth)
            }}
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
            onChange={(elements, _appState, files) => {
              updatePageData(elements, files)
            }}
            onScrollChange={(scrollX, scrollY) => {
              if (scrollX !== 0 || scrollY !== 0) {
                excalidrawAPIRef.current?.updateScene({
                  appState: { scrollX: 0, scrollY: 0 },
                })
              }
            }}
            viewModeEnabled={readOnly}
            zenModeEnabled={false}
            UIOptions={HIDE_DEFAULT_UI_OPTIONS}
          />
        </GoodNotesPaperSheet>
      </main>
    </div>
  )
}

export default NotebookBoard
