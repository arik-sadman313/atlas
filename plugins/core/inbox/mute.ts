import { notify, notifyError } from "@vaultite"
import { getEvents, markEventsDone, unsettle } from "./events"
import { settings } from "./settings"
import type { InboxEvent } from "./types"

type Account = NonNullable<InboxEvent["account"]>
const named = (a: Account) => (m: string) => [a.id, a.label].some((x) => x.toLowerCase() === m.trim().toLowerCase())

export async function muteAccount(a: Account) {
  await settings.ready()
  const before = settings.get().muted ?? []
  if (before.some(named(a))) return
  const open = getEvents().events.filter((e) => e.state !== "done" && e.account && named(a)(e.account.id))
  try { await settings.set({ muted: [...before, a.label] }) } catch (e) { return notifyError(e, "Couldn't mute that account") }
  if (open.length) void markEventsDone(open.map((e) => e.id))
  notify(`Muted the ${a.label} account: its sessions no longer show here or notify you`, { action: { label: "Undo", run: async () => {
    const now = settings.get().muted ?? []
    await settings.set({ muted: now.filter((m) => !named(a)(m)).length ? now.filter((m) => !named(a)(m)) : null })
    if (open.length) await unsettle(open)
  } } })
}
