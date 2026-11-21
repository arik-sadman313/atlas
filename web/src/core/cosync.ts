type Owner = { kind: "joining" | "live" }
const owners = new Map<string, Owner>()
type Back = (path: string, base: string | null, shown: string | null) => void
const backs = new Set<Back>()

/** Whether a live session keeps `path` now (joining it or typed in): its editors' autosave stands down. */
export const keptLive = (path: string) => owners.has(path)
export const typedLive = (path: string) => owners.get(path)?.kind === "live"

/** A live session takes `path`'s saving (joining it): `live` once typed in, `handBack` on `base` (the server's text then;
 *  none: unknown) and `shown` (its editors' text then). A later hold on the path replaces this one, doing nothing. */
export function keepLive(path: string) {
  const me: Owner = { kind: "joining" }
  owners.set(path, me)
  return {
    live() { if (owners.get(path) === me) me.kind = "live" },
    handBack(base: string | null = null, shown: string | null = base) {
      if (owners.get(path) !== me) return
      owners.delete(path)
      for (const fn of backs) fn(path, base, shown)
    },
  }
}

export function onHandBack(fn: Back) {
  backs.add(fn)
  return () => { backs.delete(fn) }
}
