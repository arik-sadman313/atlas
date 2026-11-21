// The ask page (LiveView.tsx, LiveAsk.tsx, LiveSteps.tsx, electron/browser/live.ts), watched as from another device; WRITES
// only the throwaway vault. Usage: node web/qa/liveask.mjs <vault copy> [shots dir]
import { _electron } from "playwright-core"
import fs from "node:fs"
import http from "node:http"
import os from "node:os"
import path from "node:path"
import { ROOT, freePort, qa, until } from "./lib/qa.mjs"
import { testServer } from "../../tools/test/lib.ts"

const { args: [VAULT, SHOTS], browser, check, watch, done } = await qa(import.meta.url)
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), "vau-liveask-"))
const RUN = path.join(TMP, "run")
fs.mkdirSync(RUN)
const plugins = path.join(VAULT, ".vaultite/plugins.json")
const on = fs.existsSync(plugins) ? JSON.parse(fs.readFileSync(plugins, "utf8")) : { enabled: [], disabled: [] }
fs.writeFileSync(plugins, JSON.stringify({ ...on, enabled: [...new Set([...(on.enabled ?? []), "web-viewer", "activity", "machines", "inbox", "terminal", "claude-code"])] }))

const ROW = "display:block;margin:8px 0;font:17px system-ui"
const site = http.createServer((q, res) => {
  const u = new URL(q.url, "http://x")
  if (u.pathname === "/url") { res.writeHead(302, { Location: u.searchParams.get("q") }); return res.end() }
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" })
  if (u.pathname.startsWith("/landed/")) return res.end(`<!doctype html><title>landed ${u.pathname.slice(8)}</title><h1>Signed in</h1>`)
  res.end(`<!doctype html><title>Sign in - Healthchecks</title><body style="font:16px system-ui;margin:0;background:#f6f7f9">
<div style="max-width:420px;margin:16px auto;background:#fff;padding:20px 28px;border-radius:10px;box-shadow:0 1px 3px #0002">
<h2 style="margin-top:0">Sign in to Healthchecks</h2><p>We'll email you a link to sign in.</p>
<label>Email<br><input name="email" aria-label="Email" style="width:100%;font-size:16px;padding:8px;margin:6px 0 14px"></label>
<button id="send" style="font-size:16px;padding:10px 16px;background:#22863a;color:#fff;border:0;border-radius:6px">Email me a link</button>
<p id="said"></p><a id="plain" style="${ROW}" href="/landed/plain" target="_blank">Log In</a>
<a id="gmail" style="${ROW}" href="/landed/gmail" target="_blank" rel="noreferrer">Log In (mail)</a><button id="popup" style="${ROW}">Sign in with a popup</button></div>
<script>send.onclick=()=>{said.textContent="Check your email"};gmail.onmousedown=()=>{gmail.href="/url?q="+encodeURIComponent(location.origin+"/landed/gmail")}
popup.onclick=()=>open("/landed/popup","signin","width=500,height=600")</script>`)
})
await new Promise((ok) => site.listen(0, "127.0.0.1", ok))
const SITE = `http://127.0.0.1:${site.address().port}/`

const PORT = await freePort()
const B = `http://127.0.0.1:${PORT}`
const machines = path.join(VAULT, ".vaultite/plugins/machines/data.json")
fs.mkdirSync(path.dirname(machines), { recursive: true })
fs.writeFileSync(machines, JSON.stringify({ machines: [{ id: "owner", label: "Owner", url: B }] }))
const server = testServer({ stdio: ["ignore", "pipe", "pipe"],
  env: { ...process.env, VAULTITE_VAULT: VAULT, VAULTITE_LOCAL: path.join(TMP, "local"), HOST: "127.0.0.1", PORT: String(PORT), VAULTITE_DESKTOP: "", TMPDIR: RUN, XDG_RUNTIME_DIR: RUN } })
let out = ""
server.stdout.on("data", (d) => { out += d })
server.stderr.on("data", (d) => { out += d })
await until(() => /vaultite: vault read/.test(out), 60000)
const app = await _electron.launch({
  executablePath: path.join(ROOT, "node_modules/.bin/electron"), args: [ROOT, "--vault", VAULT],
  env: { ...process.env, TMPDIR: RUN, XDG_RUNTIME_DIR: RUN, VAULTITE_QUIET: process.env.SHOW ? "" : "1", VAULTITE_USER_DATA: path.join(TMP, "userData"), VAULTITE_LOCAL: path.join(TMP, "app-local") },
})
const win = await app.firstWindow()
await win.waitForSelector("[role=tree]", { timeout: 60000 })
const call = async (id, params) => {
  const r = await fetch(`${B}/api/ops/${id}`, { method: "POST", headers: { "Content-Type": "application/json", "X-Vaultite-Client": "cli", "X-Vaultite-Agent": "claude-code" }, body: JSON.stringify(params ?? {}) })
  const j = await r.json().catch(() => ({}))
  return r.ok ? (j.result ?? j) : { error: j.error ?? r.status }
}
const op = (id, params) => call(`web-viewer.${id}`, params)
await until(async () => (await fetch(`${B}/api/machines/self`).then((r) => r.json())).desktop === true, 15000)
const tabs = async () => (await (await fetch(`${B}/api/web-viewer/tabs?local=1`)).json()).tabs

const term = await call("terminal.start", { command: "sleep 900", name: "Healthchecks sign-in" })
const T = term.id
check("(a terminal for the asking agent)", !!T && !term.error, term)
const by = { terminal: T }, asker = process.env.BEFORE ? by : { ...by, agent: "claude" }
const opened = await op("open", { url: SITE, task: "healthchecks", ...by })
const TAB = opened.tab
check("an agent's tab is open", Number.isInteger(TAB), TAB)
await op("navigate", { tab: TAB, to: SITE, ...by })
await op("act", { tab: TAB, action: "fill", fields: [{ name: "Email", value: "alice@example.com" }], ...by })
for (let i = 0; i < 3; i++) await op("act", { tab: TAB, action: "click", name: "Email me a link", ...by })
await op("ask", { tab: TAB, reason: "Open the Healthchecks email in Gmail and click its Log In button, then Done", ...asker })
check("the ask is on the tab", await until(async () => (await tabs()).find((t) => t.tab === TAB)?.ask, 10000))

const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2 })
const page = watch(await ctx.newPage(), { label: "ask", console: true, ignore: /favicon|Failed to load resource|WebSocket/ })
await page.goto(`${B}/#view/${encodeURIComponent(`web-live/${TAB}@owner`)}`)
const isLive = (p) => p.locator("[data-web-live-status=live] [data-web-live-frame]").isVisible()
check("the asked tab shows live", await until(() => isLive(page), 20000))
const shot = (name) => SHOTS && page.screenshot({ path: `${SHOTS}/liveask-${name}.png` })
await shot("open")
if (process.env.BEFORE) { await ctx.close(); await app.close(); server.kill(); site.close(); await done(); process.exit() }

const card = page.locator("[data-web-live-ask]")
check("the ask names who asked and its session", await until(async () => /Claude Code/.test(await card.innerText()) && /Healthchecks sign-in/.test(await card.innerText()), 10000), await card.innerText().catch(() => ""))
const steps = await page.locator("[data-web-live-steps]").innerText()
check("the steps read as a person says them, repeats folded", /Filled “Email”/.test(steps) && /Clicked “Email me a link” ×3/.test(steps) && !/\be\d+\b/.test(steps), steps)
check("… under their page, a link", await page.locator("[data-web-live-step-page]").first().getAttribute("href") === SITE)
const frame = await page.locator("[data-web-live-frame]").boundingBox(), box = await page.locator("[data-web-live-frame]").locator("..").boundingBox()
check("the page's picture fills its room", frame.width > box.width - 40 || frame.height > box.height - 40, [frame, box])

await page.locator("[data-web-live-asker]").first().click()
check("its session opens in a tab", await until(() => page.locator(`[data-terminal]`).count(), 10000))
await page.goBack().catch(() => {})
await page.goto(`${B}/#view/${encodeURIComponent(`web-live/${TAB}@owner`)}`)
await until(() => page.locator("[data-web-live-cant]").isVisible(), 15000)

const shownTab = async () => Number((await page.locator("[data-web-live]").getAttribute("data-web-live"))?.split("@")[0])
const landed = async (name) => (await tabs()).find((t) => t.title === `landed ${name}`)
async function clickIn(sel) {
  const box = await page.locator("[data-web-live-frame]").boundingBox()
  const [x, y, w, h] = await app.evaluate(({ webContents }, [site, sel]) => webContents.getAllWebContents().find((c) => c.getURL() === site)
    ?.executeJavaScript(`(() => { const r = document.querySelector(${JSON.stringify(sel)}).getBoundingClientRect(); return [r.x + 20, r.y + r.height / 2, innerWidth, innerHeight] })()`), [SITE, sel])
  await page.mouse.click(box.x + box.width * (x / w), box.y + box.height * (y / h))
}
for (const name of ["plain", "gmail", "popup"]) {
  await clickIn(`#${name}`)
  const opened = await until(() => landed(name), 10000)
  check(`${name}: what the click opens opens on the desktop`, !!opened, (await tabs()).map((t) => [t.tab, t.title]))
  check(`${name}: … and shows here, the ask kept`, await until(async () => opened && (await shownTab()) === opened.tab && await page.locator("[data-web-live-done]").isVisible(), 10000), [opened?.tab, await shownTab()])
  if (name === "plain") await shot("followed")
  await page.locator(`[data-web-live-stack-tab="${TAB}"]`).click()
  check(`${name}: … the asked tab a click away`, await until(async () => (await shownTab()) === TAB && await isLive(page), 10000), await shownTab())
}

const waiting = op("wait", { tab: TAB, helped: true, timeout: 60 })
await page.locator("[data-web-live-cant]").click()
await page.keyboard.type("That inbox isn't mine")
await shot("cant")
await page.locator("[data-web-live-cant-send]").click()
const said = await waiting
check("I can't fails the agent's wait, with the reason", /can't do what you asked: That inbox isn't mine/.test(String(said.error ?? "")), said)
check("… and the page says it was told", await until(() => page.locator("[data-web-live-answered=cant]").isVisible(), 5000))

await op("ask", { tab: TAB, reason: "Solve the check, then Done", ...asker })
check("a new ask shows open again", await until(() => page.locator("[data-web-live-ask=open]").isVisible(), 10000))
await fetch(`${B}/api/web-viewer/tabs/${TAB}/done`, { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" })
check("one answered elsewhere says so", await until(() => page.locator("[data-web-live-answered=elsewhere]").isVisible(), 10000))

await op("ask", { tab: TAB, reason: "Sign in, then Done", ...asker })
await until(() => page.locator("[data-web-live-ask=open]").isVisible(), 10000)
await call("terminal.end", { id: T })
check("one whose terminal ended says nothing waits", await until(() => page.locator("[data-web-live-asker-gone]").isVisible(), 20000))
await shot("gone")

const phone = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true, deviceScaleFactor: 3 })
const p2 = watch(await phone.newPage(), { label: "phone", console: true, ignore: /favicon|Failed to load resource|WebSocket/ })
await op("ask", { tab: TAB, reason: "Open the Healthchecks email and tap Log In, then Done", ...asker })
await p2.goto(`${B}/#view/${encodeURIComponent(`web-live/${TAB}@owner`)}`)
check("phone: the ask is a strip over the page", await until(async () => await p2.locator("[data-web-live-done]").isVisible() && await isLive(p2), 20000))
if (SHOTS) await p2.screenshot({ path: `${SHOTS}/liveask-phone.png` })
await p2.locator("[data-web-live-done]").tap()
check("phone: Done ends the ask", await until(async () => (await tabs()).find((t) => t.tab === TAB)?.ask === null, 5000))
await phone.close()
await ctx.close()
await app.close()
server.kill()
site.close()
try { fs.rmSync(TMP, { recursive: true, force: true }) } catch {}
await done()
