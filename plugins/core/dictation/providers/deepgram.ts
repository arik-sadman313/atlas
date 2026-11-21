import { z } from "zod"
import { accepted, providerSocket, type Heard, type Provider } from "./provider.ts"

const WS = () => process.env.VAULTITE_DEEPGRAM_URL || "wss://api.deepgram.com"
const API = () => process.env.VAULTITE_DEEPGRAM_API || "https://api.deepgram.com"

const Results = z.object({
  type: z.literal("Results"), is_final: z.boolean().catch(false), from_finalize: z.boolean().catch(false),
  start: z.number().catch(0), duration: z.number().catch(0),
  channel: z.object({ alternatives: z.array(z.object({ transcript: z.string() })) }),
})
const Failure = z.object({ type: z.literal("Error"), description: z.string().catch("error") })
const Message = z.union([Results, Failure])

function results(r: z.infer<typeof Results>, heard: Heard) {
  const said = r.channel.alternatives[0]?.transcript.trim() ?? ""
  if (!r.is_final) return heard.pending(said)
  if (said) heard.final(said, Math.round((r.start + r.duration) * 1000))
  heard.pending("")
  if (r.from_finalize) heard.flushed()
}

export const deepgram: Provider = {
  id: "deepgram",
  name: "Deepgram",
  model: "nova-3",
  check: (key) => accepted(`${API()}/v1/projects`, { Authorization: `Token ${key}` }),
  open({ key, model, languages, terms }, heard) {
    const q = new URLSearchParams({ model, encoding: "linear16", sample_rate: "16000", channels: "1", interim_results: "true",
      punctuate: "true", smart_format: "true", language: languages.length === 1 ? languages[0] : "multi" })
    for (const t of terms) q.append("keyterm", t)
    const s = providerSocket("Deepgram", `${WS()}/v1/listen?${q}`, { Authorization: `Token ${key}` }, heard.failed, {
      schema: Message,
      message: (m) => (m.type === "Error" ? s.fail(502, `Deepgram: ${m.description}`) : results(m, heard)),
    })
    return {
      audio: (pcm) => s.send(pcm),
      flush: () => { s.send(JSON.stringify({ type: "Finalize" })); return true },
      keepalive: () => s.send(JSON.stringify({ type: "KeepAlive" })),
      close: s.close,
    }
  },
}
