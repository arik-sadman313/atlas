import React, { useState, useRef, useEffect } from "react"
import { Download, Image as ImageIcon, FileCode, Copy, Check } from "lucide-react"

export interface GoodNotesExportMenuProps {
  onExportPng: () => void
  onExportSvg: () => void
  onCopyPng: () => void
  onCopySvg: () => void
}

interface DropdownListProps extends GoodNotesExportMenuProps {
  copiedType: string | null
  onCopy: (type: "png" | "svg", fn: () => void) => void
  onClose: () => void
}

const ExportDropdownList: React.FC<DropdownListProps> = ({
  onExportPng,
  onExportSvg,
  onCopyPng,
  onCopySvg,
  copiedType,
  onCopy,
  onClose,
}) => (
  <div className="absolute left-0 mt-1.5 w-52 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-xl py-1.5 z-50 text-xs text-slate-700 dark:text-slate-300">
    <button
      onClick={() => { onExportPng(); onClose() }}
      className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 text-left transition-colors"
    >
      <ImageIcon className="size-3.5 text-blue-500" />
      <span>Save as PNG Image</span>
    </button>
    <button
      onClick={() => { onExportSvg(); onClose() }}
      className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 text-left transition-colors"
    >
      <FileCode className="size-3.5 text-emerald-500" />
      <span>Save as SVG Vector</span>
    </button>
    <div className="h-[1px] bg-slate-200 dark:bg-slate-800 my-1" />
    <button
      onClick={() => onCopy("png", onCopyPng)}
      className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 text-left transition-colors"
    >
      {copiedType === "png" ? <Check className="size-3.5 text-emerald-500" /> : <Copy className="size-3.5 text-slate-400" />}
      <span>{copiedType === "png" ? "Copied PNG!" : "Copy PNG to Clipboard"}</span>
    </button>
    <button
      onClick={() => onCopy("svg", onCopySvg)}
      className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-slate-100 dark:hover:bg-slate-800 text-left transition-colors"
    >
      {copiedType === "svg" ? <Check className="size-3.5 text-emerald-500" /> : <Copy className="size-3.5 text-slate-400" />}
      <span>{copiedType === "svg" ? "Copied SVG!" : "Copy SVG to Clipboard"}</span>
    </button>
  </div>
)

export const GoodNotesExportMenu: React.FC<GoodNotesExportMenuProps> = (props) => {
  const [isOpen, setIsOpen] = useState(false)
  const [copiedType, setCopiedType] = useState<string | null>(null)
  const menuRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (!isOpen) return
    const handleClickOutside = (e: MouseEvent) => {
      if (menuRef.current && e.target instanceof Node && !menuRef.current.contains(e.target)) {
        setIsOpen(false)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [isOpen])

  const handleCopy = (type: "png" | "svg", fn: () => void) => {
    fn()
    setCopiedType(type)
    setTimeout(() => { setCopiedType(null); setIsOpen(false) }, 1200)
  }

  return (
    <div className="relative" ref={menuRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`p-1.5 rounded-lg transition-colors ${
          isOpen
            ? "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300"
            : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
        }`}
        data-tip="Export Drawing"
      >
        <Download className="size-4" />
      </button>

      {isOpen && (
        <ExportDropdownList
          {...props}
          copiedType={copiedType}
          onCopy={handleCopy}
          onClose={() => setIsOpen(false)}
        />
      )}
    </div>
  )
}
