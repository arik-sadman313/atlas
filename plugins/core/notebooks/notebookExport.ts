import {
  exportToBlob,
  exportToSvg,
  exportToClipboard,
  getNonDeletedElements,
} from "@excalidraw/excalidraw"
import type { ExcalidrawImperativeAPI } from "@excalidraw/excalidraw/types"

function getExportPayload(api: ExcalidrawImperativeAPI) {
  const elements = getNonDeletedElements(api.getSceneElements())
  const appState = api.getAppState()
  const files = api.getFiles()
  return {
    elements,
    files,
    appState: {
      ...appState,
      exportBackground: true,
      exportWithDarkMode: appState.theme === "dark",
    },
  }
}

function triggerDownload(url: string, filename: string) {
  const a = document.createElement("a")
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

export async function exportSceneToPng(api: ExcalidrawImperativeAPI, filename: string) {
  const payload = getExportPayload(api)
  const blob = await exportToBlob({
    ...payload,
    mimeType: "image/png",
    exportPadding: 20,
  })
  const url = URL.createObjectURL(blob)
  triggerDownload(url, `${filename}.png`)
}

export async function exportSceneToSvg(api: ExcalidrawImperativeAPI, filename: string) {
  const payload = getExportPayload(api)
  const svg = await exportToSvg({
    ...payload,
    exportPadding: 20,
  })
  const svgString = new XMLSerializer().serializeToString(svg)
  const blob = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" })
  const url = URL.createObjectURL(blob)
  triggerDownload(url, `${filename}.svg`)
}

export async function copySceneToClipboard(api: ExcalidrawImperativeAPI, type: "png" | "svg") {
  const payload = getExportPayload(api)
  await exportToClipboard({
    ...payload,
    type,
    exportPadding: 20,
  })
}
