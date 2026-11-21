// A test server's preload: while VAULTITE_SLOW_WHILE exists, fs calls under VAULTITE_SLOW_DIR take VAULTITE_SLOW_MS more.
import fs from "node:fs"
import { syncBuiltinESMExports } from "node:module"

const dir = process.env.VAULTITE_SLOW_DIR ?? "", ms = Number(process.env.VAULTITE_SLOW_MS ?? 0), marker = process.env.VAULTITE_SLOW_WHILE ?? ""
const there = fs.existsSync
let on = !marker
if (marker) setInterval(() => { on = there(marker) }, 100).unref()
const held = new Int32Array(new SharedArrayBuffer(4))
const hold = () => { Atomics.wait(held, 0, 0, ms) }
const slow = (p: fs.PathLike) => on && !!dir && ms > 0 && (p instanceof URL ? p.pathname : String(p)).startsWith(dir)
const SYNC = ["statSync", "lstatSync", "readdirSync", "readFileSync", "writeFileSync", "renameSync", "existsSync", "openSync", "mkdirSync", "rmSync", "unlinkSync", "copyFileSync"] as const
const ASYNC = ["stat", "lstat", "readdir", "readFile", "writeFile", "rename", "open", "mkdir", "rm", "unlink", "copyFile", "access"] as const
type Fn = (p: fs.PathLike, ...rest: never[]) => void
// oxlint-disable-next-line anti-slop/no-object-parameters, anti-slop/no-reflect-get, anti-slop/no-reflect-apply, anti-slop/no-runtime-typeof -- patches node:fs, whose functions it names
function wrap(on: object, name: string, make: (real: Fn) => Fn) { const real = Reflect.get(on, name); if (typeof real === "function") Reflect.set(on, name, make((...a) => Reflect.apply(real, on, a))) }
for (const name of SYNC) wrap(fs, name, (real) => (p, ...rest) => { if (slow(p)) hold(); return real(p, ...rest) })
for (const name of ASYNC) {
  wrap(fs.promises, name, (real) => (p, ...rest) => { if (!slow(p)) return real(p, ...rest); return new Promise((r) => setTimeout(r, ms)).then(() => real(p, ...rest)) })
  wrap(fs, name, (real) => (p, ...rest) => { if (!slow(p)) return real(p, ...rest); setTimeout(() => real(p, ...rest), ms) })
}
syncBuiltinESMExports()
