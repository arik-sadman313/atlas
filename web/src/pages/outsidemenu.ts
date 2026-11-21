import { Copy, FolderSearch } from "lucide-react"
import { outsidePaths } from "@/core/desktopapp"
import { notify } from "@/core/notify"
import { isMac, isWindows } from "@/core/platform"
import type { MenuItem } from "@/components/ContextMenu"
import { copied, grouped } from "@/components/FileActions"
import { viewMenuItems } from "@/pages/folderviews"

const SHOW_LABEL = isMac ? "Open in Finder" : isWindows ? "Open in Explorer" : "Open in file manager"
export const showItem = (folder: string): MenuItem[] => {
  const out = outsidePaths()
  return out ? [{ label: SHOW_LABEL, icon: FolderSearch, run: () => out.showFolder(folder).then((ok) => { if (!ok) notify(`Couldn't show ${folder}`) }) }] : []
}
export const copyItem = (path: string): MenuItem => ({ label: "Copy path", icon: Copy, run: () => copied(path, "path") })
export const outsideTabMenu = (path: string): MenuItem[] => grouped([viewMenuItems(), [copyItem(path), ...showItem(path)]])
