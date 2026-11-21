import { openView } from "@vaultite"

const FRESH_MS = 3000
let askedAt = 0
const heard = new Set<() => void>()
export function showTalk() {
  askedAt = Date.now()
  for (const f of heard) f()
  openView("conversations", { newTab: true })
}
export const talkAsked = {
  just: () => Date.now() - askedAt < FRESH_MS,
  on: (f: () => void) => { heard.add(f); return () => { heard.delete(f) } },
}
