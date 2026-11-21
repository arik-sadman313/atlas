import { RotateCcw, Settings2 } from "lucide-react"
import { notifyError, openPluginSettings, type MenuItem } from "@vaultite"
import { engine, type Choice, type PagePermissions } from "./engine"
import { kindIcon, kindName } from "./permissionkinds"

export const CHOICES: { value: Choice; label: string }[] = [{ value: "ask", label: "Ask" }, { value: "allow", label: "Allow" }, { value: "block", label: "Block" }]
const choiceNote = (kind: string, c: Choice) => c === "ask" ? "Asks the first time the site wants it"
  : c === "allow" ? (kind === "notifications" ? "Allowed unless you block it" : "Allowed without asking") : "Blocked: the site can't ask"

export const setChoice = (profile: string, site: string, kind: string, choice: Choice) =>
  Promise.resolve(engine("permissions:set", profile, site, kind, choice)).catch((e) => notifyError(e, "Couldn't change it"))

function macItems(p: PagePermissions): MenuItem[] {
  return (["camera", "microphone"] as const).flatMap((k): MenuItem[] => p.mac[k] === "granted" ? [] : [{
    label: p.mac[k] === "not-determined" ? `Let Vaultite use the ${k}…` : `macOS blocks Vaultite's ${k}: open Settings…`,
    icon: Settings2, sep: true,
    run: () => Promise.resolve(engine("permissions:mac", k)).catch((e) => notifyError(e, "Couldn't ask macOS")),
  }])
}

export type Shown = Omit<PagePermissions, "kinds"> & { kinds: (PagePermissions["kinds"][number] & { was: Choice; default: Choice })[] }
export function siteItems(p: Shown, reload: () => void): MenuItem[] {
  const changed = p.kinds.some((k) => k.choice !== k.was)
  return [
    { caption: true, label: `What ${p.site} may use`, run: () => {} },
    ...p.kinds.map((k): MenuItem => ({ label: kindName(k.kind), icon: kindIcon(k.kind), hint: CHOICES.find((c) => c.value === k.choice)?.label, run: () => {},
      items: [{ caption: true, label: choiceNote(k.kind, k.choice), run: () => {} }, ...CHOICES.map((c): MenuItem => ({ label: c.label, checked: k.choice === c.value, keep: true,
        run: () => { k.choice = c.value; void setChoice(p.profile, p.site, k.kind, c.value) } }))] })),
    ...macItems(p),
    ...(changed ? [{ label: "Reload to use the new settings", icon: RotateCcw, sep: true, run: reload }] : []),
    { label: "Reset permissions", icon: RotateCcw, sep: !changed, disabled: p.kinds.every((k) => k.choice === k.default),
      run: () => Promise.resolve(engine("permissions:clear", p.profile, p.site)).then(reload, (e) => notifyError(e, "Couldn't reset them")) },
    { label: "Site permissions…", icon: Settings2, run: () => openPluginSettings("web-viewer", "permissions") },
  ]
}
