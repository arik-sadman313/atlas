import { useEffect } from "react"
import { Bot, Check, Clock, Pin, PinOff, RotateCcw, X } from "lucide-react"
import { Button, cn, detailPath, Empty, fmtAgo, haptic, Markdown, notify, notifyError, openDetail, SheetHead, useAgents, openAgentSession } from "@vaultite"
import { agentOf, answerable, answerAsk, markEventsDone, markRead, pinEvents, snoozable, unsettle, SESSION_DETAIL, useEvents } from "./events"
import { leaveSheet } from "./keyboard"
import { snoozeBelow } from "./Snoozing"
import { Questions } from "./Questions"
import { ReplyBox } from "./Reply"
import { ItemActions } from "./ItemActions"
import type { InboxEvent } from "./types"

const WHY: Record<string, string> = {
  permission: "Asks permission", question: "Asks you something", auth: "Needs you to sign in", plan: "Has a plan for you to approve",
  answer: "Answered", report: "Reported", error: "Stopped with an error",
}

const BLOCKED = ["permission", "question", "auth", "plan"]


const answer = (e: InboxEvent, a: "approve" | "deny") => (haptic("medium"), answerAsk(e, a)).then(
  () => notify(a === "approve" ? "Approved" : "Denied"), (err) => notifyError(err, "Couldn't answer it"))

const isSession = (p: { terminal?: string; session?: string }, x: InboxEvent) => x.kind === "session" && !x.machine &&
  ((!!p.terminal && x.terminal === p.terminal) || (!!p.session && x.session === p.session))
const STATE: Record<string, string> = { open: "Needs you", working: "Working", done: "Settled" }
const head = "h-11 px-3 md:h-8"

function DelegatedBy({ e }: { e: InboxEvent }) {
  const { events } = useEvents()
  if (!e.parent) return null
  const p = e.parent
  const from = events.find((x) => x.id !== e.id && isSession(p, x))
  const toParent = () => {
    if (from) return openDetail(detailPath(SESSION_DETAIL, from.id))
    void openAgentSession({ terminal: p.terminal, session: p.session, agent: p.agent, host: !p.terminal }).catch((err) => notifyError(err, "Couldn't open it"))
  }
  return <> · from <button type="button" data-lineage-parent className="cursor-pointer font-medium text-foreground/80 underline decoration-foreground/25 underline-offset-2 hover:decoration-foreground/60" onClick={toParent}>{from?.title ?? p.title}</button></>
}

function Subagents({ e }: { e: InboxEvent }) {
  const { events } = useEvents()
  const agents = useAgents()
  const kids = events.filter((x) => x.id !== e.id && x.parent && isSession(x.parent, e))
  if (!kids.length) return null
  return (
    <section className="mb-5" data-lineage>
      <h3 className="mb-1 text-[13px] font-medium text-muted-foreground max-md:text-[15px]">Subagents</h3>
      <div className="-mx-2 flex flex-col">
        {kids.map((k) => {
          const a = agentOf(k, agents), Icon = a?.icon ?? Bot
          return (
            <button key={k.id} type="button" data-lineage-child={k.id} onClick={() => openDetail(detailPath(SESSION_DETAIL, k.id))}
              className="flex min-h-8 cursor-pointer items-center gap-2 rounded-control px-2 text-left hover:bg-foreground/[0.04] max-md:min-h-11">
              <Icon className="size-4 shrink-0" style={{ color: a?.tint }} />
              <span className="min-w-0 flex-1 truncate text-[14px] max-md:text-[17px]">{k.title}</span>
              <span data-lineage-state={k.state} className={cn("flex shrink-0 items-center gap-1.5 text-[13px] max-md:text-[15px]", k.state === "open" ? "font-medium text-foreground" : "text-muted-foreground")}>
                {k.state === "open" && <span aria-hidden className="size-1.5 rounded-full bg-(--inbox)" />}{STATE[k.state]}
              </span>
            </button>
          )
        })}
      </div>
    </section>
  )
}

function Triage({ e }: { e: InboxEvent }) {
  const done = (to: boolean) => {
    haptic("medium")
    if (to) leaveSheet(e.id)
    void markEventsDone([e.id], to)
    notify(to ? `Settled “${e.title}”` : `Back in the inbox: “${e.title}”`, { action: { label: "Undo", run: () => (to ? unsettle([e]) : markEventsDone([e.id], true)) } })
  }
  if (e.state === "done") return <Button look="quiet" className={head} data-session-done="undo" onClick={() => done(false)}><RotateCcw className="size-4" /> Back to inbox</Button>
  return <>
    <Button look="quiet" className={head} data-session-done onClick={() => done(true)}><Check className="size-4" /> Settle</Button>
    <Button look="quiet" className={head} data-session-pin={e.pinned ? "on" : "off"} onClick={() => { haptic("medium"); pinEvents([e.id], !e.pinned) }}>
      {e.pinned ? <><PinOff className="size-4" /> Unpin</> : <><Pin className="size-4" /> Pin</>}
    </Button>
    {snoozable(e) && e.state !== "working" && (
      <Button look="quiet" className={head} data-session-snooze onClick={snoozeBelow([`e:${e.id}`], () => leaveSheet(e.id))}><Clock className="size-4" /> Snooze</Button>
    )}
  </>
}

export function SessionSheet({ id }: { id: string }) {
  const e = useEvents().events.find((x) => x.id === id)
  const agents = useAgents()
  const agent = e ? agentOf(e, agents) : null
  useEffect(() => { if (e && !e.read && !answerable(e)) markRead([e.id]) }, [e?.id, e?.t]) // eslint-disable-line react-hooks/exhaustive-deps
  if (!e) return <Empty>This session is no longer in the inbox.</Empty>
  const name = agent?.label ?? (e.source ? e.source[0].toUpperCase() + e.source.slice(1) : "the agent")
  const why = e.state === "working" ? "Working on it" : e.state === "done" ? "Settled" : WHY[e.ask ?? ""] ?? "Needs you"
  const sub = <>{[why, name, e.machineLabel && `on ${e.machineLabel}`, fmtAgo(e.t)].filter(Boolean).join(" · ")}<DelegatedBy e={e} /></>
  const asks = answerable(e)
  const blocked = e.state === "open" && BLOCKED.includes(e.ask ?? "")
  const answeredHere = blocked && (!e.questions || (e.questions.length === 1 && !e.questions[0].multi && !e.questions[0].closed))
  const open = () => openAgentSession({ terminal: e.terminal, session: e.session, agent: e.source, machine: e.machine, host: e.host })
  return (
    <div data-session-sheet={e.id} data-ask={e.ask ?? ""}>
      <SheetHead icon={agent?.icon ?? Bot} tint={agent?.tint ?? "var(--inbox)"} kicker="Inbox" title={e.title} sub={sub}>
        <ItemActions open={open} quiet={asks} triage={!asks && <Triage e={e} />} className="mt-3" />
      </SheetHead>
      {e.questions && blocked
        ? <Questions e={{ ...e, questions: e.questions }} />
        : e.body
        ? <Markdown text={e.body} className="mb-5 break-words" />
        : <Empty>{e.state === "done" ? "It finished with nothing to say." : "It said nothing more."}</Empty>}
      {asks && (
        <div className="mb-5 flex gap-2">
          <Button look="primary" className="h-11 px-4 md:h-8" data-gate="approve" onClick={() => void answer(e, "approve")}><Check className="size-4" /> Approve</Button>
          <Button className="h-11 px-4 md:h-8" data-gate="deny" onClick={() => void answer(e, "deny")}><X className="size-4" /> Deny</Button>
        </div>
      )}
      <Subagents e={e} />
      {!answeredHere && <ReplyBox to={e.id} name={name} open={open} sent={() => markRead([e.id])} back={() => openDetail(detailPath(SESSION_DETAIL, e.id))}
        placeholder={e.questions && blocked ? "Or tell it something else instead" : undefined} />}
    </div>
  )
}
