import { useState } from "react"
import { Play } from "lucide-react"
import { cn, notifyError, op } from "@vaultite"
import type { Exchange, KeptDrawing } from "./conversation"

const dayOf = (t: number) => { const d = new Date(t), two = (n: number) => String(n).padStart(2, "0"); return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())}` }
export default function DrawingChips({ e, compact }: { e: Exchange; compact?: boolean }) {
  return (
    <div className={cn("flex flex-wrap gap-1.5", compact ? "mt-0.5" : "mt-1.5")} data-companion-drawings>
      {(e.drawings ?? []).map((d) => <DrawingChip key={d.id} d={d} day={dayOf(e.t)} compact={compact} />)}
    </div>
  )
}
function DrawingChip({ d, day, compact }: { d: KeptDrawing; day: string; compact?: boolean }) {
  const [busy, setBusy] = useState(false)
  const play = () => { setBusy(true); op("companion.redraw", { id: d.id, day }).catch((err) => notifyError(err, "Couldn't draw it again")).finally(() => setBusy(false)) }
  return (
    <button type="button" onClick={play} disabled={busy} data-companion-drawing={d.id} data-tip="Draw it on the screen again"
      className={cn("flex max-w-full min-w-0 cursor-pointer items-center gap-1.5 rounded-full border border-border bg-foreground/[0.03] pr-2.5 pl-2 text-muted-foreground transition-colors hover:bg-foreground/[0.07] hover:text-foreground disabled:cursor-default disabled:opacity-60",
        compact ? "h-6 text-[12px]" : "h-7 text-[13px]")}>
      <Play className="size-3 shrink-0 fill-current" strokeWidth={2.25} />
      <span className="min-w-0 truncate font-medium text-foreground">{d.title}</span>
      <span className="shrink-0 tabular-nums">{d.marks} {d.marks === 1 ? "mark" : "marks"}</span>
    </button>
  )
}
