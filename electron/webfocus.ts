import type { AppWindow } from "./appwindow.ts"
import { cdp } from "./browser/cdp.ts"
import { pageHeld } from "./browser/engine.ts"
import { focusStep, type FocusEvent } from "./focusstep.ts"
import { pages } from "./webbase.ts"

const kept = new WeakMap<AppWindow, number | null>()

function emulate(id: number, on: boolean) {
  const p = pages.get(id)
  if (!p || p.view.webContents.isDestroyed() || pageHeld(id)) return
  void cdp(p.view.webContents, "Emulation.setFocusEmulationEnabled", { enabled: on }).catch(() => {})
}

export function focusOn(win: AppWindow, e: FocusEvent) {
  if (win.isDestroyed()) return
  if (!kept.has(win)) win.on("blur", () => focusOn(win, { type: "appBlurred" }))
  const withKeyboard = e.type === "raise" ? [...pages.values()].find((p) => p.win === win && !p.view.webContents.isDestroyed() && p.view.webContents.isFocused())?.id ?? null : null
  const m = focusStep(kept.get(win) ?? null, e, withKeyboard)
  kept.set(win, m.kept)
  if (m.off !== null) emulate(m.off, false)
  if (m.on !== null) emulate(m.on, true)
}
