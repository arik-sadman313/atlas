import type { CSSProperties } from "react"
import { colorVar } from "@vaultite"

export const tintWash = (tint: string | undefined, on: boolean): CSSProperties | undefined => {
  if (!tint) return undefined
  const c = `color-mix(in oklab, ${colorVar(tint)} ${on ? 22 : 10}%, transparent)`
  return { backgroundImage: `linear-gradient(${c}, ${c})` }
}

export const laneWash = (tint: string | undefined): CSSProperties | undefined => {
  if (!tint) return undefined
  const c = (p: number) => `color-mix(in oklab, ${colorVar(tint)} ${p}%, transparent)`
  return { backgroundImage: `linear-gradient(${c(16)}, ${c(5)} 7rem, ${c(5)})` }
}
