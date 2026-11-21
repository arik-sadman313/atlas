// Live data failing on a phone: blocks, search, Agents say why with Try again, and recover. WRITES: throwaway server.   node web/qa/phonelive.mjs <base url> [out dir]
// Paths: core/liveread.ts, core/data.ts, components/kit.tsx, components/TryAgain.tsx, components/SearchPalette.tsx, components/Palette.tsx, core/agentruns.tsx, plugins/core/calendar/Agenda.tsx, plugins/core/daily-notes/Day.tsx, plugins/core/agents/AgentsPanel.tsx, plugins/core/claude-code/runs.ts
import { mkdirSync } from "node:fs"
import { execFileSync } from "node:child_process"
import path from "node:path"
import { apiAt, qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
const { args: [B, OUT = "/tmp/phonelive-shots/"], browser, check, watch, done } = await qa(import.meta.url)
mkdirSync(OUT, { recursive: true })
const vau = (...a) => execFileSync(process.execPath, [path.resolve(import.meta.dirname, "../../bin/vau"), "--url", B, ...a], { encoding: "utf8" })
vau("plugin", "on", "calendar")
vau("plugin", "on", "activity")
vau("plugin", "grant", "activity", "--allow", "false")
const api = apiAt(B)
const run = Date.now().toString(36)
const TODAY = `Qa live/Today ${run}.md`
await api("POST", "file", { path: TODAY, text: "---\ntype: dashboard\n---\n\n```block-day\n```\n\n```block-agenda\n```\n\n```block-activity-summary\n```\n" })
await api("POST", "file", { path: `Qa live/Lighthouse ${run}.md`, text: "# Lighthouse\n\nThe keeper's log, kept by Alice Park.\n" })

const PHONE = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true }
const IGNORE = /favicon|Failed to load resource|WebSocket|ERR_INTERNET_DISCONNECTED|503/
const unavailable = (r) => r.fulfill({ status: 503, contentType: "text/html", body: "<html><body>Service Unavailable</body></html>" })
const LIVE = /\/api\/(daily-notes\/day|calendar|activity\/summary)\b/
const block = (page, id) => page.locator(`[data-block="${id}"]`).first()
const failedIn = (page, id) => block(page, id).locator("[data-loading-failed]")
const said = (loc) => loc.innerText().then((t) => t.replace(/\s+/g, " ").trim(), () => "")
async function openToday(page, ui) {
  await page.goto("about:blank")
  await page.goto(`${B}#file/${encodeURIComponent(TODAY)}`)
  await block(page, "agenda").waitFor({ timeout: 30_000 })
  await ui.idle({ timeout: 20_000 })
}

{
  const ctx = await browser.newContext(PHONE)
  const page = watch(await ctx.newPage(), { console: true, ignore: IGNORE }), ui = app(page)
  await page.route(LIVE, unavailable)
  await openToday(page, ui)
  await until(() => failedIn(page, "agenda").count(), 10_000)
  const agenda = await said(block(page, "agenda")), day = await said(block(page, "day"))
  check("a failed calendar says so and why, not that nothing is scheduled",
    /Couldn't read the calendar\. The server didn't answer\./.test(agenda) && !/Nothing scheduled/.test(agenda), agenda)
  check("a failed daily note says it couldn't read it, not that it couldn't find it",
    /Couldn't read the daily note\. The server didn't answer\./.test(day) && !/Couldn't find/.test(day), day)
  check("no status text reaches the page", !(await page.getByText(/Service Unavailable|Bad Gateway|Error 503/).count()))
  const button = failedIn(page, "agenda").getByRole("button", { name: "Try again" })
  const tall = (await button.boundingBox())?.height ?? 0
  check("each offers Try again, a 44px target on a phone", (await failedIn(page, "day").getByRole("button", { name: "Try again" }).count()) === 1 && tall >= 43.5, tall)
  await page.screenshot({ path: `${OUT}dashboard-failed.png` })
  await page.unroute(LIVE)
  await button.tap()
  check("Try again brings the calendar back", await until(async () => !(await failedIn(page, "agenda").count()) && /calendar|scheduled|connected/i.test(await said(block(page, "agenda"))), 10_000), await said(block(page, "agenda")))
  check("the other blocks come back by themselves", await until(async () => !(await page.locator("[data-loading-failed]").count()), 15_000), await said(page.locator("[data-loading-failed]").first()))
  await ui.idle()
  await page.screenshot({ path: `${OUT}dashboard-recovered-after-failure.png` })
  await ctx.close()
}

{
  const ctx = await browser.newContext(PHONE)
  await ctx.addInitScript(() => {
    const WS = window.WebSocket
    window.__qaSockets = []
    window.WebSocket = class extends WS { constructor(...a) { super(...a); window.__qaSockets.push(this) } }
  })
  const page = watch(await ctx.newPage(), { console: true, ignore: IGNORE }), ui = app(page)
  await openToday(page, ui)
  const before = await said(block(page, "agenda"))
  await ctx.setOffline(true)
  await page.evaluate(() => { for (const s of window.__qaSockets) s.close() })
  await block(page, "day").getByRole("button", { name: "Day after" }).tap()
  check("offline, the next day's note says it couldn't be read, with Try again",
    await until(() => failedIn(page, "day").getByRole("button", { name: "Try again" }).count(), 15_000), await said(block(page, "day")))
  check("what was shown stays shown", (await said(block(page, "agenda"))) === before)
  await ui.toast.wait(/Can't connect to Vaultite|You're offline/, { timeout: 20_000 }).catch(() => {})
  await page.screenshot({ path: `${OUT}dashboard-offline.png` })
  await ctx.setOffline(false)
  check("back online, it comes back by itself", await until(async () => !(await failedIn(page, "day").count()) && /Tomorrow|No note/.test(await said(block(page, "day"))), 40_000),
    await said(block(page, "day")))
  await ui.idle({ timeout: 20_000 })
  await page.screenshot({ path: `${OUT}dashboard-recovered.png` })
  await ctx.close()
}

{
  const ctx = await browser.newContext(PHONE)
  const page = watch(await ctx.newPage(), { console: true, ignore: IGNORE }), ui = app(page)
  await openToday(page, ui)
  let release
  const held = new Promise((r) => { release = r })
  await page.route(/\/api\/search\?/, async (r) => { await held; await unavailable(r).catch(() => {}) })
  await page.keyboard.press("ControlOrMeta+o")
  await page.locator("[role=dialog][aria-label=Search] input").waitFor()
  await page.keyboard.type("keeper")
  const tail = page.locator('[data-palette-tail="In files"]')
  check("while the files are searched, an In files section shows rows on their way", await until(() => tail.locator(".skeleton").count(), 5000))
  check("and it doesn't say nothing matches yet", !(await page.getByText("Nothing matches").count()))
  await page.screenshot({ path: `${OUT}search-pending.png` })
  release()
  await until(() => tail.locator("[data-loading-failed]").count(), 10_000)
  const text = await said(tail)
  check("a failed search says why, with Try again", /Couldn't search in files: the server didn't answer\./.test(text) && /Try again/.test(text), text)
  await page.screenshot({ path: `${OUT}search-failed.png` })
  await page.unroute(/\/api\/search\?/)
  await tail.getByRole("button", { name: "Try again" }).tap()
  check("Try again finds the note", await until(() => page.locator("[role=option]", { hasText: `Lighthouse ${run}` }).count(), 10_000))
  await ctx.close()
}

{
  const ctx = await browser.newContext(PHONE)
  const page = watch(await ctx.newPage(), { console: true, ignore: IGNORE })
  const now = Date.now()
  const chat = { id: `qa${run}`, cwd: "/Users/alice/lighthouse", by: "app", started: now - 600000, at: now - 300000, asks: [], turn: null, model: "", effort: "",
    mode: "auto", account: "default", seq: 0, told: 0, state: "idle", title: "Tidy the Lighthouse README" }
  let failing = false
  await page.route(/\/api\/claude-code\/chats(\?.*)?$/, (r) => (failing ? unavailable(r) : r.fulfill({ json: { sessions: [chat] } })))
  await page.goto(`${B}#view/agents`)
  const panel = page.locator("[data-agents-view]")
  check("the Agents page lists the chat", await until(() => panel.getByText("Tidy the Lighthouse README").count(), 15_000))
  failing = true
  const line = panel.locator("[data-agents-unreachable]")
  check("its source failing, it says it can't reach it", await until(() => line.filter({ hasText: "Can't reach Claude Code's chats" }).count(), 20_000), await said(panel))
  check("and keeps the row it had, never No agents at work", (await panel.getByText("Tidy the Lighthouse README").count()) > 0 && !(await panel.getByText("No agents at work").count()))
  await page.screenshot({ path: `${OUT}agents-failed.png` })
  failing = false
  await line.getByRole("button", { name: "Try again" }).tap()
  check("Try again clears it", await until(async () => !(await line.count()), 10_000))
  await ctx.close()
}

await done()
