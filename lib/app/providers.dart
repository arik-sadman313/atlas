import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/calendar_dao.dart';
import '../core/database/daos/ink_dao.dart';
import '../core/database/daos/links_dao.dart';
import '../core/database/daos/nodes_dao.dart';
import '../core/database/daos/tasks_dao.dart';
import '../core/database/daos/workspaces_dao.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/blob_storage_service.dart';
import '../features/calendar/data/repositories/calendar_repository.dart';
import '../features/documents/data/repositories/link_repository.dart';
import '../features/handwriting/data/repositories/ink_repository.dart';
import '../features/pdf/data/repositories/pdf_repository.dart';
import '../features/pdf/data/services/pdf_export_service.dart';
import '../features/pdf/data/services/pdf_rendering_service.dart';
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
