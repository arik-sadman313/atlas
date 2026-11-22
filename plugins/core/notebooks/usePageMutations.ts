import { useCallback } from "react"
import type { ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"
import type { NotebookDocument, NotebookPage } from "./types"
import { createEmptyPage } from "./types"

function clonePage(src: NotebookPage, newIndex: number): NotebookPage {
  return {
    ...src,
    id: `page_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    pageNumber: newIndex,
    elements: src.elements ? [...src.elements] : [],
    files: src.files ? { ...src.files } : {},
  }
}

export function usePageMutations(
  docRef: React.MutableRefObject<NotebookDocument>,
  setDoc: React.Dispatch<React.SetStateAction<NotebookDocument>>,
  switchPage: (targetIndex: number, api: ExcalidrawImperativeAPI | null) => void,
  saveCurrentScene: (api: ExcalidrawImperativeAPI | null) => void
) {
  const addPage = useCallback((afterIndex: number, api: ExcalidrawImperativeAPI | null) => {
    saveCurrentScene(api)
    const cur = docRef.current.pages[afterIndex] || docRef.current.pages[0]
    const newPage = createEmptyPage(afterIndex + 2, cur.template, cur.paperColor)
    docRef.current.pages.splice(afterIndex + 1, 0, newPage)
    docRef.current.pages.forEach((p, i) => { p.pageNumber = i + 1 })
    setDoc({ ...docRef.current })
    switchPage(afterIndex + 1, api)
  }, [docRef, setDoc, saveCurrentScene, switchPage])

  const duplicatePage = useCallback((index: number, api: ExcalidrawImperativeAPI | null) => {
    saveCurrentScene(api)
    const src = docRef.current.pages[index]
    const clone = clonePage(src, index + 2)
    docRef.current.pages.splice(index + 1, 0, clone)
    docRef.current.pages.forEach((p, i) => { p.pageNumber = i + 1 })
    setDoc({ ...docRef.current })
    switchPage(index + 1, api)
  }, [docRef, setDoc, saveCurrentScene, switchPage])

  const deletePage = useCallback((index: number, api: ExcalidrawImperativeAPI | null) => {
    if (docRef.current.pages.length <= 1) return
    docRef.current.pages.splice(index, 1)
    docRef.current.pages.forEach((p, i) => { p.pageNumber = i + 1 })
    setDoc({ ...docRef.current })
    const nextIdx = Math.max(0, Math.min(index, docRef.current.pages.length - 1))
    switchPage(nextIdx, api)
  }, [docRef, setDoc, switchPage])

  return { addPage, duplicatePage, deletePage }
}
