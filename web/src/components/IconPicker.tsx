import { useEffect, useMemo, useRef, useState, type KeyboardEvent, type RefObject } from "react"
import { Blocks, Clock } from "lucide-react"
import { loadIconTags } from "@/core/icons"
import { ICONS } from "@/core/pages"
import { catalog, EMOJI_GROUPS, ICONS_GROUP, recentGlyphs, rememberGlyph, RECENT_GROUP, sectionsFor, type Catalog, type Glyph } from "@/core/glyphs"
import { CELL, layout, moved, useColumns, type Layout, type Move } from "@/core/glyphgrid"
import { usePrefs } from "@/core/prefs"
import { pickIcon, type IconAsk } from "@/core/iconask"
import { capitalize, cn } from "@/lib/utils"
import { Keys, NoMatches, PaletteFrame } from "@/components/Palette"
import { GlyphGrid, GlyphMark } from "@/components/GlyphGrid"

export default function IconPicker({ a }: { a: IconAsk }) {
  return <Picker key={a.title} a={a} onClose={() => { pickIcon(null); a.onClose?.() }} />
}

let made: Catalog | null = null, making: Promise<Catalog> | null = null
const loadCatalog = () => (making ??= Promise.all([loadIconTags(), import("gemoji")]).then(([tags, m]) => {
  const drawn = new Set<unknown>(), firstNameOfEach = Object.entries(ICONS).flatMap(([n, c]) => (drawn.has(c) ? [] : (drawn.add(c), [n])))
  return (made = catalog(tags, m.gemoji, firstNameOfEach))
}))
function useCatalog() {
  const [c, setC] = useState(made)
  useEffect(() => { if (!c) void loadCatalog().then(setC) }, [c])
  return c
}

const KEYS = new Map<string, Move>([["ArrowLeft", "left"], ["ArrowRight", "right"], ["ArrowUp", "up"], ["ArrowDown", "down"], ["PageUp", "page-up"], ["PageDown", "page-down"]])
const moveOf = (e: KeyboardEvent): Move | null =>
  e.altKey || e.metaKey ? null : KEYS.get(e.key) ?? (e.key === "Tab" ? (e.shiftKey ? "previous-group" : "next-group") : null)
const MARKS = new Map(EMOJI_GROUPS)

function Skeleton() {
  return (
    <div className="loading-in flex flex-wrap px-1.5" aria-busy>
      {Array.from({ length: 60 }, (_, i) => <span key={i} className="grid place-items-center" style={{ width: CELL, height: CELL }}><span className="skeleton size-[22px] rounded-[6px]" /></span>)}
    </div>
  )
}

function Jumps({ heads, shown, onJump }: { heads: { name: string }[]; shown: number; onJump: (k: number) => void }) {
  return (
    <div className="flex shrink-0 gap-0.5 overflow-x-auto border-b-[0.5px] border-border px-2 py-1.5 [scrollbar-width:none]" data-glyph-groups>
      {heads.map((h, k) => {
        const Icon = h.name === RECENT_GROUP ? Clock : h.name === ICONS_GROUP ? Blocks : null
        return (
          <button key={h.name} type="button" tabIndex={-1} aria-label={h.name} data-tip={h.name} aria-pressed={k === shown}
            onMouseDown={(e) => e.preventDefault()} onClick={() => onJump(k)}
            className={cn("grid size-8 shrink-0 cursor-pointer place-items-center rounded-[7px] text-muted-foreground hover:bg-foreground/[0.06] max-md:size-10",
              k === shown && "bg-foreground/[0.09] text-foreground")}>
            {Icon ? <Icon className="size-[17px]" strokeWidth={2} /> : <span className={cn("text-[17px] leading-none", k !== shown && "opacity-70 grayscale-[0.4]")}>{MARKS.get(h.name)}</span>}
          </button>
        )
      })}
    </div>
  )
}

function Hint({ keys, children }: { keys: string; children: string }) {
  return <span className="flex items-center gap-1 whitespace-nowrap"><Keys keys={keys} small />{children}</span>
}

function About({ g, current }: { g: Glyph | null; current?: string }) {
  const sub = !g ? "" : [g.kind === "emoji" ? (g.code ? `:${g.code}:` : "Emoji") : g.kind === "none" ? "No icon" : "Icon", g.id === current && "Current"].filter(Boolean).join(" · ")
  return (
    <div className="flex items-center gap-4 border-t-[0.5px] border-border py-2.5 pr-5 pl-3">
      <div className="flex min-w-0 flex-1 items-center gap-3" data-glyph-about aria-live="polite">
        <span className={cn("grid size-10 shrink-0 place-items-center rounded-[9px]", g && "bg-foreground/[0.06]")}>{g && <GlyphMark g={g} big />}</span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-[15px] leading-[20px] text-foreground" data-glyph-name>{g ? (g.kind === "icon" ? g.id : capitalize(g.name)) : " "}</span>
          <span className="block truncate text-[12px] leading-[16px] text-muted-foreground">{sub || " "}</span>
        </span>
      </div>
      <div className="hidden shrink-0 items-center gap-3 text-[12px] text-muted-foreground md:flex">
        <Hint keys="Tab">next group</Hint>
        <Hint keys="Enter">to pick</Hint>
        <Hint keys="Escape">to dismiss</Hint>
      </div>
    </div>
  )
}

const NONE = "\u0000none"
function useLayout(a: IconAsk, q: string, list: RefObject<HTMLDivElement | null>) {
  const c = useCatalog()
  const { iconPickerEmoji: emoji } = usePrefs()
  const [recent] = useState(recentGlyphs)
  const [none] = useState<Glyph | undefined>(() => a.noIcon && { id: NONE, kind: "none", name: a.noIcon.label, words: [], group: "", mark: a.noIcon.mark })
  const sections = useMemo(() => (c ? sectionsFor(c, q, { emoji, current: a.current, recent, none }) : []), [c, q, emoji, a.current, recent, none])
  const cols = useColumns(list)
  const l = useMemo(() => layout(sections, cols), [sections, cols])
  const empty = c ? <NoMatches what={emoji || q.trim().startsWith(":") ? "No icon or emoji matches" : "No icon matches"} query={q} /> : <Skeleton />
  return { l, emoji, empty }
}

function useSelection(l: Layout, q: string, current: string | undefined) {
  const [sel, setSel] = useState<number | null>(null)
  const [selFor, setSelFor] = useState(q)
  if (selFor !== q) { setSelFor(q); setSel(0) }
  const at = Math.min(sel ?? Math.max(0, l.flat.findIndex((g) => g.id === current)), Math.max(0, l.flat.length - 1))
  return { at, setSel, move: (move: Move, page: number) => setSel(moved(l, at, move, page)) }
}

function Picker({ a, onClose }: { a: IconAsk; onClose: () => void }) {
  const [q, setQ] = useState("")
  const list = useRef<HTMLDivElement>(null)
  const { l, emoji, empty } = useLayout(a, q, list)
  const current = a.current ?? (a.noIcon ? NONE : undefined)
  const { at, setSel, move } = useSelection(l, q, current)
  const [shown, setShown] = useState(0)
  const selected = l.flat[at] ?? null
  const pick = (i: number) => {
    const g = l.flat[i]
    if (!g) return
    onClose()
    if (g.kind === "none") { a.noIcon?.onPick(); return }
    rememberGlyph(g.id)
    a.onPick(g.id)
  }
  const jump = (k: number) => {
    const h = l.heads[k]
    if (!h) return
    setSel(h.first)
    setShown(k)
    list.current?.scrollTo({ top: l.tops[h.line] })
  }
  const onKey = (e: KeyboardEvent) => {
    const m = e.nativeEvent.isComposing ? null : moveOf(e)
    if (m) { e.preventDefault(); move(m, Math.max(1, Math.floor((list.current?.clientHeight ?? CELL) / CELL) - 1)) }
    else if (e.key === "Enter" && !e.nativeEvent.isComposing) { e.preventDefault(); pick(at) }
  }
  return (
    <PaletteFrame label={a.title} onClose={onClose} onKeyDown={(e) => { if (e.key === "Tab") e.preventDefault() }}>
      <div className="flex items-center gap-2 border-b-[0.5px] border-border pr-3 pl-5">
        <input autoFocus value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={onKey} placeholder={emoji ? "Search icons and emoji…" : "Search icons, or type : for emoji…"}
          autoComplete="off" autoCorrect="off" spellCheck={false} enterKeyHint="go" role="combobox" aria-expanded aria-controls="glyph-grid"
          aria-activedescendant={selected ? `glyph-${at}` : undefined} className="h-14 min-w-0 flex-1 bg-transparent text-[17px] outline-none placeholder:text-muted-foreground" />
      </div>
      {!q.trim() && l.heads.length > 1 && <Jumps heads={l.heads} shown={shown} onJump={jump} />}
      <GlyphGrid list={list} l={l} sel={at} current={current} label={a.title} onHover={setSel} onPick={pick} onShown={setShown} empty={empty} />
      <About g={selected} current={current} />
    </PaletteFrame>
  )
}
