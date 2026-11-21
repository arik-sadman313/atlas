// The icon picker (components/IconPicker.tsx, GlyphGrid.tsx, core/glyphs.ts, glyphgrid.ts): node web/qa/iconpicker.mjs <base url> <vault path>
import { readFileSync, writeFileSync, mkdirSync } from "node:fs"
import path from "node:path"
import { apiAt, qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
import { setAsideWorkspaces, workspaces, wsDir } from "./lib/wsfiles.mjs"
const { args: [B, VAULT], browser, check, watch, done } = await qa(import.meta.url)
const api = apiAt(B, { "X-Vaultite-Client": "app/qa" })

const PLUGINS = path.join(VAULT, ".vaultite/plugins.json")
const pluginsBefore = readFileSync(PLUGINS, "utf8")
const putBack = setAsideWorkspaces(B)
writeFileSync(PLUGINS, JSON.stringify({ ...JSON.parse(pluginsBefore), enabled: [...(JSON.parse(pluginsBefore).enabled ?? []), "workspaces"] }, null, 2) + "\n")
mkdirSync(wsDir(VAULT), { recursive: true })
writeFileSync(path.join(wsDir(VAULT), "1.json"), JSON.stringify({ name: "Tournament", icon: "🥷" }) + "\n")
const SWITCHER = "aside [data-workspace-switcher]", GRID = "[role=dialog] #glyph-grid"

try {
  const page = watch(await (await browser.newContext({ viewport: { width: 1280, height: 800 } })).newPage(), { console: true, ignore: /favicon|Failed to load resource|WebSocket/ }), ui = app(page)
  await page.goto(B)
  await page.waitForSelector(SWITCHER, { timeout: 30000 })
  const open = async () => {
    await page.click(SWITCHER, { button: "right" })
    await page.locator("[role=menu] [role^=menuitem]", { hasText: /^Change icon/ }).last().click()
    await page.waitForSelector(`${GRID} [data-glyph]`, { timeout: 8000 }); await ui.idle()
  }
  const name = () => page.$eval("[data-glyph-name]", (e) => e.textContent)
  const selected = () => page.$eval(`${GRID} [aria-selected=true]`, (e) => e.dataset.glyph).catch(() => null)
  const glyphs = () => page.$$eval(`${GRID} [data-glyph]`, (els) => els.map((e) => e.dataset.glyph))
  const type = async (q) => { await page.fill("[role=dialog] input", q); await ui.idle() }

  await open()
  check("opens on the current one, named, not drawn twice", await selected() === "🥷" && await name() === "Ninja"
    && (await page.innerText("[data-glyph-about]")).includes(":ninja:"), [await selected(), await page.innerText("[data-glyph-about]")])
  const groups = await page.$$eval("[data-glyph-groups] button", (els) => els.map((e) => e.getAttribute("aria-label")))
  check("groups to jump to: recent, icons, then the emoji's", groups.slice(0, 3).join() === "Recent,Icons,Smileys & Emotion" && groups.includes("Flags"), groups)
  const drawn = (await glyphs()).length
  check("only the rows near the screen drawn, of thousands", drawn > 60 && drawn < 900, drawn)
  const cells = await glyphs()
  check("a workspace's picker starts with its own number, the current icon after it", cells[0] === "\u0000none" && cells[1] === "🥷", cells.slice(0, 3))
  await page.keyboard.press("ArrowDown"); await ui.idle()
  check("Down: the icons' first row, under it", await selected() === "apple", await selected())
  await page.keyboard.press("ArrowLeft"); await ui.idle()
  await page.keyboard.press("ArrowRight"); await page.keyboard.press("ArrowDown"); await ui.idle()
  const second = await selected()
  await page.keyboard.press("ArrowUp"); await ui.idle()
  check("Right and Down move along the grid, Up back", second !== "apple" && second !== null && await selected() === "apple", [second, await selected()])
  await page.keyboard.press("Tab"); await ui.idle()
  check("Tab: the next group's first", await selected() === "😀" && await name() === "Grinning face", [await selected(), await name()])
  await page.click("[data-glyph-groups] button[aria-label=Flags]"); await ui.idle()
  check("a group's button scrolls to it, far down", await until(async () => (await glyphs()).includes("🏁"), 2000) && await page.$eval(GRID, (e) => e.scrollTop) > 5000)

  await type("ninja")
  check("an emoji found by its name", (await glyphs())[0] === "🥷", await glyphs())
  await type("heart")
  const hearts = await glyphs()
  check("icons and emoji found together", hearts[0] === "heart" && hearts.includes("❤️"), hearts.slice(0, 8))
  await type(":heart")
  check("a colon: emoji only", (await glyphs()).every((g) => !/^[a-z]/.test(g)) && (await glyphs())[0] === "❤️", (await glyphs()).slice(0, 5))
  await type("book-open")
  await page.keyboard.press("Enter")
  check("Enter picks it, kept in its file", await until(() => workspaces(B)[0]?.icon === "book-open", 5000), workspaces(B)[0])

  await api("POST", "ops/settings.set", { name: "appearance", values: { iconPickerEmoji: false } })
  await until(() => page.evaluate(() => JSON.parse(localStorage.getItem("vaultite.prefs") ?? "{}").iconPickerEmoji === false), 5000)
  await open()
  const off = await page.$$eval("[data-glyph-groups] button", (els) => els.map((e) => e.getAttribute("aria-label")))
  check("emoji off: none to jump to, but a colon finds them", !off.some((g) => g.includes("Smileys")) && (await type(":ninja"), (await glyphs())[0] === "🥷"), off)
  await type("ninja")
  check("… and without it, none", (await glyphs()).length === 0 && /No icon matches/.test(await page.innerText("[role=dialog]")))
  await page.keyboard.press("Escape")
} finally {
  await api("POST", "ops/settings.set", { name: "appearance", values: { iconPickerEmoji: null } }).catch(() => {})
  writeFileSync(PLUGINS, pluginsBefore)
  putBack()
}
await done()
