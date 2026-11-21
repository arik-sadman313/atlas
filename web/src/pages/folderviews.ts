import { ArrowUpDown, Columns3, GalleryHorizontalEnd, Group, LayoutGrid, List } from "lucide-react"
import { dateText } from "@/core/data"
import { kindOf, type FileKind } from "@/core/filekinds"
import { isDesktop } from "@/core/platform"
import { getPrefs, setPrefs, type FolderGroup, type FolderView } from "@/core/prefs"
import type { MenuItem } from "@/components/ContextMenu"
import { SORTS, type FolderItem } from "@/components/FileTree"

type ViewOption = { value: FolderView; label: string; icon: typeof List }
export const VIEWS: ViewOption[] = [
  { value: "grid", label: "Grid", icon: LayoutGrid }, { value: "list", label: "List", icon: List },
  { value: "columns", label: "Columns", icon: Columns3 }, { value: "gallery", label: "Gallery", icon: GalleryHorizontalEnd },
]
const viewsFor = (desk: boolean) => (desk ? VIEWS : VIEWS.slice(0, 2))
const viewOf = (v: unknown): FolderView => VIEWS.find((o) => o.value === v)?.value ?? "list"
export const shownView = (v: unknown, desk: boolean): FolderView => {
  const view = viewOf(v)
  return desk ? view : view === "columns" ? "list" : view === "gallery" ? "grid" : view
}
export const setView = (v: FolderView) => void setPrefs({ folderView: v })

const GROUPS: { value: FolderGroup; label: string }[] = [{ value: "none", label: "None" }, { value: "kind", label: "Kind" }, { value: "modified", label: "Date modified" }]
export const groupOf = (v: unknown): FolderGroup => GROUPS.find((o) => o.value === v)?.value ?? "none"

function sortItems(): MenuItem[] {
  const { fileSort } = getPrefs()
  return SORTS.flatMap((g, k) => g.map((o, i) => ({ label: o.label, checked: fileSort === o.value, sep: k > 0 && i === 0, run: () => setPrefs({ fileSort: o.value }) })))
}
function groupItems(): MenuItem[] {
  const by = groupOf(getPrefs().folderGroup)
  return GROUPS.map((o) => ({ label: o.label, checked: by === o.value, run: () => setPrefs({ folderGroup: o.value }) }))
}
export function viewMenuItems(): MenuItem[] {
  const v = shownView(getPrefs().folderView, isDesktop())
  const icon = VIEWS.find((o) => o.value === v)!.icon
  return [
    { label: "Show as", icon, run: () => {}, items: viewsFor(isDesktop()).map((o) => ({ label: o.label, icon: o.icon, checked: v === o.value, run: () => setView(o.value) })) },
    { label: "Sort by", icon: ArrowUpDown, run: () => {}, items: sortItems() },
    { label: "Group by", icon: Group, run: () => {}, items: groupItems() },
  ]
}
export const arrangeItems = (): MenuItem[] => [
  { label: "Sort by", caption: true, run: () => {} }, ...sortItems(),
  { label: "Group by", caption: true, sep: true, run: () => {} }, ...groupItems(),
]

export type Section = { title: string; items: FolderItem[] }
const KIND_HEADS: Record<FileKind, string> = {
  markdown: "Notes", image: "Images", video: "Videos", audio: "Audio", pdf: "PDFs", code: "Code", json: "Code", notebook: "Code", binary: "Other", other: "Other",
}
const KIND_ORDER = ["Folders", "Notes", "Images", "Videos", "Audio", "PDFs", "Web pages", "Code", "Other"]
const kindHead = (path: string) => (/\.html?$/i.test(path) ? "Web pages" : KIND_HEADS[kindOf(path)])
const DAY = 86400_000
function dateHead(ms: number, today: number, year: number): [number, string] {
  const d = new Date(ms), days = Math.floor((today - new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()) / DAY)
  if (days <= 0) return [0, "Today"]
  if (days === 1) return [1, "Yesterday"]
  if (days < 7) return [2, "Previous 7 days"]
  if (days < 30) return [3, "Previous 30 days"]
  if (d.getFullYear() === year) return [100 - d.getMonth(), dateText(d, { month: "long" })]
  return [1000 + year - d.getFullYear(), String(d.getFullYear())]
}
export function sectionsOf(items: FolderItem[], by: FolderGroup): Section[] | null {
  if (by === "none") return null
  const now = new Date(), today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
  const out = new Map<string, { at: number; items: FolderItem[] }>()
  for (const n of items) {
    const [at, title] = n.folder ? [-1, "Folders"] : by === "kind" ? [KIND_ORDER.indexOf(kindHead(n.path)), kindHead(n.path)] : dateHead(n.mtime, today, now.getFullYear())
    const s = out.get(title) ?? out.set(title, { at, items: [] }).get(title)!
    s.items.push(n)
  }
  return [...out].sort((a, b) => a[1].at - b[1].at).map(([title, s]) => ({ title, items: s.items }))
}

const joined = (root: string, rest: string) => (!root ? rest : root.endsWith("/") ? root + rest : `${root}/${rest}`)
export function chainOf(root: string, folder: string) {
  if (folder === root || !folder.startsWith(root)) return [root]
  const parts = folder.slice(root ? root.length + (root.endsWith("/") ? 0 : 1) : 0).split("/")
  return [root, ...parts.map((_, i) => joined(root, parts.slice(0, i + 1).join("/")))]
}


export const outsideMenus = { tab: (_path: string): MenuItem[] => viewMenuItems() }
