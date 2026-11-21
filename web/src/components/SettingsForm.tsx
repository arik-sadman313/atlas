import { type ReactNode, useState } from "react"
import { ChevronDown, ChevronRight } from "lucide-react"
import { useStore } from "@/core/data"
import { notifyError } from "@/core/notify"
import { pluginById, usePluginsVersion } from "@/core/plugins"
import { pluginSettings, settingAsked } from "@/core/pluginSettings"
import { applies, depthOf, formGroups, summaryOf, type FormGroup } from "@/core/settingsform"
import { AND } from "@/core/bundlenames"
import { cn } from "@/lib/utils"
import { Group, Section, SettingRow } from "@/components/kit"
import { Field } from "@/components/SettingField"
import type { Offer } from "@/components/settingKit"
import type { SettingDecl, SettingDecls } from "../../../core/blocks.ts"

function useSettings(id: string, decls: SettingDecls) {
  const data = pluginSettings(id).use(true)
  const seeds = useStore().store?.settingDefaults?.[`plugins/${id}/data`]
  if (!data) return null
  const declOf = (k: string): SettingDecl => (seeds && Object.hasOwn(seeds, k) ? { ...decls[k], default: seeds[k] } : decls[k])
  const set = (k: string, v: unknown) => {
    const next = v === undefined || v === null || v === "" || JSON.stringify(v) === JSON.stringify(declOf(k).default) ? null : v
    pluginSettings(id).set({ [k]: next }).catch((e) => notifyError(e, "Couldn't save it"))
  }
  return { data, declOf, set, textOf: (k: string) => String(data[k] ?? declOf(k).default ?? "") }
}
type Settings = NonNullable<ReturnType<typeof useSettings>>

type FormProps = { id: string; decls: SettingDecls; offers?: Record<string, Offer>; lead?: ReactNode }

export function SettingsForm({ id, decls, offers, lead }: FormProps) {
  const s = useSettings(id, decls)
  if (!s) return <Group><div className="min-h-12" aria-busy /></Group>
  const groups = formGroups(decls)
  const field = (k: string, inFold = false) => {
    const on = applies(decls, k, s.textOf)
    if (inFold && !on) return null
    const depth = inFold ? 0 : depthOf(decls, k)
    return (
      <div key={k} data-setting-row={k} data-inactive={!on || undefined} className={cn(depth === 1 && "ml-5", depth > 1 && "ml-10")}>
        <div className={cn("transition-opacity", !on && "opacity-45")}>
          <Field k={k} d={s.declOf(k)} value={s.data[k]} set={(v) => s.set(k, v)} offer={offers?.[k]} />
        </div>
      </div>
    )
  }
  return (
    <>
      {lead && groups[0]?.title && <Group>{lead}</Group>}
      {groups.map((g, i) => {
        const rows = <GroupRows g={g} s={s} decls={decls} field={field} lead={i === 0 && !g.title ? lead : null} plugin={id} />
        return g.title && !g.folded
          ? <div key={g.title} data-settings-group={g.title}><Section title={g.title}>{rows}</Section></div>
          : <div key={g.title || "-"} data-settings-group={g.title || undefined}>{rows}</div>
      })}
    </>
  )
}

const namesOf = (names: string[]) => (names.length > 3 ? `${names.slice(0, 2).join(", ")} and ${names.length - 2} more` : AND.format(names))

function GroupRows({ g, s, decls, field, lead, plugin }: { g: FormGroup; s: Settings; decls: SettingDecls; field: (k: string, inFold?: boolean) => ReactNode; lead: ReactNode; plugin: string }) {
  const [open, setOpen] = useState(false)
  const asked = settingAsked.use((a) => a?.id === plugin && g.advanced.includes(a.key))
  if (asked && !open) setOpen(true)
  const folded = g.advanced.filter((k) => applies(decls, k, s.textOf))
  const fold = (g.folded || folded.length > 0) && (
    <SettingRow label={g.folded ? g.title : "Advanced"} onClick={() => setOpen(!open)} chevron={open ? ChevronDown : ChevronRight} aria-expanded={open}
      data-settings-fold={g.title || "Advanced"}
      sub={open || g.folded ? undefined : namesOf(folded.map((k) => decls[k].label))}
      value={!open && g.folded ? summaryOf(decls, g.advanced, s.textOf) : undefined} />
  )
  return (
    <Group>
      {lead}
      {g.rows.map((k) => field(k))}
      {fold}
      {open && g.advanced.map((k) => field(k, true))}
    </Group>
  )
}

/** One of a plugin's declared settings as its form draws it, for its settingsPanel to place (settingsPanelDraws). */
export function PluginSetting({ plugin, k, sub }: { plugin: string; k: string; sub?: ReactNode }) {
  usePluginsVersion()
  const decls = pluginById(plugin)?.settingsDecls ?? {}
  const s = useSettings(plugin, decls)
  if (!s || !decls[k]) return null
  return <Field k={k} d={s.declOf(k)} value={s.data[k]} set={(v) => s.set(k, v)} sub={sub} />
}
