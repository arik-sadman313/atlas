// Phone drawers swiped from anywhere, real touches (components/drawerMotion.ts, core/sideways.ts, components/SwipeRow.tsx). WRITES Qa drawer/, the Inbox.
//   node web/qa/drawerswipe.mjs <base url> [out dir]
import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import path from "node:path"
import { app } from "./lib/app.mjs"
import { apiAt, fingers, qa, until, wait } from "./lib/qa.mjs"
const { args: [B, OUT = "/tmp/drawerswipe-shots/"], browser, check, watch, done } = await qa(import.meta.url, { motion: true })
mkdirSync(OUT, { recursive: true })
const api = apiAt(B)
const VAULT = (await (await fetch(new URL("api/vault", B))).json()).path
const conf = (n) => path.join(VAULT, `.vaultite/${n}.json`)
const kept = Object.fromEntries(["sidebars", "newtab"].map((n) => { try { return [n, readFileSync(conf(n), "utf8")] } catch { return [n, null] } }))
writeFileSync(conf("sidebars"), JSON.stringify({ left: ["inbox:inbox", "files:files", "search:search"], right: ["outline:outline", "tags:tags"], collapsed: [] }))
writeFileSync(conf("newtab"), JSON.stringify({ sections: ["inbox:inbox"] }))
const lines = Array.from({ length: 50 }, (_, i) => `Harbour line ${i + 1}: words enough to wrap across a phone's width, twice at least.`).join("\n\n")
await api("POST", "file", { path: "Qa drawer/Harbour.md", text: `# Harbour\n\n${lines}\n` })
const ROW = `Drawer row ${Date.now().toString(36)}`
await api("POST", "inbox", { title: ROW, body: "Body.", from: "Qa" })

const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true })
const page = watch(await ctx.newPage(), { console: true, ignore: /favicon|Failed to load resource|WebSocket/ }), ui = app(page)
const { touch } = await fingers(page)
const frame = () => page.evaluate(() => new Promise(requestAnimationFrame))
async function finger(x, y, dx, dy, { n = 12, ms = 16, lift = true, rest = 0, down = true } = {}) {
  if (down) await touch("touchStart", x, y)
  for (let i = 1; i <= n; i++) {
    // oxlint-disable-next-line vaultite/no-sleep -- a finger's speed is its moves' spacing in time
    await wait(i === n ? ms + rest : ms)
    await touch("touchMove", x + (dx * i) / n, y + (dy * i) / n)
  }
  if (lift) await touch("touchEnd")
}
const out = () => page.evaluate(() => document.documentElement.dataset.drawer ?? null)
const still = () => until(() => page.evaluate(() => [...document.querySelectorAll("[role=dialog][aria-label$=idebar]")].every((d) => !d.getAnimations().some((a) => a.playState === "running"))), 3000)
const inBy = (side) => page.evaluate((side) => {
  const d = document.querySelector(`[data-phone-drawer=${side}]`)
  if (!d) return null
  const r = d.getBoundingClientRect()
  return Math.round(side === "left" ? r.right : innerWidth - r.left)
}, side)
const opened = async (side) => { await until(async () => (await out()) === side && ((await inBy(side)) ?? 0) >= 300, 3000); await still() }
const shut = async () => { if (await out()) { await page.keyboard.press("Escape"); await until(async () => !(await out()), 3000) } await still(); await ui.idle() }

await page.goto(`${B}#file/${encodeURIComponent("Qa drawer/Harbour.md")}`)
await page.waitForSelector(".cm-content"); await ui.idle()
await page.evaluate(() => {
  window.__frames = []
  let t = performance.now()
  const tick = (now) => { window.__frames.push(now - t); t = now; requestAnimationFrame(tick) }
  requestAnimationFrame(tick)
})

await touch("touchStart", 200, 300); await touch("touchEnd"); await ui.idle(); await page.evaluate(() => { window.__frames = [] })
await finger(120, 420, 150, 4, { lift: false })
const mid = await inBy("left")
check("a swipe right from the page's middle brings the left sidebar, under the finger", mid !== null && Math.abs(mid - 150) <= 14, mid)
await page.screenshot({ path: `${OUT}mid-swipe.png` })
await touch("touchEnd"); await still()
check("...past a third, let go: it opens", (await out()) === "left")
await page.screenshot({ path: `${OUT}left-open.png` })
const frames = await page.evaluate(() => window.__frames)
console.log(`longest frame while swiping: ${Math.round(Math.max(...frames))}ms`)
await shut()

await finger(300, 420, -220, 4)
await still()
check("a swipe left from the middle opens the right sidebar", (await out()) === "right")
await shut()

await finger(200, 420, 66, 3, { n: 3, ms: 8 })
await still()
check("a quick flick a fifth of the way opens it", (await out()) === "left")
await shut()

await finger(150, 420, 90, 3, { n: 6, rest: 250 }); await still()
check("a short drag held, then let go: it goes back", !(await out()))

const y0 = await page.evaluate(() => scrollY)
await finger(200, 600, 40, -260)
await still()
check("a mostly vertical drag scrolls, opens nothing", !(await out()) && (await page.evaluate(() => scrollY)) > y0 + 50, [await out(), y0, await page.evaluate(() => scrollY)])

const word = await page.evaluate(() => {
  const line = [...document.querySelectorAll(".cm-line")].find((l) => /Harbour line \d+/.test(l.textContent) && l.getBoundingClientRect().top > 200)
  const t = line?.firstChild
  if (!t) return null
  const r = document.createRange(); r.setStart(t, 0); r.setEnd(t, 7)
  getSelection().removeAllRanges(); getSelection().addRange(r)
  const b = r.getBoundingClientRect()
  return { x: b.x + 30, y: b.y + b.height / 2 }
})
if (word) await finger(word.x + 60, word.y, 150, 3)
await still()
check("with text selected, a swipe over it opens nothing", !!word && !(await out()), word)
await page.evaluate(() => getSelection().removeAllRanges())

await page.evaluate(() => {
  const s = document.createElement("div")
  s.id = "qa-wide"
  s.style.cssText = "overflow-x:auto;position:fixed;left:0;right:0;top:300px;height:120px;z-index:5;background:var(--card)"
  s.innerHTML = '<div style="width:1400px;height:100%"></div>'
  document.querySelector("#main-scroll > main").append(s)
})
await finger(300, 360, -200, 2)
await still()
const sl = await page.evaluate(() => document.getElementById("qa-wide").scrollLeft)
check("a swipe left on a wide scroller scrolls it, opens nothing", sl > 0 && !(await out()), [sl, await out()])
const left = () => page.evaluate(() => document.getElementById("qa-wide").scrollLeft)
await until(async () => { const a = await left(); for (let i = 0; i < 8; i++) await frame(); return a === await left() }, 3000)
await page.evaluate(() => { document.getElementById("qa-wide").scrollLeft = 0 })
await frame()
await finger(100, 360, 200, 2)
await still()
check("at its start, a swipe right passes on and opens the left sidebar", (await out()) === "left")
await shut()
await finger(10, 360, 220, 2)
await still()
check("from the screen's edge, the sidebar wins even over a scroller", (await out()) === "left")
await shut()
await page.evaluate(() => document.getElementById("qa-wide").remove())

await page.evaluate(() => scrollTo(0, 0)); await until(() => page.locator("[data-phone-header] button[aria-label='Open sidebar']").isVisible(), 3000); await ui.idle()
await page.locator("[data-phone-header] button[aria-label='Open sidebar']").tap(); await opened("left")
await finger(200, 500, -170, 2)
await still()
check("a swipe left across the open sidebar's middle shuts it", !(await out()))
await page.locator("[data-phone-header] button[aria-label='Open right sidebar']").tap(); await opened("right")
await finger(30, 500, 200, 2)
await still()
check("a swipe right from the shade beside the right sidebar shuts it", !(await out()))

await page.locator("[data-phone-header] button[aria-label='Open sidebar']").tap()
await until(async () => { const v = await inBy("left"); return v !== null && v > 60 && v < 260 }, 1000, 5)
await touch("touchStart", 40, 500)
const caught = await inBy("left")
for (let i = 0; i < 8; i++) await frame()
const held = await inBy("left")
check("a touch on a drawer sliding in holds it where it was", caught !== null && held !== null && caught < 320 && Math.abs(held - caught) <= 4, [caught, held])
await finger(40, 500, -64, 1, { n: 8, down: false }); await still()
check("...and flicked back, it shuts", !(await out()))
await ui.idle()

await page.goto(`${B}#new`); await page.waitForSelector("[data-newtab-section]"); await ui.idle()
const row = await page.evaluate((t) => {
  const r = [...document.querySelectorAll("[data-newtab-section] [data-result]")].find((x) => x.textContent.includes(t))
  if (!r) return null
  r.scrollIntoView({ block: "center" })
  const b = r.getBoundingClientRect()
  return { x: b.x + b.width / 2, y: b.y + b.height / 2 }
}, ROW)
if (row) {
  await finger(row.x + 60, row.y, -150, 1); await ui.idle()
  const buttons = await page.evaluate(() => [...document.querySelectorAll("[data-newtab-section] [data-swipe-under]")].some((u) => u.getBoundingClientRect().width > 20))
  check("a swipe left on a row shows its buttons, no sidebar", buttons && !(await out()), [buttons, await out()])
  await page.screenshot({ path: `${OUT}row.png` })
  await finger(row.x - 60, row.y, 180, 1); await ui.idle()
  const shutRow = await page.evaluate(() => !document.querySelector("[data-newtab-section] [data-swiped]"))
  check("open, a swipe right shuts the row first, no sidebar", shutRow && !(await out()), [shutRow, await out()])
  await finger(row.x - 60, row.y, 180, 1); await still()
  check("then a swipe right on the row opens the left sidebar", (await out()) === "left")
  await shut()
} else check("the Inbox row shows on the new tab", false)

for (const [n, text] of Object.entries(kept)) { if (text === null) rmSync(conf(n), { force: true }); else writeFileSync(conf(n), text) }
await api("DELETE", `file?path=${encodeURIComponent("Qa drawer/Harbour.md")}`).catch(() => {})
await done()
