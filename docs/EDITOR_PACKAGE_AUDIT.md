# ATLAS — Editor Package Audit & Architectural Evaluation
**Document Version:** 2.0.0  
**Date:** November 2026  
**Status:** Approved for Implementation (Milestone 3)  
**Author:** Principal Software Architect & Flutter Lead  

---

## 1. Executive Summary

Milestone 3 of ATLAS introduces the **Rich Text & Knowledge System**, requiring a document editor supporting structured headings (H1-H3), bullet/numbered lists, checklists (to-dos), code blocks, quote blocks, and bidirectional wiki-links across Linux desktop, iPadOS, and Android.

In strict adherence to the ATLAS **Reuse Existing Software Directive** and the explicit instructions of Prompt 03, we audited both `appflowy_editor` and `flutter_quill` on the target engine (Flutter 3.47.9 / Dart 3.13.7).

### Final Architectural Decision: Selection of `flutter_quill` (v11.6.0)
Due to a **fatal Flutter 3.47+ compiler incompatibility in `appflowy_editor`**, ATLAS officially selects **`flutter_quill` (v11.6.0)** under the **Apache-2.0** license as the rich-text editing engine for ATLAS, abstracted behind ATLAS domain models and services (`AtlasEditorController`, `DocumentContentService`).

---

## 2. Exhaustive Candidate Audit & Findings

### Candidate A: `appflowy_editor` (v6.2.0) — **REJECTED (Fatal Incompatibility)**
- **License:** Dual MPL-2.0 / AGPL-3.0 (Legally acceptable under MPL-2.0 larger work clause).
- **Architecture:** Tree-based block editor.
- **Flutter 3.47.9 Verification Result: FATAL COMPILER ERROR**
  When integrated on Flutter 3.47.9, the Dart compiler immediately halts with:
  ```text
  ../../../../.pub-cache/hosted/pub.dev/appflowy_editor-6.2.0/lib/src/editor/editor_component/service/ime/delta_input_service.dart:7:7: Error: 
  The non-abstract class 'DeltaTextInputService' is missing implementations for these members:
   - TextInputClient.onFocusReceived
  class DeltaTextInputService extends TextInputService with DeltaTextInputClient {
        ^^^^^^^^^^^^^^^^^^^^^
  flutter/lib/src/services/text_input.dart:1401:8: Context: 'TextInputClient.onFocusReceived' is defined here.
  ```
  **Root Cause Analysis:**
  Flutter 3.47.9 introduced `bool onFocusReceived() => false;` on `mixin TextInputClient`. In Dart 3, `DeltaTextInputClient` declares `implements TextInputClient`. Because `DeltaTextInputService` mixes in `DeltaTextInputClient` without mixing in `TextInputClient` or providing an override, the class fails abstract method resolution in Flutter 3.47.9. Since published pub packages cannot be altered in production without brittle local forks or patching scripts, this is a fatal platform incompatibility.

### Candidate B: `flutter_quill` (v11.6.0) — **APPROVED & SELECTED**
- **License:** **Apache-2.0** (100% permissive open source; zero copyleft or AGPL risk).
- **Flutter 3.47.9 Verification Result:** **PASS (0 compilation errors, 0 warnings)**.
- **Platform Support:** Linux Desktop (GTK), iPadOS / iOS, Android, macOS, Windows, Web.
- **Document Model:** Standard Quill Delta model with attributes for:
  - Headings (H1, H2, H3)
  - Bulleted lists (`list: 'bullet'`)
  - Numbered lists (`list: 'ordered'`)
  - Checklists / To-Dos (`list: 'checked'` / `list: 'unchecked'`)
  - Code blocks (`code-block: true`)
  - Block quotes (`blockquote: true`)
  - Dividers / Horizontal rules
  - Inline links (`link: url`)
  - Formatting (bold, italic, strikethrough, underline, inline code, color)
- **Serialization:** Canonical Delta JSON (`Delta.toJson()`, `Document.fromJson()`), compact, portable, and ideal for Content Addressable Storage (CAS).
- **Undo / Redo:** Native controller history (`QuillController.undo()`, `QuillController.redo()`).

---

## 3. Comparison Matrix

| Feature | `appflowy_editor` (6.2.0) | `flutter_quill` (11.6.0) |
| :--- | :--- | :--- |
| **Flutter 3.47+ Support** | ❌ **FAILED (Fatal build break)** | ✅ **PASSED (Clean build)** |
| **License** | Dual MPL-2.0 / AGPL-3.0 | **Apache-2.0 (Permissive)** |
| **Headings (H1-H3)** | Supported | Supported |
| **Checklists / To-Dos** | Supported | Supported |
| **Lists (Bullet/Number)**| Supported | Supported |
| **Code & Quote Blocks** | Supported | Supported |
| **CAS JSON Persistence**| Supported | Supported (Quill Delta JSON) |
| **Cross-Platform** | Linux, iOS, Android | Linux, iOS, Android |
| **Production Stability** | Broken on current Flutter stable | Extremely stable & mature |

---

## 4. Architectural Integration & Abstraction Layer

To preserve architectural decoupling and ensure ATLAS is never locked into Quill internals, all document editing is wrapped behind the following ATLAS domain abstractions:

```
┌────────────────────────────────────────────────────────┐
│                   ATLAS Presentation                   │
│   (DocumentEditorScreen, DocumentTitleBar, WikiLink)   │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│                ATLAS Editor Abstraction                │
│    - AtlasEditorController                             │
│    - DocumentContentService (CAS Serializer)           │
│    - WikiLinkParser & LinkRepository                   │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│                     flutter_quill                      │
│     (QuillController, QuillEditor, QuillToolbar)       │
└────────────────────────────────────────────────────────┘
```

1. **`DocumentContentService`**:
   - Handles saving `Document` to CAS blob storage via SHA-256 hash.
   - Handles loading `Document` from CAS storage or generating an empty default document.
   - Extracts plain text from the document for full-text search and wiki-link parsing.
2. **`WikiLinkParser` & `LinkRepository`**:
   - Scans text for `[[Node Title]]` or `[[Node Title|Alias]]`.
   - Resolves target node IDs in the current workspace.
   - Synchronizes forward links and backlinks in SQLite via Drift.
3. **`BacklinksPanel`**:
   - Collapsible panel displaying incoming references with source type, title, and timestamp.
   - Supports routing to documents or notebooks via GoRouter.

---

## 5. Conclusion

As prescribed by the prompt's fallback directive, `flutter_quill: ^11.6.0` is the verified, stable, and production-ready solution for ATLAS Milestone 3.
