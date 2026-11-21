// Cloud voices for the companion (voicelogic.ts' `Cloud`): ElevenLabs' and Soniox's real-time TTS. Another provider
// (Cartesia) is another function here giving the same `Cloud`, picked by `cloudVoice`.
import WebSocket from "ws"
import { z } from "zod"
import { type Cloud, type Made, RATE, type Timed } from "./voicelogic.ts"

/** How a cloud voice is reached: its provider's socket and key (the server's, never logged), the voice and its speed. */
export type CloudConfig = { provider: "soniox" | "elevenlabs"; url: string; key: string; model: string; voice: string; speed?: number }

export type CloudVoice = Cloud & {
  /** Its socket opened now, before the first piece (the Talk key pressed): the first audio comes sooner. */
  warm: () => void
  close: () => void
}

export function cloudVoice(c: CloudConfig): CloudVoice {
  return c.provider === "elevenlabs" ? elevenlabs(c) : soniox(c)
}

function closedWhy(code: number, reason: Buffer, error: string) {
  const said = String(reason ?? "").trim()
  return `the socket closed${code && code !== 1000 && code !== 1005 ? ` (${code}${said ? `: ${said}` : ""})` : ""}${error ? `: ${error}` : ""}`
}

const ElevenError = z.object({ detail: z.looseObject({ status: z.string().optional(), code: z.string().optional(), message: z.string().optional() }).optional().catch(undefined) })
function elevenWhy(status: number, d: z.infer<typeof ElevenError>["detail"]) {
  const what = /quota|credit/i.test(`${d?.status ?? d?.code} ${d?.message}`) ? "out of credits" : status === 401 || status === 403 ? "its key was refused"
    : status === 429 ? "too many requests" : `it answered ${status}`
  return d?.message ? `${what} (${d.message})` : what
}
/** ElevenLabs' socket ends a piece silently when its credits ran out: its HTTP API says why (null: it works now). */
export async function failedWhy(c: CloudConfig): Promise<string | null> {
  if (c.provider !== "elevenlabs") return null
  try {
    const r = await fetch(`${c.url.replace(/^ws/, "http").replace(/\/$/, "")}/v1/text-to-speech/${encodeURIComponent(c.voice)}?output_format=pcm_16000`, { method: "POST", signal: AbortSignal.timeout(5000),
      headers: { "xi-api-key": c.key, "Content-Type": "application/json" }, body: JSON.stringify({ text: ".", model_id: c.model }) })
    return r.ok ? null : elevenWhy(r.status, ElevenError.safeParse(await r.json().catch(() => null)).data?.detail)
  } catch { return null }
}

const KEEP_MS = 20_000, IDLE_MS = 90_000
/** ElevenLabs: a piece whose audio went this quiet (ms) has all of it; after its final word, untimed, this long. */
const QUIET_MS = 1000, FINAL_MS = 300
const quietFor = (x: { closed?: boolean; timed: Timed }) => (x.closed && !x.timed.chars.length ? FINAL_MS : QUIET_MS)

/** Soniox's TTS (docs.soniox.com/tts): one socket, a stream per piece (5 at most), its config then its text whole; its
 *  audio comes as base64 PCM with each character's timing. A keepalive between streams, closed a while after the last. */
function soniox(c: CloudConfig): CloudVoice {
  let ws: WebSocket | null = null, keep: ReturnType<typeof setInterval> | null = null, idle: ReturnType<typeof setTimeout> | null = null, sid = 0
  const streams = new Map<string, { to: Made; timed: Timed }>()
  const queued: string[] = []

  function open() {
    if (ws && ws.readyState <= WebSocket.OPEN) return ws
    const s = new WebSocket(c.url, { headers: { Authorization: `Bearer ${c.key}` }, handshakeTimeout: 4000 })
    ws = s
    let why = ""
    s.on("open", () => { for (const m of queued.splice(0)) s.send(m) })
    s.on("message", (d) => heard(String(d)))
    s.on("error", (e) => { why ||= e.message })
    s.on("close", (code, reason) => {
      if (ws !== s) return
      ws = null; queued.length = 0
      if (keep) { clearInterval(keep); keep = null }
      for (const [id, x] of streams) { streams.delete(id); x.to.fail(closedWhy(code, reason, why)) }
    })
    keep ??= setInterval(() => { if (!streams.size) send({ keep_alive: true }) }, KEEP_MS)
    keep.unref?.()
    return s
  }
  function send(m: object) {
    const s = open(), line = JSON.stringify(m)
    if (s.readyState === WebSocket.OPEN) s.send(line); else queued.push(line)
  }
  function rest() {
    if (idle) clearTimeout(idle)
    idle = setTimeout(() => { if (!streams.size) close() }, IDLE_MS)
    idle.unref?.()
  }
  function heard(d: string) {
    let m: { stream_id?: string; audio?: string; audio_end?: boolean; terminated?: boolean; error_code?: number; error_type?: string; error_message?: string
      timestamps?: { characters?: string[]; character_end_times_seconds?: number[] } }
    try { m = JSON.parse(d) } catch { return }
    const x = m.stream_id ? streams.get(m.stream_id) : undefined
    if (m.error_code || m.error_type) {
      const why = [`${m.error_type ?? "error"} ${m.error_code ?? ""}`.trim(), m.error_message].filter(Boolean).join(": ")
      // (one with no stream is the connection's: every stream fails)
      for (const [id, s] of m.stream_id ? (x ? [[m.stream_id, x] as const] : []) : [...streams]) { streams.delete(id); s.to.fail(why) }
      if (!streams.size) rest()
      return
    }
    if (!x) return
    if (m.timestamps?.characters && m.timestamps.character_end_times_seconds) { x.timed.chars.push(...m.timestamps.characters); x.timed.ends.push(...m.timestamps.character_end_times_seconds) }
    if (m.audio) x.to.audio(Buffer.from(m.audio, "base64"), x.timed)
    if (m.terminated) { streams.delete(m.stream_id!); x.to.end(); if (!streams.size) rest() }
  }
  function close() {
    if (keep) { clearInterval(keep); keep = null }
    if (idle) { clearTimeout(idle); idle = null }
    const s = ws
    ws = null; queued.length = 0
    for (const [id, x] of streams) { streams.delete(id); x.to.fail("closed") }
    s?.close()
  }
  return {
    make(p, to) {
      const id = `v${++sid}`
      streams.set(id, { to, timed: { chars: [], ends: [] } })
      if (idle) { clearTimeout(idle); idle = null }
      send({ stream_id: id, model: c.model, language: p.language, voice: c.voice, audio_format: "pcm_s16le", sample_rate: RATE, return_timestamps: true,
        ...(c.speed && c.speed !== 1 ? { speed: Math.min(1.3, Math.max(0.7, c.speed)) } : {}), client_reference_id: "vaultite-companion" })
      send({ stream_id: id, text: p.text, text_end: true })
      return () => { if (streams.delete(id)) { send({ stream_id: id, cancel: true }); if (!streams.size) rest() } }
    },
    warm() { open(); rest() },
    reset: close,
    close,
  }
}

/** ElevenLabs' multi-context socket (multi-stream-input): a context per piece, its text flushed, PCM at 24 kHz with each
 *  character's timing; it ends, its context closed, once those cover its text, else once its audio went quiet. */
function elevenlabs(c: CloudConfig): CloudVoice {
  let ws: WebSocket | null = null, idle: ReturnType<typeof setTimeout> | null = null, cid = 0
  type Stream = { to: Made; timed: Timed; bytes: number; letters: number; quiet?: ReturnType<typeof setTimeout>; closed?: boolean }
  const streams = new Map<string, Stream>()
  const queued: string[] = []
  const url = () => {
    const u = new URL(`${c.url.replace(/\/$/, "")}/v1/text-to-speech/${encodeURIComponent(c.voice)}/multi-stream-input`)
    u.searchParams.set("model_id", c.model)
    u.searchParams.set("output_format", `pcm_${RATE}`)
    u.searchParams.set("sync_alignment", "true")
    u.searchParams.set("inactivity_timeout", "120")
    return u.toString()
  }
  function open() {
    if (ws && ws.readyState <= WebSocket.OPEN) return ws
    const s = new WebSocket(url(), { headers: { "xi-api-key": c.key }, handshakeTimeout: 4000 })
    ws = s
    let why = ""
    s.on("open", () => { for (const m of queued.splice(0)) s.send(m) })
    s.on("message", (d) => heard(String(d)))
    s.on("error", (e) => { why ||= e.message })
    s.on("close", (code, reason) => {
      if (ws !== s) return
      ws = null; queued.length = 0
      for (const [id, x] of streams) { drop(id, x); x.to.fail(closedWhy(code, reason, why)) }
    })
    return s
  }
  function send(m: object) {
    const s = open(), line = JSON.stringify(m)
    if (s.readyState === WebSocket.OPEN) s.send(line); else queued.push(line)
  }
  function rest() {
    if (idle) clearTimeout(idle)
    idle = setTimeout(() => { if (!streams.size) close() }, IDLE_MS)
    idle.unref?.()
  }
  function drop(id: string, x: Stream) { clearTimeout(x.quiet); streams.delete(id); if (!streams.size) rest() }
  /** The piece ended, its context closed (closing it sooner can end its audio short). */
  function finish(id: string, x: Stream) {
    if (!x.closed) { x.closed = true; send({ context_id: id, close_context: true }) }
    drop(id, x)
    x.to.end()
  }
  /** No audio for `ms`, nor any waiting to be read (Node runs timers before a socket's reads): the piece ends. */
  function hush(id: string, x: Stream, ms: number) {
    clearTimeout(x.quiet)
    const quiet = setTimeout(() => setImmediate(() => { if (streams.get(id) === x && x.quiet === quiet) finish(id, x) }), ms)
    x.quiet = quiet
    quiet.unref?.()
  }
  function heard(d: string) {
    let m: { contextId?: string; audio?: string | null; isFinal?: boolean; error?: string; message?: string
      alignment?: { chars?: string[]; charStartTimesMs?: number[]; charDurationsMs?: number[] } | null }
    try { m = JSON.parse(d) } catch { return }
    const x = m.contextId ? streams.get(m.contextId) : undefined
    if (m.error) {
      const why = [String(m.error), m.message].filter(Boolean).join(": ")
      for (const [id, s] of m.contextId ? (x ? [[m.contextId, x] as const] : []) : [...streams]) { drop(id, s); s.to.fail(why) }
      return
    }
    if (!x) return
    const id = m.contextId!
    if (m.audio) {
      const pcm = Buffer.from(m.audio, "base64"), at = x.bytes / (RATE * 2), a = m.alignment
      if (a?.chars && a.charStartTimesMs && a.charDurationsMs) {
        x.timed.chars.push(...a.chars)
        x.timed.ends.push(...a.charStartTimesMs.map((t, i) => at + (t + (a.charDurationsMs![i] ?? 0)) / 1000))
      }
      x.bytes += pcm.length
      x.to.audio(pcm, x.timed)
      if (x.timed.chars.join("").replace(/\s/g, "").length >= x.letters) return finish(id, x)
      if (!m.isFinal) hush(id, x, quietFor(x))
    }
    // (its final word can come before its last audio, read late on a stalled machine: what still comes is said too)
    if (m.isFinal) { x.closed = true; hush(id, x, quietFor(x)) }
  }
  function close() {
    if (idle) { clearTimeout(idle); idle = null }
    const s = ws
    ws = null; queued.length = 0
    for (const [id, x] of streams) { drop(id, x); x.to.fail("closed") }
    if (s?.readyState === WebSocket.OPEN) s.send(JSON.stringify({ close_socket: true }))
    s?.close()
  }
  return {
    make(p, to) {
      const id = `v${++cid}`, x: Stream = { to, timed: { chars: [], ends: [] }, bytes: 0, letters: p.text.replace(/\s/g, "").length }
      streams.set(id, x)
      if (idle) { clearTimeout(idle); idle = null }
      send({ text: " ", context_id: id, ...(c.speed && c.speed !== 1 ? { voice_settings: { speed: Math.min(1.2, Math.max(0.7, c.speed)) } } : {}) })
      // (not closed with it: closed at once, its final word came after its first second of audio and the rest was lost)
      send({ text: `${p.text} `, context_id: id, flush: true })
      return () => { if (streams.get(id) !== x) return; drop(id, x); if (!x.closed) send({ context_id: id, close_context: true }) }
    },
    warm() { open(); rest() },
    reset: close,
    close,
  }
}
