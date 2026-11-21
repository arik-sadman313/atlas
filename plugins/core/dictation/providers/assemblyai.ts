import { z } from "zod"
import { accepted, providerSocket, type Provider } from "./provider.ts"

const WS = () => process.env.VAULTITE_ASSEMBLYAI_URL || "wss://streaming.assemblyai.com"
const API = () => process.env.VAULTITE_ASSEMBLYAI_API || "https://api.assemblyai.com"
const MIN_CHUNK = 640, CHUNK = 1600

const Turn = z.object({
  type: z.literal("Turn"), end_of_turn: z.boolean().catch(false), transcript: z.string().catch(""),
  words: z.array(z.object({ text: z.string(), end: z.number().optional() })).catch([]),
})
const Failure = z.object({ type: z.literal("Error"), error: z.string().catch("error") })

export const assemblyai: Provider = {
  id: "assemblyai",
  name: "AssemblyAI",
  model: "assemblyai-stt-3-7-realtime",
  check: (key) => accepted(`${API()}/v2/transcript?limit=1`, { Authorization: key }),
  open({ key, model, terms }, heard) {
    const q = new URLSearchParams({ sample_rate: "16000", encoding: "pcm_s16le", speech_model: model })
    const keyterms = terms.filter((t) => t.length <= 50).slice(0, 100)
    if (keyterms.length) q.set("keyterms_prompt", JSON.stringify(keyterms))
    let unended = false, forcedSinceTurn = 0, held: Buffer[] = [], heldBytes = 0
    const out = (all: boolean) => {
      if (!heldBytes || (!all && heldBytes < CHUNK)) return
      s.send(Buffer.concat([...held, Buffer.alloc(Math.max(0, MIN_CHUNK - heldBytes))]))
      held = []; heldBytes = 0
    }
    const ended = (t: z.infer<typeof Turn>) => {
      unended = false
      if (t.transcript.trim()) heard.final(t.transcript.trim(), t.words.at(-1)?.end)
      heard.pending("")
      for (; forcedSinceTurn; forcedSinceTurn--) heard.flushed()
    }
    const s = providerSocket("AssemblyAI", `${WS()}/v3/ws?${q}`, { Authorization: key }, heard.failed, {
      schema: z.union([Turn, Failure]),
      message: (m) => {
        if (m.type === "Error") s.fail(502, `AssemblyAI: ${m.error}`)
        else if (m.end_of_turn) ended(m)
        else heard.pending(m.words.map((w) => w.text).join(" ") || m.transcript)
      },
    })
    return {
      audio: (pcm) => { unended = true; held.push(pcm); heldBytes += pcm.length; out(false) },
      flush: () => {
        out(true)
        if (!unended) return false
        forcedSinceTurn++
        s.send(JSON.stringify({ type: "ForceEndpoint" }))
        return true
      },
      keepalive: () => {},
      close: () => { s.send(JSON.stringify({ type: "Terminate" })); s.close() },
    }
  },
}
