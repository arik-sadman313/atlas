import { useMemo, useState } from "react"
import { Folder, Plus, X } from "lucide-react"
import { useStore } from "@/core/data"
import { folderList } from "@/core/files"
import { valueLabel } from "@/core/pluginSettings"
import { cn } from "@/lib/utils"
import { SettingRow } from "@/components/kit"
import { chooseFolder } from "@/components/FolderPicker"
import { beside, field, type FieldProps } from "@/components/settingKit"

function useFolders() {
  const files = useStore().store?.files
  return useMemo(() => new Set(files ? folderList(files) : []), [files])
}
const missing = (f: string) => <span className="text-ink-(--red)">There's no folder {f}</span>
const trimmed = (f: string) => f.replace(/^\/+|\/+$/g, "")

export function FolderField({ k, d, value, set, sub }: FieldProps) {
  const folders = useFolders()
  const v = value ? trimmed(String(value)) : ""
  return (
    <SettingRow stack label={d.label} sub={v && !folders.has(v) ? missing(v) : sub} data-setting={k}>
      <div className={cn("flex items-center gap-1", beside)}>
        <button type="button" aria-label={d.label} onClick={() => chooseFolder(d.label, set)} data-folder-field
          className={cn(field, "flex min-w-0 flex-1 cursor-pointer items-center gap-1.5 text-left hover:bg-foreground/[0.03]")}>
          <Folder className="size-3.5 shrink-0 text-muted-foreground" strokeWidth={2} />
          <span className={cn("min-w-0 flex-1 truncate", !v && "text-muted-foreground")}>{v || String(d.default || d.unset || "Choose a folder")}</span>
        </button>
        {v && (
          <button type="button" aria-label={`Clear ${d.label.toLowerCase()}`} data-tip="Back to its default" onClick={() => set(null)}
            className="grid size-11 shrink-0 cursor-pointer place-items-center rounded-control text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground md:size-7">
            <X className="size-3.5" strokeWidth={2.25} />
          </button>
        )}
      </div>
    </SettingRow>
  )
}

const chip = "flex min-h-10 items-center gap-1 rounded-full border-[0.5px] text-[15px] md:min-h-7 md:text-[13px]"

function ChipList({ k, d, items, set, sub, add, wrong, muted }: Omit<FieldProps, "value"> & {
  items: string[]; add: (done: (item: string) => void) => void; wrong?: (item: string) => string | undefined; muted?: boolean
}) {
  return (
    <SettingRow stack label={d.label} sub={sub} data-setting={k}>
      <div className="flex flex-wrap gap-1.5 sm:max-w-[60%] sm:justify-end" data-chip-list>
        {items.map((f) => (
          <span key={f} data-folder-chip={f} data-list-item={f} data-tip={wrong?.(f)}
            className={cn(chip, "max-w-full min-w-0 pr-0.5 pl-2.5", wrong?.(f) ? "border-[var(--red)] text-ink-(--red)" : "border-border", muted && "text-muted-foreground")}>
            <span className="min-w-0 truncate">{f}</span>
            <button type="button" aria-label={`Remove ${f}`} onClick={() => { const rest = items.filter((x) => x !== f); set(rest.length ? rest : []) }}
              className="grid size-9 shrink-0 cursor-pointer place-items-center rounded-full text-muted-foreground hover:bg-foreground/[0.06] hover:text-foreground md:size-6">
              <X className="size-3" strokeWidth={2.25} />
            </button>
          </span>
        ))}
        <AddChip label={d.label} add={add} onAdd={(more) => { const next = [...new Set([...items, ...more])]; if (next.length > items.length) set(next) }} />
      </div>
    </SettingRow>
  )
}

function AddChip({ label, add, onAdd }: { label: string; add: (done: (item: string) => void) => void; onAdd: (items: string[]) => void }) {
  const [typing, setTyping] = useState<string | null>(null)
  const take = (text: string) => onAdd(text.split(",").map((t) => t.trim()).filter(Boolean))
  if (typing !== null) {
    const done = () => { take(typing); setTyping(null) }
    return (
      <input autoFocus aria-label={`Add to ${label.toLowerCase()}`} value={typing} spellCheck={false} autoComplete="off" data-list-add-field
        onChange={(e) => setTyping(e.target.value)} onBlur={done}
        onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); done() } else if (e.key === "Escape") { e.stopPropagation(); setTyping(null) } }}
        className={cn(field, "h-10 w-40 rounded-full px-3 md:h-7")} />
    )
  }
  return (
    <button type="button" data-folder-add data-list-add onClick={() => add((f) => (f ? onAdd([f]) : setTyping("")))}
      className={cn(chip, "cursor-pointer border-border px-2.5 text-muted-foreground hover:text-foreground")}>
      <Plus className="size-3.5" strokeWidth={2.25} /> Add…
    </button>
  )
}

export function Folders(p: FieldProps) {
  const folders = useFolders()
  const items = (Array.isArray(p.value) ? p.value : []).flatMap((x) => trimmed(String(x)) || [])
  return <ChipList {...p} items={items} set={(v) => p.set(Array.isArray(v) && !v.length ? null : v)}
    wrong={(f) => (folders.has(f) ? undefined : `There's no folder ${f}`)} add={(done) => chooseFolder(p.d.label, done)} />
}

export function ListField(p: FieldProps) {
  const own = Array.isArray(p.value)
  const items = (Array.isArray(p.value) ? p.value : Array.isArray(p.d.default) ? p.d.default : []).map(String)
  return <ChipList {...p} items={items} muted={!own && items.length > 0} set={(v) => p.set(Array.isArray(v) && !v.length && !p.d.default ? null : v)} add={(done) => done("")} />
}

export function Chips({ k, d, value, set, sub }: FieldProps) {
  const list = Array.isArray(value) ? value : []
  return (
    <SettingRow below label={d.label} sub={sub} data-setting={k}>
      <div className="flex flex-wrap gap-1.5">
        {(d.values ?? []).map((v) => {
          const on = list.includes(v)
          return (
            <button key={String(v)} type="button" aria-pressed={on} onClick={() => set(on ? list.filter((x) => x !== v) : [...list, v])}
              className={cn("min-h-10 cursor-pointer rounded-full border-[0.5px] px-3.5 text-[15px] md:min-h-7 md:px-3 md:text-[13px]",
                on ? "border-primary bg-primary/10 text-primary" : "border-border text-muted-foreground hover:text-foreground")}>
              {valueLabel(d, v)}
            </button>
          )
        })}
      </div>
    </SettingRow>
  )
}
