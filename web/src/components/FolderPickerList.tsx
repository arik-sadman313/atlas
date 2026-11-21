import { useMemo, useState } from "react"
import { Folder, FolderPlus } from "lucide-react"
import { cleanName, isHidden } from "@/core/files"
import { fuzzy } from "@/core/fuzzy"
import { marked, NoMatches, Palette } from "@/components/Palette"
import type { FolderPick } from "@/components/FolderPicker"

type Item = { id: string; path: string; label: string; marks: number[]; create: boolean }

export function Picker({ p, onClose }: { p: FolderPick; onClose: () => void }) {
  const [q, setQ] = useState("")
  const items = useMemo((): Item[] => {
    const query = q.trim().replace(/^\/+|\/+$/g, "")
    const all = p.folders.map((f) => { const marks: number[] = []; return { id: `f-${f}`, path: f, label: f || "/", marks, score: 0, create: false } })
    if (!query) return all
    const out: Item[] = all.flatMap((h) => { const m = fuzzy(query, h.label); return m ? [{ ...h, ...m }] : [] }).sort((a, b) => b.score - a.score)
    const name = cleanName(query)
    const taken = new Set(p.all.map((f) => f.toLowerCase()))
    if (name && !taken.has(name.toLowerCase()) && !isHidden(name) && (!p.not || (name !== p.not && !name.startsWith(`${p.not}/`)))) {
      out.push({ id: `new-${name}`, path: name, label: name, marks: [], create: true })
    }
    return out
  }, [p, q])
  const pick = (h: Item) => { onClose(); p.onPick(h.path, h.create) }
  return (
    <Palette label={p.label} placeholder={p.placeholder} query={q} setQuery={setQ} items={items} onClose={onClose}
      onPick={(it, { shift }) => {
        const h = shift ? items.find((x) => x.create) : it
        if (h) pick(h)
      }}
      empty={<NoMatches what="No folder matches" query={q} />}
      hints={[["ArrowUp ArrowDown", "to navigate"], ["Enter", `to ${p.verb}`], ["Shift+Enter", "to make the folder"], ["Escape", "to dismiss"]]}
      row={(h) => (
        <>
          {h.create
            ? <FolderPlus className="size-[18px] shrink-0 text-muted-foreground" strokeWidth={2} />
            : <Folder className="size-[18px] shrink-0 text-muted-foreground" strokeWidth={2} />}
          <span className="min-w-0 flex-1 truncate text-[15px] leading-[21px] text-foreground/90">{marked(h.label, h.marks)}</span>
          {(h.create || !h.path) && <span className="shrink-0 text-[13px] text-muted-foreground">{h.create ? "New folder" : "Vault root"}</span>}
        </>
      )} />
  )
}
