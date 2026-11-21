## File history
Earlier versions of the vault's text files (Markdown, and code, JSON, HTML and CSV, of any size) are kept automatically
on the machine that runs the server, not in the vault: when a file changes (through the app, an AI, or on disk), its
previous content is saved when it had rested a minute, and at most once every `interval_min` minutes while it keeps
changing, for `keep_days` days; an agent's edit through the API is a version of its own (the file is kept just before
and just after it). Deleted and renamed files keep theirs.
- Read it: `vau history <file>` (`history.list`: its versions, newest first, each with `t` in ms and `by`, who wrote it:
  You, an agent as Activity names it), `vau history.read <file> <t>` (that version's text). Over HTTP: `GET
  /api/history?path=` (`versions`, `now`: the file now and who wrote it, `others`: versions plugins keep, a git
  plugin's commits, read with `&source=<source>&id=<id>`, each offering the service `versions:<source>`),
  `GET /api/history/version?path=&t=`.
- Restore one: `vau history restore <file> <t>` (`history.restore`): the text now is kept first (`was`, to restore it
  back), so it can be undone.
- `POST /api/history/keep {"path", "text"?}` keeps a version now, whatever the interval: the file as it is, or `text`.
- In the app: "Open version history" in a file's menu or the palette; a file an agent changed last says so at its top.
