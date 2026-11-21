import fs from "node:fs"
import path from "node:path"
import { z } from "zod"

const CUT = z.object({ t: z.number(), what: z.enum(["press", "turn"]), heard: z.string().optional(), audio: z.string().optional() })
export type Cut = z.infer<typeof CUT>
export const TELL_MS = 6 * 3600_000
const file = (dir: string) => path.join(dir, "cut.json")

export function keepCut(dir: string, c: Cut) {
  try { fs.mkdirSync(dir, { recursive: true }); fs.writeFileSync(file(dir), JSON.stringify(c)) } catch { return }
}

export function takeCut(dir: string, now = Date.now()): Cut | null {
  let json: unknown
  try { json = JSON.parse(fs.readFileSync(file(dir), "utf8")) } catch { return null }
  fs.rmSync(file(dir), { force: true })
  const c = CUT.safeParse(json).data
  return c && now - c.t < TELL_MS ? c : null
}

const clip = (s: string) => (s.length > 140 ? `${s.slice(0, 140).trimEnd()}…` : s)
const clock = (t: number) => new Date(t).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })

export function cutWords(c: Cut, at = clock) {
  const when = at(c.t)
  if (c.what === "turn") return { title: "The companion's answer was cut off", body: `Vaultite restarted at ${when} while the companion was answering${c.heard ? ` "${clip(c.heard)}"` : ""}. Its answer may be in its conversation; ask again if it isn't.` }
  return { title: "Your ask didn't reach the companion", body: c.heard ? `Vaultite restarted at ${when} while you were saying "${clip(c.heard)}". Say it again.` : `Vaultite restarted at ${when} while you held the Talk key. Say it again.` }
}
