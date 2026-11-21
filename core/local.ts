import path from "node:path"
import { fileURLToPath } from "node:url"

export const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)))
/** This machine's own files: secrets. Never synced, never in the vault. */
export const LOCAL = process.env.VAULTITE_LOCAL || path.join(ROOT, "data")
