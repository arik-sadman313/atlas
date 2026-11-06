# ATLAS — Architectural Decision Records (ADRs)

## Index of Architectural Decision Records

- [ADR-001: Selection of Flutter + Dart as Unified Core](#adr-001-selection-of-flutter--dart-as-unified-core)
- [ADR-002: Dual Handwriting Engine Architecture](#adr-002-dual-handwriting-engine-architecture)
- [ADR-003: SQLite with Drift ORM & FTS5 as Local Source of Truth](#adr-003-sqlite-with-drift-orm--fts5-as-local-source-of-truth)
- [ADR-004: Adoption of AppFlowy Editor under MPL-2.0](#adr-004-adoption-of-appflowy-editor-under-mpl-20)
- [ADR-005: Custom Portable Ink Format (.atlas_ink) over PencilKit Serialization](#adr-005-custom-portable-ink-format-atlas_ink-over-pencilkit-serialization)
- [ADR-006: Riverpod with Code Generation for State Management](#adr-006-riverpod-with-code-generation-for-state-management)
- [ADR-007: Content-Addressable Storage (CAS) for Large File Blobs](#adr-007-content-addressable-storage-cas-for-large-file-blobs)
- [ADR-008: Clean-Room Policy for GPL/AGPL Candidate Projects](#adr-008-clean-room-policy-for-gplagpl-candidate-projects)
- [ADR-009: Hybrid Logical Clocks (HLC) for Sync Architecture Readiness](#adr-009-hybrid-logical-clocks-hlc-for-sync-architecture-readiness)
- [ADR-010: Adoption of pdfrx (PDFium) for High-Performance PDF Rendering](#adr-010-adoption-of-pdfrx-pdfium-for-high-performance-pdf-rendering)

---

### ADR-001: Selection of Flutter + Dart as Unified Core

- **Status:** Accepted
- **Context:** ATLAS must run across iPadOS, Linux desktop, and Android with high UI polish, responsive desktop multi-pane layouts, and consistent typography.
- **Decision:** Build ATLAS using the Flutter framework and Dart language.
- **Alternatives Considered:**
  - *React Native / Electron:* Poor Linux desktop support; heavy webview overhead; poor low-latency stylus drawing performance.
  - *Native per platform (Swift + Kotlin + C++/GTK):* Prohibitive development and maintenance costs; impossible to maintain feature parity across complex knowledge graphs, databases, and document engines.
  - *Qt / QML / C++:* Excellent on Linux, but poor developer velocity on iPadOS and Android; cumbersome modern state management.
- **Consequences:** 
  - (+) Single unified codebase for domain, data, and presentation layers.
  - (+) High-performance Skia/Impeller rendering engine capable of 120fps on ProMotion displays.
  - (-) Requires native platform views for Apple PencilKit on iPadOS.

---

### ADR-002: Dual Handwriting Engine Architecture

- **Status:** Accepted
- **Context:** iPadOS requires hardware-accelerated Apple Pencil input with sub-10ms latency, native palm rejection, and tilt/force response. Flutter's custom touch-event loop on iOS exhibits ~25-40ms latency, which feels sluggish for handwriting. Conversely, Linux desktop and Android cannot run Apple's proprietary PencilKit framework.
- **Decision:** Implement a dual-engine architecture:
  - **iPadOS:** Embed native iOS `PKCanvasView` inside Flutter using a `UIKitView` platform view, controlled via Swift method channels.
  - **Linux & Android:** Implement a pure Dart vector ink engine using `CustomPainter` with Catmull-Rom spline tessellation. Linux supports desktop mouse/tablet input; Android uses this engine purely for read-only viewing and vector zooming.
- **Consequences:**
  - (+) Provides the best possible native Apple Pencil experience on iPadOS.
  - (+) Provides portable, zero-dependency rendering on Linux and Android.
  - (-) Requires a bidirectional synchronization bridge to convert between native `PKDrawing` and portable `.atlas_ink`.

---

### ADR-003: SQLite with Drift ORM & FTS5 as Local Source of Truth

- **Status:** Accepted
- **Context:** ATLAS is a local-first application requiring complex relational queries (notebook hierarchies, task subtasks, backlinks, tags) and instantaneous full-text search.
- **Decision:** Use SQLite 3 via the **Drift** Dart ORM with WAL mode enabled and SQLite FTS5 virtual tables.
- **Alternatives Considered:**
  - *Hive / Isar:* NoSQL document stores lack robust relational foreign keys, complex JOIN capabilities, and standardized FTS5 ranking; Isar's maintenance has been inconsistent.
  - *Pure JSON / Markdown files on disk:* Fast for simple text, but scaling to 50,000 tasks, backlinks, and pages causes severe file I/O bottlenecks and lacks atomic transactions.
- **Consequences:**
  - (+) Fully ACID-compliant transactions prevent database corruption on crashes.
  - (+) Drift provides compile-time query verification and reactive streams.
  - (+) FTS5 delivers sub-15ms search across entire vaults.

---

### ADR-004: Adoption of AppFlowy Editor under MPL-2.0

- **Status:** Accepted
- **Context:** Building a Notion-style block editor from scratch with slash commands, markdown shortcuts, nested lists, and custom widgets requires thousands of engineering hours.
- **Decision:** Adopt the `appflowy_editor` package from pub.dev under the terms of the **Mozilla Public License 2.0 (MPL-2.0)**.
- **Alternatives Considered:**
  - *flutter_quill:* Uses Quill Delta format, which is linear rather than block-based; difficult to embed complex custom blocks like inline handwriting canvases.
  - *super_editor:* Highly composable, but requires immense boilerplate to achieve standard Notion-style productivity workflows.
- **Consequences:**
  - (+) Proven, actively maintained block document architecture.
  - (+) Pure Dart; zero Rust FFI overhead.
  - (+) MPL-2.0 is file-level copyleft; using it as a pub dependency does not infect the proprietary or commercial host application.

---

### ADR-005: Custom Portable Ink Format (.atlas_ink) over PencilKit Serialization

- **Status:** Accepted
- **Context:** Apple's `PKDrawing.dataRepresentation()` is an opaque, proprietary Apple binary format that cannot be decoded on Linux or Android without reverse-engineering private Apple frameworks.
- **Decision:** Define and standardize an open, cross-platform document format: **Atlas Portable Ink Format (`.atlas_ink`)**. On iPadOS, both the native `.pkdrawing` blob and the `.atlas_ink` representation are generated and stored concurrently.
- **Consequences:**
  - (+) Linux and Android can render, zoom, and analyze every stroke, pressure value, and layer.
  - (+) Future-proof against Apple proprietary format changes.
  - (-) Small conversion CPU overhead on page save (~10ms for 500 strokes).

---

### ADR-006: Riverpod with Code Generation for State Management

- **Status:** Accepted
- **Context:** ATLAS needs a predictable, compile-time safe, and highly testable state management system that integrates with Drift reactive database streams.
- **Decision:** Adopt **Riverpod** with code generation (`riverpod_annotation`, `riverpod_generator`).
- **Alternatives Considered:**
  - *Bloc:* Verbose boilerplate; high event-state overhead for rapid UI interactions.
  - *Provider:* Runtime lookup errors possible; lacks auto-dispose scoping and async notifier primitives.
- **Consequences:**
  - (+) Compile-time safety for all provider dependencies.
  - (+) Seamless conversion of Drift database streams into UI states.
  - (+) Clean dependency injection and mockability in unit tests.

---

### ADR-007: Content-Addressable Storage (CAS) for Large File Blobs

- **Status:** Accepted
- **Context:** Storing large binary drawings, raster previews, and PDF documents directly in SQLite tables degrades database query performance, increases memory usage, and makes vacuuming slow.
- **Decision:** Store all binary files in a Content-Addressable Storage (CAS) filesystem directory indexed by SHA-256 hash. The SQLite database stores only the hash, metadata, and relations.
- **Consequences:**
  - (+) SQLite database remains lean and lightning-fast.
  - (+) Automatic deduplication of identical attachments and templates.
  - (+) Simplifies future chunked delta-synchronization.

---

### ADR-008: Clean-Room Policy for GPL/AGPL Candidate Projects

- **Status:** Accepted
- **Context:** Several candidate open-source projects (Saber, Butterfly, AppFlowy Core) are licensed under GPL-3.0 or AGPL-3.0. Copying any code from them would force ATLAS to adopt copyleft licensing.
- **Decision:** Enforce a strict **Clean-Room Implementation Policy**. Developers may inspect these repositories to understand mathematical principles (e.g. Catmull-Rom splines, smart dark mode inversion), but zero code may be copied into the ATLAS codebase.
- **Consequences:**
  - (+) Eliminates all legal risk of copyleft infection.
  - (+) Ensures complete ownership and license freedom for ATLAS.
  - (-) Requires independent implementation of ink mathematics and UI controls.

---

### ADR-009: Hybrid Logical Clocks (HLC) for Sync Architecture Readiness

- **Status:** Accepted
- **Context:** ATLAS is local-first. When multi-device synchronization is activated in future milestones, devices will update notes and tasks while offline. Relying on physical wall-clock timestamps causes data loss due to clock drift.
- **Decision:** Design the database and mutation log (`sync_log`) around **Hybrid Logical Clocks (HLC)**.
- **Consequences:**
  - (+) Strict causal ordering of events across offline devices.
  - (+) Zero cloud infrastructure required in initial milestones.
  - (+) Smooth migration to peer-to-peer or server-assisted sync later.

---

### ADR-010: Adoption of pdfrx (PDFium) for High-Performance PDF Rendering

- **Status:** Accepted
- **Context:** ATLAS requires cross-platform PDF viewing and multi-layer ink annotation across iPadOS, Linux, and Android.
- **Decision:** Integrate `pdfrx` (MIT License), which wraps Google's PDFium library.
- **Alternatives Considered:**
  - *flutter_pdfview:* Android and iOS only; lacks Linux desktop support.
  - *pdfx:* Lacks advanced multi-layer custom canvas overlays.
- **Consequences:**
  - (+) Native C++ PDFium performance on Linux, Android, and iOS.
  - (+) Supports pinch-to-zoom, page virtualization, and custom coordinate mapping.
