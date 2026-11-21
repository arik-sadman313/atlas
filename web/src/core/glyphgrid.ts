import { useLayoutEffect, useState, type RefObject } from "react"
import type { Glyph, Section } from "./glyphs.ts"

export const CELL = 44, HEAD = 30, PAD = 6

type Line = { key: string; head: string } | { key: string; start: number; items: Glyph[] }
type Head = { name: string; line: number; first: number }
export type Layout = { lines: Line[]; flat: Glyph[]; lineOf: Int32Array; tops: Float64Array; heads: Head[] }

export function layout(sections: readonly Section[], cols: number): Layout {
  const lines: Line[] = [], flat: Glyph[] = [], heads: Head[] = []
  sections.forEach((s, k) => {
    heads.push({ name: s.name, line: lines.length, first: flat.length })
    if (sections.length > 1) lines.push({ key: `h${k}`, head: s.name })
    for (let r = 0; r < s.items.length; r += cols) {
      lines.push({ key: `${k}:${r}`, start: flat.length, items: s.items.slice(r, r + cols) })
      flat.push(...s.items.slice(r, r + cols))
    }
  })
  const lineOf = new Int32Array(flat.length), tops = new Float64Array(lines.length + 1)
  lines.forEach((l, i) => {
    tops[i + 1] = tops[i] + ("items" in l ? CELL : HEAD)
    if ("items" in l) for (let j = 0; j < l.items.length; j++) lineOf[l.start + j] = i
  })
  return { lines, flat, lineOf, tops, heads }
}

export type Move = "left" | "right" | "up" | "down" | "page-up" | "page-down" | "next-group" | "previous-group"

function toGroup(l: Layout, at: number, next: boolean) {
  const k = l.heads.findLastIndex((h) => h.first <= at)
  const h = next ? l.heads[k + 1] : at > l.heads[k].first ? l.heads[k] : l.heads[k - 1]
  return h ? h.first : at
}

function toRow(l: Layout, at: number, step: 1 | -1, rows: number) {
  let line = l.lineOf[at], left = rows
  const row = l.lines[line], col = "items" in row ? at - row.start : 0
  for (let i = line + step; i >= 0 && i < l.lines.length && left > 0; i += step) {
    if ("items" in l.lines[i]) { line = i; left-- }
  }
  const to = l.lines[line]
  return "items" in to ? to.start + Math.min(col, to.items.length - 1) : at
}

export function moved(l: Layout, at: number, move: Move, page = 1): number {
  const last = l.flat.length - 1
  if (last < 0) return 0
  switch (move) {
    case "left": return Math.max(0, at - 1)
    case "right": return Math.min(last, at + 1)
    case "next-group": case "previous-group": return toGroup(l, at, move === "next-group")
    case "up": return toRow(l, at, -1, 1)
    case "down": return toRow(l, at, 1, 1)
    case "page-up": return toRow(l, at, -1, page)
    case "page-down": return toRow(l, at, 1, page)
  }
}

export function useColumns(list: RefObject<HTMLElement | null>) {
  const [cols, setCols] = useState(1)
  useLayoutEffect(() => {
    const el = list.current
    if (!el) return
    const fit = () => setCols(Math.max(1, Math.floor((el.clientWidth - 2 * PAD) / CELL)))
    const ro = new ResizeObserver(fit)
    ro.observe(el)
    fit()
    return () => ro.disconnect()
  }, [list])
  return cols
}
