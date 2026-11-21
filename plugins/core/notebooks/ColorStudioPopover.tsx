import { useState, useEffect } from "react"
import { Palette, Plus, Check, Sparkles } from "lucide-react"

interface ColorStudioPopoverProps {
  quickColors: string[]
  activeColorIndex: number
  onSelectQuickSlot: (index: number) => void
  onChangeQuickColor: (index: number, newColor: string) => void
  onClose: () => void
}

const ESSENTIAL_PALETTE = [
  "#000000",
  "#1e293b",
  "#334155",
  "#475569",
  "#1e3a8a",
  "#2563eb",
  "#0284c7",
  "#0891b2",
  "#14532d",
  "#16a34a",
  "#059669",
  "#10b981",
  "#7f1d1d",
  "#dc2626",
  "#ea580c",
  "#d97706",
  "#581c87",
  "#7c3aed",
  "#9333ea",
  "#c026d3",
]

const PASTEL_PALETTE = [
  "#fecdd3", // blush
  "#fda4af", // soft rose
  "#fed7aa", // peach
  "#fef08a", // butter yellow
  "#dcfce7", // honeydew
  "#bbf7d0", // mint
  "#cffafe", // sky mint
  "#bae6fd", // powder blue
  "#bfdbfe", // pastel blue
  "#c7d2fe", // periwinkle
  "#ddd6fe", // lilac
  "#f5d0fe", // lavender
  "#fbcfe8", // bubblegum
  "#e2e8f0", // cool oat
  "#fef3c7", // vanilla cream
  "#ffedd5", // warm biscuit
]

const VINTAGE_PALETTE = [
  "#451a03", // espresso
  "#78350f", // sepia
  "#9a3412", // terracotta
  "#b45309", // warm ochre
  "#4d7c0f", // olive
  "#3f6212", // moss
  "#134e4a", // dark teal
  "#1e293b", // slate navy
  "#831843", // wine
  "#701a75", // plum
]

const NEON_PALETTE = [
  "#facc15", // cyber yellow
  "#a3e635", // electric lime
  "#38bdf8", // vivid cyan
  "#f43f5e", // neon pink
  "#fb923c", // neon orange
  "#c084fc", // neon purple
  "#34d399", // bright emerald
  "#fb7185", // hot coral
]

export function ColorStudioPopover({
  quickColors,
  activeColorIndex,
  onSelectQuickSlot,
  onChangeQuickColor,
  onClose,
}: ColorStudioPopoverProps) {
  const [tab, setTab] = useState<"presets" | "custom">("presets")
  const activeColor = quickColors[activeColorIndex] || quickColors[0]
  const [hexInput, setHexInput] = useState(activeColor)
  const [customPalette, setCustomPalette] = useState<string[]>(() => {
    try {
      const stored = localStorage.getItem("goodnotes_custom_palette")
      if (stored) {
        return JSON.parse(stored)
      }
    } catch {
      // Fallback
    }
    return ["#6366f1", "#ec4899", "#8b5cf6", "#14b8a6", "#f97316"]
  })

  useEffect(() => {
    setHexInput(activeColor)
  }, [activeColor])

  const saveCustomPalette = (colors: string[]) => {
    setCustomPalette(colors)
    try {
      localStorage.setItem("goodnotes_custom_palette", JSON.stringify(colors))
    } catch {
      // Ignore
    }
  }

  const handleHexSubmit = (val: string) => {
    let clean = val.trim()
    if (!clean.startsWith("#")) clean = "#" + clean
    if (/^#[0-9A-Fa-f]{6}$/.test(clean)) {
      onChangeQuickColor(activeColorIndex, clean)
    }
  }

  const addCurrentToCustomPalette = () => {
    if (!customPalette.includes(activeColor)) {
      const updated = [activeColor, ...customPalette].slice(0, 24)
      saveCustomPalette(updated)
    }
  }

  const removeFromCustomPalette = (colorToRemove: string) => {
    const updated = customPalette.filter((c) => c !== colorToRemove)
    saveCustomPalette(updated)
  }

  return (
    <div className="w-84 bg-white dark:bg-[#1a1e26] rounded-2xl shadow-2xl border border-slate-200/80 dark:border-slate-800/80 backdrop-blur-xl p-4 flex flex-col gap-3.5 animate-in fade-in zoom-in-95 duration-150">
      {/* Header: Quick Color Slot Selection */}
      <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800/60 pb-2.5">
        <div className="flex items-center gap-1.5 text-xs font-bold text-slate-800 dark:text-slate-100 uppercase tracking-wider">
          <Palette className="w-3.5 h-3.5 text-purple-500" />
          <span>Color Studio</span>
        </div>
        <button
          onClick={onClose}
          className="text-xs font-medium text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
        >
          Done
        </button>
      </div>

      {/* 3 Quick Color Target Slots */}
      <div className="flex items-center justify-between bg-slate-100 dark:bg-slate-800/50 p-1.5 rounded-xl">
        <span className="text-[11px] font-semibold text-slate-500 dark:text-slate-400 pl-1">
          Active Slot:
        </span>
        <div className="flex items-center gap-2">
          {quickColors.map((color, idx) => (
            <button
              key={idx}
              onClick={() => onSelectQuickSlot(idx)}
              className={`w-7 h-7 rounded-full border-2 transition-all flex items-center justify-center ${
                activeColorIndex === idx
                  ? "border-blue-600 ring-2 ring-blue-400/40 scale-110 shadow-md"
                  : "border-white dark:border-slate-700 hover:scale-105"
              }`}
              style={{ backgroundColor: color }}
              title={`Quick Color Slot ${idx + 1}`}
            >
              {activeColorIndex === idx && <Check className="w-3.5 h-3.5 text-white drop-shadow-md stroke-[3]" />}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Switcher */}
      <div className="flex rounded-lg bg-slate-100 dark:bg-slate-800/60 p-0.5 text-xs font-semibold">
        <button
          onClick={() => setTab("presets")}
          className={`flex-1 py-1 rounded-md transition-all ${
            tab === "presets"
              ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm"
              : "text-slate-500 dark:text-slate-400 hover:text-slate-700"
          }`}
        >
          Curated Palettes
        </button>
        <button
          onClick={() => setTab("custom")}
          className={`flex-1 py-1 rounded-md transition-all ${
            tab === "custom"
              ? "bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-sm"
              : "text-slate-500 dark:text-slate-400 hover:text-slate-700"
          }`}
        >
          Custom & Wheel
        </button>
      </div>

      {/* Tab Content: Curated Palettes */}
      {tab === "presets" && (
        <div className="flex flex-col gap-3 max-h-72 overflow-y-auto pr-1">
          {/* Essentials */}
          <div>
            <div className="text-[11px] font-semibold text-slate-500 dark:text-slate-400 mb-1.5 flex items-center justify-between">
              <span>Standard Essentials</span>
            </div>
            <div className="grid grid-cols-10 gap-1.5">
              {ESSENTIAL_PALETTE.map((c) => (
                <button
                  key={c}
                  onClick={() => onChangeQuickColor(activeColorIndex, c)}
                  className={`w-6 h-6 rounded-full border border-slate-200 dark:border-slate-700 transition-transform hover:scale-115 ${
                    activeColor.toLowerCase() === c.toLowerCase() ? "ring-2 ring-blue-500 scale-110" : ""
                  }`}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>

          {/* Aesthetic Pastel */}
          <div>
            <div className="text-[11px] font-semibold text-slate-500 dark:text-slate-400 mb-1.5 flex items-center justify-between">
              <span>GoodNotes Aesthetic Pastel</span>
              <Sparkles className="w-3 h-3 text-amber-500" />
            </div>
            <div className="grid grid-cols-8 gap-1.5">
              {PASTEL_PALETTE.map((c) => (
                <button
                  key={c}
                  onClick={() => onChangeQuickColor(activeColorIndex, c)}
                  className={`w-6 h-6 rounded-full border border-slate-200 dark:border-slate-700 transition-transform hover:scale-115 ${
                    activeColor.toLowerCase() === c.toLowerCase() ? "ring-2 ring-blue-500 scale-110" : ""
                  }`}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>

          {/* Vintage Earth */}
          <div>
            <div className="text-[11px] font-semibold text-slate-500 dark:text-slate-400 mb-1.5">
              Vintage Earth Tones
            </div>
            <div className="grid grid-cols-10 gap-1.5">
              {VINTAGE_PALETTE.map((c) => (
                <button
                  key={c}
                  onClick={() => onChangeQuickColor(activeColorIndex, c)}
                  className={`w-6 h-6 rounded-full border border-slate-200 dark:border-slate-700 transition-transform hover:scale-115 ${
                    activeColor.toLowerCase() === c.toLowerCase() ? "ring-2 ring-blue-500 scale-110" : ""
                  }`}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>

          {/* Neon & Highlighting */}
          <div>
            <div className="text-[11px] font-semibold text-slate-500 dark:text-slate-400 mb-1.5">
              Neon Highlighting
            </div>
            <div className="grid grid-cols-8 gap-1.5">
              {NEON_PALETTE.map((c) => (
                <button
                  key={c}
                  onClick={() => onChangeQuickColor(activeColorIndex, c)}
                  className={`w-6 h-6 rounded-full border border-slate-200 dark:border-slate-700 transition-transform hover:scale-115 ${
                    activeColor.toLowerCase() === c.toLowerCase() ? "ring-2 ring-blue-500 scale-110" : ""
                  }`}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Tab Content: Custom Color Wheel & Hex */}
      {tab === "custom" && (
        <div className="flex flex-col gap-3">
          {/* Wheel & Hex Row */}
          <div className="flex items-center gap-3 bg-slate-50 dark:bg-slate-900/50 p-2.5 rounded-xl border border-slate-200/70 dark:border-slate-800">
            {/* Native HTML5 Color Wheel Trigger */}
            <div className="relative w-10 h-10 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 shadow flex-shrink-0 cursor-pointer">
              <input
                type="color"
                value={activeColor}
                onChange={(e) => {
                  onChangeQuickColor(activeColorIndex, e.target.value)
                  setHexInput(e.target.value)
                }}
                className="absolute -top-4 -left-4 w-20 h-20 cursor-pointer border-none"
              />
            </div>

            {/* Hex Input */}
            <div className="flex-1 flex flex-col gap-1">
              <span className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">
                Hex Code (#RRGGBB)
              </span>
              <input
                type="text"
                value={hexInput}
                onChange={(e) => {
                  setHexInput(e.target.value)
                  handleHexSubmit(e.target.value)
                }}
                onBlur={() => handleHexSubmit(hexInput)}
                className="w-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg px-2.5 py-1 text-xs font-mono font-semibold text-slate-800 dark:text-slate-100 outline-none focus:ring-1 focus:ring-blue-500"
                placeholder="#000000"
                maxLength={7}
              />
            </div>

            {/* Add to Custom Palette Button */}
            <button
              onClick={addCurrentToCustomPalette}
              className="p-2 rounded-lg bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 hover:bg-blue-100 transition-colors flex items-center justify-center"
              title="Add current color to Custom Palette"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>

          {/* User's Saved Custom Palette */}
          <div>
            <div className="flex items-center justify-between text-[11px] font-semibold text-slate-500 dark:text-slate-400 mb-1.5">
              <span>Saved Custom Swatches ({customPalette.length})</span>
            </div>
            {customPalette.length === 0 ? (
              <div className="text-[11px] text-slate-400 italic py-2 text-center">
                No custom colors saved yet. Use the color picker above and click + to save.
              </div>
            ) : (
              <div className="grid grid-cols-8 gap-1.5 max-h-36 overflow-y-auto pr-1">
                {customPalette.map((c) => (
                  <div key={c} className="group relative">
                    <button
                      onClick={() => onChangeQuickColor(activeColorIndex, c)}
                      className={`w-6 h-6 rounded-full border border-slate-200 dark:border-slate-700 transition-transform hover:scale-115 ${
                        activeColor.toLowerCase() === c.toLowerCase() ? "ring-2 ring-blue-500 scale-110" : ""
                      }`}
                      style={{ backgroundColor: c }}
                    />
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        removeFromCustomPalette(c)
                      }}
                      className="absolute -top-1 -right-1 w-3.5 h-3.5 rounded-full bg-rose-500 text-white hidden group-hover:flex items-center justify-center text-[9px] shadow"
                      title="Remove swatch"
                    >
                      ×
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
