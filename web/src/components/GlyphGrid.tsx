import { createElement, memo, useEffect, useLayoutEffect, useMemo, useRef, useState, type ReactNode, type RefObject } from "react"
import { namedIcon } from "@/core/pages"
import type { Glyph } from "@/core/glyphs"
import { CELL, HEAD, PAD, type Layout } from "@/core/glyphgrid"
import { useVirtual } from "@/core/virtual"
import { cn } from "@/lib/utils"

export function GlyphMark({ g, big = false }: { g: Glyph; big?: boolean }) {
  if (g.mark) return createElement(g.mark, { className: big ? "size-6" : "size-[22px]" })
  if (g.kind === "emoji") return <span className={cn("leading-none", big ? "text-[26px]" : "text-[24px]")} aria-hidden>{g.id}</span>
  const icon = namedIcon(g.id)
  return icon && createElement(icon, { className: big ? "size-6" : "size-[22px]", strokeWidth: big ? 1.75 : 2 })
}

type Hands = { hover: (i: number) => void; pick: (i: number) => void }
const Row = memo(function Row({ index, items, start, sel, current, hands }: { index: number; items: Glyph[]; start: number; sel: number; current?: string; hands: Hands }) {
  return (
    <div data-vi={index} role="presentation" className="flex px-1.5" style={{ height: CELL }}>
      {items.map((g, j) => (
        <button key={g.id} id={`glyph-${start + j}`} type="button" role="option" aria-selected={sel === j} aria-label={g.kind === "icon" ? g.id : g.name}
          data-glyph={g.id} data-glyph-none={g.kind === "none" || undefined} data-i={start + j} tabIndex={-1} onMouseMove={() => hands.hover(start + j)} onClick={() => hands.pick(start + j)}
          className={cn("grid shrink-0 cursor-pointer place-items-center rounded-[8px] text-foreground/90", sel === j && "bg-foreground/[0.09] text-foreground",
            g.id === current && "ring-[1.5px] ring-primary/70 ring-inset")}
          style={{ width: CELL, height: CELL }}>
          <GlyphMark g={g} />
        </button>
      ))}
    </div>
  )
})

function Head({ index, name }: { index: number; name: string }) {
  return <div data-vi={index} role="presentation" className="flex items-end px-3 pb-1 text-[12px] font-semibold text-muted-foreground" style={{ height: HEAD }}>{name}</div>
}

export function GlyphGrid({ list, l, sel, current, label, onHover, onPick, onShown, empty }: {
  list: RefObject<HTMLDivElement | null>; l: Layout; sel: number; current?: string; label: string
  onHover: (i: number) => void; onPick: (i: number) => void; onShown: (head: number) => void; empty: ReactNode
}) {
  const keys = useMemo(() => l.lines.map((x) => x.key), [l])
  const v = useVirtual(list, keys, { estimate: CELL, keep: [keys[l.lineOf[sel]]], overscan: 400 })
  const hands = useRef<Hands & { sel: number }>({ hover: onHover, pick: onPick, sel })
  const pointed = useRef(false)
  useLayoutEffect(() => { hands.current = { hover: onHover, pick: onPick, sel } })
  const [stable] = useState<Hands>(() => ({
    hover: (i) => { if (i !== hands.current.sel) { pointed.current = true; hands.current.hover(i) } },
    pick: (i) => hands.current.pick(i),
  }))
  useEffect(() => {
    const el = list.current, line = l.lineOf[sel], byPointer = pointed.current
    pointed.current = false
    if (!el || !l.flat.length || line === undefined || byPointer) return
    const top = l.tops[line] - (l.lines[line - 1] && "head" in l.lines[line - 1] ? HEAD : 0), bottom = l.tops[line + 1] + 2 * PAD
    if (top < el.scrollTop) el.scrollTo({ top })
    else if (bottom > el.scrollTop + el.clientHeight) el.scrollTo({ top: bottom - el.clientHeight })
  }, [sel, l, list])
  const onScroll = () => {
    const el = list.current
    if (el) onShown(Math.max(0, l.heads.findLastIndex((h) => l.tops[h.line] <= el.scrollTop + 4)))
  }
  const out: ReactNode[] = []
  for (const { index, gap } of v.slots) {
    const x = l.lines[index]
    if (gap > 0.5) out.push(<div key={`gap${index}`} aria-hidden style={{ height: gap }} />)
    out.push("head" in x ? <Head key={x.key} index={index} name={x.head} />
      : <Row key={x.key} index={index} items={x.items} start={x.start} sel={l.lineOf[sel] === index ? sel - x.start : -1} current={current} hands={stable} />)
  }
  if (v.rest > 0.5) out.push(<div key="rest" aria-hidden style={{ height: v.rest }} />)
  return (
    <div ref={list} id="glyph-grid" role="listbox" aria-label={label} onScroll={onScroll}
      className="h-[min(408px,46dvh)] min-h-0 shrink overflow-y-auto overscroll-contain" style={{ padding: `${PAD}px 0` }}>
      {l.flat.length ? out : empty}
    </div>
  )
}
