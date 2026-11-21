import { useState } from "react"
import { Button, Group, notify, notifyError, op, plural, PluginSetting, post, Section, secretDialog, SettingRow, useLive } from "@vaultite"
import { forgetFormatted, touchesLibrary } from "./client.ts"
import { useLibraryVersion } from "./hooks.ts"
import type { StatusAnswer, ZoteroState } from "./wire.ts"

type Side = ZoteroState & { on: boolean }

function zoteroSub(s: Side, web: boolean): string | undefined {
  if (!s.on) return web ? "Your library on zotero.org, for a server that isn't the computer Zotero runs on" : undefined
  if (s.state === "ready") return `${plural(s.items, "reference")} in ${s.libraries.join(", ")}${web ? "" : s.bbt ? `, Better BibTeX ${s.bbt}` : ", without Better BibTeX"}`
  if (s.state === "off") return "Not read yet"
  if (s.state === "unreachable" && !web) return `Zotero isn't open${s.items ? `: citing the ${plural(s.items, "reference")} it had` : ""}`
  return s.detail
}

async function setWebKey(had: boolean) {
  if (had) {
    try { await op("references.zotero-key", { remove: true }); notify("Removed the Zotero key") } catch (e) { notifyError(e, "Couldn't remove the key") }
    return
  }
  const given = await secretDialog({ title: "Zotero API key", body: "Make one with read access at zotero.org/settings/keys. It stays on this computer, out of your vault.", confirm: "Connect", field: "secret" })
  if (!given) return
  try { await op("references.zotero-key", { key: given.value.trim() }); forgetFormatted(); notify("Connected your zotero.org library") } catch (e) { notifyError(e, "Couldn't connect to zotero.org") }
}

export function Sources() {
  const [v, setV] = useState(0)
  const { data: s } = useLive<StatusAnswer>("references/status", `${v}:${useLibraryVersion()}`, touchesLibrary)
  const [busy, setBusy] = useState(false)
  const refresh = async () => {
    setBusy(true)
    try { await post("references/refresh", {}); forgetFormatted(); setV((n) => n + 1) } catch (e) { notifyError(e, "Couldn't read the library") } finally { setBusy(false) }
  }
  if (!s) return null
  const local = s.zotero.local, web = s.zotero.web
  return (
    <Section title="Sources">
      <Group>
        <SettingRow label="Library" sub={`${plural(s.items, "reference")} to cite, ${plural(s.notes, "literature note")}`} data-references-library>
          <Button look="outline" size="small" busy={busy} onClick={() => void refresh()} data-references-refresh>Read again</Button>
        </SettingRow>
        <PluginSetting plugin="references" k="findBibliographies" />
        <PluginSetting plugin="references" k="bibliographies" />
        {s.files.map((f) => (
          <SettingRow key={f.path} label={f.path} sub={f.problems.length ? `${plural(f.count, "reference")}; ${f.problems[0]}${f.problems.length > 1 ? ` (and ${f.problems.length - 1} more)` : ""}` : plural(f.count, "reference")}
            data-references-file={f.path} />
        ))}
        <PluginSetting plugin="references" k="zoteroLocal" sub={zoteroSub(local, false)} />
        <PluginSetting plugin="references" k="zoteroGroups" />
        <SettingRow label="Zotero web library" sub={zoteroSub(web, true)} data-references-zotero-web>
          <Button look="outline" size="small" onClick={() => void setWebKey(web.on).then(() => setV((n) => n + 1))}>{web.on ? "Disconnect" : "Connect…"}</Button>
        </SettingRow>
      </Group>
    </Section>
  )
}
