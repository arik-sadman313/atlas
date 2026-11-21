import fs from "node:fs"
import path from "node:path"
import { LOCAL } from "./local.ts"
import { logger } from "./log.ts"
import { messageOf } from "./values.ts"

const log = logger("vaultite")
export const REPORTS = path.join(LOCAL, "reports")
export const KEEP = 20
export type Why = "stall" | "start" | "signal"
const REPORT_NAME = /^\d{4}-\d\d-\d\d-\d{6}-\d+-[a-z]+\.json$/

export const reportName = (why: Why, t = Date.now(), offsetMin = new Date(t).getTimezoneOffset(), pid = process.pid) =>
  `${new Date(t - offsetMin * 60_000).toISOString().slice(0, 19).replace("T", "-").replace(/:/g, "")}-${pid}-${why}.json`

export function pruneReports(dir = REPORTS, keep = KEEP) {
  let oldestFirst: string[]
  try { oldestFirst = fs.readdirSync(dir).filter((n) => REPORT_NAME.test(n)).sort() } catch { return }
  for (const n of oldestFirst.slice(0, Math.max(0, oldestFirst.length - keep))) fs.rmSync(path.join(dir, n), { force: true })
}

export function writeReportNow(why: Why, dir = REPORTS) {
  fs.mkdirSync(dir, { recursive: true })
  const file = path.join(dir, reportName(why))
  process.report.writeReport(file)
  pruneReports(dir)
  return file
}

export function reportsWithoutEnvOrNetwork() {
  process.report.excludeEnv = true
  Reflect.set(process.report, "excludeNetwork", true) // (Node 20.13's, not in @types/node yet)
}

/** SIGUSR2 writes a report once the main thread turns (Node can't sooner; the watchdog reports a stalled one itself). */
export function reportOnSignal() {
  if (process.platform === "win32") return
  reportsWithoutEnvOrNetwork()
  pruneReports()
  process.on("SIGUSR2", () => {
    try { log.info(`a report, as SIGUSR2 asked: ${writeReportNow("signal")}`) } catch (e) { log.error(`SIGUSR2's report couldn't be written: ${messageOf(e)}`) }
  })
}
