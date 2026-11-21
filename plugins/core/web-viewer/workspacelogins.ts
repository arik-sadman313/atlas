export const OLD_WORKSPACES = [2, 3, 4, 5]

type Site = { site: string; with?: string[]; other?: boolean }
type Named = { id: string; name: string }
export type Move<C> = { from: string; container: Named & { color: C }; logins: string[][] }

export function planMoves<C>(found: Record<string, Site[]>, labels: Map<number, string>, have: Named[], colors: readonly C[]): Move<C>[] {
  const list = [...have], moves: Move<C>[] = []
  for (const n of OLD_WORKSPACES) {
    const logins = (found[String(n)] ?? []).filter((s) => !s.other).map((s) => [s.site, ...(s.with ?? [])])
    if (!logins.length) continue
    const label = labels.get(n)?.trim().slice(0, 40) || `Workspace ${n}`
    const taken = new Set(list.map((c) => c.name.toLowerCase()))
    const name = [label, `Workspace ${n}`, `Workspace ${n} logins`].find((x) => !taken.has(x.toLowerCase())) ?? label
    const ids = new Set(list.map((c) => c.id))
    let id = `workspace${n}`
    for (let k = 2; ids.has(id); k++) id = `workspace${n}x${k}`
    const container = { id, name, color: colors[list.length % colors.length] }
    list.push(container)
    moves.push({ from: String(n), container, logins })
  }
  return moves
}
