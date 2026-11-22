import React from "react"
import type { PageTemplate, PaperColor } from "./types"

interface GoodNotesPaperSheetProps {
  template: PageTemplate
  paperColor: PaperColor
  children: React.ReactNode
}

function getRuledOrGridStyle(template: PageTemplate, bgColor: string, lineColor: string, marginColor: string): React.CSSProperties {
  if (template === "ruled") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `repeating-linear-gradient(transparent, transparent 27px, ${lineColor} 27px, ${lineColor} 28px)`,
    }
  }
  if (template === "ruled-wide") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `repeating-linear-gradient(transparent, transparent 39px, ${lineColor} 39px, ${lineColor} 40px)`,
    }
  }
  if (template === "grid") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `linear-gradient(to right, ${lineColor} 1px, transparent 1px), linear-gradient(to bottom, ${lineColor} 1px, transparent 1px)`,
      backgroundSize: "24px 24px",
    }
  }
  if (template === "dotted") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `radial-gradient(${lineColor} 1.5px, transparent 1.5px)`,
      backgroundSize: "20px 20px",
    }
  }
  if (template === "cornell") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `linear-gradient(to right, transparent 120px, ${marginColor} 120px, ${marginColor} 122px, transparent 122px), repeating-linear-gradient(transparent, transparent 27px, ${lineColor} 27px, ${lineColor} 28px)`,
    }
  }
  return { backgroundColor: bgColor }
}

function getPaperStyle(template: PageTemplate, paperColor: PaperColor = "white"): React.CSSProperties {
  const isDark = paperColor === "dark"
  const isCream = paperColor === "cream"
  const bgColor = isDark ? "#181b20" : isCream ? "#fefae0" : "#ffffff"
  const lineColor = isDark ? "rgba(255, 255, 255, 0.08)" : "rgba(30, 41, 59, 0.12)"
  const marginColor = isDark ? "rgba(244, 63, 94, 0.3)" : "rgba(225, 29, 72, 0.25)"
  return getRuledOrGridStyle(template, bgColor, lineColor, marginColor)
}

export const GoodNotesPaperSheet: React.FC<GoodNotesPaperSheetProps> = ({
  template,
  paperColor,
  children,
}) => (
  <div
    className="w-full h-full relative overflow-hidden transition-colors duration-200 select-none"
    style={getPaperStyle(template, paperColor)}
  >
    {children}
  </div>
)
