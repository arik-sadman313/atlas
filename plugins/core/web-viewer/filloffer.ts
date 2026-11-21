import { notify } from "@vaultite"
import type { FillLogin as Login } from "./engine"
import { mineOf } from "./whose"

const nameOf = (l: Login) => l.title || l.username || "this login"
const offeredFill = new Set<string>()
export async function offerFill(id: number, url: string, container: string | null, logins: Login[], fill: (id: number, l: Login) => Promise<void>, choose: (id: number) => Promise<void>) {
  const host = hostOf(url), key = `${id} ${host}`
  if (!host || offeredFill.has(key)) return
  offeredFill.add(key)
  const one = logins.length === 1 ? logins[0] : await mineOf(logins, container)
  notify(one ? `Sign in to ${host} as ${one.username || nameOf(one)}?` : `Sign in to ${host}: your passwords have ${logins.length} logins for it`, {
    id: `fill-login-${id}`, duration: 15_000,
    action: { label: one ? "Fill" : "Choose…", run: () => (one ? fill(id, one) : choose(id)) },
  })
}
const hostOf = (url: string) => { try { return new URL(url).hostname.replace(/^www\./, "") } catch { return "" } }
