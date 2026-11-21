import { check } from "../lib.ts"

{
  const { inVault, typedPath } = await import("../../../core/typedpath.ts")
  check("switcher: full paths are paths, as typed", typedPath("/Users/alice/Pictures/Lighthouse.png") === "/Users/alice/Pictures/Lighthouse.png"
    && typedPath(" ~/Downloads/a b.pdf ") === "~/Downloads/a b.pdf" && typedPath("~") === "~" && typedPath("C:\\Users\\alice\\x.png") === "C:\\Users\\alice\\x.png")
  check("switcher: a copied path's quotes come off", typedPath(`"/Users/alice/My notes/a.md"`) === "/Users/alice/My notes/a.md" && typedPath("'~/x.png'") === "~/x.png")
  check("switcher: a file:// URL is its path, decoded", typedPath("file:///Users/alice/My%20Pictures/a.png") === "/Users/alice/My Pictures/a.png"
    && typedPath("file:///C:/Users/alice/a.png") === "C:/Users/alice/a.png" && typedPath("file://localhost/etc/hosts") === "/etc/hosts" && typedPath("file://server/share/a") === null)
  check("switcher: a vault path needs a slash; words, addresses and other schemes aren't paths", typedPath("Notes/Ideas") === "Notes/Ideas"
    && typedPath("Lighthouse plan") === null && typedPath("https://example.com/a") === null && typedPath("mailto:alice@example.com") === null && typedPath("../x/y") === null && typedPath("  ") === null)
  check("switcher: a full path in the vault is its vault path", inVault("/Users/alice/Vault/Notes/a.md", "/Users/alice/Vault") === "Notes/a.md"
    && inVault("/Users/alice/Vault/", "/Users/alice/Vault") === "" && inVault("~/Vault/Notes", "/Users/alice/Vault", "/Users/alice") === "Notes")
  check("switcher: outside the vault is null, a sibling with the same start too", inVault("/Users/alice/Vault2/a.md", "/Users/alice/Vault") === null
    && inVault("/etc/hosts", "/Users/alice/Vault") === null && inVault("~/a.md", "/Users/alice/Vault") === null)
  check("switcher: Windows paths match by any case and slash", inVault("c:\\users\\alice\\vault\\Notes\\a.md", "C:\\Users\\alice\\Vault") === "Notes/a.md")
  check("switcher: a relative path is the vault's", inVault("Notes/Ideas/", "/Users/alice/Vault") === "Notes/Ideas" && inVault("./Notes/a.md", "") === "Notes/a.md")
}

