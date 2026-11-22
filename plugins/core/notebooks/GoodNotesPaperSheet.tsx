import React from "react"
import type { PageTemplate, PaperColor, PageSize, PageOrientation } from "./types"
import { PAGE_DIMENSIONS } from "./types"

interface GoodNotesPaperSheetProps {
  template: PageTemplate
  paperColor: PaperColor
  pageSize?: PageSize
  orientation?: PageOrientation
  zoom?: number
  sheetRef?: React.Ref<HTMLDivElement>
  children: React.ReactNode
}

function getRuledOrGridStyle(
  template: PageTemplate,
  bgColor: string,
  lineColor: string,
  marginColor: string,
  zoom: number
): React.CSSProperties {
  const lineGap = Math.round(28 * zoom)
  const lineGapWide = Math.round(40 * zoom)
  const gridSize = Math.round(24 * zoom)
  const dotSize = Math.round(20 * zoom)
  const marginWidth = Math.round(120 * zoom)

  if (template === "ruled") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `repeating-linear-gradient(transparent, transparent ${lineGap - 1}px, ${lineColor} ${lineGap - 1}px, ${lineColor} ${lineGap}px)`,
    }
  }
  if (template === "ruled-wide") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `repeating-linear-gradient(transparent, transparent ${lineGapWide - 1}px, ${lineColor} ${lineGapWide - 1}px, ${lineColor} ${lineGapWide}px)`,
    }
  }
  if (template === "grid") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `linear-gradient(to right, ${lineColor} 1px, transparent 1px), linear-gradient(to bottom, ${lineColor} 1px, transparent 1px)`,
      backgroundSize: `${gridSize}px ${gridSize}px`,
    }
  }
  if (template === "dotted") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `radial-gradient(${lineColor} 1.5px, transparent 1.5px)`,
      backgroundSize: `${dotSize}px ${dotSize}px`,
    }
  }
  if (template === "cornell") {
    return {
      backgroundColor: bgColor,
      backgroundImage: `linear-gradient(to right, transparent ${marginWidth}px, ${marginColor} ${marginWidth}px, ${marginColor} ${marginWidth + 2}px, transparent ${marginWidth + 2}px), repeating-linear-gradient(transparent, transparent ${lineGap - 1}px, ${lineColor} ${lineGap - 1}px, ${lineColor} ${lineGap}px)`,
    }
  }
  return { backgroundColor: bgColor }
}

function getPaperStyle(template: PageTemplate, paperColor: PaperColor = "white", zoom = 1): React.CSSProperties {
  const isDark = paperColor === "dark"
  const isCream = paperColor === "cream"
  const bgColor = isDark ? "#181b20" : isCream ? "#fefae0" : "#ffffff"
  const lineColor = isDark ? "rgba(255, 255, 255, 0.08)" : "rgba(30, 41, 59, 0.12)"
  const marginColor = isDark ? "rgba(244, 63, 94, 0.3)" : "rgba(225, 29, 72, 0.25)"
  return getRuledOrGridStyle(template, bgColor, lineColor, marginColor, zoom)
}

export const GoodNotesPaperSheet: React.FC<GoodNotesPaperSheetProps> = ({
  template,
  paperColor,
  pageSize = "Standard",
  orientation = "portrait",
  zoom = 1,
  sheetRef,
  children,
}) => {
  const dims = PAGE_DIMENSIONS[pageSize]?.[orientation] || PAGE_DIMENSIONS.Standard.portrait
  const width = Math.round(dims.width * zoom)
  const height = Math.round(dims.height * zoom)
  return (
    <div
      ref={sheetRef}
      className="goodnotes-paper-sheet relative rounded-md border border-slate-300/80 dark:border-slate-800 shadow-2xl shadow-black/20 dark:shadow-black/70 shrink-0 select-none transition-[width,height] duration-75"
      style={{
        ...getPaperStyle(template, paperColor, zoom),
        width: `${width}px`,
        height: `${height}px`,
      }}
    >
      {children}
    </div>
  )
}
