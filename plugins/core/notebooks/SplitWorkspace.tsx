import React from "react"
import { Columns2, X, Plus, BookOpen, FileText } from "lucide-react"

export interface WorkspaceTab {
  id: string
  title: string
  path: string
  isPdf?: boolean
}

interface SplitWorkspaceProps {
  tabs: WorkspaceTab[]
  activeTabId: string
  onSelectTab: (tabId: string) => void
  onCloseTab: (tabId: string) => void
  onNewTab: () => void
  isSplitView: boolean
  onToggleSplitView: () => void
  leftContent: React.ReactNode
  rightContent?: React.ReactNode
}

export const SplitWorkspace: React.FC<SplitWorkspaceProps> = ({
  tabs,
  activeTabId,
  onSelectTab,
  onCloseTab,
  onNewTab,
  isSplitView,
  onToggleSplitView,
  leftContent,
  rightContent,
}) => {
  return (
    <div className="flex flex-col h-full w-full overflow-hidden font-sans select-none">
      {/* Top Browser-style Tab Bar */}
      <div className="flex items-center justify-between px-2 bg-slate-200/80 dark:bg-[#15181e] border-b border-slate-300 dark:border-slate-800 text-xs">
        {/* Scrollable Tabs List */}
        <div className="flex items-center gap-1 overflow-x-auto py-1">
          {tabs.map((tab) => {
            const isActive = tab.id === activeTabId
            return (
              <div
                key={tab.id}
                onClick={() => onSelectTab(tab.id)}
                className={`group flex items-center gap-2 px-3 py-1.5 rounded-t-lg cursor-pointer border-t-2 transition-all ${
                  isActive
                    ? "bg-white dark:bg-[#1a1d24] border-blue-600 text-blue-600 dark:text-blue-400 font-bold shadow-sm"
                    : "border-transparent text-slate-600 dark:text-slate-400 hover:bg-slate-300/50 dark:hover:bg-slate-800"
                }`}
              >
                {tab.isPdf ? (
                  <FileText className="w-3.5 h-3.5 text-rose-500" />
                ) : (
                  <BookOpen className="w-3.5 h-3.5 text-blue-500" />
                )}
                <span className="truncate max-w-[140px]">{tab.title}</span>

                {tabs.length > 1 && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      onCloseTab(tab.id)
                    }}
                    className="p-0.5 rounded hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-400 hover:text-slate-600 opacity-60 group-hover:opacity-100"
                  >
                    <X className="w-3 h-3" />
                  </button>
                )}
              </div>
            )
          })}

          <button
            onClick={onNewTab}
            className="p-1 text-slate-500 hover:text-slate-800 dark:hover:text-slate-200 hover:bg-slate-300/60 dark:hover:bg-slate-800 rounded-lg ml-1"
            title="Open New Tab"
          >
            <Plus className="w-4 h-4" />
          </button>
        </div>

        {/* Side-by-Side Split View Toggle */}
        <button
          onClick={onToggleSplitView}
          className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold transition-all ${
            isSplitView
              ? "bg-blue-600 text-white shadow-sm"
              : "text-slate-600 dark:text-slate-300 hover:bg-slate-300/60 dark:hover:bg-slate-800"
          }`}
          title="Toggle Side-by-Side Split View"
        >
          <Columns2 className="w-4 h-4" />
          <span>{isSplitView ? "Close Split" : "Split View"}</span>
        </button>
      </div>

      {/* Main Document Panes */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left Document Pane */}
        <div className={`h-full overflow-hidden ${isSplitView ? "w-1/2 border-r border-slate-300 dark:border-slate-800" : "w-full"}`}>
          {leftContent}
        </div>

        {/* Right Split Document Pane (when active) */}
        {isSplitView && (
          <div className="w-1/2 h-full overflow-hidden">
            {rightContent || (
              <div className="flex flex-col items-center justify-center h-full text-slate-400 text-xs">
                <span>Select a second notebook or PDF to view side-by-side</span>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
