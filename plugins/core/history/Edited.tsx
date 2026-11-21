import { History } from "lucide-react"
import { cn, fmtAgo, openView, pluginSettings, useAi, useLive, type FileHead } from "@vaultite"

type Edited = { path: string; by: string; t: number }
const useEdited = () => useLive<{ files: Edited[] }>("history/edited", undefined, true)

export function EditedChip({ file }: { file: FileHead & { place: "bar" | "line" } }) {
  const ai = useAi()
  const shown = pluginSettings<{ header?: boolean }>("history").use().header !== false
  const f = useEdited().data?.files.find((x) => x.path === file.path)
  if (!f || !shown || !ai) return null
  const bar = file.place === "bar"
  const what = `${f.by} edited this ${fmtAgo(f.t)}`
  return (
    <button type="button" data-opens onClick={() => openView(`history/${file.path}`)} data-history-edited aria-label={`${what}: open version history`} data-tip="See what changed in version history"
      className={cn("flex min-w-0 shrink cursor-pointer items-center gap-1 text-muted-foreground hover:text-foreground",
        bar ? "h-7 rounded-[5px] px-1.5 text-[12px] hover:bg-foreground/[0.06]"
          : "-my-1.5 h-11 px-1 text-[13px] active:opacity-50 md:my-0 md:h-8 md:rounded-[6px] md:px-1.5 md:hover:bg-foreground/[0.06]")}>
      <History className={cn("shrink-0", bar ? "size-3.5" : "size-4")} strokeWidth={2.25} />
      <span className="truncate">{what}</span>
    </button>
  )
}
