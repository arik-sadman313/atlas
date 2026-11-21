// A web tab's hover card: its page's picture once shown, its site's icon if never (plugins/core/web-viewer/thumbs.ts, WebPicture.tsx). Throwaway vault only:   node web/qa/webcards.mjs <vault copy> [out dir]
import { _electron } from "playwright-core"
import fs from "node:fs"
import http from "node:http"
import os from "node:os"
import path from "node:path"
import { ROOT, apiAt, qa, until } from "./lib/qa.mjs"
import { app as appOf } from "./lib/app.mjs"

const { args: [VAULT, OUT = "/tmp/webcards-shots/"], check, watch, done } = await qa(import.meta.url, { chrome: false })
fs.mkdirSync(OUT, { recursive: true })
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), "vau-webcards-"))
const page = (title, bg) => `<!doctype html><html><head><meta charset="utf-8"><title>${title}</title>
<style>body{font:40px/1.5 Georgia,serif;margin:0;padding:40px 60px;background:${bg};color:#222}</style></head><body><h1>${title}</h1></body></html>`
const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" })
  res.end(req.url.startsWith("/b") ? page("Second page", "#dde8f3") : req.url.startsWith("/c") ? page("Never shown", "#e8f0e0") : page("Lighthouse field notes", "#f6d7a8"))
})
await new Promise((ok, fail) => { server.once("error", fail); server.listen(0, "127.0.0.1", ok) })
const SITE = `http://127.0.0.1:${server.address().port}`

fs.mkdirSync(path.join(VAULT, ".vaultite"), { recursive: true })
const app = await _electron.launch({
  executablePath: path.join(ROOT, "node_modules/.bin/electron"), args: [ROOT, "--vault", VAULT],
  env: { ...process.env, VAULTITE_QUIET: process.env.SHOW ? "" : "1", VAULTITE_USER_DATA: path.join(TMP, "userData"), VAULTITE_LOCAL: path.join(TMP, "local") },
})
const win = await app.firstWindow()
watch(win, { console: true, fail: false })
const ui = appOf(win)
await win.waitForSelector("[role=tree]", { timeout: 60000 })
const origin = new URL(win.url()).origin
const api = apiAt(`${origin}/`)
const look = await api("GET", "config/appearance")
await api("PUT", "config/appearance", { ...look, tabBar: true })
const openWeb = (url, background = false) => api("POST", "ui", { action: "open", path: url, newTab: true, background })
const shown = (p) => app.evaluate(({ BaseWindow }, p) => {
  const w = BaseWindow.getAllWindows()[0]
  return !!w?.contentView.children.some((v) => v.webContents && v.webContents !== w.webContents && v.getVisible() && new URL(v.webContents.getURL() || "about:blank").pathname === p)
}, p)

await openWeb(`${SITE}/a`)
check("the first page shows", await until(() => shown("/a"), 20000))
await ui.idle()
await openWeb(`${SITE}/b`)
check("then the second", await until(() => shown("/b"), 20000))
await openWeb(`${SITE}/c`, true)

const chip = (name) => win.locator("[data-tab-bar] [data-tab-id]", { hasText: name })
const card = win.locator("[data-tab-hover-card]")
const rest = async (name) => { const b = await chip(name).boundingBox(); await win.mouse.move(b.x + b.width / 2, b.y + b.height / 2, { steps: 4 }); await ui.idle() }
await rest("Lighthouse field notes")
check("a shown tab's card: its page's picture", await until(() => card.locator("img[data-web-picture]").evaluate((e) => e.complete && e.naturalWidth > 0 && e.src.startsWith("blob:")).catch(() => false), 5000))
await win.screenshot({ path: `${OUT}web.png` })
await win.mouse.move(700, 600, { steps: 3 }); await ui.idle()
await rest("127.0.0.1")
check("a tab never shown: its site's icon, no picture", (await card.count()) === 1 && (await card.locator("img[data-web-picture]").count()) === 0
  && (await card.locator("[data-web-picture]").textContent()).includes("127.0.0.1"))
await api("PUT", "config/appearance", look)
await app.close()
server.close()
fs.rmSync(TMP, { recursive: true, force: true })
await done()
