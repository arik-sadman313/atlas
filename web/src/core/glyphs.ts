import type { ComponentType } from "react"

export type Glyph = { id: string; kind: "icon" | "emoji" | "none"; name: string; code?: string; words: string[]; group: string
  mark?: ComponentType<{ className?: string }> }
export type Section = { name: string; items: Glyph[] }
export type Catalog = { icons: Glyph[]; emoji: Glyph[]; byId: Map<string, Glyph> }
type Gemoji = { emoji: string; names: string[]; tags: string[]; description: string; category: string }

export const isEmoji = (s: string) => /\p{Extended_Pictographic}|\p{Regional_Indicator}/u.test(s) && [...s].length <= 10 && !/[\p{L}\p{N}]{2}/u.test(s)

export const ICONS_GROUP = "Icons", RECENT_GROUP = "Recent"
export const EMOJI_GROUPS: [string, string][] = [
  ["Smileys & Emotion", "😀"], ["People & Body", "👋"], ["Animals & Nature", "🐻"], ["Food & Drink", "🍔"], ["Travel & Places", "✈️"],
  ["Activities", "⚽"], ["Objects", "💡"], ["Symbols", "💟"], ["Flags", "🏁"],
]

const split = (s: string) => s.toLowerCase().split(/[\s_\-:&,.’'()]+/).filter(Boolean)

export function catalog(tags: Record<string, string[]>, emoji: readonly Gemoji[], common: readonly string[]): Catalog {
  const first = common.filter((n) => tags[n])
  const icons = [...new Set([...first, ...Object.keys(tags).sort()])]
    .map((n): Glyph => ({ id: n, kind: "icon", name: n, words: [...new Set([...split(n), ...tags[n].flatMap(split)])], group: ICONS_GROUP }))
  const rank = new Map(EMOJI_GROUPS.map(([g], i) => [g, i]))
  const emojis = emoji.filter((e) => rank.has(e.category)).sort((x, y) => (rank.get(x.category) ?? 0) - (rank.get(y.category) ?? 0))
    .map((e): Glyph => ({ id: e.emoji, kind: "emoji", name: e.description, code: e.names[0], words: [...new Set([...e.names.flatMap(split), ...split(e.description), ...e.tags.flatMap(split)])], group: e.category }))
  const byId = new Map<string, Glyph>()
  for (const g of [...icons, ...emojis]) if (!byId.has(g.id)) byId.set(g.id, g)
  return { icons, emoji: emojis, byId }
}

const bare = (id: string) => id.replace(/\uFE0F/g, "")
export function glyphOf(c: Catalog, id: string): Glyph {
  const known = c.byId.get(id) ?? c.byId.get(bare(id)) ?? c.byId.get(`${bare(id)}\uFE0F`)
  if (known) return known.id === id ? known : { ...known, id }
  return isEmoji(id) ? { id, kind: "emoji", name: "Emoji", words: [], group: "Emoji" } : { id, kind: "icon", name: id, words: [], group: ICONS_GROUP }
}

export function rankOf(g: Glyph, words: readonly string[], typed: string): number | null {
  const name = g.name.toLowerCase()
  if (name === typed || g.code === typed) return 0
  if (name.startsWith(typed) || g.code?.startsWith(typed)) return 1
  const own = split(g.code ? `${g.name} ${g.code}` : g.name)
  if (words.every((w) => own.some((o) => o.startsWith(w)))) return 2
  return words.every((w) => g.words.some((o) => o.startsWith(w))) ? 3 : null
}

function found(list: readonly Glyph[], words: readonly string[], typed: string) {
  const hits: { g: Glyph; r: number; i: number }[] = []
  list.forEach((g, i) => { const r = rankOf(g, words, typed); if (r !== null) hits.push({ g, r, i }) })
  hits.sort((a, b) => a.r - b.r || a.i - b.i)
  return { items: hits.map((h) => h.g), best: hits[0]?.r ?? Infinity }
}

function browsing(c: Catalog, only: boolean, withEmoji: boolean, current: string | undefined, recent: readonly string[]): Section[] {
  const out: Section[] = []
  const seen = [...new Set([current, ...recent.filter((id) => withEmoji || !isEmoji(id))].filter((id): id is string => !!id))].map((id) => glyphOf(c, id))
  if (seen.length && !only) out.push({ name: RECENT_GROUP, items: seen })
  if (!only) out.push({ name: ICONS_GROUP, items: c.icons })
  if (withEmoji) for (const [name] of EMOJI_GROUPS) out.push({ name, items: c.emoji.filter((g) => g.group === name) })
  return out.filter((s) => s.items.length)
}

export function sectionsFor(c: Catalog, query: string, { emoji, current, recent = [], none }: { emoji: boolean; current?: string; recent?: readonly string[]; none?: Glyph }): Section[] {
  const q = query.trim()
  if (q && isEmoji(q)) return [{ name: "Emoji", items: [glyphOf(c, q)] }]
  const only = q.startsWith(":"), typed = (only ? q.slice(1).replace(/:$/, "") : q).toLowerCase(), words = split(typed)
  const withEmoji = emoji || only
  if (!words.length) {
    const shown = browsing(c, only, withEmoji, current, recent)
    return none && shown[0] ? [{ ...shown[0], items: [none, ...shown[0].items] }, ...shown.slice(1)] : shown
  }
  const icons = only ? { items: [], best: Infinity } : found(c.icons, words, typed)
  const emojis = withEmoji ? found(c.emoji, words, typed) : { items: [], best: Infinity }
  const both = [{ name: ICONS_GROUP, ...icons }, { name: "Emoji", ...emojis }].filter((s) => s.items.length)
  return both.sort((a, b) => a.best - b.best).map(({ name, items }) => ({ name, items }))
}

const RECENT = "vau:icon-picker:recent"
export function recentGlyphs(): string[] {
  try { return localStorage.getItem(RECENT)?.split("\n").filter(Boolean) ?? [] } catch { return [] }
}
export function rememberGlyph(id: string, max = 30) {
  try { localStorage.setItem(RECENT, [id, ...recentGlyphs().filter((k) => k !== id)].slice(0, max).join("\n")) } catch { return }
}
