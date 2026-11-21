import fs from "node:fs"
import http from "node:http"
import path from "node:path"
import { WebSocket, WebSocketServer } from "ws"
import type { Any, VaultTest } from "../harness.ts"
import { portOf } from "../../../../core/listening.ts"

type Seen = { path: string; query: URLSearchParams; auth: string; config?: Any; chunks: number[] }
type Client = { ws: WebSocket; got: Any[]; status: number; closed: Promise<void> }
type Rig = { $: VaultTest; set: (data: Any) => Promise<void>; secrets: (patch: Any) => void; config: string; seen: Seen[]; mode: { now: string }
  connect: (token: string) => Promise<Client>; cloud: (q?: string) => Promise<Any> }

export async function relay($: VaultTest) {
  const settings = path.join($.VAULT, ".vaultite/plugins/dictation/data.json"), config = path.join(process.env.VAULTITE_LOCAL!, "config.json")
  let t = Date.now() / 1000 + 10
  const set = async (data: Any) => {
    fs.mkdirSync(path.dirname(settings), { recursive: true })
    fs.writeFileSync(settings, JSON.stringify(data))
    fs.utimesSync(settings, ++t, t)
    await $.vault.sync()
  }
  const secrets = (patch: Any) => {
    const all = fs.existsSync(config) ? JSON.parse(fs.readFileSync(config, "utf8")) : {}
    fs.mkdirSync(path.dirname(config), { recursive: true })
    fs.writeFileSync(config, JSON.stringify({ ...all, ...patch }))
  }
  const was = fs.existsSync(config) ? fs.readFileSync(config, "utf8") : null
  const mode = { now: "ok" }, seen: Seen[] = []
  const providers = await standIns(seen, mode), relay = await relayHost($)
  const env = envFor(`127.0.0.1:${portOf(providers.rest)}`)
  Object.assign(process.env, env)
  const rig: Rig = { $, set, secrets, config, seen, mode, connect: relay.connect, cloud: async (q = "") => (await $.api("GET", `dictation/cloud${q}`))[1] }
  try {
    await keys(rig)
    for (const id of Object.keys(STAND_INS)) await relayed(rig, id)
    await tokens(rig)
    await failures(rig)
    await phone(rig)
  } finally {
    fs.rmSync(settings, { force: true })
    if (was === null) fs.rmSync(config, { force: true }); else fs.writeFileSync(config, was)
    for (const k of Object.keys(env)) delete process.env[k]
    providers.close()
    relay.close()
  }
}

const envFor = (base: string) => ({ VAULTITE_SONIOX_API: `http://${base}/soniox`, VAULTITE_SONIOX_URL: "wss://soniox.example/stand-in",
  VAULTITE_DEEPGRAM_URL: `ws://${base}/deepgram`, VAULTITE_DEEPGRAM_API: `http://${base}/deepgram`, VAULTITE_ASSEMBLYAI_URL: `ws://${base}/assemblyai`,
  VAULTITE_ASSEMBLYAI_API: `http://${base}/assemblyai`, VAULTITE_OPENAI_REALTIME_URL: `ws://${base}/openai`, VAULTITE_ELEVENLABS_URL: `ws://${base}/elevenlabs` })

const GOOD = new Set(["Token dg-good-key", "aai-good-key", "Bearer good-key-123"])
async function standIns(seen: Seen[], mode: { now: string }) {
  const rest = http.createServer((req, res) => {
    const good = GOOD.has(String(req.headers.authorization ?? ""))
    if (new URL(req.url!, "http://x").pathname !== "/soniox/v1/auth/temporary-api-key") { res.statusCode = good ? 200 : 401; return res.end("{}") }
    res.statusCode = mode.now === "no-temp" ? 500 : good ? 201 : 401
    res.end(JSON.stringify(res.statusCode === 201 ? { api_key: "snx_temp_abc123", expires_at: "2026-11-17T12:00:00Z" } : {}))
  })
  const wss = new WebSocketServer({ noServer: true })
  rest.on("upgrade", (req, sock, head) => {
    const u = new URL(req.url!, "http://x")
    if (mode.now === "refuse") return sock.end("HTTP/1.1 401 Unauthorized\r\n\r\n")
    wss.handleUpgrade(req, sock, head, (ws) => {
      const s: Seen = { path: u.pathname, query: u.searchParams, auth: String(req.headers.authorization ?? req.headers["xi-api-key"] ?? ""), chunks: [] }
      seen.push(s)
      standIn(u.pathname.split("/")[1], ws, s, mode.now)
    })
  })
  await new Promise<void>((done) => rest.listen(0, "127.0.0.1", done))
  return { rest, close: () => { rest.close(); wss.close() } }
}

async function relayHost($: VaultTest) {
  const { matchSocket, HTTPError } = await import("../../../../core/plugins.ts")
  const host = http.createServer(), wss = new WebSocketServer({ noServer: true })
  host.on("upgrade", async (req, sock, head) => {
    const [, s] = matchSocket($.app.plugins, ["dictation", "live"])!, params = { wild: [], query: {} }
    try { await s.accept?.(req, params) } catch (e) { return sock.end(`HTTP/1.1 ${e instanceof HTTPError ? e.status : 500} No\r\n\r\n`) }
    wss.handleUpgrade(req, sock, head, (ws) => s.fn(ws, req, params))
  })
  await new Promise<void>((done) => host.listen(0, "127.0.0.1", done))
  const connect = (token: string) => new Promise<Client>((resolve) => {
    const ws = new WebSocket(`ws://127.0.0.1:${portOf(host)}/api/dictation/live`, { headers: { Authorization: `Bearer ${token}` } })
    const c: Client = { ws, got: [], status: 101, closed: new Promise((done) => ws.on("close", () => done())) }
    ws.on("message", (d) => c.got.push(JSON.parse(String(d))))
    ws.on("open", () => resolve(c))
    ws.on("unexpected-response", (_q, res) => resolve({ ...c, status: res.statusCode ?? 0 }))
    ws.on("error", () => resolve({ ...c, status: 0 }))
  })
  return { connect, close: () => { host.close(); wss.close() } }
}

const until = async ($: VaultTest, c: Client, ok: (got: Any[]) => boolean, ms = 4000) => { for (let i = 0; i < ms / 20 && !ok(c.got); i++) await $.sleep(20); return ok(c.got) }
const tokensOf = (got: Any[]): Any[] => got.flatMap((m) => m.tokens ?? [])
const isFin = (m: Any) => tokensOf([m]).some((x) => x.text === "<fin>")
const fins = (got: Any[]) => got.filter(isFin).length
const finalText = (got: Any[]) => tokensOf(got).flatMap((x) => (x.is_final && x.text !== "<fin>" ? [x.text] : [])).join("").trim()
const errorOf = (got: Any[]) => got.find((m) => m.error_code)
const speak = (c: Client, ms: number) => { for (let i = 0; i < ms / 10; i++) c.ws.send(Buffer.alloc(320)) }
const start = (c: Client) => c.ws.send(JSON.stringify({ model: "stt-rt-v6", audio_format: "pcm_s16le", sample_rate: 16000, num_channels: 1,
  language_hints: ["en", "pt"], context: { terms: ["Alice Park", "Lighthouse"] } }))
const finalize = (c: Client) => c.ws.send(JSON.stringify({ type: "finalize" }))

async function keys({ $, secrets, config }: Rig) {
  const key = async (body: Any) => (await $.api("POST", "ops/dictation.key", body))
  const [wrong, refused] = await key({ provider: "deepgram", key: "dg-wrong-key" })
  $.check("dictation key: a Deepgram key it refuses isn't kept", wrong === 400 && /Deepgram refused/.test(refused.error), refused)
  const [st] = await key({ provider: "deepgram", key: "dg-good-key" })
  const [, aai] = await key({ provider: "assemblyai", key: "aai-good-key" })
  const stored = JSON.parse(fs.readFileSync(config, "utf8")).dictation
  $.check("dictation key: Deepgram's and AssemblyAI's checked and kept beside each other", [st === 200, aai.checked === true, stored?.deepgram === "dg-good-key", stored?.assemblyai === "aai-good-key"].every(Boolean), stored)
  secrets({ companion: { openai: "sk-good-openai-key-0001", elevenlabs: "el-good-key-0000000001" } })
  const [est, el] = await key({ provider: "elevenlabs" })
  $.check("dictation key: ElevenLabs' is the companion's own, one key", est === 200 && el.set === true && el.provider === "elevenlabs", el)
}

async function relayed(rig: Rig, id: string) {
  const { $ } = rig
  await rig.set({ engine: id, languages: ["en", "pt"] })
  const c1 = await rig.cloud()
  $.check(`dictation cloud: ${id} is the relay, with a token for it, never its key`, [c1.provider === id, c1.url === "/api/dictation/live", /^[\w-]{30,}$/.test(c1.key),
    !["dg-good-key", "aai-good-key", "sk-good-openai-key-0001", "el-good-key-0000000001"].some((k) => JSON.stringify(c1).includes(k))].every(Boolean), { ...c1, terms: undefined })
  const c = await rig.connect(c1.key)
  start(c)
  finalize(c)
  const empty = await until($, c, (g) => fins(g) === 1, 500)
  speak(c, 500)
  await until($, c, (g) => tokensOf(g).some((x) => !x.is_final))
  c.ws.send(JSON.stringify({ type: "keepalive" }))
  finalize(c)
  await until($, c, (g) => fins(g) === 2)
  const fin = c.got.filter(isFin)[1]
  const pend = tokensOf(c.got).some((x) => !x.is_final && /segment/.test(x.text))
  $.check(`relay ${id}: a finalize with nothing said answers at once; words show pending, then settle before its <fin>, which says where the audio was`,
    [empty, pend, finalText(c.got) === "Segment 1.", tokensOf([fin]).some((x) => x.end_ms === 500)].every(Boolean), c.got)
  speak(c, 300)
  c.ws.send("")
  await until($, c, (g) => g.some((m) => m.finished))
  await Promise.race([c.closed, $.sleep(2000)])
  const s = rig.seen.at(-1)!
  $.check(`relay ${id}: the end's last words, then finished, and both sockets close`, [finalText(c.got) === "Segment 1. Segment 2.", c.got.at(-1)?.finished === true, c.ws.readyState === c.ws.CLOSED].every(Boolean), c.got.slice(-3))
  $.check(`relay ${id}: the provider is told its key, the languages and the words to expect`, standInOf(id).told(s), { auth: s.auth, query: s.query.toString(), config: s.config })
  const again = await rig.connect(c1.key)
  $.check(`relay ${id}: a token opens it once`, again.status === 401, again.status)
}

async function tokens(rig: Rig) {
  await rig.set({ engine: "deepgram" })
  const none = await rig.connect(""), madeUp = await rig.connect("x".repeat(32))
  const late = (await rig.cloud()).key, now = Date.now
  Date.now = () => now() + 61_000
  let stale: Client
  try { stale = await rig.connect(late) } finally { Date.now = now }
  rig.$.check("relay: no token, a made-up one or one past its minute is refused", [none, madeUp, stale].every((x) => x.status === 401), [none.status, madeUp.status, stale.status])
}

async function failing(rig: Rig, id: string, how: string) {
  await rig.set({ engine: id })
  rig.mode.now = how
  const c = await rig.connect((await rig.cloud()).key)
  start(c)
  speak(c, 200)
  if (how === "silent") finalize(c)
  await until(rig.$, c, (g) => g.some((m) => m.error_code || isFin(m)), 5000)
  await Promise.race([c.closed, rig.$.sleep(1000)])
  rig.mode.now = "ok"
  return c
}

async function failures(rig: Rig) {
  const { check } = rig.$
  for (const id of Object.keys(STAND_INS)) {
    const e = errorOf((await failing(rig, id, "error")).got)
    check(`relay ${id}: the provider's error is Soniox's error_code and error_message`, Number.isInteger(e?.error_code) && /Bad|Session limit/.test(e.error_message), e)
  }
  let c = await failing(rig, "openai", "drop")
  check("relay: the provider dropping mid-stream is an error, and the socket closes", /OpenAI's connection dropped/.test(errorOf(c.got)?.error_message) && c.ws.readyState === c.ws.CLOSED, c.got)
  c = await failing(rig, "elevenlabs", "refuse")
  check("relay: a key the provider refuses says so", errorOf(c.got)?.error_code === 401 && /ElevenLabs refused the key/.test(errorOf(c.got).error_message), c.got)
  c = await failing(rig, "deepgram", "silent")
  const both = c.got.some((m) => tokensOf([m]).some((x) => x.is_final && x.text.trim()) && tokensOf([m]).some((x) => !x.is_final))
  check("relay: no answer to a finalize in time, what showed settles (pending no more) and its <fin> comes", [finalText(c.got) === "segment", fins(c.got) === 1, !both].every(Boolean), c.got)
}

async function phone(rig: Rig) {
  const { $ } = rig
  rig.secrets({ dictation: { ...JSON.parse(fs.readFileSync(rig.config, "utf8")).dictation, soniox: "good-key-123" } })
  await rig.set({ engine: "auto", language: "pt-BR" })
  let p = await rig.cloud("?for=phone")
  const mac = await rig.cloud()
  $.check("dictation cloud: the phone gets a temporary Soniox key, the Mac this machine's, both its name and the language",
    [p.key === "snx_temp_abc123", p.url === "wss://soniox.example/stand-in", p.name === "Soniox", p.language === "pt-BR", mac.key === "good-key-123"].every(Boolean), { p: p.key, mac: mac.key })
  rig.mode.now = "no-temp"
  p = await rig.cloud("?for=phone")
  rig.mode.now = "ok"
  $.check("dictation cloud: no temporary key, the phone is told why and goes local", !p.url && !p.key && /temporary key/.test(p.why), p)
  await rig.set({ engine: "openai", phone: "iphone" })
  p = await rig.cloud("?for=phone")
  const macToo = await rig.cloud()
  $.check("dictation cloud: the iPhone's own set, the phone never gets the cloud (the Mac still does)", [!p.url, !p.key, !p.why, p.terms?.length > 0, macToo.url === "/api/dictation/live"].every(Boolean), p)
  await rig.set({ engine: "deepgram" })
  p = await rig.cloud("?for=phone")
  $.check("dictation cloud: the phone gets the relay too, named", p.url === "/api/dictation/live" && p.name === "Deepgram", p)
  const [, status] = await $.api("POST", "ops/companion.status", {})
  $.check("companion status: hears with the recognizer picked, when its key is here", status.voice?.hears === "deepgram", status.voice)
  await $.api("POST", "ops/dictation.key", { provider: "deepgram", remove: true })
  const left = JSON.parse(fs.readFileSync(rig.config, "utf8")).dictation
  p = await rig.cloud()
  $.check("dictation key --remove: only that provider's key goes; picked without it, why", [left?.soniox === "good-key-123", !left?.deepgram, !p.url, /No Deepgram key.*--provider deepgram/.test(p.why)].every(Boolean), { left: Object.keys(left ?? {}), p })
}

const OPENAI_BYTES = 38_400
type Turn = { send: (m: Any) => void; audio: number; m: Any; ms: number; n: () => number; state: { inTurn: boolean; item: number }; mode: string }

const deepgram = {
  told: (s: Seen) => [s.auth === "Token dg-good-key", s.query.get("language") === "multi", s.query.getAll("keyterm").join() === "Alice Park,Lighthouse", s.query.get("model") === "nova-3"].every(Boolean),
  error: (t: Turn) => t.send({ type: "Error", description: "Bad request" }),
  answer: (t: Turn) => {
    if (t.audio) t.send({ type: "Results", is_final: false, start: 0, duration: t.ms / 1000, channel: { alternatives: [{ transcript: "segment" }] } })
    if (t.m?.type === "Finalize" && t.mode !== "silent") t.send({ type: "Results", is_final: true, from_finalize: true, start: 0, duration: t.ms / 1000, channel: { alternatives: [{ transcript: `Segment ${t.n()}.` }] } })
  },
}
const assemblyai = {
  told: (s: Seen) => [s.auth === "aai-good-key", s.query.get("keyterms_prompt") === '["Alice Park","Lighthouse"]', Math.min(...s.chunks) >= 640, s.chunks.slice(0, -1).every((n) => n >= 1600)].every(Boolean),
  error: (_t: Turn, ws: WebSocket) => ws.close(3005, "Session limit reached"),
  answer: (t: Turn) => {
    if (t.audio) { t.state.inTurn = true; t.send({ type: "Turn", end_of_turn: false, transcript: "", words: [{ text: "segment", end: t.ms }] }) }
    if (t.m?.type !== "ForceEndpoint" || !t.state.inTurn) return
    t.state.inTurn = false
    t.send({ type: "Turn", end_of_turn: true, transcript: `Segment ${t.n()}.`, words: [{ text: "Segment", end: t.ms }] })
  },
}
const openai = {
  told: (s: Seen) => {
    const tr = s.config?.session?.audio?.input?.transcription ?? {}
    return [s.auth === "Bearer sk-good-openai-key-0001", s.query.get("intent") === "transcription", tr.model === "gpt-live-transcribe", tr.languages?.join() === "en,pt",
      tr.keywords?.join() === "Alice Park,Lighthouse", Math.abs(s.chunks.reduce((a, b) => a + b, 0) - OPENAI_BYTES) < 64].every(Boolean)
  },
  error: (t: Turn) => t.send({ type: "error", error: { code: "invalid_value", message: "Bad model" } }),
  answer: (t: Turn) => {
    const item_id = `item_${t.state.item}`
    if (t.audio && !t.state.inTurn) { t.state.inTurn = true; t.send({ type: "conversation.item.input_audio_transcription.delta", item_id, delta: " segment" }) }
    if (t.m?.type !== "input_audio_buffer.commit") return
    t.state.inTurn = false
    t.state.item++
    t.send({ type: "input_audio_buffer.committed", item_id })
    t.send({ type: "conversation.item.input_audio_transcription.completed", item_id, transcript: `Segment ${t.n()}.` })
  },
}
const elevenlabs = {
  told: (s: Seen) => [s.auth === "el-good-key-0000000001", s.query.get("language_code") === "en", s.query.getAll("secondary_languages").join() === "pt",
    s.query.getAll("keyterms").join() === "Alice Park,Lighthouse", s.query.get("commit_strategy") === "manual"].every(Boolean),
  error: (t: Turn) => t.send({ message_type: "input_error", error: "Bad audio" }),
  answer: (t: Turn) => {
    if (t.audio) t.send({ message_type: "partial_transcript", text: "segment" })
    if (t.m?.commit) t.send({ message_type: "committed_transcript", text: `Segment ${t.n()}.` })
  },
}
const STAND_INS = { deepgram, assemblyai, openai, elevenlabs }
const standInOf = (id: string) => Object.entries(STAND_INS).find(([k]) => k === id)![1]
const audioIn = (binary: boolean, d: Buffer, m: Any) => (binary ? d.length : Buffer.from(m?.audio ?? m?.audio_base_64 ?? "", "base64").length)

function standIn(id: string, ws: WebSocket, s: Seen, mode: string) {
  let bytes = 0, segments = 0
  const state = { inTurn: false, item: 1 }
  ws.on("error", () => {})
  ws.on("message", (d: Buffer, binary: boolean) => {
    const m = binary ? null : JSON.parse(String(d)), audio = audioIn(binary, d, m)
    if (m?.type === "session.update") s.config = m
    if (audio) { s.chunks.push(audio); bytes += audio }
    const t: Turn = { send: (x) => ws.send(JSON.stringify(x)), audio, m, ms: Math.round(bytes / 32), n: () => ++segments, state, mode }
    if (audio && mode === "drop") return ws.terminate()
    if (audio && mode === "error") return standInOf(id).error(t, ws)
    standInOf(id).answer(t)
  })
}
