export const waitsOnUser = (s: { state?: string }) => s.state === "blocked"
export const hasNews = (s: { needs?: boolean; review?: boolean }) => !!s.needs || !!s.review
export type Awaits = { on: string; since: number; n: number }
export const sameAwaits = (a: Awaits | null | undefined, b: Awaits | null | undefined) => (a?.on ?? "") === (b?.on ?? "") && (a?.since ?? 0) === (b?.since ?? 0) && (a?.n ?? 0) === (b?.n ?? 0)
export const awaitsText = (a: Awaits) => `Waiting on ${a.on}${a.n > 1 ? ` and ${a.n - 1} more` : ""}`
const TIME = new Intl.DateTimeFormat(undefined, { hour: "numeric", minute: "2-digit" }), DAY_TIME = new Intl.DateTimeFormat(undefined, { weekday: "short", hour: "numeric", minute: "2-digit" })
export function awaitsLine(a: Awaits, now = Date.now()) {
  if (!a.since) return awaitsText(a)
  return `${awaitsText(a)}, since ${(new Date(now).toDateString() === new Date(a.since).toDateString() ? TIME : DAY_TIME).format(a.since)}`
}
