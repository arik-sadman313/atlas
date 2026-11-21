import React, { useState } from "react"
import {
  Layers,
  Star,
  ListTree,
  RotateCw,
  Copy,
  Trash2,
  Plus,
  X,
  ChevronRight,
  Eye,
  Edit3,
} from "lucide-react"
import type { NotebookPage, NotebookOutlineItem } from "./types"

interface DocumentNavigationDrawerProps {
  isOpen: boolean
  onClose: () => void
  pages: NotebookPage[]
  currentPageIndex: number
  onSelectPage: (index: number) => void
  onAddPage: (afterIndex: number) => void
  onDuplicatePage: (index: number) => void
  onDeletePage: (index: number) => void
  onRotatePage: (index: number) => void
  onToggleBookmark: (index: number) => void
  outlines?: NotebookOutlineItem[]
  onAddOutlineItem?: (title: string, pageIndex: number) => void
  readOnly: boolean
  onToggleReadOnly: () => void
}

export const DocumentNavigationDrawer: React.FC<DocumentNavigationDrawerProps> = ({
  isOpen,
  onClose,
  pages,
  currentPageIndex,
  onSelectPage,
  onAddPage,
  onDuplicatePage,
  onDeletePage,
  onRotatePage,
  onToggleBookmark,
  outlines = [],
  onAddOutlineItem,
  readOnly,
  onToggleReadOnly,
}) => {
  const [activeTab, setActiveTab] = useState<"thumbnails" | "outlines" | "bookmarks">("thumbnails")
  const [newOutlineTitle, setNewOutlineTitle] = useState("")

  if (!isOpen) return null

  const bookmarkedPages = pages
    .map((p, idx) => ({ page: p, idx }))
    .filter(({ page }) => page.bookmarked)

  return (
    <div className="absolute left-0 top-12 bottom-0 w-80 bg-white dark:bg-[#1a1d24] border-r border-slate-200 dark:border-slate-800 shadow-2xl z-40 flex flex-col animate-in slide-in-from-left duration-200">
      {/* Top Header & Read-Only Toggle */}
      <div className="flex items-center justify-between p-3 border-b border-slate-200 dark:border-slate-800">
        <div className="flex items-center gap-1.5">
          <button
            onClick={onToggleReadOnly}
            className={`flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-lg transition-all ${
              readOnly
                ? "bg-amber-100 text-amber-900 dark:bg-amber-950 dark:text-amber-300 border border-amber-300"
                : "bg-blue-50 text-blue-700 dark:bg-blue-950 dark:text-blue-300 border border-blue-200"
            }`}
            title="Toggle Read-Only View Lock (Enables clicking hyperlinks & peeling study tape without accidental ink)"
          >
            {readOnly ? <Eye className="w-3.5 h-3.5" /> : <Edit3 className="w-3.5 h-3.5" />}
            <span>{readOnly ? "Read-Only (Lock)" : "Editing Mode"}</span>
          </button>
        </div>

        <button
          onClick={onClose}
          className="p-1 text-slate-400 hover:text-slate-600 rounded"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* 3 Navigation Tabs */}
      <div className="flex items-center border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50 text-xs">
        <button
          onClick={() => setActiveTab("thumbnails")}
          className={`flex-1 py-2 flex items-center justify-center gap-1 font-semibold border-b-2 transition-colors ${
            activeTab === "thumbnails"
              ? "border-blue-600 text-blue-600 dark:text-blue-400"
              : "border-transparent text-slate-500 hover:text-slate-700"
          }`}
        >
          <Layers className="w-3.5 h-3.5" />
          <span>Thumbnails ({pages.length})</span>
        </button>

        <button
          onClick={() => setActiveTab("outlines")}
          className={`flex-1 py-2 flex items-center justify-center gap-1 font-semibold border-b-2 transition-colors ${
            activeTab === "outlines"
              ? "border-blue-600 text-blue-600 dark:text-blue-400"
              : "border-transparent text-slate-500 hover:text-slate-700"
          }`}
        >
          <ListTree className="w-3.5 h-3.5" />
          <span>Outlines</span>
        </button>

        <button
          onClick={() => setActiveTab("bookmarks")}
          className={`flex-1 py-2 flex items-center justify-center gap-1 font-semibold border-b-2 transition-colors ${
            activeTab === "bookmarks"
              ? "border-amber-500 text-amber-600 dark:text-amber-400"
              : "border-transparent text-slate-500 hover:text-slate-700"
          }`}
        >
          <Star className="w-3.5 h-3.5" />
          <span>Favorites ({bookmarkedPages.length})</span>
        </button>
      </div>

      {/* Tab 1: Thumbnails Grid View */}
      {activeTab === "thumbnails" && (
        <div className="flex-1 overflow-y-auto p-3 grid grid-cols-2 gap-3">
          {pages.map((p, idx) => (
            <div
              key={p.id}
              onClick={() => onSelectPage(idx)}
              className={`group relative flex flex-col items-center p-2 rounded-xl cursor-pointer border transition-all ${
                idx === currentPageIndex
                  ? "border-blue-500 bg-blue-50/50 dark:bg-blue-950/30 shadow-md ring-2 ring-blue-400/30"
                  : "border-slate-200 dark:border-slate-700 hover:border-slate-300 bg-slate-50 dark:bg-slate-800/40"
              }`}
            >
              {/* Thumbnail page card */}
              <div
                className="w-full h-28 bg-white rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden relative flex flex-col items-center justify-center"
                style={{
                  backgroundColor:
                    p.paperColor === "dark" ? "#1e232a" : p.paperColor === "cream" ? "#fefae0" : "#ffffff",
                  transform: `rotate(${p.rotation || 0}deg)`,
                }}
              >
                <span className="text-[10px] text-slate-400 font-mono">
                  {p.strokes.length} strokes
                </span>
                <span className="text-[9px] text-slate-400 font-sans capitalize">
                  {p.template}
                </span>

                {p.bookmarked && (
                  <Star className="absolute top-1 right-1 w-3.5 h-3.5 fill-amber-400 text-amber-500" />
                )}
              </div>

              {/* Page Number & Action Icons */}
              <div className="flex items-center justify-between w-full mt-1.5 px-0.5 text-xs text-slate-600 dark:text-slate-400">
                <span className="font-semibold text-[11px]">Page {idx + 1}</span>

                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      onRotatePage(idx)
                    }}
                    className="p-0.5 hover:text-blue-500"
                    title="Rotate 90°"
                  >
                    <RotateCw className="w-3 h-3" />
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      onDuplicatePage(idx)
                    }}
                    className="p-0.5 hover:text-blue-500"
                    title="Duplicate Page"
                  >
                    <Copy className="w-3 h-3" />
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      onDeletePage(idx)
                    }}
                    disabled={pages.length <= 1}
                    className="p-0.5 hover:text-rose-500 disabled:opacity-20"
                    title="Delete Page"
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </div>
              </div>
            </div>
          ))}

          {/* Add Page Card */}
          <div
            onClick={() => onAddPage(pages.length - 1)}
            className="flex flex-col items-center justify-center p-4 border-2 border-dashed border-slate-300 dark:border-slate-700 hover:border-blue-500 rounded-xl cursor-pointer text-slate-400 hover:text-blue-600 transition-colors h-36"
          >
            <Plus className="w-5 h-5 mb-1" />
            <span className="text-xs font-semibold">Add Page</span>
          </div>
        </div>
      )}

      {/* Tab 2: Outlines View */}
      {activeTab === "outlines" && (
        <div className="flex-1 overflow-y-auto p-3 space-y-3">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={newOutlineTitle}
              onChange={(e) => setNewOutlineTitle(e.target.value)}
              placeholder="Outline item title..."
              className="flex-1 px-2.5 py-1 text-xs bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-lg outline-none"
            />
            <button
              onClick={() => {
                if (newOutlineTitle.trim() && onAddOutlineItem) {
                  onAddOutlineItem(newOutlineTitle.trim(), currentPageIndex)
                  setNewOutlineTitle("")
                }
              }}
              className="px-2.5 py-1 text-xs font-semibold bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Add
            </button>
          </div>

          <div className="space-y-1">
            {outlines.length > 0 ? (
              outlines.map((item) => (
                <div
                  key={item.id}
                  onClick={() => onSelectPage(item.pageIndex)}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer text-xs"
                >
                  <div className="flex items-center gap-2">
                    <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
                    <span className="font-medium text-slate-700 dark:text-slate-200">
                      {item.title}
                    </span>
                  </div>
                  <span className="text-slate-400 text-[11px]">P. {item.pageIndex + 1}</span>
                </div>
              ))
            ) : (
              <div className="text-center text-xs text-slate-400 py-12">
                No outline entries yet. Add one above to create table-of-contents shortcuts.
              </div>
            )}
          </div>
        </div>
      )}

      {/* Tab 3: Bookmarks View */}
      {activeTab === "bookmarks" && (
        <div className="flex-1 overflow-y-auto p-3 space-y-2">
          {bookmarkedPages.length > 0 ? (
            bookmarkedPages.map(({ page, idx }) => (
              <div
                key={page.id}
                onClick={() => onSelectPage(idx)}
                className="flex items-center justify-between p-2.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-amber-400 bg-slate-50 dark:bg-slate-800/40 cursor-pointer text-xs"
              >
                <div className="flex items-center gap-2">
                  <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
                  <span className="font-semibold text-slate-700 dark:text-slate-200">
                    Page {idx + 1}
                  </span>
                  <span className="text-slate-400 text-[11px]">({page.strokes.length} strokes)</span>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    onToggleBookmark(idx)
                  }}
                  className="text-xs text-slate-400 hover:text-rose-500"
                  title="Remove Bookmark"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            ))
          ) : (
            <div className="text-center text-xs text-slate-400 py-12 flex flex-col items-center gap-2">
              <Star className="w-8 h-8 text-slate-300 stroke-[1.5]" />
              <span>No bookmarked pages yet.</span>
              <span className="text-[10px] text-slate-500">
                Tap the star icon in the toolbar on any page to add it to your favorites.
              </span>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
