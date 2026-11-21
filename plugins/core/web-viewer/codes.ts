import { z } from "zod"
import { OpError, type Plugin } from "../../../core/plugins.ts"

const CODE = z.object({ code: z.string(), from: z.string(), subject: z.string(), at: z.number(), container: z.string().nullable() }).nullable()
type Code = z.infer<typeof CODE>

export function signInCodes(plugin: Plugin) {
  plugin.op({
    id: "web-viewer.code",
    cli: "browser code",
    mcp: "browser_code",
    summary: "The sign-in or verification code a site just mailed the user, read from their Gmail, for a sign-in you're doing.",
    help: `Read from Gmail signed in in a browser container agents may read (vau browser sites), through Gmail's feed of
unread mail: nothing is opened or marked read. Only mail from the site's own domain, sent in the last --minutes (10;
60 at most), and only its code, sender, subject and time: never the mail's text. Ask for the code to be sent first,
then run this (again, a few seconds on, while the mail hasn't come); type it with browser act, or browser login when
the user's passwords for agents have the site's one-time code. A sign-in link instead of a code: ask the user.

  vau browser code x.ai
  vau browser code github.com --minutes 5`,
    kind: "read",
    params: {
      site: { type: "string", required: true, description: "the site that sent the code (x.ai): only its mail is read" },
      minutes: { type: "integer", default: 10, description: "how recent (at most 60)" },
    },
    args: ["site"],
    run: async (p) => {
      try { return CODE.parse(await plugin.desktopWaiting(0, "agent:code", p.site, p.minutes)) } catch (e) { throw new OpError(e instanceof Error ? e.message : String(e), 409) }
    },
    text: (c: Code) => (c ? `${c.code}\nFrom ${c.from}, ${new Date(c.at).toISOString()}: ${c.subject}` : "No code from that site in the unread mail yet: run it again in a few seconds."),
  })
}
