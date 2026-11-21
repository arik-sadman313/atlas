import { useLayoutEffect, useMemo, useRef, useState } from "react"
import { ChevronRight } from "lucide-react"
import { cn, dateText, openWebLink } from "@vaultite"
import { hostOf } from "./address"
import type { LiveStep } from "./livetabs"
import { kindOf, verbOf } from "./steps"
import { CANT, phrase, rowsOf } from "./stepwords"

const TIME = { hour: "numeric", minute: "2-digit" } as const

function Step({ steps, many }: { steps: LiveStep[]; many: boolean }) {
  const [open, setOpen] = useState(false)
  const s = steps[0], said = CANT.test(s.failed ?? ""), k = said ? kindOf({ action: "help" }) : kindOf(s), Icon = k.icon
  const same = steps.every((x) => phrase(x) === phrase(s))
  const text = steps.length === 1 ? phrase(s) : same ? phrase(s) : `${verbOf(s.action)} ${steps.length} things`
  const end = steps.at(-1)!
  return (
    <li className="flex gap-2.5 py-1" data-web-live-step={s.action}>
      <span className="mt-[3px] grid size-5 shrink-0 place-items-center rounded-full" style={{ background: `color-mix(in srgb, ${k.color} 14%, transparent)` }}>
        <Icon className="size-3" strokeWidth={2.25} style={{ color: k.color }} />
      </span>
      <span className="flex min-w-0 flex-1 flex-col">
        <span className={cn("text-[15px] leading-[20px] md:text-[13px] md:leading-[18px]", s.failed && !said && "text-ink-(--red)")}>
          {text}{steps.length > 1 && same && <span className="text-muted-foreground"> ×{steps.length}</span>}
        </span>
        {steps.length > 1 && !same && (
          <button type="button" onClick={() => setOpen(!open)} aria-expanded={open}
            className="flex w-fit cursor-pointer items-center gap-0.5 text-[12px] text-muted-foreground hover:text-foreground">
            <ChevronRight className={cn("size-3 transition-transform", open && "rotate-90")} strokeWidth={2} />{open ? "Hide them" : "Show them"}
          </button>
        )}
        {open && <ul className="mt-0.5 flex flex-col gap-0.5">{steps.map((x) => <li key={x.t} className="text-[13px] text-muted-foreground">{phrase(x)}</li>)}</ul>}
        <span className="text-[12px] text-tertiary">{dateText(end.t, TIME)}{many ? ` · ${s.by}` : ""}</span>
      </span>
    </li>
  )
}

export function LiveSteps({ steps, className }: { steps: LiveStep[]; className?: string }) {
  const rows = useMemo(() => rowsOf(steps), [steps])
  const many = useMemo(() => new Set(steps.map((s) => s.by)).size > 1, [steps])
  const box = useRef<HTMLDivElement>(null)
  const atEnd = useRef(true)
  useLayoutEffect(() => { const el = box.current; if (el && atEnd.current) el.scrollTop = el.scrollHeight }, [steps.length])
  const scrolled = () => { const el = box.current; if (el) atEnd.current = el.scrollHeight - el.scrollTop - el.clientHeight < 24 }
  return (
    <div ref={box} onScroll={scrolled} className={cn("min-h-0 overflow-y-auto overscroll-contain", className)}>
      {!steps.length ? <p className="py-1 text-[15px] text-tertiary md:text-[13px]">No agent has done anything in this tab yet.</p> : (
        <ol className="flex flex-col" data-web-live-steps={steps.length}>
          {rows.map((r) => r.kind === "page" ? (
            <li key={r.key} className="mt-2.5 mb-0.5 first:mt-0">
              <a href={r.url} onClick={(e) => { e.preventDefault(); openWebLink(r.url) }} data-web-live-step-page
                className="block truncate text-[12px] font-medium text-muted-foreground underline decoration-foreground/20 underline-offset-2 hover:text-foreground hover:decoration-foreground/60">
                {r.title || hostOf(r.url)}<span className="font-normal text-tertiary"> · {hostOf(r.url)}</span>
              </a>
            </li>
          ) : <Step key={r.key} steps={r.steps} many={many} />)}
        </ol>
      )}
    </div>
  )
}
