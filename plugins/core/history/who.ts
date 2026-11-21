export type Kind = "you" | "agent" | "cli" | "script" | "disk"
export type Change = { t: number; last?: number; actor: { kind: Kind; name: string; device?: string }; action: string; paths?: string[]; method?: string }
export type Writer = { by: string; kind: Kind; device?: string }

/** A coding agent tells its hook of an edit after the write. */
const HOOK_LAG = 3000
/** Linux dates an mtime from a coarse clock: up to a tick before the request that wrote it began. */
const MTIME_LAG = 20
/** A file watcher sees a change (iCloud, another app) up to this long after the write. */
const NOTICED = 10_000
const AFTER = 5000

const theApp = (e: Change) => e.actor.kind === "script" && e.actor.name === "Vaultite"
const lagOf = (e: Change) => (e.actor.kind === "disk" ? NOTICED : e.method ? MTIME_LAG : HOOK_LAG)

export function changesTo(changes: Change[], rel: string) {
  return changes.filter((e) => e.paths?.includes(rel) && !theApp(e))
}

/** The writer whose change came last before the write (a request after another's is its own), Activity's runs of one
 *  writer's changes each at its last one before it. */
export function writerAt(changes: Change[], t: number): Writer | undefined {
  let best: Change | undefined, at = -Infinity
  for (const e of changes) {
    const lag = lagOf(e), end = e.last ?? e.t
    if (t < e.t - lag || t > end + AFTER) continue
    const when = end <= t + lag ? end : e.t
    const disk = e.actor.kind === "disk"
    if (!best || (best.actor.kind === "disk" && !disk) || (disk === (best.actor.kind === "disk") && when > at)) { best = e; at = when }
  }
  if (!best) return undefined
  return { by: best.actor.name, kind: best.actor.kind, ...(best.actor.device ? { device: best.actor.device } : {}) }
}

export function lastByAgents(changes: Change[], hidden: (p: string) => boolean) {
  const last = new Map<string, Change>()
  for (const e of changes) {
    if (theApp(e)) continue
    for (const p of e.paths ?? []) {
      const was = last.get(p)
      if (!was || (e.last ?? e.t) >= (was.last ?? was.t)) last.set(p, e)
    }
  }
  return [...last].flatMap(([path, e]) => (e.actor.kind === "agent" && !hidden(path) ? [{ path, by: e.actor.name, t: e.last ?? e.t }] : []))
    .sort((a, b) => b.t - a.t)
}
