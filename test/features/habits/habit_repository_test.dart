import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/habits/data/repositories/habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitRepository Tests', () {
    late AppDatabase db;
    late HabitRepository repo;
    const wsId = 'ws-habit-repo';

    setUp(() async {
      db = AppDatabase.inMemory();
      repo = HabitRepository(habitsDao: db.habitsDao);

      await db.workspacesDao.createWorkspace(
        WorkspacesCompanion.insert(
          id: wsId,
          name: 'Habits Workspace',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'createHabit and watchHabitsWithProgress tracks completion and streaks',
      () async {
        final habit = await repo.createHabit(
          workspaceId: wsId,
          title: 'Morning Yoga',
          colorHex: '#10B981',
          icon: 'self_improvement',
          frequency: 'daily',
        );

        expect(habit.title, 'Morning Yoga');
        expect(habit.colorHex, '#10B981');
        expect(habit.isArchived, isFalse);

        // Verify stream emits initial progress
        final initialList = await repo.watchHabitsWithProgress(wsId).first;
        expect(initialList.length, 1);
        expect(initialList.first.habit.id, habit.id);
        expect(initialList.first.isCompletedToday, isFalse);
        expect(initialList.first.currentStreak, 0);

        // Toggle today
        final isNowCompleted = await repo.toggleHabitToday(habit.id);
        expect(isNowCompleted, isTrue);

        final updatedList = await repo.watchHabitsWithProgress(wsId).first;
        expect(updatedList.first.isCompletedToday, isTrue);
        expect(updatedList.first.currentStreak, 1);
        expect(updatedList.first.bestStreak, 1);

        // Archive habit
        await repo.archiveHabit(habit.id, isArchived: true);
        final activeList = await repo
            .watchHabitsWithProgress(wsId, includeArchived: false)
            .first;
        expect(activeList, isEmpty);

        final allList = await repo
            .watchHabitsWithProgress(wsId, includeArchived: true)
            .first;
        expect(allList.length, 1);
        expect(allList.first.habit.isArchived, isTrue);
      },
    );

    test('Goals CRUD operations', () async {
      final goal = await repo.createGoal(
        workspaceId: wsId,
        title: 'Complete Milestone 6',
        description: 'Dashboard, Habits, and Daily Journal',
        targetDate: DateTime(2026, 12, 31),
        status: 'in_progress',
      );

      expect(goal.title, 'Complete Milestone 6');
      expect(goal.status, 'in_progress');

      final goalsList = await repo.getGoals(wsId);
      expect(goalsList.length, 1);

      // Update goal status
      await repo.updateGoalStatus(goal.id, 'achieved');
      final updated = await repo.getGoals(wsId);
      expect(updated.first.status, 'achieved');

      // Delete goal
      await repo.deleteGoal(goal.id);
      final afterDelete = await repo.getGoals(wsId);
      expect(afterDelete, isEmpty);
    });
  });
}
