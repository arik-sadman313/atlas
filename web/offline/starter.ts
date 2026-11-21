import vectorDrawing from "../../examples/vault/Notes/Vector Drawing.notebook?raw"

export const START_HERE_TEXT = `---
type: dashboard
icon: compass
tint: blue
---

# Welcome to Atlas for iPad 📱✨

Atlas is your high-performance, standalone notebook and digital workspace running **100% natively and offline** on your iPad. No servers, no host machine, and no network connection required.

---

## 🎨 Note-Taking & Vector Canvas Suite
Open **\`Notes/Vector Drawing.notebook\`** from the sidebar to test the full GoodNotes precision engine:

- **3 Distinct Pen Engines**:
  - **Fountain Pen**: Velocity and pressure-sensitive calligraphic taper for elegant cursive.
  - **Ballpoint Pen**: Crisp, uniform stroke width with smooth rounded nibs.
  - **Brush Pen**: Wide dynamic pressure response for artistic lettering and calligraphy.
- **Designer Color Studio**:
  - Quick 3-slot top-bar swatches.
  - Presets: *GoodNotes Aesthetic Pastel*, *Vintage Earth Tones*, *Neon Highlighting*, and *Standard Essentials*.
  - Full Spectrum HTML5 Color Wheel with live hex input and custom palette storage.
- **Precision Tools**:
  - **Highlighter**: Darken/multiply blend mode under text with straight-line auto-snap.
  - **Eraser Modes**: Precision Eraser, Standard Eraser, and Stroke Eraser.
  - **Shape Recognition**: Draw and hold any rough stroke to snap into clean lines, circles, ellipses, triangles, and rectangles.
- **Apple Pencil & iPad Gestures**:
  - **100% Palm Rejection**: Differentiates Apple Pencil from touch gestures.
  - **Multi-Touch Navigation**: Two-finger smooth pan and pinch-to-zoom (0.5x to 3.0x).
  - **120Hz ProMotion**: Low-latency hardware-accelerated vector rendering.

---

## 📁 Local Files & Privacy
Everything in Atlas is stored directly on your iPad in your sandbox Documents storage:
\`On My iPad > Vault > Atlas\`

You can create, organize, and export your notes freely at any time.
`

export const QUICK_NOTE = JSON.stringify({
  version: 1,
  title: "Quick Note",
  createdAt: Date.now(),
  updatedAt: Date.now(),
  pages: [
    {
      id: "page_1",
      pageNumber: 1,
      template: "ruled",
      strokes: [],
      textBoxes: [],
      images: [],
    },
  ],
}, null, "\t")

export function getStarterFiles(): Record<string, string> {
  return {
    "Start here.md": START_HERE_TEXT,
    "Notes/Vector Drawing.notebook": vectorDrawing,
    "Notes/Quick Note.notebook": QUICK_NOTE,
    ".vaultite/pages.json": JSON.stringify({
      pinned: ["Notes/Vector Drawing.notebook", "Start here.md"],
      pinNew: false,
    }, null, 2),
    ".vaultite/sidebars.json": JSON.stringify({
      left: ["pages:pages", "files:files"],
      right: [],
      collapsed: [],
    }, null, 2),
  }
}
