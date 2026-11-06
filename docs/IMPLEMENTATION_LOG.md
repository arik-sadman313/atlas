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
