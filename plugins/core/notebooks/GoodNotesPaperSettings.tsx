import React from "react"
import { AlignJustify, Grid, CircleDot, FileText, Check } from "lucide-react"
import type { PageTemplate, PaperColor } from "./types"

interface GoodNotesPaperSettingsProps {
  isOpen: boolean
  onClose: () => void
  template: PageTemplate
  paperColor: PaperColor
  onChangeTemplate: (template: PageTemplate) => void
  onChangeColor: (color: PaperColor) => void
}

const TEMPLATE_OPTIONS: readonly { id: PageTemplate; label: string; icon: React.FC<{ className?: string }> }[] = [
  { id: "ruled", label: "Ruled Lines", icon: AlignJustify },
  { id: "ruled-wide", label: "Wide Ruled", icon: AlignJustify },
  { id: "grid", label: "Grid Graph", icon: Grid },
  { id: "dotted", label: "Dot Grid", icon: CircleDot },
  { id: "blank", label: "Blank Paper", icon: FileText },
  { id: "cornell", label: "Cornell Notes", icon: AlignJustify },
]

const COLOR_OPTIONS: readonly { id: PaperColor; label: string; bg: string; border: string }[] = [
  { id: "white", label: "White", bg: "#ffffff", border: "#cbd5e1" },
  { id: "cream", label: "Cream", bg: "#fefae0", border: "#e2d9b4" },
  { id: "dark", label: "Dark", bg: "#181b20", border: "#334155" },
]

const ColorSelectorSection: React.FC<{
  paperColor: PaperColor
  onChangeColor: (color: PaperColor) => void
}> = ({ paperColor, onChangeColor }) => (
  <div className="mt-3">
    <label className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-2">
      Paper Color
    </label>
    <div className="flex items-center gap-3">
      {COLOR_OPTIONS.map((c) => (
        <button
          key={c.id}
          onClick={() => onChangeColor(c.id)}
          className={`flex-1 flex items-center justify-center gap-1.5 py-1.5 px-2 rounded-xl border text-xs font-medium transition-all ${
            paperColor === c.id
              ? "ring-2 ring-blue-500 border-transparent shadow-sm"
              : "hover:scale-105"
          }`}
          style={{ backgroundColor: c.bg, borderColor: c.border }}
        >
          <span className={`text-xs ${c.id === "dark" ? "text-slate-100" : "text-slate-800"}`}>
            {c.label}
          </span>
          {paperColor === c.id && (
            <Check className={`size-3 ${c.id === "dark" ? "text-blue-400" : "text-blue-600"}`} />
          )}
        </button>
      ))}
    </div>
  </div>
)

const PatternSelectorSection: React.FC<{
  template: PageTemplate
  onChangeTemplate: (template: PageTemplate) => void
}> = ({ template, onChangeTemplate }) => (
  <div className="mt-4">
    <label className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-2">
      Page Pattern
    </label>
    <div className="grid grid-cols-2 gap-2">
      {TEMPLATE_OPTIONS.map((t) => {
        const Icon = t.icon
        const isSelected = template === t.id
        return (
          <button
            key={t.id}
            onClick={() => onChangeTemplate(t.id)}
            className={`flex items-center gap-2 p-2 rounded-xl border text-left text-xs transition-all ${
              isSelected
                ? "border-blue-500 bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 font-semibold shadow-sm"
                : "border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700 bg-slate-50/50 dark:bg-slate-900/30 text-slate-700 dark:text-slate-300"
            }`}
          >
            <Icon className="size-4 shrink-0" />
            <span className="truncate">{t.label}</span>
          </button>
        )
      })}
    </div>
  </div>
)

export const GoodNotesPaperSettings: React.FC<GoodNotesPaperSettingsProps> = ({
  isOpen,
  onClose,
  template,
  paperColor,
  onChangeTemplate,
  onChangeColor,
}) => {
  if (!isOpen) return null

  return (
    <div className="absolute top-14 left-44 z-50 w-72 bg-white dark:bg-[#1a1d24] rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 p-4 text-slate-800 dark:text-slate-100 animate-in fade-in zoom-in-95 duration-150">
      <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
        <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          Paper Settings
        </span>
        <button
          onClick={onClose}
          className="text-xs text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
        >
          Done
        </button>
      </div>

      <ColorSelectorSection paperColor={paperColor} onChangeColor={onChangeColor} />
      <PatternSelectorSection template={template} onChangeTemplate={onChangeTemplate} />
    </div>
  )
}
