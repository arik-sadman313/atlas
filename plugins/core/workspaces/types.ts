import type { Moves } from "./order"

declare module "@vaultite" {
  interface PluginState {
    workspaces?: unknown[]
    workspaceMoves?: Moves
  }
}
