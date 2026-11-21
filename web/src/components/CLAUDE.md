# Notes for `web/src/components/`

- Settings: the Settings page holds only the app's own; a plugin's options are its settings sheet
  (`PluginSettings.tsx`), which Settings' search also finds. Choices in a sheet unfold in place, no menus (one menu only
  for a choice made of two, as a model and its effort). A page shows what most people set; what few change folds under
  its Advanced (manifest `settingsAdvanced`). A line about a Group is a `GroupNote`, in line with the titles.
- A setting's line under its label says, in a phrase, what the label can't: its description's first clause (`brief`);
  the rest is for agents and the tooltip. A long form groups its settings under headings (manifest `group`), sets a
  dependent one in under the one it hangs on (`when`: dimmed, never hidden), and folds what few change (`advanced`).
- A setting's value is always shown: its default as text in a muted tone, else what leaving it out does (`unset`),
  never a grey placeholder that reads as empty. A list of words is chips with an Add one, never a comma-separated field.
- A part that fails, fails alone: every tab, panel, header item and sheet draws in a `Guard` (`Guard.tsx`); smaller
  parts use `Catch`.
- Files a plugin draws (`FormatView.tsx`): the text is the only state, `onChange(text)` goes through autosave.
- Sidebars hold only plugins' panels, one model (`core/sidebars.ts`, shared with the CLI and Workspaces). A panel that
  wants room opens as a view, never tabs inside a sidebar. Panel heights go straight onto the boxes, no React render.
- Only a bounded box scrolls: `overflow-y-auto` on a box nothing bounds swallows the wheel. A component that may be
  either takes a prop (FileTree's `scroll`, a panel's `bounded`).
