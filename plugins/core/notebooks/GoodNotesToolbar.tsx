import React, { useState } from "react"
import {
  Pen,
  Highlighter,
  Eraser,
  Lasso,
  Square,
  Circle,
  Minus,
  ArrowUpRight,
  Type,
  Sparkles,
  Image as ImageIcon,
  ChevronLeft,
  ChevronRight,
  Plus,
  Layers,
  Sliders,
} from "lucide-react"
import { GoodNotesStyleControls, type GoodNotesStyleControlsProps } from "./GoodNotesStyleControls"

export interface GoodNotesToolbarProps extends GoodNotesStyleControlsProps {
  activeTool: string
  activeForm: string
  onSelectTool: (tool: string) => void
  onSelectForm: (form: string) => void
  currentPageIndex: number
  totalPages: number
  onPrevPage: () => void
  onNextPage: () => void
  onAddPage: () => void
  onToggleDrawer: () => void
  isDrawerOpen: boolean
  onTogglePaperSettings: () => void
  onInsertImage: () => void
}

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
    >
      <ChevronRight className="size-3.5" />
    </button>
  </div>
)

const PageNavSection: React.FC<{
  currentPageIndex: number
  totalPages: number
  isDrawerOpen: boolean
  onToggleDrawer: () => void
  onPrevPage: () => void
  onNextPage: () => void
  onAddPage: () => void
  onTogglePaperSettings: () => void
}> = ({
  currentPageIndex,
  totalPages,
  isDrawerOpen,
  onToggleDrawer,
  onPrevPage,
  onNextPage,
  onAddPage,
  onTogglePaperSettings,
}) => (
  <div className="flex items-center gap-1 shrink-0">
    <button
      onClick={onToggleDrawer}
      className={`p-1.5 rounded-lg transition-colors ${
        isDrawerOpen
          ? "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300"
          : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
      }`}
      data-tip="Pages & Thumbnails"
    >
      <Layers className="size-4" />
    </button>

    <PageCounter
      currentPageIndex={currentPageIndex}
      totalPages={totalPages}
      onPrevPage={onPrevPage}
      onNextPage={onNextPage}
    />

    <button
      onClick={onAddPage}
      className="flex items-center gap-1 px-2 py-1 bg-blue-50 hover:bg-blue-100 dark:bg-blue-950/60 dark:hover:bg-blue-900/60 text-blue-600 dark:text-blue-400 rounded-lg text-xs font-semibold transition-colors"
      data-tip="Add Page After Current"
    >
      <Plus className="size-3.5" />
      <span>Page</span>
    </button>

    <button
      onClick={onTogglePaperSettings}
      className="p-1.5 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
      data-tip="Paper Template & Color"
    >
      <Sliders className="size-4" />
    </button>
  </div>
)

const FormPickerMenu: React.FC<{
  onSelectForm: (form: string) => void
  onClose: () => void
}> = ({ onSelectForm, onClose }) => {
  const options = [
    { id: "rectangle", label: "Rectangle", icon: Square },
    { id: "ellipse", label: "Circle", icon: Circle },
    { id: "arrow", label: "Arrow", icon: ArrowUpRight },
    { id: "line", label: "Line", icon: Minus },
  ]
  return (
    <div className="absolute top-11 left-0 z-50 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 p-1 flex gap-1 animate-in fade-in zoom-in-95 duration-100">
      {options.map((opt) => {
        const Icon = opt.icon
        return (
          <button
            key={opt.id}
            onClick={() => {
              onSelectForm(opt.id)
              onClose()
            }}
            className="p-1.5 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg text-slate-700 dark:text-slate-300"
            data-tip={opt.label}
          >
            <Icon className="size-4" />
          </button>
        )
      })}
    </div>
  )
}

const MainToolsGroup: React.FC<{
  activeTool: string
  onSelectTool: (tool: string) => void
}> = ({ activeTool, onSelectTool }) => {
  const buttons = [
    { id: "pen", label: "Pen", icon: Pen },
    { id: "highlighter", label: "Highlighter", icon: Highlighter },
    { id: "eraser", label: "Eraser", icon: Eraser },
    { id: "lasso", label: "Lasso", icon: Lasso },
  ]
  return (
    <>
      {buttons.map((btn) => {
        const Icon = btn.icon
        const isSelected = activeTool === btn.id
        return (
          <button
            key={btn.id}
            onClick={() => onSelectTool(btn.id)}
            className={`p-2 rounded-lg transition-all ${
              isSelected
                ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
                : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200"
            }`}
            data-tip={btn.label}
          >
            <Icon className="size-4" />
          </button>
        )
      })}
    </>
  )
}

const FormTriggerButton: React.FC<{
  activeTool: string
  activeForm: string
  showFormMenu: boolean
  onToggleFormMenu: () => void
  onSelectForm: (form: string) => void
}> = ({ activeTool, activeForm, showFormMenu, onToggleFormMenu, onSelectForm }) => (
  <div className="relative">
    <button
      onClick={onToggleFormMenu}
      className={`p-2 rounded-lg transition-all flex items-center gap-0.5 ${
        activeTool === "form"
          ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
          : "text-slate-600 dark:text-slate-400 hover:text-slate-900"
      }`}
      data-tip="Geometric Form"
    >
      {activeForm === "circle" ? (
        <Circle className="size-4" />
      ) : activeForm === "arrow" ? (
        <ArrowUpRight className="size-4" />
      ) : activeForm === "line" ? (
        <Minus className="size-4" />
      ) : (
        <Square className="size-4" />
      )}
    </button>
    {showFormMenu && (
      <FormPickerMenu onSelectForm={onSelectForm} onClose={onToggleFormMenu} />
    )}
  </div>
)

const ExtraToolsGroup: React.FC<{
  activeTool: string
  onSelectTool: (tool: string) => void
  onInsertImage: () => void
}> = ({ activeTool, onSelectTool, onInsertImage }) => (
  <>
    <button
      onClick={() => onSelectTool("text")}
      className={`p-2 rounded-lg transition-all ${
        activeTool === "text"
          ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
          : "text-slate-600 dark:text-slate-400 hover:text-slate-900"
      }`}
      data-tip="Text Note"
    >
      <Type className="size-4" />
    </button>
    <button
      onClick={() => onSelectTool("laser")}
      className={`p-2 rounded-lg transition-all ${
        activeTool === "laser"
          ? "bg-white dark:bg-slate-700 text-blue-600 dark:text-blue-400 shadow-sm"
          : "text-slate-600 dark:text-slate-400 hover:text-slate-900"
      }`}
      data-tip="Laser Pointer"
    >
      <Sparkles className="size-4" />
    </button>
    <button
      onClick={onInsertImage}
      className="p-2 rounded-lg text-slate-600 dark:text-slate-400 hover:text-slate-900 hover:bg-white/60 dark:hover:bg-slate-700/60 transition-all"
      data-tip="Insert Image"
    >
      <ImageIcon className="size-4" />
    </button>
  </>
)

const ToolPaletteSection: React.FC<{
  activeTool: string
  activeForm: string
  onSelectTool: (tool: string) => void
  onSelectForm: (form: string) => void
  onInsertImage: () => void
}> = ({ activeTool, activeForm, onSelectTool, onSelectForm, onInsertImage }) => {
  const [showFormMenu, setShowFormMenu] = useState(false)

  return (
    <div className="flex items-center gap-1 bg-slate-100/90 dark:bg-slate-800/80 p-1 rounded-xl">
      <MainToolsGroup
        activeTool={activeTool}
        onSelectTool={(t) => {
          setShowFormMenu(false)
          onSelectTool(t)
        }}
      />
      <FormTriggerButton
        activeTool={activeTool}
        activeForm={activeForm}
        showFormMenu={showFormMenu}
        onToggleFormMenu={() => {
          onSelectTool("form")
          setShowFormMenu(!showFormMenu)
        }}
        onSelectForm={(f) => {
          onSelectForm(f)
          setShowFormMenu(false)
        }}
      />
      <ExtraToolsGroup
        activeTool={activeTool}
        onSelectTool={(t) => {
          setShowFormMenu(false)
          onSelectTool(t)
        }}
        onInsertImage={onInsertImage}
      />
    </div>
  )
}

export const GoodNotesToolbar: React.FC<GoodNotesToolbarProps> = (props) => (
  <header className="h-12 bg-white/95 dark:bg-[#1a1d24]/95 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 px-3 flex items-center justify-between gap-2 shadow-sm select-none z-30 shrink-0">
    <PageNavSection
      currentPageIndex={props.currentPageIndex}
      totalPages={props.totalPages}
      isDrawerOpen={props.isDrawerOpen}
      onToggleDrawer={props.onToggleDrawer}
      onPrevPage={props.onPrevPage}
      onNextPage={props.onNextPage}
      onAddPage={props.onAddPage}
      onTogglePaperSettings={props.onTogglePaperSettings}
    />

    <ToolPaletteSection
      activeTool={props.activeTool}
      activeForm={props.activeForm}
      onSelectTool={props.onSelectTool}
      onSelectForm={props.onSelectForm}
      onInsertImage={props.onInsertImage}
    />

    <GoodNotesStyleControls
      color={props.color}
      onChangeColor={props.onChangeColor}
      strokeWidth={props.strokeWidth}
      onChangeStrokeWidth={props.onChangeStrokeWidth}
      onUndo={props.onUndo}
      onRedo={props.onRedo}
    />
  </header>
)
