// A move in a big vault on a slow disk (iCloud Drive's: tools/test/slowfs.ts) leaves the server answering /api all along.
import fs from "node:fs"
import http from "node:http"
import path from "node:path"
import { pathToFileURL } from "node:url"
import { z } from "zod"
import { check, exit, freePort, sleep, summary, tempDir, testServer } from "./test/lib.ts"
const began = Date.now()

const NOTES = 3000, SLOW_MS = 2, LINKED = 30
const tmp = tempDir("vaultite-slowmove-test-")
const VAULT = path.join(tmp, "vault"), SLOW = path.join(tmp, "slow")
const put = (rel: string, text: string) => { fs.mkdirSync(path.dirname(path.join(VAULT, rel)), { recursive: true }); fs.writeFileSync(path.join(VAULT, rel), text) }
put(".vaultite/plugins.json", "{}\n")
for (let i = 0; i < NOTES; i++) put(`Notes/F${i % 40}/Note ${i}.md`, `---\ntype: note\n---\n\nSee [[Note ${(i * 7) % NOTES}]]${i % (NOTES / LINKED) ? "" : " and [[Plan]]"}.\n`)
put("Inbox/Plan.md", "---\ntype: note\n---\n\nThe plan.\n")

const port = await freePort()
const server = testServer({
  env: { ...process.env, VAULTITE_VAULT: VAULT, VAULTITE_LOCAL: path.join(tmp, "local"), PORT: String(port), HOST: "127.0.0.1", VAULTITE_DESKTOP: "",
    NODE_OPTIONS: `${process.env.NODE_OPTIONS ?? ""} --import ${pathToFileURL(path.join(import.meta.dirname, "test", "slowfs.ts")).href}`.trim(),
    VAULTITE_SLOW_DIR: VAULT, VAULTITE_SLOW_MS: String(SLOW_MS), VAULTITE_SLOW_WHILE: SLOW },
  stdio: ["ignore", "pipe", "pipe"],
})
let log = ""
server.stdout!.on("data", (d) => { log += d })
server.stderr!.on("data", (d) => { log += d })

const touchEachNoteAsICloudDoes = () => { for (let i = 0; i < NOTES; i++) fs.chmodSync(path.join(VAULT, `Notes/F${i % 40}/Note ${i}.md`), 0o600) }

type Answer = { status: number; text: string; ms: number }
const call = (p: string, body?: { from: string; to: string }) => new Promise<Answer>((resolve) => {
  const t = performance.now(), done = (status: number, text: string) => resolve({ status, text, ms: performance.now() - t })
  const q = http.request(`http://127.0.0.1:${port}/api/${p}`, { method: body ? "POST" : "GET", agent: false, headers: { "content-type": "application/json" }, timeout: 120_000 }, (res) => {
    let d = ""
    res.on("data", (c) => { d += c })
    res.on("end", () => done(res.statusCode ?? 0, d))
  })
  q.on("error", (e) => done(0, String(e)))
  q.on("timeout", () => q.destroy(new Error("timed out")))
  q.end(body ? JSON.stringify(body) : undefined)
})
const json = <T,>(schema: z.ZodType<T>, a: Answer) => { try { return schema.safeParse(JSON.parse(a.text)).data } catch { return undefined } }
const Loading = z.object({ ready: z.boolean() }), Moved = z.object({ updated: z.array(z.string()) })

try {
  let up = false
  for (const t0 = Date.now(); !up && Date.now() - t0 < 180_000 && server.exitCode === null;) { up = !!json(Loading, await call("loading"))?.ready; if (!up) await sleep(200) }
  check("the server reads the vault", up, log.slice(-1500))
  if (!up) throw new Error("the server never read the vault")
  fs.writeFileSync(SLOW, "")
  touchEachNoteAsICloudDoes()
  await sleep(300)
  const waits: number[] = []
  let moving = true
  const pings = (async () => { while (moving) { const a = await call("loading"); waits.push(a.status === 200 ? a.ms : Infinity); await sleep(50) } })()
  await sleep(300)
  const moved = await call("file/move", { from: "Inbox/Plan.md", to: "Projects/The plan.md" })
  await sleep(300)
  moving = false
  await pings
  fs.rmSync(SLOW)
  const updated = json(Moved, moved)?.updated ?? []
  check("the move ends, rewriting every link to the note", moved.status === 200 && updated.length === LINKED, [moved.status, updated.length, moved.ms])
  check("a linking note links to its new place", fs.readFileSync(path.join(VAULT, "Notes/F0/Note 0.md"), "utf8").includes("[[The plan]]"))
  const worst = Math.max(...waits)
  check(`the server answers /api all through the move, each well before a walk of the vault would end (${NOTES * SLOW_MS} ms)`,
    waits.length >= 3 && worst < NOTES * SLOW_MS / 3,
    { pings: waits.length, worstMs: Math.round(worst), moveMs: Math.round(moved.ms) })
  console.log(`move ${Math.round(moved.ms)} ms, ${waits.length} pings meanwhile, the slowest ${Math.round(worst)} ms`)
} catch (e) {
  check("the test runs to its end", false, String(e))
} finally {
  if (server.exitCode === null && server.signalCode === null) server.kill("SIGKILL")
}
await exit(summary("slowmove", began))
