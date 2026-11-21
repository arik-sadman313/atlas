import { useEffect, useMemo } from "react"
import { compare } from "@/core/filesort"
import { get } from "@/core/http"
import { getPrefs, usePrefs, type FileSort } from "@/core/prefs"
import { signal } from "@/core/signal"
import type { FolderItem } from "@/components/FileTree"
import type { Lister } from "@/pages/FolderColumns"

type Item = { name: string; folder: boolean; mtime: number; ctime: number; size: number; count?: number }
type Listed = { path: string; root: string; items: Item[] }
export type Got = { listed: Listed } | { why: string }

const lists = new Map<string, Got>()
const asking = new Set<string>()
const listed = signal()
function fetchList(folder: string) {
  if (asking.has(folder)) return
  asking.add(folder)
  get<Listed>(`outside/list?path=${encodeURIComponent(folder)}`).then((l) => lists.set(folder, { listed: l }), (e: Error) => lists.set(folder, { why: e.message }))
    .finally(() => { asking.delete(folder); listed.notify() })
}
export const useListed = (folder: string) => {
  useEffect(() => fetchList(folder), [folder])
  return listed.use(() => lists.get(folder) ?? null)
}

export const inside = (folder: string, name: string) => (folder.endsWith("/") ? folder + name : `${folder}/${name}`)
export function itemsOf(l: Listed, sort: FileSort, hidden: boolean) {
  const counts = new Map<string, number>()
  const items: FolderItem[] = []
  for (const it of l.items) {
    if (!hidden && it.name.startsWith(".")) continue
    const path = inside(l.path, it.name)
    if (it.folder) counts.set(path, it.count ?? 0)
    items.push({ path, name: it.name, folder: it.folder, other: !it.folder && !/\.md$/i.test(it.name), mtime: it.mtime, ctime: it.ctime, children: [] })
  }
  return { items: items.sort(compare(sort)), counts }
}
export const rootOf = (got: Got | null, path: string) => (got && "listed" in got ? got.listed.root : path)

function useOutsideItems(folder: string) {
  const got = useListed(folder)
  const { fileSort, showHidden } = usePrefs()
  return useMemo(() => (got && "listed" in got ? itemsOf(got.listed, fileSort, showHidden).items : null), [got, fileSort, showHidden])
}
export const listerOf = (root: string): Lister => ({
  root, useList: useOutsideItems,
  peek: (folder) => { const got = lists.get(folder), { fileSort, showHidden } = getPrefs(); return got && "listed" in got ? itemsOf(got.listed, fileSort, showHidden).items : null },
})

