import fs from "node:fs"
import path from "node:path"
import type { Any, VaultTest } from "./harness.ts"

export default async ($: VaultTest) => {
  const { check, tmp, sleep } = $
  const { phraseKey, phraseStore, PHRASES, withPhrases } = await import("../../../electron/ttscache.ts")
  const { voice } = await import("../../../electron/voicelogic.ts")
  const { SAID_OFTEN, sayable } = await import("../../../core/desktop/spoken.ts")
  const dir = path.join(tmp, "voice-phrases")
  const asked: string[] = []
  const cloud = (short = false) => ({ make: (p: Any, to: Any) => {
    asked.push(p.text)
    const chars = [...p.text], ends = chars.map((_c, i) => (i + 1) * 0.03)
    setImmediate(() => { to.audio(Buffer.alloc(4800, 1), { chars: short ? chars.slice(0, 3) : chars, ends }); to.audio(Buffer.alloc(4800, 2), { chars: short ? chars.slice(0, 3) : chars, ends }); to.end() })
    return () => {}
  } })
  const voiced = { provider: "soniox" as const, model: "tts-1", voice: "Adrian", speed: 1 }
  const say = async (c: Any, text: string) => {
    const out: string[] = [], heard: string[] = []
    let bytes = 0
    const v = voice({ clouds: () => [c], hints: () => ["en"], firstMs: 5000, stallMs: 5000, heard: (h) => heard.push(h.text),
      out: { pcm: (_n, b) => { bytes += b.length; out.push("pcm") }, say: (_n, t) => out.push(`mac:${t}`), end: () => out.push("end"), stop: () => out.push("stop") } })
    v.start("hand it off")
    v.text("s1", text)
    v.end()
    for (let i = 0; i < 50 && !out.includes("end"); i++) await sleep(10)
    for (let i = 1; i <= 2; i++) v.played(i, Date.now())
    return { out, bytes, heard }
  }
  const store = phraseStore(dir), mine = withPhrases(cloud(), voiced, store)
  const line = SAID_OFTEN.handed
  check("phrases: the handoff line is said as it's written (the key is its words)", sayable(line, "en") === line, sayable(line, "en"))
  const first = await say(mine, line)
  check("phrases: the handoff line, said the first time, is the cloud's and is kept", asked.length === 1 && first.bytes === 9600 && first.out.at(-1) === "end" &&
    store.kept() === 1 && fs.existsSync(path.join(dir, `${phraseKey(voiced, { text: line, language: "en" })}.pcm`)), { asked, first, kept: store.kept() })
  const again = await say(mine, line)
  check("phrases: said again it plays from disk, the cloud never asked: the same audio, its sentence heard", asked.length === 1 && again.bytes === 9600 &&
    again.out.at(-1) === "end" && again.heard.join() === line, { asked, again })
  const later = await say(withPhrases(cloud(), voiced, phraseStore(dir)), line)
  check("phrases: kept across restarts (on disk)", asked.length === 1 && later.bytes === 9600, { asked, later })
  await say(withPhrases(cloud(), { ...voiced, voice: "Grace" }, store), line)
  await say(withPhrases(cloud(), { ...voiced, speed: 1.2 }, store), line)
  check("phrases: another voice or speed is a miss: the cloud makes it (and it's kept for that voice)", asked.length === 3 && store.kept() === 3, asked)

  const other = "Sure, opening it now."
  await say(mine, other)
  check("phrases: any other short line isn't kept the first time", asked.length === 4 && store.kept() === 3)
  await say(mine, other)
  await say(mine, other)
  check(`phrases: …but once it's said a ${PHRASES.keptOnSaying}nd time, then played from disk`, asked.length === 5 && store.kept() === 4, asked)
  const long = "This answer is one long sentence that runs well past the length of any stock line the companion says."
  await say(mine, long); await say(mine, long); await say(mine, long)
  check("phrases: a long piece is never kept", asked.filter((x) => x === long).length === 3 && store.kept() === 4, asked.slice(-3))

  const cut = withPhrases(cloud(true), voiced, phraseStore(path.join(tmp, "voice-phrases-cut")))
  await say(cut, SAID_OFTEN.passed); await say(cut, SAID_OFTEN.passed)
  check("phrases: a piece cut short (its letters not all timed) isn't kept", asked.filter((x) => x === SAID_OFTEN.passed).length === 2, asked)

  fs.rmSync(path.join(dir, `${phraseKey(voiced, { text: line, language: "en" })}.pcm`))
  await say(mine, line)
  check("phrases: its file gone, the cloud makes it again", asked.filter((x) => x === line).length === 4, asked)
}
