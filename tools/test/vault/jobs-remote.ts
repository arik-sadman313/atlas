import { spawn } from "node:child_process"
import fs from "node:fs"
import path from "node:path"
import type { Any, VaultTest } from "./harness.ts"
import { waitFor } from "../lib.ts"
import { request } from "../fakes.ts"
import { portOf } from "../../../core/listening.ts"
import { jobSite } from "./jobsite.ts"

export default async ($: VaultTest) => {
  const { asItsTool } = await import("../../../plugins/core/companion/chat.ts")
  const { api, app, check } = $
  const J = await import("../../../plugins/core/companion/jobs.ts")
  const L = await import("../../../plugins/core/companion/joblife.ts")
  const { roots, repo, g, done } = jobSite()

  // Another machine's job: where and its worker asked of that machine's companion, its terminal started and ended there.
  {
    const http = await import("node:http")
    const calls: Any[] = []
    let stage = "working", farHas = true, landed = false, farLive = false, takes = true
    const verdicts: Any[] = []
    const server = http.createServer((req, res) => {
      const chunks: Buffer[] = []
      req.on("data", (d) => chunks.push(d))
      req.on("end", () => {
        const [op, qs] = req.url!.replace("/api/ops/", "").split("?"), raw = Buffer.concat(chunks), png = op === "companion.picture-take"
        const p = png ? { ...Object.fromEntries(new URLSearchParams(qs)), bytes: raw.length } : raw.length ? JSON.parse(String(raw)) : {}
        calls.push({ op, p, client: req.headers["x-vaultite-client"] })
        // (its worker fixing forward once it's told CI failed: its next turn says the fix's commit)
        if (op === "terminal.send" && stage === "merged") { stage = "fixed"; verdicts.splice(0, verdicts.length, { commit: "5e6f7a8b", live: true, final: true, outcome: "live", why: "5e6f7a8 is live here" }) }
        const merged = stage === "merged" ? "1a2b3c4d" : "5e6f7a8b"
        const out: Any = png ? { path: `/home/alice/.vaultite/local/companion/screens/${p.name}` } : op === "companion.where" ? (farHas ? { cwd: "/home/alice/Projects/site", repo: "site", base: "abc123", why: "as asked", refused: "", ...(farLive ? { live: true } : {}) }
            : { cwd: "/home/alice/Vault", repo: "", base: "", why: "nothing on screen named a project: the vault", from: "vault", refused: "" })
          : op === "companion.worker-start" ? { id: "claude-remote1" }
          : op === "companion.capacity" ? { jobs: 0, cap: 4, agents: ["claude"], accounts: ["default", "personal"] }
          : op === "companion.worker" ? (stage === "working" ? { running: true, state: "working", title: "✳ Editing the header", typed: Date.now(), ...(p.turn ? { turn: { text: "", files: [], at: 0, final: false, session: "rs1" } } : {}) }
            : stage === "gone" ? { running: false, exit: { code: 0, signal: 1 }, ...(p.turn ? { turn: { text: "Shipped the header.", files: ["/home/alice/Projects/site/a.ts"], at: Date.now(), final: false, session: "rs1" }, diff: "1 file changed, +2 -1" } : {}) }
            : stage === "landed" ? (p.cwd ? { running: false, onMain: landed, marks: { whole: "a".repeat(40), each: ["b".repeat(40)] } } : null)
            : stage === "merged" || stage === "fixed" ? { running: true, state: "idle", ...(p.turn ? { turn: { text: `Merged: ${merged} pushed to main.`, files: ["/home/alice/Projects/site/a.ts"], at: Date.now(), final: true }, diff: "1 file changed, +2 -1" } : {}), ...(p.cwd ? { onMain: true } : {}) }
            : { running: true, state: "idle", ...(p.turn ? { turn: { text: "Header done. Try https://studio.tail1.ts.net:8450", files: ["/home/alice/Projects/site/a.ts"], at: Date.now(), final: true }, diff: "1 file changed, +2 -1" } : {}) })
          : op === "terminal.end" ? { id: "claude-remote1" } : op === "terminal.send" ? (takes ? { submitted: true } : { submitted: false, why: "its input kept the text" }) : op === "app.version" ? { live: verdicts.length > 1 ? verdicts.shift() : verdicts[0] } : {}
        // (its machine failing to read its terminal)
        if (out === null) return void res.writeHead(500, { "Content-Type": "application/json" }).end(JSON.stringify({ error: "no such terminal" }))
        const none = op === "claude-code.limits" && p.account === "nope"
        res.writeHead(none ? 404 : 200, { "Content-Type": "application/json" }).end(JSON.stringify(none ? { error: "no Claude Code account 'nope' (default, personal)" } : out))
      })
    }).listen(0, "127.0.0.1")
    await new Promise((r) => server.once("listening", r))
    const url = `http://127.0.0.1:${portOf(server)}`
    const ms = app.plugins.find((p) => p.id === "machines")!.services, wasM = { ...ms }
    const studio = { id: "studio", label: "Studio", url, online: true, self: false, plugins: ["terminal", "companion"] }
    ms["machines"] = async () => [studio]
    ms["machines:machine"] = async (id: string) => (id === "studio" ? studio : null)
    const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
    let job: Any = null
    try {
      let [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the header", machine: "studio", cwd: "~/Projects/site" }, agent))
      job = b
      const start = calls.find((c) => c.op === "companion.worker-start")
      check("handoff: a routine one (no say) still announces itself in one short line",
        !!(await waitFor(async () => (await api("POST", "ops/companion.status", {}))[1].notes.some((n: Any) => n.kind === "say" && n.text === "Handed that off to a background agent."), 3000, 50)))
      check("handoff on another machine: its where asked there, its terminal started there in that folder, the card says so",
        st === 200 && b.link === "view:terminal/claude-remote1@studio" && b.where.startsWith("Studio, site") && !!calls.find((c) => c.op === "companion.where")?.client?.startsWith("machine/") &&
        start?.p.cwd === "/home/alice/Projects/site" && /Fix the header/.test(start?.p.prompt ?? ""), [st, b, calls])
      const working = await waitFor(async () => { const r = (await api("POST", "ops/companion.job", { id: job.id }))[1]; return r.state === "working" && r }, 10000, 200)
      check("jobs on another machine: read from its worker there; typed in there by the user, it's theirs (never closed by itself)", !!working && working.now === "Editing the header" && working.held === true, working)
      stage = "idle"
      const review = await waitFor(async () => { const r = (await api("POST", "ops/companion.job", { id: job.id }))[1]; return r.state === "ready for review" && r }, 15000, 300)
      check("jobs on another machine: its turn's end there, with the diff counted there and its preview link", !!review && review.result.diff === "1 file changed, +2 -1" &&
        review.result.link === "https://studio.tail1.ts.net:8450" && calls.some((c) => c.op === "companion.worker" && c.p.turn && c.p.base === "abc123"), review)
      ;[st, b] = await api("POST", "ops/companion.job-stop", { id: job.id })
      check("job-stop on another machine: its terminal ended there; reviewed, it's done", st === 200 && b.state === "done" && calls.some((c) => c.op === "terminal.end" && c.p.id === "claude-remote1"), [st, b, calls.at(-1)])
      // Its machine offline: a new job waits for it (shown so), a follow-up waits on its job, each sent once it's back.
      {
        const Wk = await import("../../../plugins/core/companion/workers.ts")
        Wk.paced({ flush: 1 })
        await api("PATCH", "config/plugin/companion", { mode: "quiet" })
        await waitFor(async () => (await api("POST", "ops/companion.status", {}))[1].mode !== "off", 5000, 50)
        const says = async () => (await api("POST", "ops/companion.status", {}))[1].notes.filter((n: Any) => n.kind === "say").map((n: Any) => n.text)
        const card = async (id: string) => (await api("POST", "ops/companion.jobs", {}))[1].jobs.find((x: Any) => x.id === id)
        ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Say hi", machine: "studio", cwd: "~/Projects/site", account: "nope" }, agent))
        check("handoff --account: an account that machine hasn't is refused, saying which there are", st === 404 && /nope/.test(b.error) && /personal/.test(b.error), [st, b])
        studio.online = false
        calls.length = 0
        ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the footer", machine: "studio", cwd: "~/Projects/site", account: "personal" }, agent))
        const waiting = b
        check("handoff to a machine that's offline: kept as a job waiting for it, in that account, said so; nothing started",
          st === 200 && b.state === "waiting" && b.queued === true && /Waiting for Studio to come back/.test(b.now) && /Personal/.test(b.where) && !calls.some((c) => c.op === "companion.worker-start") &&
          !!(await waitFor(async () => (await says()).includes("Studio is offline: the job starts there once it's back."), 3000, 50)), [st, b, calls])
        ;(await import("../../../plugins/core/companion/screensocket.ts")).screenMoment({ kind: "ask", agent: "Claude", text: "and make it red. Also, can you run things on my personal account?", app: "com.example.browser", title: "Site", sx: 10, sy: 20 })
        ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Make it red", job: waiting.id, ask: false }, agent))
        check("handoff --job to a job still waiting for its machine: added to its task, said so", st === 200 && b.state === "waiting" && !!(await waitFor(async () => (await says()).at(-1) === "Studio is still offline: that goes to its job once it's back.", 3000, 50)), [st, b])
        ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Make it red", job: waiting.id }, agent))
        check("handoff --job: the same follow-up again isn't kept twice", st === 200 && !!(await waitFor(async () => (await says()).at(-1) === "That's already waiting for Studio.", 3000, 50)), [st, b])
        studio.online = true
        const begun = await waitFor(() => calls.find((c) => c.op === "companion.worker-start"), 15000, 200)
        check("a job waiting for its machine starts there once it's back: in its account and folder, told its follow-up, never their words a follow-up left out",
          begun?.p.agent === "claude_personal" && begun.p.cwd === "/home/alice/Projects/site" && /Fix the footer/.test(begun.p.prompt) && /Also: Make it red/.test(begun.p.prompt) &&
          !/personal account\?/.test(begun.p.prompt), begun?.p)
        const started = await waitFor(async () => { const r = await card(waiting.id); return r && r.state !== "waiting" && r }, 10000, 200)
        check("a job started once its machine is back is no longer waiting", !!started && started.terminal === "claude-remote1" && !started.queued, started)
        studio.online = false
        ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Use bigger text", job: waiting.id }, agent))
        check("handoff --job to a job whose machine went offline: kept, its card waiting, said so",
          st === 200 && b.state === "waiting" && /to pass on a follow-up/.test(b.now) && !!(await waitFor(async () => (await says()).at(-1) === "Studio is offline: I'll pass that on to its job once it's back.", 3000, 50)) &&
          !calls.some((c) => c.op === "terminal.send"), [st, b])
        studio.online = true
        const sent = await waitFor(() => calls.find((c) => c.op === "terminal.send"), 15000, 200)
        check("a follow-up kept for its machine is typed in once it's back, and its card no longer waits",
          sent?.p.id === "claude-remote1" && /Use bigger text They said/.test(sent.p.text) && !!(await waitFor(async () => !(await card(waiting.id))?.queued, 5000, 200)), sent?.p)
        Wk.paced({ flush: L.PACE.flush })
        // Several handoffs in one turn (one tool call each, at once): one line naming the jobs, never the default line per call.
        const more: string[] = []
        for (const task of ["Ship the video card", "Fix dictation dropping words"]) {
          const was = (await says()).at(-1)
          ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task, say: `On it: ${task}.`, machine: "studio", cwd: "~/Projects/site" }, agent))
          more.push(b.id)
          await waitFor(async () => (await says()).at(-1) !== was, 3000, 50)
        }
        const was = (await says()).at(-1)
        const all = await asItsTool(() => Promise.all([waiting.id, ...more].map((job) => api("POST", "ops/companion.handoff", { task: "They can merge on their own", job, ask: false }, agent))))
        await waitFor(async () => (await says()).at(-1) !== was, 3000, 50)
        await new Promise((r) => setTimeout(r, 700))
        const tail = (await says()).slice(-2), last = tail[1] ?? ""
        check("handoffs in one turn: one line naming the jobs, said once", all.every(([st]) => st === 200) && tail[0] === was &&
          /^Passed that on to three jobs: [^.]+\.$/.test(last) && ["Fix the footer", "Ship the video card", "Fix dictation dropping words"].every((x) => last.includes(x)), [all.map(([st, b]) => [st, b.error]), tail])
        for (const id of more) await asItsTool(() => api("POST", "ops/companion.job-stop", { id }, agent)).catch(() => {})
        await asItsTool(() => api("POST", "ops/companion.job-stop", { id: waiting.id }, agent)).catch(() => {})
      }
      // Nothing tying it here (no machine, no folder, no preview or editor): to the always-on machine with this vault.
      Object.assign(studio, { standalone: true, vault: "v1" })
      ms["machines"] = async () => [{ id: "lap", label: "Lap", url: "http://127.0.0.1:1", online: true, self: true, plugins: ["terminal", "companion"], vault: "v1" }, studio]
      ms["machines:vault"] = () => "v1"
      stage = "working"
      calls.length = 0
      // (its own ask over the GitHub page: an earlier block's may be no longer the last; heard only while the companion is on)
      await api("PATCH", "config/plugin/companion", { mode: "quiet" })
      await waitFor(async () => (await api("POST", "ops/companion.status", {}))[1].mode !== "off", 5000, 50)
      // (its pictures in the helper's folder here, under a name with a space as Application Support's)
      const shots = path.join($.tmp, "Vaultite Main", "screens"), shot = path.join(shots, "display-7-1001.png"), close = path.join(shots, "close-7-1002.png")
      fs.mkdirSync(shots, { recursive: true })
      const pngBytes = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(3000, 7)])
      fs.writeFileSync(shot, pngBytes); fs.writeFileSync(close, pngBytes.subarray(0, 1200))
      ;(await import("../../../plugins/core/companion/screensocket.ts")).screenMoment({ kind: "ask", agent: "Claude", text: "research the header", app: "com.example.browser", title: "Site", screen: "https://github.com/lighthouse/site", sx: 10, sy: 20,
        shot, shotAt: { x: 0, y: 0, width: 800, height: 600 }, closeUp: { shot: close, at: { x: 0, y: 0, width: 100, height: 60 }, scale: 3, mark: "pointer" } })
      ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Research the header", say: "On it." }, agent))
      job = b
      check("handoff with nothing tying it here (the ask's GitHub page): on the always-on machine, only the page passed on", st === 200 && b.where.startsWith("Studio") && /on Studio \(always on\b/.test(b.why) &&
        JSON.stringify(calls.find((c) => c.op === "companion.where")?.p) === JSON.stringify({ url: "https://github.com/lighthouse/site" }), [st, b, calls])
      check("handoff on another machine: its worker started there through that machine's companion, told its home (this server, and that machine's id here)",
        JSON.stringify(calls.find((c) => c.op === "companion.worker-start")?.p.home) === JSON.stringify({ url: "http://127.0.0.1:1", as: "studio" }), calls.find((c) => c.op === "companion.worker-start")?.p)
      const told = calls.find((c) => c.op === "companion.worker-start")?.p.prompt ?? "", took = calls.filter((c) => c.op === "companion.picture-take")
      check("handoff on another machine: the ask's picture and close-up copied there (machine to machine), the worker told their paths there, never this one's",
        took.map((c) => `${c.p.name}:${c.p.bytes}`).sort().join() === "close-7-1002.png:1200,display-7-1001.png:3008" && took.every((c) => c.client?.startsWith("machine/")) &&
        told.includes("Their screen then (a picture): /home/alice/.vaultite/local/companion/screens/display-7-1001.png") &&
        told.includes("(3× as large): /home/alice/.vaultite/local/companion/screens/close-7-1002.png") && !told.includes(shots), [took, told])
      await waitFor(async () => (await api("POST", "ops/companion.job", { id: job.id }))[1].session === "rs1", 10000, 200)
      stage = "gone"
      const shipped = await waitFor(async () => { const r = (await api("POST", "ops/companion.job", { id: job.id }))[1]; return r.state !== "working" && r }, 15000, 300)
      const again = (await api("POST", "ops/companion.job", { id: job.id }))[1]
      check("jobs on another machine: a worker that closed itself after its changes is ready for review, read from its session, and stays so",
        shipped?.state === "ready for review" && /Shipped the header/.test(shipped.result?.text ?? "") && again.state === "ready for review" &&
        calls.some((c) => c.op === "companion.worker" && c.p.turn && c.p.session === "rs1"), [shipped, again.state])
      // Its terminal unreadable there now, its change landed later by anyone: looked for on main all the same (its marks
      // kept from its branch and passed back), and closed as done.
      const Wk = await import("../../../plugins/core/companion/workers.ts")
      stage = "landed"
      calls.length = 0
      Wk.paced({ ship: 300 })
      try {
        const jobs = async () => (await api("POST", "ops/companion.jobs", {}))[1].jobs.find((x: Any) => x.id === job.id)
        const kept = await waitFor(async () => calls.some((c) => c.op === "companion.worker" && c.p.marks?.whole === "a".repeat(40)) && await jobs(), 10000, 100)
        check("jobs: one ready for review whose terminal can't be read stays so until its change is on main, its marks kept", kept?.state === "ready for review" && kept.marks?.each?.[0] === "b".repeat(40), kept)
        landed = true
        const closed = await waitFor(async () => { const r = await jobs(); return r?.state === "done" && r }, 10000, 100)
        check("jobs: one ready for review is done once its change is on main, its terminal unreadable on its machine", !!closed && closed.log.at(-1).ev === "landed" &&
          calls.some((c) => c.op === "companion.worker" && c.p.branch === `job-${job.id}` && c.p.cwd === "/home/alice/Projects/site"), [closed, calls.map((c) => c.p)])
        takes = false
        const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Make the header darker", job: job.id, ask: false }, agent))
        const after = (await api("POST", "ops/companion.job", { id: job.id }))[1]
        check("jobs: a follow-up its terminal didn't take leaves it as it was, its landing still its last move: nothing to merge",
          st === 409 && /didn't take it/.test(b.error) && after.state === "done" && after.log.at(-1).ev === "landed" && after.at === closed.at && !J.landable(after) && J.onMain(after), [st, b, after.log.slice(-2)])
      } finally { Wk.paced({ ship: L.PACE.ship }); takes = true }
      // Landing itself where its server takes main: it ends at its push, the server waits for its commit to go live there,
      // sends CI's red back to it to fix forward, and marks it done once its fix is live.
      {
        Wk.paced({ live: 200 })
        await api("PATCH", "config/plugin/companion", { jobs_land: true })
        farLive = true; stage = "working"; farHas = true
        calls.length = 0
        const red = { commit: "1a2b3c4d", live: false, final: true, outcome: "never", red: "1a2b3c4d", why: "1a2b3c4 won't be live here: CI failed on it: it goes live with a fix CI passes" }
        verdicts.push({ commit: "1a2b3c4d", live: false, final: false, outcome: "pending", why: "1a2b3c4 isn't live here yet: updates waiting: CI runs on it" })
        try {
          const [st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the footer live", machine: "studio", cwd: "~/Projects/site" }, agent))
          const told = calls.find((c) => c.op === "companion.worker-start")?.p.prompt ?? ""
          check("jobs: one landing itself in its server's own checkout is told to end at its push, the server waiting for it to go live", st === 200 && /don't wait yourself/.test(told), [st, b, told.slice(-1500)])
          await waitFor(async () => (await api("POST", "ops/companion.job", { id: b.id }))[1].state === "working", 10000, 100)
          stage = "merged"
          const waiting = await waitFor(async () => { const r = (await api("POST", "ops/companion.job", { id: b.id }))[1]; return r.going?.state === "waiting" && calls.some((c) => c.op === "app.version") && /CI runs on it/.test(r.now) && r }, 15000, 100)
          check("jobs: its turn over saying Merged, it stays working while the server looks for that commit live on its machine (app.version there), saying so",
            waiting?.state === "working" && waiting.going.commit === "1a2b3c4d" && waiting.now === "Merged 1a2b3c4: waiting for it to go live (updates waiting: CI runs on it)" &&
            calls.find((c) => c.op === "app.version")?.p.commit === "1a2b3c4d", waiting)
          verdicts.splice(0, verdicts.length, red)
          const sent = await waitFor(() => calls.find((c) => c.op === "terminal.send"), 10000, 100)
          check("jobs: CI red on its commit sends it back into its terminal to fix it forward", /^CI failed on 1a2b3c4d, the commit you landed[^]*Fix it forward/.test(sent?.p.text ?? ""), sent?.p)
          const done = await waitFor(async () => { const r = (await api("POST", "ops/companion.job", { id: b.id }))[1]; return r.state === "done" && r }, 20000, 100)
          const knock = (await api("POST", "ops/companion.knocks", {}))[1].knocks.find((k: Any) => k.line === "Live: Fix the footer live")
          check("jobs: its fix's commit live there, it's done and live: its card says so, a short knock too",
            done?.going?.state === "live" && done.going.commit === "5e6f7a8b" && done.going.fixes === 1 && done.now === "Live: 5e6f7a8 runs on Studio" && !!knock &&
            calls.filter((c) => c.op === "app.version").at(-1)?.p.commit === "5e6f7a8b", { done, knock })
          await asItsTool(() => api("POST", "ops/companion.job-stop", { id: b.id }, agent)).catch(() => {})
          stage = "working"
          calls.length = 0
          verdicts.splice(0, verdicts.length, { commit: "1a2b3c4d", live: false, final: true, outcome: "never", why: "1a2b3c4 won't be live here: its checkout has uncommitted changes" })
          const [, s] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Fix the header live", machine: "studio", cwd: "~/Projects/site" }, agent))
          const job2 = async () => (await api("POST", "ops/companion.job", { id: s.id }))[1]
          await waitFor(async () => (await job2()).state === "working", 10000, 100)
          stage = "merged"
          const stuck = await waitFor(async () => { const r = await job2(); return r.state === "done" && r }, 15000, 100)
          check("jobs: its landed commit that won't be live by itself (a blocked checkout): done, said so on it, never sent back",
            stuck?.going?.state === "stuck" && stuck.now === "Merged 1a2b3c4, not live: its checkout has uncommitted changes" && stuck.log.at(-1).ev === "landed" &&
            !calls.some((c) => c.op === "terminal.send"), stuck)
          stage = "working"
          const fixing = await waitFor(async () => { const r = await job2(); return r.state === "working" && r }, 10000, 100)
          check("jobs: its worker working again after its commit wasn't live is fixing that, its card saying what it does",
            fixing?.going?.state === "fixing" && fixing.now === "Editing the header", fixing)
          stage = "gone"
          const left = await waitFor(async () => { const r = await job2(); return r.exited && r }, 10000, 100)
          const line = left ? (await import("../../../plugins/core/companion/jobs.ts")).jobText(left).split("\n").find((l) => l.startsWith("going live:")) : ""
          check("jobs: its terminal ending as it fixed its commit forward leaves it stuck, its card saying no fix landed",
            left?.going?.state === "stuck" && line === "going live: 1a2b3c4 isn't live, and its terminal ended before a fix landed: it needs you", { going: left?.going, line })
          await asItsTool(() => api("POST", "ops/companion.job-stop", { id: s.id }, agent)).catch(() => {})
        } finally {
          Wk.paced({ live: L.PACE.live })
          farLive = false
          await api("PATCH", "config/plugin/companion", { jobs_land: false })
        }
      }
      // A preview served here: to the always-on machine when it has the repo and all of it is pushed, else here, saying why.
      if (process.platform !== "win32") {
        const cc = app.plugins.find((p) => p.id === "claude-code")!.services, wasC = { ...cc }, ours: string[] = []
        cc["agent:claude"] = async () => ({ command: "sleep 60", cwd: null })
        g("add", "-A"); g("commit", "-qm", "earlier blocks' changes", "--allow-empty"); g("update-ref", "refs/remotes/origin/main", "HEAD")
        const pv = spawn(process.execPath, ["-e", "const s=require('http').createServer(()=>{}).listen(0,'127.0.0.1',()=>console.log(s.address().port))"], { cwd: repo, stdio: ["ignore", "pipe", "ignore"] })
        const port = await new Promise<string>((ok) => pv.stdout!.once("data", (d) => ok(String(d).trim())))
        const ask = async () => {
          ;(await import("../../../plugins/core/companion/screensocket.ts")).screenMoment({ kind: "ask", agent: "Claude", text: "make the header blue", app: "com.example.browser", title: "Site", screen: `localhost:${port}/about`, sx: 10, sy: 20 })
          calls.length = 0
          const r = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Make the header blue", say: "On it." }, agent))
          if (!String(r[1].link ?? "").includes("@")) ours.push(String(r[1].link ?? "").split("/").pop()!)
          return r
        }
        try {
          // (an earlier block leaves it off, which drops the ask)
          await api("PATCH", "config/plugin/companion", { mode: "quiet" })
      await waitFor(async () => (await api("POST", "ops/companion.status", {}))[1].mode !== "off", 5000, 50)
          stage = "working"
          ;[st, b] = await ask()
          const start = calls.find((c) => c.op === "companion.worker-start")
          check("handoff over a preview here, its repo pushed and checked out on the always-on machine: it runs there, in that checkout, told to preview there",
            st === 200 && b.link.endsWith("@studio") && /all pushed: as asked, on Studio \(always on[^)]*\), previewed there/.test(b.why) &&
            JSON.stringify(calls.find((c) => c.op === "companion.where")?.p) === JSON.stringify({ url: "https://github.com/lighthouse/site" }) && start?.p.cwd === "/home/alice/Projects/site" &&
            new RegExp(`asked over the preview http://localhost:${port} on [^]*Studio's own preview[^]*say it's on Studio`).test(start?.p.prompt ?? ""), [st, b, start?.p])
          await asItsTool(() => api("POST", "ops/companion.job-stop", { id: b.id }, agent))
          fs.appendFileSync(path.join(repo, "index.html"), "<p>wip</p>\n")
          ;[st, b] = await ask()
          check("handoff over a preview here with uncommitted changes: it stays here, its why saying they'd be lost by moving",
            st === 200 && !b.link.includes("@") && /1 uncommitted change, not yet pushed, would be lost on Studio: here\)$/.test(b.why) && !calls.some((c) => c.op === "companion.where"), [st, b, calls])
          await asItsTool(() => api("POST", "ops/companion.job-stop", { id: b.id }, agent))
          g("checkout", "--", "index.html")
          farHas = false
          ;[st, b] = await ask()
          check("handoff over a pushed preview the always-on machine hasn't checked out: it stays here, saying so",
            st === 200 && !b.link.includes("@") && /not checked out on Studio: here\)$/.test(b.why) && calls.some((c) => c.op === "companion.where"), [st, b])
          // A repo named, with no machine nor folder: to the always-on machine when it has it and what a job starts from is pushed.
          const Wh = await import("../../../plugins/core/companion/where.ts")
          Wh.checkoutsIn(roots)
          farHas = true
          const byName = async () => {
            calls.length = 0
            const r = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Make the header blue", repo: "site", say: "On it." }, agent))
            if (!String(r[1].link ?? "").includes("@")) ours.push(String(r[1].link ?? "").split("/").pop()!)
            else await asItsTool(() => api("POST", "ops/companion.job-stop", { id: r[1].id }, agent))
            return r
          }
          try {
            const head = g("rev-parse", "HEAD").trim()
            fs.appendFileSync(path.join(repo, "index.html"), "<p>wip</p>\n")
            ;[st, b] = await byName()
            const start = calls.find((c) => c.op === "companion.worker-start")
            check("handoff naming a repo checked out here, its commits pushed: on the always-on machine (uncommitted changes a worktree never takes don't tie it), from this commit, saying why",
              st === 200 && b.link.endsWith("@studio") && /^site is .*site here, all pushed: as asked, on Studio \(always on[^)]*\)$/.test(b.why) &&
              JSON.stringify(calls.find((c) => c.op === "companion.where")?.p) === JSON.stringify({ url: "https://github.com/lighthouse/site" }) &&
              start?.p.cwd === "/home/alice/Projects/site" && (start?.p.prompt ?? "").includes(`${head.slice(0, 12)} (fetch that commit first if need be)`), [st, b, start?.p])
            g("checkout", "--", "index.html")
            fs.appendFileSync(path.join(repo, "index.html"), "<p>local</p>\n"); g("commit", "-qam", "local only")
            ;[st, b] = await byName()
            check("handoff naming a repo with a commit only here: it stays here, its why saying the commit would be missing there",
              st === 200 && !b.link.includes("@") && /1 unpushed commit it starts from would be missing on Studio: here\)$/.test(b.why) && !calls.some((c) => c.op === "companion.where"), [st, b])
            g("reset", "-q", "--hard", head)
            await api("PATCH", "config/plugin/companion", { jobs_machine: "here" })
            ;[st, b] = await byName()
            check("handoff naming a repo with jobs_machine here: it stays here, saying so", st === 200 && !b.link.includes("@") && /Studio isn't in jobs_machine: here\)$/.test(b.why), [st, b])
            await api("PATCH", "config/plugin/companion", { jobs_machine: "auto" })
            // (a machine with a vault of its own: a coding job reports home, so it may go; the vault's own work may not)
            Object.assign(studio, { vault: "v2" })
            try {
              ;[st, b] = await byName()
              check("handoff naming a repo, the always-on machine on another vault: the coding job goes there all the same", st === 200 && b.link.endsWith("@studio"), [st, b])
              ;(await import("../../../plugins/core/companion/screensocket.ts")).screenMoment({ kind: "ask", agent: "Claude", text: "write up the week", app: "com.example.notes", title: "Notes", sx: 10, sy: 20 })
              calls.length = 0
              ;[st, b] = await asItsTool(() => api("POST", "ops/companion.handoff", { task: "Write up the week in a note", say: "On it." }, agent))
              if (!String(b.link ?? "").includes("@")) ours.push(String(b.link ?? "").split("/").pop()!)
              check("handoff of the vault's own work, the always-on machine on another vault: it stays here, saying why", st === 200 && !String(b.link).includes("@") && /Studio has another vault: here\)$/.test(b.why), [st, b])
            } finally { Object.assign(studio, { vault: "v1" }) }
            farHas = false
            ;[st, b] = await byName()
            check("handoff naming a repo the always-on machine hasn't checked out: it stays here, saying so", st === 200 && !b.link.includes("@") && /not checked out on Studio: here\)$/.test(b.why), [st, b])
          } finally { Wh.checkoutsIn(); await api("PATCH", "config/plugin/companion", { jobs_machine: "auto" }) }
        } finally {
          await api("PATCH", "config/plugin/companion", { mode: "off" })
          pv.kill()
          Object.assign(cc, wasC)
          for (const id of ours) await api("DELETE", `terminals/${id}`).catch(() => {})
        }
      }
    } finally {
      await api("POST", "ops/companion.next", { timeout: 0 })
      await api("PATCH", "config/plugin/companion", { mode: "off" })
      Object.assign(ms, wasM)
      for (const k of Object.keys(ms)) if (!(k in wasM)) delete ms[k]
      server.close()
    }
  }
  done()
}
