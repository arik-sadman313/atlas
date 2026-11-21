import React, { useState } from "react"
import {
  BookOpen,
  X,
  FileText,
  Calendar,
  Grid,
  Music,
  Check,
} from "lucide-react"
import type {
  NotebookDocument,
  CoverStyle,
  PageTemplate,
  PageSize,
  PageOrientation,
  PaperColor,
} from "./types"
import { createEmptyNotebook } from "./types"

interface NotebookCreationModalProps {
  isOpen: boolean
  onClose: () => void
  onCreate: (notebook: NotebookDocument) => void
}

const COVER_STYLES: { id: CoverStyle; label: string; bg: string; text: string }[] = [
  { id: "notebook-classic", label: "Classic Black", bg: "#1e293b", text: "#f8fafc" },
  { id: "gradient-sunset", label: "Sunset Gradient", bg: "linear-gradient(135deg, #f97316 0%, #ec4899 100%)", text: "#ffffff" },
  { id: "marble-blue", label: "Marble Blue", bg: "linear-gradient(135deg, #2563eb 0%, #38bdf8 100%)", text: "#ffffff" },
  { id: "minimal-kraft", label: "Minimal Kraft", bg: "#d97706", text: "#ffffff" },
  { id: "academic-navy", label: "Academic Navy", bg: "#0f172a", text: "#38bdf8" },
  { id: "leather-black", label: "Fine Leather", bg: "#18181b", text: "#e4e4e7" },
]

const TEMPLATES: { id: PageTemplate; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { id: "ruled", label: "Ruled (Standard)", icon: FileText },
  { id: "ruled-wide", label: "Ruled (Wide)", icon: FileText },
  { id: "grid", label: "Squared (Grid)", icon: Grid },
  { id: "dotted", label: "Dotted (Journal)", icon: Grid },
  { id: "cornell", label: "Cornell Notes", icon: FileText },
  { id: "music-staff", label: "Music Staff", icon: Music },
  { id: "monthly-planner", label: "Monthly Planner", icon: Calendar },
  { id: "weekly-planner", label: "Weekly Planner", icon: Calendar },
  { id: "blank", label: "Blank Canvas", icon: FileText },
]

export const NotebookCreationModal: React.FC<NotebookCreationModalProps> = ({
  isOpen,
  onClose,
  onCreate,
}) => {
  const [title, setTitle] = useState("New Notebook")
  const [coverStyle, setCoverStyle] = useState<CoverStyle>("notebook-classic")
  const [template, setTemplate] = useState<PageTemplate>("ruled")
  const [pageSize, setPageSize] = useState<PageSize>("Standard")
  const [orientation, setOrientation] = useState<PageOrientation>("portrait")
  const [paperColor, setPaperColor] = useState<PaperColor>("white")

  if (!isOpen) return null

  const handleCreate = () => {
    const notebook = createEmptyNotebook(
      title.trim() || "Untitled Notebook",
      template,
      paperColor,
      coverStyle,
      pageSize,
      orientation
    )
    onCreate(notebook)
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in select-none">
      <div className="bg-white dark:bg-[#1a1d24] rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 max-w-2xl w-full max-h-[90vh] flex flex-col overflow-hidden">
        {/* Modal Header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            <h2 className="text-base font-bold text-slate-800 dark:text-slate-100">
              Create New Notebook
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-1 text-slate-400 hover:text-slate-600 rounded-lg"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Title input */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">
              Notebook Title
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 text-sm bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 font-semibold"
              placeholder="e.g. Physics Notes, Biology 101, Bullet Journal..."
            />
          </div>

          {/* 1. Cover Selection */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-2 uppercase tracking-wide">
              1. Choose Cover Design
            </label>
            <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
              {COVER_STYLES.map((c) => {
                const isSelected = coverStyle === c.id
                return (
                  <button
                    key={c.id}
                    onClick={() => setCoverStyle(c.id)}
                    className={`relative flex flex-col items-center justify-between p-2 h-28 rounded-xl border-2 transition-all ${
                      isSelected
                        ? "border-blue-500 shadow-md scale-105"
                        : "border-transparent hover:border-slate-300"
                    }`}
                    style={{ background: c.bg }}
                  >
                    <div className="w-full flex justify-end">
                      {isSelected && (
                        <div className="w-4 h-4 rounded-full bg-blue-500 text-white flex items-center justify-center">
                          <Check className="w-3 h-3 stroke-[3]" />
                        </div>
                      )}
                    </div>
                    <span
                      className="text-[10px] font-bold text-center px-1 py-0.5 rounded backdrop-blur-sm"
                      style={{ color: c.text }}
                    >
                      {c.label}
                    </span>
                  </button>
                )
              })}
            </div>
          </div>

          {/* 2. Paper Template Selection */}
          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-2 uppercase tracking-wide">
              2. Paper Template Library
            </label>
            <div className="grid grid-cols-3 gap-2.5">
              {TEMPLATES.map((t) => {
                const Icon = t.icon
                const isSelected = template === t.id
                return (
                  <button
                    key={t.id}
                    onClick={() => setTemplate(t.id)}
                    className={`flex items-center gap-2.5 p-2.5 rounded-xl border text-xs font-medium transition-all ${
                      isSelected
                        ? "border-blue-500 bg-blue-50/60 dark:bg-blue-950/40 text-blue-600 dark:text-blue-300 shadow-sm"
                        : "border-slate-200 dark:border-slate-700 hover:border-slate-300 text-slate-700 dark:text-slate-300"
                    }`}
                  >
                    <Icon className="w-4 h-4 text-slate-500" />
                    <span>{t.label}</span>
                  </button>
                )
              })}
            </div>
          </div>

          {/* 3. Paper Size & Orientation */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">
                Paper Size
              </label>
              <select
                value={pageSize}
                onChange={(e) => setPageSize(e.target.value as PageSize)}
                className="w-full px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none font-medium"
              >
                <option value="Standard">Goodnotes Standard</option>
                <option value="A4">A4 (Standard Document)</option>
                <option value="A5">A5 (Compact Journal)</option>
                <option value="A3">A3 (Large Drafting)</option>
                <option value="Letter">US Letter</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 mb-1.5 uppercase tracking-wide">
                Orientation & Paper Tone
              </label>
              <div className="flex items-center gap-2">
                <select
                  value={orientation}
                  onChange={(e) => setOrientation(e.target.value as PageOrientation)}
                  className="flex-1 px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none font-medium"
                >
                  <option value="portrait">Portrait</option>
                  <option value="landscape">Landscape</option>
                </select>
                <select
                  value={paperColor}
                  onChange={(e) => setPaperColor(e.target.value as PaperColor)}
                  className="flex-1 px-3 py-2 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-xl outline-none font-medium"
                >
                  <option value="white">White</option>
                  <option value="cream">Cream</option>
                  <option value="dark">Dark Slate</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="flex items-center justify-end gap-2 p-4 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/60">
          <button
            onClick={onClose}
            className="px-4 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800 rounded-xl"
          >
            Cancel
          </button>
          <button
            onClick={handleCreate}
            className="px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-md transition-colors"
          >
            Create Notebook
          </button>
        </div>
      </div>
    </div>
  )
}
