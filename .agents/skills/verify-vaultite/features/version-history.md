# Version history

A file's earlier versions, like a shared document's: who wrote each (You, an agent by name, another app or device),
what each changed marked in the note (its words added and taken out, its blocks added and removed), and Restore this
version, with Undo. A file an agent changed last, in the past day, says so at its top and leads here.

## Sub-features
- `writers`: each version names who wrote it; consecutive ones by the same writer within an hour fold under one (+N).
- `changes`: Show changes marks what that version changed against the one before; off, the version as it read.
- `restore`: Restore this version writes it back (the file's text before kept as a version); the toast's Undo puts it back.
- `stepper`: on a phone, Older version and Newer version step through them; All versions opens the list.
- `edited`: a file an agent changed last says "<agent> edited this <when>" in its header; a click opens its history.

## How to get to it (user POV)
- A file's menu (desktop: the tab's or the file's; phone: More, then More), Open version history.
- The palette's Open version history for the current file.
- The header line on a file an agent changed.

## Driving it with vv
Preconditions: `vv vau plugin on activity` (who wrote what comes from Activity), then make versions: a write as the
user (`curl -X PUT <base>/api/file -H 'X-Vaultite-Client: app/desktop' -d '{"path":"Notes/X.md","text":"..."}'`) and
two `vv vau edit` (an agent's, Claude Code's: each its own version).

- **List.** `vv open '#view/history%2FNotes%2FX.md'`. `vv eval '[...document.querySelectorAll("[data-history-entry]")]
  .map(e => e.textContent)'`: Current version first, by Claude Code; a version by You.
- **Changes.** `vv click --sel '[data-history-entry="<t>"]'` (an agent's): `[data-history-text] ins` holds its words.
- **Restore.** `vv click --role button --name "Restore this version"`; `vv vau read Notes/X.md` is that version.
  `vv click --role button --name Undo`: the text before is back.
- **Phone.** `vv viewport phone`: `vv click --role button --name "Older version"`, `--name "All versions"`.
- **Header.** `vv open '#file/Notes%2FX.md'` after an agent's edit: `[data-history-edited]` names it.
