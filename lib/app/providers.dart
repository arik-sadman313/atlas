import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/daos/ink_dao.dart';
import '../core/database/daos/links_dao.dart';
import '../core/database/daos/nodes_dao.dart';
import '../core/database/daos/workspaces_dao.dart';
import '../core/storage/blob_storage_service.dart';
import '../features/documents/data/repositories/link_repository.dart';
import '../features/handwriting/data/repositories/ink_repository.dart';

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
