// Tab groups in the Tabs panel taking a tab, opening under one held there, going to a workspace whole. Writes settings (put back).
//   node web/qa/groupdrag.mjs <base url> <vault path> [out dir]
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import path from "node:path"
import { apiAt, palette, qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
import { setAsideWorkspaces, workspaces } from "./lib/wsfiles.mjs"
const { args: [B0, VAULT, OUT = "/tmp/groupdrag-shots/"], browser, check, watch, done } = await qa(import.meta.url)
const B = B0.endsWith("/") ? B0 : `${B0}/`
mkdirSync(OUT, { recursive: true })
const api = apiAt(B)

const keep = (f) => { const p = path.join(VAULT, ".vaultite", f); return { p, was: existsSync(p) ? readFileSync(p, "utf8") : null } }
const look = keep("appearance.json"), plugins = keep("plugins.json"), sidebars = keep("sidebars.json")
const json = (f) => JSON.parse(f.was ?? "{}")
writeFileSync(plugins.p, JSON.stringify({ ...json(plugins), enabled: [...(json(plugins).enabled ?? []), "workspaces"] }) + "\n")
const putBack = setAsideWorkspaces(B)
const notes = ["Start here.md", "Projects/Lighthouse.md", "Projects/Garden planner.md", "ME.md"]

try {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 760 } })
  const page = watch(await ctx.newPage()), ui = app(page)
  await page.goto(`${B}#file/${encodeURIComponent(notes[0])}`)
  await page.waitForSelector("aside [data-workspace-switcher]")
  await palette(page, "Show tabs in the sidebar")
  await page.waitForSelector("[data-tabs-panel] [data-open-tab]")
  for (const p of notes.slice(1)) await api("POST", "ops/ui.open", { path: p, newTab: true })
  await until(async () => (await page.$$("[data-tabs-panel] [data-open-tab]")).length === 4, 6000)
  await api("POST", "ops/tabs.group", { tabs: ["Projects/Lighthouse.md", "ME.md"], name: "Lighthouse work", collapsed: true })
  const head = page.locator("[data-tabs-panel] [data-group-row]").first()
  await head.waitFor()
  const row = (label) => page.locator("[data-tabs-panel] [data-open-tab]", { hasText: label }).first()
  const hold = async (from, to, at = 0.5) => {
    const a = await from.boundingBox(), b = await to.boundingBox()
    await page.mouse.move(a.x + 40, a.y + a.height / 2); await page.mouse.down()
    await page.mouse.move(a.x + 48, a.y + a.height / 2 + 4, { steps: 3 })
    await page.mouse.move(b.x + 40, b.y + b.height * at, { steps: 12 })
    return async (drop = true) => { if (!drop) await page.keyboard.press("Escape"); await page.mouse.up(); await ui.idle() }
  }
  const count = () => head.locator("[data-group-count]").innerText().then((t) => t.trim())
  await row("Start here").click(); await ui.idle()

  let release = await hold(row("Garden planner"), head)
  const seen = await until(async () => {
    const lit = await head.evaluate((e) => e.hasAttribute("data-target")).catch(() => false)
    return lit ? { lit, count: await count(), aside: await page.$eval("[data-drag-card]", (e) => e.style.translate !== "") } : null
  }, 3000)
  await page.screenshot({ path: `${OUT}held-on-folded.png`, clip: { x: 0, y: 0, width: 420, height: 320 } })
  await release()
  check("held on a folded group: its row lights, its count says 3, the card steps aside", seen?.count === "3" && seen.aside, seen)
  check("  dropped: the tab goes in, the group still folded", await until(async () => (await count()) === "3" && !(await row("Garden planner").count()), 4000) && (await head.getAttribute("aria-expanded")) === "false", await count())

  release = await hold(row("Start here"), head)
  const sprang = await until(async () => (await head.getAttribute("aria-expanded")) === "true", 4000)
  await page.screenshot({ path: `${OUT}sprung-open.png`, clip: { x: 0, y: 0, width: 420, height: 320 } })
  await release(false)
  const refolded = await until(async () => (await head.getAttribute("aria-expanded")) === "false", 4000)
  check("held a second on it, the group opens; nothing dropped, it folds again", !!sprang && !!refolded && (await count()) === "3", [sprang, refolded, await count()])

  const switcher = page.locator("aside [data-workspace-switcher]")
  release = await hold(head, switcher)
  await until(() => page.$("[data-workspace-list]"), 3000)
  const two = page.locator("[data-workspace-list] [data-workspace='2']"), t = await two.boundingBox()
  await page.mouse.move(t.x + t.width / 2, t.y + t.height / 2, { steps: 8 }); await ui.idle()
  const ghost = await page.$eval("[data-drag-ghost]", (e) => e.innerText).catch(() => "")
  await page.screenshot({ path: `${OUT}group-onto-workspace.png`, clip: { x: 0, y: 0, width: 520, height: 320 } })
  await release()
  check("a group over a workspace says so on its card, with its chip", ghost.includes("Lighthouse work") && ghost.includes("Move group to workspace 2"), ghost)
  const there = await until(() => { const l = workspaces(B)[1]?.layout; return l?.groups?.length === 1 && l.tabs.length === 3 ? l : null }, 6000)
  check("  dropped: workspace 2 has the group, its 3 tabs, still folded", !!there && there.groups[0].name === "Lighthouse work" && there.groups[0].collapsed === true, there)
  check("  and it's gone from here", !!(await until(async () => !(await page.$("[data-tabs-panel] [data-group-row]")), 4000)))
  await ctx.close()
} finally {
  putBack()
  for (const f of [look, plugins, sidebars]) if (f.was === null) rmSync(f.p, { force: true }); else writeFileSync(f.p, f.was)
}
await done()
