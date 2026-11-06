import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/notifications/notification_service.dart';
import 'package:atlas/features/tasks/data/repositories/task_repository.dart';
import 'package:atlas/features/tasks/presentation/tasks_screen.dart';
import 'package:atlas/features/tasks/presentation/widgets/quick_add_task_bar.dart';
import 'package:atlas/features/tasks/presentation/widgets/task_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestWorkspaceIdNotifier extends CurrentWorkspaceIdNotifier {
  @override
  String build() => 'ws-test';
}

void main() {
  group('TasksScreen Widget Tests', () {
    late AppDatabase database;
    late NotificationService notificationService;
    late TaskRepository taskRepository;

    setUp(() async {
      database = AppDatabase.inMemory();
      notificationService = NotificationService();
      taskRepository = TaskRepository(
        tasksDao: database.tasksDao,
        notificationService: notificationService,
      );

      final now = DateTime.now();
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-test',
              name: 'Workspace Test',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Pre-populate tasks
      await taskRepository.createTask(
        workspaceId: 'ws-test',
        title: 'Complete System Architecture',
        priority: 1,
      );
    });

    tearDown(() async {
      await database.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          tasksDaoProvider.overrideWithValue(database.tasksDao),
          taskRepositoryProvider.overrideWithValue(taskRepository),
          currentWorkspaceIdProvider.overrideWith(TestWorkspaceIdNotifier.new),
          currentWorkspaceProvider.overrideWith(
            (ref) async => WorkspaceEntry(
              id: 'ws-test',
              name: 'Workspace Test',
              settingsJson: '{}',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isDeleted: false,
              clientModifiedAt: DateTime.now(),
              modifiedDeviceId: 'test-device',
              syncVersion: 1,
            ),
          ),
        ],
        child: const MaterialApp(home: TasksScreen()),
      );
    }

    testWidgets('renders filter chips, quick-add bar, and pre-populated task', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify title & filter chips
      expect(find.text('Tasks & Planning'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Verify QuickAddTaskBar is present
      expect(find.byType(QuickAddTaskBar), findsOneWidget);

      // Verify pre-populated task item
      expect(find.byType(TaskItemWidget), findsOneWidget);
      expect(find.text('Complete System Architecture'), findsOneWidget);

      // Clean unmount to drain Drift stream timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('switching filter chips updates active filter', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on 'Completed' chip
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // No completed tasks yet, shows empty state
      expect(find.text('No completed tasks'), findsOneWidget);

      // Tap back to 'Inbox'
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      expect(find.text('Complete System Architecture'), findsOneWidget);

      // Clean unmount to drain Drift stream timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
