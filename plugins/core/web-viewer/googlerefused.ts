import { notify, webPages, type WebSite } from "@vaultite"
import { allLogins, isIn, moveLogin, nameOf, type Logins } from "./loginsets"

const REFUSED = /^https:\/\/accounts\.google\.com\/(v3\/)?signin\/rejected\b/
const told = new Set<number>()

export const refusedByGoogle = (url: string) => REFUSED.test(url)

export function retryOf(url: string) {
  try {
    const to = new URL(url).searchParams.get("continue") ?? ""
    return /^https:\/\//i.test(to) ? to : "https://accounts.google.com/"
  } catch { return "https://accounts.google.com/" }
}

async function signedInElsewhere(here: Logins): Promise<{ from: Logins; site: WebSite } | null> {
  for (const from of allLogins()) {
    if (from.prof === here.prof || !webPages?.sites) continue
    const site = (await webPages.sites(from.prof).catch(() => [])).find((s) => s.site === "google.com" && isIn(s))
    if (site) return { from, site }
  }
  return null
}

export async function googleRefused(id: number, url: string, container: string | null) {
  if (!refusedByGoogle(url)) { told.delete(id); return }
  if (told.has(id)) return
  told.add(id)
  const here = allLogins().find((l) => l.container === container)
  if (!here) return
  const found = await signedInElsewhere(here), these = here.container ? here.name : "these logins"
  if (!found) {
    notify(`Google doesn't trust ${these} yet. Sign in to Google in another container or on another Mac, then copy that login here from Sites.`, { duration: 20_000 })
    return
  }
  const { from, site } = found
  notify(`Google doesn't trust ${these} yet. Copy your Google login from ${nameOf(from)} and try again?`, {
    duration: 30_000,
    action: { label: "Copy and retry", run: async () => { if (await moveLogin(from, here, site, true, { quiet: true }) === "moved") await webPages?.go(id, "load", retryOf(url)) } },
  })
}
