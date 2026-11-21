const px = (v: string) => Number.parseFloat(v) || 0

export function styleRules(text: string, css: boolean): { at: number; rule: string }[] {
  if (!css) {
    let at = 0
    return text.split("\n").map((rule) => { const r = { at, rule }; at += rule.length + 1; return r })
  }
  const bare = text.replace(/\/\*[\s\S]*?\*\//g, (c) => c.replace(/[^\n]/g, " "))
  return [...bare.matchAll(/[^{};]*\{[^{}]*\}/g)].map((m) => ({ at: m.index + m[0].search(/\S/), rule: m[0] }))
}

const BARS = [/\bborder-l-(\d+(?:\.\d+)?)\b/g, /\bborder-l-\[(\d+(?:\.\d+)?)px\]/g, /\bborder-left(?:-width)?\s*:\s*(\d+(?:\.\d+)?)px/g,
  /\bborderLeft(?:Width)?\s*:\s*["'`](\d+(?:\.\d+)?)px/g, /\binset[\s_]+(\d+(?:\.\d+)?)px[\s_]+0(?:px)?[\s_]+0/g]

export function bentBar(rule: string): boolean {
  const bar = BARS.some((re) => [...rule.matchAll(re)].some((m) => px(m[1]) >= 2))
  return bar && roundsLeft(rule)
}

function roundsLeft(rule: string): boolean {
  const tw = [...rule.matchAll(/(?<![\w-])rounded(?:-(t|b|l|s|tl|bl|ss|es|r|e|tr|br|se|ee|none))?(?:-[\w[\].%()-]+)?(?![\w-])/g)]
  if (tw.some((m) => m[1] !== "r" && m[1] !== "e" && m[1] !== "tr" && m[1] !== "br" && m[1] !== "se" && m[1] !== "ee" && m[1] !== "none"
    && !/-(0|none)$/.test(m[0]))) return true
  for (const m of rule.matchAll(/\bborder-?[rR]adius\s*:\s*["'`]?([^;"'`}]+)/g)) {
    const v = m[1].split("/")[0].trim().split(/\s+/).map((r) => !/^0(px|%|em|rem)?$/.test(r))
    const [tl, bl] = v.length === 1 ? [v[0], v[0]] : v.length < 4 ? [v[0], v[1]] : [v[0], v[3]]
    if (tl || bl) return true
  }
  return false
}
