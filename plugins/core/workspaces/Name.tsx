import { useRef } from "react"
import { cn } from "@vaultite"
import { slots } from "./state"

export function NameField({ n, done, className }: { n: number; done: (name: string | null, key?: "Enter" | "Escape") => void; className: string }) {
  const ended = useRef(false)
  const end = (name: string | null, key?: "Enter" | "Escape") => { if (ended.current) return; ended.current = true; done(name, key) }
  return (
    <input autoFocus onFocus={(e) => e.currentTarget.select()} aria-label={`Name of workspace ${n}`}
      defaultValue={slots()?.[n - 1]?.name ?? ""} placeholder={`Workspace ${n}`}
      onKeyDown={(e) => {
        if (e.key === "Enter") end(e.currentTarget.value, "Enter")
        else if (e.key === "Escape") { e.stopPropagation(); end(null, "Escape") }
      }}
      onBlur={(e) => end(e.currentTarget.value)}
      className={cn("-mx-1 min-w-0 flex-1 rounded-[4px] border-[0.5px] border-primary bg-background px-1 outline-none", className)} />
  )
}
