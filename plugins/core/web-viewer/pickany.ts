import { Box } from "lucide-react"
import { choose, dotIcon, notify } from "@vaultite"
import { colorOf, containerById, containers, setSiteRule } from "./containers"
import { ruleSiteOf } from "./where.ts"
import { hintsFor } from "./whose"

export async function pickAny(site: string, url: string, current: string | null | undefined, done: (id: string | null | undefined) => void) {
  const ids = [...containers().map((c) => c.id), null]
  const hints = await hintsFor(url, ids)
  const items = ids.map((id) => {
    const c = containerById(id), user = hints.get(id)
    return { id: id ?? "", label: c?.name ?? "No container", detail: user ? `Your login: ${user}` : undefined, icon: c ? dotIcon(colorOf(c)) : Box, hinted: !!user }
  }).sort((a, b) => Number(b.hinted) - Number(a.hinted))
  const ruleSite = ruleSiteOf(url)
  choose({
    title: "Open in", heading: `No container is signed in to ${site}. Sign in where?`, placeholder: "Open in…",
    items: items.map(({ hinted: _, ...it }) => it),
    current: current === undefined ? items.find((it) => it.detail)?.id : current ?? "",
    modHint: `to always open ${ruleSite} there`,
    onPick: (it, how) => {
      const id = it.id || null, c = containerById(id)
      if (how.mod && c) void setSiteRule(ruleSite, c.id).then(() => notify(`${ruleSite} opens in ${c.name} from now on`))
      done(id)
    },
    onDismiss: () => done(undefined),
  })
}

const SIGN_IN_PAGE = /(^|[./-])(log-?in|sign-?in|auth\w*|sso|accounts?)([./?#-]|$)/i
export const signInPage = (url: string) => { try { const u = new URL(url); return SIGN_IN_PAGE.test(u.hostname) || SIGN_IN_PAGE.test(u.pathname) } catch { return false } }
