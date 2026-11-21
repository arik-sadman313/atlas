import { COLORS, devicePref, notify, notifyError, pluginSettings, put, webPages, workspaceList, type WebSite } from "@vaultite"
import { containers, profileIn } from "./containers.ts"
import { settings } from "./state.ts"
import { OLD_WORKSPACES, planMoves, type Move } from "./workspacelogins.ts"

const done = devicePref<boolean>("web-viewer:workspace-logins-moved", false)
const raw = pluginSettings<{ logins?: unknown }>("web-viewer")

type Planned = Move<(typeof COLORS)[number]>[]

export async function moveWorkspaceLogins() {
  const sites = webPages?.sites
  if (done.get() || !sites || !webPages?.move) return
  done.set(true)
  await settings.ready()
  const was = raw.get().logins
  if (was === "shared") return
  try {
    if (was !== undefined) await raw.set({ logins: null })
    const found = Object.fromEntries(await Promise.all(OLD_WORKSPACES.map(async (n): Promise<[string, WebSite[]]> => [String(n), await sites(String(n))])))
    const moves = planMoves(found, new Map(workspaceList().map((w) => [w.n, w.label])), containers(), COLORS)
    if (moves.length) await carryOut(moves)
  } catch (e) {
    done.set(false)
    notifyError(e, "Couldn't move workspaces' logins to containers")
  }
}

async function carryOut(moves: Planned) {
  await settings.set({ containers: [...containers(), ...moves.map((m) => m.container)] })
  const kept: string[] = []
  for (const m of moves) for (const names of m.logins) if (!(await moveLogin(m.from, m.container.id, names))) kept.push(names[0])
  const desks = new Set(workspaceList().flatMap((w) => (w.container ? [] : [w.n])))
  for (const m of moves) if (desks.has(Number(m.from))) await put(`workspaces/${m.from}`, { container: m.container.id }).catch(() => {})
  notify(`Each workspace's logins are now a container: ${moves.map((m) => m.container.name).join(", ")}`, { duration: 15_000 })
  if (kept.length) notify(`Couldn't move ${kept.join(", ")}: sign in to ${kept.length > 1 ? "them" : "it"} in the new container`, { kind: "error" })
}

const moveLogin = (from: string, container: string, names: string[]) =>
  webPages?.move?.(from, profileIn(container), names, false).then((r) => r.ok, () => false) ?? Promise.resolve(false)
