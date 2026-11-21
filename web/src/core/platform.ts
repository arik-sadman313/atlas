import { useSyncExternalStore } from "react"

const ua = typeof navigator === "undefined" ? "" : navigator.platform || navigator.userAgent

/** A Mac, iPhone or iPad: ⌘ is the app's Mod key. */
export const isMac = /Mac|iPhone|iPad/.test(ua)
/** A Linux computer (not Android). */
export const isLinux = /Linux/.test(ua) && !/Android/.test(typeof navigator === "undefined" ? "" : navigator.userAgent)
/** A Windows computer. */
export const isWindows = /Win/.test(ua)

/** Showing a file where it is: Finder on a Mac, Explorer on Windows, the file manager elsewhere. */
export const revealLabel = isMac ? "Reveal in Finder" : isWindows ? "Show in Explorer" : "Show in folder"
/** The same for a toast's action, on something just saved. */
export const showLabel = isMac ? "Show in Finder" : isWindows ? "Show in Explorer" : "Show in folder"
/** The app's Mod key in words, for "⌘-click" / "Ctrl-click". */
export const modKey = isMac ? "⌘" : "Ctrl"

const GLYPH: Record<string, string> = { "⌃": "Ctrl", "⌘": "Ctrl", "⌥": "Alt", "⇧": "Shift" }
/** A Mac's key glyphs in text (a manifest's "⌥⌘F", "⌘-click") as this computer names them: "Ctrl+Alt+F", "Ctrl-click". */
export const keysText = (s: string, mac = isMac) => mac ? s : s.replace(/([⌃⌘⌥⇧]+)(?=([^\s\-.,;:)]?))/g, (g, _m, next: string) => {
  const names = [...new Set([...g].map((c) => GLYPH[c]))].sort((a, b) => ["Ctrl", "Alt", "Shift"].indexOf(a) - ["Ctrl", "Alt", "Shift"].indexOf(b))
  return names.join("+") + (next ? "+" : "")
})

const NARROW = "(max-width: 767.98px)", TOUCH = "(pointer: coarse)"
const PHONE_SIDE = 600
const canMatch = typeof matchMedia === "function"
/** A phone: a touch screen with a short side under 600px, whatever its window is. */
export const isPhoneDevice = () => canMatch && matchMedia(TOUCH).matches && Math.min(screen.width, screen.height) < PHONE_SIDE
const phoneLayout = () => canMatch && (matchMedia(NARROW).matches || isPhoneDevice())
/** The desktop's panes, not the phone's layout: a window as narrow as a phone's, or a phone either way up (its short side under 600px: an iPhone's is at most 440, an iPad mini's 744). */
export const isDesktop = () => !phoneLayout()

let phone = phoneLayout()
const layoutChanged = new Set<() => void>()
const markLayout = () => { if (document.documentElement.hasAttribute("data-phone") !== phone) document.documentElement.toggleAttribute("data-phone", phone) }
function relayout() {
  if (phoneLayout() === phone) return
  phone = !phone
  markLayout()
  for (const f of layoutChanged) f()
}
export const onLayoutChange = (f: () => void) => { layoutChanged.add(f); return () => { layoutChanged.delete(f) } }
/** isDesktop that follows the window: a computer's window resized as narrow as a phone's takes the phone's layout. */
export const useDesktop = () => useSyncExternalStore(onLayoutChange, isDesktop)
if (typeof document !== "undefined" && canMatch) {
  markLayout()
  addEventListener("resize", relayout)
  for (const q of [NARROW, TOUCH]) matchMedia(q).addEventListener("change", relayout)
}

let measuredAt = 0
const probe = () => {
  const el = document.createElement("div")
  el.style.cssText = "position:fixed;top:-200px;width:100px;height:100px;overflow:scroll;visibility:hidden"
  return el
}
function measureScrollbars(again = false) {
  if (!again && measuredAt === devicePixelRatio) return
  measuredAt = devicePixelRatio
  const html = document.documentElement
  // ::-webkit-scrollbar rules don't reach into a shadow root: the system's own bar
  const host = html.appendChild(document.createElement("div")), native = host.attachShadow({ mode: "open" }).appendChild(probe())
  const classic = native.offsetWidth > native.clientWidth
  host.remove()
  if (classic !== html.hasAttribute("data-classic-scrollbars")) html.toggleAttribute("data-classic-scrollbars", classic)
  let room = "0px"
  if (classic) { const ours = html.appendChild(probe()); room = `${ours.offsetWidth - ours.clientWidth}px`; ours.remove() }
  if (html.style.getPropertyValue("--scrollbar-room") !== room) html.style.setProperty("--scrollbar-room", room)
  if (classic) addEventListener("scroll", scrolled, { capture: true, passive: true })
  else removeEventListener("scroll", scrolled, { capture: true })
}
const scrolling = new Map<Element, number>()
function scrolled(e: Event) {
  const el = e.target
  if (!(el instanceof Element)) return
  const was = scrolling.get(el)
  if (was) clearTimeout(was)
  else el.setAttribute("data-scrolling", "")
  scrolling.set(el, window.setTimeout(() => { scrolling.delete(el); el.removeAttribute("data-scrolling") }, 1000))
}
if (typeof document !== "undefined" && typeof devicePixelRatio === "number") {
  measureScrollbars()
  addEventListener("resize", () => measureScrollbars())
  // macOS's "Show scroll bars", or a mouse plugged in, changes them while the app runs
  addEventListener("focus", () => measureScrollbars(true))
}
