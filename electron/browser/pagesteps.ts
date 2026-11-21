import type { EnginePage } from "./engine.ts"
import { scrubDeep } from "./pagesecrets.ts"

export type PageStep = { t: number; by: string; action: string; url: string; title: string; name?: string; value?: string; fields?: string[]
  site?: string; result?: string; failed?: string }
type Said = { action: string; name?: string; value?: string; fields?: { ref: string; name?: string }[]; site?: string; result?: string; failed?: string }
const KEPT = 200
const steps = new Map<number, PageStep[]>()

export function noteStep(p: EnginePage, t: number, by: string | undefined, said: Said) {
  const s: PageStep = { t, by: by ?? "", action: said.action, url: p.wc.getURL(), title: p.wc.getTitle() }
  for (const k of ["name", "value", "site", "result", "failed"] as const) if (said[k]) s[k] = said[k]
  if (said.fields) s.fields = said.fields.map((f) => f.name || f.ref)
  const list = steps.get(p.id) ?? []
  list.push(scrubDeep(s))
  if (list.length > KEPT) list.splice(0, list.length - KEPT)
  steps.set(p.id, list)
}
export const stepsIn = (id: number, since = 0) => (steps.get(id) ?? []).filter((s) => s.t >= since)
export const forgetSteps = (id: number) => steps.delete(id)
