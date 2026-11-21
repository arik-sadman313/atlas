import { Fragment, useEffect, useState } from "react"
import { addDays, fmtLongDay, notifyError, op } from "@vaultite"
import { type Day, JobRow, talkOf, Turn } from "./Page"

const LOOK_BACK = 14

async function dayWithTalkBefore(from: string): Promise<Day | null> {
  let d = from
  for (let i = 0; i < LOOK_BACK; i++) {
    d = addDays(d, -1)
    const r = await op<Day>("companion.conversation", { day: d })
    if (r.exchanges.length) return r
  }
  return null
}

export function EarlierDays({ before, auto }: { before: string; auto: boolean }) {
  const [days, setDays] = useState<Day[]>([])
  const [busy, setBusy] = useState(false), [end, setEnd] = useState(false)
  const got = (r: Day | null) => { if (r) setDays((x) => (x.some((d) => d.day === r.day) ? x : [r, ...x])); else setEnd(true) }
  useEffect(() => {
    if (!auto) return
    let on = true
    dayWithTalkBefore(before).then((r) => on && got(r), () => {})
    return () => { on = false }
  }, [auto, before])
  const more = () => {
    setBusy(true)
    dayWithTalkBefore(days[0]?.day ?? before).then(got, (e) => notifyError(e, "Couldn't read the earlier talk")).finally(() => setBusy(false))
  }
  return <>
    {!end && <button type="button" data-companion-earlier-days disabled={busy} onClick={more}
      className="cursor-pointer self-center rounded-[6px] px-2 py-0.5 text-[12px] text-muted-foreground hover:bg-muted hover:text-foreground disabled:cursor-default disabled:opacity-60">
      {busy ? "Looking back…" : "Earlier days"}</button>}
    {days.map((d) => <Fragment key={d.day}>
      <div className="text-center text-[11.5px] font-medium text-muted-foreground">{fmtLongDay(d.day)}</div>
      {talkOf(d, d.day).map((x) => (x.e ? <Turn key={`e${x.e.seq}-${x.e.t}`} e={x.e} compact /> : <JobRow key={`j${x.j.id}`} j={x.j} />))}
    </Fragment>)}
  </>
}
