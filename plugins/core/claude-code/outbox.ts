import { cell, notifyError } from "@vaultite"
import type { Entry } from "./chatlog"
import { type Picture, draftPictures, dropPictures, keepPictures } from "./images"

export type Out = { key: string; text: string; pictures: Picture[]; docked: boolean; wordsBefore: number; sent?: string }

const boxes = cell<ReadonlyMap<string, Out[]>>(new Map())
const NONE: Out[] = []
const chains = new Map<string, Promise<unknown>>()
const backs = new Map<string, Set<() => void>>()
const CANCELLED = new Error("Cancelled: an earlier message didn't go")

export const outOf = (chat: string) => boxes.get().get(chat) ?? NONE
export const useOutbox = (chat: string) => boxes.use((m) => m.get(chat) ?? NONE)

export const draftKey = (chat: string) => `vaultite.chat.${chat}`
const cutKey = (chat: string) => `${draftKey(chat)}:sending`
function stored(key: string) { try { return localStorage.getItem(key) ?? "" } catch { return "" } }
function store(key: string, text: string) { try { if (text.trim()) localStorage.setItem(key, text); else localStorage.removeItem(key) } catch { /* private mode */ } }
const joined = (texts: string[]) => texts.flatMap((t) => (t.trim() ? [t.trim()] : [])).join("\n\n")

function put(chat: string, outs: Out[]) {
  const m = new Map(boxes.get())
  if (outs.length) m.set(chat, outs); else m.delete(chat)
  boxes.set(m)
  store(cutKey(chat), joined(outs.flatMap((o) => (o.sent === undefined ? [o.text] : []))))
}

export function draftOf(chat: string) {
  const cut = outOf(chat).length ? "" : stored(cutKey(chat))
  if (!cut) return stored(draftKey(chat))
  const text = joined([cut, stored(draftKey(chat))])
  store(draftKey(chat), text)
  store(cutKey(chat), "")
  return text
}
export const keepDraft = (chat: string, text: string) => store(draftKey(chat), text)

export const wordsIn = (chat: string, entries: Entry[], text: string) =>
  entries.filter((e) => e.k === "user" && e.text.trim() === text.trim()).length + outOf(chat).filter((o) => o.text.trim() === text.trim()).length

export const landed = (out: Out, entries: Entry[]) =>
  (!!out.sent && entries.some((e) => e.id === out.sent)) || entries.filter((e) => e.k === "user" && e.text.trim() === out.text.trim()).length > out.wordsBefore

export function deliver<T>(chat: string, out: Out, go: () => Promise<T>, failed: string): Promise<T | null> {
  put(chat, [...outOf(chat), out])
  const has = () => outOf(chat).some((o) => o.key === out.key)
  const run = (chains.get(chat) ?? Promise.resolve()).then(() => { if (!has()) throw CANCELLED; return go() })
  const settled = run.catch((e) => {
    if (e !== CANCELLED && has()) { giveBack(chat, out.key); notifyError(e, failed) }
    return null
  })
  chains.set(chat, settled)
  return settled
}

function giveBack(chat: string, key: string) {
  const outs = outOf(chat), from = outs.findIndex((o) => o.key === key)
  const back = outs.slice(from).filter((o) => o.sent === undefined)
  put(chat, outs.filter((o) => !back.includes(o)))
  store(draftKey(chat), joined([...back.map((o) => o.text), stored(draftKey(chat))]))
  keepPictures(draftKey(chat), [...back.flatMap((o) => o.pictures), ...draftPictures(draftKey(chat))])
  for (const fn of backs.get(chat) ?? []) fn()
}

export function onBack(chat: string, fn: () => void) {
  const set = backs.get(chat) ?? new Set()
  backs.set(chat, set.add(fn))
  return () => { set.delete(fn) }
}

export function sent(chat: string, key: string, uuid: string, to = chat) {
  const out = outOf(chat).find((o) => o.key === key)
  if (!out) return
  if (to === chat) return put(chat, outOf(chat).map((o) => (o === out ? { ...o, sent: uuid } : o)))
  put(chat, outOf(chat).filter((o) => o !== out))
  put(to, [...outOf(to), { ...out, sent: uuid, wordsBefore: 0 }])
}

export function settle(chat: string, key: string) {
  const out = outOf(chat).find((o) => o.key === key)
  if (!out) return
  put(chat, outOf(chat).filter((o) => o !== out))
  dropPictures(out.pictures)
}
