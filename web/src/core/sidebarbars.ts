import type { ComponentType } from "react"
import { Puzzle } from "lucide-react"
import type { HeaderItem, Plugin } from "@/core/define"
import { getPrefs, setPrefs, type Prefs } from "@/core/prefs"
import { share } from "@/core/share"
import { headerItems, hidePanel, sidebarPanels, sidebars, sideOf, type PanelOf, type Sidebars } from "@/core/plugins"
import { placeKey } from "../../../core/slots.ts"

export type SidebarBar = "header" | "foot"
export const BAR_NAMES: Record<SidebarBar, string> = { header: "header", foot: "bottom bar" }
export const PLUGINS_BUTTON = "core:plugins"

type Icon = ComponentType<{ className?: string; strokeWidth?: number }>
export type BarThing = { key: string; title: string; icon: Icon; to?: string }
  & ({ kind: "item"; item: HeaderItem; plugin: Plugin } | { kind: "panel"; of: PanelOf } | { kind: "app" })

export function barThings(disabled: string[]): Map<string, BarThing> {
  const out = new Map<string, BarThing>()
  for (const { key, item, plugin } of headerItems(disabled))
    out.set(key, { key, kind: "item", item, plugin, title: item.title ?? plugin.name, icon: plugin.icon, to: item.view && `view:${item.view}` })
  for (const of of sidebarPanels(disabled)) {
    const icon = of.panel.flyout?.icon
    if (icon && !out.has(of.key)) out.set(of.key, { key: of.key, kind: "panel", of, title: of.panel.title, icon, to: of.panel.view && `view:${of.panel.view}` })
  }
  if (!share) out.set(PLUGINS_BUTTON, { key: PLUGINS_BUTTON, kind: "app", title: "Plugins", icon: Puzzle, to: "plugins" })
  return out
}

export const canGoInBar = (key: string, disabled = getPrefs().disabled) => barThings(disabled).has(key)
export const barOnly = (key: string) => key === PLUGINS_BUTTON

export function barKeys(prefs: Pick<Prefs, "disabled" | "sidebarHeader" | "sidebarFoot"> = getPrefs()): Record<SidebarBar, string[]> {
  const { sidebarHeader: header, sidebarFoot: foot } = prefs
  return {
    header: header ?? headerItems(prefs.disabled).map((x) => x.key).filter((k) => !foot?.includes(k)),
    foot: foot ?? (share ? [] : [PLUGINS_BUTTON]).filter((k) => !header?.includes(k)),
  }
}

export function shownIn(bar: SidebarBar, prefs: Prefs, setup: Sidebars): BarThing[] {
  const things = barThings(prefs.disabled)
  return barKeys(prefs)[bar].filter((k) => !sideOf(k, setup)).flatMap((k) => things.get(k) ?? [])
}

export function barOf(key: string): SidebarBar | null {
  const keys = barKeys()
  return keys.header.includes(key) ? "header" : keys.foot.includes(key) ? "foot" : null
}

export function placeInBar(key: string, bar: SidebarBar, before: string | null = null) {
  const keys = barKeys(), out = (l: string[]) => l.filter((k) => k !== key)
  const next = { header: out(keys.header), foot: out(keys.foot) }
  next[bar] = placeKey(next[bar], key, before)
  void setPrefs({ sidebarHeader: next.header, sidebarFoot: next.foot })
  if (sideOf(key, sidebars())) hidePanel(key)
}

export function takeOutOfBars(key: string) {
  const keys = barKeys()
  if (!keys.header.includes(key) && !keys.foot.includes(key)) return
  void setPrefs({ sidebarHeader: keys.header.filter((k) => k !== key), sidebarFoot: keys.foot.filter((k) => k !== key) })
}

export function phoneItems(prefs: Prefs) {
  const keys = barKeys(prefs), on = new Set([...keys.header, ...keys.foot])
  return headerItems(prefs.disabled).filter((x) => on.has(x.key))
}
