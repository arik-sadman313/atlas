# ATLAS — PDF Engine Evaluation & Package Audit

**Date:** 2026-11-06  
**Milestone:** Milestone 4 — Notebook & PDF System  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Approved & Adopted  

---

## 1. Executive Summary & Directive

In accordance with the project's **Mature Software Reuse Directive**, ATLAS avoids developing a custom PDF parser, font rasterizer, or rendering pipeline from scratch.

A production-grade PDF engine for ATLAS must fulfill four mandatory criteria:
1. **True Cross-Platform Support:** Seamless operation across **Linux desktop**, **iPadOS**, and **Android** without platform-exclusive forks.
2. **Accurate Vector & Layout Coordinates:** Exact dimension reporting in standard PDF points ($1.0\text{ pt} = 1/72\text{ inch}$) to ensure handwritten ink annotations align with the underlying document regardless of screen density, zoom level, or device.
3. **High-Performance Viewport & Rasterization:** Hardware-accelerated rasterization at variable DPI, viewport culling, and offscreen page image generation for previews and thumbnail grids.
4. **Permissive Licensing:** Must be licensed under MIT, BSD, or Apache-2.0. Clean-room policy strictly prohibits GPL/AGPL dependencies.

---

## 2. Candidate Evaluation Matrix

| Criterion | A. pdfrx (^2.12.0) | B. pdfx (^2.6.0) | C. flutter_pdfview (^1.3.4) |
| :--- | :--- | :--- | :--- |
| **Published Version** | `2.12.0` (Actively maintained) | `2.6.0` | `1.3.4` |
| **License** | **MIT** | **MIT** | **Apache-2.0** |
| **Linux Desktop** | **Yes** (Native Google PDFium via `pdfium_flutter`) | Partial (requires manual CMake bundle) | **No** (Mobile only) |
| **iPadOS** | **Yes** (PDFKit / PDFium) | **Yes** (PDFKit) | **Yes** (PDFKit) |
| **Android** | **Yes** (Native Google PDFium) | **Yes** | **Yes** (AndroidPdfViewer) |
| **Coordinate System** | Exact dimensions in points ($Points = Inches \times 72$) | Relative percentage | View coordinates only |
| **Direct Raster Access** | `PdfPage.render(...)` returns raw pixel buffers / images | Limited | No raw pixel buffers |
| **Flutter 3.47+ Health** | **Clean compilation (0 warnings)** | Intermittent CMake breakages | Incompatible on Linux |

---

## 3. Candidate Breakdown

### 3.1 Candidate A: `pdfrx` (Selected)
- **Architecture:** Powered by Google's battle-tested `PDFium` engine via native C bindings (`pdfium_flutter` / `pdfium_dart`) on Linux, Android, and Desktop platforms, alongside native iOS bindings.
- **Key Capabilities:**
  - `PdfDocument.openFile(path)` and `PdfDocument.openData(bytes)` for CAS blob integration.
  - Direct access to page dimensions (`page.width`, `page.height`) in standard points.
  - High-resolution rendering to `ui.Image` with `PdfPage.render(...)` for thumbnail caches and export flattening.
  - Native tile/viewport culling preventing out-of-memory errors on 500+ page documents.
- **License Compliance:** MIT license. Zero transitive AGPL copyleft infection.

### 3.2 Candidate B: `pdfx` (Rejected)
- **Evaluation:** While previously viable, `pdfx` suffers from infrequent maintenance and CMake linkage discrepancies when building on newer Linux distributions (Debian 12/Ubuntu 24.04). It also lacks granular rasterization control required for our multi-layer annotation pipeline.

### 3.3 Candidate C: `flutter_pdfview` (Rejected)
- **Evaluation:** Only supports Android and iOS using platform views. Completely lacks Linux desktop support, directly violating the ATLAS Linux desktop mandate.

---

## 4. ATLAS Architectural Abstraction (`PdfRenderingService`)

To insulate ATLAS domain logic from the underlying rendering engine:
- The raw `pdfrx` APIs are encapsulated behind an abstract Dart interface: [`PdfRenderingService`](../lib/features/pdf/data/services/pdf_rendering_service.dart).
- Handlers convert document instances into immutable domain descriptors ([`PdfDocumentDescriptor`](../lib/features/pdf/domain/models/pdf_document_descriptor.dart)).
- Layer stacking mounts the PDF page as the background surface beneath `InkCanvas` on Linux and `PencilKit` on iPadOS with a fixed 1:1 point coordinate mapping.
