// Switching layouts (Standard, Browser: Workspaces off and on) loses no tab, adds none twice. WRITES settings: throwaway only.
//   node web/qa/layoutswitch.mjs <base url>
import { spawnSync } from "node:child_process"
import path from "node:path"
import { ROOT, apiAt, command, qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
// Paths: web/src/core/workspace.ts, plugins/core/workspaces/state.ts, plugins/core/workspaces/plugin.ts

const { args: [B], browser, check, watch, done } = await qa(import.meta.url)
const api = apiAt(B)

function apply(id) {
  const r = spawnSync(process.execPath, [path.join(ROOT, "bin/vau"), "bundle", "apply", id, "--code"], { encoding: "utf8", env: { ...process.env, VAULTITE_URL: B.replace(/\/$/, "") } })
  if (r.status !== 0) throw new Error(r.stderr || r.stdout)
}

const OLD = Date.now() - 3 * 86_400_000
const p = (id, to, extra = {}) => ({ id, to, seen: OLD, ...extra })
/** Tabs worth losing: two groups (one folded), a split of a split with its own sizes, a name, a pin, focus off the first. */
const MINE = {
  active: "t2",
  groups: [{ id: "g1", name: "Trip", color: "teal" }, { id: "g2", name: "Later", color: "red", collapsed: true }],
  tabs: [
    { id: "t1", group: "g1", root: p("p1", "file:Start here.md"), focus: "p1", pinned: true },
    { id: "t2", group: "g1", focus: "p3", root: { id: "s1", dir: "row", sizes: [0.3, 0.7], kids: [p("p2", "file:Notes/Lisbon trip.md"),
      { id: "s2", dir: "col", sizes: [0.65, 0.35], kids: [p("p3", "file:Notes/How this vault works.md"), p("p4", "view:files")] }] } },
    { id: "t3", group: "g2", root: p("p5", "view:folder/Notes"), focus: "p5", name: "Desk" },
    { id: "t4", root: p("p6", "view:search/lisbon"), focus: "p6" },
  ],
}
const THEIRS = { active: "w2", tabs: [{ id: "w1", root: { id: "q1", to: "file:Start here.md" }, focus: "q1" }, { id: "w2", root: { id: "q2", to: "view:files" }, focus: "q2" }] }

/** What a layout is made of, without what's only for this visit or the archive's stamps. */
const shapeOf = (l) => l && JSON.stringify(l, (k, v) => (["seen", "back", "fwd", "from", "home", "windows"].includes(k) ? undefined
  : v && typeof v === "object" && !Array.isArray(v) ? Object.fromEntries(Object.entries(v).sort(([a], [b]) => a.localeCompare(b))) : v))
const placesOf = (n) => (n?.kids ? n.kids.flatMap(placesOf) : n?.to ? [n.to] : [])
const tabsOf = (l) => (l?.tabs ?? []).map((t) => `${placesOf(t.root).join("+")}${t.group ? `@${l.groups?.find((g) => g.id === t.group)?.name ?? "?"}` : ""}`)
const allPlaces = (l) => (l?.tabs ?? []).flatMap((t) => placesOf(t.root))
const shown = (page) => page.evaluate(() => ({ held: localStorage.getItem("vaultite.tabs.held") === "1", tabs: JSON.parse(localStorage.getItem("vaultite.tabs") ?? "null") }))
const numbers = (page) => page.locator("[data-workspace-switcher], [data-workspace]").count()
const ws1 = async () => (await api("GET", "workspaces")).workspaces?.[0]?.layout ?? null

const ctx = await browser.newContext({ viewport: { width: 1280, height: 820 } })
// A device of its own, as a person's browser is (webdriver hides it, devicetabs.mjs): the "From <device>" group's name.
await ctx.addInitScript(() => Object.defineProperty(Navigator.prototype, "webdriver", { get: () => false }))
const page = watch(await ctx.newPage(), { label: "layoutswitch" }), ui = app(page)
const fresh = async () => { await page.goto("about:blank"); await page.goto(B); await until(() => page.locator("[data-status-bar]").count(), 10_000); await ui.saved() }
const holds = async (on) => { await until(async () => (await shown(page)).held === on, 10_000); await ui.saved() }

try {
  apply("standard")
  await api("DELETE", "workspaces/1")
  // (seeded from a page of the server's that isn't the app, so the app doesn't write its own first tab over them)
  await page.goto(`${B}api/workspaces`)
  await page.evaluate((l) => { localStorage.removeItem("vaultite.tabs.held"); localStorage.setItem("vaultite.tabs", JSON.stringify(l)) }, MINE)
  await fresh()
  const before = await shown(page)
  check("seeded: my tabs on screen, Workspaces not holding them", !before.held && shapeOf(before.tabs) === shapeOf(MINE), before)

  apply("browser")
  await holds(true)
  const inBrowser = await shown(page)
  check("Browser: the tabs on screen stay, now the unused workspace's", shapeOf(inBrowser.tabs) === shapeOf(MINE), inBrowser.tabs)
  await until(async () => shapeOf(await ws1()) === shapeOf(MINE), 8000)
  check("Browser: workspace 1 took them, groups and splits too", shapeOf(await ws1()) === shapeOf(MINE), await ws1())
  check("Browser: no toast for an unused workspace", !(await ui.toast()).some((t) => /from this device/.test(t)), await ui.toast())

  apply("standard")
  await holds(false)
  check("back to Standard: the same tabs, groups, splits, sizes and focus", shapeOf((await shown(page)).tabs) === shapeOf(MINE), (await shown(page)).tabs)
  await fresh()
  check("and after a reload", shapeOf((await shown(page)).tabs) === shapeOf(MINE))

  await api("PUT", "workspaces/1", { layout: THEIRS })
  apply("browser")
  await holds(true)
  const merged = ["file:Start here.md", "view:files", "file:Notes/Lisbon trip.md+file:Notes/How this vault works.md+view:files@Trip", "view:folder/Notes@Later"]
  const isMerged = (l) => { const t = tabsOf(l); return t.length === 5 && t.slice(0, 4).join() === merged.join() && t[4].startsWith("view:search/lisbon@From ") }
  await until(async () => isMerged((await shown(page)).tabs), 10_000)
  const took = (await shown(page)).tabs
  check("Browser over a workspace with tabs: its own first, then mine not open there yet, the loose one in a \"From ...\" group", isMerged(took), tabsOf(took))
  check("...nothing of mine out of sight", allPlaces(MINE).every((to) => allPlaces(took).includes(to)), [allPlaces(MINE), allPlaces(took)])
  check("...splits and sizes kept", JSON.stringify(took.tabs.find((t) => t.id === "t2")?.root?.sizes) === "[0.3,0.7]", took.tabs.find((t) => t.id === "t2"))
  const toast = await ui.toast.wait(/from this device (is|are) in workspace 1/i).catch(() => null)
  const toastText = toast ? await toast.innerText() : ""
  check("Browser: a toast says where they went, naming the group, with Show workspaces", /3 tabs from this device are in workspace 1, in the group "From .+"/i.test(toastText) && /Show workspaces/.test(toastText), [toastText, await ui.toast()])
  await until(async () => isMerged(await ws1()), 8000)
  check("Browser: workspace 1 saved the merge", isMerged(await ws1()), tabsOf(await ws1()))
  if (toast) {
    const allTabsCount = () => page.locator("[data-all-tabs-workspace='1'][aria-current] [data-all-tabs-count]").innerText().then((t) => t.trim(), () => "")
    await toast.getByRole("button", { name: "Show workspaces" }).click(); await ui.idle()
    check("the toast's Show workspaces: the Workspaces page, workspace 1 with its 5 tabs, the split it opened in still one", !!(await until(async () => (await allTabsCount()) === "5", 6000)),
      await allTabsCount())
    // (opened in the focused pane, the split's, as a tab of its own: closed, the pane shows its note again)
    await command(page, "Close current tab", 0); await ui.saved()
    check("...closed again, the workspace's 5 tabs", !!(await until(async () => isMerged((await shown(page)).tabs), 6000)), tabsOf((await shown(page)).tabs))
  }
  const kept = tabsOf((await shown(page)).tabs)
  await fresh()
  check("Browser, reloaded: still the workspace's", tabsOf((await shown(page)).tabs).join() === kept.join(), tabsOf((await shown(page)).tabs))

  apply("standard")
  await holds(false)
  check("Standard again: the workspace's tabs stay on screen", tabsOf((await shown(page)).tabs).join() === kept.join(), tabsOf((await shown(page)).tabs))
  apply("browser")
  await holds(true)
  check("Browser again: nothing added twice", tabsOf((await shown(page)).tabs).join() === kept.join() && tabsOf(await ws1()).join() === kept.join(), [tabsOf((await shown(page)).tabs), tabsOf(await ws1())])
  check("Browser again: no toast, nothing moved", !(await ui.toast()).some((t) => /from this device/.test(t)), await ui.toast())

  // ---- off while the app was closed: it opens on what it last showed ----
  await page.goto("about:blank")
  apply("standard")
  await fresh()
  await holds(false)
  check("turned off while closed: the tabs it last showed", tabsOf((await shown(page)).tabs).join() === kept.join(), tabsOf((await shown(page)).tabs))

  // ---- from the picker, as the user does it: a click on Browser, then on Standard ----
  await api("DELETE", "workspaces/1")
  await page.goto("about:blank"); await page.goto(`${B}#settings`)
  /** Layout tile `id`, clicked (a narrow pane lists Settings' sections: Appearance opens first). */
  const pick = async (id) => {
    await until(() => page.locator("[data-layout-pick], [data-settings-list]").count(), 8000)
    if (!(await page.locator(`[data-layout-pick=${id}]`).count())) await page.locator("[data-settings-nav=appearance]").first().click()
    await until(() => page.locator(`[data-layout-pick=${id}]`).count(), 8000)
    await page.locator(`[data-layout-pick=${id}]`).first().click()
  }
  await ui.saved()
  await until(() => page.locator("[data-layout-pick], [data-settings-list]").count(), 8000)
  if (!(await page.locator("[data-layout-pick]").count())) { await page.locator("[data-settings-nav=appearance]").first().click(); await ui.idle() }
  const set = (await shown(page)).tabs
  await pick("browser")
  await holds(true)
  check("picker, Browser: the same tabs on screen", tabsOf((await shown(page)).tabs).join() === tabsOf(set).join(), [tabsOf((await shown(page)).tabs), tabsOf(set)])
  check("picker, Browser: Workspaces is on", (await numbers(page)) > 0 || (await ws1()) != null)
  await pick("standard")
  await holds(false)
  check("picker, back to Standard: the same tabs again", tabsOf((await shown(page)).tabs).join() === tabsOf(set).join(), [tabsOf((await shown(page)).tabs), tabsOf(set)])
} finally {
  apply("standard")
}
await done()
