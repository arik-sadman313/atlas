// A turned phone keeps its layout, place and video (full screen too), clear of the notch: core/platform.ts, core/anchor.ts, index.css, App.tsx, components/PhoneDrawer.tsx, components/PhoneHeader.tsx, components/DetailSheet.tsx, components/FileView.tsx, components/TabSwitcher.tsx. Needs ffmpeg: node web/qa/rotate.mjs <base url> <vault path> [out dir]
import { execFileSync } from "node:child_process"
import fs from "node:fs"
import { SHOTS, qa, until } from "./lib/qa.mjs"
import { app } from "./lib/app.mjs"
const { args: [B, VAULT, OUT = SHOTS], browser, check, watch, done } = await qa(import.meta.url, { chrome: { args: ["--autoplay-policy=no-user-gesture-required"] } })
const NOTE = "Qa rotate/Clip.md"
const put = async (path, text) => {
  const r = await fetch(`${B}api/file`, { method: "PUT", headers: { "Content-Type": "application/json", "X-Vaultite-Client": "app/qa" }, body: JSON.stringify({ path, text }) })
  if (!r.ok) throw new Error(`couldn't write ${path}: ${r.status} ${await r.text()}`)
}

fs.mkdirSync(`${VAULT}/Qa rotate`, { recursive: true })
execFileSync("ffmpeg", ["-loglevel", "error", "-y", "-f", "lavfi", "-i", "testsrc=d=120:s=320x180:r=15", "-c:v", "libvpx-vp9", "-b:v", "60k", `${VAULT}/Qa rotate/Qa clip.webm`])
const para = (n) => `Paragraph ${n}. ${"A line long enough to wrap differently on a phone held upright and turned sideways, so its height changes. ".repeat(3)}`
await put(NOTE, `![[Qa clip.webm]]\n\n${Array.from({ length: 40 }, (_, i) => para(i + 1)).join("\n\n")}\n`)

const state = (page) => page.evaluate(() => {
  const v = document.querySelector("[data-player-for]"), main = document.querySelector("#main-scroll > main")
  const drawer = document.querySelector("[data-phone-drawer]")
  return {
    phone: document.documentElement.hasAttribute("data-phone"), panes: document.querySelectorAll("[data-pane]").length,
    header: !!document.querySelector("[data-phone-header]")?.getClientRects().length, bar: !!document.querySelector("[data-phone-bar]")?.getClientRects().length,
    main: main?.dataset.qaMark ?? null, video: v?.dataset.qaMark ?? null, playing: !!v && !v.paused, t: v?.currentTime ?? -1,
    drawer: !!drawer && drawer.getAttribute("aria-hidden") === "false", full: document.fullscreenElement === v && !!v,
    sidebar: !!document.querySelector("aside[data-side=left]")?.getClientRects().length && getComputedStyle(document.querySelector("aside[data-side=left]")).display !== "none",
  }
})
const lineReadAtTop = (page) => page.evaluate(() => {
  const y = (parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) || 0) + 1, main = document.querySelector("#main-scroll > main")
  const box = main.getBoundingClientRect()
  for (const el of document.querySelectorAll("#main-scroll :is(.cm-line, p)")) {
    const r = el.getBoundingClientRect()
    if (r.top <= y && r.bottom > y) return { text: el.textContent.slice(0, 13), into: Math.round(((y - r.top) / r.height) * 100) / 100, x: Math.round(r.left - box.left) }
  }
  return null
})

const videoIntoAtTop = (page) => page.evaluate(() => {
  const r = document.querySelector("[data-player-for]").getBoundingClientRect(), y = (parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) || 0) + 1
  return Math.round(((y - r.top) / r.height) * 100) / 100
})

for (const [w, h] of [[390, 844], [430, 932]]) {
  const label = `${w}x${h}`
  const ctx = await browser.newContext({ viewport: { width: w, height: h }, screen: { width: w, height: h }, deviceScaleFactor: 3, isMobile: true, hasTouch: true })
  const page = watch(await ctx.newPage(), { label }), ui = app(page)
  await page.goto(`${B}#file/${encodeURIComponent(NOTE)}`)
  await page.locator("[data-player-for]").waitFor({ state: "attached", timeout: 30000 }); await ui.idle()
  const asSafariWithoutScrollAnchoring = "* { overflow-anchor: none !important; }"
  await page.addStyleTag({ content: asSafariWithoutScrollAnchoring })
  await page.evaluate(async () => {
    document.querySelector("#main-scroll > main").dataset.qaMark = "main"
    const v = document.querySelector("[data-player-for]")
    v.dataset.qaMark = "video"; v.muted = true
    await v.play()
  })
  await until(async () => (await state(page)).t > 0.5, 5000)
  const up = await state(page)
  check(`${label}: upright, the phone's layout, the video playing`, up.phone && up.header && up.bar && !up.panes && up.playing, up)
  await page.screenshot({ path: `${OUT}rotate-${label}-portrait.png` })

  await page.setViewportSize({ width: h, height: w }); await ui.idle()
  const side = await state(page)
  check(`${label}: turned, still the phone's layout (header, bar, no panes)`, side.phone && side.header && side.bar && !side.panes && !side.sidebar, side)
  check(`${label}: turned, nothing drawn anew`, side.main === "main" && side.video === "video", side)
  check(`${label}: turned, the video plays on from where it was`, side.playing && side.t >= up.t, { up: up.t, side: side.t, playing: side.playing })
  check(`${label}: turned, the drawer stays shut`, !side.drawer, side)
  const pad = await page.evaluate(() => { const m = document.querySelector("#main-scroll > main").getBoundingClientRect(); return { left: m.left, width: m.width } })
  check(`${label}: turned, the page keeps a reading width, centred`, pad.width <= 701 && Math.abs(pad.left - (h - pad.width) / 2) <= 1, pad)
  await page.screenshot({ path: `${OUT}rotate-${label}-landscape.png` })

  const cdp = await ctx.newCDPSession(page), NOTCH = 59
  const iosSafeArea = (n) => cdp.send("Emulation.setSafeAreaInsetsOverride", { insets: { top: 0, left: n, right: n, bottom: n ? 21 : 0 } })
  await iosSafeArea(NOTCH); await ui.idle()
  const clear = await page.evaluate(() => {
    const r = (s) => document.querySelector(s)?.getBoundingClientRect()
    return { sidebar: r("[data-phone-header] [aria-label='Open sidebar']")?.left, more: innerWidth - r("[data-phone-header] [aria-label=More]")?.right,
      page: r("#main-scroll > main")?.left, sheet: getComputedStyle(document.querySelector("dialog.sheet-h")).paddingLeft }
  })
  check(`${label}: turned, the header, the page and sheets keep clear of the notch`, clear.sidebar >= NOTCH && clear.more >= NOTCH && clear.page >= NOTCH && clear.sheet === `${NOTCH}px`, clear)
  await page.locator("[data-phone-header] [aria-label='Open sidebar']").tap(); await ui.idle()
  const drawn = await page.evaluate(() => { const d = document.querySelector("[data-phone-drawer]"), body = d?.firstElementChild?.getBoundingClientRect(); return { open: d?.getAttribute("aria-hidden") === "false", left: body?.left } })
  check(`${label}: turned, the drawer's rows keep clear of the notch`, drawn.open && drawn.left >= NOTCH, drawn)
  await page.screenshot({ path: `${OUT}rotate-${label}-landscape-drawer.png` })
  await page.mouse.click(h - 100, w / 2); await ui.idle()
  check(`${label}: and it shuts`, !(await state(page)).drawer)
  await iosSafeArea(0)

  await page.setViewportSize({ width: w, height: h }); await ui.idle()
  const scrollToVideoMiddle = () => page.evaluate(() => { const r = document.querySelector("[data-player-for]").getBoundingClientRect(); window.scrollBy(0, r.top + r.height / 2 - 57) })
  await scrollToVideoMiddle(); await ui.idle()
  const before = await videoIntoAtTop(page)
  const asked = await page.evaluate(() => document.querySelector("[data-player-for]").requestFullscreen().then(() => "", (e) => String(e)))
  check(`${label}: the video goes full screen`, !asked && await until(async () => (await state(page)).full, 3000), asked)
  await page.setViewportSize({ width: h, height: w }); await ui.idle()
  const full = await state(page)
  check(`${label}: full screen stays full screen as it turns, playing`, full.full && full.playing && full.video === "video", full)
  await page.evaluate(() => document.exitFullscreen()); await until(async () => !(await state(page)).full, 3000); await ui.idle()
  const out = await state(page)
  check(`${label}: out of full screen turned, the video is in its place, playing, the layout the phone's`, !out.full && out.playing && out.video === "video" && out.main === "main" && out.phone && !out.panes, out)
  const after = await videoIntoAtTop(page)
  check(`${label}: and the page where it was`, before > 0.3 && Math.abs(after - before) < 0.1, { before, after })

  await page.evaluate(() => document.querySelector("[data-player-for]").pause())
  await page.setViewportSize({ width: w, height: h }); await ui.idle()
  await page.evaluate(() => window.scrollTo(0, 2600)); await ui.idle()
  await page.evaluate(() => {
    const y = (parseFloat(getComputedStyle(document.documentElement).scrollPaddingTop) || 0) + 1
    const read = [...document.querySelectorAll("#main-scroll :is(.cm-line, p)")].find((el) => el.textContent.trim() && el.getBoundingClientRect().bottom > y)
    const r = read.getBoundingClientRect()
    window.scrollBy(0, r.top + r.height * 0.4 - y)
  }); await ui.idle()
  const read0 = await lineReadAtTop(page)
  await page.setViewportSize({ width: h, height: w }); await ui.idle()
  const read1 = await lineReadAtTop(page)
  check(`${label}: turned, the line read at the top stays there`, read0 && read1?.text === read0.text && Math.abs(read1.into - read0.into) < 0.2, { read0, read1 })
  await page.setViewportSize({ width: w, height: h }); await ui.idle()
  const read2 = await lineReadAtTop(page)
  check(`${label}: and turned back`, read2?.text === read0?.text && Math.abs(read2.into - read0.into) < 0.2, { read0, read2 })
  const back = await state(page)
  check(`${label}: back upright, still nothing drawn anew`, back.phone && back.main === "main" && back.video === "video" && !back.drawer, back)
  await ctx.close()
}

{
  const ctx = await browser.newContext({ viewport: { width: 932, height: 430 }, screen: { width: 932, height: 430 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true })
  const page = watch(await ctx.newPage()), ui = app(page), cdp = await ctx.newCDPSession(page), NOTCH = 59
  await cdp.send("Emulation.setSafeAreaInsetsOverride", { insets: { top: 0, left: NOTCH, right: NOTCH, bottom: 21 } })
  await page.goto(`${B}#view/conversations`); await page.locator(".phone-fill").waitFor({ timeout: 30000 }); await ui.idle()
  const fill = await page.evaluate(() => { const r = document.querySelector(".phone-fill").getBoundingClientRect(); return { left: Math.round(r.left), right: Math.round(innerWidth - r.right) } })
  check("932x430 turned: a view that fills the screen spans it, notch to notch, past the page's reading width", fill.left === NOTCH && fill.right === NOTCH, fill)
  await page.setViewportSize({ width: 430, height: 932 }); await cdp.send("Emulation.setSafeAreaInsetsOverride", { insets: { top: 59, left: 0, right: 0, bottom: 34 } }); await ui.idle()
  const up = await page.evaluate(() => { const r = document.querySelector(".phone-fill").getBoundingClientRect(); return { left: Math.round(r.left), right: Math.round(innerWidth - r.right) } })
  check("430x932 upright: it spans the screen edge to edge", up.left === 0 && up.right === 0, up)
  await ctx.close()
}

for (const [label, opts, phone] of [
  ["iPad landscape", { viewport: { width: 1180, height: 820 }, screen: { width: 1180, height: 820 }, isMobile: true, hasTouch: true }, false],
  ["iPad mini upright", { viewport: { width: 768, height: 1024 }, screen: { width: 768, height: 1024 }, isMobile: true, hasTouch: true }, false],
  ["desktop", { viewport: { width: 1280, height: 800 } }, false],
  ["narrow desktop window", { viewport: { width: 600, height: 800 } }, true],
]) {
  const ctx = await browser.newContext(opts)
  const page = watch(await ctx.newPage(), { label }), ui = app(page)
  await page.goto(`${B}#file/${encodeURIComponent(NOTE)}`); await page.locator("[data-player-for]").waitFor({ state: "attached", timeout: 30000 }); await ui.idle()
  const s = await state(page)
  check(`${label}: ${phone ? "the phone's layout" : "the desktop's panes"}`, phone ? s.phone && s.header && s.bar && !s.panes : !s.phone && s.panes > 0 && !s.header && !s.bar, s)
  if (label === "desktop") {
    await page.setViewportSize({ width: 600, height: 800 }); await ui.idle()
    const narrow = await state(page)
    check("desktop: made as narrow as a phone, the phone's layout", narrow.phone && narrow.header && !narrow.panes, narrow)
    await page.setViewportSize({ width: 1280, height: 800 }); await ui.idle()
    const wide = await state(page)
    check("desktop: wide again, the panes", !wide.phone && wide.panes > 0 && !wide.header, wide)
  }
  await ctx.close()
}

await done()
