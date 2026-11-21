/** OpenAI Realtime's PCM: 16-bit mono, little-endian, 24 kHz, in and out (voice.swift plays the same). */
export const RT_RATE = 24_000
/** The microphone's (dictation.swift's tap). */
export const MIC_RATE = 16_000

/** A stream of 16-bit PCM at `from` Hz made `to` Hz, chunk by chunk (linear: speech needs no more), its phase kept
 *  across chunks so their joins don't click. */
export function resampler(from = MIC_RATE, to = RT_RATE) {
  const step = from / to
  // (pos is in this chunk's samples; -1 is the chunk before's last one)
  let pos = 0, last = 0
  return (b: Buffer): Buffer => {
    const n = Math.floor(b.length / 2)
    if (!n) return Buffer.alloc(0)
    const at = (i: number) => (i < 0 ? last : b.readInt16LE(i * 2))
    const out: number[] = []
    for (; pos <= n - 1; pos += step) {
      const i = Math.floor(pos), f = pos - i
      out.push(f ? Math.round(at(i) * (1 - f) + at(i + 1) * f) : at(i))
    }
    pos -= n
    last = at(n - 1)
    const o = Buffer.alloc(out.length * 2)
    out.forEach((v, i) => o.writeInt16LE(Math.max(-32768, Math.min(32767, v)), i * 2))
    return o
  }
}
