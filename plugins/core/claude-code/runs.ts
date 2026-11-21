import { useMemo } from "react"
import { splitMachine, statusOf, stem, useAccountNames, useLive, type AgentFeed, type AgentRun } from "@vaultite"
import { agentTint } from "../../../core/agenttint.ts"
import { type Awaits, awaitsLine } from "../../../core/attention.ts"

type Chat = { id: string; state: "starting" | "working" | "waiting" | "idle" | "error"; cwd: string; account?: string; project?: string; by: string; started: number; at: number
  asks: string[]; title?: string; error?: string; turn: { prompt: string; text: string; error?: string } | null
  progress?: string; awaits?: Awaits }

const EVERY = 4000
const firstLine = (t: string | undefined) => t?.trim().split("\n")[0]?.slice(0, 120) || undefined

export function useChatRuns(): AgentFeed {
  const { data, error, cause, retry } = useLive<{ sessions: Chat[] }>("claude-code/chats", undefined, false, EVERY)
  const accountName = useAccountNames()
  const status = statusOf(cause)
  const unreachable = cause !== undefined && !(status && status < 500) ? "Claude Code's chats" : undefined
  const runs = useMemo(() => {
    if (!data) return error ? [] : null
    return data.sessions.map((c): AgentRun => {
      const [id, machine] = splitMachine(c.id)
      const needs = c.state === "waiting" || c.asks.length > 0, failed = c.state === "error", awaits = c.state === "idle" ? c.awaits : undefined
      return {
        id: `chat:${c.id}`, kind: "chat", title: c.title || firstLine(c.turn?.prompt) || stem(c.cwd) || "Chat",
        step: needs ? "Waiting for your answer" : failed ? firstLine(c.error ?? c.turn?.error) : c.state === "working" ? c.progress || firstLine(c.turn?.prompt)
          : awaits ? awaitsLine(awaits) : firstLine(c.turn?.text),
        state: needs ? "needs" : c.state === "working" || c.state === "starting" ? "working" : awaits ? "waiting" : "done", failed,
        machine, agent: "Claude Code", tint: `var(--${agentTint(id)})`, session: id, account: accountName("claude", machine ?? "", c.account) || undefined,
        project: c.project || stem(c.cwd) || undefined, at: c.at || c.started, to: `view:claude-session/${c.id}`,
      }
    })
  }, [data, error, accountName])
  return useMemo(() => ({ runs, unreachable, retry }), [runs, unreachable, retry])
}
