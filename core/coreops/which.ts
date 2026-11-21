import type { App } from "../app.ts"
import { closest, type Findable } from "../appmatch.ts"
import { commandList, panelsOf, viewsOf } from "../appsource.ts"
import { settingsOf } from "../blocks.ts"
import { topics } from "../docs.ts"
import { tree } from "../files.ts"
import { defineOp, type Op } from "../ops.ts"
import { panelList } from "./panels.ts"
import { onOff, pluginList } from "./plugins.ts"

type SidebarPanel = { key: string; hiddenFromSidebars: boolean }
export type Found = { kind: "page" | "setting" | "command" | "operation" | "docs" | "folder" | "file"; title: string; plugin: string | null; pluginOff: boolean
  summary: string | null; panel: SidebarPanel | null; how: string }
type Entry = Found & Findable

function pages(app: App, on: (id: string) => boolean): Entry[] {
  const plugins = pluginList(app), names = new Map(plugins.map((p) => [p.id, p.name]))
  const shown = new Set(panelList(app).panels.filter((p) => p.side).map((p) => p.key))
  const panelOf = new Map(plugins.flatMap((p) => panelsOf(p)).flatMap((d) => (d.view ? [[d.view, d] as const] : [])))
  return plugins.flatMap((p) => viewsOf(p)).map((v): Entry => {
    const d = panelOf.get(v.name)
    return { kind: "page", weight: 6, title: d?.title ?? v.title, names: [v.title, v.name, ...(d?.names ?? [])], about: names.get(v.plugin), plugin: v.plugin,
      pluginOff: !on(v.plugin), summary: null, panel: d ? { key: d.key, hiddenFromSidebars: !shown.has(d.key) } : null, how: `vau open view:${v.name}` }
  })
}

const settings = (app: App, on: (id: string) => boolean): Entry[] =>
  app.plugins.flatMap((p) => Object.entries(settingsOf(p.manifest)).map(([key, d]): Entry => ({ kind: "setting", weight: 4, title: d.label || key, names: [key],
    about: `${d.description} ${p.manifest.name ?? p.id}`, plugin: p.id, pluginOff: !on(p.id), summary: null, panel: null, how: `vau settings show ${p.id}.${key}` })))

const shownPath = (p: string) => !p.split("/").some((x) => x.startsWith("."))
const named = (p: string) => p.split("/").pop()!.replace(/\.md$/i, "")
function vaultEntries(app: App): Entry[] {
  const place = (kind: "folder" | "file", path: string, weight: number): Entry => ({ kind, weight, title: path, names: [`${named(path)} ${kind === "folder" ? "folder" : "note"}`], plugin: null, pluginOff: false,
    summary: null, panel: null, how: `vau open "${path}"` })
  return [...app.vault.folders.filter(shownPath).map((p) => place("folder", p, 5)), ...tree(app.vault).files.map((f) => f.path).filter(shownPath).map((p) => place("file", p, 1))]
}

function everything(app: App): Entry[] {
  const plugins = pluginList(app), { on } = onOff(plugins, app.vault.config("plugins")), ids = new Set(plugins.map((p) => p.id))
  const commands = commandList(plugins.filter((p) => p.tier === "vault")).map((c): Entry => {
    const plugin = c.id.split(":")[0]
    return { kind: "command", weight: 2, title: c.name, names: [c.id], plugin: null, pluginOff: ids.has(plugin) && !on(plugin), summary: null, panel: null, how: `vau command ${c.id}` }
  })
  const ops = app.catalog().map((e): Entry => ({ kind: "operation", title: e.cli ?? e.id.replace(/[.-]/g, " "), names: [e.id], about: e.summary, summary: e.summary,
    plugin: e.plugin, pluginOff: false, panel: null, how: e.cli ? `vau ${e.cli}` : `vau ${e.id}` }))
  const docs = topics(app.plugins).map((t): Entry => ({ kind: "docs", title: t.title, names: [t.id], about: t.text, plugin: t.plugin, pluginOff: false, summary: null,
    panel: null, how: `vau docs ${t.id}` }))
  return [...pages(app, on), ...settings(app, on), ...commands, ...ops, ...docs, ...vaultEntries(app)]
}

const panelText = (p: SidebarPanel | null) => (p ? `, also the sidebar panel ${p.key}${p.hiddenFromSidebars ? " (hidden from the sidebars now)" : ""}` : "")
const line = (f: Found) => `- ${f.kind} "${f.title}"${f.summary ? ` (${f.summary})` : ""}${f.plugin ? ` (${f.plugin}${f.pluginOff ? ", its plugin is off" : ""})` : ""}` +
  `${panelText(f.panel)}: ${f.how}`

export function whichOps(app: App): Op[] {
  return [defineOp({
    id: "app.which",
    cli: "which",
    mcp: "which",
    summary: "Which part of the app or the vault is something, or does it: pages (views and sidebar panels, hidden ones too), settings, commands, operations, docs, and the vault's folders and notes by name, best first.",
    help: `For "which page shows my logins?", "is there a setting for...", "can it pin a folder?", "open the KMF folder":
looks in what the app registers (every plugin's views and sidebar panels, settings, palette commands, operations and
docs topics) and the vault's folders and notes by their names (what's in notes: vau search). Each match says how to
get there or do it: vau open view:<name> for a page, vau open <path> for a folder or note, vau settings show for a
setting, vau command for a command, the operation's own command. Say something doesn't exist, or can't be done,
only when this finds nothing for it; else try what it found and say what happened.

  vau which "logins and containers"
  vau which "pin a folder"
  vau which kmf`,
    kind: "read",
    params: { words: { type: "string", required: true, description: "what it shows or does, in a few words (logins, dark mode, scheduled jobs)" } },
    args: ["words"],
    run: ({ words }) => closest(String(words), everything(app), 8).map(({ names: _, about: __, weight: ___, ...f }) => f),
    text: (rows, p) => [rows.length ? rows.map(line).join("\n")
      : `Nothing in the app matches "${String(p.words)}": no page, sidebar panel, setting, command, operation or docs topic. Try other words for what it shows.`,
    ...(rows.some((r) => r.kind === "setting") ? [] : [`Settings the app draws itself (appearance, the editor) aren't listed here: vau settings show "${String(p.words)}" finds one by its words.`])].join("\n"),
  })]
}
