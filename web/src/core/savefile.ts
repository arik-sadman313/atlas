import { phoneApp } from "@/core/phoneapp"

const ua = typeof navigator === "undefined" ? "" : navigator.userAgent
const downloadsTrapTheApp = !!phoneApp || /iPhone|iPad|iPod/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)
export const savesBySharing = downloadsTrapTheApp && "share" in navigator

export function saveFile(url: string, name: string) {
  if (savesBySharing) return void import("@/core/sharefile").then((m) => m.shareFile(url, name))
  const a = document.createElement("a")
  a.href = url
  a.download = name
  a.click()
}
