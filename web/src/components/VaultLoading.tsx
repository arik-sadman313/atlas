import { useEffect, useReducer, useState } from "react"
import { getStore, reload, type Store } from "@/core/data"
import { get } from "@/core/http"
import { notify } from "@/core/notify"
import { checkServer } from "@/core/connection"
import { SLOW } from "@/core/reading"
import { ReadFailed, ReadSlow } from "@/components/Pending"

function namesOf(files: string[]) {
  const names = files.slice(0, 3).map((f) => f.slice(f.lastIndexOf("/") + 1).replace(/\.md$/, ""))
  return files.length > 3 ? `${names.join(", ")} and ${files.length - 3} more` : names.join(", ")
}

export function VaultLoading({ error }: { error: unknown }) {
  const [retried, setRetried] = useState<unknown>()
  const failed = error !== undefined && error !== retried
  const [files, setFiles] = useState<string[]>([])
  const [tries, tried] = useReducer((n: number) => n + 1, 0)
  const [slowAt, setSlowAt] = useState<number | null>(null)
  const slow = slowAt === tries
  useEffect(() => {
    if (failed) return
    const late = setTimeout(() => { setSlowAt(tries); checkServer() }, SLOW)
    return () => clearTimeout(late)
  }, [failed, tries])
  useEffect(() => {
    if (failed) return
    let on = true, timer: ReturnType<typeof setTimeout>
    const look = async () => {
      if (getStore()) return
      const r = await get<{ downloading: string[] }>("loading").catch(() => null)
      if (on && r) setFiles(r.downloading)
      if (on) timer = setTimeout(look, 1000)
    }
    timer = setTimeout(look, 500)
    return () => { on = false; clearTimeout(timer) }
  }, [failed])
  const read = { value: undefined, error, slow, retry: () => { setRetried(error); tried(); checkServer(); void reload() } }
  if (failed) return <ReadFailed read={read} what="Couldn't load the vault" className="mt-10" />
  return (
    <div aria-busy data-vault-loading className="loading-in mt-10 space-y-1 text-[17px] text-muted-foreground md:text-[15px]" style={{ animationDelay: "500ms" }}>
      <p>Reading the vault…</p>
      {files.length > 0 && <p>Waiting for iCloud to download {files.length === 1 ? "a file" : `${files.length} files`}: {namesOf(files)}</p>}
      <ReadSlow read={read} className="mt-6" />
    </div>
  )
}

let told = false
export function DownloadingNotice({ store }: { store: Store | null }) {
  useEffect(() => {
    if (!store || told) return
    told = true
    const files = store.vault.downloading ?? []
    if (files.length) notify(`iCloud is still downloading ${files.length === 1 ? "a file" : `${files.length} files`} (${namesOf(files)}): they show when they arrive`, { duration: 8000 })
  }, [store])
  return null
}
