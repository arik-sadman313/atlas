import { RotateCcw } from "lucide-react"
import { cn } from "@/lib/utils"

const LOOK = "inline-flex shrink-0 cursor-pointer items-center gap-1.5 rounded-[6px] px-3 text-[13px] font-medium h-7 max-md:h-11 max-md:text-[15px] focus-visible:ring-2 focus-visible:ring-primary/50 focus-visible:outline-none"

export function TryAgain({ onClick, quiet, className }: { onClick: () => void; quiet?: boolean; className?: string }) {
  return (
    <button type="button" onClick={onClick} data-try-again className={cn(LOOK, quiet ? "text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground"
      : "mt-3 bg-foreground/[0.06] text-foreground hover:bg-foreground/[0.1]", className)}>
      <RotateCcw className="size-3.5" strokeWidth={2} />Try again
    </button>
  )
}
