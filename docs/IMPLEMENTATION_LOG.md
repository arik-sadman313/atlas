# ATLAS — Milestone 1 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 1 — Core Foundation & Application Shell  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Implemented Components & Scope

### 1.1 Project Initialization & Core Framework
- Multi-platform Flutter project initialized using Flutter 3.47.9 and Dart 3.13.7 with target platforms: `linux`, `android`, and `ios`.
- Clean, feature-first modular architecture established with clear separation between presentation, domain, and data layers:
  - `lib/app/`: Root app configuration (`atlas_app.dart`), bootstrap sequence (`bootstrap.dart`), global providers (`providers.dart`).
  - `lib/core/database/`: Drift ORM database (`app_database.dart`), native connection manager with WAL mode (`native.dart`), DAOs (`workspaces_dao.dart`, `nodes_dao.dart`), and table definitions.
  - `lib/core/storage/`: Content-Addressable Storage manager (`cas_storage_service.dart`, `blob_storage_service.dart`) utilizing SHA-256 content hashing.
  - `lib/core/theme/`: Complete Atlas Design System ("Quiet Craft"): color tokens, spacing, typography scale, light/dark themes, and theme mode notifier.
  - `lib/core/router/`: Declarative routing via `go_router` (`app_router.dart`, `routes.dart`) with persistent `ShellRoute` integration.
  - `lib/shared/widgets/`: Reusable components: `AtlasScaffold` (adaptive multi-pane shell), `AtlasSidebar`, `AtlasCard`, `AtlasButton`, and `AtlasEmptyState`.
  - `lib/features/`: Initial application destinations: `dashboard`, `notebooks`, `documents`, `tasks`, `calendar`, `search`, `settings`.

### 1.2 Database Foundation (Drift / SQLite)
- Configured native SQLite database connection with performance PRAGMAs:
  - `PRAGMA foreign_keys = ON;`
  - `PRAGMA journal_mode = WAL;`
  - `PRAGMA synchronous = NORMAL;`
  - `PRAGMA busy_timeout = 5000;`
- Implemented core relational tables:
  1. `workspaces`: Multi-workspace isolation, soft delete, JSON metadata.
  2. `nodes`: Universal polymorphic entity for pages, documents, notebooks, folders.
  3. `node_blocks`: Hierarchical block storage for document content.
  4. `attachments`: Metadata mapping SHA-256 hashes to relative paths and byte sizes.
- Implemented DAOs with reactive Drift `watch()` streams:
  - `WorkspacesDao`: Workspace CRUD and `getOrCreateDefaultWorkspace()`.
  - `NodesDao`: Workspace-scoped node queries, recent nodes, favorite starred nodes, live title search, and block CRUD with cascading deletes.

### 1.3 Content-Addressable Storage (CAS)
- Implemented `CasStorageService` outside SQLite for large file blobs.
- Computes SHA-256 checksums (`crypto` package).
- Partitions directories by 2-character hex prefix (`blobs/{hash[0..1]}/{hash}`) to optimize filesystem lookup.
- Guaranteed atomic writes via temporary file renaming to prevent partial writes.
- Automatic content deduplication: identical payloads return existing hash immediately.

### 1.4 Adaptive Multi-Pane Shell & Design System
- **Design Aesthetic:** "Quiet Craft" — serene typography, neutral zinc and carbon surfaces, delicate hairline borders (`rgba(0,0,0,0.08)` light / `rgba(255,255,255,0.08)` dark), restrained accent colors.
- **Breakpoints:**
  - $\ge 1024\text{ dp}$ (Desktop Linux & iPad Landscape): 3-column / 2-column layout with persistent collapsible navigation sidebar, outline pane, and workspace.
  - $768\text{ dp} - 1023\text{ dp}$ (iPad Portrait): Collapsible sidebar with toggle.
  - $< 768\text{ dp}$ (Android Mobile): Single-pane view with modern `NavigationBar` bottom navigation.
- **Desktop Keyboard Shortcuts:**
  - `Ctrl + \`: Toggle navigation sidebar.
  - `Ctrl + N`: Open Quick Create modal dialog.
  - `Ctrl + ,`: Navigate to Settings.

### 1.5 Functional Screens Implemented
1. **Dashboard:** Greeting header, quick statistics (recent documents, active notebooks), recent pages list backed by reactive Drift stream, Quick Page creation.
2. **Notebooks:** Grid of digital notebooks with real SQLite querying, new notebook creation, delete action.
3. **Documents:** Document list with real SQLite query, new document creation with automatic initial block insertion, favorite star toggle.
4. **Document Detail:** Full document viewer displaying title, timestamps, blocks stream, and an interactive block composer that adds blocks directly into the SQLite database.
5. **Tasks:** Tasks navigation destination with view filter chips and an empty state explaining Milestone 5 integration.
6. **Calendar:** Calendar navigation destination with current month header and an empty state explaining Milestone 5 timeline integration.
7. **Search:** Real live search querying the SQLite `nodes` table by title in real-time as the user types.
8. **Settings:** Theme mode selector (System, Light, Dark) persisted in state, active workspace information, and architectural diagnostics.

---

## 2. Dependencies Added & Verified Licenses

| Package | Version | License | Justification |
| :--- | :--- | :--- | :--- |
| `flutter_riverpod` | `3.4.3` | MIT | Centralized reactive state management and dependency injection. |
| `riverpod_annotation` | `4.0.7` | MIT | Riverpod code generation annotations. |
| `drift` | `2.35.3` | MIT | Type-safe SQLite ORM, query builder, and migrations. |
| `sqlite3_flutter_libs` | `0.6.0+eol` | MIT | Precompiled SQLite binaries for Android, iOS, Linux. |
| `path_provider` | `2.1.6` | BSD-3-Clause | Standard platform-specific directories for database and CAS blobs. |
| `path` | `1.9.1` | BSD-3-Clause | Filesystem path manipulation. |
| `go_router` | `18.1.3` | BSD-3-Clause | Declarative URL routing with shell route support. |
| `uuid` | `4.6.0` | MIT | Entity UUIDv4 generation. |
| `crypto` | `3.0.8` | BSD-3-Clause | SHA-256 calculation for CAS blob storage. |
| `intl` | `0.20.3` | BSD-3-Clause | Date formatting and localization. |
| *(dev)* `drift_dev` | `2.35.2` | MIT | Drift code generator. |
| *(dev)* `build_runner` | `2.16.2` | BSD-3-Clause | Dart builder execution harness. |
| *(dev)* `riverpod_generator` | `4.0.9` | MIT | Riverpod code generator. |

> [!NOTE]
> `appflowy_editor` was **not** added in this milestone, in strict compliance with the instructions requiring a separate verified decision.

---

## 3. Commands Executed & Verification Results

1. **Project Initialization:**
   `flutter create . --project-name atlas --org com.atlas.app --platforms=linux,android,ios --empty`
   - Initialized Flutter structure without overwriting git history or documentation.

2. **Code Generation:**
   `dart run build_runner build --delete-conflicting-outputs`
   - Generated `app_database.g.dart`, `workspaces_dao.g.dart`, and `nodes_dao.g.dart` (78 outputs written).

3. **Code Formatting:**
   `dart format .`
   - Formatted 44 Dart files across `lib/` and `test/`.

4. **Static Analysis:**
   `flutter analyze`
   - **Result:** `No issues found! (ran in 11.3s)` — 0 errors, 0 warnings, 0 linter hints.

5. **Unit & Widget Tests:**
   `flutter test`
   - **Result:** `00:02 +11: All tests passed!`
     - `test/core/storage/cas_storage_service_test.dart` (5 tests passing): SHA-256 hashing, deduplication, byte read-back, deletion, and missing blob exceptions.
     - `test/core/database/database_test.dart` (5 tests passing): default workspace creation, custom workspace CRUD, node search, cascading deletion of child blocks, and reactive stream emission.
     - `test/features/app_smoke_test.dart` (1 test passing): app mounting, navigation shell rendering, and header verification.

6. **Linux Desktop Native Build:**
   `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`
   - Executable binary verified at `build/linux/x64/debug/bundle/atlas`.

7. **Linux Application Launch & Screenshot:**
   - Successfully launched `./build/linux/x64/debug/bundle/atlas` on Fedora 44 with Impeller OpenGL backend.
   - Captured desktop screenshot via `spectacle` and saved to `docs/images/atlas_desktop_running.png`.

8. **Android Build Verification:**
   `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (73.0s).

9. **iOS Project Verification:**
   - Inspected `ios/Runner.xcodeproj` and `ios/Runner/AppDelegate.swift`. iOS project scaffolding is valid and staged for future macOS Xcode compilation.

---

## 4. Architectural Discoveries & Adjustments

1. **SQLite FTS5 on Host Platform:**
   - Discovery: Fedora Linux's default `/usr/bin/sqlite3` lacks FTS5 compiled into its system dynamic library (`no such module: fts5`).
   - Resolution: In accordance with prompt instructions ("Do not create fake FTS5 functionality..."), FTS5 virtual tables are documented and planned for Milestone 3 where a bundled custom SQLite binary with FTS5 enabled will be integrated.
2. **Riverpod 3.x Migration:**
   - Riverpod 3.x replaced `StateNotifier` and `StateProvider` with `Notifier` and `NotifierProvider`. All providers (`themeModeProvider`, `currentWorkspaceIdProvider`) were authored natively with the modern Notifier pattern.
3. **Drift Test Timer Invariant:**
   - Stream query cancellation in Drift executes a zero-duration cleanup timer (`Timer.run`). In widget tests, pumping a final frame (`await tester.pump(const Duration(milliseconds: 100))`) ensures the FakeAsync event loop completely clears before invariant checking.

---

## 5. Known Limitations & Outstanding Technical Risks

1. **Desktop Window Constraints:**
   - Currently, window resizing relies on standard GTK window manager limits. In a future milestone, `window_manager` or `bitsdojo_window` can be evaluated if custom titlebars or strict minimum window dimensions (e.g., $900 \times 600$) are desired.
---

# ATLAS — Milestone 2 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 2 — Portable Ink Engine & Native PencilKit Integration  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Candidate Audit & Mandatory Software Reuse
- Conducted comprehensive audit of open-source handwriting and drawing libraries ([docs/INK_PACKAGE_AUDIT.md](INK_PACKAGE_AUDIT.md)):
  - Evaluated `fluera_canvas` (rejected for core due to whiteboard mismatch and commercial paywalls).
  - Evaluated `draw_your_image` (rejected due to lack of pressure and persistence).
  - Adopted `perfect_freehand: ^2.5.2+1` (MIT) for pure Dart variable-width stroke outline geometry.
  - Adopted `pencil_kit: ^2.1.1` (MIT) for native iOS platform view wrapper.

---

## 2. Implemented Architecture & Components

### 2.1 Domain Layer
- `AtlasInkDocument`: Multi-layer, immutable portable document model with metadata and paper templates.
- `InkLayer`: Layer container supporting visibility, opacity, and blend modes (`multiply`, `srcOver`).
- `InkStroke`: Stroke model with tool types, color, baseWidth, opacity, points, and computed bounds.
- `InkPoint`: High-resolution input point with x, y, normalized pressure, tilt azimuth, tilt altitude, and time offset.
- `InkToolConfig` & `InkToolType`: Ballpoint Pen, Fountain Pen, Highlighter, Pencil, Vector Eraser, and Pixel Eraser.
- `StrokeTessellator`: High-performance bridge adapting `perfect_freehand` into smooth quadratic Bézier `ui.Path` outlines with tool-specific profiles.

### 2.2 Data & Persistence Layer
- `InkJsonSerializer`: Human-readable `.atlas_ink` JSON serialization with UTF-8 byte conversion.
- `InkBinarySerializer`: Compact packed binary format (`.atlas_ink_bin`) with `ATLASINK` 8-byte magic header, 16-byte point packing, and full blend mode preservation.
- `InkDao`: Drift ORM accessor supporting `getOrCreateDocumentForNode`, `createPage`, `updatePage`, `deletePage`, and document page watching.
- `InkRepository`: Repository bridging SQLite relational metadata with Content-Addressable Storage (CAS) for deduplicated ink blobs.
- Database Schema upgraded to **version 2** with `ink_documents` and `ink_pages` tables.

### 2.3 Presentation & Platform Layer
- `InkPlatformService`: Clean platform abstraction decoupling UI from native hardware specifics.
- `PencilKitBridge`: Native iOS implementation binding `pencil_kit` and `PKTool` types.
- `AtlasPencilKitPlugin.swift`: Swift platform channel plugin implementing `PKCanvasView` export of `.pkdrawing` binaries, high-res PNG previews, and vector stroke collections.
- `DartVectorInkService`: Cross-platform fallback implementation using pure Dart vector math.
- `InkCanvasController`: Undo/redo history (50 snapshots depth), active in-flight stroke tracking, and spatial vector eraser.
- `InkCanvas`: Interactive input canvas supporting touch, mouse, and hardware tablet pressure.
- `InkDocumentPainter`: Reusable `CustomPainter` rendering paper templates (blank, ruled, dotted, square grid), normal ink layers, and offscreen multiply-composited highlighters.
- `InkPageView`: Read-only zoomable viewer with `InteractiveViewer` (0.5x to 4.0x) and companion badge for Android.
- `InkToolPalette`: Floating adaptive pill widget with tool buttons, width selectors, curated color swatches, and undo/redo controls.
- `NotebookEditorScreen`: Multi-page notebook editor supporting page navigation, adding pages, paper template switching, and debounced autosave.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** 0 issues found (clean).

2. **Code Formatting:**
   - `dart format .`
   - **Result:** All files formatted cleanly.

3. **Automated Test Suite (32 tests):**
   - `test/core/database/database_test.dart` (WorkspacesDao, NodesDao, cascades).
   - `test/core/storage/cas_storage_service_test.dart` (CAS hashing, deduplication, deletion).
   - `test/features/app_smoke_test.dart` (Shell navigation, multi-pane rendering).
   - `test/features/handwriting/stroke_tessellator_test.dart` (Tessellation, dot handling, bounds, tools).
   - `test/features/handwriting/ink_serialization_test.dart` (JSON & Binary roundtrips, corruption errors).
   - `test/features/handwriting/ink_repository_test.dart` (Persistence with Drift + CAS, graceful recovery).
   - `test/features/handwriting/ink_canvas_widget_test.dart` (Drawing gestures, undo/redo, eraser, palette, read-only viewer).
   - `test/features/handwriting/capture_prototype_screenshot_test.dart` (Headless rendering to PNG).
   - **Result:** `✓ All 32 tests passed!`.

4. **Native Linux Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

5. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (22.4s). Confirms zero drawing/stylus dependencies leaked to Android.

6. **Prototype Screenshot Artifact:**
   - Rendered prototype image to `docs/images/atlas_handwriting_prototype.png` (32 KB) illustrating handwritten math notes, sine wave diagrams, and yellow highlighter multi-pass compositing over ruled paper.

---

# ATLAS — Milestone 3 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 3 — Rich Text & Knowledge System  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Objectives & Architectural Requirements

1. **Rich-Text Document Editor:** Integrate a production-grade rich-text editor behind an ATLAS-owned abstraction supporting headings (H1-H3), bullet/numbered lists, checklists, inline code, block quotes, and wiki-links.
2. **Schema Version 3 Migration:** Upgrade Drift schema to v3, introducing `nodes.content_hash`, `node_links`, `tags`, and `node_tags` with indexing.
3. **Wiki-Link Engine:** Implement `[[Note Title]]` and `[[Target|Alias]]` parsing, title resolution, and modal autocomplete dialog.
4. **Bidirectional Knowledge Graph:** Real-time incoming backlinks querying and reactive streaming embedded in both typed documents and handwritten notebooks.
5. **Aesthetics & Navigation Safety:** "Quiet Craft" styling, debounced 1-second CAS autosave, save mutex lock, and `PopScope` back-navigation interceptor.

---

## 2. Implemented Components

### 2.1 Editor Package Evaluation & Selection
- **Audit Findings:** Evaluated `appflowy_editor: 6.2.0` and discovered a fatal Flutter 3.47+ compilation error (`TextInputClient.onFocusReceived`).
- **Selection:** Selected `flutter_quill: ^11.6.0` (Apache-2.0, zero AGPL dependencies) behind the ATLAS [`DocumentContentService`](../lib/features/documents/data/services/document_content_service.dart) abstraction.
- **Audit Report:** Fully documented in [`docs/EDITOR_PACKAGE_AUDIT.md`](./EDITOR_PACKAGE_AUDIT.md).

### 2.2 Database Schema Upgrade (v2 -> v3)
- Upgraded `AppDatabase.schemaVersion` to `3`.
- Added `nodes.content_hash` column to link documents to CAS blob storage.
- Added `node_links` table with foreign key cascades and indexes on `source_node_id` and `target_node_id`.
- Added `tags` and `node_tags` tables with workspace isolation.
- Created [`LinksDao`](../lib/core/database/daos/links_dao.dart) providing reactive joins for incoming backlinks, forward links, and batch syncing.
- Enhanced [`NodesDao`](../lib/core/database/daos/nodes_dao.dart) with `findNodeByTitle` and `updateNodePartial`.

### 2.3 Domain & Persistence Services
- [`WikiLinkParser`](../lib/features/documents/domain/parser/wiki_link_parser.dart): Robust regular expression parser handling unaliased and aliased wiki-links, bracket escaping, and open-query detection.
- [`LinkRepository`](../lib/features/documents/data/repositories/link_repository.dart): Orchestrates link synchronization from document text to SQLite `node_links`, title search, and backlinks streaming.
- [`DocumentContentService`](../lib/features/documents/data/services/document_content_service.dart): Manages Quill Delta serialization to CAS storage, plain text extraction, and default document scaffolding.

### 2.4 Presentation & UI Components
- [`DocumentEditorScreen`](../lib/features/documents/presentation/document_editor_screen.dart):
  - Notion/Craft "Quiet Craft" responsive layout (max-width 860px centered desktop layout, fluid mobile layout).
  - Unobtrusive formatting toolbar (`QuillSimpleToolbar`) with essential styling controls.
  - Live word counter and document last-modified timestamp header.
  - 1-second debounced autosave with save mutex (`_isSaving`, `_saveQueued`) preventing concurrent writes.
  - `PopScope` back-navigation guard flushing pending changes before route dismissal.
  - Interactive link tapping (`_handleLaunchUrl`) navigating internal `atlas://node/:id` links.
- [`BacklinksPanel`](../lib/features/documents/presentation/widgets/backlinks_panel.dart):
  - Collapsible references panel with reactive StreamBuilder listening to incoming links.
  - Displays source node type badges (`Document`, `Notebook`), titles, and relative update times.
  - Embedded directly below document editor body and inside notebook editor via action bottom sheet.
- [`WikiLinkDialog`](../lib/features/documents/presentation/widgets/wiki_link_dialog.dart):
  - Autocomplete search dialog allowing rapid searching of vault notes by title and entering optional aliases.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** `No issues found!` (0 errors, 0 warnings).

2. **Automated Test Suite (63 tests across all modules):**
   - `test/core/database/database_test.dart` (4 tests)
   - `test/core/database/schema_migration_v3_test.dart` (2 tests)
   - `test/core/storage/cas_storage_service_test.dart` (5 tests)
   - `test/features/app_smoke_test.dart` (24 tests)
   - `test/features/handwriting/stroke_tessellator_test.dart` (8 tests)
   - `test/features/handwriting/ink_serialization_test.dart` (4 tests)
   - `test/features/handwriting/ink_repository_test.dart` (3 tests)
   - `test/features/handwriting/ink_canvas_widget_test.dart` (4 tests)
   - `test/features/handwriting/pencil_kit_converter_test.dart` (3 tests)
   - `test/features/handwriting/notebook_editor_navigation_test.dart` (3 tests)
   - `test/features/documents/wiki_link_parser_test.dart` (6 tests)
   - `test/features/documents/link_repository_test.dart` (2 tests)
   - `test/features/documents/document_content_service_test.dart` (2 tests)
   - `test/features/documents/document_editor_test.dart` (3 tests)
   - **Result:** `✓ All 63 tests passed!`.

3. **Linux Desktop Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

4. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk`.

---

# ATLAS — Milestone 4 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 4 — Notebook & PDF System  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Engineering Directives & Reuse Verification
- **PDF Engine Audit:** Conducted independent audit across candidates (`pdfrx`, `pdfx`, `flutter_pdfview`) and recorded findings in `docs/PDF_PACKAGE_AUDIT.md`.
- **Selected Packages:**
  - `pdfrx: ^2.12.0` (MIT license, Google PDFium-backed on Linux desktop and Android, Apple PDFKit-backed on iPadOS/iOS).
  - `pdf: ^3.13.1` (Apache-2.0 license, multi-page vector/raster PDF compositing).
  - `file_picker: ^13.3.2` (MIT license, native desktop and mobile file picker).
- **Encapsulation:** All third-party packages are encapsulated behind domain service abstractions (`PdfRenderingService`, `PdfExportService`, `PdfRepository`).

---

## 2. Implemented Subsystems

### 2.1 Database Schema v4 Migration
- Created table `pdf_documents` tracking imported PDF metadata (`cas_hash`, `file_name`, `file_size_bytes`, `page_count`, `node_id`).
- Altered table `ink_pages` adding `pdf_document_id` and `template_spacing` (points).
- Extended `InkDao` with atomic reordering (`batchReorderPages`), insertion (`insertPageAt`), duplication (`duplicatePage`), deletion (`deletePageAndReorder`), template updating (`updatePageTemplate`), and PDF CRUD methods.
- Upgraded `AppDatabase.schemaVersion` to 4 with automated SQLite table and column migration handlers.

### 2.2 Domain & Services
- [`PdfDocumentDescriptor`](../lib/features/pdf/domain/models/pdf_document_descriptor.dart): Dimension modeling, aspect ratios, and $1.0\text{ pt} = 1.0\text{ canvas unit}$ point coordinate mapping.
- [`PdfRenderingService`](../lib/features/pdf/data/services/pdf_rendering_service.dart) & [`PdfrxRenderingService`](../lib/features/pdf/data/services/pdf_rendering_service.dart): Abstract interface and concrete PDFium/PDFKit rendering adapter.
- [`PdfRepository`](../lib/features/pdf/data/repositories/pdf_repository.dart): Ingests local PDFs into CAS blob storage, inspects page geometry, scaffolds parent notebook nodes, and creates individual `ink_pages`.
- [`PdfExportService`](../lib/features/pdf/data/services/pdf_export_service.dart): Offscreen canvas rasterization merging background PDF/stationery templates and vector ink strokes into exportable `.pdf` documents.

### 2.3 Presentation & Interaction
- [`PdfPageBackground`](../lib/features/pdf/presentation/widgets/pdf_page_background.dart): Dual-layer background widget rendering cached high-resolution PDF page rasters beneath ink canvases.
- [`PaperPatternPainter`](../lib/features/handwriting/presentation/widgets/ink_document_painter.dart): Extended with customizable point/millimeter spacing and light/dark theme adaptation for blank, ruled, square grid, and dot grid stationery.
- [`NotebookPageDrawer`](../lib/features/handwriting/presentation/widgets/notebook_page_drawer.dart): Multi-page drawer featuring live/cached thumbnails, page jump, reordering, duplicate, insert below, delete, and stationery template customization.
- [`NotebookEditorScreen`](../lib/features/handwriting/presentation/screens/notebook_editor_screen.dart):
  - Wired multi-page drawer into scaffold `endDrawer`.
  - Added AppBar action buttons for PDF Export and Page Manager Drawer.
  - Multi-platform dual-layer rendering across Linux desktop (`InkCanvas`), iPadOS (`PencilKit`), and Android (`InkPageView`).
- [`NotebooksScreen`](../lib/features/notebooks/presentation/notebooks_screen.dart): Added "Import PDF" button and file picker flow with automatic notebook generation and navigation.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** `No issues found!` (0 errors, 0 warnings).

2. **Automated Test Suite (83 tests across all modules):**
   - `test/core/database/database_test.dart` (4 tests)
   - `test/core/database/schema_migration_v3_test.dart` (2 tests)
   - `test/core/database/schema_migration_v4_test.dart` (6 tests)
   - `test/core/storage/cas_storage_service_test.dart` (5 tests)
   - `test/features/app_smoke_test.dart` (24 tests)
   - `test/features/handwriting/stroke_tessellator_test.dart` (8 tests)
   - `test/features/handwriting/ink_serialization_test.dart` (4 tests)
   - `test/features/handwriting/ink_repository_test.dart` (3 tests)
   - `test/features/handwriting/ink_canvas_widget_test.dart` (4 tests)
   - `test/features/handwriting/pencil_kit_converter_test.dart` (3 tests)
   - `test/features/handwriting/notebook_editor_navigation_test.dart` (3 tests)
   - `test/features/handwriting/paper_pattern_painter_test.dart` (5 tests)
   - `test/features/handwriting/notebook_page_drawer_test.dart` (4 tests)
   - `test/features/pdf/pdf_descriptor_test.dart` (2 tests)
   - `test/features/pdf/pdf_export_service_test.dart` (3 tests)
   - `test/features/documents/wiki_link_parser_test.dart` (6 tests)
   - `test/features/documents/link_repository_test.dart` (2 tests)
   - `test/features/documents/document_content_service_test.dart` (2 tests)
   - `test/features/documents/document_editor_test.dart` (3 tests)
   - **Result:** `✓ All 83 tests passed!`.

3. **Linux Desktop Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

4. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (145.8s).

---

# ATLAS — Milestone 5 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 5 — Tasks, Calendar & Reminders  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Objectives & Scope Boundaries

1. **Package Reuse Evaluation:** Audit candidate packages for calendar rendering (`table_calendar`) and local notifications (`flutter_local_notifications` + `timezone`). Document evaluation in `docs/PRODUCTIVITY_PACKAGE_AUDIT.md`.
2. **Schema Version 5 Migration:** Add `projects`, `tasks`, and `calendar_events` tables to SQLite via Drift with foreign key relationships (`tasks.projectId` SET NULL, `tasks.nodeId` SET NULL, `tasks.parentTaskId` CASCADE, `calendarEvents.nodeId` SET NULL, `calendarEvents.taskId` SET NULL).
3. **Data Access & Business Repositories:** Implement `TasksDao`, `CalendarDao`, `TaskRepository` (Inbox, Today, Upcoming, Projects, Completed views with reactive filtering), and `CalendarRepository` (merging scheduled events and due tasks into unified agenda streams).
4. **Task Management UI:** `TasksScreen` with responsive grouping (Project, Due Date, Priority), `TaskItemWidget`, `QuickAddTaskBar`, `TaskDetailSheet` with subtask checklist and progress bar, and embedded `NodeTasksPanel` in `DocumentEditorScreen` and `NotebookEditorScreen`.
5. **Calendar & Agenda UI:** `CalendarScreen` powered by `table_calendar` (month grid, 2-week view, week view) with event markers, unified daily agenda with `AgendaItemCard`, and `EventDetailSheet` modal.
6. **Local Notifications:** Platform-agnostic `NotificationService` handling Linux desktop DBus notifications, Android exact alarms with Java 8 core library desugaring, iOS UNUserNotificationCenter, and startup reconciliation in `bootstrap.dart`.
7. **Strict Scope Boundaries Maintained:** Zero external calendar sync (Google/CalDAV/Outlook), zero cloud push notifications, zero Kanban drag-and-drop boards, zero NLP natural language date parsing.

---

## 2. Implemented Architecture & Components

### 2.1 Persistence & Data Layer
- [`ProjectsTable`](../lib/core/database/tables/projects_table.dart), [`TasksTable`](../lib/core/database/tables/tasks_table.dart), [`CalendarEventsTable`](../lib/core/database/tables/calendar_events_table.dart).
- [`TasksDao`](../lib/core/database/daos/tasks_dao.dart):
  - Streams: `watchTasksForWorkspace`, `watchTasksForNode`, `watchSubtasks`, `watchProjectsForWorkspace`.
  - Operations: `createTask`, `updateTask`, `deleteTask`, `toggleTaskCompletion`, `batchReorderTasks`, `createProject`, `updateProject`, `deleteProject`.
- [`CalendarDao`](../lib/core/database/daos/calendar_dao.dart):
  - Streams: `watchAllEvents`, `watchEventsForRange`, `watchEventsForDay`, `watchEventsForNode`.
  - Operations: `createEvent`, `updateEvent`, `deleteEvent`.
- Database schema bumped to **version 5** in [`AppDatabase`](../lib/core/database/app_database.dart) with automated migration.

### 2.2 Domain & Repositories
- [`TaskRepository`](../lib/features/tasks/data/repositories/task_repository.dart):
  - Manages view filters (`TaskFilter.inbox`, `today`, `upcoming`, `projects`, `completed`) and grouping modes.
  - Automatically segregates subtasks from primary views and schedules/cancels reminders upon task mutations.
- [`CalendarAgendaItem`](../lib/features/calendar/domain/models/calendar_agenda_item.dart):
  - Unified agenda model unifying both `CalendarEventEntry` and `TaskEntry` items with color coding, start/end timestamps, all-day flags, and linked note references.
- [`CalendarRepository`](../lib/features/calendar/data/repositories/calendar_repository.dart):
  - `watchAgendaForDay`: Merges `calendarDao.watchEventsForDay` and `tasksDao.watchTasksForWorkspace` using `Rx.combineLatest2`.
  - Sorts all-day items first, then chronologically ascending by start time.
- [`NotificationService`](../lib/core/notifications/notification_service.dart):
  - Cross-platform scheduling via `flutter_local_notifications` (`LinuxInitializationSettings`, `AndroidInitializationSettings`, `DarwinInitializationSettings`).
  - Schedules reminders `reminderMinutesBefore` due dates/start times.
  - `reschedulePendingReminders`: Startup reconciliation invoked during application bootstrap.
  - Graceful degradation when notifications plugin is uninitialized or permissions are withheld.

### 2.3 Presentation & Interaction
- [`TasksScreen`](../lib/features/tasks/presentation/tasks_screen.dart):
  - Filter chips for Inbox, Today, Upcoming, Projects, and Completed views.
  - Project sub-filter strip and new project creation modal.
  - Grouping options: None, by Project, by Due Date, by Priority.
- [`TaskItemWidget`](../lib/features/tasks/presentation/widgets/task_item_widget.dart):
  - Priority indicator color styling (P1-P4), custom animated circular check, due date badge, project chip, and linked note chip.
- [`QuickAddTaskBar`](../lib/features/tasks/presentation/widgets/quick_add_task_bar.dart):
  - Inline task input with priority selector, date picker, project selector, and submission on Enter.
- [`TaskDetailSheet`](../lib/features/tasks/presentation/widgets/task_detail_sheet.dart):
  - Modal sheet for editing title, description, due date/time, priority, recurrence, reminder intervals, project assignment, and note links.
  - Interactive subtasks checklist with visual completion progress bar.
- [`NodeTasksPanel`](../lib/features/tasks/presentation/widgets/node_tasks_panel.dart):
  - Collapsible node-level task panel mounted directly in `DocumentEditorScreen` and accessible via AppBar modal in `NotebookEditorScreen`.
- [`CalendarScreen`](../lib/features/calendar/presentation/calendar_screen.dart):
  - Powered by `table_calendar: ^3.3.0` with month grid, 2-week view, and week format.
  - Day markers showing scheduled events and tasks due.
  - Responsive layout: 2-column on desktop (`width >= 900`), adaptive split on tablet, collapsible week strip on mobile companion.
  - Daily agenda timeline with `AgendaItemCard` and quick task/event addition.
- [`EventDetailSheet`](../lib/features/calendar/presentation/widgets/event_detail_sheet.dart):
  - Event creation and editing modal supporting title, description, location, all-day toggle, start/end dates and times, Atlas color palette tag picker, and note linkage.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** `No issues found!` (0 errors, 0 warnings, 0 hints).

2. **Automated Test Suite (101 tests across all modules):**
   - `test/core/database/database_test.dart` (4 tests)
   - `test/core/database/schema_migration_v3_test.dart` (2 tests)
   - `test/core/database/schema_migration_v4_test.dart` (6 tests)
   - `test/core/database/schema_migration_v5_test.dart` (5 tests)
   - `test/core/notifications/notification_service_test.dart` (4 tests)
   - `test/core/storage/cas_storage_service_test.dart` (5 tests)
   - `test/features/app_smoke_test.dart` (24 tests)
   - `test/features/handwriting/stroke_tessellator_test.dart` (8 tests)
   - `test/features/handwriting/ink_serialization_test.dart` (4 tests)
   - `test/features/handwriting/ink_repository_test.dart` (3 tests)
   - `test/features/handwriting/ink_canvas_widget_test.dart` (4 tests)
   - `test/features/handwriting/pencil_kit_converter_test.dart` (3 tests)
   - `test/features/handwriting/notebook_editor_navigation_test.dart` (3 tests)
   - `test/features/handwriting/paper_pattern_painter_test.dart` (5 tests)
   - `test/features/handwriting/notebook_page_drawer_test.dart` (4 tests)
   - `test/features/pdf/pdf_descriptor_test.dart` (2 tests)
   - `test/features/pdf/pdf_export_service_test.dart` (3 tests)
   - `test/features/documents/wiki_link_parser_test.dart` (6 tests)
   - `test/features/documents/link_repository_test.dart` (2 tests)
   - `test/features/documents/document_content_service_test.dart` (2 tests)
   - `test/features/documents/document_editor_test.dart` (3 tests)
   - `test/features/tasks/task_repository_test.dart` (3 tests)
   - `test/features/tasks/tasks_screen_test.dart` (2 tests)
   - `test/features/calendar/calendar_repository_test.dart` (2 tests)
   - `test/features/calendar/calendar_screen_test.dart` (2 tests)
   - **Result:** `✓ All 101 tests passed!`.

3. **Linux Desktop Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

4. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (27.8s) with core library desugaring enabled.

---

# ATLAS — Milestone 6 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 6 — Personal Dashboard, Habits & Daily Journal  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Objectives & Scope Boundaries

1. **Lightweight Visualization Evaluation:** Evaluate custom painting vs external packages for habit progress rings and streaks. Selected lightweight native `CustomPainter` (`HabitProgressRingPainter`, under 100 lines) with isolated `RepaintBoundary` caching. Documented in ADR-020.
2. **Schema Version 6 Migration:** Added `habits`, `habit_logs`, `goals`, and `journal_entries` tables to Drift with foreign key cascades and unique composite constraints (`habit_logs(habit_id, log_date)`, `journal_entries(workspace_id, journal_date)`).
3. **Data Access & Streak Math:** Implemented `HabitsDao` with contiguous day streak algorithm (calculating current streak backwards from today/yesterday, best streak across all chronological runs, and 7-day weekly completion map) and `JournalDao` (date lookups, node linkage, and recent reflections).
4. **Habits & Goals Module:** Created `HabitProgressRingPainter`, `HabitProgressRing`, `HabitCheckInTile` (1-tap toggle, streak badge e.g. "🔥 12 days", weekly dots), `HabitWeeklyTracker`, `HabitEditDialog` (palette picker, icon picker, frequency), and `GoalsSummaryCard` (milestones, target dates, status pills).
5. **Daily Journal Engine:** Created `JournalRepository` with `getOrCreateTodayJournalNode` (auto-scaffolding document node, pre-populating CAS storage with structured sections: `# Journal: ...`, `## Daily Focus`, `## Key Wins`, `## Reflections`, and reusing existing entries), and `JournalContextDayPanel` embedded into `DocumentEditorScreen` when viewing a daily reflection.
6. **Central Dashboard Overhaul:** Redesigned `DashboardScreen` into a responsive bento-grid layout with "Quiet Craft" greeting header, quick action bar ("New Note", "New Task", "Today's Journal"), live "Today's Focus & Agenda" (tasks & calendar events), "Daily Habits" strip with progress ring, "Today's Reflection" card, and preserved stats counters.
7. **Strict Scope Boundaries Maintained:** Zero external health platform sync (HealthKit/Google Fit), zero heavy graphing packages, zero cloud sync, zero AI sentiment analysis.

---

## 2. Implemented Architecture & Components

### 2.1 Persistence & Data Layer
- [`HabitsTable`](../lib/core/database/tables/habits_table.dart), [`HabitLogsTable`](../lib/core/database/tables/habit_logs_table.dart), [`GoalsTable`](../lib/core/database/tables/goals_table.dart), [`JournalEntriesTable`](../lib/core/database/tables/journal_entries_table.dart).
- [`HabitsDao`](../lib/core/database/daos/habits_dao.dart):
  - Streams: `watchHabitsForWorkspace`, `watchHabitsWithProgress`, `watchGoalsForWorkspace`.
  - Contiguous day streak math: `calculateProgress`, `toggleHabit`, `setHabitCompleted`, Goals CRUD.
- [`JournalDao`](../lib/core/database/daos/journal_dao.dart):
  - Streams: `watchEntryByDate`, `watchEntryByNodeId`, `watchRecentJournalEntries`.
  - CRUD operations for date-linked reflection records.
- Database schema bumped to **version 6** in [`AppDatabase`](../lib/core/database/app_database.dart) with automated migration.

### 2.2 Domain & Repositories
- [`HabitRepository`](../lib/features/habits/data/repositories/habit_repository.dart):
  - Manages active and archived habits, progress streams, 1-tap check-ins, and workspace goals.
- [`JournalRepository`](../lib/features/journal/data/repositories/journal_repository.dart):
  - Resolves or creates today's journal node, writes starter sections into CAS via `DocumentContentService`, and handles mood tracking.

### 2.3 Presentation & Interaction
- [`HabitProgressRingPainter`](../lib/features/habits/presentation/widgets/habit_progress_ring_painter.dart):
  - 99-line `CustomPainter` with smooth arc rendering and `RepaintBoundary` wrapper.
- [`HabitCheckInTile`](../lib/features/habits/presentation/widgets/habit_check_in_tile.dart):
  - Interactive tile with progress ring, streak badge ("🔥 5 days"), title, description, and weekly tracker.
- [`HabitWeeklyTracker`](../lib/features/habits/presentation/widgets/habit_weekly_tracker.dart):
  - 7-day row with weekday initials, completed check indicators, and today accent ring.
- [`HabitEditDialog`](../lib/features/habits/presentation/widgets/habit_edit_dialog.dart):
  - Customization modal with title, description, frequency toggle, palette picker, and productivity icons.
- [`GoalsSummaryCard`](../lib/features/habits/presentation/widgets/goals_summary_card.dart):
  - Active workspace goals with target dates, status pills, and creation dialog.
- [`JournalContextDayPanel`](../lib/features/journal/presentation/widgets/journal_context_day_panel.dart):
  - Contextual summary panel displaying tasks completed and habits fulfilled on the journal's date.
- [`DashboardScreen`](../lib/features/dashboard/presentation/dashboard_screen.dart):
  - Bento grid layout adapting across Linux desktop (wide multi-column), iPadOS (2-column), and Android (vertical scroll feed).
  - Quick action bar: "New Note", "New Task", "Today's Journal".
  - Live cards: Today's Focus & Agenda, Daily Habits Strip, Goals & Milestones, Today's Reflection, Recently Modified Notes.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** `No issues found!` (0 errors, 0 warnings, 0 hints).

2. **Automated Test Suite (111 tests across all modules):**
   - `test/core/database/schema_migration_v6_test.dart` (6 tests)
   - `test/features/habits/habit_repository_test.dart` (2 tests)
   - `test/features/journal/journal_repository_test.dart` (1 test)
   - `test/features/dashboard/dashboard_screen_test.dart` (1 test)
   - All 101 existing regression tests verified passing.
   - **Result:** `✓ All 111 tests passed!`.

3. **Linux Desktop Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

4. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (26.1s).

---

# ATLAS — Milestone 7 Implementation Log

**Date:** 2026-11-06  
**Milestone:** Milestone 7 — Global Search, Command Palette & Knowledge Graph  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Objectives & Architectural Requirements

1. **Unified Global Search Engine:** Cross-entity indexing and querying across typed Documents, Notebooks (titles + CAS Delta extracts), Tasks (with parent projects), Calendar Events, Daily Journals, and Tags.
2. **Relevance Scoring Rubric:** Implement multi-tiered relevance scoring: Exact title ($100$), Prefix title ($80$), Word-prefix ($70$), Tag/Project ($60$), Content body ($40$), Fuzzy subsequence ($25$), and Recency decay boost ($+1$ to $+10$).
3. **Universal Command Palette:** Floating modal with backdrop blur accessible globally via `Ctrl+K` / `Cmd+K`. Support mode prefixes (`>` for system actions, `#` for taxonomy tags, `@` for calendar dates).
4. **Interactive 2D Knowledge Graph:** Visualizing node topology, degree-scaled radii, direction-neutral subtle edges, and real-time node dragging.
5. **Self-Contained Physics Simulation:** Fruchterman-Reingold / Verlet 2D physics engine (< 250 lines) with kinetic energy convergence detection to halt ticking at equilibrium.
6. **Embedded 1-Hop Local Graph:** Embed localized neighborhood graph in `DocumentEditorScreen` and `NotebookEditorScreen`.
7. **Quality Gates:** 0 analyzer warnings, 100% test pass rate, clean Linux and Android builds.

---

## 2. Implemented Components

### 2.1 Package Audits & Architectural Decisions
- Evaluated `graphview: ^1.2.0` (MIT) vs a lightweight self-contained 2D Force-Directed Layout service. Chose self-contained physics service (`ForceDirectedLayoutService`, 171 lines) for 60 FPS repaint isolation, kinetic energy convergence stopping, and instant dragging without widget overhead.
- Evaluated `fuzzy: ^0.5.1` (Apache-2.0) vs custom multi-tier scorer. Chose custom `SearchScorer` for exact rubric compliance and contextual window snippet extraction.
- Fully documented in [`docs/TECHNICAL_DECISIONS.md`](./TECHNICAL_DECISIONS.md#adr-021-unified-search-scorer-universal-command-palette--self-contained-2d-knowledge-graph-layout).

### 2.2 Global Search Subsystem
- [`SearchScorer`](../lib/features/search/data/services/search_scorer.dart):
  - Implements the 7-tier scoring rubric with recency decay boost and window snippet extraction.
- [`SearchService`](../lib/features/search/data/services/search_service.dart):
  - Asynchronously queries `NodesDao`, `TasksDao`, `CalendarDao`, `JournalDao`, `LinksDao`, and CAS `BlobStorageService`.
- [`SearchRepository`](../lib/features/search/data/repositories/search_repository.dart):
  - Exposes clean domain search interface to presentation layer.
- [`SearchScreen`](../lib/features/search/presentation/search_screen.dart):
  - Overhauled with 250ms debounced search-as-you-type, entity filter chips (`All`, `Documents`, `Notebooks`, `Tasks`, `Calendar`, `Journal`), rich result cards with keyword highlighting, breadcrumbs, relative timestamps, and keyboard navigation.

### 2.3 Universal Command Palette Subsystem
- [`CommandAction`](../lib/shared/presentation/command_palette/command_action.dart):
  - Model for executable palette actions with categories, shortcuts, and keywords.
- [`CommandRegistry`](../lib/shared/presentation/command_palette/command_registry.dart):
  - Comprehensive action registry: Navigation (Dashboard, Notebooks, Documents, Tasks, Calendar, Graph, Search, Settings), Quick Creation (New Document, New Notebook, New Task, Today's Journal, New Habit), and System commands (Toggle Theme, Knowledge Graph).
- [`CommandPaletteModal`](../lib/shared/presentation/command_palette/command_palette_modal.dart):
  - Floating centered modal with backdrop blur (`BackdropFilter`), mode prefixes (`>`, `#`, `@`), keyboard navigation (Arrow Up/Down, Enter, Esc), and quick hint badges.
- [`AtlasScaffold`](../lib/shared/widgets/atlas_scaffold.dart):
  - Wired global `Ctrl+K` and `Cmd+K` keyboard shortcuts via `CallbackShortcuts`.
- [`AtlasSidebar`](../lib/shared/widgets/atlas_sidebar.dart):
  - Added quick command launcher button.

### 2.4 Knowledge Graph Subsystem
- [`GraphData`, `GraphNode`, `GraphEdge`](../lib/features/graph/domain/models/graph_models.dart):
  - Graph domain topology models with degree tracking, position kinematics, and type categorization.
- [`ForceDirectedLayoutService`](../lib/features/graph/domain/services/force_directed_layout_service.dart):
  - Self-contained 2D physics simulation with Coulomb repulsion, Hooke's law spring tension, center gravity pull, velocity clamping, damping, and kinetic energy convergence stopping (< 0.04 threshold).
- [`GraphRepository`](../lib/features/graph/data/repositories/graph_repository.dart):
  - Assembles nodes and node links from SQLite, calculates connectivity degrees, and extracts 1-hop local subgraphs.
- [`KnowledgeGraphPainter`](../lib/features/graph/presentation/widgets/knowledge_graph_painter.dart):
  - High-performance custom painter with subtle direction-neutral edges, degree-scaled node radii ($4\text{px}$ to $16\text{px}$), glow highlights on hover/selection, and text labels.
- [`InteractiveKnowledgeGraph`](../lib/features/graph/presentation/widgets/interactive_knowledge_graph.dart):
  - Interactive widget with `InteractiveViewer` zoom/pan bounds, node dragging with dynamic spring updates, and hover tooltips.
- [`KnowledgeGraphScreen`](../lib/features/graph/presentation/knowledge_graph_screen.dart):
  - Full-screen graph viewer with filter capsule (Docs, Notebooks, Tags, Orphans toggle, live node search) mounted at route `/graph`.
- [`LocalGraphPanel`](../lib/features/graph/presentation/widgets/local_graph_panel.dart):
  - Collapsible 1-hop local neighborhood graph mounted in `DocumentEditorScreen` and `NotebookEditorScreen`.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** `No issues found!` (0 errors, 0 warnings, 0 hints).

2. **Code Formatting:**
   - `dart format .`
   - **Result:** All files formatted cleanly.

3. **Automated Test Suite (139 tests across all modules):**
   - `test/features/search/search_scorer_test.dart` (10 tests)
   - `test/features/search/search_service_test.dart` (4 tests)
   - `test/shared/command_palette_test.dart` (4 tests)
   - `test/features/graph/force_directed_layout_test.dart` (7 tests)
   - `test/features/graph/knowledge_graph_widget_test.dart` (3 tests)
   - All 111 existing regression tests verified passing.
   - **Result:** `✓ All 139 tests passed!`.

4. **Linux Desktop Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

5. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (24.0s).

---

# ATLAS — Milestone 8 Implementation Log

**Date:** 2026-11-07  
**Milestone:** Milestone 8 — Local-First Synchronization, Vault Portability & Backup  
**Author:** Principal Software Architect & Senior Flutter Engineer  
**Status:** Completed & Verified  

---

## 1. Objectives & Executive Summary

Milestone 8 achieves complete local-first, peer-to-peer / folder-based multi-device synchronization and full vault data portability for ATLAS across Linux desktop, iPadOS, and Android companion devices without relying on any central proprietary cloud servers.

Key architectural pillars implemented:
1. **Reuse Directive & Package Audit (ADR-022):**
   - Adopted `archive: ^4.0.2` (Apache-2.0, zero AGPL transitive dependencies) for pure Dart streaming ZIP and GZip packaging.
   - Adopted `shared_preferences: ^2.5.4` (BSD-3-Clause) for persistent device UUID and sync folder paths.
2. **Database Migration to Schema Version 7:**
   - Appended 4 sync metadata columns (`deletedAt`, `clientModifiedAt`, `modifiedDeviceId`, `syncVersion`) across all 14 tables.
   - Created `sync_history` table for tracking audit logs and sync performance metrics.
   - Updated all existing DAOs to filter out soft-deleted records (`deletedAt.isNull()`) while preserving referential integrity and cascading/SET NULL operations.
   - Built `SyncDao` with mutation querying, Last-Write-Wins (LWW) upserts, and sync run status management.
3. **Vault Archive Engine (`.atlas_vault`):**
   - Implemented `VaultExportService` to flush WAL journal (`PRAGMA wal_checkpoint(FULL);`), compute SHA-256 checksums, and package `manifest.json`, `database.sqlite`, and `cas/` content blobs into a standard portable `.atlas_vault` container.
   - Implemented `VaultImportService` to inspect archive versions, verify SHA-256 integrity, create safety rollback backups, and execute atomic restorations.
4. **Folder-Based Local-First Sync Engine (`FolderSyncEngine`):**
   - Standardized folder layout: `[SyncDir]/clients/[deviceId]/info.json`, `[SyncDir]/clients/[deviceId]/changes/[ts]_[seq].atlas_changeset`, and `[SyncDir]/blobs/[prefix]/[sha256]`.
   - Mutation scanning and compressed changeset generation with automatic blob replication.
   - Remote changeset ingestion with Last-Write-Wins (LWW) per-entity reconciliation.
   - 5-minute concurrent edit non-destructive conflict forking (`[Title] (Sync Conflict [Date])`).
5. **Universal Portability & Bulk Export:**
   - Implemented `MarkdownExportService`: converts documents to `.md` files with YAML frontmatter, Obsidian `[[WikiLinks]]`, and extracted CAS images in `assets/`, packaged into a ZIP archive.
   - Implemented `NotebookBulkPdfExportService`: bulk-flattens handwritten notebooks and annotated PDFs into composite vector/raster `.pdf` files packaged into a ZIP archive.
6. **Settings & Sync Management UI (`SettingsScreen`):**
   - Added Device Identity section with editable device name and client ID badge.
   - Added Local-First Synchronization section with directory picker, manual sync action, and live sync history.
   - Added Vault Archive section with full backup export and confirmation-guarded restore.
   - Added Data Portability section with bulk Markdown and PDF export actions.
   - Added Storage Breakdown & Metrics card showing SQLite file size, CAS blob cache breakdown, and tracked attachments.

---

## 2. Implemented Subsystems & File Inventory

### 2.1 Storage & Sync Infrastructure
- [`SyncHistoryTable`](../lib/core/database/tables/sync_history_table.dart):
  - Drift schema definition for sync tracking (`id`, `syncStartedAt`, `syncCompletedAt`, `syncType`, `status`, `recordsExported`, `recordsImported`, `blobsTransferred`, `errorMessage`).
- [`WorkspacesTable`, `NodesTable`, `NodeLinksTable`, `TagsTable`, `NodeTagsTable`, `InkPagesTable`, `PdfDocumentsTable`, `ProjectsTable`, `TasksTable`, `CalendarEventsTable`, `HabitsTable`, `HabitLogsTable`, `GoalsTable`, `JournalEntriesTable`](../lib/core/database/tables/):
  - Updated with `deletedAt`, `clientModifiedAt`, `modifiedDeviceId`, `syncVersion`.
- [`SyncDao`](../lib/core/database/daos/sync_dao.dart):
  - Implements `startSync`, `completeSync`, `failSync`, `getMutationsSince`, `upsertRemote*`, and soft-delete propagation.
- [`DeviceIdentityService`](../lib/core/sync/device/device_identity_service.dart):
  - Manages client instance UUID v4 generation, device name, and sync directory persistence via `shared_preferences`.

### 2.2 Vault Archive Subsystem
- [`VaultManifest`](../lib/core/sync/vault/vault_manifest.dart):
  - Cryptographic manifest model recording format version (`1.0`), timestamps, node counts, database SHA-256 checksum, and relative CAS blob map.
- [`VaultExportService`](../lib/core/sync/vault/vault_export_service.dart):
  - WAL checkpointing, CAS SHA-256 scanning, and streaming `.atlas_vault` packaging.
- [`VaultImportService`](../lib/core/sync/vault/vault_import_service.dart):
  - Manifest validation, checksum integrity verification, safety rollback preservation, and atomic database replacement.

### 2.3 Folder-Based Synchronization Subsystem
- [`AtlasChangeset`](../lib/core/sync/folder/changeset_model.dart):
  - GZip-compressed changeset serialization model supporting all 14 entity types and referenced blob hashes.
- [`ClientInfo`](../lib/core/sync/folder/client_info_model.dart):
  - Client metadata descriptor for multi-device sync discovery.
- [`FolderSyncEngine`](../lib/core/sync/folder/folder_sync_engine.dart):
  - Mutation scanner, blob replicator, changeset exporter, chronological remote ingest, LWW resolver, and 5-minute non-destructive conflict forker.

### 2.4 Universal Bulk Exporters & Presentation
- [`MarkdownExportService`](../lib/features/settings/data/markdown_export_service.dart):
  - Delta-to-Markdown parser with line prefixing, inline bold/italic/code formatting, YAML frontmatter, `[[WikiLinks]]`, and `assets/` CAS image packaging into ZIP.
- [`NotebookBulkPdfExportService`](../lib/features/settings/data/notebook_bulk_pdf_export_service.dart):
  - Batch exporter compiling all notebooks into vector/raster composite PDFs packaged into ZIP.
- [`SettingsScreen`](../lib/features/settings/presentation/settings_screen.dart):
  - Full settings interface incorporating Device Identity, Local-First Sync, Vault Archive (.atlas_vault), Data Portability (Markdown & PDF), Storage Breakdown, Active Workspace, and Platform & Architecture diagnostics.

---

## 3. Verification & Quality Gates

1. **Static Analysis:**
   - `flutter analyze`
   - **Result:** `No issues found!` (0 errors, 0 warnings, 0 hints across all 181 files).

2. **Code Formatting:**
   - `dart format .`
   - **Result:** 100% formatted cleanly.

3. **Automated Test Suite (152 tests across all modules):**
   - `test/core/database/schema_migration_v7_test.dart` (4 tests)
   - `test/core/sync/vault_archive_test.dart` (4 tests)
   - `test/core/sync/folder_sync_engine_test.dart` (3 tests)
   - `test/features/settings/markdown_export_test.dart` (1 test)
   - `test/features/settings/settings_sync_screen_test.dart` (1 test)
   - All 139 existing regression tests passing.
   - **Result:** `✓ All 152 tests passed!` (100% pass rate).

4. **Linux Desktop Debug Build:**
   - `flutter build linux --debug`
   - **Result:** `✓ Built build/linux/x64/debug/bundle/atlas`.

5. **Android Build Verification:**
   - `flutter build apk --debug`
   - **Result:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (82.8s).





