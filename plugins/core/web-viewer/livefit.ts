import { useLayoutEffect, useState, type RefObject } from "react"

const MAX_FIT = 2, FRAME_PAD = 12

export function useRoom(el: RefObject<HTMLElement | null>) {
  const [room, setRoom] = useState({ w: 0, h: 0 })
  useLayoutEffect(() => {
    const e = el.current
    if (!e) return
    const ro = new ResizeObserver(() => setRoom((r) => (r.w === e.clientWidth && r.h === e.clientHeight ? r : { w: e.clientWidth, h: e.clientHeight })))
    ro.observe(e)
    return () => ro.disconnect()
  }, [el])
  return room
}

export function fitIn(w: number, h: number, room: { w: number; h: number }) {
  const s = Math.min(MAX_FIT, (room.w - FRAME_PAD * 2) / w, (room.h - FRAME_PAD * 2) / h)
  return { w: Math.max(1, Math.round(w * s)), h: Math.max(1, Math.round(h * s)) }
}
