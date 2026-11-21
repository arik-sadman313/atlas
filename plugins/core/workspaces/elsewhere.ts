import { cleanTabLayout as clean, notify, withGroupFolded, withoutTabs } from "@vaultite"
import { current, named, patch, slots } from "./state"

const layoutOf = (n: number) => (n === current() ? null : clean(slots()?.[n - 1]?.layout))

export function foldIn(n: number, id: string) {
  const l = layoutOf(n)
  if (!l) return
  const next = { ...withGroupFolded(l, id) }
  if (l.windows) next.windows = l.windows.map((w) => withGroupFolded(w, id))
  patch(n, { layout: next })
}

export function closeIn(n: number, id: string) {
  const before = layoutOf(n)
  if (!before) return
  patch(n, { layout: withoutTabs(before, new Set([id])) })
  const after = JSON.stringify(slots()?.[n - 1]?.layout)
  notify(`Closed in ${named(n)}`, { action: { label: "Undo", run: () => { if (JSON.stringify(slots()?.[n - 1]?.layout) === after) patch(n, { layout: before }) } } })
}

export function reorderIn(n: number, order: { id: string; group?: string }[]) {
  const l = layoutOf(n)
  if (!l) return
  const byId = new Map(l.tabs.map((t) => [t.id, t]))
  const tabs = order.flatMap(({ id, group }) => {
    const t = byId.get(id)
    if (!t) return []
    const { group: _, ...rest } = t
    return [group ? { ...rest, group } : rest]
  })
  if (tabs.length === l.tabs.length) patch(n, { layout: { ...l, tabs } })
}
