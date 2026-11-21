import { agentContainers, serve } from "./browser/agent.ts"
import { logger } from "./browser/engine.ts"
import { codeFrom, mailOf, type Code } from "./signincodes.ts"
import { sitesOf } from "./webaccounts.ts"
import { readySession } from "./websession.ts"
import { siteOf } from "./webwire.ts"

const log = logger("mail codes")
const MAX_MINUTES = 60, MAX_ACCOUNTS = 5

type Found = Code & { container: string | null }

async function gmailOf(profile: string) {
  const google = (await sitesOf(profile)).find((s) => s.site === "google.com" && s.signed)
  return google ? Math.min(MAX_ACCOUNTS, 1 + (google.more?.length ?? 0)) : 0
}

async function feedOf(profile: string, account: number) {
  const s = await readySession(profile)
  const r = await s.fetch(`https://mail.google.com/mail/u/${account}/feed/atom`, { credentials: "include", signal: AbortSignal.timeout(10_000) }).catch(() => null)
  const text = r?.ok ? await r.text().catch(() => "") : ""
  if (text.includes("<feed")) return text
  log.warn(`Gmail's feed didn't answer in ${profile} (u/${account}): ${r?.status ?? "no answer"}`)
  return ""
}

serve("agent:code", async (_win, site, minutes) => {
  const want = siteOf(String(site ?? "").trim().toLowerCase().replace(/^https?:\/\//, "").split("/")[0])
  if (!want) throw new Error("name the site whose code you wait for (x.ai)")
  const since = Date.now() - Math.min(MAX_MINUTES, Math.max(1, Number(minutes) || 10)) * 60_000
  let gmail = false, newest: Found | null = null
  for (const c of agentContainers()) {
    const accounts = await gmailOf(c.profile)
    gmail ||= accounts > 0
    for (let u = 0; u < accounts; u++) {
      const code = codeFrom(mailOf(await feedOf(c.profile, u)), want, since)
      if (code && (!newest || code.at > newest.at)) newest = { ...code, container: c.profile.startsWith("c-") ? c.profile.slice(2) : null }
    }
  }
  if (!gmail) throw new Error("no container agents may read is signed in to Gmail: the user signs in to Google in one (vau browser sites lists them)")
  return newest
})
