import { execFileSync } from "node:child_process"
import fs from "node:fs"
import path from "node:path"
import type { Any, VaultTest } from "./harness.ts"
import { waitFor } from "../lib.ts"
import { request } from "../fakes.ts"
import { jobSite } from "./jobsite.ts"

export default async ($: VaultTest) => {
  const { asItsTool } = await import("../../../plugins/core/companion/chat.ts")
  const { api, app, check } = $
  const { tmp, roots, done } = jobSite()
  const { gitEnv } = await import("../../../core/gitenv.ts")

  // A cloud job (a fake cloud: claude-code's cloud services): placed there when its repo allows it, all pushed; started
  // from a checkout here, followed (its question, its landing found on main once fetched), told follow-ups, stopped.
  if (process.platform !== "win32") {
    const Wh = await import("../../../plugins/core/companion/where.ts")
    const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
    const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
    const asApp = request({ host: "127.0.0.1:8793", "x-vaultite-client": "app/desktop" }, { remote: "127.0.0.1" })
    const dir = path.join(roots[0], "cloudy"), bare = path.join(tmp, "cloudy.git"), gh = "https://github.com/lighthouse/cloudy.git"
    const c = (cwd: string, ...a: string[]) => execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@example.com", ...a], { cwd, stdio: "pipe", env: gitEnv() }).toString()
    fs.mkdirSync(dir, { recursive: true })
    c(tmp, "init", "-q", "--bare", bare)
    // (GitHub's address, fetched from a folder here: its remote says GitHub, its fetch reaches the folder)
    c(dir, "init", "-q", "-b", "main"); c(dir, "remote", "add", "origin", gh); c(dir, "config", `url.${bare}.insteadOf`, gh)
    fs.writeFileSync(path.join(dir, ".vaultite-jobs.json"), JSON.stringify({ cloud: true })); c(dir, "add", "."); c(dir, "commit", "-qm", "first"); c(dir, "push", "-q", "origin", "main")
    const base = c(dir, "rev-parse", "HEAD").trim()
    const cloud: Any = { started: [], told: [], status: "running", turn: null, reads: [] }
    cc["agent:claude"] = async () => ({ command: "sleep 60", cwd: null })
    cc["cloud-ready:claude"] = (account: string) => (account === "personal" ? "" : `no Claude Code account '${account}' here`)
    cc["cloud-start:claude"] = async (account: string, st: Any) => { cloud.started.push({ account, ...st }); return { session: "session_01cloudy", url: "https://claude.ai/code/session_01cloudy", title: "Footer" } }
    cc["cloud-tell:claude"] = async (account: string, session: string, text: string) => { cloud.told.push({ account, session, text }); return { submitted: true } }
    cc["cloud-read:claude"] = async (account: string, ids: string[], turns: string[]) => {
      cloud.reads.push(account)
      return { sessions: Object.fromEntries(ids.map((id) => [id, { status: cloud.status, title: "Footer", updated: Date.now() }])), turns: Object.fromEntries(turns.map((id) => [id, cloud.turn])) }
    }
    const job = async (id: string) => (await api("POST", "ops/companion.job", { id }))[1]
    const neverDone = (r: Any) => !r.log.some((x: Any) => x.to === "done")
    Wh.checkoutsIn(roots)
    try {
      await api("PATCH", "config/plugin/companion", { jobs_cloud: "personal", jobs_machine: "cloud", jobs_land: true })
      fs.writeFileSync(path.join(dir, "local.txt"), "x"); c(dir, "add", "."); c(dir, "commit", "-qm", "local only")
      let [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the footer", repo: "cloudy", say: "On it." }, agent))
      check("cloud: a repo with a commit only here stays here, saying it would be missing in the cloud",
        st === 200 && !b.where.startsWith("Cloud") && /the cloud: 1 unpushed commit it starts from would be missing in the cloud/.test(b.why) && !cloud.started.length, [st, b])
      if (b.link) await api("DELETE", `terminals/${String(b.link).split("/").pop()}`).catch(() => {})
      await asItsTool(() => api("POST", "ops/companion.job-stop", { id: b.id }, agent)).catch(() => {})
      c(dir, "reset", "-q", "--hard", base)
      ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the footer", repo: "cloudy", say: "On it." }, agent))
      const s0 = cloud.started[0]
      check("cloud: a job its repo lets run in the cloud goes there (jobs_machine names it), started in the cloud account from this checkout's pushed commit, its card linking its session",
        st === 200 && b.where.startsWith("Cloud, cloudy, Personal") && /all pushed: in the cloud/.test(b.why) && b.link === "view:web/https://claude.ai/code/session_01cloudy" &&
        s0?.account === "personal" && s0.repo === "lighthouse/cloudy" && s0.branch === "main" && s0.base === base && fs.realpathSync(s0.from) === fs.realpathSync(dir) &&
        /Fix the footer[^]*no vau[^]*git push origin HEAD:main/.test(s0.prompt) && !/worktree add/.test(s0.prompt), [st, b, s0])
      const working = await waitFor(async () => { const r = await job(b.id); return r.state === "working" && r }, 10000, 200)
      check("cloud: its session running, the job is working, read in its account", !!working && cloud.reads.every((a: string) => a === "personal"), working)
      cloud.status = "idle"
      cloud.turn = { prompt: "Fix the footer", text: "", at: Date.now(), final: false, files: [] }
      await new Promise((r) => setTimeout(r, 4000))
      const early = await job(b.id)
      cloud.turn = { prompt: "Fix the footer", text: "", at: Date.now(), final: true, files: [] }
      await new Promise((r) => setTimeout(r, 4000))
      const empty = await job(b.id)
      check("cloud: its session at rest with no answer yet, the job stays working, never done", [early, empty].every((r) => r.state === "working" && neverDone(r)), [early, empty])
      cloud.status = "running"
      cloud.status = "requires_action"
      cloud.turn = { prompt: "Fix the footer", text: "", at: Date.now(), final: false, files: [], asks: [{ question: "Which colour?", choices: ["Blue", "Red"] }] }
      const asks = await waitFor(async () => { const r = await job(b.id); return r.state === "needs you" && r }, 10000, 200)
      check("cloud: its question waits on them, with its choices", asks?.waits?.question === "Which colour?" && asks.waits.choices.join() === "Blue,Red", asks)
      const [sa, ra] = await api("POST", "ops/companion.job-answer", { id: b.id, choice: "Red" }, asApp)
      check("cloud: their answer goes to its session as its next message", sa === 200 && cloud.told.at(-1)?.text === "Red" && cloud.told.at(-1)?.session === "session_01cloudy", [sa, ra, cloud.told])
      cloud.status = "idle"
      cloud.turn = { prompt: "Red", text: "Verify runs in the background; I'll report when it ends.", at: Date.now(), final: true, files: [], awaits: { on: "npm run verify", since: Date.now(), n: 1 } }
      const waits = await waitFor(async () => { const r = await job(b.id); return r.now.startsWith("Waiting on npm run verify, since ") && r }, 8000, 300)
      await new Promise((r) => setTimeout(r, 2000))
      check("cloud: at rest with a task in the background, it stays working", !!waits && (await job(b.id)).state === "working", waits)
      // (it lands from afar: its commit on GitHub's main, found here once fetched)
      const other = path.join(tmp, "cloudy-far")
      c(tmp, "clone", "-q", "-b", "main", bare, other); fs.writeFileSync(path.join(other, "footer.txt"), "red"); c(other, "add", "."); c(other, "commit", "-qm", "fix: footer"); c(other, "push", "-q", "origin", "HEAD:main")
      const landed = c(other, "rev-parse", "HEAD").trim()
      cloud.status = "idle"
      cloud.turn = { prompt: "Red", text: `Merged: ${landed.slice(0, 10)} on main.`, at: Date.now(), final: true, files: ["/home/user/cloudy/footer.txt"] }
      const done = await waitFor(async () => { const r = await job(b.id); return r.state === "done" && r }, 20000, 300)
      check("cloud: its turn over saying Merged, its commit found on main once fetched: done", !!done && done.log.at(-1).ev === "landed" && /Merged/.test(done.result?.text ?? ""), done ?? await job(b.id))
      ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Make it blue after all", job: b.id, ask: false }, agent))
      check("cloud: a follow-up goes to its session", st === 200 && b.state === "working" && /^Make it blue after all/.test(cloud.told.at(-1)?.text ?? ""), [st, b, cloud.told.at(-1)])
      cloud.status = "running"
      await waitFor(async () => (await job(b.id)).state === "working", 5000, 200)
      const n = cloud.told.length
      ;[st] = await asItsTool(() => api("POST", "ops/companion.job-stop", { id: b.id }, agent))
      check("cloud: stopped while it works, its session is told to stop", st === 200 && cloud.told.length === n + 1 && /^Stop here/.test(cloud.told.at(-1).text), cloud.told.slice(n))
      const Wk = await import("../../../plugins/core/companion/workers.ts"), L = await import("../../../plugins/core/companion/joblife.ts")
      Wk.paced({ cloudQuiet: 3000 })
      cloud.status = "idle"; cloud.turn = null
      ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the header", repo: "cloudy", say: "On it." }, agent))
      const quiet = await waitFor(async () => { const r = await job(b.id); return r.state === "failed" && r }, 20000, 300)
      Wk.paced({ cloudQuiet: L.PACE.cloudQuiet })
      check("cloud: a session resting on with no answer fails its job, saying why, never done", [quiet].every((r) => !!r && /no answer: open it/.test(r.now) && neverDone(r)), quiet)
      await asItsTool(() => api("POST", "ops/companion.job-stop", { id: b.id }, agent)).catch(() => {})
      await api("PATCH", "config/plugin/companion", { jobs_cloud: "nobody" })
      const [sn, bn] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the header", repo: "cloudy", machine: "cloud", say: "On it." }, agent))
      check("cloud: asked for while it can't start sessions, refused saying why", sn === 409 && /can't run in the cloud: the cloud can't start sessions: no Claude Code account 'nobody'/.test(bn.error), [sn, bn])
    } finally {
      Wh.checkoutsIn()
      await api("PATCH", "config/plugin/companion", { jobs_cloud: "", jobs_machine: "auto", jobs_land: false })
      Object.assign(cc, was)
      for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
    }
  }
  done()
}
