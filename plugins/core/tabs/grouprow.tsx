import { ChevronDown } from "lucide-react"
import { GroupLabel, SidebarRow, type TabGroup } from "@vaultite"

export function TabGroupRow({ g, n, target, onFold, more, children, ...rest }: {
  g: TabGroup; n: number; target?: boolean; onFold: () => void
  more?: boolean
  children?: React.ReactNode
} & Record<`data-${string}`, string | undefined>) {
  return (
    <SidebarRow data-group-row={g.id} {...rest} aria-expanded={!g.collapsed} open tip={null} more={more} onClick={onFold}
      label={<span className="flex"><GroupLabel g={g} n={n} target={target} /></span>}>
      {children}
      <ChevronDown aria-hidden className="size-3.5 shrink-0 text-muted-foreground opacity-0 transition-[rotate,opacity] duration-200 group-hover/row:opacity-100 group-aria-[expanded=false]/row:-rotate-90" strokeWidth={2.25} />
    </SidebarRow>
  )
}
