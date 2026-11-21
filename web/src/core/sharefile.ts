import { dismissNotice, notify, notifyError } from "@/core/notify"
import { errorIn } from "../../../core/plainerror.ts"

const MAX_BYTES = 300e6
const SLOW_MS = 400

async function fetchFile(url: string, name: string) {
  const r = await fetch(url)
  if (!r.ok) throw Object.assign(new Error(errorIn(await r.json().catch(() => ({}))) || r.statusText || `Error ${r.status}`), { status: r.status })
  if (Number(r.headers.get("content-length")) > MAX_BYTES) { void r.body?.cancel(); return null }
  const blob = await r.blob()
  return new File([blob], name, { type: blob.type })
}

async function shareSheet(file: File) {
  try {
    await navigator.share({ files: [file] })
  } catch (e) {
    const why = e instanceof DOMException ? e.name : ""
    if (why === "AbortError") return
    const tapTooLongAgo = why === "NotAllowedError"
    if (tapTooLongAgo) return void notify(`${file.name} is ready`, { id: `save-${file.name}`, action: { label: "Save", run: () => shareSheet(file) } })
    notifyError(e, `Couldn't save ${file.name}`)
  }
}

export async function shareFile(url: string, name: string) {
  const id = `save-${name}`
  const slow = setTimeout(() => notify(`Getting ${name}…`, { id, duration: Infinity }), SLOW_MS)
  let file: File | null
  try { file = await fetchFile(url, name) } catch (e) { return void notifyError(e, `Couldn't get ${name}`, { id }) } finally { clearTimeout(slow) }
  if (!file) return void notify(`${name} is too big to save on this phone`, { id })
  if (navigator.canShare && !navigator.canShare({ files: [file] })) return void notify(`This phone can't save ${name} from here`, { id })
  dismissNotice(id)
  await shareSheet(file)
}
