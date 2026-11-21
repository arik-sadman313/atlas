import { Keyboard, RotateCcw, X } from "lucide-react"
import { defaultKeysOf, isCustom, keyHint, keysOf, knownCommands, runCommandById, sameKeys, setHotkeys, shortcutOf, type KnownCommand } from "@/core/commands"
import { notify } from "@/core/notify"
import { isMac } from "@/core/platform"
import { bindable, keyHolders } from "@/core/keyholders"
import { openMenu, replaceMenu, type MenuItem } from "@/components/ContextMenu"

const save = (id: string, keys: string[]) => {
  const c = knownCommands().find((x) => x.id === id)
  const defaults = c ? defaultKeysOf(c) : []
  const same = keys.length === defaults.length && keys.every((k, i) => sameKeys(k, defaults[i]))
  return setHotkeys(id, same ? null : keys)
}

function snapshot(ids: string[]) {
  const was = ids.map((id) => {
    const c = knownCommands().find((x) => x.id === id)
    return [id, isCustom(id) && c ? keysOf(c) : null] as const
  })
  return () => { for (const [id, keys] of was) void setHotkeys(id, keys) }
}

export function bindKeys(c: KnownCommand, k: string, was: string | undefined, from: KnownCommand[] = []) {
  const undo = snapshot([c.id, ...from.map((o) => o.id)])
  for (const o of from) void save(o.id, keysOf(o).filter((x) => !sameKeys(x, k)))
  const keys = keysOf(c), at = was ? keys.findIndex((x) => sameKeys(x, was)) : -1
  const next = at < 0 ? [...keys, k] : keys.map((x, i) => (i === at ? k : x))
  void save(c.id, next.filter((x, i) => next.findIndex((y) => sameKeys(x, y)) === i))
  notify(`${c.name} is now ${keyHint(k)}`, { action: { label: "Undo", run: undo } })
}

function removeKeys(c: KnownCommand, k: string) {
  const undo = snapshot([c.id])
  void save(c.id, keysOf(c).filter((x) => !sameKeys(x, k)))
  notify(`${c.name} has no ${keyHint(k)} now`, { action: { label: "Undo", run: undo } })
}

function restoreKeys(c: KnownCommand) {
  const undo = snapshot([c.id])
  void setHotkeys(c.id, null)
  const first = defaultKeysOf(c)[0]
  notify(first ? `${c.name} is back to ${keyHint(first)}` : `${c.name} is back to no shortcut`, { action: { label: "Undo", run: undo } })
}

let stopNow: (() => void) | null = null

const firstItems = (c: KnownCommand, was: string | undefined, said?: string): MenuItem[] => {
  const defaults = defaultKeysOf(c)
  return [
    { label: said ?? `Press new keys for ${c.name.replace(/…$/, "")}`, icon: Keyboard, caption: true, run: () => {} },
    ...(was ? [{ label: `Remove ${keyHint(was)}`, icon: X, run: () => removeKeys(c, was) }] : []),
    ...(isCustom(c.id) ? [{ label: "Restore default", icon: RotateCcw, hint: defaults[0] ? keyHint(defaults[0]) : "None", run: () => restoreKeys(c) }] : []),
    { label: "All hotkeys", icon: Keyboard, sep: true, run: () => { runCommandById("hotkeys:open") } },
  ]
}
const takenItems = (c: KnownCommand, was: string | undefined, k: string, others: KnownCommand[]): MenuItem[] => [
  { label: `${keyHint(k)} is ${others.map((o) => o.name).join(", ")}. Press other keys, or:`, icon: Keyboard, caption: true, run: () => {} },
  { label: "Replace", run: () => bindKeys(c, k, was, others) },
  { label: "Keep both", run: () => bindKeys(c, k, was) },
]
const alone = (k: string) => `${keyHint(k)} alone types text: hold ${keyHint("Mod")}, ${keyHint("Alt")}${isMac ? ` or ${keyHint("Ctrl")}` : ""} with it`
const NAVIGATES = /^(Escape|Tab|Enter|ArrowUp|ArrowDown|ArrowLeft|ArrowRight|Home|End)$/

export function rebind(id: string, el: Element, which?: string) {
  stopNow?.()
  const c = knownCommands().find((x) => x.id === id)
  if (!c) return
  const was = which ?? keysOf(c)[0]
  let items = firstItems(c, was)
  const show = (next: MenuItem[]) => { replaceMenu(items, next); items = next }
  const down = (e: KeyboardEvent) => {
    if (e.isComposing || NAVIGATES.test(e.key)) return
    e.preventDefault()
    e.stopImmediatePropagation()
    const k = shortcutOf(e)
    if (!k) return
    if (!bindable(k)) return show(firstItems(c, was, alone(k)))
    if (was && sameKeys(k, was)) return replaceMenu(items, [])
    const others = keyHolders(k, id)
    if (others.length) return show(takenItems(c, was, k, others))
    replaceMenu(items, [])
    bindKeys(c, k, was)
  }
  const r = el.getBoundingClientRect()
  const stop = () => {
    removeEventListener("keydown", down, true)
    el.removeAttribute("data-rebinding")
    if (stopNow === stop) stopNow = null
  }
  stopNow = stop
  el.setAttribute("data-rebinding", "")
  addEventListener("keydown", down, true)
  openMenu({ x: r.left, y: r.bottom + 4, flip: r.top - 4 }, items, false, undefined, stop)
}
