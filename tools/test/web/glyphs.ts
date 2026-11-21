import { check } from "../lib.ts"
import { web } from "./lib.ts"

type Glyph = { id: string; kind: "icon" | "emoji"; name: string; code?: string; group: string }
type Section = { name: string; items: Glyph[] }
type Catalog = { icons: Glyph[]; emoji: Glyph[] }
const g: {
  catalog(tags: Record<string, string[]>, emoji: readonly object[], common: readonly string[]): Catalog
  sectionsFor(c: Catalog, q: string, o: { emoji: boolean; current?: string; recent?: string[] }): Section[]
  glyphOf(c: Catalog, id: string): Glyph
  isEmoji(s: string): boolean
} = await web("core/glyphs.ts")
const { gemoji } = await import("gemoji")
const { default: tags } = await import("../../../web/src/core/lucide-tags.json", { with: { type: "json" } })
const c = g.catalog(tags, gemoji, ["activity", "dumbbell"])
const ids = (q: string, emoji = true, recent: string[] = [], current?: string) => g.sectionsFor(c, q, { emoji, current, recent }).map((s) => `${s.name}: ${s.items.slice(0, 4).map((x) => x.id).join(" ")}`)
const names = (q: string, emoji = true) => g.sectionsFor(c, q, { emoji }).map((s) => s.name)

check("glyphs: every Lucide icon and every emoji offered", c.icons.length === Object.keys(tags).length && c.emoji.length > 1800, [c.icons.length, c.emoji.length])
check("glyphs: the common icons first", c.icons[0].id === "activity" && c.icons[1].id === "dumbbell", c.icons.slice(0, 3).map((x) => x.id))
const browse = names("")
check("glyphs: with nothing typed, the icons then the emoji by group", browse[0] === "Icons" && browse[1] === "Smileys & Emotion" && browse.at(-1) === "Flags", browse)
check("glyphs: … the current and recent ones first, once each", ids("", true, ["book-open", "🥷"], "🥷")[0] === "Recent: 🥷 book-open", ids("", true, ["book-open", "🥷"], "🥷")[0])
check("glyphs: emoji off, none listed but the current one", names("", false).join() === "Icons" && ids("", false, ["🎉", "book-open"], "🥷")[0] === "Recent: 🥷 book-open", ids("", false, ["🎉", "book-open"], "🥷"))
check("glyphs: an emoji found by its name (ninja)", ids("ninja")[0]?.startsWith("Emoji: 🥷"), ids("ninja"))
check("glyphs: an emoji found by a word of its name or a tag", ids("grinning")[0]?.includes("😀") && g.sectionsFor(c, "happy", { emoji: true }).some((s) => s.items.some((x) => x.id === "😀")), [ids("grinning"), ids("happy")])
check("glyphs: the better kind first (heart: the icon is named so)", ids("heart")[0]?.startsWith("Icons: heart "), ids("heart"))
check("glyphs: words in any order (up arrow finds arrow-up)", g.sectionsFor(c, "up arrow", { emoji: false })[0]?.items.some((x) => x.id === "arrow-up"), ids("up arrow", false))
check("glyphs: emoji off, a search finds only icons", names("ninja", false).length === 0 && names("heart", false).join() === "Icons", [names("ninja", false), names("heart", false)])
check("glyphs: a colon asks for emoji only, even with them off", names(":heart", false).join() === "Emoji" && ids(":ninja:", false)[0]?.startsWith("Emoji: 🥷"), [names(":heart", false), ids(":ninja:", false)])
check("glyphs: a colon alone lists the emoji by group", names(":")[0] === "Smileys & Emotion" && !names(":").includes("Icons"), names(":"))
check("glyphs: an emoji typed is offered as itself, named when known", ids("🥷")[0] === "Emoji: 🥷" && g.glyphOf(c, "🥷").name === "ninja" && g.glyphOf(c, "❤").name === "red heart", [ids("🥷"), g.glyphOf(c, "❤")])
check("glyphs: one not known still offered (a plugin's icon, an emoji gemoji lacks)", g.glyphOf(c, "github").kind === "icon" && g.glyphOf(c, "🫨🫨").kind === "emoji")
check("glyphs: emoji told from text", g.isEmoji("🥷") && g.isEmoji("👍🏽") && g.isEmoji("🇯🇵") && !g.isEmoji("ninja") && !g.isEmoji("hi 🥷"))

type Layout = { flat: Glyph[]; lines: object[]; tops: Float64Array }
const grid: { layout(s: Section[], cols: number): Layout; moved(l: Layout, at: number, m: string, page?: number): number } = await web("core/glyphgrid.ts")
const mk = (n: number, group: string) => Array.from({ length: n }, (_, i) => ({ id: `${group}${i}`, kind: "icon" as const, name: `${group}${i}`, group }))
const l = grid.layout([{ name: "A", items: mk(7, "a") }, { name: "B", items: mk(5, "b") }], 3)
check("glyph grid: groups headed, cut into rows of the columns that fit", l.lines.length === 2 + 3 + 2 && l.flat.length === 12 && l.tops[2] === 30 + 44, [l.lines.length, l.tops])
const at = (m: string, from: number, page?: number) => l.flat[grid.moved(l, from, m, page)].id
check("glyph grid: Down keeps the column, into the next group, short rows clamp", at("down", 1) === "a4" && at("down", 4) === "a6" && at("down", 6) === "b0" && at("down", 5) === "a6", [at("down", 1), at("down", 4), at("down", 6), at("down", 5)])
check("glyph grid: Up back, Left and Right along, stopping at the ends", at("up", 7) === "a6" && at("left", 0) === "a0" && at("right", 11) === "b4" && at("right", 6) === "b0")
check("glyph grid: Tab to the next group's first, Shift+Tab to this one's then the one before", at("next-group", 2) === "b0" && at("previous-group", 9) === "b0" && at("previous-group", 7) === "a0")
check("glyph grid: a page down moves that many rows", at("page-down", 0, 2) === "a6" && at("page-down", 0, 9) === "b3")
