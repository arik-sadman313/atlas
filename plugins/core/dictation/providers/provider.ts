import { type RawData, WebSocket } from "ws"
import type { z } from "zod"

export type Heard = {
  pending: (text: string) => void
  final: (text: string, endMs?: number) => void
  flushed: () => void
  failed: (code: number, message: string) => void
}
export type Stream = {
  audio: (pcm: Buffer) => void
  flush: () => boolean
  keepalive: () => void
  close: () => void
}
export type Options = { key: string; model: string; languages: string[]; terms: string[] }
export type Provider = {
  id: string
  name: string
  model: string
  check?: (key: string) => Promise<boolean | null>
  open: (o: Options, heard: Heard) => Stream
}

const refused = (status: number) => status === 401 || status === 403

export async function accepted(url: string, headers: Record<string, string>) {
  const r = await fetch(url, { headers, signal: AbortSignal.timeout(8000) }).catch(() => null)
  if (!r) return null
  return refused(r.status) ? false : r.ok || null
}

const text = (d: RawData) => (Array.isArray(d) ? Buffer.concat(d) : Buffer.isBuffer(d) ? d : Buffer.from(d)).toString()

export function providerSocket<T>(name: string, url: string, headers: Record<string, string>, failed: Heard["failed"],
  o: { schema: z.ZodType<T>; open?: () => void; message: (m: T) => void }) {
  const ws = new WebSocket(url, { headers, handshakeTimeout: 8000 })
  const early: (string | Buffer)[] = []
  let over = false, opened = false
  const fail = (code: number, why: string) => { if (over) return; over = true; ws.terminate(); failed(code, why) }
  ws.on("open", () => { opened = true; o.open?.(); for (const m of early.splice(0)) ws.send(m) })
  ws.on("unexpected-response", (_req, res) => {
    const s = res.statusCode ?? 0
    fail(refused(s) ? 401 : 502, refused(s) ? `${name} refused the key` : `${name} answered ${s}`)
  })
  ws.on("error", () => fail(503, opened ? `${name}'s connection dropped` : `${name} can't be reached`))
  ws.on("close", (_code, reason) => fail(503, reason.length ? `${name} closed the stream: ${reason.toString().slice(0, 200)}` : `${name}'s connection dropped`))
  ws.on("message", (d, binary) => {
    if (binary) return
    let m: z.ZodSafeParseResult<T>
    try { m = o.schema.safeParse(JSON.parse(text(d))) } catch { return }
    if (m.success) o.message(m.data)
  })
  return {
    send: (m: string | Buffer) => { if (over) return; if (ws.readyState === ws.OPEN) ws.send(m); else early.push(m) },
    fail,
    close: () => { if (over) return; over = true; if (ws.readyState === ws.CONNECTING) ws.terminate(); else ws.close() },
  }
}
