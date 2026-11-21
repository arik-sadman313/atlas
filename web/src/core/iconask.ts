import type { ComponentType } from "react"
import { signal } from "@/core/signal"

export type IconAsk = { title: string; current?: string; onPick: (name: string) => void; onClose?: () => void
  noIcon?: { label: string; mark: ComponentType<{ className?: string }>; onPick: () => void } }
let asking: IconAsk | null = null
const subs = signal()
/** Ask the user for an icon: `onPick` gets its name (`guitar`) or the emoji; `onClose` runs as it closes, picked or not. */
export function pickIcon(a: IconAsk | null) { asking = a; subs.notify() }
export const useIconAsk = () => subs.use(() => asking)
