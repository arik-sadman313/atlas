export const vaultHolder = new SharedArrayBuffer(4 + 240)
const size = new Int32Array(vaultHolder, 0, 1), bytes = new Uint8Array(vaultHolder, 4), encoder = new TextEncoder()

export function holdingVault(by: string) {
  Atomics.store(size, 0, encoder.encodeInto(by, bytes).written)
}
