import { z } from "zod"
import { OpError, type OpCtx, type Plugin, type Request } from "../../../core/plugins.ts"
import { grant, RELAY } from "./relay.ts"
import { deepgram } from "./providers/deepgram.ts"
import { assemblyai } from "./providers/assemblyai.ts"
import { openai } from "./providers/openai.ts"
import { elevenlabs } from "./providers/elevenlabs.ts"

const WS = () => process.env.VAULTITE_SONIOX_URL || "wss://stt-rt.soniox.com/transcribe-websocket"
const API = () => process.env.VAULTITE_SONIOX_API || "https://api.soniox.com"
const MODEL = "stt-rt-v6"
const RELAYED = [deepgram, assemblyai, openai, elevenlabs]
export const CLOUD = ["soniox", ...RELAYED.map((p) => p.id)]
const COMPANION_KEYS = new Set(["openai", "elevenlabs"])
const relayedOf = (id: string) => RELAYED.find((p) => p.id === id)
const nameOf = (id: string) => relayedOf(id)?.name ?? "Soniox"
export const setKey = (id: string) => `vau secret "${nameOf(id)} API key" | vau dictation key${id === "soniox" ? "" : ` --provider ${id}`}`
const cloudId = (v: string) => CLOUD.find((c) => c === v)

const Keys = z.record(z.string(), z.string().catch("")).catch({})
const Secrets = z.looseObject({ dictation: Keys.optional(), companion: Keys.optional() }).catch({})
const Temporary = z.object({ api_key: z.string() })
const KeySet = z.looseObject({ set: z.boolean(), removed: z.boolean().optional(), checked: z.boolean().optional() })

export type Expect = { terms: string[]; replacements: [string, string][]; keep: boolean }
type KeyResult = z.infer<typeof KeySet> & { provider: string }
type Answer = Expect & { language?: string; why?: string; provider?: string; name?: string; url?: string; key?: string; model?: string; languages?: string[] }

function keysOf(plugin: Plugin) {
  const all = () => Secrets.parse(plugin.secrets())
  const mine = () => all().dictation ?? {}
  const keyOf = (id: string) => ((COMPANION_KEYS.has(id) ? all().companion : mine())?.[id] ?? "").trim()
  return { mine, keyOf }
}

async function temporary(key: string): Promise<{ key: string } | { why: string }> {
  const r = await fetch(`${API()}/v1/auth/temporary-api-key`, { method: "POST", signal: AbortSignal.timeout(8000), headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ usage_type: "transcribe_websocket", expires_in_seconds: 60, single_use: true }) }).catch(() => null)
  const t = r?.ok ? Temporary.safeParse(await r.json().catch(() => null)).data : undefined
  if (t) return { key: t.api_key }
  return { why: r ? `Soniox gave no temporary key (it answered ${r.status})` : "Soniox can't be reached for a temporary key" }
}

const Languages = z.array(z.string().catch("")).catch([]).transform((ls) => ls.flatMap((l) => (l.trim() ? [l.trim()] : [])))

export function cloudParts(plugin: Plugin, expect: () => Expect) {
  const { mine, keyOf } = keysOf(plugin)
  const chosen = () => { const e = String(plugin.settings().engine ?? "auto"); return e === "auto" ? "soniox" : cloudId(e) }
  plugin.provide("dictation:hears", () => { const id = chosen(); return id && keyOf(id) ? id : "mac" })

  plugin.route("GET", "dictation/cloud", async (req: Request): Promise<Answer | Record<string, never>> => {
    await plugin.ownerOnly(req, "Dictation's key")
    if (plugin.isOff()) return {}
    const s = plugin.settings(), phone = req.query.for === "phone", id = chosen()
    const local: Answer = expect()
    const language = z.string().catch("").parse(s.language).trim()
    if (language) local.language = language
    if (!id || (phone && s.phone === "iphone")) return local
    const key = keyOf(id)
    if (!key) return (s.engine ?? "auto") === "auto" ? local : { ...local, why: `No ${nameOf(id)} key on this machine (${setKey(id)})` }
    const cloud = { ...local, provider: id, name: nameOf(id), languages: Languages.parse(s.languages) }
    const relayed = relayedOf(id)
    if (relayed) return { ...cloud, url: RELAY, key: grant(relayed, key), model: relayed.model }
    if (!phone) return { ...cloud, url: WS(), key, model: MODEL }
    const temp = await temporary(key)
    return "why" in temp ? { ...local, why: temp.why } : { ...cloud, url: WS(), key: temp.key, model: MODEL }
  }, { lock: false, sync: false })

  keyOp(plugin, mine, keyOf)
}

async function checked(id: string, k: string) {
  const relayed = relayedOf(id)
  if (relayed) return relayed.check?.(k) ?? null
  const r = await fetch(`${API()}/v1/models`, { headers: { Authorization: `Bearer ${k}` }, signal: AbortSignal.timeout(8000) }).catch(() => null)
  if (!r) return null
  return r.status === 401 || r.status === 403 ? false : r.ok || null
}

function keyText(r: KeyResult) {
  const name = nameOf(r.provider), uses = r.provider === "soniox" ? "dictation goes through Soniox" : `dictation uses it when the recognizer is ${name} (engine: ${r.provider})`
  if (r.removed) return `Removed the ${name} key${r.provider === "soniox" ? ": dictation is this Mac's" : ""}.`
  if (r.checked === undefined) return r.set ? `A ${name} key is set: ${uses}.` : `No ${name} key here: ${setKey(r.provider)}`
  return `Set the ${name} key${r.checked ? "" : ` (${name} didn't answer, so it isn't checked)`}: ${uses}.`
}

function keyOp(plugin: Plugin, mine: () => Record<string, string>, keyOf: (id: string) => string) {
  const companions = async (id: string, p: { key?: unknown; remove?: unknown }, ctx: OpCtx): Promise<KeyResult> =>
    ({ ...KeySet.parse(await ctx.op("companion.voice-key", { provider: id, key: p.key, remove: p.remove })), provider: id })
  plugin.op({
    id: "dictation.key",
    cli: "dictation key",
    mcp: false,
    owner: "Dictation's key",
    summary: "Set this machine's key for a cloud recognizer (Soniox's by default; Deepgram's, AssemblyAI's, OpenAI's or ElevenLabs'): dictation goes through the one the engine setting picks (this Mac's when it can't).",
    help: `Kept in this machine's data/config.json, never in the vault; checked with the provider first. OpenAI's and ElevenLabs'
are the companion's voice keys (vau voice key), one key each; Soniox's also gives the companion Soniox's voice. Pipe it in
from vau secret, so it never lands in a transcript. With nothing piped, says whether one is set.

  ${setKey("soniox")}
  ${setKey("deepgram")}
  vau dictation key --provider assemblyai --remove`,
    kind: "write",
    params: {
      key: { type: "string", stdin: true, description: "the API key (piped in when left out)" },
      provider: { type: "string", enum: CLOUD, default: "soniox", description: "whose key: soniox, deepgram, assemblyai, openai or elevenlabs" },
      remove: { type: "boolean", description: "remove the key" },
    },
    lock: false,
    run: async (p, ctx): Promise<KeyResult> => {
      if (ctx.who.client === "mcp") throw new OpError("not over MCP: keys stay on the user's machines (vau dictation key, in a terminal)", 403)
      const id = cloudId(String(p.provider ?? "")) ?? "soniox"
      if (COMPANION_KEYS.has(id)) return companions(id, p, ctx)
      const { [id]: _, ...rest } = mine()
      if (p.remove) { plugin.saveSecrets(Object.keys(rest).length ? rest : null); return { provider: id, set: false, removed: true } }
      const k = z.string().catch("").parse(p.key).trim()
      if (!k) return { provider: id, set: !!keyOf(id) }
      if (!/^[\x21-\x7e]{8,300}$/.test(k)) throw new OpError(`that isn't a ${nameOf(id)} key (one line, no spaces)`)
      const ok = await checked(id, k)
      if (ok === false) throw new OpError(`${nameOf(id)} refused this key: check it in ${nameOf(id)}'s console`, 400)
      plugin.saveSecrets({ ...rest, [id]: k })
      return { provider: id, set: true, checked: ok === true }
    },
    text: keyText,
    did: (p) => {
      const name = nameOf(cloudId(String(p.provider ?? "")) ?? "soniox")
      return { action: "settings", text: p.remove ? `Removed the ${name} key` : p.key ? `Set the ${name} key` : `Checked for a ${name} key` }
    },
  })
}
