// Drawn before chat.css (the chat's chunk) has come: plain utilities only.

export function TalkSkeleton() {
  return (
    <div className="loading-in space-y-5 pt-2" aria-busy>
      <div className="ml-auto h-10 rounded-[18px] bg-muted" style={{ width: "40%" }} />
      <div className="space-y-2.5">{["92%", "80%", "60%"].map((w) => <div key={w} className="h-3.5 rounded-chip bg-muted" style={{ width: w }} />)}</div>
      <div className="space-y-2.5 pt-2">{["40%", "33%"].map((w) => <div key={w} className="h-3.5 rounded-chip bg-muted opacity-70" style={{ width: w }} />)}</div>
    </div>
  )
}

export function ChatLoading({ fresh }: { fresh: boolean }) {
  return (
    <div className="mx-auto flex h-full max-w-3xl flex-col px-4 pt-16 pb-2 max-md:px-2.5" data-chat-loading>
      <div className="flex-1 overflow-hidden px-1">{!fresh && <TalkSkeleton />}</div>
      <div className="loading-in h-24 rounded-card border-[0.5px] border-border bg-card" />
    </div>
  )
}
