import React from "react"
import {
  Pen,
  Highlighter,
  Eraser,
  Lasso,
  Hand,
  Square,
  Diamond,
  Circle,
  ArrowUpRight,
  Minus,
  Frame,
  Type,
  Globe,
  Sparkles,
  Image as ImageIcon,
  Library,
  ChevronLeft,
  ChevronRight,
  Plus,
  Layers,
  Sliders,
} from "lucide-react"
import { GoodNotesStyleControls, type GoodNotesStyleControlsProps } from "./GoodNotesStyleControls"
import { GoodNotesExportMenu, type GoodNotesExportMenuProps } from "./GoodNotesExportMenu"
import { CanvasQuickControls, type CanvasQuickControlsProps } from "./CanvasQuickControls"

export interface GoodNotesToolbarProps
  extends GoodNotesStyleControlsProps,
    GoodNotesExportMenuProps,
    CanvasQuickControlsProps {
  activeTool: string
  onSelectTool: (tool: string) => void
  currentPageIndex: number
  totalPages: number
  onPrevPage: () => void
  onNextPage: () => void
  onAddPage: () => void
  onToggleDrawer: () => void
  isDrawerOpen: boolean
  onTogglePaperSettings: () => void
  onInsertImage: () => void
  onToggleLibrary: () => void
  isLibraryOpen: boolean
}

interface ToolItem {
  id: string
  label: string
  icon: React.ComponentType<{ className?: string }>
}

const DRAWING_TOOLS: ToolItem[] = [
  { id: "pen", label: "Pen", icon: Pen },
  { id: "highlighter", label: "Highlighter", icon: Highlighter },
  { id: "eraser", label: "Eraser", icon: Eraser },
  { id: "lasso", label: "Lasso / Select", icon: Lasso },
  { id: "hand", label: "Hand / Pan", icon: Hand },
]

const FORM_TOOLS: ToolItem[] = [
  { id: "rectangle", label: "Rectangle", icon: Square },
  { id: "diamond", label: "Diamond", icon: Diamond },
  { id: "ellipse", label: "Circle", icon: Circle },
  { id: "arrow", label: "Arrow", icon: ArrowUpRight },
  { id: "line", label: "Line", icon: Minus },
  { id: "frame", label: "Frame / Slide", icon: Frame },
]

const CONTENT_TOOLS: ToolItem[] = [
  { id: "text", label: "Text Note", icon: Type },
  { id: "embeddable", label: "Web Embed", icon: Globe },
  { id: "laser", label: "Laser Pointer", icon: Sparkles },
]

const PageCounter: React.FC<{
  currentPageIndex: number
  totalPages: number
  onPrevPage: () => void
  onNextPage: () => void
}> = ({ currentPageIndex, totalPages, onPrevPage, onNextPage }) => (
  <div className="flex items-center bg-slate-100 dark:bg-slate-800/80 rounded-lg p-0.5 text-xs font-medium text-slate-700 dark:text-slate-300">
    <button
      onClick={onPrevPage}
      disabled={currentPageIndex <= 0}
      className="p-1 hover:text-blue-600 disabled:opacity-30 disabled:hover:text-inherit"
      data-tip="Previous Page"
    >
      <ChevronLeft className="size-3.5" />
    </button>
    <span className="px-1.5 select-none font-semibold">
      {currentPageIndex + 1} / {totalPages}
    </span>
    <button
      onClick={onNextPage}
      disabled={currentPageIndex >= totalPages - 1}
      className="p-1 hover:text-blue-600 disabled:opacity-30 disabled:hover:text-inherit"
      data-tip="Next Page"
    >
      <ChevronRight className="size-3.5" />
    </button>
  </div>
)

const PageNavSection: React.FC<Pick<
  GoodNotesToolbarProps,
  | "currentPageIndex"
  | "totalPages"
  | "isDrawerOpen"
  | "onToggleDrawer"
  | "onPrevPage"
  | "onNextPage"
  | "onAddPage"
  | "onTogglePaperSettings"
  | "onExportPng"
  | "onExportSvg"
  | "onCopyPng"
  | "onCopySvg"
>> = (props) => (
  <div className="flex items-center gap-1 shrink-0">
    <button
      onClick={props.onToggleDrawer}
      className={`p-1.5 rounded-lg transition-colors ${
        props.isDrawerOpen
          ? "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300"
          : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
      }`}
      data-tip="Pages & Thumbnails"
    >
      <Layers className="size-4" />
    </button>
    <PageCounter
      currentPageIndex={props.currentPageIndex}
      totalPages={props.totalPages}
      onPrevPage={props.onPrevPage}
      onNextPage={props.onNextPage}
    />
    <button
      onClick={props.onAddPage}
      className="flex items-center gap-1 px-2 py-1 bg-blue-50 hover:bg-blue-100 dark:bg-blue-950/60 dark:hover:bg-blue-900/60 text-blue-600 dark:text-blue-400 rounded-lg text-xs font-semibold transition-colors"
      data-tip="Add Page After Current"
    >
      <Plus className="size-3.5" />
      <span>Page</span>
    </button>
    <button
      onClick={props.onTogglePaperSettings}
      className="p-1.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
      data-tip="Paper Template & Color"
    >
      <Sliders className="size-4" />
    </button>
    <div className="w-[1px] h-4 bg-slate-200 dark:bg-slate-800 mx-0.5" />
    <GoodNotesExportMenu
      onExportPng={props.onExportPng}
      onExportSvg={props.onExportSvg}
      onCopyPng={props.onCopyPng}
      onCopySvg={props.onCopySvg}
    />
  </div>
)

const ToolButton: React.FC<{
  tool: ToolItem
  active: boolean
  onClick: () => void
}> = ({ tool, active, onClick }) => {
  const Icon = tool.icon
  return (
    <button
      onClick={onClick}
      className={`p-1.5 rounded-lg transition-all ${
        active
          ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
          : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/40"
      }`}
      data-tip={tool.label}
    >
      <Icon className="size-4" />
    </button>
  )
}

const ToolPaletteSection: React.FC<{
  activeTool: string
  onSelectTool: (tool: string) => void
  onInsertImage: () => void
  onToggleLibrary: () => void
  isLibraryOpen: boolean
}> = ({ activeTool, onSelectTool, onInsertImage, onToggleLibrary, isLibraryOpen }) => (
  <div className="flex items-center gap-0.5 bg-slate-100/90 dark:bg-slate-800/80 p-1 rounded-xl">
    {DRAWING_TOOLS.map((t) => (
      <ToolButton
        key={t.id}
        tool={t}
        active={activeTool === t.id}
        onClick={() => onSelectTool(t.id)}
      />
    ))}
    <div className="w-[1px] h-4 bg-slate-300 dark:bg-slate-700 mx-0.5" />
    {FORM_TOOLS.map((t) => (
      <ToolButton
        key={t.id}
        tool={t}
        active={activeTool === t.id}
        onClick={() => onSelectTool(t.id)}
      />
    ))}
    <div className="w-[1px] h-4 bg-slate-300 dark:bg-slate-700 mx-0.5" />
    {CONTENT_TOOLS.map((t) => (
      <ToolButton
        key={t.id}
        tool={t}
        active={activeTool === t.id}
        onClick={() => onSelectTool(t.id)}
      />
    ))}
    <button
      onClick={onInsertImage}
      className="p-1.5 rounded-lg text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/40 transition-all"
      data-tip="Insert Image"
    >
      <ImageIcon className="size-4" />
    </button>
    <div className="w-[1px] h-4 bg-slate-300 dark:bg-slate-700 mx-0.5" />
    <button
      onClick={onToggleLibrary}
      className={`p-1.5 rounded-lg transition-all ${
        isLibraryOpen
          ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
          : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-200/50 dark:hover:bg-slate-700/40"
      }`}
      data-tip="Excalidraw Library (Assets & Stickers)"
    >
      <Library className="size-4" />
    </button>
  </div>
)

export const GoodNotesToolbar: React.FC<GoodNotesToolbarProps> = (props) => (
  <header className="h-12 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 px-3 flex items-center justify-between gap-2 shadow-sm select-none z-30 shrink-0">
    <PageNavSection {...props} />

    <ToolPaletteSection
      activeTool={props.activeTool}
      onSelectTool={props.onSelectTool}
      onInsertImage={props.onInsertImage}
      onToggleLibrary={props.onToggleLibrary}
      isLibraryOpen={props.isLibraryOpen}
    />

    <div className="flex items-center gap-2">
      <CanvasQuickControls
        gridMode={props.gridMode}
        onToggleGridMode={props.onToggleGridMode}
        snapToObjects={props.snapToObjects}
        onToggleSnapToObjects={props.onToggleSnapToObjects}
        zoom={props.zoom}
        onZoomIn={props.onZoomIn}
        onZoomOut={props.onZoomOut}
        onResetZoom={props.onResetZoom}
        onHelp={props.onHelp}
      />
      <div className="w-[1px] h-4 bg-slate-200 dark:bg-slate-800" />
      <GoodNotesStyleControls
        color={props.color}
        onChangeColor={props.onChangeColor}
        strokeWidth={props.strokeWidth}
        onChangeStrokeWidth={props.onChangeStrokeWidth}
        onUndo={props.onUndo}
        onRedo={props.onRedo}
      />
    </div>
  </header>
)
