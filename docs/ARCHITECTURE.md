# ATLAS — Architectural Specification

## 1. Architectural Philosophy & Principles

ATLAS is architected as a **Local-First, Modular, Feature-First** application built on Flutter and Dart.

```mermaid
flowchart TD
    subgraph UI_Layer [Presentation Layer]
        Widgets[Flutter Widgets & Screens]
        Controllers[Riverpod Notifiers / StateNotifier]
        DesignSystem[Atlas Design System & Theme]
    end

    subgraph Domain_Layer [Domain Layer - Pure Dart]
        Entities[Entities & Value Objects (Freezed)]
        UseCases[Use Cases & Domain Services]
        RepoInterfaces[Repository Interfaces]
        InkMath[Ink Math & Spline Tessellator]
    end

    subgraph Data_Layer [Data Layer]
        RepoImpl[Repository Implementations]
        DriftDB[Drift ORM Database (SQLite)]
        FTS5Engine[SQLite FTS5 Full-Text Search]
        CASStorage[File-System CAS Storage (Blobs/Ink/PDF)]
        PlatformAdapters[Platform Channel Adapters]
    end

    subgraph Platform_Layer [Platform Specific Services]
        PencilKitBridge[iPadOS PencilKit Native Bridge (Swift)]
        LinuxPlatform[Linux GTK / Native Integrations]
        AndroidPlatform[Android Native File & Notification Services]
    end

    Widgets --> Controllers
    Controllers --> UseCases
    UseCases --> RepoInterfaces
    RepoInterfaces <|.. RepoImpl
    RepoImpl --> DriftDB
    RepoImpl --> FTS5Engine
    RepoImpl --> CASStorage
    RepoImpl --> PlatformAdapters
    PlatformAdapters --> PencilKitBridge
    PlatformAdapters --> LinuxPlatform
    PlatformAdapters --> AndroidPlatform
```

### Core Tenets
1. **Local-First Source of Truth:** All user data, metadata, relations, and settings reside in a local SQLite database (`atlas.db`) and local filesystem storage. The app is fully functional without internet access.
2. **Feature-First Modularity:** Code is organized by domain features (`features/handwriting`, `features/notes`, `features/tasks`, etc.) rather than technical layers (`widgets/`, `models/`).
3. **Strict Layer Separation:**
   - **Presentation Layer:** Pure Flutter UI. Observes Riverpod providers. Emits user actions to controllers. No direct database or file system calls.
   - **Domain Layer:** Pure Dart. Zero Flutter UI dependencies. Houses core entities, value objects, business logic, ink math calculations, and repository contracts. Highly unit-testable.
   - **Data Layer:** Implements repository contracts. Coordinates Drift SQLite queries, SQLite FTS5 index updates, and filesystem I/O.
4. **Content-Addressable Storage (CAS) for Heavy Blobs:** Binary ink drawings, high-resolution PNG previews, and imported PDF attachments are stored in a managed local directory addressed by their SHA-256 hash. The SQLite database stores only the hash references, file paths, and relational metadata.
5. **Platform Independence Behind Interfaces:** Platform-specific APIs (such as iOS PencilKit) are strictly encapsulated behind abstract Dart interfaces (`InkPlatformService`).

---

## 2. Directory & Package Structure

```
lib/
├── app.dart                        # Root MaterialApp & router initialization
├── main.dart                       # Entry point, dependency initialization
├── core/                           # Shared infrastructure across features
│   ├── constants/                  # App constants, defaults, limits
│   ├── database/                   # Drift database definition, tables, DAOs
│   │   ├── app_database.dart       # Drift database class
│   │   ├── app_database.g.dart     # Generated Drift code
│   │   ├── connection/             # Native SQLite connection setup (Linux/iOS/Android)
│   │   ├── daos/                   # Feature-specific Data Access Objects
│   │   └── tables/                 # Table definitions
│   ├── errors/                     # Failure types, exceptions, error handlers
│   ├── router/                     # go_router configuration, route definitions
│   ├── storage/                    # Content-Addressable Storage (CAS) manager
│   ├── sync/                       # Sync log, change vector models, HLC
│   └── theme/                      # Atlas Design System tokens, typography, colors
├── features/                       # Feature-first modular packages
│   ├── dashboard/                  # Dashboard widgets, agenda, quick notes
│   ├── document/                   # Rich-text block editor (AppFlowy Editor wrapper)
│   ├── graph/                      # Knowledge graph visualization & backlink resolution
│   ├── habits/                     # Habit tracking, logs, streaks
│   ├── handwriting/                # Ink engine, canvas, stroke smoothing, PencilKit bridge
│   │   ├── domain/                 # Ink models, stroke points, spline algorithms
│   │   ├── data/                   # Ink document serializer, file persistence
│   │   └── presentation/           # Canvas widgets, tool palettes, native platform view
│   ├── notebooks/                  # Notebook hierarchy, chapters, pages, templates
│   ├── pdf/                        # PDF viewing (pdfrx) and ink annotation overlay
│   ├── search/                     # FTS5 search queries, command palette
│   └── tasks/                      # Tasks, projects, reminders, calendar views
└── platform/                       # Native platform channels & plugin bridges
    ├── ios/                        # iOS-specific method channels & view factories
    ├── linux/                      # Linux-specific integrations
    └── android/                    # Android-specific integrations
```

---

## 3. State Management & Unidirectional Data Flow

ATLAS uses **Riverpod** with code generation (`riverpod_annotation`, `riverpod_generator`).

```mermaid
sequenceDiagram
    participant User
    participant Widget as Flutter View (ConsumerWidget)
    participant Controller as Riverpod Notifier (@riverpod)
    participant Repo as Repository Implementation
    participant DB as Drift (SQLite) & CAS
    participant Stream as Reactive Stream (Drift Watcher)

    User->>Widget: Interacts (e.g., completes a task)
    Widget->>Controller: Invokes toggleTaskCompletion(id)
    Controller->>Repo: Calls updateTask(task)
    Repo->>DB: Executes UPDATE tasks SET completed = 1
    DB-->>Stream: Drift reactive table trigger fires
    Stream-->>Controller: Emits updated List<Task>
    Controller-->>Widget: Notifier updates state; Widget rebuilds
```

### State Layer Conventions:
- **`AsyncNotifier<T>`:** Used for all asynchronous business operations that load, mutate, or fetch data.
- **Provider Scoping:** View-specific states (e.g., active zoom level, current tool selection) use local auto-dispose providers.
- **Drift Reactive Watchers:** Drift `watch()` streams are directly mapped to Riverpod `StreamProvider` or integrated into `AsyncNotifier` subscriptions, guaranteeing zero desynchronization between database state and UI.

---

## 4. Platform Abstraction & Handwriting Engine Architecture

Handwriting requires radically different execution models across target platforms:

```mermaid
flowchart TD
    subgraph UI_Surface [Presentation Layer]
        CanvasContainer[Handwriting Canvas Container]
    end

    subgraph Decision [Platform Switcher]
        PlatformCheck{Platform.isIOS?}
    end

    subgraph iPadOS_Native [iPadOS Native Pipeline]
        PencilKitWidget[UIKitView / PKCanvasView]
        PencilKitController[Native Swift PKCanvasController]
        ApplePencil[Apple Pencil / Metal Hardware Pipeline]
    end

    subgraph Portable_Dart [Linux & Android Portable Engine]
        DartCanvas[CustomPaint / RepaintBoundary]
        Tessellator[Spline Tessellator & Path Cache]
        InputController[Pointer / Tablet Event Listener]
    end

    subgraph Data_Sink [Common Data Representation]
        PIFSerializer[Atlas Portable Ink Format Serializer]
        CASStorageSink[CAS Blob Storage .atlas_ink / .pkdrawing / .png]
    end

    CanvasContainer --> Decision
    Decision -- Yes --> PencilKitWidget
    PencilKitWidget --> PencilKitController
    PencilKitController --> ApplePencil
    PencilKitController -- On Save / Export --> PIFSerializer

    Decision -- No --> DartCanvas
    DartCanvas --> Tessellator
    InputController --> Tessellator
    Tessellator -- On Save (Linux edit) --> PIFSerializer

    PIFSerializer --> CASStorageSink
```

### Interface Definition (`InkPlatformService`)
```dart
abstract class InkPlatformService {
  /// Whether native hardware acceleration (PencilKit) is available
  bool get hasNativeHardwareSupport;

  /// Loads an ink page into the active platform drawing context
  Future<void> loadDrawing({
    required String pageId,
    required String? rawPencilKitBlobPath,
    required String portableInkBlobPath,
  });

  /// Exports the current canvas state into native, portable, and preview formats
  Future<InkExportResult> exportDrawing({
    required String pageId,
    required double scale,
  });

  /// Dispatches tool changes (pen, highlighter, eraser, width, color)
  Future<void> setTool(InkToolConfig tool);

  /// Performs undo/redo operations
  Future<void> undo();
  Future<void> redo();
}
```

---

## 5. Storage Subsystem & Content-Addressable Storage (CAS)

To guarantee that SQLite database size remains compact and performance does not degrade when storing thousands of high-resolution drawings and PDFs:

1. **Relational Data (SQLite):**
   - Stored in `~/.local/share/atlas/atlas.db` (Linux), `ApplicationDocumentsDirectory/atlas.db` (iOS/Android).
   - Only stores string metadata, relational links, titles, tags, tasks, and file hashes.
2. **Binary Blobs (CAS Store):**
   - Stored in `.../atlas/blobs/ab/cd/abcdef123456...`.
   - Files are partitioned using the first two characters of their SHA-256 hash to prevent directory traversal performance hits.
   - De-duplication: Identical attachments or template backgrounds share the same physical storage file.

---

## 6. Synchronization Strategy (Future-Ready Architecture)

While cloud infrastructure is deferred to future milestones, ATLAS implements a **Sync-Ready Foundation** from day one:

```mermaid
erDiagram
    SYNC_LOG {
        INTEGER id PK
        TEXT entity_type "node | task | ink_page | project"
        TEXT entity_id "UUIDv4"
        TEXT operation "INSERT | UPDATE | DELETE"
        INTEGER hlc_logical_time
        TEXT hlc_node_id "Unique device GUID"
        TEXT payload_json "Serialized mutation diff"
        TEXT state_hash "SHA-256 of resulting entity"
        INTEGER created_at "Unix epoch millis"
    }
```

### Sync Principles:
- **Hybrid Logical Clocks (HLC):** Replaces physical wall-clock timestamps for conflict ordering. HLC provides causality tracking across offline devices without time-drift anomalies.
- **Tombstone Strategy:** Deletions do not wipe rows immediately; they mark `is_deleted = 1` and record a tombstone in `sync_log`.
- **Blob Sync:** Handled out-of-band via hash manifest comparison. Small metadata records sync first, heavy binary blobs download on-demand.

---

## 7. Rich Text & Knowledge Graph Architecture (Milestone 3)

### 7.1 Rich Text Engine (`flutter_quill`)
- **Package Selection:** `flutter_quill: ^11.6.0` (Apache-2.0) adopted behind the ATLAS `DocumentContentService` abstraction. Replaced `appflowy_editor` due to Flutter 3.47+ compilation break (`TextInputClient.onFocusReceived`).
- **Content Storage:** Delta JSON documents are serialized and stored in Content-Addressable Storage (CAS) referenced by `nodes.content_hash`. SQLite stores metadata while CAS guarantees immutability, de-duplication, and instant snapshotting.
- **Autosave & Navigation Safety:**
  - 1-second debounced autosave timer resets on user typing.
  - Asynchronous save mutex (`_isSaving`, `_saveQueued`) prevents racing writes.
  - `PopScope` intercepts back navigation to flush pending changes before screen exit.

### 7.2 Wiki-Links & Bidirectional Backlinks
```mermaid
flowchart LR
    Doc[Document / Editor] -->|Types [[Note]]| Parser[WikiLinkParser]
    Parser -->|Regex Matches| LinkRepo[LinkRepository]
    LinkRepo -->|Search Titles| NodesDao[NodesDao]
    LinkRepo -->|Insert / Sync Links| LinksDao[LinksDao / NodeLinks]
    LinksDao -->|Watch Backlinks Stream| BacklinksPanel[BacklinksPanel Widget]
    BacklinksPanel -->|Click Target| Router[GoRouter Navigate]
```
- **Wiki-Link Syntax:** Supports standard `[[Note Title]]` and aliased `[[Target Note|Custom Display Text]]`.
- **Reactive Backlinks Stream:** `LinksDao.watchBacklinksForTarget(nodeId)` joins `node_links` with `nodes` to provide a real-time stream of incoming references sorted by update timestamp.
- **Cross-Feature Interoperability:** Embedded in both `DocumentEditorScreen` and `NotebookEditorScreen` (via bottom sheet on iPadOS/Linux/Android).

---

## 8. Notebook & PDF System Architecture (Milestone 4)

### 8.1 PDF Engine & Coordinate System
- **Engine Selection:** `pdfrx: ^2.12.0` (MIT license, no AGPL dependencies). Backed by Google's native **PDFium** on Linux desktop, Android, and Windows, and Apple's native **PDFKit** on iPadOS/iOS.
- **Coordinate System Alignment:**
  - Standard PDF dimensions are expressed in PDF points ($1/72\text{ inch}$).
  - Standard A4 is $595.28 \times 841.89\text{ pt}$, US Letter is $612.0 \times 792.0\text{ pt}$.
  - The ATLAS Ink Engine operates at a $1.0\text{ canvas unit} = 1.0\text{ PDF point}$ ratio, providing zero-distortion 1:1 overlay precision.

```mermaid
flowchart TD
    subgraph UI["Dual-Layer Annotation Surface"]
        direction TB
        TopLayer["Drawing Layer (InkCanvas / PencilKit / InkPageView)"]
        BottomLayer["Background Layer (PdfPageBackground / PaperPatternPainter)"]
    end
    TopLayer -->|Transparent Background| BottomLayer
    BottomLayer -->|Streams Blob| CAS["CAS Storage Service (SHA-256)"]
    BottomLayer -->|Renders via PDFium/PDFKit| Engine["PdfRenderingService (pdfrx)"]
```

### 8.2 PDF Import & Scaffolding Pipeline
1. **User Action:** Selects local `.pdf` file via `file_picker`.
2. **CAS Ingestion:** `PdfRepository` hashes and writes the raw PDF binary into CAS blob storage.
3. **Structure Inspection:** `PdfRenderingService.openBytes(pdfBytes)` extracts page count and exact bounding dimensions for each page.
4. **Notebook Scaffolding:**
   - Creates parent `notebook` record in `nodes`.
   - Creates metadata entry in `pdf_documents`.
   - Creates container in `ink_documents`.
   - Inserts individual `ink_pages` matching the exact width and height of each PDF page with `pdfDocumentId`, `pdfSourceHash`, and `pdfPageIndex`.

### 8.3 Multi-Page Notebook Architecture
- **Page Manager Drawer (`NotebookPageDrawer`):**
  - Displays cached raster thumbnail previews for every page.
  - Supports dynamic page navigation, reordering, arbitrary page insertion below, page duplication, and page deletion.
  - Stationery template picker (ruled, grid, dot grid, blank) with customizable millimeter/point spacing.
- **Contiguous 1-Based Page Indexing:**
  - Database operations (`batchReorderPages`, `insertPageAt`, `deletePageAndReorder`) maintain strict contiguous 1-based page numbering to eliminate numbering gaps.

### 8.4 PDF Export Pipeline (`PdfExportService`)
- Uses the `pdf: ^3.13.1` (Apache-2.0) package to composite background stationery/PDF page rasters and vector ink strokes into standard PDF documents.
- Offscreen rasterizer (`renderCompositePageImage`) scales to $2.0\times$ device resolution for publication-quality output.
- Outputs `.pdf` to local filesystem with instant user notification.

### 8.5 Platform Boundary Integrity
- **Linux Desktop:** Full interactive vector handwriting canvas (`InkCanvas` + `InkToolPalette`) stacked over `PdfPageBackground`.
- **iPadOS:** Full hardware-accelerated Apple Pencil support (`PencilKit`) stacked over `PdfPageBackground`.
- **Android Companion:** Strictly read-only viewer (`InkPageView` with pinch-to-zoom and pan) stacked over `PdfPageBackground`. Zero editing or stroke capture capabilities.

