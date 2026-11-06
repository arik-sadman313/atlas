import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/habits_dao.dart';

class HabitRepository {
  final HabitsDao habitsDao;
  final Uuid uuid;

  HabitRepository({required this.habitsDao, Uuid? uuid})
    : uuid = uuid ?? const Uuid();

  // --- Habits ---

  Stream<List<HabitEntry>> watchHabits(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    return habitsDao.watchHabitsForWorkspace(
      workspaceId,
      includeArchived: includeArchived,
    );
  }

  Stream<List<HabitWithProgress>> watchHabitsWithProgress(
    String workspaceId, {
    DateTime? today,
    bool includeArchived = false,
  }) {
    return habitsDao.watchHabitsWithProgress(
      workspaceId,
      today: today,
      includeArchived: includeArchived,
    );
  }

  Future<HabitEntry> createHabit({
    required String workspaceId,
    required String title,
    String? description,
    String? colorHex,
    String? icon,
    String? frequency,
    int? targetCountPerPeriod,
    int? sortOrder,
  }) {
    final now = DateTime.now();
    return habitsDao.createHabit(
      HabitsCompanion(
        id: Value(uuid.v4()),
        workspaceId: Value(workspaceId),
        title: Value(title.trim()),
        description: Value(description),
        colorHex: colorHex != null ? Value(colorHex) : const Value('#4CAF50'),
        icon: Value(icon),
        frequency: frequency != null ? Value(frequency) : const Value('daily'),
        targetCountPerPeriod: targetCountPerPeriod != null
            ? Value(targetCountPerPeriod)
            : const Value(1),
        isArchived: const Value(false),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> updateHabit(HabitEntry habit) {
    return habitsDao.updateHabit(habit.toCompanion(false));
  }

  Future<bool> toggleHabitToday(String habitId, {DateTime? today}) {
    final dateStr = HabitsDao.formatDate(today ?? DateTime.now());
    return habitsDao.toggleHabit(habitId, dateStr);
  }

  Future<bool> toggleHabitForDate(String habitId, String dateString) {
    return habitsDao.toggleHabit(habitId, dateString);
  }

  Future<void> setHabitCompleted(
    String habitId,
    String dateString,
    bool completed,
  ) {
    return habitsDao.setHabitCompleted(habitId, dateString, completed);
  }

  Future<bool> archiveHabit(String habitId, {bool isArchived = true}) async {
    return habitsDao.updateHabit(
      HabitsCompanion(
        id: Value(habitId),
        isArchived: Value(isArchived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteHabit(String habitId) {
    return habitsDao.deleteHabit(habitId);
  }

  // --- Goals ---

  Stream<List<GoalEntry>> watchGoals(String workspaceId, {String? status}) {
    return habitsDao.watchGoalsForWorkspace(workspaceId, status: status);
  }

  Future<List<GoalEntry>> getGoals(String workspaceId, {String? status}) {
    return habitsDao.getGoalsForWorkspace(workspaceId, status: status);
  }

  Future<GoalEntry> createGoal({
    required String workspaceId,
    required String title,
    String? description,
    DateTime? targetDate,
    String status = 'in_progress',
    String? colorHex,
  }) {
    final now = DateTime.now();
    return habitsDao.createGoal(
      GoalsCompanion(
        id: Value(uuid.v4()),
        workspaceId: Value(workspaceId),
        title: Value(title.trim()),
        description: Value(description),
        targetDate: Value(targetDate),
        status: Value(status),
        colorHex: Value(colorHex),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> updateGoal(GoalEntry goal) {
    return habitsDao.updateGoal(goal.toCompanion(false));
  }

  Future<bool> updateGoalStatus(String goalId, String status) {
    return habitsDao.updateGoal(
      GoalsCompanion(
        id: Value(goalId),
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteGoal(String goalId) {
    return habitsDao.deleteGoal(goalId);
  }
}
