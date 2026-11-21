// Where a page shows words now (the companion's marks, agent:find), as plugins/core/companion/locate.ts finds them in the
// app's own page. Run in the page (its source sent there), so it uses nothing from outside it.

/** Where the page shows `text` on screen: each place (viewport CSS px) with how well (3: an element named it; 2: its whole
 *  words; 1: inside longer words), shown and on top. */
export function findWords(text: string, visible: typeof shownPart) {
  const norm = (t: string) => t.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim(), want = norm(text), out: { x: number; y: number; w: number; h: number; q: number }[] = []
  if (!want) return out
  const onTop = (el: Element, r: DOMRect) => {
    if (!el.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })) return false
    const top = document.elementFromPoint(r.left + Math.min(r.width / 2, 12), r.top + r.height / 2)
    return !!top && (el.contains(top) || top.contains(el))
  }
  const add = (el: Element, r: DOMRect, q: number) => { const v = visible(el, r); if (v && onTop(el, v)) out.push({ x: v.left, y: v.top, w: v.width, h: v.height, q }) }
  for (const el of document.querySelectorAll("[aria-label], [title], img[alt], input[placeholder]")) {
    if ([el.getAttribute("aria-label"), el.getAttribute("title"), el.getAttribute("alt"), el.getAttribute("placeholder")].some((n) => n && norm(n) === want)) add(el, el.getBoundingClientRect(), 3)
  }
  // (each character's block: words across blocks are found only along one row, each just after the one before)
  let flat = "", block: Element | null = null, nb = 0
  const at: [Text, number][] = [], blocks: number[] = [], walk = document.createTreeWalker(document.body ?? document.documentElement, NodeFilter.SHOW_TEXT)
  for (let n = walk.nextNode(); n; n = walk.nextNode()) {
    const v = n.nodeValue ?? "", p = n.parentElement
    if (!(n instanceof Text) || !v.trim() || !p || p.closest("script, style, noscript, template")) continue
    const b = p.closest("p, div, li, dt, dd, td, th, tr, h1, h2, h3, h4, h5, h6, pre, blockquote, section, article, header, footer, nav, aside, main, figcaption, label, button, option, summary")
    if (b !== block) { nb++; if (flat && !flat.endsWith(" ")) { flat += " "; at.push([n, 0]); blocks.push(nb) } }
    block = b
    for (let i = 0; i < v.length; i++) {
      const c = v[i].toLowerCase()
      if (/[\p{L}\p{N}]/u.test(c)) { flat += c[0]; at.push([n, i]); blocks.push(nb) } else if (flat && !flat.endsWith(" ")) { flat += " "; at.push([n, i]); blocks.push(nb) }
    }
  }
  const letter = ([n, i]: [Text, number]) => { const r = document.createRange(); r.setStart(n, i); r.setEnd(n, Math.min(i + 1, n.length)); return r.getBoundingClientRect() }
  const oneRow = (i: number, end: number) => {
    for (let k = i + 1; k <= end; k++) {
      if (blocks[k] === blocks[k - 1]) continue
      let a = k - 1, b = k
      while (a > i && flat[a] === " ") a--
      while (b < end && flat[b] === " ") b++
      const x = letter(at[a]), y = letter(at[b]), h = Math.max(x.height, y.height, 1)
      if (Math.min(x.bottom, y.bottom) - Math.max(x.top, y.top) < Math.min(x.height, y.height) / 2 || y.left < x.left || y.left - x.right > 4 * h) return false
    }
    return true
  }
  for (let i = flat.indexOf(want), k = 0; i >= 0 && k < 40; i = flat.indexOf(want, i + 1), k++) {
    const whole = (i === 0 || flat[i - 1] === " ") && (i + want.length === flat.length || flat[i + want.length] === " ")
    if (!whole && want.length < 6) continue
    if (!oneRow(i, i + want.length - 1)) continue
    const range = document.createRange()
    range.setStart(at[i][0], at[i][1])
    range.setEnd(at[i + want.length - 1][0], at[i + want.length - 1][1] + 1)
    add(at[i][0].parentElement!, range.getBoundingClientRect(), whole ? 2 : 1)
  }
  return out.map((r) => ({ x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.w), h: Math.round(r.h), q: r.q }))
}

export function shownPart(el: Element, r: DOMRect): DOMRect | null {
  if (!(r.width > 0 && r.height > 0)) return null
  const v = { l: Math.max(r.left, 0), t: Math.max(r.top, 0), r: Math.min(r.right, innerWidth), b: Math.min(r.bottom, innerHeight) }
  const clip = (p: HTMLElement, s: CSSStyleDeclaration) => {
    const box = p.getBoundingClientRect(), x0 = box.left + p.clientLeft, y0 = box.top + p.clientTop
    if (s.overflowX !== "visible") Object.assign(v, { l: Math.max(v.l, x0), r: Math.min(v.r, x0 + p.clientWidth) })
    if (s.overflowY !== "visible") Object.assign(v, { t: Math.max(v.t, y0), b: Math.min(v.b, y0 + p.clientHeight) })
  }
  let pos = getComputedStyle(el).position
  for (let p = el.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
    const s = getComputedStyle(p)
    if (s.transform === "none" && (pos === "fixed" || (pos === "absolute" && s.position === "static"))) continue
    clip(p, s)
    pos = s.position === "absolute" || s.position === "fixed" ? s.position : "static"
  }
  const w = v.r - v.l, h = v.b - v.t
  return w > 0 && h > 0 && w * h >= (r.width * r.height) / 2 ? new DOMRect(v.l, v.t, w, h) : null
}
