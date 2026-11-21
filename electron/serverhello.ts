import type { EventEmitter } from "node:events"

export function heardHello(child: Pick<EventEmitter, "on">) {
  let spoke: unknown, came = false
  const waiting = new Set<() => void>()
  child.on("message", (m: { type?: string; protocol?: unknown } | null) => {
    if (m?.type !== "desktop:hello") return
    spoke = m.protocol
    came = true
    for (const done of waiting) done()
  })
  return (ms: number) => came ? Promise.resolve(spoke) : new Promise<unknown>((ok) => {
    const done = () => { clearTimeout(timer); waiting.delete(done); ok(spoke) }
    const timer = setTimeout(done, ms)
    waiting.add(done)
  })
}
