export type RefsPlace = "div" | "heading" | "end"

export const REFS_DIV = /^:::\s*\{#refs[^}]*\}\s*\n(?:[^\n]*\n)*?:::\s*$/m
const NAMES = /^(?:references|bibliography|works cited|literature cited|cited works|literature|sources|literaturverzeichnis|bibliographie|références|referencias|bibliografia)$/i

function lastHeading(text: string): string | null {
  let fence = false, last: string | null = null
  for (const line of text.split("\n")) {
    if (/^\s*(```|~~~)/.test(line)) fence = !fence
    const h = fence ? null : /^#{1,6}[ \t]+(.*?)[ \t]*#*[ \t]*$/.exec(line)
    if (h) last = h[1]
  }
  return last
}

export function refsPlace(text: string): RefsPlace {
  if (REFS_DIV.test(text)) return "div"
  return NAMES.test(lastHeading(text) ?? "") ? "heading" : "end"
}
