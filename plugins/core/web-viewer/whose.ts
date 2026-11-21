import { webPages } from "@vaultite"
import { engine } from "./engine"
import { profileIn } from "./containers"

const lower = (s: string) => s.trim().toLowerCase()

export async function accountsIn(container: string | null): Promise<Set<string>> {
  const sites = await webPages?.sites?.(profileIn(container)).catch(() => []) ?? []
  return new Set(sites.flatMap((s) => [s.account ?? "", ...(s.more ?? [])]).filter(Boolean).map(lower))
}

export const savedUsers = (url: string): Promise<string[]> => engine("passwords:users", url).then((u) => u ?? [], () => [])

export async function hintsFor(url: string, ids: (string | null)[]): Promise<Map<string | null, string>> {
  const users = await savedUsers(url)
  const out = new Map<string | null, string>()
  if (!users.length) return out
  await Promise.all(ids.map(async (id) => {
    const mine = await accountsIn(id), user = users.find((u) => mine.has(lower(u)))
    if (user) out.set(id, user)
  }))
  return out
}

export async function mineOf<L extends { username: string }>(list: L[], container: string | null): Promise<L | null> {
  const mine = await accountsIn(container)
  const matched = list.filter((l) => mine.has(lower(l.username)))
  return matched.length === 1 ? matched[0] : null
}
