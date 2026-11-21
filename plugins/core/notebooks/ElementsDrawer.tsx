import React, { useState } from "react"
import { Sparkles, Folder, Trash2, X } from "lucide-react"
import type { ElementCollection, NotebookElement } from "./types"

interface ElementsDrawerProps {
  isOpen: boolean
  onClose: () => void
  onInsertElement: (element: NotebookElement) => void
  customElements: NotebookElement[]
  onDeleteCustomElement?: (id: string) => void
}

// Built-in pre-shipped sticker collections
const BUILTIN_COLLECTIONS: ElementCollection[] = [
  {
    id: "mindmap",
    name: "Mind Map Symbols",
    icon: "Brain",
    elements: [
      {
        id: "elem_idea",
        name: "Idea Lightbulb",
        collectionId: "mindmap",
        strokes: [
          {
            id: "s_bulb",
            tool: "brush",
            color: "#f59e0b",
            size: 4,
            points: [
              { x: 30, y: 15 },
              { x: 45, y: 25 },
              { x: 40, y: 45 },
              { x: 20, y: 45 },
              { x: 15, y: 25 },
              { x: 30, y: 15 },
            ],
            createdAt: 0,
          },
        ],
      },
      {
        id: "elem_flow_box",
        name: "Decision Node",
        collectionId: "mindmap",
        strokes: [
          {
            id: "s_diamond",
            tool: "shape",
            shapeType: "polygon",
            color: "#3b82f6",
            size: 3,
            points: [
              { x: 30, y: 10 },
              { x: 50, y: 30 },
              { x: 30, y: 50 },
              { x: 10, y: 30 },
            ],
            createdAt: 0,
          },
        ],
      },
    ],
  },
  {
    id: "badges",
    name: "Sticky Badges",
    icon: "Badge",
    elements: [
      {
        id: "elem_todo",
        name: "TODO Stamp",
        collectionId: "badges",
        strokes: [
          {
            id: "s_todo",
            tool: "fountain",
            color: "#ef4444",
            size: 4,
            points: [
              { x: 10, y: 20 },
              { x: 50, y: 20 },
              { x: 50, y: 40 },
              { x: 10, y: 40 },
              { x: 10, y: 20 },
            ],
            createdAt: 0,
          },
        ],
      },
      {
        id: "elem_urgent",
        name: "URGENT Flag",
        collectionId: "badges",
        strokes: [
          {
            id: "s_flag",
            tool: "brush",
            color: "#dc2626",
            size: 5,
            points: [
              { x: 15, y: 10 },
              { x: 15, y: 50 },
              { x: 45, y: 25 },
              { x: 15, y: 10 },
            ],
            createdAt: 0,
          },
        ],
      },
    ],
  },
  {
    id: "math",
    name: "Math & Symbols",
    icon: "Sigma",
    elements: [
      {
        id: "elem_sum",
        name: "Summation Σ",
        collectionId: "math",
        strokes: [
          {
            id: "s_sigma",
            tool: "fountain",
            color: "#1e293b",
            size: 3,
            points: [
              { x: 45, y: 10 },
              { x: 15, y: 10 },
              { x: 30, y: 30 },
              { x: 15, y: 50 },
              { x: 45, y: 50 },
            ],
            createdAt: 0,
          },
        ],
      },
      {
        id: "elem_integral",
        name: "Integral ∫",
        collectionId: "math",
        strokes: [
          {
            id: "s_int",
            tool: "fountain",
            color: "#2563eb",
            size: 3,
            points: [
              { x: 35, y: 10 },
              { x: 30, y: 15 },
              { x: 25, y: 45 },
              { x: 20, y: 50 },
            ],
            createdAt: 0,
          },
        ],
      },
    ],
  },
]

export const ElementsDrawer: React.FC<ElementsDrawerProps> = ({
  isOpen,
  onClose,
  onInsertElement,
  customElements,
  onDeleteCustomElement,
}) => {
  const [activeTab, setActiveTab] = useState<string>("mindmap")

  if (!isOpen) return null

  const allCollections: ElementCollection[] = [
    ...BUILTIN_COLLECTIONS,
    {
      id: "custom",
      name: `Custom (${customElements.length})`,
      icon: "Folder",
      elements: customElements,
    },
  ]

  const activeCollection = allCollections.find((c) => c.id === activeTab) || allCollections[0]

  return (
    <div className="absolute right-0 top-12 bottom-0 w-80 bg-white dark:bg-[#1a1d24] border-l border-slate-200 dark:border-slate-800 shadow-2xl z-40 flex flex-col animate-in slide-in-from-right duration-200">
      {/* Drawer Header */}
      <div className="flex items-center justify-between p-3 border-b border-slate-200 dark:border-slate-800">
        <div className="flex items-center gap-1.5 font-bold text-xs text-slate-800 dark:text-slate-100">
          <Sparkles className="w-4 h-4 text-amber-500" />
          <span>Elements & Reusable Stickers</span>
        </div>
        <button
          onClick={onClose}
          className="p-1 text-slate-400 hover:text-slate-600 rounded"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Collection Category Tabs */}
      <div className="flex items-center gap-1 p-2 bg-slate-50 dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 overflow-x-auto text-xs">
        {allCollections.map((col) => (
          <button
            key={col.id}
            onClick={() => setActiveTab(col.id)}
            className={`px-2.5 py-1 rounded-full whitespace-nowrap font-medium transition-colors ${
              activeTab === col.id
                ? "bg-blue-600 text-white shadow-sm"
                : "text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-800"
            }`}
          >
            {col.name}
          </button>
        ))}
      </div>

      {/* Element Stickers Grid */}
      <div className="flex-1 overflow-y-auto p-4 grid grid-cols-2 gap-3">
        {activeCollection.elements.map((elem) => (
          <div
            key={elem.id}
            onClick={() => onInsertElement(elem)}
            className="group relative flex flex-col items-center justify-center p-3 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-blue-500 bg-slate-50 dark:bg-slate-800/40 cursor-pointer hover:shadow-md transition-all hover:scale-105"
          >
            {/* Element Preview SVG Icon */}
            <div className="w-16 h-16 flex items-center justify-center bg-white dark:bg-slate-900 rounded-lg shadow-sm border border-slate-100 dark:border-slate-800 mb-2">
              <svg viewBox="0 0 60 60" className="w-12 h-12">
                {elem.strokes.map((s, idx) => (
                  <path
                    key={idx}
                    d={`M${s.points.map((p) => `${p.x},${p.y}`).join(" L")}`}
                    fill="none"
                    stroke={s.color}
                    strokeWidth={s.size}
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                ))}
              </svg>
            </div>

            <span className="text-[11px] font-semibold text-slate-700 dark:text-slate-300 text-center truncate w-full">
              {elem.name}
            </span>

            {/* Delete custom element option */}
            {activeTab === "custom" && onDeleteCustomElement && (
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  onDeleteCustomElement(elem.id)
                }}
                className="absolute top-1 right-1 p-1 text-rose-400 hover:text-rose-600 opacity-0 group-hover:opacity-100 transition-opacity"
                title="Delete Element"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        ))}

        {activeCollection.elements.length === 0 && (
          <div className="col-span-2 text-center text-xs text-slate-400 py-12 flex flex-col items-center gap-2">
            <Folder className="w-8 h-8 text-slate-300 stroke-[1.5]" />
            <span>No elements in this collection yet.</span>
            <span className="text-[10px] text-slate-500">
              Use the Lasso tool to select handwriting or diagrams, then choose "Add to Elements".
            </span>
          </div>
        )}
      </div>
    </div>
  )
}
