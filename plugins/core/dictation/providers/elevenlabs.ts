import { z } from "zod"
import { providerSocket, type Provider } from "./provider.ts"

const WS = () => process.env.VAULTITE_ELEVENLABS_URL || "wss://api.elevenlabs.io"
const ENDS_STREAM = new Set(["error", "quota_exceeded", "unaccepted_terms", "rate_limited", "queue_overflow", "resource_exhausted",
  "session_time_limit_exceeded", "input_error", "invalid_request", "chunk_size_exceeded", "transcriber_error"])

const Message = z.looseObject({ message_type: z.string(), text: z.string().catch(""), error: z.string().optional().catch(undefined) })

export const elevenlabs: Provider = {
  id: "elevenlabs",
  name: "ElevenLabs",
  model: "scribe_v3_live",
  open({ key, model, languages, terms }, heard) {
    const q = new URLSearchParams({ model_id: model, audio_format: "pcm_16000", commit_strategy: "manual" })
    if (languages.length) q.set("language_code", languages[0])
    for (const l of languages.slice(1)) q.append("secondary_languages", l)
    for (const t of terms) q.append("keyterms", t)
    let uncommitted = 0, asked = 0
    const answered = () => { if (asked) { asked--; heard.flushed() } }
    const committed = (text: string) => { if (text.trim()) heard.final(text.trim()); heard.pending(""); answered() }
    const s = providerSocket("ElevenLabs", `${WS()}/v1/speech-to-text/realtime?${q}`, { "xi-api-key": key }, heard.failed, {
      schema: Message,
      message: (m) => {
        const type = m.message_type
        if (type === "partial_transcript") heard.pending(m.text.trim())
        else if (type === "committed_transcript") committed(m.text)
        else if (type === "commit_throttled") answered()
        else if (type === "auth_error") s.fail(401, "ElevenLabs refused the key")
        else if (ENDS_STREAM.has(type)) s.fail(502, `ElevenLabs: ${m.error ?? type.replace(/_/g, " ")}`)
      },
    })
    const chunk = (pcm: Buffer, commit: boolean) => s.send(JSON.stringify({ message_type: "input_audio_chunk", audio_base_64: pcm.toString("base64"), commit, sample_rate: 16_000 }))
    return {
      audio: (pcm) => { uncommitted += pcm.length; chunk(pcm, false) },
      flush: () => {
        if (!uncommitted) return false
        uncommitted = 0
        asked++
        chunk(Buffer.alloc(0), true)
        return true
      },
      keepalive: () => {},
      close: s.close,
    }
  },
}
