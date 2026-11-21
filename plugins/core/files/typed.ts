import { Folder, FolderOpen } from "lucide-react"
import { get, getStore, isFolder, kindIcon, notify, openFile, openFolder, openOutside, outsidePaths, post, Stone, type SearchDoc } from "@vaultite"
import { inVault, typedPath } from "../../../core/typedpath.ts"

type Named = { where: "vault"; path: string; folder: boolean } | { where: "outside"; path: string; kind: "file" | "folder" | "vault" }
type Place = { root: string; home?: string }

let place: Promise<Place> | null = null
const vaultPlace = () => (place ??= get<{ current?: string | null; home?: string }>("vaults")
  .then((v): Place => ({ root: v.current ?? "", home: v.home }), (): Place => { place = null; return { root: "" } }))

async function named(typed: string): Promise<Named | null> {
  const p = typedPath(typed)
  if (p === null) return null
  const t = getStore()?.files
  const { root, home } = await vaultPlace()
  const rel = inVault(p, root, home)
  if (rel !== null && t) {
    if (rel && [...t.files, ...t.others].some((f) => f.path === rel)) return { where: "vault", path: rel, folder: false }
    if (rel === "" || isFolder(t, rel)) return { where: "vault", path: rel, folder: true }
    if (rel && t.files.some((f) => f.path === `${rel}.md`)) return { where: "vault", path: `${rel}.md`, folder: false }
  }
  const outside = outsidePaths()
  if (!/^[\\/~]|^[a-z]:[\\/]/i.test(p) || !outside) return null
  const found = await outside.kind(p).catch(() => null)
  return found && { where: "outside", ...found }
}

function open(n: Named, newTab: boolean) {
  if (n.where === "vault") return n.folder ? openFolder(n.path, { newTab }) : openFile(n.path, { newTab })
  if (n.kind !== "folder") return void openOutside(n.path)
  void post<{ path: string }>("outside/allow", { path: n.path }).then((r) => openFolder(r.path, { newTab }), (e) => notify(`Couldn't open ${n.path}: ${e instanceof Error ? e.message : String(e)}`))
}

function row(n: Named): SearchDoc {
  const base = { kind: "Path", tint: "var(--muted-foreground)", text: "", recent: 0, title: `Open ${n.path}`, run: (newTab: boolean) => open(n, newTab) }
  if (n.where === "vault") {
    return n.folder
      ? { ...base, id: `folder-${n.path}`, title: `Open ${n.path || "the vault's top folder"}`, meta: "Folder in the vault", icon: Folder }
      : { ...base, id: `file-${n.path}`, meta: "In the vault", icon: kindIcon(n.path), file: n.path }
  }
  const id = `path-${n.path}`
  if (n.kind === "vault") return { ...base, id, meta: "Vault", icon: Stone }
  if (n.kind === "folder") return { ...base, id, meta: "Folder", icon: FolderOpen }
  return { ...base, id, meta: "Outside the vault", icon: kindIcon(n.path) }
}

export async function typedRows(q: string): Promise<SearchDoc[]> {
  const n = await named(q)
  return n ? [row(n)] : []
}
