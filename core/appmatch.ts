export type Findable = { title: string; names?: readonly string[]; about?: string; weight?: number }

const STOP = new Set(["a", "an", "the", "my", "all", "of", "in", "on", "for", "to", "and", "or", "with", "where", "what", "which", "shows",
  "show", "see", "page", "view", "that", "is", "are", "i", "me", "it", "its", "each", "different", "every", "list", "lists"])

const stem = (w: string) => (w.length > 4 && w.endsWith("ies") ? `${w.slice(0, -3)}y` : w.length > 3 && w.endsWith("s") && !w.endsWith("ss") ? w.slice(0, -1) : w)
const wordsOf = (s: string) => s.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean).map(stem)

function edits(a: string, b: string, most: number) {
  if (Math.abs(a.length - b.length) > most) return most + 1
  let row = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    const next = [i]
    for (let j = 1; j <= b.length; j++) next[j] = Math.min(row[j] + 1, next[j - 1] + 1, row[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1))
    row = next
  }
  return row[b.length]
}

function alike(said: string, word: string) {
  if (said === word) return true
  const [short, long] = said.length <= word.length ? [said, word] : [word, said]
  if (short.length >= 5 && long.startsWith(short)) return true
  return said.length >= 5 && word.length >= 5 && edits(said, word, 2) <= (said.length >= 8 ? 2 : 1)
}

export function matchScore(said: string, f: Findable): number {
  const all = wordsOf(said), asked = all.filter((w) => !STOP.has(w))
  const qs = asked.length ? asked : all
  if (!qs.length) return 0
  const phrase = all.join(" ")
  const named = [f.title, ...(f.names ?? [])].map(wordsOf)
  if (named.some((ws) => ws.join(" ") === phrase)) return 100
  const best = (60 * qs.filter((w) => named.some((ws) => ws.some((x) => alike(w, x)))).length) / qs.length
  const whole = Math.max(...named.map((ws) => (ws.length ? ws.filter((x) => qs.some((w) => alike(w, x))).length / ws.length : 0)))
  const about = wordsOf(f.about ?? "")
  const told = qs.filter((w) => w.length > 2 && about.some((x) => alike(w, x))).length
  const score = best + (20 * told) / qs.length + (best ? 10 * whole : 0)
  return score > 0 ? score + (f.weight ?? 0) : 0
}

export function closest<T extends Findable>(said: string, all: readonly T[], most = 5, least = 15): T[] {
  return all.flatMap((f) => { const s = matchScore(said, f); return s >= least ? [{ f, s }] : [] }).sort((a, b) => b.s - a.s).slice(0, most).map((x) => x.f)
}
