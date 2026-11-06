import 'dart:io';

import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late CasStorageService blobStorage;
    late WorkspaceEntry defaultWs;

    setUp(() async {
      db = AppDatabase.inMemory();
      defaultWs = await db.workspacesDao.getOrCreateDefaultWorkspace();
      tempDir = Directory.systemTemp.createTempSync('atlas_dashboard_test_');
      blobStorage = CasStorageService(rootDirectory: tempDir);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'renders greeting, quick actions, stat cards, habits, and focus widgets',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final now = DateTime.now();

        // Pre-populate a habit
        await db.habitsDao.createHabit(
          HabitsCompanion.insert(
            id: 'habit-d1',
            workspaceId: defaultWs.id,
            title: 'Daily Coding',
            colorHex: const Value('#3B82F6'),
            icon: const Value('code'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Pre-populate a high priority task
        await db.tasksDao.createTask(
          TasksCompanion.insert(
            id: 'task-d1',
            workspaceId: defaultWs.id,
            title: 'Review PR #42',
            priority: const Value(1),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Pre-populate an active goal
        await db.habitsDao.createGoal(
          GoalsCompanion.insert(
            id: 'goal-d1',
            workspaceId: defaultWs.id,
            title: 'Ship M6 Release',
            status: const Value('in_progress'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              blobStorageServiceProvider.overrideWithValue(blobStorage),
              currentWorkspaceIdProvider.overrideWith(
                () => _MockCurrentWorkspaceIdNotifier(defaultWs.id),
              ),
              currentWorkspaceProvider.overrideWith(
                (ref) => Future.value(defaultWs),
              ),
            ],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Header & Greeting
        expect(find.text('Workspace Overview'), findsOneWidget);
        expect(find.text(defaultWs.name), findsOneWidget);

        // 2. Quick Action Buttons
        expect(find.text('New Task'), findsOneWidget);
        expect(find.text("Today's Journal"), findsOneWidget);
        expect(find.text('New Note'), findsOneWidget);

        // 3. Stat Cards
        expect(find.text('Documents'), findsOneWidget);
        expect(find.text('Notebooks'), findsOneWidget);
        expect(find.text('Tasks'), findsOneWidget);

        // 4. Live Widgets
        expect(find.text('Daily Habits'), findsOneWidget);
        expect(find.text('Daily Coding'), findsOneWidget);
        expect(find.text("Today's Focus & Agenda"), findsOneWidget);
        expect(find.text('Review PR #42'), findsOneWidget);
        expect(find.text('Goals & Milestones'), findsOneWidget);
        expect(find.text('Ship M6 Release'), findsOneWidget);
        expect(find.text('Daily Reflection'), findsOneWidget);

        // 5. Test 1-tap habit toggle
        final habitToggleFinder = find.byIcon(Icons.code);
        expect(habitToggleFinder, findsOneWidget);
        await tester.tap(habitToggleFinder);
        await tester.pumpAndSettle();

        // After toggle, checkmark icon should appear
        expect(find.byIcon(Icons.check), findsWidgets);

        // Clean up and advance time to flush any scheduled Stream cancellation timers
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}

class _MockCurrentWorkspaceIdNotifier extends CurrentWorkspaceIdNotifier {
  final String _initialId;
  _MockCurrentWorkspaceIdNotifier(this._initialId);

  @override
  String build() => _initialId;
}
