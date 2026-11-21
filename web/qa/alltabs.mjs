// The Workspaces page (each one's tabs, name and menu; the switcher dragged onto a pane), tab search, and Workspaces turned on and off, losing no tab.
//   node web/qa/alltabs.mjs <base url> <vault path> [out dir]
import { execFileSync } from "node:child_process"
import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import path from "node:path"
import { apiAt, qa, until, workspaceKey } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
import { clearWorkspaces, workspaces } from "./lib/wsfiles.mjs"
// Paths: plugins/core/workspaces/AllTabs.tsx, plugins/core/workspaces/Name.tsx, plugins/core/workspaces/Numbers.tsx, plugins/core/workspaces/state.ts, web/src/components/TabSearch.tsx, web/src/core/scope.ts
const { args: [B, VAULT, OUT = "/tmp/alltabs-shots/"], browser, check, watch, noErrors, done } = await qa(import.meta.url)
mkdirSync(OUT, { recursive: true })

const api = apiAt(B)
const vau = (...a) => execFileSync(process.execPath, [path.resolve(import.meta.dirname, "../../bin/vau"), "--url", B, ...a],
  { encoding: "utf8", env: { ...process.env, VAULTITE_URL: B, VAULTITE_VAULT: VAULT } })
const pluginsFile = path.join(VAULT, ".vaultite/plugins.json")
const pluginsBefore = (() => { try { return readFileSync(pluginsFile, "utf8") } catch { return null } })()

const DIR = "Qa all"
const F = (name) => `file:${DIR}/${name}.md`
const T = (id, name) => ({ id, root: { id: `p${id}`, to: F(name) }, focus: `p${id}` })
const placesOf = (n) => (n?.kids ? n.kids.flatMap(placesOf) : n?.to ? [n.to] : [])
const tosOf = (l) => (l?.tabs ?? []).flatMap((t) => placesOf(t.root))

const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } })
// A device of its own, as a person's browser is (webdriver hides it, devicetabs.mjs): the "From <device>" group's name.
await ctx.addInitScript(() => Object.defineProperty(Navigator.prototype, "webdriver", { get: () => false }))
const page = watch(await ctx.newPage(), { console: true, ignore: /favicon|Failed to load resource|WebSocket/ }), ui = app(page)
const SWITCHER = "aside [data-workspace-switcher]"
const lit = () => page.$eval(SWITCHER, (e) => e.getAttribute("data-workspace-switcher")).catch(() => null)
const mine = () => page.evaluate(() => JSON.parse(localStorage.getItem("vaultite.tabs") ?? "null"))
const strip = () => page.$$eval("[data-tab-strip] [role=tab]", (els) => els.map((t) => t.innerText.trim()))
const active = () => page.$eval("[data-tab-strip] [role=tab][aria-selected=true]", (e) => e.innerText.trim()).catch(() => null)
const card = (n) => page.locator(`[data-all-tabs-workspace='${n}']`)
const rows = (n) => card(n).locator("[data-all-tabs-tab]").allInnerTexts().then((t) => t.map((x) => x.trim()))

try {
  vau("plugin", "off", "workspaces")
  clearWorkspaces(B)
  const names = ["Reading list", "Trip ideas", "Standup", "Budget 2027", "Sprint review", "Release notes", "Roadmap", "Retro"]
  for (const n of names) await api("POST", "file", { path: `${DIR}/${n}.md`, text: `# ${n}\n\n${n} text.\n` })
  await api("PUT", "workspaces/1", { name: "Personal", layout: { active: "a1", tabs: [T("a1", "Reading list"), T("a2", "Trip ideas")] } })
  const split = { id: "b3", root: { id: "sb3", dir: "row", sizes: [1, 1], kids: [{ id: "pb3a", to: F("Roadmap") }, { id: "pb3b", to: F("Retro") }] }, focus: "pb3a" }
  await api("PUT", "workspaces/2", { name: "Work", layout: { active: "b1", groups: [{ id: "g1", name: "Lighthouse", color: "blue" }],
    tabs: [{ ...T("b1", "Budget 2027"), group: "g1" }, { ...T("b2", "Sprint review"), group: "g1" }, split] } })
  await api("PUT", "workspaces/3", { name: "Vaultite", layout: { active: "c1", tabs: [T("c1", "Release notes")] } })

  const seedOffTheApp = async (l) => { await page.goto(`${B}api/workspaces`); await page.evaluate((l) => { localStorage.clear(); localStorage.setItem("vaultite.tabs", JSON.stringify(l)) }, l) }
  await seedOffTheApp({ active: "d1", tabs: [T("d1", "Standup"), T("d2", "Reading list")] })
  await page.goto(B); await page.waitForSelector("[data-tab-strip]"); await ui.saved()
  const own = tosOf(await mine())
  check("off: this device's own tabs", own.join() === [F("Standup"), F("Reading list")].join(), own)

  await ui.sees(".vaultite/plugins.json", () => vau("plugin", "on", "workspaces"))
  await page.waitForSelector(SWITCHER)
  const toast = await ui.toast.wait(/from this device/).catch(() => null)
  const said = toast ? (await toast.innerText()).trim() : ""
  check("on: a toast says where this device's tab went, and its group", /^1 tab from this device is in Personal, in the group "From .+"/.test(said) && /Show workspaces/.test(said), [said, await ui.toast()])
  await until(async () => tosOf(await mine()).includes(F("Standup")), 8000); await ui.saved()
  const took = await mine()
  check("on: Personal's tabs first, then Standup (Reading list isn't added twice)", tosOf(took).join() === [F("Reading list"), F("Trip ideas"), F("Standup")].join(), tosOf(took))
  const group = took.groups?.find((g) => g.id === took.tabs.find((t) => placesOf(t.root).includes(F("Standup")))?.group)
  check("on: Standup in a group named after this device", /^From .+/.test(group?.name ?? ""), took.groups)
  check("on: nothing of this device's out of sight", own.every((to) => tosOf(took).includes(to)), [own, tosOf(took)])
  check("on: the group shows in the tab bar", !!(await until(() => page.locator("[data-tab-strip]", { hasText: group?.name ?? "From " }).count(), 4000)), await strip())
  check("on: Personal saved them", !!(await until(() => tosOf(workspaces(B)[0]?.layout).join() === tosOf(took).join(), 6000)), tosOf(workspaces(B)[0]?.layout))
  check("on: Work and Vaultite untouched", tosOf(workspaces(B)[1]?.layout).join() === [F("Budget 2027"), F("Sprint review"), F("Roadmap"), F("Retro")].join() && tosOf(workspaces(B)[2]?.layout).join() === F("Release notes"),
    workspaces(B).map((w) => tosOf(w?.layout)))
  await page.screenshot({ path: `${OUT}on-toast.png` })

  await page.keyboard.press(workspaceKey(0)); await ui.idle()
  await page.waitForSelector("[data-all-tabs]")
  const cards = await page.$$eval("[data-all-tabs-workspace]", (els) => els.map((e) => e.getAttribute("data-all-tabs-workspace")))
  check("All tabs: a card for each workspace in use", cards.join() === "1,2,3", cards)
  check("All tabs: each with its tabs", (await rows(2)).join() === "Budget 2027,Sprint review,Roadmap\nRetro" && (await rows(3)).join() === "Release notes" && (await rows(1)).includes("Standup"),
    [await rows(1), await rows(2), await rows(3)])
  const grouped = card(2).locator("[data-all-tabs-group='g1']")
  check("All tabs: a tab group heads its tabs, as the tabs panel draws them", (await grouped.locator("[data-group-row]").getAttribute("aria-expanded")) === "true"
    && (await grouped.locator("[data-group-name] > span").first().innerText()).trim() === "Lighthouse"
    && (await grouped.locator("[data-all-tabs-tab]").allInnerTexts()).join() === "Budget 2027,Sprint review", await card(2).innerText())
  const halves = await card(2).locator("[data-all-tabs-split] [data-all-tabs-pane]").allInnerTexts()
  check("All tabs: a split tab is one row with its panes side by side, outside the group", halves.join() === "Roadmap,Retro" && !(await grouped.locator("[data-all-tabs-split]").count()), halves)
  const headerBoxes = () => Promise.all(["[data-all-tabs-new]", "[data-all-tabs] header input[type=search]"].map((s) => page.locator(s).boundingBox().then((b) => JSON.stringify(b))))
  const unfiltered = await headerBoxes()
  await page.locator("[data-all-tabs] input").fill("lighthouse"); await ui.idle()
  check("All tabs: filtering by a group's name keeps its tabs", (await rows(2)).join() === "Budget 2027,Sprint review" && !(await card(3).count()), await rows(2))
  check("...the header holds still while filtering", JSON.stringify(await headerBoxes()) === JSON.stringify(unfiltered), [await headerBoxes(), unfiltered])
  await page.locator("[data-all-tabs] input").fill(""); await ui.idle()
  check("All tabs: the workspaces' names", (await card(2).innerText()).includes("Work") && (await card(3).innerText()).includes("Vaultite"), await card(2).innerText())
  await page.screenshot({ path: `${OUT}all-tabs.png` })
  const joins = await card(2).evaluate((c) => {
    const pill = c.querySelector("[data-all-tabs-group='g1'] [data-group-name]").getBoundingClientRect(), rail = c.querySelector("[data-group-line='g1']")?.getBoundingClientRect()
    const last = [...c.querySelectorAll("[data-all-tabs-group='g1'] [data-all-tabs-tab]")].at(-1).getBoundingClientRect()
    return rail && { pill: [pill.top, pill.bottom, pill.left, pill.right], rail: [rail.top, rail.bottom, rail.left], last: [last.top, last.bottom, last.left] }
  })
  check("All tabs: the group's line comes out of its pill and ends by its last tab, the tabs set in past it",
    !!joins && joins.rail[0] > joins.pill[0] && joins.rail[0] < joins.pill[1] && joins.rail[2] >= joins.pill[2] + 2 && joins.rail[2] < joins.pill[3]
    && joins.rail[1] > joins.last[0] && joins.rail[1] < joins.last[1] && joins.last[2] > joins.rail[2], joins)
  const workLayout = () => workspaces(B)[1]?.layout
  await grouped.locator("[data-group-row]").click(); await ui.idle()
  const inPill = grouped.locator("[data-group-count]")
  check("All tabs: another workspace's group folds on a click, its tabs hidden and its count in its pill",
    !!(await until(async () => !(await grouped.locator("[data-all-tabs-tab]").count()) && (await grouped.locator("[data-group-row]").getAttribute("aria-expanded")) === "false", 4000))
    && (await inPill.getAttribute("aria-hidden")) === null && (await inPill.innerText()).trim() === "2", await card(2).innerText())
  check("  folded in that workspace too", !!(await until(() => workLayout()?.groups?.[0]?.collapsed === true, 6000)), workLayout()?.groups)
  await page.screenshot({ path: `${OUT}all-tabs-folded.png` })
  await grouped.locator("[data-group-row]").click(); await ui.idle()
  check("  and opens again", !!(await until(async () => (await grouped.locator("[data-all-tabs-tab]").count()) === 2 && !workLayout()?.groups?.[0]?.collapsed, 6000)), workLayout()?.groups)
  const ownGroup = card(1).locator("[data-all-tabs-group] [data-group-row]").first()
  await ownGroup.click(); await ui.idle()
  check("All tabs: this workspace's group folds in its tab bar too", !!(await until(async () => (await mine())?.groups?.some((g) => g.collapsed)
    && (await page.locator("[data-group-chip][aria-expanded=false]").count()) === 1, 4000)), (await mine())?.groups)
  await page.locator("[data-group-chip][aria-expanded=false]").click(); await ui.idle()
  check("  and opens there again", !!(await until(async () => !(await mine())?.groups?.some((g) => g.collapsed), 4000)), (await mine())?.groups)
  await page.keyboard.press(workspaceKey(0)); await page.waitForSelector("[data-all-tabs]"); await ui.idle()
  const notes = card(3).locator("[data-all-tabs-tab]", { hasText: "Release notes" })
  await notes.hover(); await notes.getByRole("button", { name: "Close Release notes" }).click()
  check("All tabs: another workspace's tab closes from its row", !!(await until(async () => !(await rows(3)).includes("Release notes") && !tosOf(workspaces(B)[2]?.layout).includes(F("Release notes")), 6000)),
    [await rows(3), tosOf(workspaces(B)[2]?.layout)])
  const closed = await ui.toast.wait(/Closed in Vaultite/)
  await closed.getByRole("button", { name: "Undo" }).click()
  check("  Undo brings it back there", !!(await until(async () => (await rows(3)).includes("Release notes") && tosOf(workspaces(B)[2]?.layout).includes(F("Release notes")), 6000)),
    [await rows(3), tosOf(workspaces(B)[2]?.layout)])
  await card(2).locator("[data-all-tabs-pane]", { hasText: "Retro" }).click(); await ui.idle()
  const focusedPane = () => page.$eval("#main-scroll", (e) => e.getAttribute("data-tab-body")).catch(() => null)
  check("All tabs: a split's pane goes to its workspace, its tab and that pane", !!(await until(async () => (await lit()) === "2" && (await focusedPane()) === "pb3b", 6000)), [await lit(), await focusedPane()])
  await page.keyboard.press(workspaceKey(0)); await page.waitForSelector("[data-all-tabs]"); await ui.idle()
  await card(2).locator("[data-all-tabs-tab]", { hasText: "Sprint review" }).click(); await ui.idle()
  check("All tabs: a click goes to its workspace and shows the tab", !!(await until(async () => (await lit()) === "2" && (await active()) === "Sprint review", 6000)), [await lit(), await active()])

  await page.click(SWITCHER); await page.waitForSelector("[data-workspace-list]")
  await page.waitForSelector("[data-workspace-list] [data-workspace-all]")
  const first = await page.$eval("[data-workspace-list] button", (e) => (e.hasAttribute("data-workspace-all") ? e.innerText.trim() : null))
  check("switcher: Workspaces is its first row", !!first?.startsWith("Workspaces"), first)
  await page.click("[data-workspace-list] [data-workspace-all]"); await page.waitForSelector("[data-all-tabs]"); await ui.idle()
  check("switcher's Workspaces: the page, the list closed", (await page.locator("[data-all-tabs]").count()) === 1 && !(await page.locator("[data-workspace-list]").count()))
  check("its tab is named Workspaces", /(^|\n)Workspaces$/.test((await active()) ?? ""), await active())

  const nameOf = (n) => card(n).locator("[data-all-tabs-name]").innerText().then((t) => t.trim(), () => null)
  const field = (n) => card(n).locator(`input[aria-label='Name of workspace ${n}']`)
  const headerBefore = await headerBoxes()
  await card(3).locator("[data-all-tabs-name]").click()
  check("a click on a workspace's name: a field with it, selected", (await field(3).inputValue()) === "Vaultite" && (await field(3).evaluate((e) => e.selectionEnd - e.selectionStart)) === 8)
  check("...the header holds still: New workspace and the filter where they were", JSON.stringify(await headerBoxes()) === JSON.stringify(headerBefore), [await headerBoxes(), headerBefore])
  await page.keyboard.type("Vaultite app"); await page.keyboard.press("Enter"); await ui.idle()
  check("Enter: renamed on the page and saved", !!(await until(async () => (await nameOf(3)) === "Vaultite app" && workspaces(B)[2]?.name === "Vaultite app", 6000)), [await nameOf(3), workspaces(B)[2]?.name])
  await card(3).locator("[data-all-tabs-name]").click(); await page.keyboard.type("Nope"); await page.keyboard.press("Escape"); await ui.idle()
  check("Escape: the name as it was", !(await field(3).count()) && (await nameOf(3)) === "Vaultite app" && workspaces(B)[2]?.name === "Vaultite app", [await nameOf(3)])
  await ui.menu.context(card(3).locator("[data-all-tabs-head]"))
  const heads = await ui.menu.items()
  check("a workspace's right-click: switch to it, then the switcher's menu", !!heads[0]?.endsWith("Switch to Vaultite app") && ["Rename", "Change icon", "Colour", "Delete"].every((x) => heads.includes(x)) && heads.some((x) => x.startsWith("Duplicate")), heads)
  await ui.menu.pick("Colour", "Green")
  check("Colour: the card takes it, saved", !!(await until(async () => workspaces(B)[2]?.tint === "green" && !!(await card(3).getAttribute("style"))?.includes("green"), 6000)), [workspaces(B)[2]?.tint, await card(3).getAttribute("style")])
  await ui.menu.open(card(3).locator("[data-all-tabs-more]"))
  const more = await ui.menu.items()
  check("its More button: the same menu", JSON.stringify(more) === JSON.stringify(heads), [more, heads])
  await ui.menu.pick("Rename")
  check("the menu's Rename: the field on the page, the switcher shut", (await field(3).count()) === 1 && !(await page.locator("[data-workspace-list]").count()))
  await page.keyboard.press("Escape"); await ui.idle()
  await ui.menu.context(card(2).locator("[data-all-tabs-head]"))
  const ownItems = await ui.menu.items()
  check("this workspace's menu: no switch to it, its Settings", ownItems[0] === "Rename" && ownItems.includes("Settings…"), ownItems)
  await ui.menu.close()

  check("New workspace: at the end, the first free number", (await page.locator("[data-all-tabs-new]").getAttribute("data-all-tabs-new")) === "4")
  await page.locator("[data-all-tabs-new]").click()
  check("...a click: a card for it, its name to type", (await field(4).count()) === 1 && (await page.locator("[data-all-tabs-new]").isDisabled()))
  await page.keyboard.press("Escape"); await ui.idle()
  check("...Escape: no workspace made", !(await card(4).count()) && !workspaces(B)[3] && (await page.locator("[data-all-tabs-new]").isEnabled()))
  await page.locator("[data-all-tabs-new]").click(); await page.keyboard.type("Ideas"); await page.keyboard.press("Enter"); await ui.idle()
  check("...named: workspace 4, saved, still on this one", !!(await until(async () => (await nameOf(4)) === "Ideas" && workspaces(B)[3]?.name === "Ideas", 6000)) && (await lit()) === "2", [await nameOf(4), workspaces(B)[3]])
  await page.screenshot({ path: `${OUT}workspaces-page.png` })
  await ui.menu.context(card(4).locator("[data-all-tabs-head]")); await ui.menu.pick("Delete")
  check("Delete from the page: its card goes, with Undo", !!(await until(async () => !(await card(4).count()) && !workspaces(B)[3], 6000)) && !!(await ui.toast.wait(/Deleted Ideas/).catch(() => null)))
  await ui.menu.context(card(3).locator("[data-all-tabs-tab]", { hasText: "Release notes" }))
  const items = await ui.menu.items()
  check("All tabs: a row's menu moves it to each other workspace, or closes it", items.join() === "Move to Personal,Move to Work,Close tab", items)
  await ui.menu.pick("Move to Personal")
  check("Move to Personal: in Personal's card, out of Vaultite's", !!(await until(async () => (await rows(1)).includes("Release notes") && !(await rows(3)).includes("Release notes"), 6000)), [await rows(1), await rows(3)])
  check("Move to Personal: saved there", !!(await until(() => tosOf(workspaces(B)[0]?.layout).includes(F("Release notes")) && !tosOf(workspaces(B)[2]?.layout).includes(F("Release notes")), 6000)),
    workspaces(B).map((w) => tosOf(w?.layout)))
  check("Move: this workspace stays on screen", (await lit()) === "2", await lit())

  const row = (n, name) => card(n).locator("[data-all-tabs-tab]", { hasText: name }).first()
  const drag = async (from, to, at) => {
    const a = await from.boundingBox(), b = await to.boundingBox()
    await page.mouse.move(a.x + 40, a.y + a.height / 2); await page.mouse.down()
    await page.mouse.move(a.x + 48, a.y + a.height / 2 + 4, { steps: 3 })
    await page.mouse.move(b.x + 40, b.y + b.height * at, { steps: 12 }); await ui.idle()
    await page.mouse.up(); await ui.idle()
  }
  const savedIn = (i) => tosOf(workspaces(B)[i]?.layout).map((to) => to.replace(`file:${DIR}/`, "").replace(".md", ""))
  await drag(row(2, "Sprint review"), row(2, "Budget 2027"), 0.2)
  check("drag in this workspace: Sprint review above Budget 2027, still in its group", !!(await until(async () => (await rows(2)).slice(0, 2).join() === "Sprint review,Budget 2027", 4000))
    && (await card(2).locator("[data-all-tabs-group='g1'] [data-all-tabs-tab]").allInnerTexts()).join() === "Sprint review,Budget 2027", await rows(2))
  await ui.saved()
  check("drag in this workspace: saved in that order", !!(await until(() => savedIn(1).slice(0, 2).join() === "Sprint review,Budget 2027", 6000)), savedIn(1))
  await drag(row(1, "Trip ideas"), row(1, "Reading list"), 0.2)
  check("drag in another workspace: Trip ideas above Reading list, there and saved", !!(await until(async () => (await rows(1))[0] === "Trip ideas" && savedIn(0)[0] === "Trip ideas", 6000)), [await rows(1), savedIn(0)])
  check("drag in another workspace: this one stays on screen", (await lit()) === "2", await lit())
  await drag(row(1, "Reading list"), row(2, "Budget 2027"), 0.8)
  check("drag across: Reading list goes from Personal to Work, after Budget 2027", !!(await until(async () => savedIn(1).join().includes("Budget 2027,Reading list") && !savedIn(0).includes("Reading list"), 6000))
    && (await rows(2)).includes("Reading list") && !(await rows(1)).includes("Reading list"), [savedIn(0), savedIn(1), await rows(2)])
  await drag(row(2, "Reading list"), card(3), 0.7)
  check("drag across: from this workspace into an empty one", !!(await until(async () => (await rows(3))[0] === "Reading list" && !savedIn(1).includes("Reading list") && savedIn(2)[0] === "Reading list", 6000)), [await rows(3), savedIn(1), savedIn(2)])
  await page.screenshot({ path: `${OUT}all-tabs-dragged.png` })

  await page.keyboard.press("ControlOrMeta+Shift+a"); await page.waitForSelector("[role=dialog] input:focus")
  await page.keyboard.type("Trip ideas"); await ui.idle()
  const other = page.getByRole("group", { name: "In other workspaces" })
  const hit = other.locator("[role=option]", { hasText: "Trip ideas" })
  check("tab search: Personal's tab under In other workspaces, named by its workspace", (await hit.count()) === 1 && (await hit.innerText()).includes("Personal"), await page.locator("[role=dialog]").innerText().catch(() => ""))
  await page.screenshot({ path: `${OUT}tab-search.png` })
  await hit.click(); await ui.idle()
  check("tab search: picking it goes to Personal and shows the tab", !!(await until(async () => (await lit()) === "1" && (await active()) === "Trip ideas", 6000)), [await lit(), await active()])
  await page.keyboard.press("ControlOrMeta+Shift+a"); await page.waitForSelector("[role=dialog] input:focus"); await ui.idle()
  check("tab search, no query: no other workspace's tab without a mark", !(await other.count()), await page.locator("[role=dialog]").innerText())
  await page.keyboard.press("Escape"); await ui.idle()

  const pagesOpen = () => page.locator("[data-all-tabs]:visible").count()
  check("Personal shows no Workspaces page before the drag", !(await pagesOpen()))
  const sw = await page.locator(SWITCHER).boundingBox(), body = await page.locator("[data-pane-body]:visible").first().boundingBox()
  await page.mouse.move(sw.x + sw.width / 2, sw.y + sw.height / 2); await page.mouse.down()
  await page.mouse.move(sw.x + sw.width / 2 + 20, sw.y + 30, { steps: 4 }); await page.mouse.move(body.x + body.width - 30, body.y + body.height / 2, { steps: 12 })
  check("the switcher dragged to a pane's edge: Workspaces follows the pointer, the half it would take shown", !!(await until(async () => /Workspaces/.test(await page.locator("[data-drag-ghost]").innerText().catch(() => "")) && (await page.locator("[data-drag-shape=page]").count()) === 1, 3000)))
  await page.screenshot({ path: `${OUT}switcher-drag.png` }); await page.mouse.up(); await ui.idle()
  check("...dropped: the Workspaces page beside the tab, no list open", !!(await until(async () => (await pagesOpen()) === 1 && (await page.locator("[data-pane-body]:visible").count()) === 2, 6000)) && !(await page.locator("[data-workspace-list]").count()),
    await page.locator("[data-pane-body]:visible").count())
  const besides = await until(async () => (await rows(1)).find((r) => /Trip ideas/.test(r) && /Workspaces/.test(r)), 4000)
  check("...and the page still lists the split tab it's in, its other pane beside it", !!besides, await rows(1))
  await page.click(SWITCHER)
  check("...and a click on it still opens the list", !!(await until(() => page.locator("[data-workspace-list]").count(), 3000)))
  await page.keyboard.press("Escape"); await ui.idle()

  const pctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true })
  const P = watch(await pctx.newPage(), { console: true, ignore: /favicon|Failed to load resource|WebSocket/ }), pUi = app(P)
  await ui.saved()
  const saved = JSON.stringify(workspaces(B).map((w) => w && { ...w, state: undefined }))
  await P.goto(`${B}#file/${encodeURIComponent(`${DIR}/Budget 2027.md`)}`)
  await P.waitForSelector("[data-tabs-button]"); await pUi.saved()
  await P.click("[data-tabs-button]"); await P.waitForSelector("[data-tab-row]"); await pUi.idle()
  const title = await P.locator("[data-tabs-title]").innerText()
  check("phone: on Personal, the file it opened in its tabs", title === "Personal" && !!(await until(() => tosOf(workspaces(B)[0]?.layout).includes(F("Budget 2027")), 6000)), [title, tosOf(workspaces(B)[0]?.layout)])
  const others = (l) => JSON.stringify(l.slice(1).map((w) => w && { ...w, state: undefined }))
  check("phone: the other workspaces as they were", others(workspaces(B)) === others(JSON.parse(saved)))
  await pctx.close()

  await ui.saved()
  const before = await strip()
  await ui.sees(".vaultite/plugins.json", () => vau("plugin", "off", "workspaces"))
  check("off: no switcher", !!(await until(async () => !(await page.$(SWITCHER)), 6000)))
  await ui.saved()
  check("off: Personal's tabs stay on screen", JSON.stringify(await strip()) === JSON.stringify(before), [await strip(), before])
  check("off: this device's again, not held", (await page.evaluate(() => localStorage.getItem("vaultite.tabs.held"))) === null && tosOf(await mine()).includes(F("Release notes")), tosOf(await mine()))
  await page.goto("about:blank"); await page.goto(B); await page.waitForSelector("[data-tab-strip]"); await ui.idle()
  check("off, reloaded: still those tabs", JSON.stringify(await strip()) === JSON.stringify(before), [await strip(), before])
  noErrors()
} catch (e) {
  check(String(e), false)
} finally {
  await browser.close()
  await api("DELETE", `file?path=${encodeURIComponent(DIR)}`).catch(() => {})
  clearWorkspaces(B)
  if (pluginsBefore === null) rmSync(pluginsFile, { force: true }); else writeFileSync(pluginsFile, pluginsBefore)
}
await done()
