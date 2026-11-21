export type Mail = { from: string; subject: string; summary: string; at: number }
export type Code = { code: string; from: string; subject: string; at: number }

const ENTITIES = new Map([["amp", "&"], ["lt", "<"], ["gt", ">"], ["quot", '"'], ["apos", "'"], ["nbsp", " "]])
const decode = (s: string) => s.replace(/&(#x[\da-f]+|#\d+|\w+);/gi, (m, e: string) => {
  if (e[0] === "#") { const n = e[1] === "x" || e[1] === "X" ? parseInt(e.slice(2), 16) : Number(e.slice(1)); return n >= 0 && n <= 0x10ffff ? String.fromCodePoint(n) : m }
  return ENTITIES.get(e.toLowerCase()) ?? m
})
const tag = (xml: string, name: string) => decode(new RegExp(`<${name}\\b[^>]*>([\\s\\S]*?)</${name}>`, "i").exec(xml)?.[1]?.trim() ?? "")

export function mailOf(feed: string): Mail[] {
  return [...feed.matchAll(/<entry\b[^>]*>([\s\S]*?)<\/entry>/gi)].map(([, e]) => ({
    from: tag(tag(e, "author"), "email").toLowerCase() || tag(e, "author").toLowerCase(),
    subject: tag(e, "title"), summary: tag(e, "summary"),
    at: Date.parse(tag(e, "issued") || tag(e, "modified")) || 0,
  })).sort((a, b) => b.at - a.at)
}

export const fromSite = (from: string, site: string) => { const d = from.split("@").pop() ?? ""; return site.includes(".") && (d === site || d.endsWith(`.${site}`)) }

const NEAR = /\b(code|passcode|pin|otp|one[- ]time|verification|verify|confirm\w*|sign[- ]?in|log[- ]?in)\b/i
export function codeIn(text: string): string | null {
  if (!NEAR.test(text)) return null
  for (const m of text.matchAll(/(?<![\w/.=-])(\d{3}[ -]\d{3}|[A-Z0-9]{4,8})(?![\w/.@-])/g)) {
    const c = m[1]
    if (!/\d/.test(c) || /^(19|20)\d\d$/.test(c)) continue
    return c.replace(/[ -]/g, "")
  }
  return null
}

export function codeFrom(mail: Mail[], site: string, since: number): Code | null {
  for (const m of mail) {
    if (m.at < since || !fromSite(m.from, site)) continue
    const code = codeIn(m.subject) ?? codeIn(m.summary)
    if (code) return { code, from: m.from, subject: m.subject, at: m.at }
  }
  return null
}
