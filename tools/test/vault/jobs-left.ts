import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import type { Any, VaultTest } from "./harness.ts"
import { waitFor } from "../lib.ts"
import { request } from "../fakes.ts"

export default async ($: VaultTest) => {
  if (process.platform === "win32") return
  const { app, api, check } = $
  const { shellQuote } = await import("../../../core/agents.ts")
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "jobs-left-")), mark = (n: string) => path.join(dir, n)
  const agent = request({ host: "127.0.0.1:8793", "x-vaultite-client": "cli", "x-vaultite-agent": "claude-code" }, { remote: "127.0.0.1" })
  const cc = app.plugins.find((p) => p.id === "claude-code")!.services, was = { ...cc }
  const osc = (s: string) => `printf '\\033]7501;state=${s}\\033\\\\'`
  const starts: Any[] = []
  const SESSION = "a1b2c3d4-left"
  cc["agent:claude"] = async (start: Any) => {
    starts.push(start)
    if (start.resume) return { command: `printf %s ${shellQuote(start.prompt ?? "")} > ${shellQuote(mark("resumed.txt"))}; ${osc("working")}; sleep 600`, cwd: null }
    return { command: `${osc("working")}; sleep 2`, cwd: null }
  }
  cc["agent-turn:claude"] = async () => ({ session: SESSION, text: "Halfway through the header.", files: [], at: Date.now(), final: false })
  const ends: string[] = []
  try {
    await api("PATCH", "config/plugin/companion", { jobs_agent: "claude" })
    let [st, b] = await api("POST", "ops/companion.handoff", { task: "Tidy the header", cwd: dir }, agent)
    const first = b?.link?.split("/").pop() ?? ""
    ends.push(first)
    check("left: a job starts in an agent's terminal", st === 200 && first.startsWith("claude-"), [st, b])
    let job: Any = null
    const failed = await waitFor(async () => { job = (await api("POST", "ops/companion.job", { id: b.id }))[1]; return job.state === "failed" && job }, 20000, 200) || job
    check("left: its agent quit mid-turn, its shell left at its prompt: the job is failed, never ready for review",
      failed?.state === "failed" && !failed.log.some((x: Any) => x.to === "ready for review") && failed.session === SESSION, failed)
    const gone = await waitFor(async () => !(await api("GET", "terminals/sessions"))[1].sessions.some((x: Any) => x.id === first), 5000, 100)
    check("left: the shell its agent left is ended, the job now its resumable conversation's", !!gone && failed?.terminal === `resume-claude-${SESSION}`, failed?.terminal)
    ;[st, b] = await api("POST", "ops/companion.handoff", { task: "Carry on with the header", job: b.id }, agent)
    ends.push(`resume-claude-${SESSION}`)
    const resumed = await waitFor(() => fs.existsSync(mark("resumed.txt")) && fs.readFileSync(mark("resumed.txt"), "utf8"), 10000, 100)
    const now = (await api("POST", "ops/companion.job", { id: b.id }))[1]
    check("left: a follow-up starts its agent again, resuming its conversation with the follow-up as its message; the job works again",
      st === 200 && /Carry on with the header/.test(resumed || "") && starts.at(-1)?.resume === SESSION && now.state === "working", [st, b, resumed, starts.at(-1), now?.state])
    {
      const [, t] = await api("POST", "ops/terminal.start", { agent: "claude", cwd: dir })
      ends.push(t.id)
      const info = app.plugins.find((p) => p.id === "terminal")!.services["terminal:info"]
      const back = await waitFor(async () => (await info(t.id))?.left === true, 15000, 200)
      const [s2, b2] = await api("POST", "ops/terminal.send", { id: t.id, text: `touch ${shellQuote(mark("ran"))}` })
      await new Promise((r) => setTimeout(r, 500))
      check("left: terminal send into an agent's terminal its agent left says so (409) and types nothing", !!back && s2 === 409 && /agent has left it/.test(b2.error) && !fs.existsSync(mark("ran")), [s2, b2])
      const [s3] = await api("POST", "ops/terminal.send", { id: t.id, text: `touch ${shellQuote(mark("ran"))}`, shell: true })
      check("left: terminal send --shell types it into that shell", s3 === 200 && !!(await waitFor(() => fs.existsSync(mark("ran")), 5000, 100)), s3)
    }
  } finally {
    Object.assign(cc, was)
    for (const k of Object.keys(cc)) if (!(k in was)) delete cc[k]
    await api("PATCH", "config/plugin/companion", { jobs_agent: "claude" })
    for (const id of ends) await api("DELETE", `terminals/${id}`).catch(() => {})
    fs.rmSync(dir, { recursive: true, force: true })
  }
}
