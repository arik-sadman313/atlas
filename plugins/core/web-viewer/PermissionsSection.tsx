import { useEffect, useState, type ComponentType } from "react"

export function PermissionsSection() {
  const [Settings, setSettings] = useState<ComponentType | null>(null)
  useEffect(() => void import("./Permissions").then((m) => setSettings(() => m.default)), [])
  return Settings ? <Settings /> : null
}
