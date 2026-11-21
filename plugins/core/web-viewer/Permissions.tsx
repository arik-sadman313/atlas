import { useEffect, useState } from "react"
import { Button, Group, notifyError, Section, SettingRow, Segmented, useWorkspaceVersion } from "@vaultite"
import { engine, type SitePermission } from "./engine"
import { allLogins, nameOf } from "./loginsets"
import { useContainers } from "./containers"
import { kindName } from "./permissionkinds"
import { CHOICES, setChoice } from "./sitemenu"
import { settings } from "./state"

function useSitePermissions() {
  const [rows, setRows] = useState<SitePermission[] | null>(null)
  const [version, setVersion] = useState(0)
  useEffect(() => {
    let gone = false
    void engine("permissions:list").then((r) => { if (!gone) setRows(r ?? []) }, () => { if (!gone) setRows([]) })
    return () => { gone = true }
  }, [version])
  return { rows, refresh: () => setVersion((v) => v + 1) }
}

export default function PermissionsSettings() {
  useWorkspaceVersion()
  settings.use()
  useContainers()
  const { rows, refresh } = useSitePermissions()
  const logins = allLogins()
  const nameFor = (prof: string) => { const l = logins.find((x) => x.prof === prof); return l ? nameOf(l) : "Other logins" }
  const groups = new Map<string, SitePermission[]>()
  for (const r of rows ?? []) groups.set(`${r.profile} ${r.site}`, [...(groups.get(`${r.profile} ${r.site}`) ?? []), r])
  const multi = new Set((rows ?? []).map((r) => r.profile)).size > 1 || logins.length > 1
  return (
    <div data-setting="permissions">
      <Section title="Site permissions">
        <div data-web-permissions-settings>
          {rows && !rows.length ? <p className="px-1 text-[13px] text-muted-foreground">No site has asked yet.</p> : (
            <Group>{[...groups.values()].flatMap((list) => list.map((r) => (
              <SettingRow key={`${r.profile} ${r.site} ${r.kind}`} chevron={null} data-web-permission={`${r.site} ${r.kind}`} label={r.site}
                sub={`${kindName(r.kind)}${multi ? ` · ${nameFor(r.profile)}` : ""}`}>
                <Segmented small label={`${kindName(r.kind)} for ${r.site}`} value={r.choice} options={CHOICES}
                  onChange={(c) => void setChoice(r.profile, r.site, r.kind, c).then(refresh)} />
              </SettingRow>
            )))}</Group>
          )}
          {!!rows?.length && <div className="mt-2"><Button size="small" onClick={() => void Promise.all([...groups.values()].map((l) => engine("permissions:clear", l[0].profile, l[0].site))).then(refresh, (e) => notifyError(e, "Couldn't reset them"))}>Reset all</Button></div>}
          <p className="mt-1.5 px-1 text-[13px] leading-[18px] text-muted-foreground">
            What each site may use: the camera, the microphone, your location, notifications. A site asks the first time; a page's site information button (left of Shields in its address bar) changes it there. Each container keeps its own.
          </p>
        </div>
      </Section>
    </div>
  )
}
