import { useEffect, useLayoutEffect, useRef, useState } from "react"
import { flushSync } from "react-dom"
import { moves } from "@/core/animation"
import { onAway } from "@/core/away"
import { elementOf } from "@/core/dom"
import { fingerHolding, holdPage } from "@/core/drag"
import { haptic } from "@/core/haptics"
import { spring } from "@/core/motion"
import { FLICK, fling, shownAt } from "@/core/pager"
import { panesTake } from "@/core/phoneTabs"
import { isDesktop } from "@/core/platform"
import type { Side } from "@/core/plugins"
import { getPrefs } from "@/core/prefs"
import { claimSideways, EDGE, eatClick, movesItself, releaseSideways, rowTakes, selectingIn, setDrawers, sidewaysOwner } from "@/core/sideways"
import { trackSoon } from "@/core/unsaved"

// Shut, a drawer waits just off screen, shadow too: hiding it (visibility, an attribute its content's style reads)
// restyled all it holds as a swipe started, a stall under the finger.
export const shift = (s: Side, p: number) => `translateX(calc(${s === "left" ? -1 : 1} * (${(1 - p) * 100}% + ${p ? 0 : 48}px)))`
const width = () => Math.min(innerWidth * 0.86, 360)
const SLOP = 8, EASE_IN = 48, HOLD_MS = 300
const response = () => (getPrefs().animation === "snappy" ? 0.26 : 0.36)
const FIELD = ":is(input:not([type=checkbox], [type=radio], [type=button]), textarea, select):focus, [data-keeps-touch]"
const BAR = "[data-phone-bar]"
const page = () => document.querySelector("#main-scroll > main") ?? document.body
const onPage = (el: Element) => el === document.body || el === document.documentElement || !!el.closest(`#main-scroll, [data-phone-header], ${BAR}`)

type Drag = { side: Side | null; el: Element | null; edge: Side | null; x: number; y: number; t: number; axis: "x" | null
  from: number; p: number; lock: number; caught: boolean; moves: [number, number][]; quit?: () => void }

function pageGives(d: Drag, side: Side, dx: number, t: number) {
  const el = d.el
  if (sidewaysOwner() || el?.closest(FIELD)) return false
  if (d.edge === side) return true
  if (!el || el.closest(BAR) || selectingIn(page())) return false
  if (el.closest("[data-own-hold]") && t - d.t > HOLD_MS) return false
  return !rowTakes(el, dx) && !movesItself(el, page(), dx) && !panesTake(el, dx)
}

function takes(d: Drag, s: Side, mx: number, my: number, t: number) {
  if (Math.abs(mx) <= Math.abs(my) * 1.15) return false
  return d.from ? !sidewaysOwner() && !rowTakes(d.el, mx) : pageGives(d, s, mx, t)
}

const opens = (d: Drag, v: number) => {
  const ahead = d.p + (v * 100) / width()
  return Math.abs(v) >= FLICK ? v > 0 : ahead > (d.from > 0.5 ? 0.66 : 0.33)
}

type Motion = { has: Record<Side, boolean>; side: Side | null; out: () => Side | null; open: (s: Side | null) => void }

export function useDrawerMotion({ has, side, out, open }: Motion) {
  useLayoutEffect(() => setDrawers((s) => has[s]))
  const [drawn, setDrawn] = useState<Side | null>(null)
  const boxes = { left: useRef<HTMLDivElement>(null), right: useRef<HTMLDivElement>(null) }, shade = useRef<HTMLDivElement>(null)
  const drag = useRef<Drag | null>(null)
  const pos = useRef(0), flight = useRef<Animation[]>([])

  const flying = () => flight.current.some((a) => a.playState === "running")
  const shown = (s: Side) => {
    const el = boxes[s].current
    if (!el || !flying()) return pos.current
    return Math.max(0, Math.min(1, 1 - Math.abs(shownAt(el)) / (el.offsetWidth || width())))
  }
  const put = (s: Side, p: number) => {
    const el = boxes[s].current, bg = shade.current
    if (!el || !bg) return
    el.style.transform = shift(s, p)
    bg.style.opacity = String(p)
    bg.style.pointerEvents = p > 0 ? "auto" : "none"
  }
  const place = (s: Side, p: number) => {
    for (const a of flight.current) a.cancel()
    flight.current = []
    pos.current = p
    put(s, p)
  }
  /** `v`: the finger's speed toward open, px/ms. True once it lands, false if caught or sent elsewhere first. */
  const slide = (s: Side, to: number, v = 0): Promise<boolean> => {
    const from = shown(s), el = boxes[s].current, bg = shade.current
    place(s, to)
    if (!el || !bg || !moves() || Math.abs(to - from) < 0.002) return Promise.resolve(true)
    const r = response(), w = el.offsetWidth || width()
    const sp = spring(r, 1, Math.max(-20, Math.min((2 * Math.PI) / r, (v * 1000) / w / (to - from))))
    const o = { duration: sp.ms, easing: sp.easing }
    flight.current = [el.animate([{ transform: shift(s, from || 0.001) }, { transform: shift(s, to || 0.001) }], o), bg.animate([{ opacity: from }, { opacity: to }], o)]
    return flight.current[0].finished.then(() => true, () => false)
  }
  const putAway = (s: Side) => { if (!out() && !drag.current) { place(s, 0); setDrawn(null) } }
  const shut = (s: Side, v = 0) => {
    let due = true
    const off = trackSoon("the drawer closing", () => due)
    void slide(s, 0, v).then((landed) => { due = false; off(); if (landed) putAway(s) })
  }

  useEffect(() => {
    if (side) {
      if (drawn && drawn !== side) place(drawn, 0)
      setDrawn(side)
      const a = document.activeElement
      if (a instanceof HTMLElement && a.closest("#main-scroll")) a.blur()
      if (pos.current !== 1 || drawn !== side) requestAnimationFrame(() => void slide(side, 1))
      return
    }
    if (drawn && pos.current !== 0) shut(drawn)
    // eslint-disable-next-line react-hooks/exhaustive-deps -- runs only when a drawer opens or closes
  }, [side])

  const begin = (e: PointerEvent | React.PointerEvent, on: Side | null) => {
    if (e.pointerType === "mouse" && e.button) return
    drag.current?.quit?.()
    const s = on ?? (drawn && flying() ? drawn : null), caught = !!s && flying(), from = s ? shown(s) : 0
    if (caught) place(s, from)
    const x = e.clientX, edge: Side | null = x < EDGE ? "left" : x > innerWidth - EDGE ? "right" : null
    drag.current = { side: s, el: elementOf(e.target), edge, x, y: e.clientY, t: e.timeStamp, axis: null, from, p: from, lock: x, caught, moves: [[e.timeStamp, x]] }
  }
  const drop = (d: Drag) => {
    drag.current = null
    if (!d.caught || !d.side) return
    if (out() === d.side) void slide(d.side, 1)
    else shut(d.side)
  }
  const lock = (d: Drag, s: Side, e: PointerEvent) => {
    d.side = s
    d.axis = "x"
    d.lock = e.clientX
    claimSideways("drawer")
    holdPage(true)
    try { elementOf(e.target)?.setPointerCapture(e.pointerId) } catch {}
    d.quit = onAway(() => end())
    if (drawn !== s) flushSync(() => setDrawn(s))
  }
  const move = (e: PointerEvent) => {
    const d = drag.current
    if (!d) return
    const mx = e.clientX - d.x, my = e.clientY - d.y
    if (!d.axis) {
      if (fingerHolding()) return drop(d)
      if (Math.hypot(mx, my) < SLOP) return
      const s = d.side ?? (mx > 0 ? "left" : "right")
      if (!has[s] || !takes(d, s, mx, my, e.timeStamp)) return drop(d)
      lock(d, s, e)
    }
    const s = d.side
    if (!s) return
    const dx = mx - (d.lock - d.x) * Math.max(0, 1 - Math.abs(e.clientX - d.lock) / EASE_IN)
    d.moves.push([e.timeStamp, e.clientX])
    if (d.moves.length > 8) d.moves.shift()
    d.p = Math.max(0, Math.min(1, d.from + ((s === "left" ? 1 : -1) * dx) / width()))
    put(s, d.p)
    pos.current = d.p
  }
  const end = (e?: PointerEvent) => {
    const d = drag.current
    drag.current = null
    releaseSideways("drawer")
    holdPage(false)
    d?.quit?.()
    if (!d) return
    if (d.axis !== "x" || !d.side) return drop(d)
    const lifted = e?.type === "pointerup"
    if (lifted) eatClick()
    const v = (d.side === "left" ? 1 : -1) * (lifted ? fling(d.moves, e.timeStamp) : 0)
    const toOpen = opens(d, v)
    if (toOpen !== (out() === d.side)) haptic("soft")
    if (toOpen) void slide(d.side, 1, v)
    else shut(d.side, v)
    open(toOpen ? d.side : null)
  }
  const live = useRef({ side, begin, move, end })
  useLayoutEffect(() => { live.current = { side, begin, move, end } })
  useEffect(() => {
    const down = (e: PointerEvent) => {
      const g = live.current
      if (drag.current && !e.isPrimary) return g.end()
      if (e.pointerType !== "touch" || !e.isPrimary || g.side || isDesktop()) return
      const el = elementOf(e.target)
      if (el && onPage(el)) g.begin(e, null)
    }
    const move = (e: PointerEvent) => { if (drag.current && e.isPrimary) live.current.move(e) }
    const up = (e: PointerEvent) => { if (drag.current && e.isPrimary) live.current.end(e) }
    const quit = new AbortController(), opts = { capture: true, passive: true, signal: quit.signal }
    addEventListener("pointerdown", down, opts)
    addEventListener("pointermove", move, opts)
    addEventListener("pointerup", up, opts)
    addEventListener("pointercancel", up, opts)
    return () => quit.abort()
  }, [])

  return { boxes, shade, drawn, begin }
}
