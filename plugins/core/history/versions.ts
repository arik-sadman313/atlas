import { agentTint, dateText, fmtDay, iso, type Color } from "@vaultite"

export type Kind = "you" | "agent" | "cli" | "script" | "disk"
/** A version of a file: one File history kept (`t`), another plugin's (`source`, `id`: a git commit), or the file now. */
export type Version = { key: string; t: number; size?: number; by?: string; kind?: Kind; source?: string; label?: string; id?: string; title?: string; now?: boolean }
type Kept = { t: number; size: number; by?: string; kind?: Kind }
type Other = { source: string; label: string; versions: { id: string; t: number; title?: string; by?: string }[] }
export type Listed = { versions: Kept[]; others?: Other[]; now?: Kept }

export function listOf(r: Listed): Version[] {
  const kept: Version[] = r.versions.map((v) => ({ ...v, key: String(v.t) }))
  const others: Version[] = (r.others ?? []).flatMap((o) => o.versions.map((v) => ({ ...v, key: `${o.source}:${v.id}`, source: o.source, label: o.label, kind: v.by ? "agent" : undefined })))
  const now: Version[] = r.now ? [{ ...r.now, key: "now", now: true }] : []
  return [...now, ...[...kept, ...others].sort((a, b) => b.t - a.t)]
}

export function writer(v: Version): string | null {
  if (v.source) return v.by ?? v.label ?? null
  if (!v.by) return null
  if (v.kind === "you") return "You"
  if (v.kind === "disk") return "Another app or device"
  return v.by
}

export const tintOf = (v: Version): Color => (v.kind === "you" ? "blue" : v.kind === "disk" || !v.by ? "gray" : agentTint(v.by))

/** One line of the list: a version, with the ones just before it by the same writer folded under it (within an hour). */
export type Row = { head: Version; folded: Version[] }
const HOUR = 3_600_000
export function rowsOf(list: Version[]): Row[] {
  const rows: Row[] = []
  for (const v of list) {
    const last = rows.at(-1), end = last && (last.folded.at(-1) ?? last.head)
    const same = last && !last.head.now && !v.source && !last.head.source && writer(v) === writer(last.head)
      && iso(new Date(v.t)) === iso(new Date(last.head.t)) && end!.t - v.t < HOUR
    if (same) last.folded.push(v); else rows.push({ head: v, folded: [] })
  }
  return rows
}

export function daysOf(rows: Row[]): { day: string; rows: Row[] }[] {
  const out: { day: string; rows: Row[] }[] = []
  for (const r of rows) {
    const day = fmtDay(iso(new Date(r.head.t)))
    if (out.at(-1)?.day === day) out.at(-1)!.rows.push(r); else out.push({ day, rows: [r] })
  }
  return out
}

const TIME = { hour: "numeric", minute: "2-digit" } as const
export const timeOf = (t: number) => dateText(new Date(t), TIME)
export function whenOf(t: number) {
  const day = fmtDay(iso(new Date(t)))
  return `${day}, ${timeOf(t)}`
}
