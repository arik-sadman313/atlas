import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/database/app_database.dart';
import '../core/database/daos/calendar_dao.dart';
import '../core/database/daos/habits_dao.dart';
import '../core/database/daos/ink_dao.dart';
import '../core/database/daos/journal_dao.dart';
import '../core/database/daos/links_dao.dart';
import '../core/database/daos/nodes_dao.dart';
import '../core/database/daos/sync_dao.dart';
import '../core/database/daos/tasks_dao.dart';
import '../core/database/daos/workspaces_dao.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/blob_storage_service.dart';
import '../core/storage/cas_storage_service.dart';
import '../core/sync/device/device_identity_service.dart';
import '../core/sync/folder/folder_sync_engine.dart';
import '../core/sync/vault/vault_export_service.dart';
import '../core/sync/vault/vault_import_service.dart';
import '../core/vaultite/vaultite_engine.dart';
import '../core/vaultite/vaultite_index.dart';
import '../features/calendar/data/repositories/calendar_repository.dart';
import '../features/documents/data/repositories/link_repository.dart';
import '../features/graph/data/repositories/graph_repository.dart';
import '../features/graph/domain/models/graph_models.dart';
import '../features/habits/data/repositories/habit_repository.dart';
import '../features/handwriting/data/repositories/ink_repository.dart';
import '../features/journal/data/repositories/journal_repository.dart';
import '../features/pdf/data/repositories/pdf_repository.dart';
import '../features/pdf/data/services/pdf_export_service.dart';
import '../features/pdf/data/services/pdf_rendering_service.dart';
import '../features/search/data/repositories/search_repository.dart';
import '../features/search/data/services/search_service.dart';
import '../features/settings/data/markdown_export_service.dart';
import '../features/settings/data/notebook_bulk_pdf_export_service.dart';
import '../features/tasks/data/repositories/task_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final workspacesDaoProvider = Provider<WorkspacesDao>((ref) {
  return ref.watch(appDatabaseProvider).workspacesDao;
});

final nodesDaoProvider = Provider<NodesDao>((ref) {
  return ref.watch(appDatabaseProvider).nodesDao;
});

final inkDaoProvider = Provider<InkDao>((ref) {
  return ref.watch(appDatabaseProvider).inkDao;
});

final linksDaoProvider = Provider<LinksDao>((ref) {
  return ref.watch(appDatabaseProvider).linksDao;
});

final tasksDaoProvider = Provider<TasksDao>((ref) {
  return ref.watch(appDatabaseProvider).tasksDao;
});

final calendarDaoProvider = Provider<CalendarDao>((ref) {
  return ref.watch(appDatabaseProvider).calendarDao;
});

final habitsDaoProvider = Provider<HabitsDao>((ref) {
  return ref.watch(appDatabaseProvider).habitsDao;
});

final journalDaoProvider = Provider<JournalDao>((ref) {
  return ref.watch(appDatabaseProvider).journalDao;
});

final syncDaoProvider = Provider<SyncDao>((ref) {
  return ref.watch(appDatabaseProvider).syncDao;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final blobStorageServiceProvider = Provider<BlobStorageService>((ref) {
  throw UnimplementedError(
    'blobStorageServiceProvider must be initialized in bootstrap',
  );
});

final inkRepositoryProvider = Provider<InkRepository>((ref) {
  final inkDao = ref.watch(inkDaoProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);
  return InkRepository(inkDao: inkDao, blobStorage: blobStorage);
});

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  final linksDao = ref.watch(linksDaoProvider);
  final nodesDao = ref.watch(nodesDaoProvider);
  return LinkRepository(linksDao: linksDao, nodesDao: nodesDao);
});

final vaultiteIndexProvider = Provider<VaultiteIndex>((ref) {
  return VaultiteIndex();
});

final vaultiteEngineProvider = Provider<VaultiteEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);
  final index = ref.watch(vaultiteIndexProvider);

  return VaultiteEngine(
    nodesDao: db.nodesDao,
    linksDao: db.linksDao,
    inkDao: db.inkDao,
    blobStorage: blobStorage,
    index: index,
  );
});

final pdfRenderingServiceProvider = Provider<PdfRenderingService>((ref) {
  return PdfrxRenderingService();
});

final pdfRepositoryProvider = Provider<PdfRepository>((ref) {
  final inkDao = ref.watch(inkDaoProvider);
  final nodesDao = ref.watch(nodesDaoProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);
  final pdfRenderingService = ref.watch(pdfRenderingServiceProvider);
  return PdfRepository(
    inkDao: inkDao,
    nodesDao: nodesDao,
    blobStorage: blobStorage,
    pdfRenderingService: pdfRenderingService,
  );
});

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  final inkDao = ref.watch(inkDaoProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);
  final pdfRenderingService = ref.watch(pdfRenderingServiceProvider);
  final inkRepo = ref.watch(inkRepositoryProvider);
  return PdfExportService(
    inkDao: inkDao,
    blobStorage: blobStorage,
    pdfRenderingService: pdfRenderingService,
    inkRepo: inkRepo,
  );
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final tasksDao = ref.watch(tasksDaoProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TaskRepository(
    tasksDao: tasksDao,
    notificationService: notificationService,
  );
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final calendarDao = ref.watch(calendarDaoProvider);
  final tasksDao = ref.watch(tasksDaoProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return CalendarRepository(
    calendarDao: calendarDao,
    tasksDao: tasksDao,
    notificationService: notificationService,
  );
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final habitsDao = ref.watch(habitsDaoProvider);
  return HabitRepository(habitsDao: habitsDao);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final journalDao = ref.watch(journalDaoProvider);
  final nodesDao = ref.watch(nodesDaoProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);
  return JournalRepository(
    journalDao: journalDao,
    nodesDao: nodesDao,
    blobStorage: blobStorage,
  );
});

final searchServiceProvider = Provider<SearchService>((ref) {
  final nodesDao = ref.watch(nodesDaoProvider);
  final tasksDao = ref.watch(tasksDaoProvider);
  final calendarDao = ref.watch(calendarDaoProvider);
  final journalDao = ref.watch(journalDaoProvider);
  final linksDao = ref.watch(linksDaoProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);

  return SearchService(
    nodesDao: nodesDao,
    tasksDao: tasksDao,
    calendarDao: calendarDao,
    journalDao: journalDao,
    linksDao: linksDao,
    blobStorage: blobStorage,
  );
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchRepository(searchService: searchService);
});

final graphRepositoryProvider = Provider<GraphRepository>((ref) {
  final nodesDao = ref.watch(nodesDaoProvider);
  final linksDao = ref.watch(linksDaoProvider);
  return GraphRepository(nodesDao: nodesDao, linksDao: linksDao);
});

final workspaceGraphProvider = FutureProvider<GraphData>((ref) async {
  final repo = ref.watch(graphRepositoryProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  return repo.loadWorkspaceGraph(workspaceId);
});

final casDirectoryProvider = Provider<Directory>((ref) {
  final blobStorage = ref.watch(blobStorageServiceProvider);
  if (blobStorage is CasStorageService) {
    return blobStorage.rootDirectory;
  }
  return Directory(p.join(Directory.systemTemp.path, 'blobs'));
});

final databaseFileProvider = Provider<File>((ref) {
  final casDir = ref.watch(casDirectoryProvider);
  return File(p.join(casDir.parent.path, 'atlas.db'));
});

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

final vaultExportServiceProvider = Provider<VaultExportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncDao = ref.watch(syncDaoProvider);
  final nodesDao = ref.watch(nodesDaoProvider);
  final deviceIdentity = ref.watch(deviceIdentityServiceProvider);
  final dbFile = ref.watch(databaseFileProvider);
  final casDir = ref.watch(casDirectoryProvider);

  return VaultExportService(
    database: db,
    syncDao: syncDao,
    nodesDao: nodesDao,
    deviceIdentity: deviceIdentity,
    databaseFile: dbFile,
    casDirectory: casDir,
  );
});

final vaultImportServiceProvider = Provider<VaultImportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncDao = ref.watch(syncDaoProvider);
  final dbFile = ref.watch(databaseFileProvider);
  final casDir = ref.watch(casDirectoryProvider);

  return VaultImportService(
    database: db,
    syncDao: syncDao,
    databaseFile: dbFile,
    casDirectory: casDir,
  );
});

final folderSyncEngineProvider = Provider<FolderSyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncDao = ref.watch(syncDaoProvider);
  final deviceIdentity = ref.watch(deviceIdentityServiceProvider);
  final casDir = ref.watch(casDirectoryProvider);

  return FolderSyncEngine(
    database: db,
    syncDao: syncDao,
    deviceIdentity: deviceIdentity,
    casDirectory: casDir,
  );
});

final markdownExportServiceProvider = Provider<MarkdownExportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final blobStorage = ref.watch(blobStorageServiceProvider);
  return MarkdownExportService(database: db, blobStorage: blobStorage);
});

final notebookBulkPdfExportServiceProvider =
    Provider<NotebookBulkPdfExportService>((ref) {
      final db = ref.watch(appDatabaseProvider);
      final inkDao = ref.watch(inkDaoProvider);
      final blobStorage = ref.watch(blobStorageServiceProvider);
      final pdfRenderingService = ref.watch(pdfRenderingServiceProvider);
      final inkRepo = ref.watch(inkRepositoryProvider);
      return NotebookBulkPdfExportService(
        database: db,
        inkDao: inkDao,
        blobStorage: blobStorage,
        pdfRenderingService: pdfRenderingService,
        inkRepo: inkRepo,
      );
    });

final syncHistoryStreamProvider = StreamProvider<List<SyncHistoryEntry>>((ref) {
  final syncDao = ref.watch(syncDaoProvider);
  return syncDao.watchRecentSyncHistory();
});

class CurrentWorkspaceIdNotifier extends Notifier<String> {
  @override
  String build() => 'workspace-default-primary';

  void setWorkspace(String id) {
    state = id;
  }
}

final currentWorkspaceIdProvider =
    NotifierProvider<CurrentWorkspaceIdNotifier, String>(
      CurrentWorkspaceIdNotifier.new,
    );

final allWorkspacesProvider = StreamProvider<List<WorkspaceEntry>>((ref) {
  final dao = ref.watch(workspacesDaoProvider);
  return dao.watchAllWorkspaces();
});

final currentWorkspaceProvider = FutureProvider<WorkspaceEntry?>((ref) async {
  final dao = ref.watch(workspacesDaoProvider);
  final id = ref.watch(currentWorkspaceIdProvider);
  return dao.getWorkspace(id);
});

final recentNodesProvider = StreamProvider<List<NodeEntry>>((ref) {
  final dao = ref.watch(nodesDaoProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  return dao.watchRecentNodes(workspaceId);
});

final favoriteNodesProvider = StreamProvider<List<NodeEntry>>((ref) {
  final dao = ref.watch(nodesDaoProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  return dao.watchFavoriteNodes(workspaceId);
});

final habitsWithProgressProvider = StreamProvider<List<HabitWithProgress>>((
  ref,
) {
  final repo = ref.watch(habitRepositoryProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  return repo.watchHabitsWithProgress(workspaceId);
});

final activeGoalsProvider = StreamProvider<List<GoalEntry>>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  return repo.watchGoals(workspaceId);
});

final todayJournalEntryProvider = StreamProvider<JournalEntryData?>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  final workspaceId = ref.watch(currentWorkspaceIdProvider);
  final todayStr = HabitsDao.formatDate(DateTime.now());
  return repo.watchEntryByDate(workspaceId, todayStr);
});

final deviceIdFutureProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(deviceIdentityServiceProvider);
  return service.getOrCreateDeviceId();
});

final deviceNameFutureProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(deviceIdentityServiceProvider);
  return service.getDeviceName();
});

final syncDirectoryFutureProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(deviceIdentityServiceProvider);
  return service.getSyncDirectoryPath();
});

class StorageMetrics {
  final int databaseSizeBytes;
  final int casSizeBytes;
  final int casBlobCount;
  final int attachmentsCount;

  const StorageMetrics({
    required this.databaseSizeBytes,
    required this.casSizeBytes,
    required this.casBlobCount,
    required this.attachmentsCount,
  });

  String get formattedDatabaseSize => _formatBytes(databaseSizeBytes);
  String get formattedCasSize => _formatBytes(casSizeBytes);
  String get formattedTotalSize =>
      _formatBytes(databaseSizeBytes + casSizeBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

final storageMetricsProvider = FutureProvider<StorageMetrics>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final dbFile = ref.watch(databaseFileProvider);
  final casDir = ref.watch(casDirectoryProvider);

  int dbSize = 0;
  if (dbFile.existsSync()) {
    dbSize += dbFile.lengthSync();
    final walFile = File('${dbFile.path}-wal');
    if (walFile.existsSync()) dbSize += walFile.lengthSync();
    final shmFile = File('${dbFile.path}-shm');
    if (shmFile.existsSync()) dbSize += shmFile.lengthSync();
  }

  int casSize = 0;
  int casCount = 0;
  if (casDir.existsSync()) {
    try {
      for (final entity in casDir.listSync(recursive: true)) {
        if (entity is File) {
          casSize += entity.lengthSync();
          casCount++;
        }
      }
    } catch (_) {}
  }

  int attachments = 0;
  try {
    final rows = await db.select(db.attachments).get();
    attachments = rows.length;
  } catch (_) {
    attachments = 0;
  }

  return StorageMetrics(
    databaseSizeBytes: dbSize,
    casSizeBytes: casSize,
    casBlobCount: casCount,
    attachmentsCount: attachments,
  );
});
