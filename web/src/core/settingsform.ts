import { capitalize } from "@/lib/utils"
import { whenOf, type SettingDecl, type SettingDecls } from "../../../core/blocks.ts"

export type FormGroup = { title: string; rows: string[]; advanced: string[]; folded: boolean }
type TextOf = (k: string) => string

export function formGroups(decls: SettingDecls): FormGroup[] {
  const by = new Map<string, string[]>([["", []]])
  for (const k of Object.keys(decls)) by.set(decls[k].group ?? "", [...(by.get(decls[k].group ?? "") ?? []), k])
  return [...by].flatMap(([title, ks]) => {
    const rows = ks.filter((k) => !decls[k].advanced), advanced = ks.filter((k) => decls[k].advanced)
    return ks.length ? [{ title, rows, advanced, folded: !rows.length }] : []
  })
}

export function applies(decls: SettingDecls, k: string, textOf: TextOf, depth = 0): boolean {
  const when = decls[k]?.when
  if (!when || depth > 8) return true
  const [on, values] = whenOf(when)
  return (values ? values.includes(textOf(on)) : textOf(on) === "true") && applies(decls, on, textOf, depth + 1)
}

export function depthOf(decls: SettingDecls, k: string): number {
  let depth = 0
  for (let when = decls[k]?.when; when && depth < 4; when = decls[whenOf(when)[0]]?.when) depth++
  return depth
}

export const valueText = (d: SettingDecl, text: string) => (text ? d.labels?.[text] ?? capitalize(text) : d.unset ?? "")

export function summaryOf(decls: SettingDecls, keys: string[], textOf: TextOf) {
  return keys.flatMap((k) => (decls[k].type === "boolean" || decls[k].type === "list" ? [] : [valueText(decls[k], textOf(k))]))
    .slice(0, 3).filter(Boolean).join(" · ")
}
