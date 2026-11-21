import { EyeOff, PanelBottom, PanelLeft, PanelRight, PanelTop } from "lucide-react"
import { dockAtEnd, sidebarPanels, sideOf } from "@/core/plugins"
import { getPrefs } from "@/core/prefs"
import { BAR_NAMES, barKeys, barOnly, barThings, placeInBar, takeOutOfBars, type BarThing, type SidebarBar as Bar } from "@/core/sidebarbars"
import { checklist, type CheckItem, type MenuItem } from "@/components/ContextMenu"
import { panelMenu } from "@/components/Sidebar"

const OTHER: Record<Bar, Bar> = { header: "foot", foot: "header" }
const ICONS: Record<Bar, typeof PanelTop> = { header: PanelTop, foot: PanelBottom }
const nameOf = (bar: Bar) => BAR_NAMES[bar][0].toUpperCase() + BAR_NAMES[bar].slice(1)

export function thingMenu(t: BarThing, bar: Bar): MenuItem[] {
  const other = OTHER[bar], own = t.kind === "panel" ? t.of.panel.menu?.() ?? [] : []
  return [
    ...own,
    { label: `Move to ${BAR_NAMES[other]}`, icon: ICONS[other], sep: own.length > 0, run: () => placeInBar(t.key, other) },
    ...(barOnly(t.key) ? [] : [
      { label: "Move to left sidebar", icon: PanelLeft, run: () => dockAtEnd(t.key, "left") },
      { label: "Move to right sidebar", icon: PanelRight, run: () => dockAtEnd(t.key, "right") },
    ]),
    { label: `Hide ${t.title}`, icon: EyeOff, sep: true, run: () => takeOutOfBars(t.key) },
    { label: nameOf(bar), icon: ICONS[bar], sep: true, run: () => {}, items: barMenu(bar) },
  ]
}

export function barMenu(bar: Bar): MenuItem[] {
  const { disabled } = getPrefs()
  const things = barThings(disabled), keys = barKeys(), other = OTHER[bar]
  const docked = new Map(sidebarPanels(disabled).map((p) => [p.key, sideOf(p.key)]))
  const choice = (t: BarThing): CheckItem => {
    const side = docked.get(t.key)
    return { key: t.key, label: t.title, icon: t.icon, hint: keys[other].includes(t.key) ? nameOf(other) : side ? `${side === "left" ? "Left" : "Right"} sidebar` : undefined }
  }
  const all = [...things.values()], here = new Set(keys[bar])
  const offOf = (panels: boolean) => all.flatMap((t) => ((t.kind === "panel") === panels && !here.has(t.key) ? [choice(t)] : []))
  return checklist(`bar:${bar}`, {
    on: keys[bar].flatMap((k) => { const t = things.get(k); return t ? [choice(t)] : [] }),
    off: [offOf(false), offOf(true)],
    set: (k, on, before) => (on ? placeInBar(k, bar, before) : takeOutOfBars(k)),
  })
}

export const barAreaMenu = (bar: Bar) => (): MenuItem[] => {
  const menu = panelMenu(), at = menu.findIndex((m) => m.label === "Customize sidebars…")
  const own: MenuItem = { label: nameOf(bar), icon: ICONS[bar], sep: true, run: () => {}, items: barMenu(bar) }
  return at < 0 ? [...menu, own] : [...menu.slice(0, at), own, { ...menu[at], sep: false }, ...menu.slice(at + 1)]
}
