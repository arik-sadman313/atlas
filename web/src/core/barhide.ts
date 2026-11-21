const DOWN = 12, UP = 28, NEAR_TOP = 56, LIVE_MS = 150, TAP_PX = 10

export function hideBarsOnUserScroll() {
  const root = document.documentElement
  let last = Math.max(0, scrollY), run = 0, frame = 0
  let touching = false, liveUntil = 0, x = 0, y = 0, moved = false
  const away = (on: boolean) => {
    run = 0
    if (on !== root.hasAttribute("data-bars-away")) root.toggleAttribute("data-bars-away", on)
  }
  const pageHeld = () => "keyboard" in root.dataset || "pageLift" in root.dataset || root.style.overflow === "hidden" || !!document.querySelector("dialog[open], [data-phone-drawer]")
  const live = () => touching || performance.now() <= liveUntil
  const read = () => {
    frame = 0
    const at = Math.max(0, scrollY), d = at - last
    last = at
    root.toggleAttribute("data-scrolled", at > 0)
    if (at < NEAR_TOP || at >= root.scrollHeight - innerHeight - 2) return away(false)
    if (!live()) return
    if (pageHeld()) return away(false)
    if (d && Math.sign(d) !== Math.sign(run)) run = 0
    run += d
    if (run > DOWN) away(true)
    else if (run < -UP) away(false)
  }
  const offs: (() => void)[] = []
  const listen = <K extends keyof WindowEventMap>(type: K, f: (e: WindowEventMap[K]) => void) => {
    addEventListener(type, f, { capture: true, passive: true })
    offs.push(() => removeEventListener(type, f, { capture: true }))
  }
  const lifted = (e: TouchEvent) => {
    touching = e.touches.length > 0
    if (moved) liveUntil = performance.now() + LIVE_MS
    else if (!touching) away(false)
  }
  const placed = () => { last = Math.max(0, scrollY); liveUntil = 0; away(false) }
  listen("scroll", () => { if (live()) liveUntil = performance.now() + LIVE_MS; frame ||= requestAnimationFrame(read) })
  listen("touchstart", (e) => { touching = true; moved = false; x = e.touches[0]?.clientX ?? 0; y = e.touches[0]?.clientY ?? 0 })
  listen("touchmove", (e) => { const t = e.touches[0]; if (t && Math.hypot(t.clientX - x, t.clientY - y) > TAP_PX) moved = true })
  listen("touchend", lifted); listen("touchcancel", lifted)
  listen("wheel", () => { liveUntil = performance.now() + LIVE_MS })
  listen("hashchange", placed); listen("popstate", placed)
  read()
  return () => {
    cancelAnimationFrame(frame)
    root.removeAttribute("data-bars-away")
    for (const off of offs) off()
  }
}
