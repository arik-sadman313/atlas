import { useLayoutEffect, useMemo, useRef, type RefObject } from "react"
import { CornerDownLeft, Undo2, type LucideIcon } from "lucide-react"
import { useGiveKeys, type FieldKeys } from "@/core/keyboard"

const key = (Icon: LucideIcon, text: string) => <span className="flex items-center gap-1.5 font-sans text-[14px]"><Icon className="size-[17px]" strokeWidth={2} />{text}</span>

export default function TitleKeys({ field, back, next }: { field: RefObject<HTMLTextAreaElement | null>; back?: () => void; next: (t: HTMLTextAreaElement) => void }) {
  const latest = useRef({ back, next })
  useLayoutEffect(() => { latest.current = { back, next } })
  const backs = !!back
  useGiveKeys(useMemo<FieldKeys>(() => ({
    label: "Name keys", owns: (el) => el === field.current,
    keys: () => [
      ...(backs ? [{ name: "Put the name back", label: key(Undo2, "Put back"), run: () => latest.current.back?.() }] : []),
      { name: "Go to the text", label: key(CornerDownLeft, "Go to the text"), run: () => { if (field.current) latest.current.next(field.current) } },
    ],
  }), [field, backs]))
  return null
}
