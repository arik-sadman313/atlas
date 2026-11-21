import { useState, lazy, Suspense } from "react"
import { FileText, PenTool } from "lucide-react"
import { definePlugin, type FileFormat } from "@vaultite"
import { createEmptyNotebook } from "../notebooks/types"

const NotebookBoard = lazy(() => import("../notebooks/NotebookBoard"))

interface PdfViewerProps {
  path: string
  text: string
  editable?: boolean
}

function PdfViewer({ path, editable = true }: PdfViewerProps) {
  const [markupMode, setMarkupMode] = useState(false)

  // Relative file path URL for embedding
  const pdfUrl = `/api/file?path=${encodeURIComponent(path)}`

  if (markupMode) {
    const notebookData = createEmptyNotebook(path.split("/").pop()?.replace(".pdf", "") || "PDF Markup")
    notebookData.pages[0].pdfSource = path
    notebookData.pages[0].template = "blank"

    return (
      <div className="relative flex flex-col h-full w-full">
        <div className="flex items-center justify-between px-3 py-1 bg-amber-50 dark:bg-amber-950/40 border-b border-amber-200 dark:border-amber-900 text-xs text-amber-800 dark:text-amber-200">
          <span>Markup Mode: Annotating {path}</span>
          <button
            onClick={() => setMarkupMode(false)}
            className="px-2 py-0.5 bg-amber-200 dark:bg-amber-900 rounded hover:opacity-80"
          >
            Exit Markup
          </button>
        </div>
        <div className="flex-1 relative">
          <Suspense fallback={<div className="p-4 text-xs text-slate-400">Loading markup tools...</div>}>
            <NotebookBoard
              text={JSON.stringify(notebookData)}
              path={path.replace(/\.pdf$/i, ".notebook")}
              editable={editable}
            />
          </Suspense>
        </div>
      </div>
    )
  }

  return (
    <div className="relative flex flex-col h-full w-full bg-slate-900">
      {/* Top action toolbar */}
      <div className="flex items-center justify-between px-4 py-2 bg-slate-800 border-b border-slate-700 text-slate-200 text-xs z-10 shadow-sm">
        <div className="flex items-center gap-2">
          <FileText className="w-4 h-4 text-rose-400" />
          <span className="font-medium truncate max-w-md">{path}</span>
        </div>
        <button
          onClick={() => setMarkupMode(true)}
          className="flex items-center gap-1.5 px-3 py-1 bg-blue-600 hover:bg-blue-500 text-white rounded font-medium shadow-sm transition-colors"
          title="Annotate PDF with Apple Pencil and highlighters"
        >
          <PenTool className="w-3.5 h-3.5" />
          <span>Annotate with Apple Pencil</span>
        </button>
      </div>

      {/* PDF Viewport */}
      <div className="flex-1 w-full h-full overflow-hidden">
        <iframe
          src={pdfUrl}
          className="w-full h-full border-none"
          title={path}
        />
      </div>
    </div>
  )
}

const format: FileFormat = {
  exts: ["pdf"],
  icon: FileText,
  tint: "var(--rose)",
  layout: "pane",
  render: (ctx) => <PdfViewer {...ctx} />,
  embed: (ctx) => <PdfViewer {...ctx} editable={false} />,
}

export default definePlugin({
  formats: { pdf: format },
})
