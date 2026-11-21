import { useEffect, useSyncExternalStore } from "react"
import { notify } from "@/core/notify"

export const GRACE = 10_000
const ID = "live"

let since: number | null = null
let offline = false
let grace: ReturnType<typeof setTimeout> | null = null
let askedAgain = false
let checker = () => {}
const subs = new Set<() => void>()
const backSubs = new Set<(wasOffline: boolean) => void>()

function setOffline(next: boolean) {
  if (offline === next) return
  offline = next
  subs.forEach((fn) => fn())
}

const tell = () => notify(typeof navigator !== "undefined" && navigator.onLine === false ? "You're offline" : "Can't connect to Vaultite",
  { id: ID, duration: Infinity, action: { label: "Try now", run: tryNow } })

function tryNow() {
  askedAgain = true
  checker()
}

export const isOffline = () => offline

export const useOffline = () => useSyncExternalStore(subscribe, isOffline, isOffline)
function subscribe(fn: () => void) {
  subs.add(fn)
  return () => { subs.delete(fn) }
}

export function onReconnect(fn: (wasOffline: boolean) => void) {
  backSubs.add(fn)
  return () => { backSubs.delete(fn) }
}

export function useOnReconnect(fn: (wasOffline: boolean) => void, on = true) {
  useEffect(() => (on ? onReconnect(fn) : undefined), [on, fn])
}

export const checkServer = () => checker()

export const WRITE_CHECK = 10_000

export function untilUnreachable() {
  const c = new AbortController()
  const lost = () => { if (offline) c.abort() }
  const late = setTimeout(() => (offline ? lost() : checker()), WRITE_CHECK)
  subs.add(lost)
  return { signal: c.signal, end: () => { clearTimeout(late); subs.delete(lost) } }
}

export const setServerCheck = (fn: () => void) => { checker = fn }

export function lostServer() {
  if (typeof document !== "undefined" && document.visibilityState === "hidden") return
  if (offline && askedAgain) { askedAgain = false; tell() }
  if (since !== null) return
  since = Date.now()
  grace = setTimeout(() => { grace = null; setOffline(true); tell() }, GRACE)
}

export function forgetUntoldLoss() {
  if (offline || !grace) return
  clearTimeout(grace)
  grace = null
  since = null
}

export function reachedServer() {
  if (grace) { clearTimeout(grace); grace = null }
  since = null
  askedAgain = false
  const was = offline
  if (was) notify("Reconnected", { id: ID })
  setOffline(false)
  for (const fn of [...backSubs]) { try { fn(was) } catch (e) { console.error(e) } }
}
