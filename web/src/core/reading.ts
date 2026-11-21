import { useCallback, useEffect, useReducer, useRef, useState } from "react"
import { checkServer, useOnReconnect } from "@/core/connection"

export const SLOW = 4_000

export type Reading<T> = { value: T | undefined; error: unknown; slow: boolean; retry: () => void }

type Got<T> = { value: T | undefined; error: unknown }

/** Read again on deps, retry, and the server's return (a slow read: after an outage); the last value outlives a failure. */
export function useRead<T>(read: (() => Promise<T>) | null, deps: readonly unknown[], initial?: T): Reading<T> {
  const [got, setGot] = useState<Got<T>>(() => ({ value: initial, error: undefined }))
  const [slow, setSlow] = useState(false)
  const [tries, retry] = useReducer((n: number) => n + 1, 0)
  const latest = useRef(read)
  latest.current = read
  const reads = !!read
  useEffect(() => {
    const fn = latest.current
    if (!fn) return
    let on = true
    setGot((g) => (g.error === undefined ? g : { value: g.value, error: undefined }))
    setSlow(false)
    const late = setTimeout(() => { if (on) { setSlow(true); checkServer() } }, SLOW)
    fn().then((value) => { if (on) setGot({ value, error: undefined }) }, (error) => { if (on) setGot((g) => ({ value: g.value, error: error ?? new Error("Couldn't read it") })) })
      .finally(() => { clearTimeout(late); if (on) setSlow(false) })
    return () => { on = false; clearTimeout(late) }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- deps are the caller's: what the read depends on
  }, [...deps, reads, tries])
  const failed = got.error !== undefined
  const back = useCallback((wasOffline: boolean) => { if (failed || wasOffline) retry() }, [failed])
  useOnReconnect(back, failed || slow)
  return { value: got.value, error: got.error, slow, retry }
}
