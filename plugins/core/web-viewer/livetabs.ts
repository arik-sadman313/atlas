export type LiveAsk = { reason: string; by: string; at: number; agent?: string; terminal?: string; session?: string; machine?: string; where?: string }
export type LiveTab = { tab: number; url: string; title: string; loading: boolean; paused: boolean; ask: LiveAsk | null; opener: number | null
  container: string | null; by: string | null; task: string; summary: string; shown: boolean; opened: number | null; appTab: string
  machine?: string; machineLabel?: string }
export type LiveTabs = { tabs: LiveTab[]; self?: string | null }
export type LiveStep = { t: number; by: string; action: string; url: string; title: string; name?: string; value?: string; fields?: string[]
  site?: string; result?: string; failed?: string }
