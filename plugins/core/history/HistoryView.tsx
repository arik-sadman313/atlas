import { useCallback, useEffect, useMemo, useState } from "react"
import { ChevronDown, ChevronLeft, ChevronRight, History } from "lucide-react"
import { Bar, cn, colorVar, get, Loading, notify, notifyError, op, openFile, put, readFile, useKeptCount, useVaultChange } from "@vaultite"
import { VersionPane } from "./Version"
import { daysOf, listOf, rowsOf, timeOf, tintOf, whenOf, writer, type Listed, type Row, type Version } from "./versions"

const urlOf = (path: string, v: Version) =>
  `api/history/version?path=${encodeURIComponent(path)}&${v.source ? `source=${encodeURIComponent(v.source)}&id=${encodeURIComponent(v.id ?? "")}` : `t=${v.t}`}`

function useTexts(path: string, wanted: (Version | undefined)[], now: string | null | undefined) {
  const [texts, setTexts] = useState<Map<string, string | null>>(() => new Map())
  const want = wanted.filter((v): v is Version => !!v && !v.now && !texts.has(v.key))
  const keys = want.map((v) => v.key).join("\n")
  useEffect(() => {
    let live = true
    for (const v of want) {
      fetch(urlOf(path, v)).then((r) => (r.ok ? r.text() : null), () => null).then((t) => { if (live) setTexts((m) => new Map(m).set(v.key, t)) })
    }
    return () => { live = false }
  }, [path, keys]) // eslint-disable-line react-hooks/exhaustive-deps -- keys names the versions in want
  return (v: Version | undefined): string | null | undefined => (!v ? null : v.now ? now : texts.get(v.key))
}

const dot = (v: Version) => <span aria-hidden className="size-2 shrink-0 rounded-full" style={{ background: colorVar(tintOf(v)) }} />
const subOf = (v: Version) => {
  const who = writer(v)
  return `${v.now ? `${timeOf(v.t)}${who ? ` · ${who}` : ""}` : who ?? (v.source ? v.label : "Edited")}${v.source && v.title ? ` · ${v.title}` : ""}`
}

function Entry({ v, sel, pick, sub, folded, open, unfold }: { v: Version; sel: boolean; pick: () => void; sub?: boolean; folded?: number; open?: boolean; unfold?: () => void }) {
  return (
    <li className="relative">
      <button type="button" role="option" aria-selected={sel} onClick={pick} data-history-entry={v.key}
        className={cn("flex w-full cursor-pointer flex-col rounded-[8px] py-2 pr-10 text-left md:rounded-[6px] md:py-1.5", sub ? "pl-7" : "pl-3",
          sel ? "bg-foreground/[0.08]" : "hover:bg-foreground/[0.04]")}>
        <span className="text-[15px] leading-[20px] font-medium md:text-[13px] md:leading-[18px]">{v.now ? "Current version" : timeOf(v.t)}</span>
        <span className="flex min-w-0 items-center gap-1.5 text-[13px] leading-[18px] text-muted-foreground md:text-[12px] md:leading-[16px]">
          {dot(v)}<span className="truncate">{subOf(v)}</span>
        </span>
      </button>
      {!!folded && (
        <button type="button" aria-expanded={open} aria-label={open ? "Hide the versions just before" : `Show ${folded} more by the same writer`} data-tip={open ? "Hide" : `${folded} more`}
          onClick={unfold} className="absolute top-1.5 right-1 grid h-8 min-w-8 cursor-pointer place-items-center rounded-[6px] px-1 text-muted-foreground hover:bg-foreground/[0.06] md:h-7 md:min-w-7">
          {open ? <ChevronDown className="size-4" strokeWidth={2.25} /> : <span className="text-[12px] font-medium tabular-nums">+{folded}</span>}
        </button>
      )}
    </li>
  )
}

function List({ rows, sel, pick }: { rows: Row[]; sel: string | null; pick: (v: Version) => void }) {
  const [open, setOpen] = useState<Set<string>>(() => new Set())
  const days = useMemo(() => daysOf(rows), [rows])
  const toggle = (k: string) => setOpen((s) => { const n = new Set(s); if (n.has(k)) n.delete(k); else n.add(k); return n })
  return (
    <div role="listbox" aria-label="Versions" data-history-list className="flex flex-col gap-3">
      {days.map((d) => (
        <section key={d.day}>
          <h3 className="px-3 pb-1 text-[13px] leading-[18px] font-semibold text-muted-foreground md:text-[12px]">{d.day}</h3>
          <ul className="flex flex-col gap-px">
            {d.rows.flatMap((r) => {
              const shown = open.has(r.head.key) || r.folded.some((f) => f.key === sel)
              return [
                <Entry key={r.head.key} v={r.head} sel={r.head.key === sel} pick={() => pick(r.head)} folded={r.folded.length} open={shown} unfold={() => toggle(r.head.key)} />,
                ...(shown ? r.folded.map((f) => <Entry key={f.key} v={f} sub sel={f.key === sel} pick={() => pick(f)} />) : []),
              ]
            })}
          </ul>
        </section>
      ))}
    </div>
  )
}

function Stepper({ v, older, newer, step, list }: { v: Version; older?: Version; newer?: Version; step: (v: Version) => void; list: () => void }) {
  const arrow = "grid size-11 shrink-0 cursor-pointer place-items-center rounded-full text-foreground disabled:opacity-30 active:bg-foreground/[0.06]"
  return (
    <div className="mb-3 flex items-center gap-1 rounded-[12px] bg-foreground/[0.04] p-1 @3xl:hidden" data-history-stepper>
      <button type="button" aria-label="Older version" disabled={!older} onClick={() => older && step(older)} className={arrow}><ChevronLeft className="size-5" strokeWidth={2.25} /></button>
      <button type="button" onClick={list} aria-label="All versions" className="flex min-w-0 flex-1 cursor-pointer flex-col items-center rounded-[10px] py-1 active:bg-foreground/[0.06]">
        <span className="flex max-w-full items-center gap-1 text-[16px] leading-[21px] font-semibold">
          <span className="truncate">{v.now ? "Current version" : whenOf(v.t)}</span><ChevronDown className="size-4 shrink-0 text-muted-foreground" strokeWidth={2.5} />
        </span>
        <span className="flex max-w-full items-center gap-1.5 text-[13px] leading-[18px] text-muted-foreground">{dot(v)}<span className="truncate">{subOf(v)}</span></span>
      </button>
      <button type="button" aria-label="Newer version" disabled={!newer} onClick={() => newer && step(newer)} className={arrow}><ChevronRight className="size-5" strokeWidth={2.25} /></button>
    </div>
  )
}

function useRestore(path: string, now: string | null | undefined, load: () => void, done: () => void) {
  const [restoring, setRestoring] = useState(false)
  const restore = async (v: Version, t: string) => {
    if (restoring) return
    setRestoring(true)
    try {
      let undo: () => Promise<void>
      if (v.source) {
        const was = now ?? ""
        await put("file", { path, text: t, base: was })
        undo = async () => { await put("file", { path, text: was, base: t }) }
      } else {
        const r = await op<{ was: number | null }>("history.restore", { path, t: v.t })
        undo = async () => { if (r.was) await op("history.restore", { path, t: r.was }) }
      }
      done()
      notify(`Restored the version from ${whenOf(v.t)}`, { action: { label: "Undo", run: () => undo().then(load, (e) => notifyError(e, "Couldn't undo it")) } })
      load()
    } catch (e) { notifyError(e, "Couldn't restore it") } finally { setRestoring(false) }
  }
  return { restoring, restore }
}

export function HistoryView({ path }: { path: string }) {
  const [list, setList] = useState<Version[] | null>(null)
  const [now, setNow] = useState<string | null | undefined>(undefined)
  const [sel, setSel] = useState<string | null>(null)
  const [listing, setListing] = useState(false)
  const load = useCallback(() => {
    get<Listed>(`history?path=${encodeURIComponent(path)}`).then((r) => {
      const all = Array.isArray(r.versions) ? listOf(r) : []
      setList(all)
      setSel((s) => (s !== null && all.some((v) => v.key === s) ? s : all[0]?.key ?? null))
    }, () => setList([]))
    readFile(path).then((f) => setNow(f.text), () => setNow(null))
  }, [path])
  useEffect(load, [load])
  useVaultChange(load, [path])
  const kept = useKeptCount(`history:${path}`, list?.length)
  const rows = useMemo(() => rowsOf(list ?? []), [list])
  const at = list?.findIndex((v) => v.key === sel) ?? -1
  const v = list?.[at], older = list?.[at + 1], newer = at > 0 ? list?.[at - 1] : undefined
  const text = useTexts(path, [v, older], now)
  const { restoring, restore } = useRestore(path, now, load, () => setSel("now"))

  const name = path.split("/").pop()!.replace(/\.md$/i, "")
  if (list === null && !kept) return <Loading className="mt-4" />
  if (list !== null && list.length < 2) {
    return (
      <div className="mt-4 flex items-center gap-2.5 rounded-[10px] bg-foreground/[0.04] px-4 py-3 text-[15px] text-muted-foreground md:text-[13px]" data-history-empty>
        <History className="size-4 shrink-0" strokeWidth={2} />No earlier versions of {name} yet. They're kept from its next change on, for a week.
      </div>
    )
  }
  const pick = (x: Version) => { setSel(x.key); setListing(false) }
  const t = text(v)
  return (
    <div className="@container mt-3 pb-10" data-history>
      <div className="flex gap-6">
        {v && !listing ? (
          <VersionPane path={path} v={v} text={t ?? null} before={older ? text(older) : null} restoring={restoring}
            onRestore={() => { if (typeof t === "string") void restore(v, t) }}
            bar={<Stepper v={v} older={older} newer={newer} step={pick} list={() => setListing(true)} />} />
        ) : <div className="min-w-0 flex-1 @max-3xl:hidden" />}
        <aside className={cn("w-[260px] shrink-0 @max-3xl:w-full", !listing && "@max-3xl:hidden")} aria-label="Version history">
          <p className="mb-3 px-3 text-[13px] leading-[18px] text-muted-foreground md:text-[12px] md:leading-[16px]">
            Kept on this machine as <button type="button" data-opens className="cursor-pointer font-medium text-foreground hover:underline" onClick={() => openFile(path)}>{name}</button> changes.
          </p>
          {list === null ? <ul aria-busy className="flex flex-col gap-2 px-3">{Array.from({ length: kept }, (_, i) => <li key={i}><Bar w={i % 2 ? "45%" : "60%"} /></li>)}</ul>
            : <List rows={rows} sel={sel} pick={pick} />}
        </aside>
      </div>
    </div>
  )
}
