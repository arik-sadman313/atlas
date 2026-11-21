import { Fragment, useEffect, useMemo, useRef, type MouseEvent, type RefObject } from "react"
import { ArrowUpDown, FolderOpen } from "lucide-react"
import { closestOf } from "@/core/dom"
import { folderOf, openFile } from "@/core/files"
import { usePane } from "@/core/pane"
import { useDesktop } from "@/core/platform"
import { usePrefs, type FolderView } from "@/core/prefs"
import { rowMenu, selectClick } from "@/core/select"
import { openInSplit } from "@/core/splits"
import { useFocusedFile } from "@/core/workspace"
import { menuBelow, type MenuItem } from "@/components/ContextMenu"
import { grouped, openItem } from "@/components/FileActions"
import type { FolderItem } from "@/components/FileTree"
import { PageHeader } from "@/components/kit"
import { cn } from "@/lib/utils"
import { Grid, Rows } from "@/pages/Folder"
import { Columns } from "@/pages/FolderColumns"
import { Gallery } from "@/pages/FolderGallery"
import { arrive, arrived, focusThing, keyedPages, type KeyedPage } from "@/pages/FolderKeys"
import { pick, pickedIn, useEnter, type Kids, type Moves } from "@/pages/FolderParts"
import { arrangeItems, groupOf, outsideMenus, sectionsOf, setView, shownView, VIEWS } from "@/pages/folderviews"
import { inside, itemsOf, listerOf, rootOf, useListed, type Got } from "@/pages/outsidelist"
import { copyItem, outsideTabMenu, showItem } from "@/pages/outsidemenu"

outsideMenus.tab = outsideTabMenu

export function OutsideCrumbs({ path }: { path: string }) {
  const root = rootOf(useListed(path), path)
  const enter = useEnter()
  const rest = path.startsWith(root) && path !== root ? path.slice(root.length).replace(/^\//, "").split("/") : []
  const crumbs = [{ at: root, name: root.split("/").pop() || root }, ...rest.map((name, i) => ({ at: inside(root, rest.slice(0, i + 1).join("/")), name }))]
  const crumb = "h-6 min-w-0 truncate rounded-[4px] px-1 leading-6"
  return (
    <nav aria-label="Folder path" data-tip={path} className="flex min-w-0 items-center">
      {crumbs.map((c, i) => i === crumbs.length - 1
        ? <span key={c.at} aria-current="page" className={cn(crumb, "shrink-0 font-medium")}>{c.name}</span>
        : (
          <Fragment key={c.at}>
            <button type="button" data-opens onClick={() => enter(c.at, -1)} className={cn(crumb, "shrink-[1000] cursor-pointer text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground")}>{c.name}</button>
            <span aria-hidden className="shrink-0 px-px text-tertiary">/</span>
          </Fragment>
        ))}
    </nav>
  )
}

function Toolbar({ path, view }: { path: string; view: FolderView }) {
  return (
    <div className="mb-1 flex shrink-0 items-center gap-1.5">
      <div role="radiogroup" aria-label="Show as" className="flex rounded-[7px] bg-foreground/[0.05] p-px">
        {VIEWS.map((o) => (
          <button key={o.value} type="button" role="radio" aria-checked={view === o.value} aria-label={o.label} data-tip={o.label} data-folder-view={o.value}
            onMouseDown={(e) => e.preventDefault()} onClick={(e) => { if (e.detail) arrive(path); setView(o.value) }}
            className={cn("grid h-6 w-7 cursor-pointer place-items-center rounded-[6px] transition-colors",
              view === o.value ? "bg-card text-foreground shadow-[0_1px_2px_rgb(0_0_0/0.12)] dark:bg-[var(--segment-on)]" : "text-muted-foreground hover:text-foreground")}>
            <o.icon className="size-[15px]" strokeWidth={2} />
          </button>
        ))}
      </div>
      <button type="button" aria-label="Sort and group" data-tip="Sort and group" data-folder-arrange onClick={(e) => menuBelow(e, arrangeItems())}
        className="grid h-[26px] w-8 cursor-pointer place-items-center rounded-[7px] text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground">
        <ArrowUpDown className="size-[15px]" strokeWidth={2} />
      </button>
    </div>
  )
}

export function OutsideFolderPage({ path }: { path: string }) {
  const got = useListed(path)
  const view = shownView(usePrefs().folderView, useDesktop())
  const box = useRef<HTMLDivElement>(null)
  return (
    <div ref={box} data-folder-page={path} data-folder-outside data-folder-shown={view} data-own-keys className="min-h-[60vh]"
      onFocus={(e) => { const k = closestOf<HTMLElement>(e.target, "[data-folder-item]")?.dataset.folderItem; if (k && folderOf(k) === path) pick(path, k) }}>
      <PageHeader title={path.split("/").pop() || path} className={view === "columns" || view === "gallery" ? "mb-3" : undefined}><Toolbar path={path} view={view} /></PageHeader>
      {got && <Listing path={path} got={got} view={view} box={box} />}
    </div>
  )
}

function useKeyed(box: RefObject<HTMLDivElement | null>, page: Omit<KeyedPage, "moves"> | null, moves: RefObject<Moves | null>) {
  useEffect(() => {
    const el = box.current
    if (el && page) keyedPages.set(el, () => ({ ...page, moves: moves.current }))
  })
  const path = page?.path, view = page?.view, items = page?.items
  useEffect(() => {
    const el = box.current, was = path === undefined ? null : pickedIn(path)
    if (el && path !== undefined && arrived(path) && was && items?.some((n) => n.path === was)) focusThing(el, was)
  }, [box, path, view, items])
}

function Listing({ path, got, view, box }: { path: string; got: Got; view: FolderView; box: RefObject<HTMLDivElement | null> }) {
  const { fileSort, folderGroup, showHidden } = usePrefs()
  const desk = useDesktop()
  const list = useMemo(() => ("listed" in got ? itemsOf(got.listed, fileSort, showHidden) : null), [got, fileSort, showHidden])
  const root = rootOf(got, path)
  const lister = useMemo(() => listerOf(root), [root])
  const { pane: own } = usePane(), focused = useFocusedFile()
  const pane = focused.pane && focused.pane !== own ? focused.pane : undefined
  const enter = useEnter()
  const moves = useRef<Moves | null>(null)
  const openIt = (n: FolderItem, newTab = false) => (n.folder ? enter(n.path, 1, newTab) : openFile(n.path, { newTab, pane }))
  const up = () => { if (path === root) return; const parent = folderOf(path) || "/"; pick(parent, path); arrive(parent); enter(parent, -1) }
  useKeyed(box, list && { path, items: list.items, view, open: openIt, outside: true, up, show: (n) => (desk && !n.folder ? void openInSplit(`file:${n.path}`, "right", false) : openIt(n)),
    showAs: (v) => { arrive(path); setView(v) } }, moves)
  if ("why" in got) return <p data-folder-gone className="mt-2 text-[15px] text-muted-foreground">Vaultite can't read this folder: {got.why}</p>
  if (!list) return null
  const menuOf = (n: FolderItem) => rowMenu("folder", n.path, (): MenuItem[] => grouped([
    [{ label: "Open", icon: FolderOpen, run: () => openIt(n) }, openItem(() => openIt(n, true), desk && !n.folder ? () => void openInSplit(`file:${n.path}`, "right") : undefined)],
    [copyItem(n.path), ...(n.folder ? showItem(n.path) : [])],
  ]))
  const open = (n: FolderItem, e: MouseEvent) => { if (!selectClick(e, "folder", n.path)) openIt(n, e.metaKey || e.ctrlKey || e.button === 1) }
  const kids: Kids = { setMoves: (m) => { moves.current = m }, items: list.items, counts: list.counts, open, menuOf, swipe: () => [], press: () => {}, renaming: null, lit: null, desk }
  const sections = view === "list" || view === "grid" ? sectionsOf(list.items, groupOf(folderGroup)) : null
  if (view === "columns") return <Columns {...kids} lister={lister} folder={path} openIt={openIt} />
  if (!list.items.length) return <p data-folder-empty className="py-20 text-center text-[15px] text-muted-foreground">This folder is empty</p>
  if (view === "gallery") return <Gallery {...kids} folder={path} openIt={openIt} />
  return view === "grid" ? <Grid {...kids} sections={sections} folder={path} /> : <Rows {...kids} sections={sections} folder={path} />
}
