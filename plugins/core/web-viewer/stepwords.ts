import { hostOf } from "./address"
import type { LiveStep } from "./livetabs"
import { pageOf, verbOf } from "./steps"

const FOLD = 3

export const quoted = (s: string) => `“${s.length > 60 ? `${s.slice(0, 59)}…` : s}”`
const SAY = new Map(Object.entries({
  open: () => "Opened this page", navigate: (s: LiveStep) => `Went to ${hostOf(s.value ?? s.url) || "a page"}`,
  form: (s: LiveStep) => (s.fields?.length ? `Filled ${s.fields.map(quoted).join(", ")}` : "Filled a form"),
  fill: (s: LiveStep) => `Typed in ${s.name ? quoted(s.name) : "a field"}`, type: (s: LiveStep) => `Typed in ${s.name ? quoted(s.name) : "a field"}`,
  press: (s: LiveStep) => `Pressed ${s.value || "a key"}`, scroll: (s: LiveStep) => `Scrolled ${s.value || "the page"}`,
  evaluate: () => "Ran a script in the page", run: () => "Ran a script of steps", help: (s: LiveStep) => (s.value ? `Asked you: ${s.value}` : "Asked you for help"),
  login: (s: LiveStep) => `Logged in${s.site ? ` to ${s.site}` : ""}${s.result ? `: ${s.result}` : ""}`, pdf: () => "Saved the page as a PDF",
  download: (s: LiveStep) => `Downloaded ${s.value ? hostOf(s.value) : "a file"}`, upload: (s: LiveStep) => `Uploaded ${s.value || "a file"}`,
}))
const TRY = new Map(Object.entries({ click: "click", dblclick: "double-click", hover: "point at", fill: "type in", type: "type in", press: "press",
  check: "check", uncheck: "uncheck", select: "pick", scroll: "scroll", upload: "upload", navigate: "go to the page", open: "open the page",
  evaluate: "run a script", run: "run a script of steps", login: "log in", read: "read the page", snapshot: "look at the page", screenshot: "take a picture",
  pdf: "save a PDF", download: "download", help: "ask you", wait: "wait", act: "act", paste: "paste" }))
export const CANT = /^the user can't do what you asked(?:: (.*?))?\. Go on another way/
export const quiet = (s: LiveStep) => s.action === "wait" && !!s.failed && /^waited \d+ s:/.test(s.failed)

export function phrase(s: LiveStep) {
  const cant = s.failed ? CANT.exec(s.failed) : null
  if (cant) return `You said you can't${cant[1] ? `: “${cant[1]}”` : ""}`
  if (s.failed) return `Couldn't ${TRY.get(s.action) ?? s.action}: ${s.failed}`
  const say = SAY.get(s.action)
  if (say) return say(s)
  return `${verbOf(s.action)} ${s.name ? quoted(s.name) : "something"}${s.value && s.action === "select" ? `: ${s.value}` : ""}`
}

type Row = { kind: "page"; url: string; title: string; key: string } | { kind: "steps"; steps: LiveStep[]; key: string }
export function rowsOf(steps: LiveStep[]): Row[] {
  const rows: Row[] = []
  let page = ""
  for (const s of steps) {
    if (quiet(s)) continue
    const p = pageOf(s.url)
    if (p !== page) { page = p; rows.push({ kind: "page", url: s.url, title: s.title, key: `p${s.t}` }) }
    const last = rows.at(-1)
    if (last?.kind === "steps" && !s.failed && !last.steps[0].failed && last.steps[0].action === s.action) last.steps.push(s)
    else rows.push({ kind: "steps", steps: [s], key: `s${s.t}` })
  }
  return rows.flatMap((r) => r.kind === "steps" && r.steps.length > 1 && r.steps.length < FOLD ? r.steps.map((s) => ({ kind: "steps" as const, steps: [s], key: `s${s.t}` })) : [r])
}
