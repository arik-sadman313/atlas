import { diffLines } from "@vaultite"

/** A run of a version's note, drawn as one piece of Markdown: kept, added, taken out, or edited in place (its words
 *  marked with <ins> and <del>). */
export type Piece = { kind: "same" | "add" | "del" | "edit"; md: string }
export type Counts = { added: number; removed: number }

const FENCE = /^\s{0,3}(`{3,}|~{3,})/
const STARTS = /^(\s{0,3}#{1,6}\s|\s*([-*+]|\d+[.)])\s)/

/** A note's body in blocks (a paragraph, a list item, a heading, a whole table or code block), each with the blank lines
 *  after it, so joined they are the text again. */
export function blocksOf(md: string): string[] {
  const out: string[] = []
  let cur = "", fence: string | null = null, blank = false
  for (const line of md.split(/(?<=\n)/)) {
    const f = FENCE.exec(line)
    if (fence) { cur += line; if (f && f[1][0] === fence[0] && f[1].length >= fence.length) fence = null; continue }
    const empty = !line.trim()
    if (cur && !empty && (blank || f || STARTS.test(line))) { out.push(cur); cur = "" }
    if (f) fence = f[1]
    cur += line
    blank = empty
  }
  if (cur) out.push(cur)
  return out
}

const TOKENS = /\s+|[\p{L}\p{N}_'’]+|[^\s\p{L}\p{N}_]/gu
const tokensOf = (s: string) => s.match(TOKENS) ?? []
const SAFE = /^[\p{L}\p{N}_'’ .,;:?!"—–/%-]*$/u
const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;")
const wrapped = (tag: string, s: string) => s.replace(/^(\s*)(.*?)(\s*)$/su, (_, a: string, x: string, b: string) => `${a}<${tag}>${esc(x)}</${tag}>${b}`)

async function inline(was: string, now: string): Promise<{ md: string; counts: Counts } | null> {
  if (FENCE.test(was) || FENCE.test(now) || /^\s*\|/.test(now)) return null
  const a = tokensOf(was), b = tokensOf(now)
  const ops = await diffLines(a, b)
  let same = 0
  for (const [tag, i1, i2] of ops) if (tag === "equal") same += a.slice(i1, i2).join("").trim().length
  if (same < 0.4 * Math.max(was.trim().length, now.trim().length)) return null
  let md = ""
  const counts = { added: 0, removed: 0 }
  for (const [tag, i1, i2, j1, j2] of ops) {
    if (tag === "equal") { md += b.slice(j1, j2).join(""); continue }
    const del = a.slice(i1, i2).join(""), ins = b.slice(j1, j2).join("")
    for (const s of [del, ins]) if (s.includes("\n") || !SAFE.test(s)) return null
    if (/^\s*$/.test(md.split("\n").at(-1) ?? "") && /^[-*+\d]/.test(del + ins)) return null
    if (del.trim()) { md += wrapped("del", del); counts.removed++ }
    if (ins.trim()) { md += wrapped("ins", ins); counts.added++ }
    else md += ins
  }
  return { md, counts }
}

function push(out: Piece[], kind: Piece["kind"], md: string) {
  const last = out.at(-1)
  if (last && last.kind === kind && kind !== "edit") last.md += md
  else out.push({ kind, md })
}
const breakAfter = (md: string) => (md.endsWith("\n\n") ? md : md.endsWith("\n") ? `${md}\n` : `${md}\n\n`)

export async function changes(was: string, now: string): Promise<{ pieces: Piece[]; counts: Counts }> {
  const a = blocksOf(was), b = blocksOf(now)
  const key = (s: string) => s.trimEnd()
  const ops = await diffLines(a.map(key), b.map(key))
  const pieces: Piece[] = [], counts = { added: 0, removed: 0 }
  for (const [tag, i1, i2, j1, j2] of ops) {
    if (tag === "equal") { push(pieces, "same", b.slice(j1, j2).join("")); continue }
    const olds = a.slice(i1, i2), news = b.slice(j1, j2)
    const paired = olds.length === news.length ? await Promise.all(olds.map((o, k) => inline(o, news[k]))) : []
    if (paired.length && paired.every((p) => p)) {
      for (const p of paired) { push(pieces, "edit", p!.md); counts.added += p!.counts.added; counts.removed += p!.counts.removed }
      continue
    }
    if (olds.length) { push(pieces, "del", olds.map(breakAfter).join("")); counts.removed += olds.length }
    if (news.length) { push(pieces, "add", news.join("")); counts.added += news.length }
  }
  return { pieces, counts }
}
