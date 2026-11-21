// The left sidebar's bars (components/SidebarBar.tsx, components/barMenus.ts, core/sidebarbars.ts, core/slide.ts): things
// dragged between header, bottom bar and sidebars; Header ▸, Hide. WRITES: appearance.json, sidebars.json (put back).
//   node web/qa/sidebarbars.mjs <base url>
import { apiAt, qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"

const { args: [B0], browser, check, watch, done } = await qa(import.meta.url)
const B = B0.endsWith("/") ? B0 : `${B0}/`
const api = apiAt(B)
const look = await api("GET", "config/appearance")
const sidesBefore = await api("GET", "config/sidebars")
await api("PATCH", "config/appearance", { sidebarHeader: null, sidebarFoot: null })

try {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } })
  await ctx.addInitScript(() => { if (!sessionStorage.getItem("qa")) { localStorage.clear(); sessionStorage.setItem("qa", "1") } })
  const page = watch(await ctx.newPage(), { console: true })
  const { idle, menu } = app(page)
  await page.goto(B)
  const inHeader = (k) => page.locator(`aside [data-sidebar-bar=header] [data-bar-key='${k}']`)
  const inFoot = (k) => page.locator(`aside [data-sidebar-bar=foot] [data-bar-key='${k}']`)
  const bars = async () => { const a = await api("GET", "config/appearance"); return { header: a.sidebarHeader, foot: a.sidebarFoot } }
  const left = async () => (await api("GET", "config/sidebars"))?.left ?? []
  check("the Plugins button is in the bottom bar", !!(await until(async () => (await inFoot("core:plugins").count()) === 1, 15000)))

  async function drag(from, to, { dx = 0, dy = 0 } = {}) {
    const a = await from.boundingBox(), b = await to.boundingBox()
    const x0 = a.x + a.width / 2, y0 = a.y + a.height / 2, x1 = b.x + b.width / 2 + dx, y1 = b.y + b.height / 2 + dy
    await page.mouse.move(x0, y0)
    await page.mouse.down()
    for (let i = 1; i <= 12; i++) await page.mouse.move(x0 + (x1 - x0) * i / 12, y0 + (y1 - y0) * i / 12)
    await idle()
    await page.mouse.up()
    await idle()
  }

  const files = page.locator("aside [data-sidebar-body=left] > [data-panel='files:files'] [data-panel-handle] span").first()
  await drag(files, page.locator("aside [data-titlebar]"), { dx: 60 })
  check("Files dragged to the header: its icon there", !!(await until(async () => (await inHeader("files:files").count()) === 1)))
  check("and out of the left sidebar", !(await left()).includes("files:files"), await left())
  await inHeader("files:files").locator("button").click()
  check("its icon opens the file explorer under it", !!(await until(async () => (await page.locator("[data-flyout='files:files']").count()) === 1)))
  await page.keyboard.press("Escape")
  await idle()

  await drag(inHeader("files:files"), inFoot("core:plugins"), { dx: -8 })
  check("dragged left of Plugins: drawn there", !!(await until(async () => (await inFoot("files:files").count()) === 1 && (await inHeader("files:files").count()) === 0)))
  const b1 = await bars()
  check("saved in the bottom bar, before Plugins", b1.foot?.join() === "files:files,core:plugins" && !b1.header?.includes("files:files"), b1)

  await drag(inFoot("files:files"), page.locator("aside [data-sidebar-body=left]"))
  check("dragged into the sidebar: its panel there again", !!(await until(async () => (await left()).includes("files:files"))), await left())
  check("and not drawn in the bottom bar too", (await inFoot("files:files").count()) === 0)

  const leftBefore = (await left()).join()
  await drag(inFoot("core:plugins"), page.locator("aside [data-sidebar-body=left] > [data-panel]").first())
  check("the Plugins button doesn't go into a sidebar", (await left()).join() === leftBefore && (await inFoot("core:plugins").count()) === 1)

  await menu.context(inFoot("core:plugins"))
  await menu.pick("Hide Plugins")
  check("Hide Plugins: gone", !!(await until(async () => (await inFoot("core:plugins").count()) === 0)))
  await menu.context(page.locator("aside [data-sidebar-foot]"), { position: { x: 150, y: 10 } })
  await menu.pick("Bottom bar", "More", "Plugins")
  await menu.close()
  check("Bottom bar ▸ More ▸ Plugins: back", !!(await until(async () => (await inFoot("core:plugins").count()) === 1)))

  await menu.context(page.locator("aside [data-titlebar]"), { position: { x: 60, y: 20 } })
  await menu.pick("Header", "Inbox")
  await menu.close()
  check("Header ▸ Inbox unticked: saved without it", !!(await until(async () => Array.isArray((await bars()).header) && !(await bars()).header.includes("inbox:inbox"))), await bars())
  await page.reload()
  await page.locator("aside [data-sidebar-bar=foot]").waitFor()
  await idle()
  check("after a reload the bars are as left", (await inFoot("core:plugins").count()) === 1 && (await inHeader("inbox:inbox").count()) === 0)
  await menu.context(page.locator("aside [data-titlebar]"), { position: { x: 60, y: 20 } })
  await menu.pick("Header", "More", "Inbox")
  await menu.close()
  check("Header ▸ More ▸ Inbox: back in it", !!(await until(async () => (await bars()).header?.includes("inbox:inbox"))), await bars())
} finally {
  await api("PATCH", "config/appearance", { sidebarHeader: look.sidebarHeader ?? null, sidebarFoot: look.sidebarFoot ?? null })
  await api("PUT", "config/sidebars", sidesBefore)
  await done()
}
