import { useEffect } from "react"
import { hostOf } from "./address"
import { splitArg } from "./containers"
import { iconKey, SiteIcon } from "./icons"
import { fromBefore, useThumb } from "./thumbs"

export function WebPicture({ arg, tab }: { arg: string; tab: string }) {
  const { url } = splitArg(arg)
  const src = useThumb(tab, arg)
  useEffect(() => { if (!src) fromBefore(tab, arg) }, [src, tab, arg])
  if (src) return <img data-web-picture src={src} alt="" decoding="async" draggable={false} className="absolute inset-0 size-full object-cover object-top" />
  return (
    <div data-web-picture="" className="absolute inset-0 flex flex-col items-center gap-2 bg-muted px-3 pt-[32%] text-center">
      <SiteIcon url={`https://${iconKey(url)}`} className="size-10" />
      <span className="max-w-full truncate text-[13px] text-muted-foreground">{hostOf(url) || "New tab"}</span>
    </div>
  )
}
