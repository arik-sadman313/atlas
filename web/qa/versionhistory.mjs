// Version history (plugins/core/history: HistoryView.tsx, Version.tsx, Edited.tsx, changes.ts): who wrote each version,
// its changes marked in the note, Restore with Undo, the header line after an agent's edit, 390px with its stepper, and
// the phone's Find in note (find/index.tsx, components/Tabs.tsx). Writes QA history <run>/, appearance.json and
// Activity's settings: throwaway server only.
//   node web/qa/versionhistory.mjs <base url> <vault path> [out dir]
import { mkdirSync, readFileSync, rmSync } from "node:fs"
import { qa, until, wait } from "./lib/qa.mjs"
const { args: [BASE, VAULT, OUT = "/tmp/history-shots/"], browser, check, watch, done } = await qa(import.meta.url)
const B = BASE.replace(/\/+$/, "")
mkdirSync(OUT, { recursive: true })
const text = (rel) => { try { return readFileSync(`${VAULT}/${rel}`, "utf8") } catch { return null } }
const api = (method, p, body, headers = {}) => fetch(`${B}/api/${p}`, { method, headers: { "Content-Type": "application/json", ...headers }, body: body && JSON.stringify(body) }).then((r) => r.json())
const as = (client, agent) => ({ "X-Vaultite-Client": client, ...(agent ? { "X-Vaultite-Agent": agent } : {}) })
const app = as("app/desktop")
const enc = encodeURIComponent
const theme = (t) => api("PATCH", "config/appearance", { theme: t }, app)

// Activity on (who wrote what is its), without its day recaps (their write asks first).
const plugins = await api("GET", "config/plugins", undefined, app)
await api("PATCH", "config/plugins", { enabled: [...(plugins.enabled ?? []).filter((x) => x !== "activity"), "activity"] }, app)
const recaps = (await api("GET", "config/plugin/activity", undefined, app))?.recaps
await api("PATCH", "config/plugin/activity", { recaps: false }, app)
await wait(1500)
const DIR = `QA history ${Date.now().toString(36).slice(-4)}`
const TRIP = `${DIR}/Trip to Porto.md`
const FIRST = "# Trip to Porto\n\nA long weekend in May with Alice Park.\n\n## Plan\n\n- Fly out Friday evening\n- Walk the Ribeira\n\n## Budget\n\nAbout 600 euros each.\n"
await api("PUT", "file", { path: TRIP, text: FIRST }, app)
await wait(400)
await api("POST", "ops/file.edit", { path: TRIP, old: "in May with Alice Park.", new: "in late May with Alice Park and Bob Lee." }, as("mcp", "ChatGPT"))
await wait(400)
await api("POST", "ops/file.edit", { path: TRIP, old: "- Walk the Ribeira", new: "- Walk the Ribeira\n- Day trip to the Douro valley" }, as("mcp", "Claude"))
const listed = () => api("GET", `history?path=${enc(TRIP)}`)
const seeded = await until(async () => { const h = await listed(); return h.now?.by === "Claude" && h.versions.some((v) => v.by === "ChatGPT") ? h : null }, 5000)
check("each version names its writer: the user's, ChatGPT's, Claude's now", !!seeded && seeded.versions.some((v) => v.kind === "you"), await listed())

async function open(w, h, mobile = false) {
  const ctx = await browser.newContext({ viewport: { width: w, height: h }, ...(mobile ? { isMobile: true, hasTouch: true } : {}) })
  return { ctx, page: watch(await ctx.newPage(), { label: w }) }
}
const go = async (page, hash) => {
  await page.goto("about:blank"); await page.goto(`${B}/#${hash}`); await wait(1200)
  const later = page.locator("dialog[data-confirm] button", { hasText: "Not now" })
  if (await later.count()) { await later.click(); await wait(300) }
}
const historyOf = `view/${enc(`history/${TRIP}`)}`
const chatgpt = seeded.versions.find((v) => v.by === "ChatGPT")

// ---------- desktop ----------
{
  const { ctx, page } = await open(1280, 800)
  await go(page, historyOf)
  const view = page.locator("[data-history]:visible")
  const entries = view.locator("[data-history-entry]")
  check("desktop: the list, the current version first, by Claude", await until(async () => (await entries.count()) >= 3) && /Current version[\s\S]*Claude/.test(await entries.first().innerText()), await view.innerText())
  check("desktop: the current version marks the block Claude added", await until(async () => (await view.locator("[data-change=add]").innerText()).includes("Douro valley")))
  await view.locator(`[data-history-entry="${chatgpt.t}"]`).click()
  const ins = view.locator("[data-history-text] ins")
  check("desktop: ChatGPT's version marks its words in the sentence", await until(async () => (await ins.allInnerTexts()).join("|") === "late|and Bob Lee"), await ins.allInnerTexts())
  for (const t of ["light", "dark"]) { await theme(t); await wait(700); await page.screenshot({ path: `${OUT}desktop-${t}-version.png` }) }
  await theme("light")
  await view.getByRole("switch", { name: "Show changes" }).click()
  check("desktop: Show changes off draws the version as it read", await until(async () => (await ins.count()) === 0 && (await view.locator("[data-history-text]").innerText()).includes("late May")))
  await view.getByRole("switch", { name: "Show changes" }).click()
  const you = (await listed()).versions.find((v) => v.kind === "you")
  await view.locator(`[data-history-entry="${you.t}"]`).click()
  await view.locator("[data-history-restore]").click()
  check("desktop: Restore this version writes it back", await until(() => text(TRIP)?.endsWith(FIRST.slice(1))), text(TRIP))
  await page.locator("[data-sonner-toast] button", { hasText: "Undo" }).click()
  check("desktop: Undo brings the text before back", await until(() => text(TRIP)?.includes("Douro valley")), text(TRIP))

  await api("POST", "ops/file.edit", { path: TRIP, old: "About 600 euros each.", new: "About 650 euros each." }, as("mcp", "ChatGPT"))
  await go(page, `file/${enc(TRIP)}`)
  const line = page.locator(`.file-view[data-path="${TRIP}"]:visible [data-history-edited]`)
  check("desktop: the header says the agent that edited it last", await until(async () => (await line.count()) === 1 && (await line.innerText()).startsWith("ChatGPT edited this")), await line.count())
  for (const t of ["light", "dark"]) {
    await theme(t); await wait(700)
    const box = await line.boundingBox()
    await page.screenshot({ path: `${OUT}desktop-${t}-header.png`, clip: { x: Math.max(0, box.x - 420), y: Math.max(0, box.y - 12), width: 700, height: 52 } })
  }
  await theme("light")
  await line.click()
  check("desktop: it opens the file's version history", await until(async () => (await page.locator("[data-history]:visible [data-history-entry]").count()) > 2))
  await ctx.close()
}

// ---------- 390 ----------
{
  const { ctx, page } = await open(390, 844, true)
  await go(page, historyOf)
  const view = page.locator("[data-history]:visible")
  const stepper = view.locator("[data-history-stepper]")
  check("390: the version with its stepper, the list folded away", await until(async () => (await stepper.count()) === 1) && !(await view.locator("[data-history-list]").isVisible()))
  await stepper.getByRole("button", { name: "Older version" }).click()
  check("390: Older version steps back", await until(async () => /Today, /.test(await stepper.innerText())), await stepper.innerText())
  const fit = await page.evaluate(() => {
    const v = [...document.querySelectorAll("[data-history]")].find((e) => e.checkVisibility())
    return { wide: document.documentElement.scrollWidth, restore: v.querySelector("[data-history-restore]")?.getBoundingClientRect().height ?? 0,
      arrows: Math.min(...[...v.querySelectorAll("[data-history-stepper] > button")].map((b) => b.getBoundingClientRect().height)) }
  })
  check("390: it fits, 44px arrows and Restore", fit.wide <= 390 && fit.arrows >= 44 && fit.restore >= 36, fit)
  for (const t of ["light", "dark"]) { await theme(t); await wait(700); await page.screenshot({ path: `${OUT}phone-${t}-version.png` }) }
  await theme("light")
  await stepper.getByRole("button", { name: "All versions" }).click()
  check("390: All versions shows the list", await until(() => view.locator("[data-history-list]").isVisible()))
  await page.screenshot({ path: `${OUT}phone-light-list.png` })

  // The phone's More menu finds in the note, as ⌘F does.
  await go(page, `file/${enc(TRIP)}`)
  await page.locator("[data-phone-header] button[aria-label=More]").click()
  const item = page.getByRole("menuitem", { name: "Find in note" })
  check("390: More starts with Find in note", await until(() => item.isVisible()))
  await page.screenshot({ path: `${OUT}phone-light-menu.png` })
  await item.click()
  const field = page.locator("[data-find-bar] input[aria-label=Find]:visible")
  check("390: the find bar opens, its field focused", await until(async () => (await field.count()) === 1 && await field.evaluate((e) => e === document.activeElement)))
  await field.fill("Ribeira")
  check("390: it counts the matches", await until(async () => /1 of 1|1 result/.test(await page.locator("[data-find-count]:visible").innerText())), await page.locator("[data-find-count]:visible").innerText())
  await page.screenshot({ path: `${OUT}phone-light-find.png` })
  await ctx.close()
}

await api("PATCH", "config/plugin/activity", { recaps: recaps ?? null }, app)
rmSync(`${VAULT}/${DIR}`, { recursive: true, force: true })
await done()
