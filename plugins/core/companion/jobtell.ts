import type { z } from "zod"
import { parseTerminal } from "../../../core/agents.ts"
import { logger, type OpCtx, OpError } from "../../../core/plugins.ts"
import { gist, type Job, landTask, linkOf, messageOf, prunedLine, resumeOf, terminalOf } from "./jobs.ts"
import { type Clock, type JobEvent, stuckLine, untell } from "./joblife.ts"
import { COMPANION, THEM } from "./jobtold.ts"
import { plainWords } from "./jobword.ts"
import type { Link, workerLinks } from "./links.ts"
import type { Moment } from "./types.ts"
import type { JobDeps, Seen } from "./workers.ts"
import type { JobLogRow } from "./rows.ts"

const log = logger("companion")

export type TellDeps = {
  all: () => Job[]; changed: () => void; move: (j: Job, ev: JobEvent, t?: number) => boolean; log: { append: (t: number, rows: z.infer<typeof JobLogRow>[]) => void }
  clockOf: (j: Job) => Clock; sending: Set<string>; links: ReturnType<typeof workerLinks>; setting: (k: string) => string; d: JobDeps
  seenOf: (j: Job, turn?: boolean, diff?: boolean) => Promise<Seen>; ended: (j: Job, s: Seen) => Promise<boolean>; refresh: (j: Job, now?: boolean) => Promise<void>
  stuck: (j: Job, s: Seen) => string
}

export function jobTell(o: TellDeps) {
  const { all, changed, move, log: jobLog, clockOf, sending, links, setting, d, seenOf, ended, refresh, stuck } = o
  const unreached = (j: Job, why: string) => new OpError(`${j.id} ${why}, so a follow-up can't reach its session: restart it first (companion job-answer ${j.id} --choice "Restart it": its conversation is kept), then tell it again (${linkOf(j)})`, 409)
  async function wake(ctx: OpCtx, j: Job, prompt = "") {
    const s = await seenOf(j).catch(() => null)
    if (!s || s.running) return false
    if (!j.exited && !s.unreachable && await ended(j, s)) changed()
    if (!j.session) throw new OpError(`${j.id}'s terminal ended and its conversation isn't known: hand it off again`, 409)
    await startIn(ctx, j, prompt, j.session)
    return true
  }
  async function startIn(ctx: OpCtx, j: Job, prompt: string, session?: string) {
    await trust(ctx, j)
    j.terminal = await links.of(j.where).start(ctx, startOf(j, { ...(prompt ? { prompt } : {}), ...(session ? { session } : {}) }))
    delete j.exited; delete j.closed
    clockOf(j).opened = Date.now()
  }
  const startOf = (j: Job, o: { prompt?: string; session?: string }) => {
    const w = j.where, mode = w.agent.split("_")[0] === "claude" ? setting("jobs_mode") : ""
    return { agent: w.agent, cwd: w.cwd, name: j.title, ...o, ...(w.model ? { model: w.model } : {}), ...(w.effort ? { effort: w.effort } : {}), ...(mode ? { mode } : {}), ...(w.cloud && w.base ? { base: w.base } : {}) }
  }
  async function fresh(ctx: OpCtx, j: Job, text: string, shown = text, by = COMPANION) {
    if (j.state === "stopped") throw new OpError(`${j.id} was stopped: hand it off again`, 409)
    const link = links.of(j.where), old = j.terminal, was = await seenOf(j).catch(() => null)
    text = await link.carry(text)
    await startIn(ctx, j, text)
    delete j.session
    if (was?.running) await link.end(ctx, old).catch(() => {})
    toldFrom(j, by, text)
    toldNow(j, `Started fresh: ${gist(shown, 120)}`)
  }
  async function retitle(ctx: OpCtx, j: Job, title: string) {
    j.title = title.replace(/\s+/g, " ").trim().slice(0, 80)
    await ctx.op("terminal.rename", { id: terminalOf(j), name: j.title }).catch(() => {})
    changed()
  }
  async function steer(ctx: OpCtx, j: Job, text: string, shown = text, by = COMPANION, how: "tell" | "land" = "tell") {
    if (j.state === "stopped") throw new OpError(`${j.id} was stopped: hand it off again`, 409)
    const link = links.of(j.where)
    text = await link.carry(j.pruned ? `${prunedLine(j.where)} ${text}` : text)
    delete j.pruned
    const s = await seenOf(j).catch(() => null)
    if (s?.running !== false && !await typedOrGone(ctx, j, s, text, shown, by, how)) return
    if (!await wake(ctx, j, text)) throw new OpError(`${j.id}'s terminal can't be reached now: try again (${linkOf(j)})`, 502)
    toldFrom(j, by, text)
    toldNow(j, `Told: ${gist(shown, 120)}`)
  }
  async function typedOrGone(ctx: OpCtx, j: Job, s: Seen | null, text: string, shown: string, by: string, how: "tell" | "land") {
    if (s) takes(j, s)
    const was = { state: j.state, turn: j.turn, now: j.now, at: j.at }
    toldNow(j, `Told: ${gist(shown, 120)}`)
    const x = j.state === was.state ? undefined : j.log.at(-1)
    sending.add(j.id)
    const sent = Date.now()
    const back = () => {
      const b = untell(j, x, was), t = Date.now()
      if (b) jobLog.append(t, [{ t, job: j.id, ev: "untold", ...b }])
      changed()
    }
    let r: Awaited<ReturnType<Link["tell"]>>
    try { r = await links.of(j.where)[how](ctx, j.terminal, text) } catch (e) {
      back()
      if ((await seenOf(j).catch(() => null))?.running === false) return true
      throw e
    } finally { sending.delete(j.id) }
    if (r.submitted === false) { back(); throw new OpError(`it didn't take it: ${r.why ?? "its input kept the text"} (${linkOf(j)})`, 409) }
    if (r.submitted !== true && await drewNothing(j, sent)) { back(); throw unreached(j, "drew nothing on its screen once it was sent (it seems stuck)") }
    toldFrom(j, by, text)
    void refresh(j).catch((e) => log.error("jobs", e))
    return false
  }
  function takes(j: Job, s: Seen) {
    const stuckWhy = stuck(j, s)
    if (stuckWhy) throw unreached(j, stuckWhy)
    if (s.state === "blocked" && s.kind === "permission") throw new OpError(`${j.id} waits on a permission in its terminal (${s.msg ?? "open it"}): only the user answers it (its notification, or job-answer on their words; ${linkOf(j)})`, 409)
  }
  async function drewNothing(j: Job, sent: number) {
    const after = await seenOf(j).catch(() => null)
    return !!after?.running && after.state === "working" && after.quiet !== undefined && after.quiet >= Date.now() - sent
  }
  function toldFrom(j: Job, by: string, text: string) {
    (j.tells ??= []).push({ at: Date.now(), by, text: text.replace(/\s+/g, " ").trim().slice(0, 300) })
    if (j.tells.length > 8) j.tells.splice(0, j.tells.length - 8)
  }
  async function trust(ctx: OpCtx, j: Job) {
    const w = j.where, by = j.by ?? ""
    if (!w.repo || w.cloud || w.agent.split("_")[0] !== "claude" || !(by === COMPANION || by === THEM || by.startsWith(`${COMPANION} (`))) return
    // (Claude Code's "Trust this folder?" answered in the job's account)
    const body = { cwd: w.cwd, account: parseTerminal(`${w.agent}-x`)?.profile || "default" }
    try { await links.of(w).there(ctx, "claude-code.trust", body, 10) } catch (e) { log.error(`jobs: ${j.id}: trust: ${messageOf(e)}`) }
  }
  function toldNow(j: Job, line: string) {
    move(j, "told")
    j.turn = Date.now()
    j.now = line
    delete clockOf(j).rest
    changed()
  }

  async function land(ctx: OpCtx, j: Job, note = "", shown?: string, by = COMPANION) {
    const was = j.land
    j.land = { asked: Date.now() }
    try { await steer(ctx, j, [landTask(j.where), note].filter(Boolean).join(" "), shown ?? "Kept: merge it", by, "land") } catch (e) { j.land = was; throw e }
  }
  async function close(ctx: OpCtx, j: Job) {
    if (move(j, "stop")) { j.seen = true; changed() }
    if (!j.terminal) return
    await endIt(ctx, j)
    const to = j.where.cloud ? "" : resumeOf(j)
    if (to && to !== j.terminal) { j.terminal = to; changed() }
  }
  const endIt = (ctx: OpCtx, j: Job) => links.of(j.where).end(ctx, j.terminal).catch((e: unknown) => { if (!(e instanceof OpError && (e.status === 404 || e.status === 502))) throw e })
  async function restart(ctx: OpCtx, j: Job, by = COMPANION) {
    if (j.where.cloud) throw new OpError(`a cloud session restarts in its session: companion job-open ${j.id}`, 409)
    if (!j.session) throw new OpError(`${j.id}'s conversation isn't known, so it can't be resumed: hand it off again`, 409)
    const why = j.waits?.kind === "stuck" ? stuckLine(j.waits.question) : "seemed stuck"
    await endIt(ctx, j)
    for (let i = 0; i < 40; i++) {
      const s = await seenOf(j).catch(() => null)
      if (!s?.running) break
      await new Promise((r) => setTimeout(r, 250))
    }
    const prompt = `(Vaultite restarted this session: it ${why}. Carry on with your task from where you were; a command you were running may need running again.)`
    await startIn(ctx, j, prompt, j.session)
    delete j.waits
    delete clockOf(j).kept
    toldFrom(j, by, prompt)
    toldNow(j, "Restarted: it seemed stuck")
  }
  const jobOver = (m: Moment | undefined) => { const to = m?.pane ? d.paneTo?.(m.pane) ?? "" : ""; return to ? all().find((x) => linkOf(x) === to) : undefined }
  function unsure(j: Job, m: Moment | undefined, which: string) {
    const over = jobOver(m)
    if (!over || over.id === j.id) return ""
    const w = plainWords(which)
    if (w && m?.text && ` ${plainWords(m.text)} `.includes(` ${w} `)) return ""
    const short = (x: Job) => x.title.split(/\s+/).slice(0, 4).join(" ")
    return `their ask was over the job "${over.title}" (${over.id}), not "${j.title}" (${j.id}): unless their words name the one they mean (then which: those words), ask them which in one short line ("${short(j)}, or ${short(over)}?"), each a button (draw: a button each, its ask the job's name, the question in its say)`
  }
  return { wake, fresh, retitle, steer, trust, startOf, land, close, restart, unsure }
}
export type Tell = ReturnType<typeof jobTell>
