// The Browser's logins in the desktop app (Electron), end to end on a throwaway vault, against a made-up site this
// script serves on 127.0.0.1 (a cookie login): signed in on a page in workspace 1, a page in workspace 2 is too (one set
// of logins, persist:web, for every page in no container); the Sites tab (every set of logins,
// plugins/core/web-viewer/Sites.tsx) lists the site signed in to (a tracker's cookie as one line, Clear) under the
// default logins, Move to takes its cookies to a container's (Undo: back), and Sign out (after asking) clears it.
// Notifications: a page's becomes an Inbox event linking to its tab, a frame inside the page can't make one, none with
// notifications off, and a burst is cut short. Workspace 2's old logins become a container named after it, once.
// WRITES: the throwaway vault only.
//   node web/qa/weblogins.mjs <vault copy>
import { _electron } from "playwright-core"
import fs from "node:fs"
import http from "node:http"
import os from "node:os"
import path from "node:path"
import { ROOT, qa, until, wait, keepAwake, uiAt } from "./lib/qa.mjs"

const { args: [VAULT], check, errs, watch, done } = await qa(import.meta.url, { chrome: false })
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), "vau-weblogins-"))
keepAwake(600)

// ---------- a made-up site with a cookie login ----------
const server = http.createServer((req, res) => {
  const u = new URL(req.url ?? "/", SITE)
  const who = /(?:^|; )who=([^;]+)/.exec(req.headers.cookie ?? "")?.[1]
  const headers = { "Content-Type": "text/html; charset=utf-8" }
  if (u.pathname === "/login") headers["Set-Cookie"] = `who=${u.searchParams.get("u")}; Path=/; Max-Age=3600`
  // (a tracker's pixel: another site's cookie, left by this site's page)
  if (u.pathname === "/pixel") { res.writeHead(200, { "Content-Type": "image/gif", "Set-Cookie": "trk=1; Path=/; Max-Age=3600; SameSite=None; Secure" }); return res.end() }
  res.writeHead(200, headers)
  res.end(`<!doctype html><title>Who</title><p id="who">${u.pathname === "/login" ? `signed in` : `who:${who ?? "nobody"}`}</p>${u.pathname === "/login" ? `<img src="http://localhost:${PORT}/pixel" alt="">` : ""}`)
})
await new Promise((ok, fail) => { server.once("error", fail); server.listen(0, "127.0.0.1", ok) })
const PORT = server.address().port
const SITE = `http://127.0.0.1:${PORT}`
const pluginsFile = path.join(VAULT, ".vaultite/plugins.json")
if (fs.existsSync(pluginsFile)) {
  const p = JSON.parse(fs.readFileSync(pluginsFile, "utf8"))
  fs.writeFileSync(pluginsFile, JSON.stringify({ ...p, enabled: [...(p.enabled ?? []).filter((x) => x !== "workspaces"), "workspaces"] }, null, 2) + "\n")
}
fs.mkdirSync(path.join(VAULT, ".vaultite/plugins/workspaces"), { recursive: true })
fs.writeFileSync(path.join(VAULT, ".vaultite/plugins/workspaces/2.json"), JSON.stringify({ name: "Writing" }))
fs.mkdirSync(path.join(VAULT, "Notes"), { recursive: true })
fs.writeFileSync(path.join(VAULT, "Notes/Site.md"), `# Site\n\nSee [who](${SITE}/whoami) and [who again](${SITE}/whoami?again).\n\nBelow the links.\n`)

// ---------- the app ----------
const app = await _electron.launch({
  executablePath: path.join(ROOT, "node_modules/.bin/electron"), args: [ROOT, "--vault", VAULT],
  env: { ...process.env, VAULTITE_QUIET: process.env.SHOW ? "" : "1", VAULTITE_USER_DATA: path.join(TMP, "userData"), VAULTITE_LOCAL: path.join(TMP, "local") },
})
const win = await app.firstWindow()
watch(win, { console: true, fail: false })
await win.waitForSelector("[role=tree]", { timeout: 60000 })
const origin = new URL(win.url()).origin
await app.evaluate(({ BaseWindow }) => { const w = BaseWindow.getAllWindows()[0]; w.setBounds({ x: 40, y: 40, width: 1280, height: 800 }); w.focus() })
const ui = (body) => uiAt(origin)(body)
const command = async (id) => { await ui({ action: "command", id }); await wait(700) }

/** The visible web page: its address, what it says, and its session's partition. */
const visible = () => app.evaluate(async ({ BaseWindow, session }) => {
  const w = BaseWindow.getAllWindows()[0]
  const v = w.contentView.children.find((x) => x.webContents && x.webContents !== w.webContents && x.getVisible())
  if (!v) return null
  const parts = ["persist:web", "persist:web-2", "persist:web-c-personal"]
  const partition = parts.find((p) => session.fromPartition(p) === v.webContents.session) ?? "?"
  const text = await v.webContents.executeJavaScript("document.getElementById('who')?.textContent ?? ''")
  return { url: v.webContents.getURL(), text, partition }
})
const cookiesIn = (partition) => app.evaluate(async ({ session }, p) => (await session.fromPartition(p).cookies.get({})).map((c) => `${c.name}=${c.value}`), partition)
/** Open the note and click its nth web link (a web tab, in the current workspace). */
async function openLink(n) {
  await ui({ action: "open", path: "Notes/Site.md" })
  await win.waitForSelector("section [data-pane] .cm-link[data-url]", { timeout: 15000 })
  await win.locator(".cm-line", { hasText: "Below the links" }).first().click()
  await wait(300)
  await win.locator("section [data-pane] .cm-link[data-url]").nth(n).click()
  await win.mouse.move(5, 400) // (off the link: its preview would cover the page)
}
/** Every web page over the window (for a failure's message). */
const all = () => app.evaluate(({ BaseWindow }) => {
  const w = BaseWindow.getAllWindows()[0]
  return w.contentView.children.filter((x) => x.webContents && x.webContents !== w.webContents).map((v) => ({ url: v.webContents.getURL(), visible: v.getVisible() }))
})
const inPage = (code) => app.evaluate(({ BaseWindow }, code) => {
  const w = BaseWindow.getAllWindows()[0]
  const v = w.contentView.children.find((x) => x.webContents && x.webContents !== w.webContents && x.getVisible())
  return v ? v.webContents.executeJavaScript(code) : null
}, code)

// ---------- workspace 1: sign in ----------
await openLink(0)
check("workspace 1: a web page in the default logins (persist:web)", await until(async () => (await visible())?.partition === "persist:web", 15000), [await visible(), await all(), await win.evaluate(() => [...document.querySelectorAll("[role=tab]")].map((t) => t.textContent))])
await inPage(`location.href = ${JSON.stringify(`${SITE}/login?u=Alice`)}`)
await until(async () => (await visible())?.text === "signed in", 10000)
await inPage(`location.href = ${JSON.stringify(`${SITE}/whoami`)}`)
check("… signed in there", await until(async () => (await visible())?.text === "who:Alice", 10000), await visible())

// ---------- the Sites tab: every set of logins ----------
const logins = (name) => win.locator("[data-web-sites-view] section", { has: win.locator("[data-web-logins-heading] [data-web-logins-name]", { hasText: new RegExp(`^${name}$`) }) })
await command("web:sites-tab")
check("Sites: the site signed in to, in the default logins", await until(async () => (await logins("Default").locator("[data-web-site='127.0.0.1']").count()) === 1, 10000),
  await win.locator("[data-web-sites-view]").innerText().catch(() => ""))
check("… a tracker's cookie as a tracker, not a site", await until(async () => (await logins("Default").locator("[data-web-trackers='1']").count()) === 1
  && (await win.locator("[data-web-sites-view] [data-web-site='localhost']").count()) === 0, 10000), await win.locator("[data-web-sites-view]").innerText().catch(() => ""))
await logins("Default").locator("[data-web-trackers]").click()
await win.locator("dialog[open] button", { hasText: "Clear" }).click()
check("Clear: the tracker's cookie goes, the site's stays", await until(async () => (await win.locator("[data-web-sites-view] [data-web-trackers]").count()) === 0, 10000)
  && (await cookiesIn("persist:web")).join() === "who=Alice", await cookiesIn("persist:web"))

// ---------- workspace 2: the same logins ----------
await command("workspace:2")
await openLink(1)
check("workspace 2: a web page in persist:web too", await until(async () => (await visible())?.url.endsWith("?again") && (await visible())?.partition === "persist:web", 15000), await visible())
check("… signed in", await until(async () => (await visible())?.text === "who:Alice", 10000), await visible())
await command("workspace:1")
await command("web:sites-tab")
check("Sites: the default logins, no workspace's", await until(async () => (await logins("Default").count()) === 1, 10000)
  && (await win.locator("[data-web-logins-name]", { hasText: /^Workspace/ }).count()) === 0, await win.locator("[data-web-sites-view]").innerText().catch(() => ""))

// ---------- move the login to a container's, and back ----------
const ownSite = logins("Default").locator("[data-web-site='127.0.0.1']")
await until(async () => (await ownSite.count()) === 1, 10000)
await ownSite.hover()
await ownSite.locator("[data-row-more]").click()
await win.locator("[role=menuitem]", { hasText: /^Move to/ }).click()
await win.locator("[role=menuitem]", { hasText: /^Personal/ }).click()
const moved = win.locator("[data-sonner-toast]", { hasText: "Moved 127.0.0.1 to Personal" })
check("… a toast says so", await until(async () => (await moved.count()) === 1, 10000), await win.locator("[data-sonner-toast]").allInnerTexts())
const jars = async () => [await cookiesIn("persist:web"), await cookiesIn("persist:web-c-personal")]
check("Move to: the site's cookie goes to Personal's logins, out of the default ones", await until(async () => {
  const [one, two] = await jars()
  return two.includes("who=Alice") && !one.includes("who=Alice")
}, 10000), await jars())
check("… Sites lists it there", await until(async () => (await logins("Personal").locator("[data-web-site='127.0.0.1']").count()) === 1
  && (await ownSite.count()) === 0, 10000), await win.locator("[data-web-sites-view]").innerText().catch(() => ""))
await moved.getByRole("button", { name: "Undo" }).click()
check("Undo: back in the default logins only", await until(async () => {
  const [one, two] = await jars()
  return one.includes("who=Alice") && !two.includes("who=Alice")
}, 10000), await jars())

// ---------- sign out ----------
await command("web:sites-tab")
const site = logins("Default").locator("[data-web-site='127.0.0.1']")
await until(async () => (await site.count()) === 1, 10000)
await site.hover()
await site.locator("[data-row-more]").click()
await win.locator("[role=menuitem]", { hasText: /^Sign out/ }).click()
check("Sign out asks first", await until(async () => (await win.locator("dialog[open]").count()) > 0, 10000), null)
await win.locator("dialog[open] button", { hasText: "Sign out" }).click()
check("… then the site's cookies go", await until(async () => !(await cookiesIn("persist:web")).includes("who=Alice"), 10000), await cookiesIn("persist:web"))
check("… and it leaves Sites", await until(async () => (await win.locator("[data-web-sites-view] [data-web-site]").count()) === 0, 10000), null)

// ---------- notifications ----------
await command("workspace:2")
await until(async () => (await visible())?.url.endsWith("?again"), 10000)
const events = async () => (await (await fetch(`${origin}/api/inbox/events?limit=100`)).json()).events
const eventNamed = async (title) => (await events()).find((e) => e.title === title)
const setting = (o) => fetch(`${origin}/api/config/plugin/web-viewer`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(o) })
check("a page sees notifications granted", await inPage("Notification.permission") === "granted", await inPage("Notification.permission"))
const page = `${SITE}/whoami?again`
/** Run JavaScript in the page at `page`, on screen or not. */
const inThat = (code) => app.evaluate(({ BaseWindow }, [code, url]) => {
  const w = BaseWindow.getAllWindows()[0]
  const v = w.contentView.children.find((x) => x.webContents && x.webContents !== w.webContents && x.webContents.getURL() === url)
  return v ? v.webContents.executeJavaScript(code) : null
}, [code, page])
await inThat(`new Notification("Looked at"); 1`)
await wait(1500)
check("while you're looking at the page: none", !(await eventNamed("Looked at")), await events())
await command("web:sites-tab") // (another tab in front: the page is put away, and still runs)
await inThat(`new Notification("Build done", { body: "All green" }); 1`)
check("a page's notification: an Inbox event", await until(async () => !!(await eventNamed("Build done")), 10000), await events())
const ev = await eventNamed("Build done")
check("… its body, its site, linking to its tab", ev?.body === "All green" && ev?.source === "127.0.0.1" && ev?.link === `view:web/${page}`, ev)
await inThat(`const f = document.createElement("iframe"); f.srcdoc = '<script>console.debug("__vaultite_notify__" + JSON.stringify({ title: "From a frame" }))<\\/script>'; document.body.append(f); 1`)
await wait(1500)
check("a frame in the page can't make one", !(await eventNamed("From a frame")), await events())
await setting({ notifications: false })
await wait(1500)
await inThat(`new Notification("Muted"); 1`)
await wait(1500)
check("notifications off: none", !(await eventNamed("Muted")), await events())
await setting({ notifications: null })
await wait(1000)
await inThat(`for (let i = 0; i < 10; i++) new Notification("Burst " + i); 1`)
await wait(2000)
const burst = (await events()).filter((e) => e.title.startsWith("Burst ")).length
check("a burst is cut short (6 a minute, the 3 before it counted)", burst > 0 && burst <= 3, burst)

// ---------- a workspace's own logins from before: a container, once ----------
const settingsFile = path.join(VAULT, ".vaultite/plugins/web-viewer/data.json")
const saved = () => { try { return JSON.parse(fs.readFileSync(settingsFile, "utf8")) } catch { return {} } }
await win.evaluate((url) => window.vaultite.web.open(url, null, "2"), `${SITE}/login?u=Bob`)
check("an old workspace's logins (persist:web-2): signed in, a tracker's cookie with it", await until(async () => {
  const two = await cookiesIn("persist:web-2")
  return two.includes("who=Bob") && two.includes("trk=1")
}, 10000), await cookiesIn("persist:web-2"))
await setting({ logins: "workspace" })
await until(async () => saved().logins === "workspace", 5000)
await win.evaluate(() => {
  const p = JSON.parse(localStorage.getItem("vaultite.prefs") ?? "{}")
  delete p.device?.["web-viewer:workspace-logins-moved"]
  localStorage.setItem("vaultite.prefs", JSON.stringify(p))
})
await win.reload()
await win.waitForSelector("[role=tree]", { timeout: 60000 })
const made = () => saved().containers?.find((c) => c.id === "workspace2")
check("on the next start: a container named after the workspace", await until(async () => made()?.name === "Writing", 15000), saved())
check("… the old logins' setting gone", !("logins" in saved()), saved())
check("… the login moved into it, the tracker's cookie left behind", await until(async () => (await cookiesIn("persist:web-c-workspace2")).includes("who=Bob")
  && (await cookiesIn("persist:web-2")).join() === "trk=1", 15000), [await cookiesIn("persist:web-c-workspace2"), await cookiesIn("persist:web-2")])
check("… a toast names it", await until(async () => (await win.locator("[data-sonner-toast]", { hasText: "Each workspace's logins are now a container: Writing" }).count()) === 1, 10000),
  await win.locator("[data-sonner-toast]").allInnerTexts())
await win.reload()
await win.waitForSelector("[role=tree]", { timeout: 60000 })
await wait(3000)
check("… once: no second container after another start", saved().containers.filter((c) => c.name === "Writing").length === 1, saved().containers)

console.log(errs.length ? `page errors:\n${errs.slice(0, 5).join("\n")}` : "no page errors")
await app.close()
server.close()
fs.rmSync(TMP, { recursive: true, force: true })
await done()
