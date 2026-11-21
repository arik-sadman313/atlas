export interface InkPoint {
  x: number
  y: number
  pressure?: number
  tiltX?: number
  tiltY?: number
  time?: number
}

export type InkToolType =
  | "fountain"
  | "ballpoint"
  | "brush"
  | "highlighter"
  | "eraser"
  | "lasso"
  | "shape"
  | "textbox"
  | "stickynote"
  | "image"

export type ShapePrimitive = "line" | "arrow" | "rect" | "ellipse" | "triangle"

export interface InkStroke {
  id: string
  tool: "pen" | "fountain" | "ballpoint" | "brush" | "highlighter" | "eraser" | "shape"
  color: string
  size: number
  points: InkPoint[]
  createdAt: number
  shapeType?: ShapePrimitive
  fill?: string
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
  bold?: boolean
  italic?: boolean
  fontFamily?: "sans" | "serif" | "mono" | "handwriting"
}

export interface NotebookImage {
  id: string
  url: string
  x: number
  y: number
  width: number
  height: number
  rotation?: number
}

export type PageTemplate =
  | "blank"
  | "ruled"
  | "ruled-wide"
  | "grid"
  | "dotted"
  | "cornell"

export type PaperColor = "white" | "cream" | "dark"

export interface NotebookPage {
  id: string
  pageNumber: number
  template: PageTemplate
  paperColor?: PaperColor
  strokes: InkStroke[]
  textBoxes: InkTextBox[]
  images?: NotebookImage[]
  bookmarked?: boolean
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

export function createEmptyPage(pageNumber: number, template: PageTemplate = "ruled", paperColor: PaperColor = "white"): NotebookPage {
  return {
    id: `page_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    pageNumber,
    template,
    paperColor,
    strokes: [],
    textBoxes: [],
    images: [],
    bookmarked: false,
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
    pages: [createEmptyPage(1, "ruled", "white")],
  }
}
