import { useContext, useLayoutEffect, useMemo, useRef, useState, type ReactNode } from "react"
import { Folder, Laptop, RefreshCw, Server, ShieldAlert } from "lucide-react"
import { dateText, PreviewLive, reload, type Store } from "@/core/data"
import { mockLive, mockStore } from "@/core/mock"
import { Zoomed } from "@/components/PreviewCard"
import { noteParts } from "@/core/frontmatter"
import { allowPlugin, autoUpdating, hostOf, isEnabled, names, pageViewOf, pluginById, rollbackPlugin, setAutoUpdate, setSwitch, switchedOn, templatesOf, tileTint,
  updatePlugin, usePluginsVersion, type Plugin } from "@/core/plugins"
import { op } from "@/core/http"
import { updatable, type Update } from "../../../core/updates.ts"
import { categoryOf } from "../../../core/categories.ts"
import { openWebLink } from "@/core/links"
import { disclosed } from "../../../core/pluginmeta.ts"
import { usePrefs } from "@/core/prefs"
import { hasSettings, settingsFile } from "@/core/pluginSettings"
import { openFile } from "@/core/files"
import { showInTree } from "@/components/FileTree"
import { PluginSettings, Where } from "@/components/PluginSettings"
import { Catch } from "@/components/Guard"
import { confirmDialog } from "@/components/ConfirmDialog"
import { notify, notifyError } from "@/core/notify"
import { closeDetail } from "@/core/nav"
import { DenseRows, ErrorDetails, Group, IconTile, KV, Section, SettingRow } from "@/components/kit"
import { Switch } from "@/components/Switch"
import { PluginParts } from "@/components/PluginParts"
import { brief } from "@/core/brief"
import { plainError } from "../../../core/plainerror.ts"
import { TITLE, TitleRow } from "@/components/FileTitle"
import { capitalize, cn } from "@/lib/utils"
import { Button } from "@/components/Button"
import { isDesktop } from "@/core/platform"

const noPreview = () => <p className="p-6 text-center text-[15px] text-muted-foreground">No preview for this one yet.</p>

function preview(p: Plugin, s: Store, disabled: string[]): ReactNode {
  if (typeof p.preview === "function") return p.preview(s)
  const pages = templatesOf(typeof p.preview === "string" ? p.preview : p.id)
  if (!pages.length) return null
  const on = [...disabled.filter((id) => id !== p.id && !(p.requires ?? []).includes(id)), ...[p.id, ...(p.requires ?? [])].map((id) => `!${id}`)]
  const view = pageViewOf("dashboard")
  if (!view) return null
  return pages.map(({ name, text }) => {
    const { fm: props, body } = noteParts(text)
    return (
      <div key={name}>
        <div className="mb-4 md:pt-6"><TitleRow icon={props.icon} tint={props.tint}><h1 className={TITLE}>{name}</h1></TitleRow></div>
        {view.render({ store: s, path: `Dashboards/${name}.md`, fm: props, body, title: name, place: "page", disabled: on })}
      </div>
    )
  })
}

function Frame({ children }: { children: ReactNode }) {
  const box = useRef<HTMLDivElement>(null)
  const [w, setW] = useState(0)
  const inner = isDesktop() ? 960 : 390
  useLayoutEffect(() => {
    if (!box.current) return
    const ro = new ResizeObserver(([e]) => setW(e.contentRect.width))
    ro.observe(box.current)
    return () => ro.disconnect()
  }, [])
  return (
    // A scrollbar coming narrows the frame, shrinks the zoomed page and goes again, a flicker: its room is always kept.
    // The zoom rounds, so nothing may scroll sideways.
    <div ref={box} className="max-h-[300px] min-h-24 overflow-x-hidden overflow-y-auto overscroll-contain rounded-card border-[0.5px] border-border bg-background [scrollbar-gutter:stable]">
      {w > 0 && (
        <Zoomed inner={inner} width={w} className="p-4">{children}</Zoomed>
      )}
    </div>
  )
}

function Kept({ plugin, files }: { plugin: Plugin; files: string[] }) {
  const folder = plugin.folder
  if (folder) return <div className="px-3"><Where path={folder} lead="Kept in" icon={Folder} open={() => showInTree(folder)} /></div>
  if (!files.includes(plugin.id)) return null
  const file = settingsFile(plugin.id)
  return <div className="px-3"><Where path={file} lead="Settings kept in" open={() => openFile(file)} /></div>
}


const BOX = "rounded-card bg-foreground/[0.04] px-3 py-3"

function Updating({ plugin }: { plugin: Plugin }) {
  const m = plugin.meta!
  return (
    <div className={cn(BOX, "flex items-center gap-2.5")} data-plugin-updating={plugin.id}>
      <RefreshCw className="size-[18px] shrink-0 animate-spin text-muted-foreground" strokeWidth={2} />
      <p className="text-[15px] leading-[20px] md:text-[13px] md:leading-[18px]">
        Updating to {m.version}: checking it matches {m.source?.repo ?? "its source"} before it runs on this machine.
      </p>
    </div>
  )
}

function Approval({ plugin }: { plugin: Plugin }) {
  // Its own component: the state can change while shown, and Waiting's hooks must not come and go.
  return plugin.meta!.approval!.state === "updating" ? <Updating plugin={plugin} /> : <Waiting plugin={plugin} />
}

function Waiting({ plugin }: { plugin: Plugin }) {
  const a = plugin.meta!.approval!
  const says = disclosed(plugin.meta!.disclosures)
  const [all, setAll] = useState(false)
  const shown = all ? a.changed : a.changed.slice(0, 8)
  const host = plugin.tier === "hosted" ? hostOf(plugin) : null
  const [busy, setBusy] = useState<"allow" | "off" | null>(null)
  const run = async (what: "allow" | "off", f: () => Promise<boolean | void>) => { setBusy(what); try { await f() } finally { setBusy(null) } }
  return (
    <div className={BOX} data-plugin-approval={plugin.id}>
      <div className="flex items-center gap-2 text-[15px] font-medium">
        <ShieldAlert className="size-[18px] shrink-0 text-[var(--orange)]" strokeWidth={2} />
        {a.state === "changed" ? "Changed since you allowed it" : "Waiting for you to allow it on this machine"}
      </div>
      <p className="mt-1 text-[14px] leading-[19px] text-muted-foreground md:text-[13px] md:leading-[18px]">
        {host ? host.trust ?? "It runs code on this machine."
          : a.state === "moved" ? "It was part of the app and moved to Vaultite's plugins: it's installed from there, with your settings."
          : a.state === "new" ? "It's on in this vault, but this machine hasn't run it: it came by sync, a shared vault or a bundle."
          : `Its files changed since you allowed ${a.since ? `version ${a.since}` : "it"}, here or wherever the vault syncs.`}{host ? "" : " It runs code on this machine, so nothing of it runs until you allow it."} Allow
        it only if you trust where it came from.
      </p>
      {a.state === "changed" && shown.length > 0 && (
        <p className="mt-1.5 max-h-60 overflow-auto font-mono text-[12px] leading-[17px] break-words text-muted-foreground select-text" data-plugin-changed>
          {shown.join(", ")}
          {a.changed.length > shown.length && <> <button type="button" onClick={() => setAll(true)} data-plugin-changed-all
            className="cursor-pointer font-sans text-foreground/80 underline decoration-border underline-offset-2 hover:text-foreground">and {a.changed.length - shown.length} more</button></>}
        </p>
      )}
      {says.length > 0 && <p className="mt-1.5 text-[14px] leading-[19px] text-ink-(--orange) md:text-[13px] md:leading-[18px]" data-plugin-discloses>{host ? "A look at its code found it can" : "It says it"} {says.join("; ")}.</p>}
      <div className="mt-2.5 flex gap-2">
        <Button look="primary" disabled={!!busy} onClick={() => void run("allow", () => allowPlugin(plugin))} data-plugin-allow={plugin.id}
          >{busy === "allow" ? "Allowing…" : "Allow"}</Button>
        <Button disabled={!!busy} onClick={() => void run("off", () => setSwitch(plugin, false))}>{host ? "Not now" : "Turn off"}</Button>
      </div>
    </div>
  )
}

function About({ plugin }: { plugin: Plugin }) {
  const m = plugin.meta!
  const says = disclosed(m.disclosures)
  const from = m.source
  if (!m.version && !m.author && !m.repo && !m.fundingUrl && !from && !says.length) return null
  const link = (url: string, text: string) => <button type="button" onClick={() => openWebLink(url)} className="cursor-pointer text-foreground/80 underline decoration-border underline-offset-2 hover:text-foreground">{text}</button>
  return (
    <>
      {says.length > 0 && (
        <Section title="What it says it does" grouped>
          <Group>{says.map((x) => <SettingRow key={x} label={capitalize(x)} />)}</Group>
        </Section>
      )}
      <Section title="About" grouped>
        <Group>
          {m.version && <KV label="Version">{m.version}</KV>}
          {m.author && <KV label="Author">{m.author}</KV>}
          {m.repo && <KV label="Repository">{link(`https://github.com/${m.repo}`, m.repo)}</KV>}
          {m.fundingUrl && <KV label={plugin.tier === "hosted" ? "Website" : "Support it"}>{link(m.fundingUrl, new URL(m.fundingUrl).host)}</KV>}
          {from && <KV label="Installed from"><span data-tip={from.source}>{from.repo ?? from.source}{from.tag ? ` ${from.tag}` : from.commit ? ` at ${from.commit.slice(0, 7)}` : ""}, {dateText(new Date(`${from.installed}T12:00:00`), { day: "numeric", month: "short", year: "numeric" })}</span></KV>}
        </Group>
      </Section>
    </>
  )
}

const HOW = { auto: "on its own", manual: "by hand", rollback: "rolled back" } as const

function Entry({ u, back, busy }: { u: Update; back?: () => void; busy: "check" | "update" | "back" | null }) {
  const dense = useContext(DenseRows)
  return (
    <div className="py-2.5" data-plugin-update-entry={u.to}>
      <div className="flex flex-wrap items-baseline gap-x-2">
        <span className={cn("text-[15px] leading-[20px] font-medium", dense && "md:text-[13px] md:leading-[18px]")}>{u.how === "rollback" ? `Back to ${u.to}` : u.to}</span>
        <span className={cn("min-w-0 flex-1 text-[13px] text-muted-foreground", dense && "md:text-[12px]")}>
          from {u.from}, {HOW[u.how]}, {dateText(new Date(u.at), { day: "numeric", month: "short", year: "numeric" })}
        </span>
        {back && (
          <button type="button" disabled={!!busy} onClick={back} data-plugin-rollback
            className={cn("ml-auto shrink-0 cursor-pointer text-[13px] text-foreground/80 underline decoration-border underline-offset-2 hover:text-foreground disabled:opacity-50", dense && "md:text-[12px]")}>
            {busy === "back" ? "Rolling back…" : `Roll back to ${u.from}`}
          </button>
        )}
      </div>
      {u.notes.length > 0 && (
        <ul className={cn("mt-1 list-disc space-y-0.5 pl-4 text-[13px] leading-[18px] text-muted-foreground", dense && "md:text-[12px] md:leading-[16px]")}>
          {u.notes.map((n) => <li key={n}>{n}</li>)}
        </ul>
      )}
    </div>
  )
}

function Updates({ plugin }: { plugin: Plugin }) {
  const prefs = usePrefs()
  const src = plugin.meta!.source!
  const [busy, setBusy] = useState<"check" | "update" | "back" | null>(null)
  const [found, setFound] = useState<{ to: string } | "current" | null>(null)
  const history = [...(src.history ?? [])].reverse()
  const last = history[0]
  const canBack = !!last && last.how !== "rollback" && last.to === src.version && !!src.tag
  const check = async () => {
    setBusy("check")
    try {
      const [row] = await op<{ current?: boolean; to?: string; error?: string }[]>("plugin.update", { id: plugin.id })
      if (row?.error) throw new Error(row.error)
      setFound(row?.current || !row?.to ? "current" : { to: row.to })
    } catch (e) { notifyError(e, `Couldn't check ${plugin.name} for updates`) } finally { setBusy(null) }
  }
  const update = async () => {
    setBusy("update")
    const to = await updatePlugin(plugin)
    if (to) setFound(null)
    setBusy(null)
  }
  const back = async () => {
    if (!await confirmDialog({ title: `Roll back ${plugin.name} to ${last.from}?`, body: `It won't update to ${last.to} on its own again; a newer version will.`, confirm: "Roll back" })) return
    setBusy("back")
    await rollbackPlugin(plugin)
    setBusy(null)
  }
  if (!updatable(src.source) && !history.length) return null
  return (
    <Section title="Updates" grouped>
      <div data-plugin-updates={plugin.id}>
        <Group>
          {updatable(src.source) && <>
            <SettingRow label="Update on its own" sub={src.skip ? `Skips ${src.skip}, rolled back from` : undefined}>
              <Switch on={autoUpdating(plugin, prefs)} onChange={(v) => void setAutoUpdate(plugin, v)} label={`Update ${plugin.name} on its own`} />
            </SettingRow>
            <SettingRow label={found === "current" ? "Up to date" : found ? `${found.to} is out` : "Check for updates"} data-plugin-update-check>
              {found && found !== "current"
                ? <Button look="primary" disabled={!!busy} onClick={() => void update()}>{busy === "update" ? "Updating…" : "Update"}</Button>
                : <Button disabled={!!busy} onClick={() => void check()}>{busy === "check" ? "Checking…" : "Check"}</Button>}
            </SettingRow>
          </>}
          {history.slice(0, 10).map((u, i) => (
            <Entry key={`${u.at}-${i}`} u={u} back={i === 0 && canBack ? () => void back() : undefined} busy={busy} />
          ))}
        </Group>
      </div>
    </Section>
  )
}

async function uninstall(p: Plugin) {
  const installed = !!p.meta?.source
  if (!(await confirmDialog(installed
    ? { title: `Uninstall ${p.name}?`, body: "Its files go to the trash. Its settings stay, in case you install it again.", confirm: "Uninstall", danger: true }
    : { title: `Move ${p.name} to the trash?`, body: "It was made in this vault: its code and settings go to the trash.", confirm: "Move to trash", danger: true }))) return
  try {
    await op("plugin.uninstall", { id: p.id })
    closeDetail()
    await reload()
    notify(installed ? `Uninstalled ${p.name}` : `Moved ${p.name} to the trash`)
  } catch (e) { notifyError(e, `Couldn't remove ${p.name}`) }
}

function Problems({ plugin }: { plugin: Plugin }) {
  const problems = plugin.problems ?? []
  const plain = problems.map((p) => plainError(p).reason)
  const said = plain.filter((r): r is string => !!r)
  const mine = plugin.tier === "vault" && !plugin.meta?.source
  const author = plugin.meta?.author && plugin.meta.author !== "Vaultite" ? plugin.meta.author : "its author"
  return (
    <div className={BOX} data-plugin-problems>
      <p className="text-[15px] font-medium">{plugin.name} couldn't start</p>
      <p className="mt-0.5 text-[13px] leading-[18px] text-muted-foreground">
        {mine ? "Its code or manifest has a problem: fix it and it starts again." : `The rest of the app works without it. Turn it off, or send the details to ${author}.`}
      </p>
      {!!said.length && <ul className="mt-2 list-disc space-y-1 pl-5 text-[13px] leading-[18px]">{said.map((r, i) => <li key={i}>{r}</li>)}</ul>}
      {plain.includes(null) && <ErrorDetails className="mt-2" text={problems.join("\n\n")} />}
    </div>
  )
}

const kickerOf = (p: Plugin) => categoryOf(p.category).label

function Head({ plugin, kicker, children }: { plugin: Plugin; kicker?: string; children?: ReactNode }) {
  const [more, setMore] = useState(false)
  const short = brief(plugin.description), full = plugin.description ?? ""
  return (
    <div className="mb-5 flex items-start gap-3" data-plugin-head>
      <IconTile icon={plugin.icon} tint={tileTint(plugin.id)} className="mt-0.5 size-11 rounded-[11px]" iconClassName="size-[24px]" />
      <div className="min-w-0 flex-1">
        {kicker && <div className="text-[12px] font-semibold tracking-wide text-muted-foreground">{kicker}</div>}
        <h2 id="sheet-title" className="text-[22px] leading-[28px] font-bold break-words">{plugin.name}</h2>
        {full && (
          <p className="mt-0.5 text-[15px] leading-[20px] text-muted-foreground md:text-[14px]" data-plugin-about>
            {more || !short ? full : short}
            {short && short.length < full.replace(/\.$/, "").length && (
              <button type="button" onClick={() => setMore(!more)} aria-expanded={more} data-plugin-more
                className="ml-1.5 cursor-pointer text-foreground/70 underline decoration-border underline-offset-2 hover:text-foreground">{more ? "Less" : "More"}</button>
            )}
          </p>
        )}
      </div>
      {children}
    </div>
  )
}

export function PluginPreview({ store, plugin: given, kicker = true }: { store: Store; plugin: Plugin; kicker?: boolean }) {
  usePluginsVersion()
  const plugin = pluginById(given.id) ?? given
  const prefs = usePrefs(), { disabled } = prefs
  const waiting = switchedOn(plugin, prefs) && !plugin.problems?.length && !!plugin.meta?.approval
  const on = switchedOn(plugin, prefs) && !plugin.problems?.length && !waiting
  const switched = switchedOn(plugin, prefs) && !waiting
  const mock = useMemo(() => mockStore(store), [store])
  const live = useMemo(() => mockLive(), [])
  const blocked = (plugin.requires ?? []).filter((r) => !isEnabled(r, disabled))
  const toggle = (v: boolean) => setSwitch(plugin, v)
  return (
    <>
      <Head plugin={plugin} kicker={kicker ? plugin.tier === "hosted" ? capitalize(hostOf(plugin)?.kind) : kickerOf(plugin) : undefined}>
        {!waiting && !plugin.alwaysOn && (
          <span className={cn("shrink-0 pt-1", kicker && "mr-9")} data-plugin-switch data-tip={switched && !blocked.length ? "Off keeps its files and settings" : undefined}>
            <Switch on={switched && !blocked.length} onChange={toggle} label={`${plugin.name} plugin`} why={blocked.length ? `Turn on ${names(blocked)} to use ${plugin.name}` : undefined} />
          </span>
        )}
      </Head>
      <div className="flex flex-col gap-6">
      {waiting && <Approval plugin={plugin} />}
      {!(plugin.tier === "vault" && !on) && <PluginParts plugin={plugin} on={on} />}
      {!(plugin.tier === "vault" && !on) && preview(plugin, mock, disabled) && (
        <PreviewLive.Provider value={live}><Frame><Catch fallback={noPreview}>{preview(plugin, mock, disabled)}</Catch></Frame></PreviewLive.Provider>
      )}
      {plugin.tier === "vault" && on && !plugin.meta?.source && (
        <Group>
          <SettingRow label="Run its edits without asking" sub="Anyone who can change the vault's files could then run code here." data-plugin-edits={plugin.id}>
            <Switch on={!!plugin.meta?.edits} onChange={(v) => void allowPlugin(plugin, v)} label={`Run ${plugin.name}'s edits without asking`} />
          </SettingRow>
        </Group>
      )}
      {on && !blocked.length && hasSettings(plugin, store.pluginSettings ?? []) && (
        <section aria-label={`${plugin.name} settings`} data-plugin-settings-inline={plugin.id}>
          <Section title="Settings" grouped>
            <Catch fallback={() => <p className="px-3 text-[13px] text-muted-foreground">Its settings couldn't be drawn.</p>}>
              <PluginSettings store={store} plugin={plugin} embedded />
            </Catch>
          </Section>
        </section>
      )}
      {plugin.meta?.source && <Updates plugin={plugin} />}
      {plugin.meta && <About plugin={plugin} />}
      {(plugin.requires || plugin.enhances || plugin.runsOnServer || plugin.desktopApp) && (
        <Section title="Works with" grouped>
          <Group>
            {plugin.requires && <KV label="Needs"><span className={cn(!!blocked.length && "dashed-under")}
              data-tip={blocked.length ? `Turn on ${names(blocked)} to use this` : undefined}>{names(plugin.requires)}</span></KV>}
            {plugin.enhances && <KV label="Does more with">{names(plugin.enhances)}</KV>}
            {plugin.runsOnServer && <KV label="Runs on"><span className="inline-flex items-center gap-1.5"><Server className="size-3.5" />The server's machine</span></KV>}
            {plugin.desktopApp && <KV label="Works in"><span className="inline-flex items-center gap-1.5" data-plugin-desktop><Laptop className="size-3.5" />The desktop app on a Mac</span></KV>}
          </Group>
        </Section>
      )}
      {!!plugin.problems?.length && <Problems plugin={plugin} />}
      {!!plugin.warnings?.length && (
        <Section title="To fix" grouped>
          <div className="space-y-2" data-plugin-warnings>
            {plugin.warnings.map((p, i) => (
              <p key={i} className="rounded-card bg-foreground/[0.04] px-3 py-2.5 font-mono text-[12px] leading-[18px] break-words whitespace-pre-wrap text-muted-foreground select-text">{p}</p>
            ))}
          </div>
        </Section>
      )}
      {plugin.tier === "vault" && !switched && (
        <p className="px-3 text-[14px] text-muted-foreground md:text-[13px]">It runs code on the server's machine: nothing of it runs, not even its preview, until you turn it on.</p>
      )}
      <Kept plugin={plugin} files={store.pluginSettings ?? []} />
      {plugin.tier === "vault" && (
        <Button className="self-start text-ink-(--red)" data-plugin-uninstall={plugin.id} onClick={() => void uninstall(plugin)}>{plugin.meta?.source ? "Uninstall" : "Move to trash"}</Button>
      )}
      {plugin.tier === "hosted" && hostOf(plugin)?.uninstall && (
        <Button className="self-start text-ink-(--red)" data-plugin-uninstall={plugin.id}
          onClick={async () => { if (await confirmDialog({ title: `Uninstall ${plugin.name}?`, body: "Its files are removed from this vault. Its settings stay, in case you install it again.", confirm: "Uninstall", danger: true })) await hostOf(plugin)?.uninstall?.(plugin.id) }}>Uninstall</Button>
      )}
      </div>
    </>
  )
}
