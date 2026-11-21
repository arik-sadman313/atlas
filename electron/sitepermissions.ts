import { ipcMain, systemPreferences } from "electron"
import { z } from "zod"
import { allPages, handle } from "./browser/engine.ts"
import { MAC, pageOf } from "./webbase.ts"
import { answer, choiceOf, loadAnswers } from "./webpermissions.ts"
import { hostOfUrl, siteOf } from "./webwire.ts"

const SHOWN = ["camera", "microphone", "geolocation", "notifications"]
const QUERIED = z.enum(["camera", "microphone", "geolocation", "notifications", "clipboard-read", "midi", "idle-detection", "window-management", "local-network-access", "local-network", "loopback-network"])
const KIND = z.string().regex(/^(camera|microphone|geolocation|notifications|clipboard-read|midi|midiSysex|idle-detection|window-management|local-network-access|local-network|loopback-network|fileSystem|openExternal:[a-z][a-z0-9+.-]{0,40})$/)
const PROFILE = z.string().regex(/^[a-z0-9-]{0,32}$/), SITE = z.string().regex(/^[a-z0-9.-]{1,253}$/)
const SET = z.tuple([PROFILE, SITE, KIND, z.enum(["allow", "block", "ask"])]), CLEAR = z.tuple([PROFILE, SITE]), MAC_KIND = z.enum(["camera", "microphone"])

const media = (k: "camera" | "microphone") => (MAC ? systemPreferences.getMediaAccessStatus(k) : "granted")

ipcMain.handle("vaultite:web:permission", (e, ...args) => {
  const kind = QUERIED.safeParse(args[0]).data, p = pageOf(e.sender), site = siteOf(hostOfUrl(e.senderFrame?.url ?? ""))
  if (!kind || !p || !site) return null
  const c = choiceOf(p.profile, site, kind)
  return c === "allow" ? "granted" : c === "block" ? "denied" : "prompt"
})

handle("permissions:page", (win, id) => {
  const p = allPages().find((x) => x.id === id && x.win === win)
  if (!p || p.wc.isDestroyed()) return null
  const site = siteOf(hostOfUrl(p.wc.getURL()))
  if (!site) return null
  const kinds = [...new Set([...SHOWN, ...Object.keys(loadAnswers()[p.profile]?.[site] ?? {})])]
  return { site, profile: p.profile, kinds: kinds.map((kind) => ({ kind, choice: choiceOf(p.profile, site, kind) })),
    mac: { camera: media("camera"), microphone: media("microphone") } }
})
handle("permissions:list", () => Object.entries(loadAnswers()).flatMap(([profile, sites]) => Object.entries(sites).flatMap(([site, kinds]) =>
  Object.entries(kinds).map(([kind, yes]) => ({ profile, site, kind, choice: yes ? "allow" : "block" })))))
handle("permissions:set", (_win, ...args) => {
  const [profile, site, kind, choice] = SET.parse(args)
  answer(profile, site, kind, choice === "ask" ? null : choice === "allow")
})
handle("permissions:clear", (_win, ...args) => {
  const [profile, site] = CLEAR.parse(args)
  for (const k of Object.keys(loadAnswers()[profile]?.[site] ?? {})) answer(profile, site, k, null)
})
handle("permissions:mac", async (_win, asked) => {
  const kind = MAC_KIND.parse(asked)
  const { permissionAct } = await import("./permissions.ts")
  await permissionAct(kind)
  return media(kind)
})
