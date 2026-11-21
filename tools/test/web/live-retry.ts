import { check } from "../lib.ts"
import { type Any, web } from "./lib.ts"

{
  const g: Any = globalThis
  const was = { setTimeout: g.setTimeout, clearTimeout: g.clearTimeout, now: Date.now, document: g.document, add: g.addEventListener, remove: g.removeEventListener }
  let now = 1_000_000
  let timers: { at: number; fn: () => void; id: number }[] = []
  let ids = 0
  g.setTimeout = (fn: () => void, ms: number) => { const id = ++ids; timers.push({ at: now + ms, fn, id }); return id }
  g.clearTimeout = (id: number) => { timers = timers.filter((t) => t.id !== id) }
  Date.now = () => now
  const advance = (ms: number) => {
    const until = now + ms
    for (let t = timers.sort((a, b) => a.at - b.at)[0]; t && t.at <= until; t = timers.sort((a, b) => a.at - b.at)[0]) {
      timers = timers.filter((x) => x !== t)
      now = t.at
      t.fn()
    }
    now = until
  }
  const win = new EventTarget(), doc = Object.assign(new EventTarget(), { visibilityState: "visible" })
  g.document = doc
  g.addEventListener = win.addEventListener.bind(win); g.removeEventListener = win.removeEventListener.bind(win)
  try {
    const { askAgain, BACKOFF }: { askAgain(ask: () => void): () => void; BACKOFF: number[] } = await web("core/liveread.ts")
    const connection: Any = await web("core/connection.ts")
    const at: number[] = []
    const start = now
    const stop = askAgain(() => at.push(now - start))
    advance(2_000 + 5_000 + 15_000 + 30_000 + 30_000)
    check("retry: a failed read asks again after 2, 5, 15 and 30 s, then every 30 s", JSON.stringify(at) === JSON.stringify([2_000, 7_000, 22_000, 52_000, 82_000]) && BACKOFF.at(-1) === 30_000, at)
    stop()

    let asked = 0
    const stop3 = askAgain(() => asked++)
    doc.visibilityState = "hidden"; doc.dispatchEvent(new Event("visibilitychange"))
    advance(120_000)
    const hidden = asked
    doc.visibilityState = "visible"; doc.dispatchEvent(new Event("visibilitychange"))
    check("retry: nothing is asked while the page is hidden, and it asks at once when it's shown", hidden === 0 && asked === 1, { hidden, asked })
    advance(1_500)
    win.dispatchEvent(new Event("online"))
    connection.reachedServer()
    const together = asked
    advance(1_000)
    win.dispatchEvent(new Event("online"))
    check("retry: the network back and the server back ask at once, one ask for both", together === 2 && asked === 3, { together, asked })
    stop3()
    const after = asked
    win.dispatchEvent(new Event("online")); connection.reachedServer(); advance(120_000)
    check("retry: stopped, nothing asks again", asked === after, asked - after)

    const { untilUnreachable, WRITE_CHECK, GRACE, setServerCheck, lostServer, reachedServer, isOffline } = connection
    let checks = 0
    setServerCheck(() => checks++)
    const slow = untilUnreachable()
    advance(WRITE_CHECK)
    check("write: unanswered on a live connection, it checks the connection and keeps waiting", checks === 1 && !slow.signal.aborted, { checks })
    advance(10 * 60_000)
    check("write: a long call on a live connection is never cut off", !slow.signal.aborted)
    lostServer()
    advance(GRACE - 1)
    const before = slow.signal.aborted
    advance(1)
    check("write: once the server's known lost, it gives up", !before && isOffline() && slow.signal.aborted)
    const late = untilUnreachable()
    advance(WRITE_CHECK - 1)
    const waited = !late.signal.aborted
    advance(1)
    check("write: one made while offline gets WRITE_CHECK to answer, then gives up", waited && late.signal.aborted)
    reachedServer()
    const answered = untilUnreachable()
    answered.end()
    lostServer(); advance(GRACE + WRITE_CHECK)
    check("write: one answered is let go: losing the server later doesn't touch it", !answered.signal.aborted)
    reachedServer()

    const { liveShown }: { liveShown(path: string | null, got: Any, failed: Any, retry: () => void): Any } = await web("core/liveread.ts")
    const failed = { text: "The server didn't answer.", cause: new TypeError("Failed to fetch") }
    const none = liveShown("a", { path: null, data: null }, failed, () => {})
    const own = liveShown("a", { path: "a", data: { n: 1 } }, failed, () => {})
    const other = liveShown("b", { path: "a", data: { n: 1 } }, failed, () => {})
    check("live: a failure with nothing to show is the error; with the path's own answer shown, it stays, stale",
      none.error === failed.text && !none.loading && !none.stale && own.error === null && own.stale && own.data.n === 1 && own.cause === failed.cause, { none, own })
    check("live: another path's answer shown meanwhile doesn't hide this one's failure", other.error === failed.text && !other.stale && other.data.n === 1, other)
    check("live: on its way, loading; came, neither", liveShown("a", { path: null, data: null }, null, () => {}).loading && !liveShown("a", { path: "a", data: 1 }, null, () => {}).stale)
  } finally {
    Object.assign(g, { setTimeout: was.setTimeout, clearTimeout: was.clearTimeout, document: was.document, addEventListener: was.add, removeEventListener: was.remove })
    Date.now = was.now
  }
}
