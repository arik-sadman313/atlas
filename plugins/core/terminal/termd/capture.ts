import type { Picture, Placement, Vt } from "../vt/vt.ts"
import { shrink } from "./kitty.ts"
import { encodePng } from "./png.ts"

const CELL = "&#1109742;"
const RUN = /<div style="([^"]*)">([^<]*)<\/div>/g
const MARK = /^\p{M}$/u
const MAX_PX_PER_CELL = { width: 16, height: 32 }
const PAGE_MAX = 8 << 20, KEPT = 8
const made = new Map<string, string>()

function blank(text: string) {
  let out = "", at = 0
  for (let i = text.indexOf(CELL); i >= 0; i = text.indexOf(CELL, at)) {
    out += `${text.slice(at, i)} `
    at = i + CELL.length
    for (let m = /^&#(\d+);/.exec(text.slice(at, at + 12)); m && MARK.test(String.fromCodePoint(Number(m[1]))); m = /^&#(\d+);/.exec(text.slice(at, at + 12))) at += m[0].length
  }
  return out + text.slice(at)
}

function idOf(style: string) {
  const rgb = /(?:^|;)color: rgb\((\d+), (\d+), (\d+)\)/.exec(style)
  if (rgb) return (Number(rgb[1]) << 16) | (Number(rgb[2]) << 8) | Number(rgb[3])
  const pal = /(?:^|;)color: var\(--vt-palette-(\d+)\)/.exec(style)
  return pal ? Number(pal[1]) : 0
}

function png(p: Picture, cols: number, rows: number) {
  const k = Math.max(1, Math.ceil(Math.max(p.width / (cols * MAX_PX_PER_CELL.width), p.height / (rows * MAX_PX_PER_CELL.height))))
  const key = `${p.id}:${p.generation}:${k}`
  let src = made.get(key)
  if (src) return src
  const ch = p.format === "rgba" ? 4 : p.format === "rgb" ? 3 : p.format === "gray_alpha" ? 2 : 1, out = ch === 2 || ch === 4 ? 4 : 3
  const s = shrink(p.data, p.width, p.height, ch, out, k)
  src = `data:image/png;base64,${encodePng({ ...s, channels: out }).toString("base64")}`
  made.set(key, src)
  for (const old of made.keys()) if (made.size > KEPT) made.delete(old)
  return src
}

type Shown = { line: number; lines: number; cells: number }

function image(t: Vt, id: number, at: Shown, placements: Placement[]) {
  const pl = placements.find((p) => p.virtual && p.image === id), p = t.picture(id)
  if (!p) return ""
  const cols = pl?.columns || pl?.gridColumns || at.cells, rows = pl?.rows || pl?.gridRows || at.lines
  const rowsCutOffAbove = at.line === 0 && at.lines < rows ? rows - at.lines : 0
  return `<span style="display: inline-block; position: relative; width: 0; height: 1lh; vertical-align: top;"><img alt="" src="${png(p, cols, rows)}" `
    + `data-cols="${cols}" data-rows="${rows}" data-up="${rowsCutOffAbove}" style="position: absolute; left: 0; top: calc(${-rowsCutOffAbove} * 1lh); width: ${cols}ch; `
    + `height: calc(${rows} * 1lh); max-width: none; object-fit: contain;"></span>`
}

export function htmlWithPictures(t: Vt, above: number): string {
  const html = t.html(above)
  if (!html.includes(CELL)) return html
  const runs: { m: RegExpExecArray; line: number; id: number }[] = []
  let line = 0, from = 0
  for (const m of html.matchAll(RUN)) {
    for (let i = html.indexOf("\n", from); i >= 0 && i < m.index; i = html.indexOf("\n", i + 1)) line++
    from = m.index
    if (m[2].includes(CELL)) runs.push({ m, line, id: idOf(m[1]) })
  }
  const shown = new Map<number, Shown>()
  for (const r of runs) {
    const s = shown.get(r.id)
    if (!s) shown.set(r.id, { line: r.line, lines: 1, cells: r.m[2].split(CELL).length - 1 })
    else if (r.line !== s.line + s.lines - 1) s.lines++
  }
  const placements = t.placements(), drawn = new Set<number>()
  let out = "", at = 0, sent = 0
  for (const r of runs) {
    out += html.slice(at, r.m.index)
    at = r.m.index + r.m[0].length
    let pic = ""
    if (r.id && !drawn.has(r.id) && sent < PAGE_MAX) { drawn.add(r.id); pic = image(t, r.id, shown.get(r.id)!, placements); sent += pic.length }
    const i = r.m[2].indexOf(CELL)
    out += `<div style="${r.m[1]}">${r.m[2].slice(0, i)}${pic}${blank(r.m[2].slice(i))}</div>`
  }
  return out + html.slice(at)
}
