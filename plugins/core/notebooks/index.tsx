import { lazy, Suspense, type ReactNode } from "react"
import { PenTool, Zap } from "lucide-react"
import { besideActive, definePlugin, freeName, getStore, openNew, plural, post, reload, type FileFormat } from "@vaultite"
import { createEmptyNotebook } from "./types"

const NotebookBoard = lazy(() => import("./NotebookBoard"))

const EMPTY = JSON.stringify(createEmptyNotebook(), null, "\t") + "\n"

const whereNew = () => besideActive("Notebooks")

async function newNotebook(folder = whereNew()) {
  const s = getStore()
  const name = s ? freeName(s.files, folder, "Notebook", ".notebook") : "Notebook"
  const f = await post<{ path: string }>("file", {
    path: `${folder ? `${folder}/` : ""}${name}.notebook`,
    text: EMPTY,
    unique: true,
  })
  await reload()
  return f.path
}

async function quickNote() {
  const s = getStore()
  const folder = "QuickNotes"
  const name = s ? freeName(s.files, folder, "QuickNote", ".notebook") : "QuickNote"
  const emptyDoc = createEmptyNotebook("QuickNote", "blank", "white")
  const f = await post<{ path: string }>("file", {
    path: `${folder}/${name}.notebook`,
    text: JSON.stringify(emptyDoc, null, "\t") + "\n",
    unique: true,
  })
  await reload()
  return f.path
}

const box = (node: ReactNode) => (
  <Suspense fallback={<div className="absolute inset-0 flex items-center justify-center text-slate-400" aria-busy>Loading notebook...</div>}>
    {node}
  </Suspense>
)

const format: FileFormat = {
  exts: ["notebook", "ink"],
  icon: PenTool,
  tint: "var(--teal)",
  json: true,
  layout: "pane",
  status: (text) => {
    try {
      const parsed = JSON.parse(text)
      const count = Array.isArray(parsed.pages) ? parsed.pages.length : 1
      return plural(count, "page")
    } catch {
      return null
    }
  },
  render: (ctx) => box(<NotebookBoard {...ctx} />),
  embed: (ctx) => box(<NotebookBoard {...ctx} editable={false} place="embed" />),
}

export default definePlugin({
  formats: { notebook: format },
  newFiles: [
    { label: "New notebook", icon: PenTool, make: newNotebook },
    { label: "QuickNote Instant Scratchpad", icon: Zap, make: quickNote },
  ],
  commands: [
    {
      id: "notebook:new",
      name: "New vector handwriting notebook",
      run: () => newNotebook().then((p) => openNew(p)),
      icon: PenTool,
    },
    {
      id: "notebook:quicknote",
      name: "QuickNote: One-tap instant scratchpad",
      run: () => quickNote().then((p) => openNew(p)),
      icon: Zap,
    },
  ],
  slash: () => [
    {
      id: "notebook:new",
      title: "Handwriting Notebook",
      section: "Drawing",
      keywords: "handwriting ink canvas notebook draw apple pencil goodnotes",
      detail: "New vector notebook",
      line: true,
      icon: PenTool,
      description: "A vector handwriting notebook with Apple Pencil support and GoodNotes tools.",
      run: async (put) => {
        const p = await newNotebook()
        put(`![[${p}]]\n`)
      },
    },
    {
      id: "notebook:quicknote",
      title: "QuickNote",
      section: "Drawing",
      keywords: "quicknote scratchpad instant notes",
      detail: "Instant handwriting scratchpad",
      line: true,
      icon: Zap,
      description: "Instant blank scratchpad canvas.",
      run: async (put) => {
        const p = await quickNote()
        put(`![[${p}]]\n`)
      },
    },
  ],
})
