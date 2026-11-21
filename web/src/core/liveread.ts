import { useEffect, useEffectEvent, useRef } from "react"
import { onReconnect } from "@/core/connection"
import { errorText } from "@/core/notify"
import { isNumber, isObj } from "../../../core/values.ts"

/** useLive's answer: `error` only while nothing of `path` shows, else `stale`: its answer kept through the failure (`cause`). */
export type Live<T> = { data: T | null; error: string | null; loading: boolean; stale: boolean; cause: Error | undefined; retry: () => void }

export type Failed = { text: string; cause: Error }
export const failedOf = (e: Error) => (was: Failed | null): Failed => {
  const text = errorText(e)
  return was?.text === text ? was : { text, cause: e ?? new Error("no answer") }
}

export function liveShown<T>(path: string | null, got: { path: string | null; data: T | null }, failed: Failed | null, retry: () => void): Live<T> {
  const own = got.data !== null && got.path === path
  return { data: got.data, error: own ? null : failed?.text ?? null, loading: !!path && got.data === null && !failed, stale: own && !!failed, cause: failed?.cause, retry }
}

export function mockedLive<T>(mock: Record<string, unknown>, path: string | null): Live<T> {
  const key = path && Object.keys(mock).find((k) => path === k || path.startsWith(`${k}?`))
  return { data: (key ? mock[key] : null) as T | null, error: null, loading: false, stale: false, cause: undefined, retry: () => {} }
}

export const statusOf = (e: Error | undefined) => (isObj(e) && isNumber(e.status) ? e.status : null)

export const BACKOFF = [2_000, 5_000, 15_000, 30_000]

export function askAgain(ask: () => void): () => void {
  let step = 0, last = 0
  let timer: ReturnType<typeof setTimeout> | null = null
  const shown = () => document.visibilityState !== "hidden"
  const wait = () => {
    if (timer) clearTimeout(timer)
    timer = shown() ? setTimeout(() => { step = Math.min(step + 1, BACKOFF.length - 1); now() }, BACKOFF[step]) : null
  }
  const now = () => {
    if (Date.now() - last >= 1_000) { last = Date.now(); ask() }
    wait()
  }
  const seen = () => { if (shown()) now(); else if (timer) { clearTimeout(timer); timer = null } }
  const offBack = onReconnect(now)
  addEventListener("online", now)
  document.addEventListener("visibilitychange", seen)
  wait()
  return () => {
    if (timer) clearTimeout(timer)
    offBack()
    removeEventListener("online", now)
    document.removeEventListener("visibilitychange", seen)
  }
}

export function useAskAgain(failed: boolean, ask: () => void, hidden: boolean) {
  const asked = useEffectEvent(() => { if (!hidden) ask() })
  useEffect(() => (failed ? askAgain(asked) : undefined), [failed])
  const shownAgain = useEffectEvent(() => { if (failed) ask() })
  const was = useRef(hidden)
  useEffect(() => {
    if (was.current && !hidden) shownAgain()
    was.current = hidden
  }, [hidden])
}
