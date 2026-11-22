import React from "react"
import { Excalidraw } from "@excalidraw/excalidraw"
import type { ExcalidrawElement } from "@excalidraw/excalidraw/element/types"
import type { AppState, BinaryFiles, ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import { GoodNotesPaperSheet } from "./GoodNotesPaperSheet"
import { migrateLegacyPageToExcalidraw } from "./legacyMigration"
import type { NotebookPage } from "./types"

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

export interface GoodNotesDeskSheetProps {
  deskRef: React.RefObject<HTMLDivElement | null>
  sheetRef: React.RefObject<HTMLDivElement | null>
  currentPage: NotebookPage
  readOnly: boolean
  gridMode: boolean
  snapToObjects: boolean
  onApiReady: (api: ExcalidrawImperativeAPI) => void
  onElementsChange: (elements: readonly ExcalidrawElement[], appState: AppState, files: BinaryFiles) => void
}

export const GoodNotesDeskSheet: React.FC<GoodNotesDeskSheetProps> = ({
  deskRef,
  sheetRef,
  currentPage,
  readOnly,
  gridMode,
  snapToObjects,
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
        gridModeEnabled={gridMode}
        objectsSnapModeEnabled={snapToObjects}
        UIOptions={HIDE_DEFAULT_UI_OPTIONS}
      />
    </GoodNotesPaperSheet>
  </main>
)
