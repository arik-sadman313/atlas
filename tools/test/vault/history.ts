import fs from "node:fs"
import path from "node:path"
import type { Any, VaultTest } from "./harness.ts"

export default async ($: VaultTest) => {
  const { VAULT, api, check, exists, read, sleep, tmp, vault, write } = $
  let code: number
  // ---------- duplicate, delete with undo, file history ----------
  let cp: Any
  ;[code, cp] = await api("POST", "notes", { ext_id: "note-dup-source", title: "Dup source", body: "Original text" })
  await sleep(20)
  ;[code, cp] = await api("POST", "file/copy", { path: "Notes/Dup source.md" })
  check("duplicate: the file as it is, next to it, named like Obsidian's", code === 201 && cp.path === "Notes/Dup source 1.md" && read("Notes/Dup source 1.md") === read("Notes/Dup source.md"), [code, cp])
  let [, dupNotes] = await api("GET", "notes")
  const idOf = (t: string) => dupNotes.find((n: Any) => n.title === t)?.ext_id
  const dupPath = (t: string) => dupNotes.find((n: Any) => n.title === t)?.id + ".md"
  check("a duplicated note keeps the original's id until it's edited", idOf("Dup source 1") === "note-dup-source", [idOf("Dup source"), idOf("Dup source 1")])
  await api("PUT", "file", { path: dupPath("Dup source 1"), text: read(dupPath("Dup source 1")).replace("Original text", "Copied text") })
  ;[, dupNotes] = await api("GET", "notes")
  check("...edited in the app, it gets its own id; the original keeps its", idOf("Dup source") === "note-dup-source" && idOf("Dup source 1") && idOf("Dup source 1") !== "note-dup-source",
    [idOf("Dup source"), idOf("Dup source 1")])
  ;[code, cp] = await api("POST", "file/copy", { path: "Notes/Dup source 1.md" })
  check("a copy of 'Name 1' is 'Name 2'", cp.path === "Notes/Dup source 2.md", cp)
  await api("PUT", "file", { path: "Notes/Dup source 2.md", text: read("Notes/Dup source 2.md") + "More.\n" })
  ;[, dupNotes] = await api("GET", "notes")
  check("three copies, three ids", new Set(dupNotes.filter((n: Any) => n.title.startsWith("Dup source")).map((n: Any) => n.ext_id)).size === 3)
  ;[code] = await api("POST", "file/copy", { path: "Notes" })
  check("a folder isn't duplicated", code === 400, code)
  write("Notes/Dup claims.md", "---\ntype: person\nname: Alice Park\naliases: [Alice]\nid: dup-claims\ncontext: Met at a course\n---\n\nText\n")
  await api("GET", "state")
  ;[code, cp] = await api("POST", "file/copy", { path: "Notes/Dup claims.md" })
  check("a duplicate is byte for byte the original, as in Obsidian", read(cp.path) === read("Notes/Dup claims.md"), read(cp.path))
  let del = undefined
  ;[code, del] = await api("DELETE", "file?path=Notes/Dup source 2.md")
  check("delete says where it went in the trash", code === 200 && typeof del.trashed === "string" && del.trashed.startsWith(".trash/Notes/Dup source 2 ") && exists(del.trashed), del)
  ;[code, del] = await api("POST", "file/restore", { path: del.trashed })
  check("...so it can be undone", code === 200 && del.path === "Notes/Dup source 2.md" && exists("Notes/Dup source 2.md"), del)

  const hist = await import("../../../plugins/core/history/plugin.ts")
  const histSettings = (o: object) => write(".vaultite/plugins/history/data.json", JSON.stringify(o))
  const versionsOf = async (p: string) => (await api("GET", `history?path=${p}`))[1].versions as Any[]
  const versionText = async (p: string, t: number) => (await api("GET", `history/version?path=${p}&t=${t}`))[1]
  let allHist: Any
  histSettings({ interval_min: 0, keep_days: 7 })
  write("Hist/a.md", "one\n")
  await api("GET", "state")
  check("history: nothing kept for a new file", !(await versionsOf("Hist/a.md")).length)
  write("Hist/a.md", "one\ntwo\n")
  let hv = await versionsOf("Hist/a.md")
  check("history: a change on disk keeps the previous content", hv.length === 1 && await versionText("Hist/a.md", hv[0].t) === "one\n", hv)
  histSettings({ interval_min: 5, keep_days: 7 })
  write("Hist/a.md", "one\ntwo\nthree\n")
  hv = await versionsOf("Hist/a.md")
  check("history: at most one snapshot per interval", hv.length === 1, hv)
  histSettings({ interval_min: 0, keep_days: 7 })
  await api("PUT", "file", { path: "Hist/a.md", text: "four\n", base: read("Hist/a.md") })
  hv = await versionsOf("Hist/a.md")
  check("history: an API write keeps what was there", hv.length === 2 && await versionText("Hist/a.md", hv[0].t) === "one\ntwo\nthree\n", hv)
  fs.utimesSync(path.join(VAULT, "Hist/a.md"), new Date(), new Date(Date.now() + 5000))
  hv = await versionsOf("Hist/a.md")
  check("history: a touch without a change keeps nothing", hv.length === 2, hv)
  write("Hist/pic.png", "not really a png")
  write("Hist/code.py", "print(1)\n")
  await api("GET", "state")
  await versionsOf("Hist/code.py") // (History looks after the sync, off it: its route waits for that look)
  write("Hist/code.py", "print(2)\n")
  hv = await versionsOf("Hist/code.py")
  check("history: code files too", hv.length === 1, hv)
  write("Hist/pic.png", "still not a png")
  check("history: not images", !(await versionsOf("Hist/pic.png")).length)
  write(".vaultite/secret.md", "hidden\n")
  await api("GET", "state")
  write(".vaultite/secret.md", "hidden 2\n")
  check("history: not hidden files", !(await versionsOf(".vaultite/secret.md")).length)
  // Any size: a file growing past a megabyte is followed on, never taken for gone.
  const bigLine = "a line of a big file\n".repeat(60_000)
  write("Hist/big.md", bigLine)
  await versionsOf("Hist/big.md")
  write("Hist/big.md", bigLine + "one more\n")
  hv = await versionsOf("Hist/big.md")
  check("history: a file over a megabyte", hv.length === 1 && await versionText("Hist/big.md", hv[0].t) === bigLine, hv.length)
  write("Hist/big.md", bigLine.repeat(2))
  hv = await versionsOf("Hist/big.md")
  ;[, allHist] = await api("GET", "history")
  check("history: grown bigger, still followed", hv.length === 2 && await versionText("Hist/big.md", hv[0].t) === bigLine + "one more\n" &&
    !allHist.find((f: Any) => f.path === "Hist/big.md")?.gone, allHist.find((f: Any) => f.path === "Hist/big.md"))
  await api("POST", "file/move", { from: "Hist/a.md", to: "Hist/b.md" })
  check("history: a renamed file takes its versions along", (await versionsOf("Hist/b.md")).length === 2 && !(await versionsOf("Hist/a.md")).length)
  await api("DELETE", "file?path=Hist/b.md")
  hv = await versionsOf("Hist/b.md")
  check("history: a deleted file keeps its last content", hv.length === 3 && await versionText("Hist/b.md", hv[0].t) === "four\n", hv)
  ;[, allHist] = await api("GET", "history")
  check("history: the list of files says which are gone", allHist.some((f: Any) => f.path === "Hist/b.md" && f.gone && f.versions === 3), allHist)
  ;[code] = await api("GET", "history/version?path=Hist/b.md&t=1")
  check("history: a version that isn't there is a 404", code === 404, code)
  hist.prune(vault, Date.now() + 8 * 86400_000)
  check("history: pruned after keep_days", !(await versionsOf("Hist/b.md")).length && !(await versionsOf("Hist/code.py")).length)
  ;[, allHist] = await api("GET", "history")
  check("history: a gone file's history goes once it's pruned", !allHist.some((f: Any) => f.path === "Hist/b.md"), allHist)
  check("history: kept outside the vault", !fs.readdirSync(VAULT).includes("history") && fs.existsSync(path.join(tmp, "local", "history")))

  await whoWrote($)
}

/** Who wrote each version (Activity's changes), an agent's edit a version of its own, restoring one and undoing that. */
async function whoWrote($: VaultTest) {
  const { VAULT, api, app, check, read, sentBy, sleep } = $
  const { whoOf } = await import("../../../core/ops.ts")
  write$($, ".vaultite/plugins/history/data.json", JSON.stringify({ interval_min: 5, keep_days: 7 }))
  const user = whoOf("app/desktop", null), chatgpt = whoOf("mcp", "ChatGPT")
  // Further apart than a coarse clock's tick (MTIME_LAG), as a person's edits and an agent's are.
  const call = async (id: string, params: Any, who = user) => {
    await sleep(40)
    const r = (await app.callOp(id, params, who, { report: `mcp ${id}` })).result as Any
    if (id.startsWith("file.")) app.changed([params.path])
    return r
  }
  async function typed(p: string, text: string) {
    await sleep(40)
    const end = app.requestStarted({ t: Date.now(), method: "PUT", route: "file", query: {}, client: "app/desktop", agent: null, command: null, ua: "", remote: "", port: 1, forwarded: false })
    const r = await api("PUT", "file", { path: p, text, base: read(p) }, sentBy("app/desktop"))
    end({ status: r[0], ms: 1, body: { path: p } })
  }
  const listed = async (p: string) => (await api("GET", `history?path=${p}`))[1]
  const N = "Who/Plans.md"
  await call("file.write", { path: N, text: "# Plans\n\nCall Alice.\n" })
  await listed(N)
  await typed(N, "# Plans\n\nCall Alice.\nBook the train.\n")
  await listed(N)
  await call("file.edit", { path: N, old: "Book the train.", new: "Book the train to Porto." }, chatgpt)
  let h = await listed(N)
  check("history: an agent's edit through the API is the current version, by its name", h.now?.by === "ChatGPT" && h.now.kind === "agent", h)
  const yours = h.versions.find((v: Any) => v.kind === "you")
  check("history: the text just before it is a version, the user's, though the interval hadn't passed", yours && (await api("GET", `history/version?path=${N}&t=${yours.t}`))[1] === "# Plans\n\nCall Alice.\nBook the train.\n", h.versions)
  check("history: the file now isn't listed again among its versions", !h.versions.some((v: Any) => v.t === h.now.t), h)
  await typed(N, read(N) + "Pack.\n")
  h = await listed(N)
  check("history: the agent's own text stays a version after the user's next edit", h.versions.some((v: Any) => v.by === "ChatGPT") && h.now.kind === "you", h)
  const [, edited] = await api("GET", "history/edited")
  check("history: a file whose last change was the user's isn't listed as an agent's", !edited.files.some((f: Any) => f.path === N), edited)
  await call("file.edit", { path: N, old: "Pack.", new: "Pack light." }, chatgpt)
  const [, edited2] = await api("GET", "history/edited")
  check("history: one an agent changed last is, with who", edited2.files.some((f: Any) => f.path === N && f.by === "ChatGPT"), edited2)
  const was = read(N)
  const r = await call("history.restore", { path: N, t: yours.t })
  check("history: restore makes the file that version again", read(N) === "# Plans\n\nCall Alice.\nBook the train.\n" && typeof r.was === "number", [read(N), r])
  await call("history.restore", { path: N, t: r.was })
  check("history: and restoring the version it kept undoes it", read(N) === was, read(N))
  const text = (await app.callOp("history.list", { path: N }, user)).text
  check("history: as text, each version with who wrote it", /by ChatGPT/.test(text) && /by You/.test(text), text)
  // A file left alone a minute: what it said is a version at its next change, whatever the interval.
  const P = "Who/Paused.md"
  write$($, P, "one\n")
  await listed(P)
  const past = new Date(Date.now() - 120_000)
  fs.utimesSync(path.join(VAULT, P), past, past)
  await listed(P)
  write$($, P, "one\ntwo\n")
  check("history: a pause of a minute ends a version", (await listed(P)).versions.length === 1)
  write$($, P, "one\ntwo\nthree\n")
  check("history: changes in a row within the interval don't", (await listed(P)).versions.length === 1)
  fs.rmSync(path.join(VAULT, "Who"), { recursive: true, force: true })
}
const write$ = ($: VaultTest, p: string, text: string) => $.write(p, text)
