import { getPrefs } from "@/core/prefs"
import { isEnabled, PLUGINS, viewFor } from "@/core/plugins"
import { closest } from "../../../core/appmatch.ts"
import type { SplitTo } from "../../../core/splitto.ts"
import type { UiAction } from "@/core/liveMessage"

type Openable = { title: string; names: string[]; target: string; panel?: string; off: boolean }

function openables(): Openable[] {
  const disabled = getPrefs().disabled, out = new Map<string, Openable>()
  for (const p of PLUGINS) {
    const off = !isEnabled(p.id, disabled)
    for (const name of Object.keys(p.views ?? {})) {
      const title = viewFor(`view:${name}`, disabled)?.def.title("") || name
      out.set(name, { title, names: [name], target: `view:${name}`, off })
    }
    for (const [name, s] of Object.entries(p.sidebar ?? {})) {
      const v = s.view && out.get(s.view)
      if (v) Object.assign(v, { title: s.title, names: [...v.names, v.title, ...(s.names ?? [])], panel: `${p.id}:${name}` })
    }
  }
  return [...out.values()]
}

const said = (o: Openable) => `${o.title}: ${o.target}${o.panel ? ` (the sidebar panel ${o.panel})` : ""}${o.off ? ", its plugin is off" : ""}`

export function openableTarget(path: string): string {
  const bare = path.replace(/^view:/, "")
  if (/^[\w-]+:[\w-]+$/.test(bare)) {
    const [plugin, name] = bare.split(":"), view = PLUGINS.find((p) => p.id === plugin)?.sidebar?.[name]?.view
    if (view) return `view:${view}`
  }
  if (!path.startsWith("view:") || viewFor(path, getPrefs().disabled)) return path
  const name = bare.split("/")[0], near = closest(name.replace(/-/g, " "), openables(), 3)
  throw new Error(`no view is called "${name}", so nothing opened${near.length ? `; the closest: ${near.map(said).join("; ")}` : ""} (vau which <words> finds a page by what it shows)`)
}

const DRAWS = "iframe, webview, video, audio, img, canvas, input, textarea, [contenteditable], .cm-editor, .xterm"
const SKIP = "[data-view-bar], [data-tab-heading], [hidden], [aria-hidden=true]"
function textIn(e: Element): string {
  let out = ""
  for (const n of e.childNodes) {
    if (n.nodeType === Node.TEXT_NODE) out += n.textContent ?? ""
    else if (n instanceof Element && !n.matches(SKIP)) out += ` ${textIn(n)}`
  }
  return out
}

export function paneBlank(pane: string): string | null {
  const box = document.querySelector(`[data-pane="${CSS.escape(pane)}"]`)
  if (!box) return null
  const holder = box.querySelector("[data-placeholder]")
  if (holder) return `a placeholder: "${holder.textContent?.trim() ?? ""}"`
  return box.querySelector(DRAWS) || textIn(box).trim() ? null : "nothing but its title: an empty page"
}

export async function blankAfterDrawing(pane: string | null, ms = 1500): Promise<string | null> {
  if (!pane) return null
  for (const until = Date.now() + ms; ;) {
    await new Promise((done) => setTimeout(done, 100))
    const why = paneBlank(pane)
    if (!why || Date.now() >= until) return why
  }
}

type Open = (path: string, split?: SplitTo | null, newTab?: boolean, background?: boolean, container?: string | null, into?: string | null) => { pane: string | null; to: string }
export async function openChecked(m: UiAction & { path: string }, open: Open) {
  const at = open(/^https?:\/\//i.test(m.path) ? m.path : openableTarget(m.path), m.split, !!m.newTab, !!m.background, m.container, m.in)
  const blank = m.background ? null : await blankAfterDrawing(at.pane)
  return blank ? { ...at, blank } : at
}
