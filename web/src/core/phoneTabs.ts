import { flushSync } from "react-dom"
import { folderOf } from "@/core/files"
import { activePane, activeTab, here, onWorkspaceChange, panes, selectPane, selectTab } from "@/core/workspace"
import { onAway } from "@/core/away"
import { haptic } from "@/core/haptics"
import { fingerHolding } from "@/core/drag"
import { openNewTab, opensSwitcher } from "@/core/launcher"
import { zoomIn, zoomNew, zoomOut } from "@/core/motion"
import { fling, glide, shownAt, stopFor, within } from "@/core/pager"
import { scrollOf } from "@/core/viewstate"
import { afterSheets, closeDetail, replaceHash, route } from "@/core/nav"
import { isPage } from "@/core/pages"
import { focusedPane, foldedAway, panesOf, type Pane, type Tab } from "../../../core/layout.ts"
import { cell } from "@/core/signal"
import { share } from "@/core/share"
import { shootTab, shotOf } from "@/core/tabShots"
import { elementOf, htmlOf } from "@/core/dom"
import { claimSideways, drawerOn, EDGE, eatClick, movesItself, releaseSideways, rowTakes, selectingIn, sidewaysOwner } from "@/core/sideways"

export async function openSwitcher(from?: { page: DOMRect; reset: () => void }) {
  if (!from) await shootTab()
  zoomOut(() => {
    replaceHash(`${route().tab}/tabs`, { sheet: 0 })
  }, () => cardOf(activeTab()), from?.page, from?.reset)
}

const cardOf = (t: Tab) => (panesOf(t).length > 1 && !t.group ? t.focus : t.id)

export function closeSwitcher() {
  if (route().detail !== "tabs") return closeDetail()
  zoomIn(cardOf(activeTab()), closeDetail)
}

export function pickTab(id: string) {
  zoomIn(id, () => afterSheets(() => selectTab(id)))
}
export function pickPane(id: string) {
  zoomIn(id, () => afterSheets(() => selectPane(id)))
}

export async function newPhoneTab(button: Element | null, group?: string) {
  if (opensSwitcher()) return afterSheets(() => openNewTab({ group }))
  await shootTab()
  const p = activePane()
  zoomNew(button, () => afterSheets(() => openNewTab({ group })), shotOf(p.id, p.to))
}

export function tabMeta(to: string) {
  if (to === "new") return "Empty"
  if (to.startsWith("file:/")) return "Outside the vault"
  if (to.startsWith("file:")) {
    const p = to.slice(5)
    return isPage(p) ? "Page" : folderOf(p).split("/").filter(Boolean).join(" / ") || (share?.folder ?? "Vault")
  }
  if (to.startsWith("view:")) return "Plugin view"
  return "App"
}

const GAP = 20, SLOP = 7
const page = () => document.querySelector<HTMLElement>("#main-scroll > main")

export type Swipe = "panes" | "tabs"
const swipe = cell<Swipe | null>(null)
export const useSwipe = swipe.use

export function besideOf(k: Swipe | null): { pane: Pane; tab: Tab; side: -1 | 1 }[] {
  const l = here(), t = activeTab()
  if (!t) return []
  const near = <T,>(xs: T[], i: number) => ([[xs[i - 1], -1], [xs[i + 1], 1]] as const).filter((x): x is readonly [T, -1 | 1] => i >= 0 && !!x[0])
  if (k === "tabs") {
    const ts = l.tabs.filter((x) => x.id === t.id || !foldedAway(l, x))
    return near(ts, ts.findIndex((x) => x.id === t.id)).map(([x, side]) => ({ pane: focusedPane(x), tab: x, side }))
  }
  const ps = panesOf(t)
  return near(ps, ps.findIndex((p) => p.id === t.focus)).map(([p, side]) => ({ pane: p, tab: t, side }))
}

const toward = (dx: number) => (dx < 0 ? 1 : -1)
export const panesTake = (el: Element | null, dx: number) =>
  panes().length > 1 && !!el && !!page()?.contains(el) && besideOf("panes").some((b) => b.side === toward(dx))

const ownsSideways = (el: Element | null, top: Element, dx: number) => rowTakes(el, dx) || movesItself(el, top, dx)

function leaves(kind: Swipe, mx: number, my: number, el: Element | null, heard: HTMLElement | null) {
  if (Math.abs(mx) <= Math.abs(my) * 1.15 || document.documentElement.dataset.pageLift !== undefined || sidewaysOwner()) return true
  if (kind !== "panes") return false
  if (!besideOf("panes").some((b) => b.side === toward(mx)) && drawerOn(mx > 0 ? "left" : "right")) return true
  return !!heard && ownsSideways(el, heard, mx)
}

export function swipeSideways() {
  type G = { id: number; x: number; y: number; from: number; axis: "x" | "y" | null; lock: number; moves: [number, number][]; kind: Swipe; bar: boolean; quit?: () => void }
  let g: G | null = null
  let pos = 0
  let flight: Animation | null = null
  let kind: Swipe = "panes"
  let m: HTMLElement | null = null, heard: HTMLElement | null = null
  const step = () => (m?.offsetWidth || innerWidth) + GAP
  const follow = (x: number) => {
    const h = document.querySelector<HTMLElement>("[data-phone-header]"), q = x / step()
    if (!h) return
    h.style.setProperty("--swipe-next", x ? String(Math.min(1, Math.max(0, -q))) : "")
    h.style.setProperty("--swipe-prev", x ? String(Math.min(1, Math.max(0, q))) : "")
  }
  const put = (x: number) => { pos = x; if (m) m.style.transform = x ? `translateX(${x}px)` : ""; follow(x) }
  const ends = () => { const b = besideOf(kind), w = step(); return { lo: b.some((x) => x.side === 1) ? -w : 0, hi: b.some((x) => x.side === -1) ? w : 0 } }
  const lay = () => {
    if (!m || m.dataset.swiping !== undefined) return
    flushSync(() => swipe.set(kind))
    const r = m.getBoundingClientRect(), cs = getComputedStyle(m), top = parseFloat(cs.paddingTop) || 0, bottom = parseFloat(cs.paddingBottom) || 0
    m.style.setProperty("--beside-top", `${-r.top}px`)
    m.style.setProperty("--beside-h", `${innerHeight}px`)
    for (const b of m.querySelectorAll<HTMLElement>("[data-beside]")) {
      const inner = htmlOf(b.firstElementChild)
      const most = Math.max(0, top + (inner?.offsetHeight ?? 0) + bottom - innerHeight)
      b.style.setProperty("--beside-y", `${top - Math.min(most, scrollOf(b.dataset.to ?? ""))}px`)
    }
    m.dataset.swiping = ""
    m.style.willChange = "transform"
  }
  const rest = () => {
    releaseSideways("pager")
    if (!m) return
    put(0)
    delete m.dataset.swiping
    m.style.willChange = ""
    swipe.set(null)
  }
  const halt = () => {
    const f = flight
    flight = null
    if (!f || !m) return
    put(shownAt(m))
    f.cancel()
  }
  const land = (k: 1 | -1) => {
    const b = besideOf(kind).find((x) => x.side === k)
    if (b) flushSync(() => { if (kind === "tabs") selectTab(b.tab.id); else selectPane(b.pane.id); swipe.set(null) })
    rest()
  }
  const settle = (to: number, v = 0) => {
    halt()
    if (!m) return
    const k = to < 0 ? 1 : to > 0 ? -1 : 0
    const a = glide(m, pos, to, v, follow)
    pos = to
    if (!a) return k ? land(k) : rest()
    flight = a
    a.finished.then(() => {
      if (flight !== a) return
      flight = null
      if (k) land(k); else rest()
    }, () => {})
  }
  const drop = () => {
    const d = g
    g = null
    d?.quit?.()
    if (d?.axis === "x") settle(Math.abs(pos) > step() / 2 ? Math.sign(pos) * step() : 0)
    else releaseSideways("pager")
  }

  const start = (e: TouchEvent, k: Swipe, bar = k === "tabs") => {
    if (g) return drop()
    const t = e.touches[0]
    if (e.touches.length !== 1 || route().detail || !t) return
    if (flight) {
      halt()
      g = { id: t.identifier, x: t.clientX, y: t.clientY, from: pos, axis: "x", lock: t.clientX, moves: [[e.timeStamp, t.clientX]], kind, bar }
      g.quit = onAway(drop)
      claimSideways("pager")
      return
    }
    if (!besideOf(k).length || t.clientX < EDGE || t.clientX > innerWidth - EDGE) return
    if (k === "panes" && heard && selectingIn(heard)) return
    g = { id: t.identifier, x: t.clientX, y: t.clientY, from: pos, axis: null, lock: t.clientX, moves: [[e.timeStamp, t.clientX]], kind: k, bar }
  }
  const move = (e: TouchEvent, block = true) => {
    const d = g
    if (!d) return
    const t = [...e.changedTouches].find((x) => x.identifier === d.id)
    if (!t) return
    if (fingerHolding()) return drop()
    const mx = t.clientX - d.x, my = t.clientY - d.y
    if (!d.axis) {
      if (Math.hypot(mx, my) < SLOP) return
      if (leaves(d.kind, mx, my, elementOf(e.target), heard)) { g = null; return }
      m = page()
      if (!m) { g = null; return }
      d.axis = "x"
      d.lock = t.clientX
      d.quit = onAway(drop)
      kind = d.kind
      claimSideways("pager")
      lay()
    }
    // iOS can start a scroll in a scroller inside the page whatever its touch-action says.
    if (block && e.cancelable) e.preventDefault()
    d.moves.push([e.timeStamp, t.clientX])
    if (d.moves.length > 8) d.moves.shift()
    const { lo, hi } = ends()
    const x = d.from + t.clientX - d.x - (d.lock - d.x) * Math.max(0, 1 - Math.abs(t.clientX - d.lock) / 48)
    put(within(x, lo, hi, step()))
  }
  const end = (e: TouchEvent) => {
    const d = g
    if (!d || ![...e.changedTouches].some((x) => x.identifier === d.id)) return
    g = null
    d.quit?.()
    if (d.axis !== "x") return
    eatClick()
    const v = e.type === "touchend" ? fling(d.moves, e.timeStamp) : 0
    const { lo, hi } = ends()
    const to = stopFor([...(lo ? [lo] : []), 0, ...(hi ? [hi] : [])], pos, v)
    if (to) haptic("selection")
    settle(to, v)
  }

  // A non-passive touchmove makes the page's scroll wait on it: listened to only while a split shows.
  const onPage = (e: TouchEvent) => start(e, "panes")
  const onMove = (e: TouchEvent) => move(e)
  const detach = () => {
    if (!heard) return
    if (kind === "panes") { halt(); g = null; rest() }
    heard.style.touchAction = ""
    heard.removeEventListener("touchstart", onPage)
    heard.removeEventListener("touchmove", onMove)
    heard.removeEventListener("touchend", end)
    heard.removeEventListener("touchcancel", end)
    heard = null
  }
  const claim = () => {
    const el = page(), on = !!el && panes().length > 1
    if (heard && (heard !== el || !on)) detach()
    else if (!g && !flight && pos) rest()
    if (!on || heard) return
    heard = el
    heard.style.touchAction = "pan-y pinch-zoom"
    heard.addEventListener("touchstart", onPage, { passive: true })
    heard.addEventListener("touchmove", onMove, { passive: false })
    heard.addEventListener("touchend", end, { passive: true })
    heard.addEventListener("touchcancel", end, { passive: true })
  }
  const onBar = (e: TouchEvent) => {
    const el = elementOf(e.target), bar = el?.closest("[data-phone-bar]")
    if (bar && (flight || !document.querySelector("dialog[open], #bar-menu"))) start(e, "tabs")
    else if (flight && el && m?.parentElement?.contains(el) && !heard?.contains(el) && !el.closest("[data-phone-header]")) start(e, kind, true)
  }
  const barMove = (e: TouchEvent) => { if (g?.bar) move(e, false) }
  const barEnd = (e: TouchEvent) => { if (g?.bar) end(e) }
  addEventListener("touchstart", onBar, { capture: true, passive: true })
  addEventListener("touchmove", barMove, { capture: true, passive: true })
  addEventListener("touchend", barEnd, { capture: true, passive: true })
  addEventListener("touchcancel", barEnd, { capture: true, passive: true })
  const unwatch = onWorkspaceChange(claim)
  claim()
  return () => {
    unwatch(); detach(); halt(); g = null; rest()
    removeEventListener("touchstart", onBar, { capture: true })
    removeEventListener("touchmove", barMove, { capture: true })
    removeEventListener("touchend", barEnd, { capture: true })
    removeEventListener("touchcancel", barEnd, { capture: true })
  }
}
