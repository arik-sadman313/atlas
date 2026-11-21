import { useEffect, useState, type MouseEvent } from "react"
import { SlidersHorizontal } from "lucide-react"
import { openMenu, webPages } from "@vaultite"
import { engine } from "./engine"

export function SiteInfoButton({ id, url, loading }: { id: number; url: string; loading?: boolean }) {
  const [site, setSite] = useState<string | null>(null)
  useEffect(() => {
    let gone = false
    void engine("permissions:page", id).then((r) => { if (!gone) setSite(r?.site ?? null) }, () => {})
    return () => { gone = true }
  }, [id, url, loading])
  if (!webPages?.engine || !site) return null
  const open = async (e: MouseEvent<HTMLButtonElement>) => {
    const r = e.currentTarget.getBoundingClientRect()
    const p = await engine("permissions:page", id).catch(() => null)
    if (!p) return
    const kinds = p.kinds.map((k) => ({ ...k, was: k.choice, default: k.kind === "notifications" ? "allow" as const : "ask" as const }))
    const page = { ...p, kinds }
    const { siteItems } = await import("./sitemenu")
    const items = () => siteItems(page, () => void webPages?.go(id, "reload"))
    openMenu({ x: r.left, y: r.bottom + 4, flip: r.top - 4 }, items(), false, items)
  }
  return (
    <button type="button" aria-label={`Site information for ${site}`} aria-haspopup="menu" data-tip="Site information" data-web-site-info
      onClick={(e) => void open(e)}
      className="flex size-6 shrink-0 cursor-pointer items-center justify-center rounded-[5px] text-muted-foreground hover:bg-foreground/[0.07] hover:text-foreground">
      <SlidersHorizontal className="size-3.5" strokeWidth={2} />
    </button>
  )
}
