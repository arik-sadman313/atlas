import { useEffect, useState } from "react"
import { get, notifyError, post, splitMachine } from "@vaultite"
import type { LiveAsk } from "./livetabs"

export type Outcome = { kind: "open" } | { kind: "done" } | { kind: "cant"; note: string } | { kind: "elsewhere" }

export const machineOf = (a: LiveAsk) => splitMachine(a.terminal ?? "")[1] || a.machine || ""

export function useAskerAlive(ask: LiveAsk | null) {
  const [heard, setHeard] = useState<{ terminal: string; alive: boolean } | null>(null)
  const terminal = ask?.terminal ?? "", machine = ask ? machineOf(ask) : ""
  useEffect(() => {
    if (!terminal) return
    let stop = false
    const [bare] = splitMachine(terminal)
    const look = () => void get<{ sessions: { id: string }[] }>(machine ? `machines/${encodeURIComponent(machine)}/terminals/sessions` : "terminals/sessions")
      .then((r) => { if (!stop) setHeard({ terminal, alive: r.sessions.some((s) => s.id === bare) }) }, () => {})
    look()
    const timer = setInterval(look, 10_000)
    return () => { stop = true; clearInterval(timer) }
  }, [terminal, machine])
  return heard && heard.terminal === terminal ? heard.alive : null
}

export function useAnswer(now: LiveAsk | null | undefined, tab: string) {
  const [last, setLast] = useState<LiveAsk | null>(now ?? null)
  const [outcome, setOutcome] = useState<Outcome>({ kind: "open" })
  if (now && now.at !== last?.at) { setLast(now); setOutcome({ kind: "open" }) }
  else if (now === null && last && outcome.kind === "open") setOutcome({ kind: "elsewhere" })
  const answer = (o: Exclude<Outcome, { kind: "open" | "elsewhere" }>) => {
    setOutcome(o)
    post(`web-viewer/tabs/${tab}/done`, o.kind === "cant" ? { cant: true, note: o.note } : {})
      .catch((e) => { setOutcome({ kind: "open" }); notifyError(e, "Couldn't tell the agent") })
  }
  return { ask: last, outcome, answer }
}
