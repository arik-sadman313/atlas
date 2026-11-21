import { isOutside } from "./fileprops.ts"

const full = (p: string): boolean => isOutside(p)

export function typedPath(typed: string): string | null {
  let t = typed.trim().replace(/^(["'])(.*)\1$/, "$2").trim()
  if (/^file:\/\//i.test(t)) {
    try {
      const u = new URL(t)
      if (u.host && u.host !== "localhost") return null
      t = decodeURIComponent(u.pathname).replace(/^\/([a-z]:\/)/i, "$1")
    } catch { return null }
  }
  if (!t || /[\n\r\0]/.test(t)) return null
  if (full(t) || /^~(?=$|[\\/])/.test(t)) return t
  if (/^[a-z][a-z0-9+.-]*:/i.test(t) || /^\.\.?([\\/]|$)/.test(t)) return null
  return t.includes("/") ? t : null
}

const plain = (p: string) => p.replace(/\\/g, "/").replace(/\/+$/, "")
const win = (p: string) => /^[a-z]:\//i.test(p)

export function inVault(path: string, root: string, home?: string): string | null {
  let p = plain(path)
  if (/^~(\/|$)/.test(p)) {
    if (!home) return null
    p = plain(home) + p.slice(1)
  }
  if (!full(p)) return p.replace(/^\.\//, "")
  const r = plain(root)
  if (!r) return null
  const same = (a: string, b: string) => (win(r) ? a.toLowerCase() === b.toLowerCase() : a === b)
  if (same(p, r)) return ""
  return same(p.slice(0, r.length + 1), `${r}/`) ? p.slice(r.length + 1) : null
}
