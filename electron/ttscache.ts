// Lines the companion says again and again ("Handed that off to a background agent.") played from disk, kept by voice
// and settings once a cloud voice made them: its fixed lines (SAID_OFTEN) the first time, other short ones the second.
import crypto from "node:crypto"
import fs from "node:fs"
import path from "node:path"
import { z } from "zod"
import { SAID_OFTEN } from "../core/desktop/spoken.ts"
import type { CloudConfig } from "./tts.ts"
import { type Cloud, type Made, type Piece, RATE, type Timed } from "./voicelogic.ts"

export const PHRASES = { longest: 90, keptOnSaying: 2, mostKept: 64, mostCounted: 400 }
const OFTEN = new Set(Object.values(SAID_OFTEN))
const SLICE_MS = 250

const TIMED = z.object({ chars: z.array(z.string()), ends: z.array(z.number()) })
const INDEX = z.object({ counts: z.record(z.string(), z.number()).catch({}), kept: z.record(z.string(), z.object({ used: z.number(), timed: TIMED })).catch({}) })
type Index = z.infer<typeof INDEX>

export type Voiced = Pick<CloudConfig, "provider" | "model" | "voice" | "speed">

export function phraseStore(dir: string) {
  let index: Index | null = null
  const file = path.join(dir, "index.json")
  const load = () => {
    if (index) return index
    try { index = INDEX.parse(JSON.parse(fs.readFileSync(file, "utf8"))) } catch { index = { counts: {}, kept: {} } }
    return index
  }
  const save = () => {
    try { fs.mkdirSync(dir, { recursive: true }); fs.writeFileSync(`${file}.tmp`, JSON.stringify(index)); fs.renameSync(`${file}.tmp`, file) } catch {}
  }
  const pcmOf = (key: string) => path.join(dir, `${key}.pcm`)
  return {
    get(key: string): { pcm: Buffer; timed: Timed } | null {
      const k = load().kept[key]
      if (!k) return null
      let pcm: Buffer
      try { pcm = fs.readFileSync(pcmOf(key)) } catch { delete load().kept[key]; save(); return null }
      k.used = Date.now()
      save()
      return { pcm, timed: k.timed }
    },
    countSaid(key: string) {
      const i = load(), n = (i.counts[key] ?? 0) + 1
      i.counts[key] = n
      const keys = Object.keys(i.counts)
      for (const k of keys.slice(0, Math.max(0, keys.length - PHRASES.mostCounted))) delete i.counts[k]
      save()
      return n
    },
    put(key: string, pcm: Buffer, timed: Timed) {
      const i = load()
      try { fs.mkdirSync(dir, { recursive: true }); fs.writeFileSync(pcmOf(key), pcm) } catch { return }
      i.kept[key] = { used: Date.now(), timed }
      const old = Object.entries(i.kept).sort((a, b) => a[1].used - b[1].used)
      for (const [k] of old.slice(0, Math.max(0, old.length - PHRASES.mostKept))) { delete i.kept[k]; fs.rmSync(pcmOf(k), { force: true }) }
      save()
    },
    kept: () => Object.keys(load().kept).length,
  }
}
export type PhraseStore = ReturnType<typeof phraseStore>

export const phraseKey = (v: Voiced, p: Pick<Piece, "text" | "language">) =>
  crypto.createHash("sha256").update(JSON.stringify([v.provider, v.model, v.voice, v.speed ?? 1, RATE, p.language, p.text.trim()])).digest("hex").slice(0, 32)

export function withPhrases<C extends Cloud>(cloud: C, voiced: Voiced, store: PhraseStore): C {
  const make: Cloud["make"] = (p, to) => {
    const text = p.text.trim()
    if (!text || text.length > PHRASES.longest) return cloud.make(p, to)
    const key = phraseKey(voiced, p), kept = store.get(key)
    if (kept) return playKept(kept, to)
    const keep = OFTEN.has(text) || store.countSaid(key) >= PHRASES.keptOnSaying
    if (!keep) return cloud.make(p, to)
    const bufs: Buffer[] = []
    let timed: Timed = { chars: [], ends: [] }
    return cloud.make(p, {
      audio(pcm, t) { bufs.push(pcm); if (t) timed = t; to.audio(pcm, t) },
      end() {
        if (bufs.length && allTimed(timed, text)) store.put(key, Buffer.concat(bufs), { chars: [...timed.chars], ends: [...timed.ends] })
        to.end()
      },
      fail: to.fail,
    })
  }
  return { ...cloud, make }
}

const letters = (s: string) => s.replace(/\s/g, "").length
const allTimed = (timed: Timed, text: string) => letters(timed.chars.join("")) >= letters(text)
function playKept(kept: { pcm: Buffer; timed: Timed }, to: Made) {
  let stopped = false
  const slice = Math.round(RATE * 2 * SLICE_MS / 1000) & ~1
  setImmediate(() => {
    for (let at = 0; at < kept.pcm.length && !stopped; at += slice) to.audio(kept.pcm.subarray(at, at + slice), kept.timed)
    if (!stopped) to.end()
  })
  return () => { stopped = true }
}
