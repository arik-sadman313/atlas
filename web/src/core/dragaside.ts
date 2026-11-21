import { useEffect, useLayoutEffect, useState } from "react"
import { onDragEnd, type DragItem } from "@/core/drag"
import { timing } from "@/core/animation"

export function useSink(card: React.RefObject<HTMLDivElement | null>, last: React.RefObject<{ into: boolean }>) {
  const [sunk, setSunk] = useState<DragItem | null>(null)
  useEffect(() => onDragEnd((e) => { if (e.dropped && last.current.into && !e.item.drawn && !e.away) setSunk(e.item) }), [last])
  useLayoutEffect(() => {
    const c = card.current
    if (!sunk || !c) return
    const a = c.animate([{ opacity: 1 }, { opacity: 0, scale: "0.4" }], { ...timing("fast"), fill: "forwards" })
    a.finished.then(() => setSunk(null), () => {})
    return () => a.cancel()
  }, [card, sunk])
  return sunk
}

export function stepAside(kind: "tab" | "pane" | "pill", grab: { x: number; y: number }, into: boolean): React.CSSProperties {
  const moves = "translate var(--motion-spring) var(--spring), scale var(--motion-spring) var(--spring)"
  if (!into) return { transformOrigin: "0 0", transition: moves }
  const translate = kind === "pill" ? undefined : `${grab.x + 14}px ${grab.y + 10}px`
  return { transformOrigin: "0 0", transition: moves, translate, scale: kind === "pane" ? "0.5" : "0.9" }
}
