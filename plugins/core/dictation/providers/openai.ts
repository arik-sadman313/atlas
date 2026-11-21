import { z } from "zod"
import { resampler } from "../../../../core/desktop/pcm.ts"
import { providerSocket, type Heard, type Provider } from "./provider.ts"

const WS = () => process.env.VAULTITE_OPENAI_REALTIME_URL || "wss://api.openai.com/v1/realtime"
const LEAST_COMMIT_BYTES = 3200

const Event = z.looseObject({ type: z.string(), item_id: z.string().optional(), delta: z.string().catch(""), transcript: z.string().optional(),
  error: z.looseObject({ code: z.string().nullish(), message: z.string().nullish() }).optional() })
type Event = z.infer<typeof Event>

class Items {
  texts = new Map<string, string>()
  order: string[] = []
  whole = new Set<string>()
  unnamed = ""
  asked = 0
  heard: Heard
  constructor(heard: Heard) { this.heard = heard }

  shown() {
    const open = [...this.order.filter((id) => !this.whole.has(id)), ...[...this.texts.keys()].filter((id) => !this.order.includes(id))]
    this.heard.pending([...open.map((id) => this.texts.get(id) ?? ""), this.unnamed].join(" ").replace(/\s+/g, " ").trim())
  }
  answered() { if (this.asked) { this.asked--; this.heard.flushed() } }
  committed(id: string) {
    this.order.push(id)
    if (this.unnamed) { this.texts.set(id, `${this.texts.get(id) ?? ""}${this.unnamed}`); this.unnamed = "" }
    this.settle()
  }
  delta(id: string | undefined, delta: string) {
    if (id) this.texts.set(id, `${this.texts.get(id) ?? ""}${delta}`); else this.unnamed += delta
    this.shown()
  }
  done(id: string, transcript?: string) {
    if (transcript !== undefined) this.texts.set(id, transcript)
    this.whole.add(id)
    this.settle()
  }
  settle() {
    while (this.order.length && this.whole.has(this.order[0])) {
      const id = this.order.shift()!, t = this.texts.get(id)?.trim()
      this.texts.delete(id); this.whole.delete(id)
      if (t) this.heard.final(t)
      this.answered()
    }
    this.shown()
  }
}

const DONE = new Set(["conversation.item.input_audio_transcription.completed", "conversation.item.input_audio_transcription.failed"])
function heardEvent(e: Event, items: Items, fail: (code: number, why: string) => void) {
  if (e.type === "input_audio_buffer.committed" && e.item_id) return items.committed(e.item_id)
  if (e.type === "conversation.item.input_audio_transcription.delta") return items.delta(e.item_id, e.delta)
  if (DONE.has(e.type) && e.item_id) return items.done(e.item_id, e.transcript)
  if (e.type !== "error") return
  const code = e.error?.code
  if (code === "input_audio_buffer_commit_empty") items.answered()
  else if (code === "invalid_api_key") fail(401, "OpenAI refused the key")
  else fail(502, `OpenAI: ${e.error?.message ?? code ?? "error"}`)
}

type Transcription = { model: string; delay: string; languages?: string[]; keywords?: string[] }
function session(model: string, languages: string[], terms: string[]) {
  const keywords = terms.flatMap((t) => { const k = t.replace(/[<>\r\n]/g, " ").trim(); return k ? [k] : [] })
  const transcription: Transcription = { model, delay: "low" }
  if (languages.length) transcription.languages = languages
  if (keywords.length) transcription.keywords = keywords
  return { type: "session.update", session: { type: "transcription", audio: { input: { format: { type: "audio/pcm", rate: 24_000 }, turn_detection: null, transcription } } } }
}

export const openai: Provider = {
  id: "openai",
  name: "OpenAI",
  model: "gpt-live-transcribe",
  open({ key, model, languages, terms }, heard) {
    const rs = resampler(), items = new Items(heard)
    let uncommitted = 0
    const s = providerSocket("OpenAI", `${WS()}?intent=transcription`, { Authorization: `Bearer ${key}` }, heard.failed, {
      schema: Event,
      open: () => { s.send(JSON.stringify(session(model, languages, terms))) },
      message: (e) => heardEvent(e, items, s.fail),
    })
    return {
      audio: (pcm) => { uncommitted += pcm.length; s.send(JSON.stringify({ type: "input_audio_buffer.append", audio: rs(pcm).toString("base64") })) },
      flush: () => {
        if (uncommitted < LEAST_COMMIT_BYTES) return false
        uncommitted = 0
        items.asked++
        s.send(JSON.stringify({ type: "input_audio_buffer.commit" }))
        return true
      },
      keepalive: () => {},
      close: s.close,
    }
  },
}
