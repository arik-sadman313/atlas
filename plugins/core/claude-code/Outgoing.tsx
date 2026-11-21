import { UserMessage } from "./Entries"
import type { Out } from "./outbox"

export function Outgoing({ outs, className }: { outs: Out[]; className?: string }) {
  if (!outs.length) return null
  return (
    <div className={className} data-outgoing>
      {outs.map((o) => (
        <div key={o.key} data-out={o.sent === undefined ? "sending" : "sent"} className="flex flex-col items-end gap-1">
          <UserMessage e={{ k: "user", id: o.key, text: o.text, at: "", images: o.pictures.map((p) => ({ src: p.url })) }} />
          {o.sent === undefined && <span role="status" className="loading-in pr-1 text-[12px] text-muted-foreground max-md:text-[13px]">Sending…</span>}
        </div>
      ))}
    </div>
  )
}
