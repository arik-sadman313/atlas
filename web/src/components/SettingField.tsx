import { type KeyboardEvent, type ReactNode, useState } from "react"
import { refuse } from "@/core/animation"
import { Check, ChevronDown, ChevronRight } from "lucide-react"
import { useLive } from "@/core/data"
import type { SettingChoice } from "@/core/define"
import { valueLabel } from "@/core/pluginSettings"
import { capitalize, cn } from "@/lib/utils"
import { brief } from "@/core/brief"
import { Segmented, SettingRow, Slider } from "@/components/kit"
import { Switch } from "@/components/Switch"
import { Chips, FolderField, Folders, ListField } from "@/components/SettingLists"
import { beside, field, type FieldProps, type Offer } from "@/components/settingKit"
import { valueProblem, type OptionType, type SettingDecl } from "../../../core/blocks.ts"

const types = (d: SettingDecl) => (Array.isArray(d.type) ? d.type : [d.type])

const withCode = (s: string) => s.split(/(`[^`]+`)/).map((p, i) => (/^`.+`$/.test(p)
  ? <code key={i} className="rounded-chip bg-foreground/[0.07] px-1 font-mono text-[0.92em]">{p.slice(1, -1)}</code> : p))

export function subOf(d: SettingDecl): ReactNode {
  const full = capitalize(d.description ?? "").replace(/\.$/, "").replace(/`/g, "")
  const short = brief(d.description, [...(d.values ?? []).map(String), ...Object.values(d.labels ?? {})], true)
  if (!short) return undefined
  return short.replace(/`/g, "") === full ? withCode(short) : <span data-tip={`${full}.`}>{withCode(short)}</span>
}

const textOf = (v: unknown, sep = ", ") => (Array.isArray(v) ? v.join(sep) : v === undefined || v === null ? "" : String(v))
const fallbackText = (d: SettingDecl) => textOf(d.default, d.lines ? "\n" : ", ")

type Kind = "switch" | "choice" | "server" | "presets" | "slider" | "number" | "chips" | "folders" | "folder" | "list" | "text" | "file"
const ONE = {
  boolean: () => "switch",
  enum: (d) => (d.values?.length ? "choice" : "file"),
  string: (d) => (d.choices ? "server" : d.values?.length ? "presets" : d.folder ? "folder" : "text"),
  number: (d) => (isSliding(d) ? "slider" : "number"),
  list: (d, v) => (d.values?.length ? "chips" : d.folder ? "folders" : d.lines ? "text" : words(v) ? "list" : "file"),
  map: () => "file",
} satisfies { [T in OptionType]: (d: SettingDecl, value: unknown) => Kind }
function kindOf(d: SettingDecl, value: unknown): Kind {
  const ts = types(d)
  if (ts.length === 1) return ONE[ts[0]](d, value)
  return ts.every((t) => t === "string" || t === "list") && words(value) ? "text" : "file"
}
const words = (v: unknown) => !Array.isArray(v) || v.every((x) => typeof x === "string" || typeof x === "number")
const isSliding = ({ min, max, step }: SettingDecl) => min !== undefined && max !== undefined && step !== undefined

const FIELDS: Record<Exclude<Kind, "switch" | "file">, (p: FieldProps) => ReactNode> = {
  choice: (p) => <Choice {...p} value={p.value ?? p.d.default} />, server: (p) => <ServerChoice {...p} />, presets: (p) => <Presets {...p} />,
  slider: (p) => <SliderField {...p} />, number: (p) => <NumberField {...p} />, chips: (p) => <Chips {...p} value={p.value ?? p.d.default} />,
  folders: (p) => <Folders {...p} />, folder: (p) => <FolderField {...p} />, list: (p) => <ListField {...p} />, text: (p) => <TextField {...p} />,
}

/** One setting as a form row, by its declaration (a panel's own too: File explorer's, in files.json); `set(undefined)`
 *  puts the default back; `sub`: what it's doing now, in place of its description. */
export function Field({ offer, ...p }: FieldProps & { offer?: Offer }) {
  const kind = kindOf(p.d, p.value)
  if (offer && kind !== "switch" && types(p.d).join() === "string") return <OfferedChoice {...p} offer={offer} />
  const sub = p.sub ?? subOf(p.d)
  if (kind === "switch") {
    return (
      <SettingRow label={p.d.label} sub={sub} data-setting={p.k}>
        <Switch on={(p.value ?? p.d.default) === true} onChange={p.set} label={p.d.label} />
      </SettingRow>
    )
  }
  if (kind === "file") return <SettingRow label={p.d.label} sub={<>{sub}{sub && ". "}Change it with Edit as JSON, below</>} data-setting={p.k} />
  return FIELDS[kind]({ ...p, sub })
}

function OfferedChoice({ offer, ...p }: FieldProps & { offer: Offer }) {
  const list = offer()
  if (!list) return <Field {...p} />
  const shown = textOf(p.value) || textOf(p.d.default)
  const all = list.some((c) => c.value === shown) || !shown ? list : [...list, { value: shown, label: p.d.labels?.[shown] ?? `${shown} (not connected)` }]
  return <Choice {...p} d={choicesOf(p.d, all)} value={shown} />
}

function choicesOf(d: SettingDecl, list: SettingChoice[]): SettingDecl {
  const all = d.unset && !list.some((c) => c.value === "") ? [{ value: "", label: d.unset }, ...list] : list
  return { ...d, type: "enum", values: all.map((c) => c.value), labels: Object.fromEntries(all.map((c) => [c.value, c.label])) }
}

function ServerChoice(p: FieldProps) {
  const { data } = useLive<{ choices: SettingChoice[] }>(p.d.choices!)
  const list = data?.choices ?? []
  if (!list.length) return <SettingRow label={p.d.label} sub={p.sub} value={textOf(p.value) || p.d.unset} data-setting={p.k} />
  return <Choice {...p} d={choicesOf(p.d, list)} value={p.value ?? textOf(p.d.default)} />
}

function Presets(p: FieldProps) {
  const values = (p.d.values ?? []).map(String), shown = textOf(p.value ?? p.d.default)
  const [own, setOwn] = useState(false)
  const custom = own || !values.includes(shown)
  const choices: SettingDecl = { ...p.d, type: "enum", values: [...values, CUSTOM], labels: { ...p.d.labels, [CUSTOM]: "Custom" } }
  return (
    <>
      <Choice {...p} d={choices} value={custom ? CUSTOM : shown} set={(v) => { setOwn(v === CUSTOM); if (v !== CUSTOM) p.set(v) }} />
      {custom && <TextField k={`${p.k}-custom`} d={{ ...p.d, label: "Custom", description: "", default: undefined }} value={values.includes(shown) ? "" : shown} set={p.set} />}
    </>
  )
}
const CUSTOM = "\0custom"

function Choice(p: FieldProps) {
  const values = p.d.values ?? []
  const fits = values.length <= 3 && values.every((v) => valueLabel(p.d, v).length <= 12)
  return fits ? <SegmentedChoice {...p} /> : <ListChoice {...p} />
}

function SegmentedChoice({ k, d, value, set, sub }: FieldProps) {
  const values = d.values ?? []
  return (
    <SettingRow stack label={d.label} sub={sub} data-setting={k}>
      <Segmented className="max-sm:w-full [&>button]:whitespace-nowrap" label={d.label} value={textOf(value)}
        options={values.map((v) => ({ value: String(v), label: valueLabel(d, v) }))} onChange={(s) => set(values.find((v) => String(v) === s))} />
    </SettingRow>
  )
}

function saidOf(d: SettingDecl, text: string) {
  return (d.values ?? []).some((v) => String(v) === text) ? valueLabel(d, text) : text ? valueLabel(d, text) : d.unset ?? ""
}

function ListChoice({ k, d, value, set, sub }: FieldProps) {
  const [open, setOpen] = useState(false)
  const unset = !textOf(value), said = saidOf(d, textOf(value))
  const below = said.length > 30 ? "always" : said.length > 18 ? "phone" : null
  const values: (string | number | undefined)[] = d.unset && !(d.values ?? []).some((v) => v === "") ? [undefined, ...d.values ?? []] : d.values ?? []
  return (
    <div data-setting={k}>
      <SettingRow label={d.label} onClick={() => setOpen(!open)} chevron={open ? ChevronDown : ChevronRight} aria-expanded={open}
        sub={below ? <>{sub}<span className={cn("block text-[15px] leading-[20px] text-foreground/80 md:text-[13px] md:leading-[18px]", below === "phone" && "md:hidden")} data-value-below>{said}</span></> : sub}
        value={below === "always" ? undefined : <span className={cn(below && "max-md:hidden", unset && "text-muted-foreground")}>{said}</span>} />
      {open && (
        <div role="radiogroup" aria-label={d.label} className="-mt-1 pb-2 pl-1">
          {values.map((v) => {
            const on = v === undefined ? unset : String(v) === textOf(value)
            return (
              <button key={textOf(v)} type="button" role="radio" aria-checked={on} onClick={() => { set(v); setOpen(false) }}
                className="flex min-h-11 w-full cursor-pointer items-center gap-2.5 rounded-control px-2 text-left text-[15px] hover:bg-foreground/[0.04] md:min-h-9 md:text-[14px]">
                <Check className={cn("size-4 shrink-0 text-primary", !on && "invisible")} strokeWidth={2.5} />
                {v === undefined ? d.unset : valueLabel(d, v)}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

function useTyped(value: unknown, d: SettingDecl, sep = ", ") {
  const [typed, setTyped] = useState<string | null>(null)
  const unset = value === undefined || value === null
  return { typed, setTyped, text: typed ?? (unset ? fallbackText(d) : textOf(value, sep)), muted: typed === null && unset }
}

function NumberField({ k, d, value, set, sub }: FieldProps) {
  const { typed, setTyped, text, muted } = useTyped(value, d)
  const n = (typed ?? "").trim() === "" ? null : Number(typed)
  const why = typed === null || n === null ? "" : Number.isNaN(n) ? "should be a number" : valueProblem(d, n)
  const save = () => { if (typed !== null && !why) set(n); if (!why) setTyped(null) }
  return (
    <SettingRow label={d.label} sub={why ? <span className="text-ink-(--red)">{capitalize(why)}</span> : sub} data-setting={k}>
      <input inputMode="decimal" aria-label={d.label} value={text} placeholder={d.unset ?? ""} data-default={muted || undefined}
        aria-invalid={!!why || undefined} onChange={(e) => setTyped(e.target.value)} onBlur={save}
        onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); if (why) refuse(e.currentTarget); else e.currentTarget.blur() } else if (e.key === "Escape") { e.stopPropagation(); setTyped(null) } }}
        className={cn(field, "w-20 text-right tabular-nums", muted && "text-muted-foreground", why && "border-[var(--red)]")} />
    </SettingRow>
  )
}

function SliderField({ k, d, value, set, sub }: FieldProps) {
  const at = Number(value ?? d.default ?? d.min)
  const [held, setHeld] = useState<number | null>(null)
  const shown = held ?? at
  return (
    <SettingRow stack label={d.label} sub={sub} data-setting={k}>
      <div className={cn("flex items-center gap-3", beside)}>
        <Slider value={at} min={d.min} max={d.max} step={d.step} label={d.label} onInput={setHeld} onChange={(v) => { setHeld(null); set(v) }} className="min-w-0 flex-1" />
        <span className={cn("w-10 shrink-0 text-right text-[14px] tabular-nums", value === undefined && held === null ? "text-muted-foreground" : "text-foreground")}>
          {Number(shown.toFixed(2))}
        </span>
      </div>
    </SettingRow>
  )
}

function textRow(d: SettingDecl, settled: string) {
  const lines = d.lines === true, list = types(d).includes("list")
  const area = lines || (!list && (settled.includes("\n") || settled.length > 80))
  return { lines, list, area, short: !area && Math.max(settled.length, (d.unset ?? "").length) <= 12 }
}

export function TextField({ k, d, value, set, sub }: FieldProps) {
  const sep = d.lines ? "\n" : ", "
  const { lines, list, area, short } = textRow(d, textOf(value ?? d.default, sep))
  const { typed, setTyped, text, muted } = useTyped(value, d, sep)
  const save = () => {
    if (typed === null) return
    const t = typed.trim()
    set(list && t ? t.split(lines ? /\r?\n/ : ",").map((s) => s.trim()).filter(Boolean) : t)
    setTyped(null)
  }
  const keys = (e: KeyboardEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !area) { e.preventDefault(); e.currentTarget.blur() } else if (e.key === "Escape") { e.stopPropagation(); setTyped(null) }
  }
  const common = { "aria-label": d.label, value: text, spellCheck: area && !lines, autoComplete: "off", onChange: (e: { target: { value: string } }) => setTyped(e.target.value), onBlur: save, onKeyDown: keys, "data-default": muted || undefined }
  const tone = muted && "text-muted-foreground"
  return (
    <SettingRow stack={!area && !short} below={area} label={d.label} sub={sub} data-setting={k}>
      {area
        ? <textarea {...common} placeholder={lines ? "One per line" : d.unset} rows={Math.min(8, Math.max(3, Math.ceil(text.length / 70) + text.split("\n").length))}
          className={cn(field, "h-auto w-full resize-y py-1.5 md:h-auto", lines && "font-mono", tone)} />
        : <input {...common} placeholder={d.unset ?? "Not set"} className={cn(field, short ? "w-36 text-right sm:w-60 sm:shrink-0 sm:text-left" : beside, tone)} />}
    </SettingRow>
  )
}
