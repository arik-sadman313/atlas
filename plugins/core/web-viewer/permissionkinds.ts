import { Bell, Camera, Clipboard, Cpu, FolderOpen, MapPin, Mic, Monitor, Moon, Music, SquareArrowOutUpRight, type LucideIcon } from "lucide-react"

const KINDS = {
  camera: { name: "Camera", icon: Camera }, microphone: { name: "Microphone", icon: Mic }, geolocation: { name: "Location", icon: MapPin },
  notifications: { name: "Notifications", icon: Bell }, "clipboard-read": { name: "Clipboard", icon: Clipboard }, midi: { name: "MIDI devices", icon: Music },
  midiSysex: { name: "MIDI control", icon: Music }, "idle-detection": { name: "Your idle state", icon: Moon }, "window-management": { name: "Window placement", icon: Monitor },
  fileSystem: { name: "Files", icon: FolderOpen },
} satisfies Record<string, { name: string; icon: LucideIcon }>
const known = (kind: string): kind is keyof typeof KINDS => Object.hasOwn(KINDS, kind)
const OTHER_APP = "openExternal:"
export const kindName = (kind: string) => known(kind) ? KINDS[kind].name : kind.startsWith(OTHER_APP) ? `Open ${kind.slice(OTHER_APP.length)}: links` : kind
export const kindIcon = (kind: string): LucideIcon => known(kind) ? KINDS[kind].icon : kind.startsWith(OTHER_APP) ? SquareArrowOutUpRight : Cpu
