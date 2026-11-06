import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables/goals_table.dart';
import '../tables/habit_logs_table.dart';
import '../tables/habits_table.dart';

part 'habits_dao.g.dart';

/// Progress and streak calculation details for a Habit.
class HabitWithProgress {
  final HabitEntry habit;
  final bool isCompletedToday;
  final int currentStreak;
  final int bestStreak;
  final Map<String, bool> weeklyCompletion;
  final List<HabitLogEntry> logs;

  const HabitWithProgress({
    required this.habit,
    required this.isCompletedToday,
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyCompletion,
    required this.logs,
  });
}

@DriftAccessor(tables: [Habits, HabitLogs, Goals])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  final Uuid _uuid;

  HabitsDao(super.db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  // --- Habit Queries ---

  Stream<List<HabitEntry>> watchHabitsForWorkspace(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    final query = select(habits)
      ..where((tbl) {
        var predicate = tbl.workspaceId.equals(workspaceId);
        if (!includeArchived) {
          predicate &= tbl.isArchived.equals(false);
        }
        return predicate;
      })
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.watch();
  }

  Future<List<HabitEntry>> getHabitsForWorkspace(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    final query = select(habits)
      ..where((tbl) {
        var predicate = tbl.workspaceId.equals(workspaceId);
        if (!includeArchived) {
          predicate &= tbl.isArchived.equals(false);
        }
        return predicate;
      })
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.get();
  }

  Stream<List<HabitWithProgress>> watchHabitsWithProgress(
    String workspaceId, {
    DateTime? today,
    bool includeArchived = false,
  }) {
    final effectiveToday = today ?? DateTime.now();

    final query =
        select(habits).join([
            leftOuterJoin(habitLogs, habitLogs.habitId.equalsExp(habits.id)),
          ])
          ..where(habits.workspaceId.equals(workspaceId))
          ..orderBy([
            OrderingTerm(expression: habits.sortOrder, mode: OrderingMode.asc),
            OrderingTerm(expression: habits.createdAt, mode: OrderingMode.asc),
          ]);

    if (!includeArchived) {
      query.where(habits.isArchived.equals(false));
    }

    return query.watch().map((rows) {
      final grouped = <String, (HabitEntry, List<HabitLogEntry>)>{};

      for (final row in rows) {
        final habit = row.readTable(habits);
        final log = row.readTableOrNull(habitLogs);

        final entry = grouped.putIfAbsent(
          habit.id,
          () => (habit, <HabitLogEntry>[]),
        );
        if (log != null) {
          entry.$2.add(log);
        }
      }

      return grouped.values.map((pair) {
        final habit = pair.$1;
        final logs = pair.$2;
        return calculateProgress(habit, logs, effectiveToday);
      }).toList();
    });
  }

  Future<HabitWithProgress?> getHabitWithProgress(
    String habitId, {
    DateTime? today,
  }) async {
    final effectiveToday = today ?? DateTime.now();

    final habit = await (select(
      habits,
    )..where((tbl) => tbl.id.equals(habitId))).getSingleOrNull();
    if (habit == null) return null;

    final logs = await (select(
      habitLogs,
    )..where((tbl) => tbl.habitId.equals(habitId))).get();
    return calculateProgress(habit, logs, effectiveToday);
  }

  /// Calculates contiguous day streak and progress for a habit.
  static HabitWithProgress calculateProgress(
    HabitEntry habit,
    List<HabitLogEntry> logs,
    DateTime today,
  ) {
    final todayStr = formatDate(today);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayStr = formatDate(yesterday);

    final completedDateStrings = <String>{};
    for (final l in logs) {
      if (l.isCompleted) {
        completedDateStrings.add(l.logDate);
      }
    }

    final isCompletedToday = completedDateStrings.contains(todayStr);

    // Calculate current streak:
    // If completed today, start counting from today backwards.
    // If not completed today, but completed yesterday, streak is alive from yesterday.
    // If neither, current streak is 0.
    int currentStreak = 0;
    if (isCompletedToday) {
      currentStreak = 1;
      var checkDate = yesterday;
      while (completedDateStrings.contains(formatDate(checkDate))) {
        currentStreak++;
        checkDate = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day - 1,
        );
      }
    } else if (completedDateStrings.contains(yesterdayStr)) {
      currentStreak = 1;
      var checkDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day - 1,
      );
      while (completedDateStrings.contains(formatDate(checkDate))) {
        currentStreak++;
        checkDate = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day - 1,
        );
      }
    }

    // Calculate best streak across all history
    int bestStreak = 0;
    if (completedDateStrings.isNotEmpty) {
      final sortedDates = completedDateStrings.map((s) {
        final parts = s.split('-').map(int.parse).toList();
        return DateTime(parts[0], parts[1], parts[2]);
      }).toList()..sort();

      int run = 0;
      DateTime? prev;
      for (final date in sortedDates) {
        if (prev == null) {
          run = 1;
        } else {
          final expected = DateTime(prev.year, prev.month, prev.day + 1);
          if (date.year == expected.year &&
              date.month == expected.month &&
              date.day == expected.day) {
            run++;
          } else {
            run = 1;
          }
        }
        if (run > bestStreak) {
          bestStreak = run;
        }
        prev = date;
      }
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    // Weekly completion for the past 7 days ending today
    final weeklyCompletion = <String, bool>{};
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day - i);
      final s = formatDate(d);
      weeklyCompletion[s] = completedDateStrings.contains(s);
    }

    return HabitWithProgress(
      habit: habit,
      isCompletedToday: isCompletedToday,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      weeklyCompletion: weeklyCompletion,
      logs: logs,
    );
  }

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // --- Habit Mutations ---

  Future<HabitEntry> createHabit(HabitsCompanion companion) async {
    final now = DateTime.now();
    final habitId = companion.id.present ? companion.id.value : _uuid.v4();

    final fullCompanion = companion.copyWith(
      id: Value(habitId),
      createdAt: companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt: companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(habits).insert(fullCompanion);
    return (select(habits)..where((tbl) => tbl.id.equals(habitId))).getSingle();
  }

  Future<bool> updateHabit(HabitsCompanion companion) async {
    final updated = companion.copyWith(updatedAt: Value(DateTime.now()));
    final count = await (update(
      habits,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(updated);
    return count > 0;
  }

  Future<int> deleteHabit(String id) {
    return (delete(habits)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Toggles habit completion for a specific date (YYYY-MM-DD).
  /// Returns the new `isCompleted` boolean state.
  Future<bool> toggleHabit(String habitId, String dateString) async {
    final existing =
        await (select(habitLogs)..where(
              (tbl) =>
                  tbl.habitId.equals(habitId) & tbl.logDate.equals(dateString),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await into(habitLogs).insert(
        HabitLogsCompanion.insert(
          id: _uuid.v4(),
          habitId: habitId,
          logDate: dateString,
          completedCount: const Value(1),
          isCompleted: const Value(true),
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } else {
      final nextState = !existing.isCompleted;
      await (update(habitLogs)..where((tbl) => tbl.id.equals(existing.id)))
          .write(HabitLogsCompanion(isCompleted: Value(nextState)));
      return nextState;
    }
  }

  Future<void> setHabitCompleted(
    String habitId,
    String dateString,
    bool completed,
  ) async {
    final existing =
        await (select(habitLogs)..where(
              (tbl) =>
                  tbl.habitId.equals(habitId) & tbl.logDate.equals(dateString),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await into(habitLogs).insert(
        HabitLogsCompanion.insert(
          id: _uuid.v4(),
          habitId: habitId,
          logDate: dateString,
          completedCount: const Value(1),
          isCompleted: Value(completed),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await (update(habitLogs)..where((tbl) => tbl.id.equals(existing.id)))
          .write(HabitLogsCompanion(isCompleted: Value(completed)));
    }
  }

  Future<List<HabitLogEntry>> getLogsForDate(String dateString) {
    return (select(habitLogs)..where(
          (tbl) =>
              tbl.logDate.equals(dateString) & tbl.isCompleted.equals(true),
        ))
        .get();
  }

  // --- Goal Queries & Mutations ---

  Stream<List<GoalEntry>> watchGoalsForWorkspace(
    String workspaceId, {
    String? status,
  }) {
    final query = select(goals)
      ..where((tbl) {
        var predicate = tbl.workspaceId.equals(workspaceId);
        if (status != null) {
          predicate &= tbl.status.equals(status);
        }
        return predicate;
      })
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.targetDate, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.watch();
  }

  Future<List<GoalEntry>> getGoalsForWorkspace(
    String workspaceId, {
    String? status,
  }) {
    final query = select(goals)
      ..where((tbl) {
        var predicate = tbl.workspaceId.equals(workspaceId);
        if (status != null) {
          predicate &= tbl.status.equals(status);
        }
        return predicate;
      })
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.targetDate, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.get();
  }

  Future<GoalEntry> createGoal(GoalsCompanion companion) async {
    final now = DateTime.now();
    final goalId = companion.id.present ? companion.id.value : _uuid.v4();

    final fullCompanion = companion.copyWith(
      id: Value(goalId),
      createdAt: companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt: companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(goals).insert(fullCompanion);
    return (select(goals)..where((tbl) => tbl.id.equals(goalId))).getSingle();
  }

  Future<bool> updateGoal(GoalsCompanion companion) async {
    final updated = companion.copyWith(updatedAt: Value(DateTime.now()));
    final count = await (update(
      goals,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(updated);
    return count > 0;
  }

  Future<int> deleteGoal(String id) {
    return (delete(goals)..where((tbl) => tbl.id.equals(id))).go();
  }
}
