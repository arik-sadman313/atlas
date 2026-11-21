export type FocusEvent = { type: "raise"; how: "app" | "through" | null } | { type: "press"; page: number } | { type: "appBlurred" } | { type: "gone"; page: number }
export type FocusMove = { kept: number | null; off: number | null; on: number | null }

export function focusStep(kept: number | null, e: FocusEvent, withKeyboard: number | null = null): FocusMove {
  const to = e.type === "raise" ? (e.how === "through" ? kept ?? withKeyboard : null)
    : e.type === "press" ? e.page : e.type === "gone" && kept !== e.page ? kept : null
  if (to === kept) return { kept, off: null, on: null }
  return { kept: to, off: e.type === "gone" ? null : kept, on: to }
}
