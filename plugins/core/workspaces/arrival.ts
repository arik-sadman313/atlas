import { allPanes, getTabLayout, isViewOpen, openFile, openView, placesIn, replaceHash, tabsOpenedSinceLoad, type TabLayout } from "@vaultite"

const arrival = location.hash
let wentTo: string | null = null
let arrived = false
for (const ev of ["hashchange", "popstate"]) addEventListener(ev, (e) => { if (e.isTrusted && !arrived) wentTo = location.hash })

let carried: Set<string> | null = null

export function keepingOpenedTabs(l: TabLayout | null): TabLayout | null {
  if (arrived) return l
  const now = getTabLayout(), opened = tabsOpenedSinceLoad(now)
  carried = new Set(opened.map((t) => t.id))
  if (!opened.length) return l
  const base = l ?? { tabs: [], active: "" }
  const ids = new Set(base.tabs.map((t) => t.id)), shown = new Set(base.tabs.flatMap(placesIn).map((p) => p.to))
  const added = opened.filter((t) => !ids.has(t.id) && !placesIn(t).every((p) => shown.has(p.to))).map(({ group: _, ...t }) => t)
  const tabs = [...base.tabs, ...added]
  return { ...base, tabs, active: tabs.some((t) => t.id === now.active) ? now.active : base.active }
}

export const settled = () => { arrived = true }

export function arrive() {
  settled()
  const now = getTabLayout()
  const opened = carried ?? new Set(tabsOpenedSinceLoad(now).map((t) => t.id))
  if (opened.has(now.active)) return
  const at = wentTo ?? arrival
  const m = /^#(file|view)\/([^/]+)/.exec(at)
  if (m) {
    try {
      const to = decodeURIComponent(m[2])
      if (m[1] === "file") openFile(to, { newTab: ![now, ...(now.windows ?? [])].flatMap(allPanes).some((p) => p.to === `file:${to}`) })
      else openView(to, { newTab: !isViewOpen(to) })
    } catch {}
  } else if (at.length > 1 && location.hash !== at) replaceHash(at)
}
