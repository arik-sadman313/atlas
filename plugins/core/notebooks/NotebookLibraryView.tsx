import React, { useState } from "react"
import {
  BookOpen,
  Star,
  Users,
  ShoppingBag,
  Trash2,
  Grid,
  List,
  Search,
  Plus,
  Zap,
  ArrowUpDown,
  Download,
} from "lucide-react"
import type { NotebookDocument, PageTemplate } from "./types"
import { NotebookCreationModal } from "./NotebookCreationModal"

export interface LibraryItem {
  id: string
  name: string
  path: string
  isFolder: boolean
  updatedAt: number
  coverStyle?: string
  pageCount?: number
  bookmarked?: boolean
  shared?: boolean
  deleted?: boolean
}

interface NotebookLibraryViewProps {
  items: LibraryItem[]
  onOpenNotebook: (path: string) => void
  onCreateNotebook: (doc: NotebookDocument, folderPath?: string) => void
  onQuickNote: () => void
  onDeleteNotebook?: (path: string) => void
  onToggleBookmark?: (path: string) => void
}

type SmartViewType = "all" | "favorites" | "shared" | "marketplace" | "trash"
type SortByType = "date" | "name" | "pages"

export const NotebookLibraryView: React.FC<NotebookLibraryViewProps> = ({
  items,
  onOpenNotebook,
  onCreateNotebook,
  onQuickNote,
  onDeleteNotebook,
  onToggleBookmark,
}) => {
  const [smartView, setSmartView] = useState<SmartViewType>("all")
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid")
  const [searchQuery, setSearchQuery] = useState("")
  const [sortBy, setSortBy] = useState<SortByType>("date")
  const [currentFolder, setCurrentFolder] = useState<string>("")
  const [isCreationModalOpen, setIsCreationModalOpen] = useState(false)

  // Filter items based on smart view and current folder
  const filteredItems = items
    .filter((item) => {
      if (smartView === "trash") return item.deleted
      if (item.deleted) return false

      if (smartView === "favorites") return item.bookmarked
      if (smartView === "shared") return item.shared
      if (smartView === "marketplace") return false // marketplace has dedicated store view

      // Folder navigation check
      if (currentFolder) {
        return item.path.startsWith(currentFolder + "/")
      }
      return true
    })
    .filter((item) => {
      if (!searchQuery) return true
      return item.name.toLowerCase().includes(searchQuery.toLowerCase())
    })
    .sort((a, b) => {
      if (sortBy === "date") return b.updatedAt - a.updatedAt
      if (sortBy === "name") return a.name.localeCompare(b.name)
      if (sortBy === "pages") return (b.pageCount || 0) - (a.pageCount || 0)
      return 0
    })

  // Sample Marketplace items for downloadable planners, covers, and sticker packs
  const MARKETPLACE_PACKS = [
    {
      id: "pack_daily_planner",
      name: "2026 Minimalist Digital Planner",
      category: "Planners",
      pages: 120,
      description: "Hyperlinked monthly, weekly, and daily habit tracking with calendar links.",
      coverBg: "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)",
      color: "#38bdf8",
    },
    {
      id: "pack_cornell_student",
      name: "Cornell Academic Study System",
      category: "Templates",
      pages: 60,
      description: "Structured cue column, notes grid, and lecture summary footer.",
      coverBg: "linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)",
      color: "#93c5fd",
    },
    {
      id: "pack_stickers_aesthetic",
      name: "Pastel Productivity Sticker Pack",
      category: "Stickers",
      pages: 24,
      description: "Over 80 vector sticky badges, checkboxes, stars, and labels.",
      coverBg: "linear-gradient(135deg, #d97706 0%, #f59e0b 100%)",
      color: "#fde68a",
    },
  ]

  return (
    <div className="flex h-full w-full bg-slate-50 dark:bg-[#121418] text-slate-800 dark:text-slate-100 font-sans select-none overflow-hidden">
      {/* 1. Left Sidebar: Infinite Nested Hierarchy & Smart Views */}
      <div className="w-64 bg-white dark:bg-[#181b22] border-r border-slate-200 dark:border-slate-800 flex flex-col p-3 space-y-4">
        {/* Quick Actions */}
        <div className="space-y-1.5">
          <button
            onClick={onQuickNote}
            className="w-full flex items-center justify-center gap-2 py-2 px-3 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-white font-bold text-xs rounded-xl shadow-md transition-all active:scale-95"
            title="One-Tap Instant Scratchpad"
          >
            <Zap className="w-4 h-4 fill-current" />
            <span>QuickNote Scratchpad</span>
          </button>

          <button
            onClick={() => setIsCreationModalOpen(true)}
            className="w-full flex items-center justify-center gap-2 py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl shadow-md transition-all active:scale-95"
          >
            <Plus className="w-4 h-4" />
            <span>New Notebook</span>
          </button>
        </div>

        {/* Smart Views Navigation */}
        <div className="space-y-1">
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 px-2">
            Smart Views
          </span>

          <button
            onClick={() => {
              setSmartView("all")
              setCurrentFolder("")
            }}
            className={`w-full flex items-center gap-2.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              smartView === "all"
                ? "bg-blue-50 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400"
                : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            }`}
          >
            <BookOpen className="w-4 h-4" />
            <span>All Documents</span>
          </button>

          <button
            onClick={() => setSmartView("favorites")}
            className={`w-full flex items-center gap-2.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              smartView === "favorites"
                ? "bg-amber-50 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400"
                : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            }`}
          >
            <Star className="w-4 h-4 text-amber-500" />
            <span>Favorites</span>
          </button>

          <button
            onClick={() => setSmartView("shared")}
            className={`w-full flex items-center gap-2.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              smartView === "shared"
                ? "bg-purple-50 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400"
                : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            }`}
          >
            <Users className="w-4 h-4 text-purple-500" />
            <span>Shared Notebooks</span>
          </button>

          <button
            onClick={() => setSmartView("marketplace")}
            className={`w-full flex items-center gap-2.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              smartView === "marketplace"
                ? "bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400"
                : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            }`}
          >
            <ShoppingBag className="w-4 h-4 text-emerald-500" />
            <span>Marketplace Store</span>
          </button>

          <button
            onClick={() => setSmartView("trash")}
            className={`w-full flex items-center gap-2.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              smartView === "trash"
                ? "bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400"
                : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            }`}
          >
            <Trash2 className="w-4 h-4 text-rose-500" />
            <span>Trash Recovery Bin</span>
          </button>
        </div>
      </div>

      {/* 2. Main Library Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Control Bar: Search, Sort, View Modes */}
        <div className="flex items-center justify-between px-6 py-3 bg-white dark:bg-[#1a1d24] border-b border-slate-200 dark:border-slate-800">
          {/* Search Input */}
          <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl w-72 text-xs">
            <Search className="w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search notebooks, planners, pages..."
              className="w-full bg-transparent outline-none text-slate-800 dark:text-slate-200"
            />
          </div>

          {/* Right Toolbar: Sort & Grid/List View Toggles */}
          <div className="flex items-center gap-3">
            {/* Sort selector */}
            <div className="flex items-center gap-1 text-xs text-slate-500">
              <ArrowUpDown className="w-3.5 h-3.5" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortByType)}
                className="bg-transparent font-medium outline-none cursor-pointer"
              >
                <option value="date">Date Modified</option>
                <option value="name">Name</option>
                <option value="pages">Page Count</option>
              </select>
            </div>

            {/* Grid / List View Toggle */}
            <div className="flex items-center bg-slate-100 dark:bg-slate-800 p-0.5 rounded-lg border border-slate-200 dark:border-slate-700">
              <button
                onClick={() => setViewMode("grid")}
                className={`p-1 rounded ${viewMode === "grid" ? "bg-white dark:bg-slate-700 shadow-sm text-blue-600" : "text-slate-400"}`}
                title="Grid View"
              >
                <Grid className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode("list")}
                className={`p-1 rounded ${viewMode === "list" ? "bg-white dark:bg-slate-700 shadow-sm text-blue-600" : "text-slate-400"}`}
                title="List View"
              >
                <List className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Library Content Viewport */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* Marketplace View */}
          {smartView === "marketplace" ? (
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-bold">GoodNotes Community Marketplace</h3>
                <p className="text-xs text-slate-500 mt-1">
                  Download professional planners, Cornell paper kits, and vector sticker packs directly into your notebooks.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {MARKETPLACE_PACKS.map((pack) => (
                  <div
                    key={pack.id}
                    className="flex flex-col bg-white dark:bg-[#1a1d24] rounded-2xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm hover:shadow-lg transition-all"
                  >
                    <div
                      className="h-36 flex flex-col justify-end p-4 text-white relative"
                      style={{ background: pack.coverBg }}
                    >
                      <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2 py-0.5 rounded-full w-max backdrop-blur-md">
                        {pack.category}
                      </span>
                      <h4 className="font-bold text-sm mt-1">{pack.name}</h4>
                    </div>
                    <div className="p-4 flex-1 flex flex-col justify-between">
                      <p className="text-xs text-slate-500 mb-4">{pack.description}</p>
                      <button
                        onClick={() => {
                          const doc = {
                            version: 1,
                            title: pack.name,
                            createdAt: Date.now(),
                            updatedAt: Date.now(),
                            cover: { style: "notebook-classic" as any, title: pack.name, color: pack.color },
                            pages: [
                              {
                                id: `page_${Date.now()}`,
                                pageNumber: 1,
                                template: "ruled" as PageTemplate,
                                paperColor: "white" as any,
                                strokes: [],
                                textBoxes: [],
                                width: 800,
                                height: 1100,
                              },
                            ],
                          }
                          onCreateNotebook(doc)
                        }}
                        className="flex items-center justify-center gap-1.5 w-full py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-semibold shadow-sm transition-colors"
                      >
                        <Download className="w-3.5 h-3.5" />
                        <span>Download to Library</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            /* Document List / Grid View */
            <div>
              {viewMode === "grid" ? (
                <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-5 gap-6">
                  {filteredItems.map((item) => (
                    <div
                      key={item.id}
                      onClick={() => onOpenNotebook(item.path)}
                      className="group relative flex flex-col items-center cursor-pointer"
                    >
                      {/* Notebook Cover Card */}
                      <div className="w-full aspect-[3/4] bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl shadow-md group-hover:shadow-xl group-hover:scale-105 transition-all p-3 flex flex-col justify-between border border-slate-700/50 relative overflow-hidden">
                        {/* Bookmark Star */}
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            onToggleBookmark?.(item.path)
                          }}
                          className="absolute top-2 right-2 p-1"
                        >
                          <Star
                            className={`w-4 h-4 ${
                              item.bookmarked
                                ? "fill-amber-400 text-amber-500"
                                : "text-slate-400 hover:text-amber-400"
                            }`}
                          />
                        </button>

                        <div className="text-right">
                          <span className="text-[10px] text-slate-400 font-mono">
                            {item.pageCount || 1} pages
                          </span>
                        </div>

                        <div className="border-t border-slate-600/60 pt-2">
                          <h4 className="text-white text-xs font-bold truncate">
                            {item.name}
                          </h4>
                          <span className="text-[10px] text-slate-400">
                            {new Date(item.updatedAt).toLocaleDateString()}
                          </span>
                        </div>
                      </div>

                      {/* Title Below */}
                      <span className="mt-2 text-xs font-semibold text-slate-700 dark:text-slate-300 truncate w-full text-center">
                        {item.name}
                      </span>
                    </div>
                  ))}

                  {/* New Notebook Placeholder Card */}
                  <div
                    onClick={() => setIsCreationModalOpen(true)}
                    className="aspect-[3/4] rounded-2xl border-2 border-dashed border-slate-300 dark:border-slate-700 hover:border-blue-500 flex flex-col items-center justify-center cursor-pointer text-slate-400 hover:text-blue-500 transition-colors"
                  >
                    <Plus className="w-8 h-8 mb-2" />
                    <span className="text-xs font-bold">New Notebook</span>
                  </div>
                </div>
              ) : (
                /* List View */
                <div className="bg-white dark:bg-[#1a1d24] rounded-2xl border border-slate-200 dark:border-slate-800 divide-y divide-slate-100 dark:divide-slate-800">
                  {filteredItems.map((item) => (
                    <div
                      key={item.id}
                      onClick={() => onOpenNotebook(item.path)}
                      className="flex items-center justify-between p-3.5 hover:bg-slate-50 dark:hover:bg-slate-800/50 cursor-pointer text-xs"
                    >
                      <div className="flex items-center gap-3">
                        <BookOpen className="w-5 h-5 text-blue-500" />
                        <div>
                          <h4 className="font-semibold text-slate-800 dark:text-slate-100">
                            {item.name}
                          </h4>
                          <span className="text-[11px] text-slate-400">
                            {item.pageCount || 1} pages • {item.path}
                          </span>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 text-slate-400">
                        <span>{new Date(item.updatedAt).toLocaleDateString()}</span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            onToggleBookmark?.(item.path)
                          }}
                          className="p-1"
                        >
                          <Star
                            className={`w-4 h-4 ${
                              item.bookmarked
                                ? "fill-amber-400 text-amber-500"
                                : "text-slate-400 hover:text-amber-400"
                            }`}
                          />
                        </button>
                        {onDeleteNotebook && (
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              onDeleteNotebook(item.path)
                            }}
                            className="p-1 hover:text-rose-500"
                            title="Delete"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Creation Modal */}
      <NotebookCreationModal
        isOpen={isCreationModalOpen}
        onClose={() => setIsCreationModalOpen(false)}
        onCreate={(doc) => onCreateNotebook(doc, currentFolder)}
      />
    </div>
  )
}
