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
  | "tape"
  | "ruler"
  | "laser"

export type EraserMode = "precision" | "standard" | "stroke"

export type ShapePrimitive = "line" | "arrow" | "rect" | "ellipse" | "triangle" | "polygon" | "arc"

export interface PenToolConfig {
  tipSharpness: number // 0 to 100%
  pressureSensitivity: number // 0 to 100%
  stabilization: number // 0 to 100%
}

export interface PenStudioSettings {
  fountain: PenToolConfig
  ballpoint: PenToolConfig
  brush: PenToolConfig
}

export const DEFAULT_PEN_SETTINGS: PenStudioSettings = {
  fountain: {
    tipSharpness: 75,
    pressureSensitivity: 60,
    stabilization: 45,
  },
  ballpoint: {
    tipSharpness: 10,
    pressureSensitivity: 0,
    stabilization: 50,
  },
  brush: {
    tipSharpness: 85,
    pressureSensitivity: 90,
    stabilization: 35,
  },
}

export interface InkStroke {
  id: string
  tool: "pen" | "fountain" | "ballpoint" | "brush" | "highlighter" | "eraser" | "shape"
  color: string
  size: number
  points: InkPoint[]
  createdAt: number
  audioTimeOffset?: number
  shapeType?: ShapePrimitive
  fill?: string
  stabilized?: boolean
  penSettings?: {
    tipSharpness?: number
    pressureSensitivity?: number
    stabilization?: number
  }
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
  underline?: boolean
  strikethrough?: boolean
  align?: "left" | "center" | "right"
  lineSpacing?: number
  borderStroke?: string
  padding?: number
  fontFamily?: "sans" | "serif" | "mono" | "handwriting"
  collapsed?: boolean
  audioTimeOffset?: number
}

export interface ImageCropData {
  type: "rect" | "freehand"
  bounds?: { x: number; y: number; width: number; height: number }
  path?: string
}

export interface NotebookImage {
  id: string
  url: string
  x: number
  y: number
  width: number
  height: number
  rotation?: number
  crop?: ImageCropData
}

export interface TapeStrip {
  id: string
  points: InkPoint[]
  width: number
  pattern?: "solid" | "stripes" | "dots"
  color: string
  revealed: boolean // Tapping in Read-Only or Study mode toggles reveal
  createdAt: number
}

export type PageSize = "Standard" | "A3" | "A4" | "A5" | "Letter"

export type PageOrientation = "portrait" | "landscape"

export const PAGE_DIMENSIONS: Record<PageSize, { portrait: { width: number; height: number }; landscape: { width: number; height: number } }> = {
  Standard: {
    portrait: { width: 800, height: 1100 },
    landscape: { width: 1100, height: 800 },
  },
  A4: {
    portrait: { width: 842, height: 1191 },
    landscape: { width: 1191, height: 842 },
  },
  A5: {
    portrait: { width: 595, height: 842 },
    landscape: { width: 842, height: 595 },
  },
  A3: {
    portrait: { width: 1191, height: 1684 },
    landscape: { width: 1684, height: 1191 },
  },
  Letter: {
    portrait: { width: 816, height: 1056 },
    landscape: { width: 1056, height: 816 },
  },
}

export type PageTemplate =
  | "blank"
  | "ruled"
  | "ruled-wide"
  | "grid"
  | "dotted"
  | "cornell"
  | "music-staff"
  | "monthly-planner"
  | "weekly-planner"

export type PaperColor = "white" | "cream" | "dark"

export type CoverStyle =
  | "leather-black"
  | "gradient-sunset"
  | "marble-blue"
  | "minimal-kraft"
  | "notebook-classic"
  | "academic-navy"

export interface NotebookCover {
  style: CoverStyle
  title: string
  author?: string
  color?: string
}

export interface AudioEvent {
  timestamp: number // milliseconds from start of recording
  type: "stroke" | "text" | "page_turn"
  targetId: string
  pageIndex?: number
}

export interface AudioRecording {
  id: string
  audioDataUrl?: string
  durationMs: number
  createdAt: number
  events: AudioEvent[]
}

export interface NotebookOutlineItem {
  id: string
  title: string
  pageIndex: number
  level: number
  children?: NotebookOutlineItem[]
}

export interface NotebookElement {
  id: string
  name: string
  collectionId: string
  strokes: InkStroke[]
  textBoxes?: InkTextBox[]
  previewSvg?: string
}

export interface ElementCollection {
  id: string
  name: string
  icon?: string
  elements: NotebookElement[]
}

export interface LassoFilter {
  handwriting: boolean
  images: boolean
  textBoxes: boolean
  stickyNotes: boolean
}

export interface RulerState {
  active: boolean
  x: number
  y: number
  angle: number // degrees with live readout
  length: number
}

export interface LaserState {
  active: boolean
  mode: "dot" | "trail"
  current: InkPoint | null
  trail: Array<{ x: number; y: number; time: number }>
  color?: string
}

export interface ZoomWindowState {
  active: boolean
  scale: number
  x: number
  y: number
  width: number
  height: number
  targetX: number
  targetY: number
}

export interface NotebookPage {
  id: string
  pageNumber: number
  template: PageTemplate
  paperColor?: PaperColor
  pageSize?: PageSize
  orientation?: PageOrientation
  rotation?: number // 0, 90, 180, 270
  customTemplateImage?: string
  customTemplatePdf?: string
  strokes: InkStroke[]
  textBoxes: InkTextBox[]
  images?: NotebookImage[]
  tapeStrips?: TapeStrip[]
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
  cover?: NotebookCover
  pageSize?: PageSize
  orientation?: PageOrientation
  outlines?: NotebookOutlineItem[]
  audioRecordings?: AudioRecording[]
  pages: NotebookPage[]
}

export function createEmptyPage(
  pageNumber: number,
  template: PageTemplate = "ruled",
  paperColor: PaperColor = "white",
  pageSize: PageSize = "Standard",
  orientation: PageOrientation = "portrait"
): NotebookPage {
  const dims = PAGE_DIMENSIONS[pageSize]?.[orientation] || PAGE_DIMENSIONS.Standard.portrait
  return {
    id: `page_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    pageNumber,
    template,
    paperColor,
    pageSize,
    orientation,
    rotation: 0,
    strokes: [],
    textBoxes: [],
    images: [],
    tapeStrips: [],
    bookmarked: false,
    width: dims.width,
    height: dims.height,
  }
}

export function createEmptyNotebook(
  title = "Untitled Notebook",
  template: PageTemplate = "ruled",
  paperColor: PaperColor = "white",
  coverStyle: CoverStyle = "notebook-classic",
  pageSize: PageSize = "Standard",
  orientation: PageOrientation = "portrait"
): NotebookDocument {
  const now = Date.now()
  return {
    version: 1,
    title,
    createdAt: now,
    updatedAt: now,
    pageSize,
    orientation,
    cover: {
      style: coverStyle,
      title,
      color: "#2563eb",
    },
    outlines: [],
    audioRecordings: [],
    pages: [createEmptyPage(1, template, paperColor, pageSize, orientation)],
  }
}
