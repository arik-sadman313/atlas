// A phone back from another app (the server restarted meanwhile) saves nothing over an agent's text it hadn't seen.
//   node web/qa/phoneresume.mjs <vault copy>
import { spawnSync } from "node:child_process"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { freePort, qa, until } from "./lib/qa.mjs"
import { testServer } from "../../tools/test/lib.ts"

// Paths: plugins/core/companion/cotype.ts, core/autosave.ts, core/cosync.ts, components/FileView.tsx

const { args: [VAULT], browser, check, watch, done } = await qa(import.meta.url)
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "vaultite-qa-phoneresume-"))
const port = await freePort()
const B = `http://127.0.0.1:${port}/`
const V = path.join(tmp, "vault"), LOCAL = path.join(tmp, "local"), F = "Lighthouse"
fs.cpSync(VAULT, V, { recursive: true })
fs.mkdirSync(path.join(V, ".vaultite/plugins/machines"), { recursive: true })
fs.writeFileSync(path.join(V, ".vaultite/plugins/machines/data.json"), JSON.stringify({ machines: [] }))
fs.mkdirSync(LOCAL, { recursive: true })
fs.mkdirSync(path.join(V, F), { recursive: true })
fs.writeFileSync(path.join(V, F, "Keeper news.md"), "# Keeper news\n\nThe keeper's log.\n")
const read = (rel) => fs.readFileSync(path.join(V, rel), "utf8")

const env = { ...process.env, PORT: String(port), HOST: "127.0.0.1", VAULTITE_VAULT: V, VAULTITE_LOCAL: LOCAL }
let server = testServer({ stdio: "ignore", env })
const up = () => until(async () => (await fetch(`${B}api/state`).catch(() => null))?.ok, 60_000, 250)
const restart = async () => {
  const was = server
  await new Promise((r) => { was.once("exit", r); was.kill() })
  server = testServer({ stdio: "ignore", env })
  return up()
}
const stop = () => {
  if (server.exitCode === null) server.kill()
  try { process.kill(Number(fs.readFileSync(path.join(os.tmpdir(), `vaultite-ptyd1-vaultite-${port}.sock.pid`), "utf8"))) } catch {}
  spawnSync("tmux", ["-L", `vaultite-${port}`, "kill-server"], { stdio: "ignore" })
  fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 5 })
}
const op = async (id, body) => { const j = await (await fetch(`${B}api/ops/${id}`, { method: "POST", headers: { "Content-Type": "application/json", "X-Vaultite-Client": "cli" }, body: JSON.stringify(body) })).json(); return j.result ?? j }
const NEWS = Array.from({ length: 30 }, (_, i) => `- Headline ${i + 1}: the lamp at the point was checked and the fog bell rang twice.`).join("\n")
const line = (p, has) => p.locator(".cm-line:visible", { hasText: has }).first()
const typeAfter = async (p, has, s) => { await line(p, has).click(); await p.keyboard.press("End"); await p.keyboard.type(s) }
const shows = (p, s) => until(() => line(p, s).count().then((n) => n > 0), 15_000)
const kept = async (rel, ...lines) => !(await until(() => !lines.every((l) => read(rel).includes(l)), 3000))
const bound = new WeakSet()
const QUIET = /WebSocket|Failed to load resource|ERR_CONNECTION_REFUSED|net::/
const page = async (ctx, label) => {
  const p = watch(await ctx.newPage(), { label, ignore: QUIET })
  p.on("websocket", (ws) => ws.on("framereceived", (f) => { if (/"t":"y-state"/.test(String(f.payload)) && /"u":"/.test(String(f.payload))) bound.add(p) }))
  return p
}
const opened = async (ctx, rel, label) => {
  const p = await page(ctx, label)
  await p.goto(`${B}#file/${encodeURIComponent(rel)}`)
  await p.locator(".cm-content").first().waitFor({ timeout: 30_000 })
  return p
}
const seen = (visible) => {
  Object.defineProperty(document, "visibilityState", { configurable: true, get: () => (visible ? "visible" : "hidden") })
  Object.defineProperty(document, "hidden", { configurable: true, get: () => !visible })
  document.dispatchEvent(new Event("visibilitychange"))
  dispatchEvent(new Event(visible ? "vaultite:back" : "vaultite:away"))
}
const switchToSafariAndFreeze = async (p, cdp) => { await p.evaluate(seen, false); await cdp.send("Page.setWebLifecycleState", { state: "frozen" }) }
const back = async (p, cdp) => { await cdp.send("Page.setWebLifecycleState", { state: "active" }); await p.evaluate(seen, true) }

async function typedTogetherThenAway(name, rel, desk, phone, after) {
  const cdp = await phone.context().newCDPSession(phone)
  check(`${name}: the phone and the desktop type together`, await until(() => bound.has(phone) && bound.has(desk), 15_000))
  await typeAfter(phone, after, " Fog at dawn.")
  check(`${name}: the phone's line is saved`, await until(() => read(rel).includes("Fog at dawn."), 10_000), read(rel))
  await op("file.write", { path: rel, text: `${read(rel)}\n${NEWS}\n` })
  check(`${name}: the agent's news reaches the phone`, await shows(phone, "Headline 30"))
  check(`${name}: ...and stays in the file`, await kept(rel, "Fog at dawn.", "Headline 30"), read(rel))

  await switchToSafariAndFreeze(phone, cdp)
  check(`${name}: the server restarts while the phone is away`, await restart())
  await back(phone, cdp)
  check(`${name}: back on the phone, the note shows the agent's news`, await shows(phone, "Headline 30"))
  check(`${name}: ...and the file keeps it`, await kept(rel, "Fog at dawn.", "Headline 30"), read(rel))
  await typeAfter(phone, "Fog at dawn.", " Calm by noon.")
  check(`${name}: the phone's next typing is saved`, await until(() => read(rel).includes("Calm by noon."), 10_000), read(rel))
  check(`${name}: ...over nothing it hadn't seen`, await kept(rel, "Fog at dawn.", "Headline 30", "Calm by noon."), read(rel))
}

const phoneOpts = { viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true }
try {
  await up()
  let deskCtx = await browser.newContext({ viewport: { width: 1200, height: 850 } }), phoneCtx = await browser.newContext(phoneOpts)
  let rel = `${F}/Keeper news.md`
  let desk = await opened(deskCtx, rel, "desktop")
  let phone = await opened(phoneCtx, rel, "phone")
  await phone.getByRole("button", { name: "Edit", exact: true }).tap()
  await typedTogetherThenAway("a note open on both", rel, desk, phone, "The keeper's log.")
  await Promise.all([deskCtx, phoneCtx].map((c) => c.close()))

  deskCtx = await browser.newContext({ viewport: { width: 1200, height: 850 } }); phoneCtx = await browser.newContext(phoneOpts)
  phone = await page(phoneCtx, "phone")
  await phone.goto(B)
  await phone.getByRole("button", { name: "New tab" }).tap()
  await phone.getByText("New note", { exact: true }).first().tap()
  await until(() => phone.evaluate(() => location.hash.startsWith("#file/Untitled")), 10_000)
  await phone.keyboard.type("Keeper news two")
  await phone.keyboard.press("Enter")
  await until(() => phone.evaluate(() => location.hash.includes("Keeper%20news%20two")), 10_000)
  rel = decodeURIComponent((await phone.evaluate(() => location.hash)).slice("#file/".length))
  await phone.keyboard.type("Any news today?")
  check("a note the phone made: its first line is saved", await until(() => read(rel).includes("Any news today?"), 10_000), read(rel))
  desk = await opened(deskCtx, rel, "desktop")
  await typedTogetherThenAway("a note the phone made", rel, desk, phone, "Any news today?")
  await Promise.all([deskCtx, phoneCtx].map((c) => c.close()))
} finally {
  stop()
}
await done()
