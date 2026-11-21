import { groupById } from "@/core/tabgroups"
import { here } from "@/core/workspace"
import { cn, plural } from "@/lib/utils"
import { GroupLabel } from "@/components/GroupLabel"
import type { TabInfo } from "@/components/Tabs"

export function GhostRow({ i, group: id, hint, finger, icons }: { i: TabInfo; group?: string; hint?: string; finger: boolean; icons: boolean }) {
  const group = id ? groupById(id) : undefined
  if (group) {
    return (
      <div className="flex h-7 shrink-0 items-center gap-1.5 pr-2 pl-1">
        <GroupLabel g={group} className="max-w-36" />
        <span className="shrink-0 text-muted-foreground">{hint ?? plural(here().tabs.filter((t) => t.group === group.id).length, "tab")}</span>
      </div>
    )
  }
  return (
    <div className={cn("flex shrink-0 items-center gap-1.5", finger ? "h-10 px-3" : "h-7 px-2")}>
      {icons && <i.icon className={cn(finger ? "size-[18px] shrink-0" : "size-3.5 shrink-0", !i.tint && "text-muted-foreground", i.iconClassName)} strokeWidth={2.25} style={i.tint ? { color: i.tint } : undefined} />}
      <span className="min-w-0 truncate font-medium">{i.label}</span>
      {hint && <span className="shrink-0 text-muted-foreground">{hint}</span>}
    </div>
  )
}
