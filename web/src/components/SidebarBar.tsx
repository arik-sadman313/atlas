import { useRef, useState } from "react"
import type { SidebarCtx } from "@/core/define"
import { startDrag, useDragItem, useDropHit, useDropTarget } from "@/core/drag"
import { APP_PAGES, hrefOf, openAppPage, type AppPage } from "@/core/apppages"
import { isDesktop } from "@/core/platform"
import { sideOf, useSidebars, usePluginsVersion } from "@/core/plugins"
import { usePrefs } from "@/core/prefs"
import { BAR_NAMES, barOf, barThings, canGoInBar, placeInBar, shownIn, type BarThing, type SidebarBar as Bar } from "@/core/sidebarbars"
import { INCOMING, reorder, slotAt, useSlide } from "@/core/slide"
import { menuFor } from "@/components/ContextMenu"
import { thingMenu } from "@/components/barMenus"
import { Drawn, Guard } from "@/components/Guard"
import { RailFlyout } from "@/components/Sidebar"
import { cn } from "@/lib/utils"

type Gap = { before: string | null; order: string[] }

export function SidebarBar({ bar, ctx, page, vertical }: { bar: Bar; ctx: SidebarCtx; page?: string; vertical?: boolean }) {
  const prefs = usePrefs()
  usePluginsVersion()
  const setup = useSidebars()
  const things = shownIn(bar, prefs, setup)
  const box = useRef<HTMLDivElement>(null)
  const [flying, setFlying] = useState<string | null>(null)
  const lifted = useDragItem(), carried = lifted?.from === "panel" ? lifted.panel : undefined
  const target = `bar:${bar}`
  const hit = useDropHit<Gap>(target)
  useDropTarget<Gap>(target, (item, x, y) => {
    const key = item.from === "panel" ? item.panel : undefined, el = box.current, area = el?.closest("[data-bar-area]")
    if (!key || !el || !area || vertical || !canGoInBar(key)) return null
    const b = area.getBoundingClientRect()
    if (x < b.left || x > b.right || y < b.top - 4 || y > b.bottom + 4) return null
    const slots = [...el.querySelectorAll<HTMLElement>(":scope > [data-bar-key]")].filter((s) => s.offsetWidth)
    const { order, before, same } = reorder(slots.map((s) => s.dataset.barKey!), [key], slotAt(el, slots, x, y, "x"))
    return same ? null : { before, order }
  }, (item, g) => placeInBar(item.panel!, bar, g.before), { hint: () => (carried && barOf(carried) === bar && !sideOf(carried) ? undefined : `To the ${BAR_NAMES[bar]}`) })
  useSlide(box, hit?.order ?? null, "x", { heldAtEnd: true })
  const coming = hit?.order.includes(INCOMING) && carried ? barThings(prefs.disabled).get(carried) : undefined
  return (
    <div ref={box} data-sidebar-bar={bar} className={cn("relative flex gap-1", vertical ? "flex-col" : "min-h-7 items-center")}>
      {things.map((t) => (
        <div key={t.key} data-bar-key={t.key} data-slide={t.key} data-header-item={bar === "header" ? t.key : undefined}
          onPointerDown={(e) => { if (e.target instanceof Node && e.currentTarget.contains(e.target)) startDrag(e, { from: "panel", panel: t.key, label: t.title, to: t.to }) }}
          onContextMenu={(e) => { if (e.target instanceof Node && e.currentTarget.contains(e.target)) menuFor(() => thingMenu(t, bar))(e) }}
          className={cn("flex min-w-0 shrink-0 empty:hidden", vertical ? "flex-col" : "items-center", carried === t.key && "opacity-50")}>
          <Thing thing={t} ctx={ctx} bar={vertical ? undefined : bar} button={bar === "foot" || !vertical} page={page} flying={flying === t.key} setFlying={(v) => setFlying(v ? t.key : null)} />
        </div>
      ))}
      {coming && (
        <span aria-hidden data-slide={INCOMING} data-slide-fixed className="absolute top-0 left-0 grid size-7 place-items-center rounded-[5px] bg-foreground/[0.06] text-muted-foreground">
          <coming.icon className="size-4" strokeWidth={2} />
        </span>
      )}
    </div>
  )
}

function Thing({ thing: t, ctx, bar, button, page, flying, setFlying }: { thing: BarThing; ctx: SidebarCtx; bar?: Bar; button: boolean; page?: string; flying: boolean; setFlying: (v: boolean) => void }) {
  if (t.kind === "item") return <Guard what="This item"><Drawn draw={() => t.item.render(ctx)} /></Guard>
  if (t.kind === "panel") return <RailFlyout panel={t.of.panel} ctx={{ ...ctx, panel: t.key }} open={flying} setOpen={setFlying} bar={bar} button={button} />
  const p = APP_PAGES.find((x) => x.id === "setup")
  return p ? <AppPageButton page={p} active={page === p.id} tipSide={bar ? "top" : "right"} /> : null
}

export function AppPageButton({ page: t, active, tipSide }: { page: AppPage; active: boolean; tipSide: "top" | "right" }) {
  return (
    <a href={hrefOf(t)} aria-label={t.label} aria-current={active ? "page" : undefined} data-tip={t.label} data-tip-side={tipSide} data-app-page={t.id}
      onClick={(e) => { if (!isDesktop()) return; e.preventDefault(); openAppPage(t, e.metaKey || e.ctrlKey) }}
      className={cn("grid size-7 shrink-0 place-items-center rounded-[5px] transition-colors",
        active ? "bg-foreground/[0.08] text-primary" : "text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground")}>
      <t.icon className="size-4" strokeWidth={2} />
    </a>
  )
}
