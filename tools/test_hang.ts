// A peer stops reading a POST's body, the fetch times out, the peer reads again; a hung server is killed. (npm test)
import { spawn, spawnSync } from "node:child_process"
import fs from "node:fs"
import path from "node:path"
import { pathToFileURL } from "node:url"
import { check, exit, skip, summary, tempDir } from "./test/lib.ts"
import type { Watchdog } from "../core/watchdog.ts"
const began = Date.now()
const tmp = tempDir("vaultite-hang-test-")
const core = (f: string) => pathToFileURL(path.join(import.meta.dirname, "..", "core", f)).href

type Ran = { code: number | null; signal: NodeJS.Signals | null; out: string; ms: number }
function runModuleKilledAfter(js: string, ms: number, env: Record<string, string> = {}, during?: (pid: number) => void): Promise<Ran> {
  return new Promise((resolve) => {
    const t0 = Date.now(), c = spawn(process.execPath, ["--input-type=module", "-e", js], { cwd: tmp, env: { ...process.env, ...env }, stdio: ["ignore", "pipe", "pipe"] })
    let out = ""
    c.stdout.on("data", (d) => { out += d }); c.stderr.on("data", (d) => { out += d })
    const kill = setTimeout(() => c.kill("SIGKILL"), ms)
    if (during && c.pid) during(c.pid)
    c.on("exit", (code, signal) => { clearTimeout(kill); resolve({ code, signal, out, ms: Date.now() - t0 }) })
  })
}

const PEER = `import http2 from "node:http2"; import fs from "node:fs"
const s = http2.createSecureServer({ key: fs.readFileSync("k.pem"), cert: fs.readFileSync("c.pem"), allowHTTP1: true, settings: { initialWindowSize: 1024 } }, (req, res) => {
  if (req.method === "GET") return res.end("v" + req.httpVersion)
  req.pause(); req.on("data", () => {}); req.on("end", () => res.end("ok"))
  setTimeout(() => req.resume(), 1500)
})
s.listen(0, "127.0.0.1", () => console.log("port", s.address().port))`
const CLIENT = (h1: boolean) => `${h1 ? `import { fetchOverHttp1 } from ${JSON.stringify(core("http1.ts"))}; console.log("h1", await fetchOverHttp1())` : ""}
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
const base = "https://127.0.0.1:" + process.env.PEER_PORT
let ticks = 0; setInterval(() => ticks++, 50)
console.log("spoke", await (await fetch(base + "/warm")).text())
await fetch(base + "/x", { method: "POST", body: Buffer.alloc(2000, 97), signal: AbortSignal.timeout(500) }).then((r) => console.log("status", r.status), (e) => console.log("threw", e.name))
const before = ticks; setTimeout(() => { console.log("ticks", ticks - before); process.exit(0) }, 3000)`

const openssl = spawnSync("openssl", ["req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", "k.pem", "-out", "c.pem", "-days", "2", "-subj", "/CN=localhost"], { cwd: tmp })
if (openssl.status !== 0) skip("fetch: a peer that stops reading", "no openssl to make the peer's certificate")
else {
  const peer = spawn(process.execPath, ["--input-type=module", "-e", PEER], { cwd: tmp, stdio: ["ignore", "pipe", "inherit"] })
  const port = await new Promise<string>((r) => peer.stdout.on("data", (d) => { const m = /port (\d+)/.exec(String(d)); if (m) r(m[1]) }))
  try {
    const got = await runModuleKilledAfter(CLIENT(true), 15_000, { PEER_PORT: port })
    const ticks = Number(/ticks (\d+)/.exec(got.out)?.[1] ?? 0)
    check("fetch speaks HTTP/1.1 once fetchOverHttp1 ran (the peer offers HTTP/2)", /h1 http1/.test(got.out) && /spoke v1\.1/.test(got.out), got.out)
    check("a fetch timed out on a peer that stopped reading leaves the process running once the peer reads again",
      got.code === 0 && /threw TimeoutError/.test(got.out) && ticks > 10, { code: got.code, signal: got.signal, ticks, out: got.out })
    if (process.env.VAULTITE_HANG_CONTROL === "1") {
      const h2 = await runModuleKilledAfter(CLIENT(false), 6000, { PEER_PORT: port })
      console.log(`control (Node's HTTP/2): ${h2.signal ? `hung, killed after ${h2.ms} ms` : `ran: ${h2.out.trim().split("\n").at(-1)}`}`)
    }
  } finally { peer.kill("SIGKILL") }
}

const REPORTS = path.join(tmp, "reports")
const TEST_GIVES_UP_MS = 24_000, WATCHDOG_GIVES_UP_ON_THE_PAUSE_THEN_THE_REPORT_MS = TEST_GIVES_UP_MS / 4, STALL_MS = 1500
const WATCHED = (o: Partial<Watchdog>, then: string) => `import { killWhenStuck } from ${JSON.stringify(core("watchdog.ts"))}
import { ready } from ${JSON.stringify(core("startup.ts"))}
killWhenStuck({ stallMs: ${STALL_MS}, startStallMs: ${STALL_MS}, memStallMs: 400, memMB: 1e6, everyMs: 100, startupMs: 60_000, reportWaitMs: ${WATCHDOG_GIVES_UP_ON_THE_PAUSE_THEN_THE_REPORT_MS}, ...${JSON.stringify(o)} }, ${JSON.stringify(REPORTS)})
console.log("watching")
${then}`
const spin = `function spinsForever() { for (;;) {} }\nsetTimeout(spinsForever, 300)`
const killed = (r: Ran) => r.signal === "SIGKILL" || (process.platform === "win32" && r.code !== null && r.code !== 0)
const reportIn = (out: string) => /its report (\S+\.json)/.exec(out)?.[1] ?? ""
const reportNeverEnds = runModuleKilledAfter(WATCHED({}, `process.report.getReport = () => { for (;;) {} }\n${spin}`), TEST_GIVES_UP_MS)
{
  const got = await runModuleKilledAfter(WATCHED({}, spin), TEST_GIVES_UP_MS)
  const stalledS = Number(/watchdog: the main thread stalled (\d+) s/.exec(got.out)?.[1] ?? Infinity), file = reportIn(got.out)
  const report = file && fs.existsSync(file) ? fs.readFileSync(file, "utf8") : ""
  const parts = report ? Object.keys(JSON.parse(report)) : []
  check("a main thread stuck in a loop is killed by the watchdog, saying so", killed(got) && stalledS < 5, got)
  check("… naming the function it was in, and the report it wrote of it (its JS stack, heap, handles; no thread's environment)", /stalled \d+ s \([^)]*\) at \S*spinsForever/.test(got.out) &&
    !!file && fs.realpathSync(path.dirname(file)) === fs.realpathSync(REPORTS) && /"javascriptStack":\{[^}]*spinsForever/.test(report) && parts.includes("libuv") && !report.includes('"environmentVariables"'), { out: got.out, file, parts })
}
{
  const got = await reportNeverEnds
  const file = /its JS stack (\S+\.json)/.exec(got.out)?.[1] ?? "", stack = file && fs.existsSync(file) ? fs.readFileSync(file, "utf8") : ""
  check("a report too slow to take still leaves the stuck function named, and its JS stack written", killed(got) && /stalled \d+ s \([^)]*\) at \S*spinsForever/.test(got.out) &&
    /full report wasn't taken/.test(got.out) && /"javascriptStack":\{[^}]*spinsForever/.test(stack), { out: got.out, stack })
}
{
  const holds = `import { holdingVault } from ${JSON.stringify(core("vaultholder.ts"))}\nsetTimeout(() => { holdingVault("#7 POST /api/file/move"); for (;;) {} }, 300)`
  const got = await runModuleKilledAfter(WATCHED({}, holds), TEST_GIVES_UP_MS)
  const at = /(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) vaultite: watchdog/.exec(got.out)?.[1], off = at ? Math.abs(Date.now() - new Date(at.replace(" ", "T")).getTime()) : Infinity
  check("the watchdog names what held the vault, stamped in local time as the log is", killed(got) && got.out.includes("the vault held by #7 POST /api/file/move") &&
    off < 60_000, { off, got })
}
{
  const got = await runModuleKilledAfter(WATCHED({}, `setTimeout(() => process.exit(0), 3000)`), TEST_GIVES_UP_MS)
  check("an idle main thread isn't killed", got.code === 0 && !/watchdog/.test(got.out), got)
}
{
  const got = await runModuleKilledAfter(WATCHED({ stallMs: 60_000, startStallMs: 60_000, memMB: 1 }, spin), TEST_GIVES_UP_MS)
  const stalledS = Number(/stalled (\d+) s/.exec(got.out)?.[1] ?? Infinity)
  check("a stalled main thread holding too much memory is killed sooner", killed(got) && stalledS < 5, got)
}
{
  const outlastsThePause = STALL_MS + WATCHDOG_GIVES_UP_ON_THE_PAUSE_THEN_THE_REPORT_MS
  const stall = `setTimeout(() => { const t = Date.now(); while (Date.now() - t < ${outlastsThePause}) {} process.exit(0) }, 300)`
  const [starting, up] = await Promise.all([runModuleKilledAfter(WATCHED({ startStallMs: 60_000 }, stall), TEST_GIVES_UP_MS),
    runModuleKilledAfter(WATCHED({ startStallMs: 60_000 }, `ready()\n${stall}`), TEST_GIVES_UP_MS)])
  check("a start is given longer to stall than a server that's ready", starting.code === 0 && !/watchdog/.test(starting.out) && killed(up) && /stalled \d+ s \(\d+ MB, ready/.test(up.out), { starting, up })
}
{
  const got = await runModuleKilledAfter(WATCHED({ startupMs: 1500 }, `setInterval(() => {}, 1000)`), TEST_GIVES_UP_MS)
  check("a start not ready in time is ended, saying where it was and with a report", killed(got) && /watchdog: the server isn't ready \d+ min after it started \(imports\)/.test(got.out) &&
    fs.existsSync(reportIn(got.out)) && reportIn(got.out).endsWith("-start.json"), got)
  const fine = await runModuleKilledAfter(WATCHED({ startupMs: 1500 }, `ready()\nsetTimeout(() => process.exit(0), 3000)`), TEST_GIVES_UP_MS)
  check("… and one that got ready isn't", fine.code === 0 && !/watchdog/.test(fine.out), fine)
}
if (process.platform === "win32") skip("SIGUSR2's report", "no SIGUSR2 on Windows")
else {
  const local = path.join(tmp, "local")
  const got = await runModuleKilledAfter(`import { reportOnSignal } from ${JSON.stringify(core("reports.ts"))}
reportOnSignal()
process.kill(process.pid, "SIGUSR2")
setTimeout(() => process.exit(0), 2000)`, 20_000, { VAULTITE_LOCAL: local })
  const kept = fs.existsSync(path.join(local, "reports")) ? fs.readdirSync(path.join(local, "reports")) : []
  check("SIGUSR2 writes a report and the server goes on", got.code === 0 && kept.length === 1 && kept[0].endsWith("-signal.json") && got.out.includes("a report, as SIGUSR2 asked"), { got, kept })
}
{
  const { pruneReports, reportName } = await import("../core/reports.ts")
  const dir = path.join(tmp, "many")
  fs.mkdirSync(dir, { recursive: true })
  const names = Array.from({ length: 25 }, (_, i) => reportName("stall", Date.UTC(2026, 0, 1, 0, 0, i), 0, 100 + i))
  for (const n of names) fs.writeFileSync(path.join(dir, n), "{}")
  fs.writeFileSync(path.join(dir, "notes.txt"), "")
  pruneReports(dir)
  const left = fs.readdirSync(dir).sort()
  check("the last 20 reports are kept, nothing else touched", left.length === 21 && left.includes("notes.txt") && left.filter((n) => n !== "notes.txt").join() === names.slice(5).join(), left)
}
if (process.platform === "win32") skip("watchdog: a stopped process", "no SIGSTOP on Windows")
else {
  const got = await runModuleKilledAfter(WATCHED({}, `setTimeout(() => process.exit(0), 6000)`), 15_000, {}, (pid) => {
    setTimeout(() => process.kill(pid, "SIGSTOP"), 500)
    setTimeout(() => process.kill(pid, "SIGCONT"), 3500)
  })
  check("a process stopped and started again (the machine slept) isn't killed", got.code === 0 && !/watchdog/.test(got.out), got)
}

fs.rmSync(tmp, { recursive: true, force: true })
await exit(summary("hang", began))
