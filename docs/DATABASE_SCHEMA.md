# ATLAS — Database Schema Specification

## 1. Storage Engine Overview

ATLAS uses **SQLite 3** as its primary structured storage engine, accessed via the **Drift** ORM in Dart.

### Database Configuration & PRAGMAs
At initialization, the database connection executes:
```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 30000000000;
PRAGMA cache_size = -64000; -- 64MB memory cache
PRAGMA busy_timeout = 5000;
```

---

## 2. Entity-Relationship Model

```mermaid
erDiagram
    WORKSPACE ||--o{ NODE : owns
    WORKSPACE ||--o{ PROJECT : owns
    WORKSPACE ||--o{ TAG : contains
    
    NODE ||--o{ NODE : children
    NODE ||--o{ NODE_BLOCK : contains
    NODE ||--o{ INK_DOCUMENT : has
    NODE ||--o{ BACKLINK : outgoing
    NODE ||--o{ BACKLINK : incoming
    
    INK_DOCUMENT ||--o{ INK_PAGE : pages
    
    PROJECT ||--o{ TASK : categorizes
    TASK ||--o{ TASK : subtasks
    NODE ||--o{ TASK : embeds
    
    TAG ||--o{ NODE_TAG : associates
    NODE ||--o{ NODE_TAG : classifies
    TAG ||--o{ TASK_TAG : associates
    TASK ||--o{ TASK_TAG : classifies
    
    WORKSPACE ||--o{ HABIT : defines
    HABIT ||--o{ HABIT_LOG : tracks
```

---

## 3. SQLite DDL Schema

### 3.1 Workspace & Node Core Tables

```sql
-- Workspaces allow multiple isolated vaults/knowledge bases
CREATE TABLE workspaces (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    name TEXT NOT NULL,
    icon TEXT,
    settings_json TEXT NOT NULL DEFAULT '{}',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

-- Nodes represent any hierarchical structural entity (Folders, Documents, Notebooks, Canvas)
CREATE TABLE nodes (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    parent_id TEXT REFERENCES nodes(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'folder' | 'document' | 'notebook' | 'database' | 'journal'
    title TEXT NOT NULL,
    icon TEXT,
    cover_image_hash TEXT,
    content_hash TEXT, -- CAS hash of serialized rich-text JSON document
    sort_order REAL NOT NULL DEFAULT 0.0,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    is_pinned INTEGER NOT NULL DEFAULT 0,
    is_archived INTEGER NOT NULL DEFAULT 0,
    is_deleted INTEGER NOT NULL DEFAULT 0,
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_nodes_workspace_parent ON nodes(workspace_id, parent_id, sort_order);
CREATE INDEX idx_nodes_type ON nodes(workspace_id, type);
CREATE INDEX idx_nodes_updated ON nodes(updated_at DESC);
```

### 3.2 Rich-Text Document Blocks

```sql
-- Block-level storage for Notion-style documents
CREATE TABLE node_blocks (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    parent_block_id TEXT REFERENCES node_blocks(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'paragraph' | 'heading_1' | 'heading_2' | 'heading_3' | 'bullet_list' | 'numbered_list' | 'todo' | 'code' | 'callout' | 'quote' | 'divider' | 'ink_canvas' | 'pdf_embed'
    content_json TEXT NOT NULL, -- Delta or AppFlowy node attributes
    sort_order REAL NOT NULL DEFAULT 0.0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_node_blocks_lookup ON node_blocks(node_id, parent_block_id, sort_order);
```

### 3.3 Handwriting & Notebook Tables

```sql
-- Handwriting document container
CREATE TABLE ink_documents (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    node_id TEXT NOT NULL UNIQUE REFERENCES nodes(id) ON DELETE CASCADE,
    default_page_width REAL NOT NULL DEFAULT 1600.0,
    default_page_height REAL NOT NULL DEFAULT 2200.0,
    default_template TEXT NOT NULL DEFAULT 'dot_grid_5mm',
    default_background_color INTEGER NOT NULL DEFAULT 4294967295, -- ARGB 0xFFFFFFFF
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- Individual pages within a notebook or PDF annotation document
CREATE TABLE ink_pages (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    document_id TEXT NOT NULL REFERENCES ink_documents(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL,
    width REAL NOT NULL,
    height REAL NOT NULL,
    template_type TEXT NOT NULL DEFAULT 'dot_grid_5mm', -- 'blank' | 'ruled' | 'grid' | 'dot' | 'cornell'
    template_spacing REAL NOT NULL DEFAULT 28.0, -- Grid/line spacing in points (1 pt = 1/72 in)
    background_color INTEGER NOT NULL DEFAULT 4294967295,
    pdf_document_id TEXT REFERENCES pdf_documents(id) ON DELETE SET NULL, -- References imported PDF
    pdf_source_hash TEXT, -- CAS hash of source PDF if page is an annotation
    pdf_page_index INTEGER, -- 0-based page index in the source PDF
    raw_pencilkit_hash TEXT, -- CAS hash of native iOS PKDrawing binary
    portable_ink_hash TEXT, -- CAS hash of cross-platform .atlas_ink JSON/binary
    preview_png_hash TEXT, -- CAS hash of high-res raster preview
    ocr_text TEXT, -- Recognized handwritten text for FTS indexing
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_ink_pages_doc_num ON ink_pages(document_id, page_number);

-- PDF Documents metadata referencing CAS blob storage
CREATE TABLE pdf_documents (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    cas_hash TEXT NOT NULL, -- CAS sha256 hash of original PDF binary
    file_name TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    page_count INTEGER NOT NULL,
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at INTEGER NOT NULL
);

CREATE INDEX idx_pdf_documents_node ON pdf_documents(node_id);
CREATE INDEX idx_pdf_documents_cas ON pdf_documents(cas_hash);
```

### 3.4 Tasks, Projects & Habits

```sql
-- Projects grouping related tasks and goals
CREATE TABLE projects (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    color INTEGER NOT NULL DEFAULT 4280191205, -- ARGB
    icon TEXT,
    status TEXT NOT NULL DEFAULT 'active', -- 'active' | 'completed' | 'on_hold' | 'archived'
    priority TEXT NOT NULL DEFAULT 'P4', -- 'P1' | 'P2' | 'P3' | 'P4'
    due_date INTEGER,
    sort_order REAL NOT NULL DEFAULT 0.0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

-- Actionable tasks
CREATE TABLE tasks (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    project_id TEXT REFERENCES projects(id) ON DELETE SET NULL,
    node_id TEXT REFERENCES nodes(id) ON DELETE SET NULL, -- Embedded link to document/page
    parent_task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE, -- Subtasks
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'todo', -- 'todo' | 'in_progress' | 'completed' | 'cancelled'
    priority TEXT NOT NULL DEFAULT 'P4', -- 'P1' | 'P2' | 'P3' | 'P4'
    due_date INTEGER, -- Unix timestamp (millis)
    reminder_date INTEGER,
    recurrence_rrule TEXT, -- iCalendar RFC 5545 RRULE string (e.g. FREQ=DAILY;INTERVAL=1)
    completed_at INTEGER,
    sort_order REAL NOT NULL DEFAULT 0.0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_tasks_workspace_status ON tasks(workspace_id, status, due_date);
CREATE INDEX idx_tasks_project ON tasks(project_id, status);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id);

-- Habits & streak tracking
CREATE TABLE habits (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    frequency_type TEXT NOT NULL DEFAULT 'daily', -- 'daily' | 'weekly_days' | 'interval'
    target_days_mask INTEGER NOT NULL DEFAULT 127, -- Bitmask for Mon-Sun (1111111 = 127)
    target_count INTEGER NOT NULL DEFAULT 1,
    color INTEGER NOT NULL DEFAULT 4283215696,
    icon TEXT,
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE habit_logs (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    date_key TEXT NOT NULL, -- 'YYYY-MM-DD'
    completed_count INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    logged_at INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_habit_logs_unique ON habit_logs(habit_id, date_key);
```

### 3.5 Backlinks, Node Links & Tags (Schema v3)

```sql
-- Bi-directional wiki-links between nodes (Implemented in Schema v3)
CREATE TABLE node_links (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    source_node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    target_node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    link_text TEXT,
    created_at INTEGER NOT NULL
);

CREATE INDEX idx_node_links_source ON node_links(source_node_id);
CREATE INDEX idx_node_links_target ON node_links(target_node_id);

-- Tags taxonomy (Implemented in Schema v3)
CREATE TABLE tags (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color INTEGER,
    created_at INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_tags_workspace_name ON tags(workspace_id, name);

CREATE TABLE node_tags (
    node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (node_id, tag_id)
);

CREATE TABLE task_tags (
    task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, tag_id)
);
```

### 3.6 Content-Addressable Attachments & Sync Log

```sql
-- Physical file attachments (PDFs, images, ink binaries)
CREATE TABLE attachments (
    sha256_hash TEXT PRIMARY KEY NOT NULL,
    relative_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    byte_size INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

-- Sync mutation stream for future synchronization
CREATE TABLE sync_log (
    sequence_id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL, -- 'node' | 'node_block' | 'ink_page' | 'task' | 'project' | 'habit'
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL, -- 'INSERT' | 'UPDATE' | 'DELETE'
    hlc_timestamp INTEGER NOT NULL, -- Hybrid Logical Clock counter
    device_id TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE INDEX idx_sync_log_seq ON sync_log(sequence_id);
```

---

## 4. Full-Text Search (SQLite FTS5)

SQLite FTS5 provides instantaneous full-text search across all text content:

```sql
-- FTS5 virtual table for nodes and rich-text blocks
CREATE VIRTUAL TABLE fts_content USING fts5(
    node_id UNINDEXED,
    title,
    body_content,
    tokenize = 'porter unicode61 remove_diacritics 2'
);

-- Triggers automatically maintain the FTS index on node changes
CREATE TRIGGER trig_nodes_ai AFTER INSERT ON nodes BEGIN
    INSERT INTO fts_content(node_id, title, body_content)
    VALUES (new.id, new.title, '');
END;

CREATE TRIGGER trig_nodes_au AFTER UPDATE OF title ON nodes BEGIN
    UPDATE fts_content SET title = new.title WHERE node_id = new.id;
END;

CREATE TRIGGER trig_nodes_ad AFTER DELETE ON nodes BEGIN
    DELETE FROM fts_content WHERE node_id = old.id;
END;

-- FTS5 virtual table for tasks
CREATE VIRTUAL TABLE fts_tasks USING fts5(
    task_id UNINDEXED,
    title,
    description,
    tokenize = 'porter unicode61 remove_diacritics 2'
);
```

---

## 5. Drift ORM Integration & Type Safety

Drift tables mirror this schema in Dart code to provide compile-time type safety, automated query generation, and reactive stream triggers:

```dart
// Example Drift table definition
@DataClassName('NodeEntry')
class Nodes extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id)();
  TextColumn get parentId => text().nullable().references(Nodes, #id)();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get coverImageHash => text().nullable()();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 6. Schema Version 2 Migration (Milestone 2)

In Milestone 2, the Drift database schema was upgraded to **version 2** with the introduction of tables supporting the Portable Ink Engine and native handwriting integration:

### 6.1 `ink_documents` Table
```sql
CREATE TABLE ink_documents (
    id TEXT PRIMARY KEY NOT NULL,
    node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    default_page_width REAL NOT NULL DEFAULT 1600.0,
    default_page_height REAL NOT NULL DEFAULT 2200.0,
    default_template TEXT NOT NULL DEFAULT 'dot_grid_5mm',
    default_background_color INTEGER NOT NULL DEFAULT 4294967295, -- 0xFFFFFFFF
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### 6.2 `ink_pages` Table
```sql
CREATE TABLE ink_pages (
    id TEXT PRIMARY KEY NOT NULL,
    document_id TEXT NOT NULL REFERENCES ink_documents(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL,
    width REAL NOT NULL DEFAULT 1600.0,
    height REAL NOT NULL DEFAULT 2200.0,
    template_type TEXT NOT NULL DEFAULT 'dot_grid_5mm',
    background_color INTEGER NOT NULL DEFAULT 4294967295,
    pdf_source_hash TEXT,
    pdf_page_index INTEGER,
    raw_pencilkit_hash TEXT, -- SHA-256 CAS blob reference for iOS native .pkdrawing
    portable_ink_hash TEXT,   -- SHA-256 CAS blob reference for cross-platform .atlas_ink_bin
    preview_png_hash TEXT,    -- SHA-256 CAS blob reference for raster thumbnail .png
    ocr_text TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### 6.3 Migration Strategy
In `AppDatabase.migration`:
```dart
onUpgrade: (m, from, to) async {
  if (from < 2) {
    await m.createTable(inkDocuments);
    await m.createTable(inkPages);
  }
  if (from < 3) {
    await m.addColumn(nodes, nodes.contentHash);
    await m.createTable(nodeLinks);
    await m.createTable(tags);
    await m.createTable(nodeTags);
  }
  if (from < 4) {
    await m.createTable(pdfDocuments);
    await m.addColumn(inkPages, inkPages.pdfDocumentId);
    await m.addColumn(inkPages, inkPages.templateSpacing);
  }
  if (from < 5) {
    await m.createTable(projects);
    await m.createTable(tasks);
    await m.createTable(calendarEvents);
  }
}
```
Tables are managed via [`InkDao`](../lib/core/database/daos/ink_dao.dart), [`TasksDao`](../lib/core/database/daos/tasks_dao.dart), and [`CalendarDao`](../lib/core/database/daos/calendar_dao.dart).

---

## 7. Schema Version 3 Migration (Milestone 3)

### 7.1 New Columns & Tables
- **`nodes.content_hash`**: Added nullable `TEXT` column storing the SHA-256 hash of serialized Delta rich-text JSON content in CAS storage.
- **`node_links`**: Bi-directional wiki-link graph index mapping `source_node_id` to `target_node_id` with extracted `link_text`.
- **`tags` & `node_tags`**: Tag entity and node-tag association tables.

### 7.2 DAOs
- [`LinksDao`](../lib/core/database/daos/links_dao.dart): Provides transactional link updates (`syncLinksForSource`), reactive incoming backlinks streams with node metadata joins (`watchBacklinksForTarget`), and forward links queries.
- [`NodesDao`](../lib/core/database/daos/nodes_dao.dart): Added `findNodeByTitle` and `updateNodePartial` for fine-grained metadata and content updates without overwriting existing fields.

---

## 8. Schema Version 4 Migration (Milestone 4: Notebook & PDF System)

### 8.1 New Columns & Tables
- **`pdf_documents`**: Dedicated catalog for imported PDF documents storing `cas_hash`, `file_name`, `file_size_bytes`, `page_count`, and parent `node_id`.
- **`ink_pages.pdf_document_id`**: Foreign key pointing to `pdf_documents.id` for PDF-backed annotation pages.
- **`ink_pages.template_spacing`**: Floating point column (points, $1.0\text{ pt} = 1/72\text{ in}$) defining stationery line/grid spacing (default: $28.0\text{ pt}$).

### 8.2 DAOs
- [`InkDao`](../lib/core/database/daos/ink_dao.dart):
  - `batchReorderPages`: Atomic re-indexing of multi-page sequence.
  - `insertPageAt`: Shifts subsequent pages and inserts new page at arbitrary index.
  - `duplicatePage`: Clones page attributes and drawings directly following the source.
  - `deletePageAndReorder`: Removes page and adjusts subsequent indices to maintain contiguous 1-based page numbering.
  - `updatePageTemplate`: Fine-grained mutation of paper template type and grid spacing.
  - `insertPdfDocument`, `getPdfDocument`, `getPdfDocumentForNode`, `deletePdfDocument`: CRUD operations for PDF metadata.

---

## 9. Schema Version 5 Migration (Milestone 5: Tasks, Calendar & Reminders)

### 9.1 New Tables

#### `projects` Table
```sql
CREATE TABLE projects (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color_hex TEXT,
    icon TEXT,
    sort_order REAL NOT NULL DEFAULT 0.0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX idx_projects_workspace ON projects(workspace_id, sort_order);
```

#### `tasks` Table
```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    project_id TEXT REFERENCES projects(id) ON DELETE SET NULL,
    node_id TEXT REFERENCES nodes(id) ON DELETE SET NULL,
    parent_task_id TEXT REFERENCES tasks(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    completed_at INTEGER,
    priority INTEGER NOT NULL DEFAULT 4, -- 1 (Urgent/P1) to 4 (None/P4)
    due_date INTEGER,
    has_time INTEGER NOT NULL DEFAULT 0,
    reminder_minutes_before INTEGER,
    recurrence_rule TEXT, -- 'daily' | 'weekdays' | 'weekly' | 'monthly' | 'custom'
    sort_order INTEGER NOT NULL DEFAULT 0,
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX idx_tasks_workspace_due ON tasks(workspace_id, due_date, is_completed);
CREATE INDEX idx_tasks_project ON tasks(project_id, is_completed, sort_order);
CREATE INDEX idx_tasks_node ON tasks(node_id, is_completed);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id, sort_order);
```

#### `calendar_events` Table
```sql
CREATE TABLE calendar_events (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    task_id TEXT REFERENCES tasks(id) ON DELETE SET NULL,
    node_id TEXT REFERENCES nodes(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    start_time INTEGER NOT NULL,
    end_time INTEGER NOT NULL,
    is_all_day INTEGER NOT NULL DEFAULT 0,
    color_hex TEXT,
    location TEXT,
    recurrence_rule TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX idx_calendar_events_range ON calendar_events(workspace_id, start_time, end_time);
CREATE INDEX idx_calendar_events_node ON calendar_events(node_id);
```

### 9.2 DAOs & Repositories
- [`TasksDao`](../lib/core/database/daos/tasks_dao.dart):
  - `watchTasksForWorkspace`, `watchTasksForNode`, `watchSubtasks`
  - `batchReorderTasks`, `toggleTaskCompletion`, `createTask`, `updateTask`, `deleteTask`
  - `watchProjectsForWorkspace`, `createProject`, `updateProject`, `deleteProject`
- [`CalendarDao`](../lib/core/database/daos/calendar_dao.dart):
  - `watchAllEvents`, `watchEventsForRange`, `getEventsForRange`, `watchEventsForDay`, `getEventsForDay`, `watchEventsForNode`
  - `createEvent`, `updateEvent`, `deleteEvent`
- [`TaskRepository`](../lib/features/tasks/data/repositories/task_repository.dart):
  - Manages task views: Inbox, Today, Upcoming, Projects, Completed with reactive filtering and subtask hierarchy segregation.
- [`CalendarRepository`](../lib/features/calendar/data/repositories/calendar_repository.dart):
  - Merges calendar events and due tasks into unified chronological `CalendarAgendaItem` agenda streams.

---

## 10. Milestone 6: Personal Dashboard, Habits & Daily Journal (Schema v6)

### 10.1 Schema Version 6 Tables

#### `habits` Table
```sql
CREATE TABLE habits (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title TEXT NOT NULL, -- min 1, max 500
    description TEXT,
    color_hex TEXT NOT NULL DEFAULT '#4CAF50',
    icon TEXT,
    frequency TEXT NOT NULL DEFAULT 'daily', -- 'daily' | 'weekly'
    target_count_per_period INTEGER NOT NULL DEFAULT 1,
    is_archived INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX idx_habits_workspace ON habits(workspace_id, is_archived, sort_order);
```

#### `habit_logs` Table
```sql
CREATE TABLE habit_logs (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    log_date TEXT NOT NULL, -- YYYY-MM-DD format
    completed_count INTEGER NOT NULL DEFAULT 1,
    is_completed INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    UNIQUE(habit_id, log_date)
);
CREATE INDEX idx_habit_logs_habit_date ON habit_logs(habit_id, log_date);
```

#### `goals` Table
```sql
CREATE TABLE goals (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title TEXT NOT NULL, -- min 1, max 500
    description TEXT,
    target_date INTEGER,
    status TEXT NOT NULL DEFAULT 'in_progress', -- 'not_started' | 'in_progress' | 'achieved' | 'abandoned'
    color_hex TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
CREATE INDEX idx_goals_workspace ON goals(workspace_id, status);
```

#### `journal_entries` Table
```sql
CREATE TABLE journal_entries (
    id TEXT PRIMARY KEY NOT NULL, -- UUIDv4
    workspace_id TEXT NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    node_id TEXT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
    journal_date TEXT NOT NULL, -- YYYY-MM-DD format
    mood TEXT, -- 'great' | 'good' | 'neutral' | 'bad' | 'awful'
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE(workspace_id, journal_date)
);
CREATE INDEX idx_journal_entries_date ON journal_entries(workspace_id, journal_date);
CREATE INDEX idx_journal_entries_node ON journal_entries(node_id);
```

### 10.2 DAOs & Repositories
- [`HabitsDao`](../lib/core/database/daos/habits_dao.dart):
  - `watchHabitsForWorkspace`, `getHabitsForWorkspace`, `watchHabitsWithProgress`
  - `calculateProgress`: contiguous date streak math (current streak, best streak, weekly completion map)
  - `toggleHabit`: idempotent toggle of habit logs for YYYY-MM-DD
  - Goals CRUD: `watchGoalsForWorkspace`, `getGoalsForWorkspace`, `createGoal`, `updateGoal`, `deleteGoal`
- [`JournalDao`](../lib/core/database/daos/journal_dao.dart):
  - `findEntryByDate`, `watchEntryByDate`, `findEntryByNodeId`, `watchEntryByNodeId`, `watchRecentJournalEntries`
  - `createJournalEntry`, `updateJournalEntry`, `deleteJournalEntry`
- [`HabitRepository`](../lib/features/habits/data/repositories/habit_repository.dart):
  - Domain facade for habit operations, streak queries, active goal management.
- [`JournalRepository`](../lib/features/journal/data/repositories/journal_repository.dart):
  - Scaffolds date-linked document nodes in CAS with structured default reflection sections (`## Daily Focus`, `## Key Wins`, `## Reflections`) and manages journal entry metadata.

