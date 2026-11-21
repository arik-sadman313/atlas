// node web/qa/rebindkeys.mjs <base url> <vault path>: clicking a shown shortcut changes it; WRITES hotkeys.json. Paths: web/src/core/rebind.ts, web/src/pages/Hotkeys.tsx, web/src/components/CommandPalette.tsx, web/src/components/ContextMenu.tsx
import { existsSync, readFileSync } from "node:fs"
import path from "node:path"
import { qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
const { args: [B, VAULT], browser, check, watch, done } = await qa(import.meta.url)

const FILE = path.join(VAULT, ".vaultite", "hotkeys.json")
const saved = () => (existsSync(FILE) ? JSON.parse(readFileSync(FILE, "utf8")) : {})
const page = watch(await browser.newPage({ viewport: { width: 1280, height: 800 } }))
const { idle, menu, toast } = app(page)
await page.goto(B)
await page.waitForSelector("[role=tree]", { timeout: 30000 })
await idle()

const palette = async () => {
  await page.keyboard.press("ControlOrMeta+p")
  await page.keyboard.type("Open hotkeys")
  await page.locator("[role=option]", { hasText: "Open hotkeys" }).first().waitFor()
  await idle()
}
const keysIn = (where) => page.locator(`${where} [data-rebind="hotkeys:open"]`).first()

await palette()
await keysIn("[role=option]").click()
await idle()
check("clicking the keys in the palette asks for new ones, the command not run", await menu.isOpen() && !(await page.$("[data-hotkeys]")), await menu.items())
check("…and keeps the palette open", !!(await page.$("[aria-label='Command palette']")))
await page.keyboard.press("Escape")
await idle()
check("Escape keeps the keys and the palette", !(await menu.isOpen()) && !!(await page.$("[aria-label='Command palette']")) && !saved()["hotkeys:open"], saved())

await keysIn("[role=option]").click()
await idle()
await page.keyboard.press("ControlOrMeta+o")
await idle()
check("keys another command has ask first", (await menu.items()).join() === "Replace,Keep both", await menu.items())
await menu.pick("Replace")
check("Replace moves them", await until(() => saved()["hotkeys:open"]?.[0] === "Mod+O" && saved()["switcher:open"]?.length === 0, 4000), saved())
check("…and says so with Undo", (await toast()).some((t) => t.includes("Open hotkeys is now")), await toast())
await page.getByRole("button", { name: "Undo" }).click()
check("Undo gives both their keys back", await until(() => !saved()["hotkeys:open"] && !saved()["switcher:open"], 4000), saved())
await page.keyboard.press("Escape")
await idle()

await page.goto("about:blank")
await page.goto(`${B}#home/hotkeys`)
await page.waitForSelector("[data-hotkeys]")
await idle()
await keysIn("[data-hotkey]").click()
await idle()
await page.keyboard.press("ControlOrMeta+Alt+j")
check("on Hotkeys, a free combination is saved at once", await until(() => saved()["hotkeys:open"]?.[0] === "Mod+Alt+J", 4000), saved())
await idle()
await keysIn("[data-hotkey]").click()
await idle()
await menu.pick("Restore default ?")
check("Restore default goes back", await until(() => !saved()["hotkeys:open"], 4000), saved())

await done()
