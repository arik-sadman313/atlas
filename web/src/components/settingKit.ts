import type { ReactNode } from "react"
import type { SettingChoice } from "@/core/define"
import type { SettingDecl } from "../../../core/blocks.ts"

export type FieldProps = { k: string; d: SettingDecl; value: unknown; set: (v: unknown) => void; sub?: ReactNode }
export type Offer = () => SettingChoice[] | null

export const field = "h-11 min-w-0 rounded-control border-[0.5px] border-border bg-card px-2.5 text-[16px] outline-none placeholder:text-muted-foreground focus:border-primary md:h-7 md:px-2 md:text-[14px]"
export const beside = "w-full sm:w-60 sm:shrink-0"
