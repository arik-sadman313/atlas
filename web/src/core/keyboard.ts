import { useEffect, useLayoutEffect, useState, useSyncExternalStore, type ReactNode } from "react"

/** The on-screen keyboard is up: the visible part of the page is well short of the window. */
export const keyboardUp = () => !!visualViewport && innerHeight - visualViewport.height > 80

const TYPING = "textarea,[contenteditable=true],input:is(:not([type]),[type=text],[type=search],[type=url],[type=email],[type=tel],[type=password],[type=number])"

export const typesText = (el: Element | null): el is HTMLElement =>
  el instanceof HTMLElement && el.matches(TYPING) && !el.matches("[readonly],[disabled],[inputmode=none]")

export function useTypedYet(on: boolean) {
  const [yet, setYet] = useState(false)
  useEffect(() => {
    if (!on || yet) return
    const typed = () => { if (typesText(document.activeElement)) setYet(true) }
    typed()
    addEventListener("focusin", typed)
    return () => removeEventListener("focusin", typed)
  }, [on, yet])
  return yet
}

const SETTLE_MS = 160

type Area = { top: number; height: number; keyboard: boolean; moving: boolean }
const same = (a: Area | null, b: Area) => !!a && a.top === b.top && a.height === b.height && a.keyboard === b.keyboard && a.moving === b.moving

/** The part of the window the user sees (above the on-screen keyboard), followed while `on`. */
export function useVisibleArea(on: boolean) {
  const [area, setArea] = useState<Area | null>(null)
  useLayoutEffect(() => {
    const vv = visualViewport
    if (!on || !vv) return
    let still = 0, later: number[] = [], seen = { top: Number.NaN, height: Number.NaN }
    const at = (moving: boolean) => {
      seen = { top: vv.offsetTop, height: vv.height }
      const n = { ...seen, keyboard: keyboardUp(), moving }
      setArea((a) => (same(a, n) ? a : n))
    }
    const read = () => { at(true); clearTimeout(still); still = window.setTimeout(() => at(false), SETTLE_MS) }
    const lookAgainAsIosMayEndItsSlideUntold = () => {
      for (const t of later) clearTimeout(t)
      later = [400, 1000].map((ms) => window.setTimeout(() => { if (vv.offsetTop !== seen.top || vv.height !== seen.height) read() }, ms))
    }
    const moved = () => { read(); lookAgainAsIosMayEndItsSlideUntold() }
    at(false)
    lookAgainAsIosMayEndItsSlideUntold()
    vv.addEventListener("resize", moved)
    vv.addEventListener("scroll", moved)
    document.addEventListener("focusin", lookAgainAsIosMayEndItsSlideUntold)
    document.addEventListener("focusout", lookAgainAsIosMayEndItsSlideUntold)
    return () => {
      clearTimeout(still); for (const t of later) clearTimeout(t)
      vv.removeEventListener("resize", moved); vv.removeEventListener("scroll", moved)
      document.removeEventListener("focusin", lookAgainAsIosMayEndItsSlideUntold); document.removeEventListener("focusout", lookAgainAsIosMayEndItsSlideUntold)
    }
  }, [on])
  return on ? area : null
}

export type BarKey = { name: string; label: ReactNode; run: () => void }

/** Keys over the keyboard, before Done, while a field it `owns` has it; one drawing its own bar sits in `[data-own-keys]`. */
export type FieldKeys = { label: string; owns: (field: HTMLElement) => boolean; keys: () => BarKey[]; scroll?: boolean }

const given: FieldKeys[] = []
const told = new Set<() => void>()
let version = 0
const tell = () => { version++; for (const fn of told) fn() }

export function giveKeys(k: FieldKeys) {
  given.push(k); tell()
  return () => { const i = given.indexOf(k); if (i >= 0) { given.splice(i, 1); tell() } }
}

export function useGiveKeys(k: FieldKeys | null) {
  useLayoutEffect(() => (k ? giveKeys(k) : undefined), [k])
}

export const keysFor = (field: HTMLElement) => given.findLast((k) => k.owns(field)) ?? null

export const useKeysGiven = () => useSyncExternalStore((fn) => { told.add(fn); return () => told.delete(fn) }, () => version)
