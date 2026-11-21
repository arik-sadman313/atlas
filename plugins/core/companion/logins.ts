import { z } from "zod"

export const SignedIn = z.array(z.object({ name: z.string(), container: z.string().nullable(), home: z.boolean(),
  sites: z.array(z.object({ site: z.string(), account: z.string().optional() })) }))
const CHARS = 1500

export function loginsText(cs: z.infer<typeof SignedIn>) {
  const text = cs.filter((c) => c.sites.length).map((c) => `${c.name}${c.home || !c.container ? "" : ` (--container ${c.container})`}: `
    + c.sites.map((s) => (s.account ? `${s.site} as ${s.account}` : s.site)).join(", ")).join("; ")
  return text.length > CHARS ? `${text.slice(0, CHARS)}… (vau browser sites lists all)` : text
}
