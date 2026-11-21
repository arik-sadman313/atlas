import type { MouseEvent as ReactMouseEvent, PointerEvent, TouchEvent as ReactTouchEvent } from "react"
import { ChevronDown } from "lucide-react"
import type { BarKey } from "@/core/keyboard"
import { cn } from "@/lib/utils"

/** The row above the keyboard. Its buttons never take focus (on iOS the keyboard would go) and act as the finger
 *  lifts. `scroll`: keys a finger wide, the row scrolling sideways when they don't fit. */
export function KeyBar({ label, keys, hide, scroll, className }: { label: string; keys: BarKey[]; hide: () => void; scroll?: boolean; className?: string }) {
  const key = cn("relative grid h-9 cursor-pointer place-items-center rounded-[8px] bg-card font-mono text-[13px] text-foreground after:absolute after:inset-x-0 after:-inset-y-1.5 active:bg-foreground/[0.12]",
    scroll ? "min-w-11 shrink-0 flex-1 px-1" : "min-w-0 flex-1")
  const tap = (run: () => void) => ({
    onPointerDown: (e: PointerEvent) => e.preventDefault(),
    onMouseDown: (e: ReactMouseEvent) => e.preventDefault(),
    onTouchEnd: (e: ReactTouchEvent) => { if (e.cancelable) e.preventDefault() },
    onPointerUp: (e: PointerEvent) => { if (e.currentTarget.contains(document.elementFromPoint(e.clientX, e.clientY))) run() },
  })
  return (
    <div role="toolbar" aria-label={label} data-no-drag data-key-bar
      className={cn("sight-foot flex shrink-0 items-center gap-1 border-t-[0.5px] border-border bg-sidebar py-1.5 pr-1.5", className)}>
      <div className={cn("flex min-w-0 flex-1 gap-1 pl-1.5", scroll && "-my-1.5 edge-fade-x overflow-x-auto overscroll-x-contain py-1.5 [scrollbar-width:none]")}>
        {keys.map((k) => (
          <button key={k.name} type="button" tabIndex={-1} aria-label={k.name} {...tap(k.run)} className={key}>{k.label}</button>
        ))}
      </div>
      <button type="button" tabIndex={-1} aria-label="Hide keyboard" {...tap(hide)}
        className="relative flex h-9 shrink-0 cursor-pointer items-center gap-1 rounded-[8px] px-2.5 text-[16px] font-semibold text-primary after:absolute after:-inset-x-1 after:-inset-y-1.5 active:bg-foreground/[0.12]">
        <ChevronDown className="size-[18px]" strokeWidth={2.4} />Done
      </button>
    </div>
  )
}
