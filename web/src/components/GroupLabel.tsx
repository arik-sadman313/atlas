import { COLOR_NAMES, colorVar } from "../../../core/colors.ts"
import type { Group } from "../../../core/layout.ts"
import { cn } from "@/lib/utils"

/** What a tab group is called: its name, or its colour's ("Blue group"). */
export const groupName = (g: Group) => g.name || `${COLOR_NAMES[g.color]} group`

/** A tab group's name in a solid chip of its colour (the tab bar's, the Tabs panel's), its text white or dark by it; no
 *  name, a small square. Folded, its count `n` shows: drawn always, to open out as the click folds it (index.css). */
export function GroupLabel({ g, n, target, className }: { g: Group; n?: number; target?: boolean; className?: string }) {
  const c = colorVar(g.color), name = n !== undefined && g.collapsed ? `${groupName(g)}, ${n} ${n === 1 ? "tab" : "tabs"}` : groupName(g)
  return (
    <span data-group-name data-bare={g.name ? undefined : ""} {...(g.name ? {} : { role: "img", "aria-label": name })}
      data-target={target || undefined}
      className={cn("on-tint inline-flex max-w-full shrink-0 items-center justify-center text-[12px] leading-none font-semibold transition-[background-color,color,box-shadow,scale] duration-(--motion)",
        g.name && "h-5 rounded-control px-1.5", className)}
      style={{ "--tint": c, background: c }}>
      {g.name && <span className="min-w-0 truncate">{g.name}</span>}
      {n !== undefined && <span data-group-count aria-hidden={!g.collapsed || undefined}><span><span key={n} className={cn("block font-medium tabular-nums opacity-80", g.name && "pl-1")}>{n}</span></span></span>}
    </span>
  )
}
