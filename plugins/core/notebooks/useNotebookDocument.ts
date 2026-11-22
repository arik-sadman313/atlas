import { useState, useRef, useCallback, useMemo } from "react"
import type { ExcalidrawElement } from "@excalidraw/excalidraw/element/types"
import type { BinaryFiles, ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import type { NotebookDocument, PageTemplate, PaperColor } from "./types"
import { createEmptyNotebook } from "./types"
import { migrateLegacyPageToExcalidraw } from "./legacyMigration"
import { usePageMutations } from "./usePageMutations"

export interface UseNotebookDocumentProps {
  text: string
  onChange?: (newText: string) => void
}

function parseDoc(text: string): NotebookDocument {
  try {
    const parsed = JSON.parse(text)
    if (parsed && Array.isArray(parsed.pages) && parsed.pages.length > 0) {
      // oxlint-disable-next-line vaultite/no-cast -- parsed JSON notebook document structure
      return parsed as NotebookDocument
    }
  } catch {
    // fallback to empty notebook
  }
  return createEmptyNotebook()
}

function usePageUpdates(
  docRef: React.MutableRefObject<NotebookDocument>,
  setDoc: React.Dispatch<React.SetStateAction<NotebookDocument>>,
  currentPageIndex: number,
  scheduleSave: () => void
) {
  const setPaperTemplate = useCallback((template: PageTemplate) => {
    const cur = docRef.current.pages[currentPageIndex]
    if (cur) { cur.template = template; setDoc({ ...docRef.current }); scheduleSave() }
  }, [docRef, setDoc, currentPageIndex, scheduleSave])

  const setPaperColor = useCallback((color: PaperColor) => {
    const cur = docRef.current.pages[currentPageIndex]
    if (cur) { cur.paperColor = color; setDoc({ ...docRef.current }); scheduleSave() }
  }, [docRef, setDoc, currentPageIndex, scheduleSave])

  const updatePageData = useCallback((elements: readonly ExcalidrawElement[], files: BinaryFiles) => {
    const cur = docRef.current.pages[currentPageIndex]
    if (cur) { cur.elements = elements; cur.files = files; scheduleSave() }
  }, [docRef, currentPageIndex, scheduleSave])

  return { setPaperTemplate, setPaperColor, updatePageData }
}

export function useNotebookDocument({ text, onChange }: UseNotebookDocumentProps) {
  const initialDoc = useMemo(() => parseDoc(text), [text])
  const docRef = useRef<NotebookDocument>(initialDoc)
  const [doc, setDoc] = useState<NotebookDocument>(initialDoc)
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const saveTimerRef = useRef<NodeJS.Timeout | null>(null)

  const scheduleSave = useCallback(() => {
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current)
    saveTimerRef.current = setTimeout(() => {
      docRef.current.updatedAt = Date.now()
      onChange?.(JSON.stringify(docRef.current, null, "\t") + "\n")
    }, 400)
  }, [onChange])

  const saveCurrentScene = useCallback((api: ExcalidrawImperativeAPI | null) => {
    if (!api) return
    const cur = docRef.current.pages[currentPageIndex]
    if (cur) { cur.elements = api.getSceneElements(); cur.files = api.getFiles(); scheduleSave() }
  }, [currentPageIndex, scheduleSave])

  const switchPage = useCallback((targetIndex: number, api: ExcalidrawImperativeAPI | null) => {
    if (targetIndex < 0 || targetIndex >= docRef.current.pages.length) return
    saveCurrentScene(api)
    const targetPage = docRef.current.pages[targetIndex]
    const elements = migrateLegacyPageToExcalidraw(targetPage)
    if (targetPage.files && api) {
      api.addFiles(Object.values(targetPage.files))
    }
    api?.updateScene({
      elements,
      appState: {
        scrollX: 0,
        scrollY: 0,
        theme: targetPage.paperColor === "dark" ? "dark" : "light",
      },
    })
    api?.history.clear()
    setCurrentPageIndex(targetIndex)
  }, [saveCurrentScene])

  const { addPage, duplicatePage, deletePage } = usePageMutations(docRef, setDoc, switchPage, saveCurrentScene)
  const { setPaperTemplate, setPaperColor, updatePageData } = usePageUpdates(docRef, setDoc, currentPageIndex, scheduleSave)

  return {
    doc,
    setDoc,
    docRef,
    currentPageIndex,
    currentPage: doc.pages[currentPageIndex] || doc.pages[0],
    switchPage,
    addPage,
    duplicatePage,
    deletePage,
    setPaperTemplate,
    setPaperColor,
    updatePageData,
    saveCurrentScene,
  }
}
