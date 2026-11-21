import { useState } from "react"
import { Monitor } from "lucide-react"
import { Button, Empty, SheetHead } from "@vaultite"
import { fixEvent, useEvents } from "./events"

export function ElsewhereSheet({ id }: { id: string }) {
  const { events } = useEvents()
  const [busy, setBusy] = useState(false)
  const e = events.find((x) => x.id === id)
  if (!e) return <Empty>This was dealt with: it's no longer in the inbox.</Empty>
  const where = e.machineLabel ?? e.machine ?? "another machine"
  const open = e.fix && e.state !== "done"
  const fix = async () => { setBusy(true); try { await fixEvent(e) } finally { setBusy(false) } }
  return (
    <div data-inbox-elsewhere={e.id}>
      <SheetHead icon={Monitor} tint="var(--inbox)" kicker={`Inbox · on ${where}`} title={e.title} />
      {e.body && <p data-elsewhere-body className="mb-3 text-[15px] leading-[21px] break-words whitespace-pre-wrap select-text md:text-[14px] md:leading-[20px]">{e.body}</p>}
      <p className="mb-4 text-[14px] leading-[19px] text-muted-foreground md:text-[13px] md:leading-[18px]">
        It happened on {where}, so it's dealt with there{open ? `: ${e.fix!.label} runs it on ${where}` : ""}. This machine's own copy may differ.
      </p>
      {open ? <Button look="primary" disabled={busy} onClick={() => void fix()} data-elsewhere-fix={e.id}>{busy ? `${e.fix!.label}…` : `${e.fix!.label} on ${where}`}</Button>
        : <p className="text-[14px] text-muted-foreground" data-elsewhere-done>Dealt with.</p>}
    </div>
  )
}
