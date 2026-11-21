import { Globe, Hand, X } from "lucide-react"
import { cn } from "@vaultite"

export function TabStrip({ tabs, shown, asked, titleOf, pick, drop }: { tabs: number[]; shown: number; asked: number; titleOf: (n: number) => string
  pick: (n: number) => void; drop: (n: number) => void }) {
  return (
    <div role="tablist" aria-label="Tabs shown here" className="flex shrink-0 items-center gap-1 overflow-x-auto border-b-[0.5px] border-border px-2 py-1.5" data-web-live-strip>
      {tabs.map((n) => (
        <span key={n} role="tab" aria-selected={n === shown} data-web-live-stack-tab={n}
          className={cn("flex h-8 max-w-[240px] min-w-0 shrink-0 cursor-pointer items-center gap-1.5 rounded-[8px] pr-1 pl-2.5 text-[13px] max-md:h-11",
            n === shown ? "bg-foreground/[0.08] text-foreground" : "text-muted-foreground hover:bg-foreground/[0.05] hover:text-foreground")}
          onClick={() => pick(n)}>
          {n === asked ? <Hand className="size-3.5 shrink-0" strokeWidth={2} style={{ color: "var(--purple)" }} /> : <Globe className="size-3.5 shrink-0" strokeWidth={2} />}
          <span className="min-w-0 truncate">{titleOf(n)}</span>
          {n !== asked ? (
            <button type="button" aria-label="Stop showing it here" data-tip="Stop showing it here (it stays open)" onClick={(e) => { e.stopPropagation(); drop(n) }}
              className="grid size-5 shrink-0 cursor-pointer place-items-center rounded-[4px] opacity-60 hover:bg-foreground/[0.08] hover:opacity-100"><X className="size-3" strokeWidth={2.25} /></button>
          ) : <span className="w-1.5" />}
        </span>
      ))}
    </div>
  )
}
