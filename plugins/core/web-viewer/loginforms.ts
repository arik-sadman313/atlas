import { cell } from "@vaultite"

export const forms = cell(new Set<number>())
export const hasLoginForm = (id: number) => !!id && forms.get().has(id)
export const useLoginForm = (id: number) => forms.use((s) => !!id && s.has(id))
