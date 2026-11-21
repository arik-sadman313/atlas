import { Worker } from "node:worker_threads"
import { REPORTS, reportsWithoutEnvOrNetwork } from "./reports.ts"
import { startShared } from "./startup.ts"
import { vaultHolder } from "./vaultholder.ts"

/** startupMs: 3 times a vault read on a throttled, swapping laptop (6-7 min), and less than a guard outside waits (25). */
export type Watchdog = { stallMs: number; startStallMs: number; memStallMs: number; memMB: number; everyMs: number; startupMs: number; reportWaitMs: number }
export const WATCHDOG: Watchdog = { stallMs: 30_000, startStallMs: 120_000, memStallMs: 5000, memMB: 4096, everyMs: 1000, startupMs: 20 * 60_000, reportWaitMs: 10_000 }

// Node's own report on a signal waits for the main thread's loop to turn, so a stalled one never gives it; the
// inspector's pause interrupts running JS (not a system call, nor one long native call), and the report is taken there.
const WATCHER_JS = `
const { workerData: w } = process.getBuiltinModule("node:worker_threads"), fs = process.getBuiltinModule("node:fs"), path = process.getBuiltinModule("node:path")
process.report.excludeEnv = true
process.report.excludeNetwork = true
const beat = new Int32Array(w.sab), start = new Int32Array(w.start, 0, 2)
const text = (sab, at, n) => new TextDecoder().decode(new Uint8Array(sab, at, n).slice())
const local = () => new Date(Date.now() - Atomics.load(beat, 1) * 60000).toISOString().slice(0, 19)
let seen = Atomics.load(beat, 0), since = performance.now(), last = since, up = w.upMs
const timer = setInterval(() => {
  const now = performance.now(), n = Atomics.load(beat, 0), watcherWasPaused = now - last > w.everyMs * 5
  if (n !== seen || watcherWasPaused) { seen = n; since = now }
  up += watcherWasPaused ? w.everyMs : now - last
  last = now
  const ready = Atomics.load(start, 0) === 1, stalled = now - since, mb = process.memoryUsage.rss() / 1048576, late = !ready && up >= w.startupMs
  if (!late && stalled < (ready ? w.stallMs : w.startStallMs) && !(stalled >= w.memStallMs && mb >= w.memMB)) return
  clearInterval(timer)
  const phase = text(w.start, 8, Atomics.load(start, 1)), by = text(w.holder, 4, Atomics.load(new Int32Array(w.holder, 0, 1), 0))
  const what = late ? "the server isn't ready " + Math.round(up / 60000) + " min after it started (" + phase + ")"
    : "the main thread stalled " + Math.round(stalled / 1000) + " s (" + Math.round(mb) + " MB, " + phase + (by ? ", the vault held by " + by : "") + ")"
  report(late ? "start" : "stall", (said) => {
    fs.writeSync(2, local().replace("T", " ") + " vaultite: watchdog: " + what + said + ": killed for its service manager to restart it\\n")
    process.kill(process.pid, "SIGKILL")
  })
}, w.everyMs)

function report(why, done) {
  let over = false, pausedAfterMs = -1
  const finish = (said) => { if (!over) { over = true; done(said) } }
  const asked = performance.now(), waited = Math.round(w.reportWaitMs / 1000) + " s"
  const file = path.join(w.dir, local().replace("T", "-").replace(/:/g, "") + "-" + process.pid + "-" + why + ".json")
  const save = (json) => { fs.mkdirSync(w.dir, { recursive: true }); fs.writeFileSync(file, json) }
  let givesUp = setTimeout(() => finish(", no report: its main thread didn't stop to give one in " + waited + " (in a system call, or one long native call)"), w.reportWaitMs)
  try {
    const s = new (process.getBuiltinModule("node:inspector").Session)()
    s.connectToMainThread()
    // (on macOS a pause is sometimes never answered on a spinning main thread; another one is: no callback, so one
    // refused as already paused finishes nothing)
    const again = setInterval(() => s.post("Debugger.pause"), 500), urls = new Map()
    s.on("Debugger.scriptParsed", (m) => urls.set(m.params.scriptId, m.params.url))
    s.on("Debugger.paused", (m) => {
      if (pausedAfterMs >= 0) return
      clearInterval(again)
      clearTimeout(givesUp)
      pausedAfterMs = Math.round(performance.now() - asked)
      const stack = m.params.callFrames.map((f) => "at " + (f.functionName || "<anonymous>") + " (" + urls.get(f.location.scriptId) + ":" + (f.location.lineNumber + 1) + ":" + (f.location.columnNumber + 1) + ")")
      const at = stack[0] ? " " + stack[0] : ""
      let kept
      try { save(JSON.stringify({ javascriptStack: { message: "the main thread as the watchdog paused it", stack } })); kept = ", its JS stack " + file }
      catch (x) { kept = ", no report: " + (x && x.message) }
      givesUp = setTimeout(() => finish(at + kept + " (its main thread stopped after " + pausedAfterMs + " ms, but its full report wasn't taken in " + waited + " more)"), w.reportWaitMs)
      s.post("Debugger.evaluateOnCallFrame", { callFrameId: m.params.callFrames[0].callFrameId,
        expression: "JSON.stringify(globalThis.process.report.getReport())", returnByValue: true }, (e, r) => {
        try {
          if (e) throw e
          save(r.result.value)
          finish(at + ", its report " + file)
        } catch (x) { finish(at + kept + " (its full report: " + (x && x.message) + ")") }
      })
    })
    const failed = (e) => { if (e) finish(", no report: " + e.message) }
    s.post("Debugger.enable", failed)
    s.post("Debugger.pause", failed)
  } catch (x) { finish(", no report: " + (x && x.message)) }
}
`

export function killWhenStuck(o: Watchdog = WATCHDOG, reports = REPORTS) {
  const sab = new SharedArrayBuffer(8), beats = new Int32Array(sab, 0, 1), mainThreadZoneOffset = new Int32Array(sab, 4, 1)
  const tick = () => { Atomics.add(beats, 0, 1); Atomics.store(mainThreadZoneOffset, 0, new Date().getTimezoneOffset()) }
  tick()
  setInterval(tick, o.everyMs).unref()
  reportsWithoutEnvOrNetwork()
  new Worker(WATCHER_JS, { eval: true, workerData: { sab, holder: vaultHolder, start: startShared, upMs: performance.now(), dir: reports, ...o } }).unref()
}
