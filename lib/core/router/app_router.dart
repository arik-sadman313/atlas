import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/documents/presentation/document_editor_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/graph/presentation/knowledge_graph_screen.dart';
import '../../features/handwriting/presentation/screens/notebook_editor_screen.dart';
import '../../features/notebooks/presentation/notebooks_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../shared/widgets/atlas_scaffold.dart';
import 'routes.dart';

GoRouter createAppRouter({String initialLocation = AtlasRoutes.documents}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AtlasScaffold(currentRoute: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AtlasRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AtlasRoutes.notebooks,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotebooksScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return NoTransitionPage(
                    child: NotebookEditorScreen(notebookId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AtlasRoutes.documents,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DocumentsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return NoTransitionPage(
                    child: DocumentEditorScreen(documentId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AtlasRoutes.tasks,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TasksScreen()),
          ),
          GoRoute(
            path: AtlasRoutes.calendar,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CalendarScreen()),
          ),
          GoRoute(
            path: AtlasRoutes.search,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: AtlasRoutes.graph,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KnowledgeGraphScreen()),
          ),
          GoRoute(
            path: AtlasRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
