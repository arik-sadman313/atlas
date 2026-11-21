import type { Side } from "./layout.ts"

export const SPLITS = ["right", "left", "down", "up"] as const
export type SplitTo = (typeof SPLITS)[number]
export const isSplitTo = (v: unknown): v is SplitTo => SPLITS.some((x) => x === v)
export const splitSide = (s: SplitTo): Side => (s === "down" ? "bottom" : s === "up" ? "top" : s)
