import { useEffect } from "react"
import { cell, trackSoon, webPages, type WebPages } from "@vaultite"
import { containerById, profileIn, splitArg } from "./containers"

type Thumb = { url: string; src: string }
const thumbs = cell<ReadonlyMap<string, Thumb>>(new Map())
const asked = new Set<string>(), taking = new Set<string>()
const KEEP = 40, WIDTH = 560, SETTLE_MS = 1200

let tracked = false
const locks = (container: string | null) => !!containerById(container)?.lock

async function small(jpeg: Uint8Array) {
  const bmp = await createImageBitmap(new Blob([new Uint8Array(jpeg)], { type: "image/jpeg" }), { resizeWidth: WIDTH, resizeQuality: "medium" })
  const c = new OffscreenCanvas(bmp.width, bmp.height)
  c.getContext("2d")?.drawImage(bmp, 0, 0)
  bmp.close()
  return c.convertToBlob({ type: "image/jpeg", quality: 0.8 })
}

async function keep(tab: string, url: string, jpeg: Uint8Array | null | undefined) {
  if (!jpeg) return
  const blob = await small(jpeg).catch(() => null)
  if (!blob) return
  const next = new Map(thumbs.get())
  const was = next.get(tab)
  if (was) URL.revokeObjectURL(was.src)
  next.delete(tab)
  next.set(tab, { url, src: URL.createObjectURL(blob) })
  for (const [old, t] of next) {
    if (next.size <= KEEP) break
    URL.revokeObjectURL(t.src)
    next.delete(old)
  }
  thumbs.set(next)
}

export function useThumbs(web: WebPages, id: number, tab: string, arg: string, settled: boolean) {
  useEffect(() => {
    const { container, url } = splitArg(arg)
    if (!id || !tab || !settled || !web.shot || locks(container)) return
    let gone = false
    if (!tracked) tracked = !!trackSoon("a web tab's picture", () => taking.size > 0)
    taking.add(tab)
    const t = window.setTimeout(() => void web.shot!(id).then((jpeg) => (gone ? undefined : keep(tab, url, jpeg)), () => {}).finally(() => { if (!gone) taking.delete(tab) }), SETTLE_MS)
    return () => { gone = true; taking.delete(tab); clearTimeout(t) }
  }, [web, id, tab, arg, settled])
}

export function fromBefore(tab: string, arg: string) {
  const { container, url } = splitArg(arg), web = webPages
  if (!tab || !web?.frame || locks(container) || asked.has(`${tab} ${url}`)) return
  asked.add(`${tab} ${url}`)
  void web.frame(tab, url, profileIn(container)).then((f) => keep(tab, url, f?.data), () => {})
}

export function useThumb(tab: string, arg: string) {
  const { container, url } = splitArg(arg)
  return thumbs.use((m) => { const t = m.get(tab); return t && t.url === url && !locks(container) ? t.src : null })
}
