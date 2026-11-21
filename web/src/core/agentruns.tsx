import { memo, useCallback, useEffect, useMemo, useState, type ReactNode } from "react"
import type { AgentRun } from "@/core/define"
import { orderRuns, type AgentFeed, type Unreachable } from "@/core/agentorder"
import { active } from "@/core/plugins"
import { usePrefs } from "@/core/prefs"

type Use = () => AgentFeed
// A component per plugin's hook: plugins coming and going would break the rules of hooks.
const Feed = memo(function Feed({ id, use, report }: { id: string; use: Use; report: (id: string, feed: AgentFeed | undefined) => void }) {
  const feed = use()
  useEffect(() => report(id, feed), [id, feed, report])
  useEffect(() => () => report(id, undefined), [id, report])
  return null
})

/** Every agent the plugins that are on know of, in order; whether some haven't said yet (`loading`), and which can't be
 *  reached (`unreachable`). `feeds` must be drawn (it draws nothing): it's what asks. Off (`on` false), nothing is asked. */
export function useAgentRuns(on = true): { runs: AgentRun[]; loading: boolean; unreachable: Unreachable[]; feeds: ReactNode } {
  const { disabled } = usePrefs()
  const plugins = useMemo(() => active(disabled).filter((p) => p.agentRuns), [disabled])
  const [got, setGot] = useState<Record<string, AgentFeed | undefined>>({})
  const report = useCallback((id: string, feed: AgentFeed | undefined) => setGot((g) => (g[id] === feed ? g : { ...g, [id]: feed })), [])
  const runs = useMemo(() => orderRuns(plugins.flatMap((p) => got[p.id]?.runs ?? [])), [plugins, got])
  const unreachable = useMemo(() => plugins.flatMap((p) => {
    const f = got[p.id]
    return f?.unreachable ? [{ what: f.unreachable, retry: f.retry }] : []
  }), [plugins, got])
  const loading = on && plugins.some((p) => got[p.id]?.runs == null && !got[p.id]?.unreachable)
  const feeds = on ? plugins.map((p) => <Feed key={p.id} id={p.id} use={p.agentRuns!} report={report} />) : null
  return { runs: on ? runs : [], loading, unreachable: on ? unreachable : [], feeds }
}
