import { execFile } from "node:child_process"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { kindOf, tooBig } from "./filetypes.ts"
import { HTTPError, reply } from "./plugins.ts"
import { planSave, saveBody } from "./contracts/save.ts"
import { onHostMessage } from "./desktopapp.ts"
import { gitEnv } from "./gitenv.ts"
import { keptOf } from "./kept.ts"
import { readText, writeText } from "./vault.ts"

const allowed = new Set<string>()
const KEPT = "outside/paths"
let keptAt: string | null = null

const slashed = (p: string) => (path.sep === "\\" ? p.replace(/\\/g, "/") : p)
const real = (p: string) => {
  try {
    return fs.realpathSync(p)
  } catch {
    return path.resolve(p)
  }
}

function allow(paths: unknown) {
  if (!Array.isArray(paths)) return
  for (const p of paths) if (typeof p === "string" && path.isAbsolute(p)) allowed.add(real(p))
}

onHostMessage("allow", (m) => allow(m.paths))

import { isOutside } from "./fileprops.ts"

export { isOutside }

export function keepIn(vaultPath: string) {
  keptAt = vaultPath
  allow(keptOf(vaultPath).get<unknown>(KEPT, []))
}

const under = (r: string, a: string) => r === a || r.startsWith(a.endsWith(path.sep) ? a : a + path.sep)
const holders = (r: string) => [...allowed].filter((a) => under(r, a)).sort((a, b) => a.length - b.length)

function check(p: string) {
  if (!holders(real(p)).length) throw new HTTPError(404, `no file '${p}'`)
  return p
}

export function allowPath(p: string) {
  const r = real(p.replace(/^~(?=$|[\\/])/, os.homedir()))
  const st = fs.statSync(r, { throwIfNoEntry: false })
  if (!st) throw new HTTPError(404, `there's no ${p} on this machine`)
  if (!holders(r).length) {
    allowed.add(r)
    const k = keptAt ? keptOf(keptAt) : null, had = k?.get<unknown>(KEPT, [])
    k?.set(KEPT, [r, ...(Array.isArray(had) ? had.filter((x) => x !== r) : [])].slice(0, 50))
  }
  return { path: slashed(r), folder: st.isDirectory() }
}

const SKIP = new Set([".git", ".DS_Store"])

const ignored = (dir: string, names: string[]) => new Promise<Set<string>>((done) => {
  if (!names.length) return done(new Set())
  const child = execFile("git", ["check-ignore", "-z", "--stdin"], { cwd: dir, timeout: 5000, maxBuffer: 8 << 20, env: gitEnv() }, (_e, out) => {
    done(new Set(String(out ?? "").split("\0").filter(Boolean).map((x) => x.replace(/\/$/, ""))))
  })
  child.stdin?.end(names.join("\0"))
})

const countIn = (dir: string) => { try { return fs.readdirSync(dir).filter((n) => !SKIP.has(n)).length } catch { return 0 } }

export async function list(p: string) {
  const r = real(check(p)), root = holders(r)[0]
  let ents: fs.Dirent[]
  try { ents = fs.readdirSync(p, { withFileTypes: true }).filter((e) => !SKIP.has(e.name)) } catch { throw new HTTPError(404, `there's no folder ${p}`) }
  const folderSlashed = (e: fs.Dirent) => (e.isDirectory() ? `${e.name}/` : e.name)
  const off = await ignored(p, ents.map(folderSlashed))
  const items = ents.filter((e) => !off.has(e.name)).flatMap((e) => {
    const at = path.join(p, e.name), st = fs.statSync(at, { throwIfNoEntry: false })
    if (!st) return []
    const folder = st.isDirectory()
    return [{ name: e.name, folder, mtime: Math.floor(st.mtimeMs), ctime: Math.floor(st.birthtimeMs || st.mtimeMs), size: st.size, count: folder ? countIn(at) : 0 }]
  })
  return { path: slashed(p), root: slashed(p.slice(0, p.length - (r.length - root.length))), items }
}

export function route(method: string, to: string, query: Record<string, string>, body: { path?: unknown }) {
  const at = method === "GET" ? query.path : body.path
  if (to === "file" && isOutside(at)) return handle(method, at, saveBody(body))
  if (to === "file/info" && method === "GET" && isOutside(at)) return info(at)
  if (to === "outside/list" && method === "GET" && isOutside(at)) return list(at)
  if (to === "outside/allow" && method === "POST" && isOutside(at)) return allowPath(at)
  return undefined
}

/** An outside path the app may read (its bytes, its info), or a 404. */
export const allowedPath = (p: string) => check(p)

export function info(p: string) {
  check(p)
  let st: fs.Stats
  try {
    st = fs.statSync(p)
  } catch {
    throw new HTTPError(404, `no file '${p}'`)
  }
  if (!st.isFile()) throw new HTTPError(400, `'${p}' is a folder`)
  return { path: p, kind: kindOf(p), size: st.size, mtime: Math.floor(st.mtimeMs), ctime: Math.floor(st.birthtimeMs || st.mtimeMs) }
}

function read(p: string) {
  let text: string, st: fs.Stats
  try {
    st = fs.statSync(p)
    text = readText(p)
    if (text.includes("\0")) throw new TypeError("binary")
  } catch (e) {
    if (e instanceof HTTPError) throw e
    if (tooBig(e)) throw new HTTPError(413, `'${p}' is too big to open as text`)
    if (e instanceof TypeError) throw new HTTPError(415, `'${p}' isn't text`)
    throw new HTTPError(404, `no file '${p}'`)
  }
  return { path: p, text, mtime: Math.floor(st.mtimeMs), kind: null, problems: [], outside: true }
}

export function handle(method: string, p: string, said: ReturnType<typeof saveBody>) {
  check(p)
  if (method === "GET") return read(p)
  if (method !== "PUT") throw new HTTPError(405, "files outside the vault can only be read and saved")
  if (!said.ok) throw new HTTPError(400, said.why)
  if (said.body.text === undefined && said.body.edit === undefined) throw new HTTPError(400, "text must be a string")
  let cur: string | null
  try {
    cur = readText(p)
  } catch {
    cur = null
  }
  const plan = planSave(cur, { ...said.body, text: said.body.text ?? "" })
  if (plan.kind === "gone") throw new HTTPError(404, `${p} isn't there any more (moved or deleted)`)
  if (plan.kind === "changed") return reply(412, { error: "the file changed on disk: send its base to merge" })
  if (plan.kind === "bad") throw new HTTPError(400, plan.why)
  if (plan.kind === "conflict") return reply(409, { error: "the file changed on disk in the same place", ...read(p) })
  if (cur !== plan.text) writeText(p, plan.text)
  return read(p)
}
