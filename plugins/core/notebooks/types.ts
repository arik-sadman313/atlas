export interface InkPoint {
  x: number
  y: number
  pressure?: number
  tiltX?: number
  tiltY?: number
  time?: number
}

export interface InkStroke {
  id: string
  tool: "pen" | "fountain" | "highlighter" | "eraser"
  color: string
  size: number
  points: InkPoint[]
  createdAt: number
}

export interface InkTextBox {
  id: string
  x: number
  y: number
  width: number
  height: number
  text: string
  fontSize: number
  color: string
  backgroundColor?: string
  isStickyNote?: boolean
}

export type PageTemplate = "blank" | "ruled" | "grid" | "dotted"

export interface NotebookPage {
  id: string
  pageNumber: number
  template: PageTemplate
  strokes: InkStroke[]
  textBoxes: InkTextBox[]
  width: number
  height: number
  pdfSource?: string
  pdfPageIndex?: number
}

export interface NotebookDocument {
  version: number
  title: string
  createdAt: number
  updatedAt: number
  pages: NotebookPage[]
}

export function createEmptyPage(pageNumber: number, template: PageTemplate = "ruled"): NotebookPage {
  return {
    id: `page_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    pageNumber,
    template,
    strokes: [],
    textBoxes: [],
    width: 800,
    height: 1100,
  }
}

export function createEmptyNotebook(title = "Untitled Notebook"): NotebookDocument {
  const now = Date.now()
  return {
    version: 1,
    title,
    createdAt: now,
    updatedAt: now,
    pages: [createEmptyPage(1, "ruled")],
  }
}
