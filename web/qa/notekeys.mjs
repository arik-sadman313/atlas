// Phones: the keys over the keyboard (KeyboardKeys.tsx, core/keyboard.ts), a note's, a terminal's, and Done for every field in the
// iPhone app (Palette.tsx, pages/Search.tsx), on a made-up keyboard. Writes and starts a shell: throwaway servers.
//   node web/qa/notekeys.mjs <base url> [out dir]
import { mkdirSync } from "node:fs"
import path from "node:path"
import { fingers, qa, until, wait } from "./lib/qa.mjs"
const { args: [B, OUT = "/tmp/notekeys-shots/"], browser, check, watch, done } = await qa(import.meta.url)
mkdirSync(OUT, { recursive: true })

const KB = 300
const W = `wander${Date.now() % 100000}` // (a word of this run's: the note keeps earlier runs' lines)
const page = watch(await browser.newPage({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }))
// The keyboard: while `__kb`, the visual viewport is KB short of the window.
await page.addInitScript((kb) => {
  const vv = window.visualViewport, h = Object.getOwnPropertyDescriptor(VisualViewport.prototype, "height").get
  Object.defineProperty(vv, "height", { get: () => h.call(vv) - (window.__kb ? kb : 0) })
  window.__keyboard = (on) => { window.__kb = on; vv.dispatchEvent(new Event("resize")) }
}, KB)
const { touch } = await fingers(page)
const tap = async (loc) => {
  // (the row scrolls sideways: the key brought into it first)
  await loc.evaluate((e) => e.scrollIntoView({ inline: "nearest", block: "nearest" })); await wait(100)
  const b = await loc.boundingBox()
  await touch("touchStart", b.x + b.width / 2, b.y + b.height / 2); await wait(40); await touch("touchEnd", b.x + b.width / 2, b.y + b.height / 2); await wait(250)
}
const text = () => page.evaluate(() => globalThis.__vaultite.modules["@vaultite"].currentEditor()?.view.state.doc.toString() ?? "")
const bar = page.locator("[role=toolbar][aria-label='Editing keys']")
const key = (name) => bar.locator(`button[aria-label='${name}']`)

await page.goto(`${B}#file/${encodeURIComponent("Notes/Lisbon trip.md")}`)
const content = page.locator(".file-view .cm-content").first()
await content.waitFor({ timeout: 30000 })
check("no keys before typing", !(await bar.count()))

// (a phone opens a note for reading: the pencil makes it editable)
if (await page.locator("[data-view-toggle=read]").count()) { await tap(page.locator("[data-view-toggle=read]").first()); await wait(500) }
await content.click()
// (the note's body made one line of this run's, the cursor after it; then typed, as a phone would)
await page.evaluate(() => {
  const { view, start } = globalThis.__vaultite.modules["@vaultite"].currentEditor()
  const from = start(view.state)
  view.dispatch({ changes: { from, to: view.state.doc.length, insert: "Plans\n\n" }, selection: { anchor: from + 7 } })
})
await page.keyboard.type(`- ${W}`)
await page.evaluate(() => window.__keyboard(true)); await wait(300)
check("the keys come up with the keyboard", await bar.count() === 1)
const box = await bar.boundingBox()
check("over the keyboard, at the visible part's foot", !!box && Math.abs(box.y + box.height - (844 - KB)) <= 2, box)
const names = await bar.locator("button").evaluateAll((bs) => bs.map((b) => b.getAttribute("aria-label")))
check("the default keys, then Hide keyboard", names.join() === "Undo,Redo,Link,Task,Unindent,Indent,Bold,Italic,Highlight,Bullet list,Photo or video,Hide keyboard", names)
const barHidden = () => page.evaluate(() => getComputedStyle(document.querySelector("[data-phone-bar]")).visibility === "hidden")
check("the bottom bar is out of sight while typing, and Hide keyboard reads Done", await until(barHidden, 2000)
  && (await bar.locator("button[aria-label='Hide keyboard']").innerText()).trim() === "Done")
await page.screenshot({ path: path.join(OUT, "keys.png") })

await tap(key("Bold"))
check("Bold: the word at the cursor", (await text()).includes(`- **${W}**`), (await text()).split("\n").filter((l) => l.includes(W)))
check("the editor kept the keyboard", await page.evaluate(() => document.activeElement?.classList.contains("cm-content")))
await tap(key("Undo"))
check("Undo: bold gone", !(await text()).includes(`**${W}**`), (await text()).split("\n").filter((l) => l.includes(W)))
await tap(key("Redo"))
check("Redo: bold back", (await text()).includes(`- **${W}**`))
await tap(key("Indent"))
check("Indent: the item one level in (a tab, the editor's default)", (await text()).includes(`\n\t- **${W}**`), (await text()).split("\n").filter((l) => l.includes(W)))
await tap(key("Unindent"))
check("Unindent: back out", (await text()).includes(`\n- **${W}**`), (await text()).split("\n").filter((l) => l.includes(W)))
await tap(key("Task"))
check("Task: a checkbox", (await text()).includes(`\n- [ ] **${W}**`), (await text()).split("\n").filter((l) => l.includes(W)))

await tap(bar.locator("button[aria-label='Hide keyboard']"))
await page.evaluate(() => window.__keyboard(false))
check("Hide keyboard: the editor lets go, the keys go, the bottom bar comes back", !!await until(async () => !(await bar.count()) && !(await barHidden()), 2000)
  && !(await page.evaluate(() => document.activeElement?.classList.contains("cm-content"))))

const title = page.locator(".file-view textarea[aria-label='File name']").first()
const nbar = page.locator("[role=toolbar][aria-label='Name keys']")
const marked = () => page.evaluate(() => document.documentElement.hasAttribute("data-keyboard"))
await tap(title)
check("a name taken: the bar steps away before the keyboard's slide ends", await marked())
await page.evaluate(() => window.__keyboard(true)); await nbar.waitFor()
const nnames = await nbar.locator("button").evaluateAll((bs) => bs.map((b) => b.getAttribute("aria-label")))
check("the name's keys over the keyboard: Go to the text, Hide keyboard", nnames.join() === "Go to the text,Hide keyboard", nnames)
const name = await title.inputValue()
await page.keyboard.type("zz"); await nbar.locator("button[aria-label='Put the name back']").waitFor()
await page.screenshot({ path: path.join(OUT, "name.png") })
await tap(nbar.locator("button[aria-label='Put the name back']"))
check("Put the name back: the name as it was, still typing it", await title.inputValue() === name
  && await page.evaluate(() => document.activeElement?.getAttribute("aria-label") === "File name"), await title.inputValue())
await tap(nbar.locator("button[aria-label='Go to the text']"))
check("Go to the text: the note's text takes the keyboard", !!await until(() => page.evaluate(() => document.activeElement?.classList.contains("cm-content")), 2000))
await tap(title); await nbar.waitFor()
await tap(nbar.locator("button[aria-label='Hide keyboard']"))
check("Hide keyboard on the name: it lets go, the keys go", !!await until(async () => !(await nbar.count()), 2000)
  && await page.evaluate(() => document.activeElement?.getAttribute("aria-label") !== "File name"))
check("the bar stays away while the keyboard slides down", await marked())
await page.evaluate(() => window.__keyboard(false))
check("and comes back once it's down", !!await until(async () => !(await marked()), 2000))
await tap(title)
check("a field with no keys rising (a hardware keyboard): marked at first", await marked())
check("then not, once the slide would have ended", !!await until(async () => !(await marked()), 2000))
await page.evaluate(() => document.activeElement?.blur())

// The terminal's keys are the same bar: esc to paste, then Hide keyboard.
await page.goto(`${B}#view/terminal%2Fnotekeys-${Date.now()}`)
const term = page.locator("[data-terminal] [data-term-input]")
await term.waitFor({ state: "attached", timeout: 30000 })
await tap(page.locator("[data-terminal]")); await term.focus()
await page.evaluate(() => window.__keyboard(true)); await wait(400)
const tkeys = await page.locator("[role=toolbar][aria-label='Terminal keys'] button").evaluateAll((bs) => bs.map((b) => b.getAttribute("aria-label")))
check("terminal: its keys over the keyboard", tkeys.join() === "Escape,Tab,Shift Tab,Control C,Left,Up,Down,Right,Paste,Hide keyboard", tkeys)
await page.screenshot({ path: path.join(OUT, "terminal.png") })
await page.close()

const fakeKeyboard = (kb) => {
  const vv = window.visualViewport, h = Object.getOwnPropertyDescriptor(VisualViewport.prototype, "height").get
  Object.defineProperty(vv, "height", { get: () => h.call(vv) - (window.__kb ? kb : 0) })
  window.__keyboard = (on) => { window.__kb = on; vv.dispatchEvent(new Event("resize")) }
}
const shell = () => {
  window.Capacitor = { isNativePlatform: () => true, isPluginAvailable: (n) => n === "Shell", nativePromise: async (_, method) => (method === "servers" ? { servers: [] } : {}) }
}

async function phone(inApp) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true })
  await ctx.addInitScript(fakeKeyboard, KB)
  if (inApp) await ctx.addInitScript(shell)
  const page = watch(await ctx.newPage())
  const { touch } = await fingers(page)
  const tap = async (loc) => {
    const b = await loc.boundingBox()
    await touch("touchStart", b.x + b.width / 2, b.y + b.height / 2); await touch("touchEnd", b.x + b.width / 2, b.y + b.height / 2)
  }
  const up = (on) => page.evaluate((v) => window.__keyboard(v), on)
  return { ctx, page, tap, up }
}
const bars = (page) => page.locator("[data-keyboard-keys] [role=toolbar]")
const labelsOf = (loc) => loc.locator("button").evaluateAll((bs) => bs.map((b) => b.getAttribute("aria-label")))
const focusedIs = (page, sel) => page.evaluate((s) => !!document.activeElement?.matches(s), sel)
const settled = async (loc) => { await loc.waitFor(); await until(() => loc.evaluate((e) => getComputedStyle(e.closest("[data-keyboard-keys]")).opacity === "1"), 2000); return loc }

{
  const { ctx, page, tap, up } = await phone(true)
  const bar = bars(page)
  await page.goto(`${B}#file/${encodeURIComponent("Notes/Lisbon trip.md")}`)
  await page.locator(".file-view").first().waitFor({ timeout: 30000 })

  await page.evaluate(() => globalThis.__vaultite.modules["@vaultite"].runCommandById("switcher:open"))
  const palette = page.locator("[data-palette] [role=dialog]")
  await palette.waitFor()
  await up(true); await settled(bar)
  check("the palette (as a pull down opens it): a row over the keyboard with only Done", await bar.count() === 1 && (await labelsOf(bar)).join() === "Hide keyboard", await labelsOf(bar))
  const b = await bar.boundingBox()
  check("  at the visible part's foot", !!b && Math.abs(b.y + b.height - (844 - KB)) <= 2, b)
  const p = await until(async () => { const r = await palette.boundingBox(); return r && r.y + r.height <= b.y + 1 && r }, 2000)
  check("  the palette ends above it", !!p, await palette.boundingBox())
  await page.screenshot({ path: path.join(OUT, "palette.png") })
  await tap(bar.locator("button[aria-label='Hide keyboard']"))
  check("  Done: the field lets go, the palette stays open", !!await until(async () => !(await focusedIs(page, "[data-palette] input")), 2000) && await palette.count() === 1)
  await up(false)
  check("  and the row goes with the keyboard", !!await until(async () => !(await bar.count()), 2000))
  await page.locator("[data-palette] input").focus(); await up(true)
  check("  the field again: the row is back", !!await until(async () => await bar.count() === 1, 2000))
  await page.keyboard.press("Escape"); await up(false)

  await page.goto(`${B}#view/search`)
  const field = page.locator("input[aria-label='Search the vault']")
  await field.waitFor({ timeout: 30000 })
  await tap(field); await up(true); await settled(bar)
  check("a page's field: Done over the keyboard", (await labelsOf(bar)).join() === "Hide keyboard", await labelsOf(bar))
  await tap(bar.locator("button[aria-label='Hide keyboard']"))
  check("  Done: the field lets go", !!await until(async () => !(await focusedIs(page, "input[aria-label='Search the vault']")), 2000))
  await up(false)
  await field.focus(); await page.keyboard.press("Enter")
  check("  its Search key lets go too", !!await until(async () => !(await focusedIs(page, "input[aria-label='Search the vault']")), 2000))

  await page.goto(`${B}#file/${encodeURIComponent("Notes/Lisbon trip.md")}`)
  const content = page.locator(".file-view .cm-content").first()
  await content.waitFor({ timeout: 30000 })
  const read = page.locator("[data-view-toggle=read]")
  if (await read.count()) { await tap(read.first()); await until(async () => !(await read.count()), 3000) }
  await content.click(); await up(true); await settled(bar)
  check("a note: one row, its editing keys", await bar.count() === 1 && await bar.getAttribute("aria-label") === "Editing keys", await bar.count())
  await page.evaluate(() => document.activeElement?.blur()); await up(false)

  await page.goto(`${B}#view/terminal%2Fkeyboardkeys-${Date.now()}`)
  const term = page.locator("[data-terminal] [data-term-input]")
  await term.waitFor({ state: "attached", timeout: 30000 })
  await tap(page.locator("[data-terminal]")); await term.focus(); await up(true)
  await page.locator("[role=toolbar][aria-label='Terminal keys']").waitFor()
  check("the terminal draws its own keys: none of ours on top", await bar.count() === 0)
  await ctx.close()
}

{
  const { ctx, page, up } = await phone(false)
  await page.goto(`${B}#view/search`)
  const field = page.locator("input[aria-label='Search the vault']")
  await field.waitFor({ timeout: 30000 })
  await field.focus(); await up(true)
  check("in a browser iOS draws its own bar: none of ours for a plain field", !(await until(async () => await bars(page).count() > 0, 1000)))
  await ctx.close()
}
const desk = watch(await browser.newPage({ viewport: { width: 1400, height: 900 } }))
await desk.goto(`${B}#file/${encodeURIComponent("Notes/Lisbon trip.md")}`)
await desk.locator(".file-view .cm-content").first().click()
await wait(400)
check("desktop: no keys", !(await desk.locator("[role=toolbar][aria-label='Editing keys']").count()))
await desk.close()
console.log(`\nshots in ${OUT}`)
await done()
