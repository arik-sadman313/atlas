import { drawerPanels, phoneDock, setDrawerOpener, useSidebars, type Side } from "@/core/plugins"
import { usePrefs } from "@/core/prefs"
import { signal } from "@/core/signal"

let out: Side | null = null
const subs = signal()
setDrawerOpener((side) => openDrawer(side))

export function openDrawer(side: Side | null) {
  if (out === side) return
  out = side
  subs.notify()
}
export const drawerOut = () => out
export const useDrawer = () => subs.use(() => out)
export function useHasDrawer(side: Side) {
  const { disabled } = usePrefs()
  const s = useSidebars()
  return drawerPanels(side, s, disabled).length > 0 || (side === "left" && phoneDock(s, disabled).length > 0)
}
