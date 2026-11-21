import type { ReactNode } from "react"
import { SquareTerminal } from "lucide-react"
import { Button, cn, notifyError } from "@vaultite"

export function OpenSession({ open, look = "secondary", className, at }: { open: () => Promise<void>; look?: "secondary" | "quiet"; className?: string; at: "top" | "end" }) {
  return (
    <Button look={look} className={cn("h-11 px-3 md:h-8", className)} data-open-session={at}
      onClick={() => void open().catch((e) => notifyError(e, "Couldn't open it"))}>
      <SquareTerminal className="size-4" /> Open session
    </Button>
  )
}

export function ItemActions({ open, quiet, triage, className }: { open: () => Promise<void>; quiet?: boolean; triage?: ReactNode; className?: string }) {
  return (
    <div data-item-actions className={cn("flex flex-wrap items-center gap-x-3 gap-y-1", className)}>
      <OpenSession open={open} at="top" look={quiet ? "quiet" : "secondary"} className={cn(quiet && "px-0 hover:bg-transparent")} />
      {triage && <div data-item-triage className="flex items-center gap-2 md:ml-auto">{triage}</div>}
    </div>
  )
}
