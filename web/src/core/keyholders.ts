import { keysOf, knownCommands, sameKeys } from "@/core/commands"
import { isMac } from "@/core/platform"

export function keyHolders(k: string, id?: string, known = knownCommands()) {
  const self = known.find((c) => c.id === id)
  return known.filter((c) => c.id !== id && !(self?.contextual && c.contextual) && keysOf(c).some((x) => sameKeys(x, k)))
}

export const bindable = (k: string) => /^(Mod|Ctrl|Alt)\+/.test(k) || /^F\d+$/.test(k.split("+").pop() ?? "")

export const heldOf = (e: KeyboardEvent) =>
  [isMac ? e.metaKey && "Mod" : e.ctrlKey && "Mod", isMac && e.ctrlKey && "Ctrl", e.altKey && "Alt", e.shiftKey && "Shift"].filter(Boolean).join("+")
