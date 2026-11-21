import { useRef, useState, type PointerEvent } from "react"
import { Ellipsis, Pin, Plus, X } from "lucide-react"
import {
  Button, closeTab, cn, colorVar, dragTab, Empty, groupName, INCOMING, startDrag, tabPreviewOrder, useSlide, FilterField, focusedPane, foldGroupMoving, groupMenu, HeadingButton, isPopout, menuFor, PageHeader, panesOf, placesIn, plural, selectPane, SidebarRow,
  rightClickBelow, tabMenuOf, useGroupIn, useGroupLines, useGrowIn, useShrinkOut, useTabLabels, useTabLayout, type MenuItem, type Pane, type Store, type Tab, type TabGroup, type TabInfo, type TabList,
} from "@vaultite"
import { TabGroupRow } from "@plugins/tabs/grouprow"
import { Mark, markIcon } from "./Mark"
import { NameField } from "./Name"
import { laneWash } from "./tint"
import { previewOf, useAllDrops, type AllDrop } from "./alldrops"
import { closeIn, foldIn } from "./elsewhere"
import { ALL_TABS, current, label, listsOf, lookOf, moveBetween, patch, showTab, slotMenu, SLOTS, slots, switchTo, useVersion } from "./state"

const READING_WIDTH = 848, LANE_WIDTH = 312
const EVEN_ROWS_BY_LANES = [
  "", "",
  "@min-[444px]:grid-cols-2",
  "@min-[444px]:grid-cols-2 @min-[672px]:grid-cols-3",
  "@min-[444px]:grid-cols-2 @min-[900px]:grid-cols-4",
  "@min-[444px]:grid-cols-2 @min-[672px]:grid-cols-3 @min-[1128px]:grid-cols-5",
  "@min-[444px]:grid-cols-2 @min-[672px]:grid-cols-3",
  "@min-[444px]:grid-cols-2 @min-[672px]:grid-cols-3 @min-[900px]:grid-cols-4",
  "@min-[444px]:grid-cols-2 @min-[672px]:grid-cols-3 @min-[900px]:grid-cols-4",
  "@min-[444px]:grid-cols-2 @min-[672px]:grid-cols-3 @min-[1128px]:grid-cols-5",
] as const
type Shown = { l: TabList; tabs: Tab[] }
type Desk = { n: number; lists: Shown[]; count: number }
type Info = (t: Tab | Pane) => TabInfo
type Keep = (t: Tab, group?: TabGroup) => boolean
type Where = { n: number; thisWindow: boolean; otherWorkspace: boolean }
type Run = { group?: TabGroup; tabs: Tab[] }

const hasWords = (q: string, text: string) => { const t = text.toLowerCase(); return q.toLowerCase().split(/\s+/).every((w) => t.includes(w)) }
const listed = (t: Tab) => placesIn(t).some((p) => !["new", `view:${ALL_TABS}`].includes(p.to))
const groupOf = (l: TabList, t: Tab) => (t.group ? l.groups?.find((g) => g.id === t.group) : undefined)

function runsOf({ l, tabs }: Shown): Run[] {
  const runs: Run[] = []
  for (const t of tabs) {
    const last = runs[runs.length - 1], group = groupOf(l, t)
    if (last && last.group?.id === group?.id) last.tabs.push(t)
    else runs.push({ group, tabs: [t] })
  }
  return runs
}

function desksOf(here: number, keep: Keep, naming: number): Desk[] {
  return SLOTS.filter((n) => n === here || n === naming || slots()?.[n - 1]).map((n) => {
    const lists = listsOf(n).map((l) => ({ l, tabs: l.tabs.filter((t) => listed(t) && keep(t, groupOf(l, t))) }))
    return { n, lists, count: lists.reduce((sum, s) => sum + s.tabs.length, 0) }
  })
}

export default function AllTabs({ store }: { store: Store }) {
  useVersion()
  useTabLayout()
  const info = useTabLabels(store)
  const [q, setQ] = useState("")
  const [folded, setFolded] = useState<ReadonlySet<string>>(new Set())
  const [naming, setNaming] = useState(0)
  const here = current(), query = q.trim(), free = SLOTS.find((n) => n !== here && !slots()?.[n - 1])
  const matches: Keep = (t, g) => hasWords(query, [info(t).label, g?.name ?? "", ...placesIn(t).flatMap((p) => [info(p).label, p.to])].join("\n"))
  const desks = desksOf(here, () => true, naming)
  const shown = query ? desksOf(here, matches, naming) : desks
  const total = desks.reduce((sum, d) => sum + d.count, 0)
  const moves = (n: number, t: Tab): MenuItem[] => desks.flatMap((d) => (d.n === n ? [] : [{ label: `Move to ${label(d.n)}`, run: () => moveBetween(n, d.n, t.id) }]))
  const fold = (at: Where, g: TabGroup) => {
    if (at.thisWindow) foldGroupMoving(g.id)
    else if (at.otherWorkspace) foldIn(at.n, g.id)
    else setFolded((s) => { const next = new Set(s); if (!next.delete(g.id)) next.add(g.id); return next })
  }
  const isFolded = (at: Where, g: TabGroup) => !query && (at.thisWindow || at.otherWorkspace ? !!g.collapsed : !!g.collapsed !== folded.has(g.id))
  const shownList = (n: number) => shownOf(n, whereOf(here, n, 0), isFolded)
  const hit = useAllDrops(shownList)
  const lanes = shown.filter((d) => !query || d.count)
  const lane = (d: Desk) => (
    <Lane key={d.n} d={d} here={here} naming={naming} name={setNaming}>
      {d.lists.map((s, w) => (!s.tabs.length ? null : (
        <div key={w}>
          {w > 0 && <h3 className="px-1.5 pt-2 pb-1 text-[12px] font-medium text-muted-foreground">Pop-out window {w}</h3>}
          <TabRows s={s} w={w} at={whereOf(here, d.n, w)} info={info} folded={isFolded} fold={fold} moves={moves}
            hit={!query && w === 0 && hit?.n === d.n ? hit : null} shown={() => shownList(d.n)} />
        </div>
      )))}
    </Lane>
  )
  return (
    <div data-all-tabs data-own-drops className="@container mx-auto pb-10" style={{ maxWidth: Math.max(READING_WIDTH, desks.length * LANE_WIDTH) }}>
      <PageHeader title="Workspaces" subtitle={`${plural(total, "tab")} in ${plural(desks.length, "workspace")}`}>
        <div className="flex items-center justify-end gap-2 max-md:basis-full">
          {free && <NewDesk n={free} naming={naming === free} start={() => { setQ(""); setNaming(free) }} />}
          <FilterField value={q} onChange={setQ} placeholder="Filter tabs" className="md:w-48 md:flex-none" />
        </div>
      </PageHeader>
      {query && !lanes.length ? <Empty>No tabs match "{query}".</Empty>
        : <div data-all-tabs-board className={cn("grid gap-3", EVEN_ROWS_BY_LANES[desks.length])}>{lanes.map(lane)}</div>}
    </div>
  )
}

function Lane({ d, here, naming, name, children }: { d: Desk; here: number; naming: number; name: (n: number) => void; children: React.ReactNode }) {
  return (
    <section data-all-tabs-workspace={d.n} aria-current={d.n === here || undefined} style={laneWash(lookOf(d.n).tint)}
      className={cn("glass flex min-w-0 flex-col rounded-card p-2 @min-[444px]:min-h-40", d.n === here && "outline-[1.5px] -outline-offset-1 outline-primary/60")}>
      <DeskHead d={d} here={here} naming={naming === d.n} name={name} />
      {!d.count && <p className="mx-0.5 mt-0.5 rounded-control border border-dashed border-border/80 px-3 py-4 text-center text-[13px] text-tertiary">No tabs</p>}
      {children}
    </section>
  )
}

function DeskHead({ d, here, naming, name }: { d: Desk; here: number; naming: boolean; name: (n: number) => void }) {
  const n = d.n
  const menu = (): MenuItem[] => [
    ...(n !== here ? [{ label: `Switch to ${label(n)}`, icon: markIcon(n, lookOf(n)), run: () => switchTo(n) }] : []),
    ...slotMenu(n, () => name(n)).map((it, k) => (k || n === here ? it : { ...it, sep: true })),
  ]
  const done = (typed: string | null) => { name(0); if (typed !== null) patch(n, { name: typed.trim() || null }) }
  return (
    <div data-all-tabs-head={n} onContextMenu={menuFor(menu)} className="flex h-8 items-center gap-2 px-1.5 pb-1">
      <Mark n={n} {...lookOf(n)} look="border border-border font-medium text-foreground" />
      {naming ? <NameField n={n} done={done} className="h-6 text-[14px] font-semibold" /> : (
        <h2 className="flex min-w-0 flex-1">
          <button type="button" data-all-tabs-name onClick={() => name(n)} data-tip="Rename"
            className="-mx-1 max-w-full cursor-text truncate rounded-[4px] px-1 text-left text-[14px] font-semibold hover:bg-foreground/[0.06]">{label(n)}</button>
        </h2>
      )}
      <span data-all-tabs-count className="text-[12px] text-muted-foreground tabular-nums">{d.count}</span>
      <HeadingButton icon={Ellipsis} label={`More for ${label(n)}`} tip="More" onClick={rightClickBelow} data-all-tabs-more={n} />
    </div>
  )
}

function NewDesk({ n, naming, start }: { n: number; naming: boolean; start: () => void }) {
  return <Button look="secondary" size="small" data-all-tabs-new={n} disabled={naming} onClick={start} className="md:h-7.5"><Plus className="-ml-0.5 size-3.5" strokeWidth={2.25} />New workspace</Button>
}

const whereOf = (here: number, n: number, w: number): Where => ({ n, thisWindow: n === here && w === 0 && !isPopout(), otherWorkspace: n !== here })
function shownOf(n: number, at: Where, folded: (at: Where, g: TabGroup) => boolean): TabList {
  const l = listsOf(n)[0] ?? { tabs: [], active: "" }
  return { ...l, groups: l.groups?.map((g) => ({ ...g, collapsed: folded(at, g) })) }
}

function TabRows({ s, w, at, info, folded, fold, moves, hit, shown }: { s: Shown; w: number; at: Where; info: Info; folded: (at: Where, g: TabGroup) => boolean
  fold: (at: Where, g: TabGroup) => void
  moves: (n: number, t: Tab) => MenuItem[]
  hit: AllDrop | null
  shown: () => TabList }) {
  const root = useRef<HTMLDivElement>(null)
  useGroupLines(root, "y")
  const l = hit && !hit.home ? shown() : null, preview = l && hit ? previewOf(l, hit) : null
  useSlide(root, l && preview ? tabPreviewOrder(l, preview) : null, "y")
  const incoming = !!preview?.tabs.some((t) => t.id === INCOMING)
  const row = (t: Tab, line?: string) => <Row key={t.id} t={t} at={at} info={info} active={!at.thisWindow && t.id === s.l.active} line={line} moves={moves(at.n, t)} />
  return (
    <div ref={root} data-all-tabs-window={w} className="relative flex flex-col gap-px" style={incoming ? { paddingBottom: 29 } : undefined}>
      {runsOf(s).map((r) => {
        const g = r.group
        if (!g) return r.tabs.map((t) => row(t))
        const shut = folded(at, g)
        return (
          <div key={`${g.id}-${r.tabs[0].id}`} data-all-tabs-group={g.id} className="contents">
            <GroupHead g={{ ...g, collapsed: shut }} n={r.tabs.length} at={at} onFold={() => fold(at, g)} />
            {!shut && r.tabs.map((t) => row(t, g.id))}
          </div>
        )
      })}
      {incoming && <div aria-hidden data-slide={INCOMING} className="pointer-events-none absolute inset-x-0 top-0 h-7 rounded-[5px] bg-foreground/[0.06]" />}
    </div>
  )
}

function GroupHead({ g, n, at, onFold }: { g: TabGroup; n: number; at: Where; onFold: () => void }) {
  const box = useRef<HTMLDivElement>(null)
  useGroupIn(box, g.id)
  const drag = (e: PointerEvent<HTMLElement>) => {
    if (at.thisWindow) startDrag(e, { from: "group", group: g.id, label: groupName(g) })
    else if (at.otherWorkspace) startDrag(e, { from: "group", label: groupName(g), away: { workspace: at.n, group: g.id, color: g.color } })
  }
  return (
    <div ref={box} data-slide={`group:${g.id}`} onPointerDown={drag} data-line-head={g.id} style={{ "--line": colorVar(g.color) }} onContextMenu={at.thisWindow ? menuFor(() => groupMenu(g.id, "panel")) : undefined}>
      <TabGroupRow g={g} n={n} onFold={onFold} more={at.thisWindow} />
    </div>
  )
}

function Row({ t, at, info, active, line, moves }: { t: Tab; at: Where; info: Info; active: boolean; line?: string; moves: MenuItem[] }) {
  const box = useRef<HTMLDivElement>(null)
  useGrowIn(box, t)
  useShrinkOut(box, { tab: t.id })
  const ps = panesOf(t).filter((p) => !p.float), split = ps.length > 1, i = info(t)
  const closes = !t.pinned && (at.thisWindow || at.otherWorkspace)
  const close = () => { if (at.thisWindow) closeTab(t.id); else closeIn(at.n, t.id) }
  const click = (e: React.MouseEvent) => {
    if (e.button === 1) { if (closes) close(); return }
    const half = e.target instanceof Element ? e.target.closest<HTMLElement>("[data-pane-half]")?.dataset.paneHalf : undefined
    showTab(at.n, t.id)
    if (half) selectPane(half)
  }
  const after = (items: MenuItem[]) => items.map((it, k) => (k ? it : { ...it, sep: true }))
  const menu = (): MenuItem[] => at.thisWindow ? [...tabMenuOf(t.id), ...after(moves)]
    : [...moves, ...(closes ? after([{ label: "Close tab", icon: X, run: close }]) : [])]
  const drag = (e: PointerEvent<HTMLElement>) => {
    if (at.thisWindow) dragTab(e, t)
    else if (at.otherWorkspace) startDrag(e, { from: "tab", label: i.label, away: { workspace: at.n, tab: t.id, to: focusedPane(t).to } })
  }
  return (
    <div ref={box} data-slide={t.id} onPointerDown={drag} data-in-group={at.thisWindow ? t.group : undefined} data-line-of={line} onContextMenu={menuFor(menu)}>
      <SidebarRow data-all-tabs-tab={t.id} data-all-tabs-split={split ? "" : undefined} icon={split ? undefined : i.icon} iconClassName={i.iconClassName} tint={i.tint}
        badge={split ? undefined : i.badge} mark={split ? undefined : i.mark} label={split ? <SplitCells ps={ps} info={info} /> : i.label} labelClassName={split ? "[mask-image:none]" : undefined}
        tip={split ? ps.map((p) => info(p).label).join(" | ") : undefined} open active={active} more className={cn(line && "ml-3.5")}
        swipe={() => (closes ? [{ label: "Close", icon: X, danger: true, run: close, removes: true }] : [])}
        actions={closes ? [<HeadingButton key="close" icon={X} label={`Close ${i.label}`} tip="Close tab" data-no-drag onClick={(e) => { e.preventDefault(); e.stopPropagation(); close() }} />] : undefined}
        onClick={click}>
        {t.pinned && <span className="grid size-5 shrink-0 place-items-center text-muted-foreground" aria-label="Pinned"><Pin className="size-3.5" strokeWidth={2} /></span>}
      </SidebarRow>
    </div>
  )
}

function SplitCells({ ps, info }: { ps: Pane[]; info: Info }) {
  return (
    <span className="-ml-1 flex w-full min-w-0 overflow-hidden rounded-[5px] ring-1 ring-foreground/15 ring-inset">
      {ps.map((p, k) => {
        const pi = info(p)
        return (
          <span key={p.id} data-pane-half={p.id} data-all-tabs-pane={p.id} data-tip={pi.label}
            className={cn("flex h-5.5 min-w-0 flex-1 basis-0 items-center gap-2 px-1 transition-colors hover:bg-foreground/[0.06]", k > 0 && "border-l border-foreground/15")}>
            <pi.icon className={cn("size-4 shrink-0", !pi.tint && "text-muted-foreground", pi.iconClassName)} strokeWidth={2} style={pi.tint ? { color: pi.tint } : undefined} />
            <span className="min-w-0 flex-1 truncate">{pi.label}</span>
          </span>
        )
      })}
    </span>
  )
}
