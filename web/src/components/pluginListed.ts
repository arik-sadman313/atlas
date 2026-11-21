import { useEffect, useEffectEvent, useReducer, useState } from "react"

type Listing<T> = { available: boolean; error?: string; entries: T[] }

export function useListed<T extends { id: string }>(ask: (() => Promise<Listing<T>>) | null, id: string, seenIn: Map<string, T>, key: string, again: number) {
  const [e, setE] = useState<T | null | undefined>(() => seenIn.get(key))
  const [unreached, setUnreached] = useState<Error | undefined>(undefined)
  const [tries, retry] = useReducer((n: number) => n + 1, 0)
  const read = useEffectEvent(() => ask?.())
  const asks = !!ask
  useEffect(() => {
    let live = true
    read()?.then((f) => {
      if (!live) return
      const known = f.entries.find((x) => x.id === id) ?? seenIn.get(key)
      if (known) seenIn.set(key, known)
      setUnreached(known || f.available ? undefined : new Error(f.error || "the listing can't be reached right now"))
      setE(known ?? (f.available ? null : undefined))
    }, (err) => { if (live) setUnreached(seenIn.get(key) ? undefined : err || new Error("no answer")) })
    return () => { live = false }
  }, [again, id, key, seenIn, asks, tries])
  return { e, unreached, retry }
}
