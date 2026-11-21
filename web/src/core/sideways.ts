import { trackSoon } from "@/core/unsaved"

// A phone's sideways swipe has one owner (a drawer, a split's pager, a row): each checks the others' rules as it locks.

export const EDGE = 24

export type Owner = "drawer" | "pager" | "row"
let owner: Owner | null = null
export const sidewaysOwner = () => owner
export const claimSideways = (who: Owner) => { owner = who }
export const releaseSideways = (who: Owner) => { if (owner === who) owner = null }

let drawers: (side: "left" | "right") => boolean = () => false
export const drawerOn = (side: "left" | "right") => drawers(side)
export const setDrawers = (has: typeof drawers) => { drawers = has }

const FIELD = ":is(input:not([type=checkbox], [type=radio], [type=button]), textarea, select):focus, [data-keeps-touch]"

export function movesItself(el: Element | null, top: Element, dx: number) {
  if (!el || el.closest(FIELD)) return true
  for (let a: Element | null = el; a && a !== top && a !== document.body; a = a.parentElement) {
    const cs = getComputedStyle(a), ta = cs.touchAction
    if ((ta === "none" || (ta.includes("pan-y") && !ta.includes("pan-x"))) && !a.matches("[data-phone-bar], [data-swipe-row]")) return true
    if (/auto|scroll/.test(cs.overflowX) && a.scrollWidth > a.clientWidth + 1) {
      if (dx < 0 ? a.scrollLeft + a.clientWidth < a.scrollWidth - 1 : a.scrollLeft > 0) return true
    }
  }
  return false
}

export function rowTakes(el: Element | null, dx: number) {
  const row = el?.closest<HTMLElement>("[data-swipe-row]")
  return !!row && (row.dataset.swiped !== undefined || Math.sign(dx) === Number(row.dataset.swipeWay ?? -1))
}

export function selectingIn(top: Element) {
  const s = getSelection()
  return !!s && !s.isCollapsed && !!s.anchorNode && top.contains(s.anchorNode)
}

/** The click a swipe's lift may still send, not the next touch's. */
export function eatClick() {
  const quit = new AbortController(), off = trackSoon("a swipe's click eaten", () => true)
  let on = true
  const stop = () => { if (on) { on = false; quit.abort(); off() } }
  addEventListener("click", (c) => { c.stopPropagation(); c.preventDefault(); stop() }, { capture: true, signal: quit.signal })
  addEventListener("pointerdown", stop, { capture: true, signal: quit.signal })
  setTimeout(stop, 400)
}
