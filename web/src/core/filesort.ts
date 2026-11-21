import type { FileSort } from "@/core/prefs"

type Sortable = { name: string; folder: boolean; mtime: number; ctime: number }
const collator = new Intl.Collator(undefined, { numeric: true, sensitivity: "base" })

export function compare(sort: FileSort) {
  const byName = (a: Sortable, b: Sortable) => collator.compare(a.name, b.name)
  const files: (a: Sortable, b: Sortable) => number = {
    name: byName,
    "name-desc": (a: Sortable, b: Sortable) => byName(b, a),
    modified: (a: Sortable, b: Sortable) => b.mtime - a.mtime || byName(a, b),
    "modified-old": (a: Sortable, b: Sortable) => a.mtime - b.mtime || byName(a, b),
    created: (a: Sortable, b: Sortable) => b.ctime - a.ctime || byName(a, b),
    "created-old": (a: Sortable, b: Sortable) => a.ctime - b.ctime || byName(a, b),
  }[sort] ?? byName
  return (a: Sortable, b: Sortable) => (a.folder !== b.folder ? (a.folder ? -1 : 1) : a.folder ? (sort === "name-desc" ? byName(b, a) : byName(a, b)) : files(a, b))
}
