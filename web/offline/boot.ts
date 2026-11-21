// The iPhone app's offline app (vaultite-local://app/offline.html, App/LocalScheme.swift), main.tsx's first import: the
// phone's copy of the vault loaded into Vaultite's server in a worker (worker.ts), which answers what the shell passes on.
import { phoneLocal } from "@/core/phoneapp"
import { previewPath } from "@/core/phonesync"
import { kindOf } from "../../core/syncengine.ts"
import { getStarterFiles } from "./starter.ts"

const vault = new URLSearchParams(location.search).get("vault") || "Atlas"
/** A copy synced from shadow mode: kept for testing only, so nothing typed here is kept (it would never reach the vault). */
const testing = vault.endsWith("-shadow")
function opened() {
  if (!phoneLocal || !/^[A-Za-z0-9-]{1,80}$/.test(vault)) throw new Error("the offline app opens from the iPhone app, on a vault's copy")
  return phoneLocal
}
const local = opened()

const b64 = (u: Uint8Array) => { let s = ""; for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode(...u.subarray(i, i + 0x8000)); return btoa(s) }
const unb64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))
/** In the server's memory: text and settings, and small files; the rest stays a file the shell serves. */
const inMemory = (path: string, size: number) => kindOf(path) !== "binary" || size < 64 << 10

const server = new Worker(new URL("./worker.ts", import.meta.url), { type: "module" })
const ready = new Promise<void>((ok, no) => {
  server.addEventListener("message", (e) => { if (e.data.type === "ready") ok(); else if (e.data.type === "failed") no(new Error(e.data.error)) })
})

// What the app wrote, into the container (one write after another).
let writing: Promise<unknown> = Promise.resolve()
server.addEventListener("message", (e) => {
  if (e.data.type !== "wrote") return
  for (const f of e.data.files as { path: string; data: Uint8Array | null }[]) {
    writing = writing.then((): Promise<unknown> => (f.data ? local.write({ area: "vault", vault, path: f.path, data: b64(f.data) }) : local.remove({ area: "vault", vault, path: f.path }))).catch(() => {})
  }
})

// The copy, read in batches of a few MB (the bridge carries base64).
const { files } = await local.list({ area: "vault", vault })
const out: { path: string; data: Uint8Array | null; mtime: number }[] = [], stat = new Map(files.map((f) => [f.path, f]))
const want = files.filter((f) => inMemory(f.path, f.size))
for (let i = 0; i < want.length;) {
  const part: string[] = []
  for (let n = 0; i < want.length && (n < 4 << 20 || !part.length); i++) { part.push(want[i].path); n += want[i].size }
  const got = (await local.read({ area: "vault", vault, paths: part })).files
  for (const p of part) out.push({ path: p, data: got[p] != null ? unb64(got[p]!) : new Uint8Array(), mtime: stat.get(p)!.mtime })
}
for (const f of files) if (!inMemory(f.path, f.size)) out.push({ path: f.path, data: null, mtime: f.mtime })
if (files.length === 0) {
  const starter = getStarterFiles()
  for (const [p, content] of Object.entries(starter)) {
    const bytes = new TextEncoder().encode(content)
    out.push({ path: p, data: bytes, mtime: Date.now() })
    void local.write({ area: "vault", vault, path: p, data: b64(bytes) }).catch(() => {})
  }
}
// (media only on the hub: there by name, so notes link to it; its preview answers for it)
const index = await local.read({ area: "sync", vault, paths: ["previews/index.json"] }).then((r) => JSON.parse(atob(r.files["previews/index.json"] ?? "") || "{}") as Record<string, string>, () => ({}))
for (const p of Object.keys(index)) if (!stat.has(p)) out.push({ path: p, data: null, mtime: 0 })
server.postMessage({ type: "files", files: out, keep: !testing })

type Forwarded = { id: string; method: string; url: string; headers: Record<string, string>; body: string | null }
/** A request the shell passed on: an image only on the hub gets its preview; the rest goes to the server. */
async function request(r: Forwarded) {
  try {
    const u = new URL(r.url, "http://localhost/")
    if (u.pathname.startsWith("/api/raw/") && r.method === "GET") {
      const at = previewPath(u.searchParams.get("path") ?? ""), jpg = (await local.read({ area: "sync", vault, paths: [at] })).files[at]
      if (jpg) return void local.answer({ id: r.id, status: 200, headers: { "Content-Type": "image/jpeg", "Cache-Control": "no-cache" }, body: jpg })
    }
    await ready
    const ch = new MessageChannel()
    const answered = new Promise<{ status: number; headers: Record<string, string>; body: string | ArrayBuffer | null }>((ok) => { ch.port1.onmessage = (m) => ok(m.data) })
    const body = r.body ? unb64(r.body).buffer : null
    server.postMessage({ type: "fetch", ask: { method: r.method, url: r.url, headers: r.headers, body } }, [ch.port2, ...(body ? [body] : [])])
    const a = await answered
    const bytes = a.body === null ? null : typeof a.body === "string" ? new TextEncoder().encode(a.body) : new Uint8Array(a.body)
    await local.answer({ id: r.id, status: a.status, headers: a.headers, body: bytes ? b64(bytes) : null })
  } catch (e) {
    await local.answer({ id: r.id, status: 500, headers: { "Content-Type": "application/json" }, body: b64(new TextEncoder().encode(JSON.stringify({ error: String((e as Error).message) }))) })
  }
}
;(window as unknown as { __vaultiteLocal: { request: (r: Forwarded) => void } }).__vaultiteLocal = { request: (r) => void request(r) }

/** The app's sockets (/api/events), to the server over a port: WebKit's scheme handlers carry no sockets. */
class LocalSocket extends EventTarget {
  static CONNECTING = 0; static OPEN = 1; static CLOSING = 2; static CLOSED = 3
  readyState = 0
  url: string
  onopen: ((e: Event) => void) | null = null
  onmessage: ((e: MessageEvent) => void) | null = null
  onerror: ((e: Event) => void) | null = null
  onclose: ((e: CloseEvent) => void) | null = null
  private port: MessagePort | null = null
  constructor(url: string | URL) {
    super()
    this.url = String(url)
    const u = new URL(this.url, location.href), at = u.pathname.indexOf("/api/")
    if (at < 0) { setTimeout(() => { this.fire(new Event("error")); this.end(1006) }, 0); return }
    const ch = new MessageChannel()
    this.port = ch.port1
    this.port.onmessage = (e) => { if (e.data === null) this.end(1000); else this.fire(new MessageEvent("message", { data: e.data })) }
    void ready.then(() => { server.postMessage({ type: "socket", url: u.pathname.slice(at) + u.search }, [ch.port2]); this.readyState = 1; this.fire(new Event("open")) })
  }
  send(text: string) { this.port?.postMessage(text) }
  close() { if (this.readyState < 2) { this.port?.postMessage(null); this.end(1000) } }
  private end(code: number) {
    if (this.readyState === 3) return
    this.readyState = 3
    this.port?.close()
    this.fire(new CloseEvent("close", { code }))
  }
  private fire(e: Event) {
    this.dispatchEvent(e)
    ;(this[`on${e.type}` as "onopen"] as ((e: Event) => void) | null)?.(e)
  }
}
globalThis.WebSocket = LocalSocket as unknown as typeof WebSocket

await ready
