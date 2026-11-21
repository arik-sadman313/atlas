import { useEffect, useState } from "react"
import { Copy, RotateCcw } from "lucide-react"
import { Button, cn, colorVar, copyText, DiffRows, Loading, Markdown, notify, notifyError, plural, splitFm, Switch, textDiff, type DiffLine } from "@vaultite"
import { changes, type Counts, type Piece } from "./changes"
import "./history.css"
import { tintOf, whenOf, writer, type Version } from "./versions"

const isMd = (p: string) => /\.md$/i.test(p)

type Shown = { kind: "md"; pieces: Piece[]; counts: Counts; props: string[] } | { kind: "lines"; lines: DiffLine[]; counts: Counts }

function propsChanged(was: string, now: string): string[] {
  const keys = (fm: string) => new Map(fm.split("\n").flatMap((l) => { const m = /^([^\s:#-][^:]*):(.*)$/.exec(l); return m ? [[m[1].trim(), m[2].trim()] as const] : [] }))
  const a = keys(was), b = keys(now)
  return [...new Set([...a.keys(), ...b.keys()])].filter((k) => a.get(k) !== b.get(k))
}

function useShown(path: string, text: string | null, before: string | null | undefined, marked: boolean): Shown | null {
  const [shown, setShown] = useState<Shown | null>(null)
  useEffect(() => {
    if (text === null || before === undefined) { setShown(null); return }
    let live = true
    const was = marked && before !== null ? before : text
    const run = async (): Promise<Shown> => {
      if (!isMd(path)) {
        const lines = await textDiff(was, text, marked ? 3 : undefined)
        return { kind: "lines", lines, counts: { added: lines.filter((l) => l.kind === "add").length, removed: lines.filter((l) => l.kind === "del").length } }
      }
      const a = splitFm(was), b = splitFm(text)
      const { pieces, counts } = await changes(a.body, b.body)
      return { kind: "md", pieces, counts, props: propsChanged(a.fm, b.fm) }
    }
    run().then((s) => { if (live) setShown(s) }, (e) => notifyError(e))
    return () => { live = false }
  }, [path, text, before, marked])
  return shown
}

function Summary({ shown, before, marked }: { shown: Shown | null; before: string | null | undefined; marked: boolean }) {
  if (!marked) return null
  if (before === null) return <>The earliest version kept</>
  if (!shown) return null
  const { added, removed } = shown.counts, props = shown.kind === "md" ? shown.props : []
  const parts = shown.kind === "lines"
    ? [added && `${plural(added, "line")} added`, removed && `${plural(removed, "line")} removed`]
    : [added && plural(added, "addition"), removed && plural(removed, "deletion"), props.length && `${props.length === 1 ? "property" : "properties"} ${props.join(", ")}`]
  const said = parts.filter(Boolean)
  return <>{said.length ? `${said.join(", ")} since the version before` : "No change to the text since the version before"}</>
}

export function VersionPane({ path, v, text, before, restoring, onRestore, bar }: {
  path: string; v: Version; text: string | null; before: string | null | undefined; restoring: boolean; onRestore: () => void; bar?: React.ReactNode
}) {
  const [marked, setMarked] = useState(true)
  const shown = useShown(path, text, before, marked)
  const who = writer(v)
  return (
    <section className="min-w-0 flex-1" aria-label="Version" data-history-version={v.key} style={{ "--c": colorVar(tintOf(v)) }}>
      {bar}
      <div className="mb-3 flex flex-wrap items-center gap-x-3 gap-y-2">
        <div className="min-w-0 flex-1 @max-3xl:hidden">
          <h2 className="truncate text-[17px] leading-[22px] font-semibold">{v.now ? "Current version" : whenOf(v.t)}</h2>
          <p className="truncate text-[13px] leading-[18px] text-muted-foreground">
            {v.now && <>{whenOf(v.t)}{who && " · "}</>}{who}{v.source && v.title ? ` · ${v.title}` : ""}
          </p>
        </div>
        <label className="flex cursor-pointer items-center gap-2 text-[15px] md:text-[13px] @max-3xl:mr-auto">
          <Switch on={marked} onChange={setMarked} label="Show changes" />Show changes
        </label>
        <Button look="quiet" size="small" disabled={text === null} onClick={() => text !== null && copyText(text).then(() => notify("Copied the version", { id: "copied" }), (e) => notifyError(e))}>
          <Copy className="size-3.5" strokeWidth={2.25} />Copy
        </Button>
        {!v.now && (
          <Button look="primary" size="small" busy={restoring} disabled={text === null} onClick={onRestore} data-history-restore>
            <RotateCcw className="size-3.5" strokeWidth={2.25} />Restore this version
          </Button>
        )}
      </div>
      <p className="mb-2 min-h-[18px] text-[13px] leading-[18px] text-muted-foreground" data-history-summary><Summary shown={shown} before={before} marked={marked} /></p>
      <div className={cn("rounded-[10px] border-[0.5px] border-border bg-card md:rounded-[8px]", shown?.kind === "lines" ? "overflow-x-auto py-2 font-mono text-[12.5px] leading-[19px]" : "vau-history-text px-4 py-3 md:px-6 md:py-5")} data-history-text>
        {!shown ? <Loading className="font-sans text-[13px]" />
          : shown.kind === "lines" ? <DiffRows lines={shown.lines} />
          : shown.pieces.map((p, i) => (
            <div key={i} data-change={p.kind === "same" ? undefined : p.kind} className={p.kind === "same" ? undefined : "marked"}>
              <Markdown text={p.md} from={path} full />
            </div>
          ))}
      </div>
    </section>
  )
}
