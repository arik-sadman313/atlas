import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/database/daos/habits_dao.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema Migration v6 Tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'fresh database initializes schema version 6+ with all tables',
      () async {
        expect(database.schemaVersion, greaterThanOrEqualTo(6));

        final now = DateTime.now();
        const wsId = 'ws-v6-test';

        // 1. Workspace
        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: wsId,
                name: 'Workspace V6',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 2. Habit
        const habitId = 'habit-1';
        await database
            .into(database.habits)
            .insert(
              HabitsCompanion.insert(
                id: habitId,
                workspaceId: wsId,
                title: 'Morning Run',
                colorHex: const Value('#10B981'),
                icon: const Value('directions_run'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final habit = await (database.select(
          database.habits,
        )..where((tbl) => tbl.id.equals(habitId))).getSingle();
        expect(habit.title, 'Morning Run');
        expect(habit.colorHex, '#10B981');
        expect(habit.icon, 'directions_run');

        // 3. Habit Log
        const logId = 'log-1';
        await database
            .into(database.habitLogs)
            .insert(
              HabitLogsCompanion.insert(
                id: logId,
                habitId: habitId,
                logDate: '2026-11-06',
                createdAt: now,
              ),
            );

        final log = await (database.select(
          database.habitLogs,
        )..where((tbl) => tbl.id.equals(logId))).getSingle();
        expect(log.habitId, habitId);
        expect(log.logDate, '2026-11-06');
        expect(log.isCompleted, true);

        // 4. Goal
        const goalId = 'goal-1';
        await database
            .into(database.goals)
            .insert(
              GoalsCompanion.insert(
                id: goalId,
                workspaceId: wsId,
                title: 'Launch ATLAS v1',
                status: const Value('in_progress'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final goal = await (database.select(
          database.goals,
        )..where((tbl) => tbl.id.equals(goalId))).getSingle();
        expect(goal.title, 'Launch ATLAS v1');
        expect(goal.status, 'in_progress');

        // 5. Document Node & Journal Entry
        const nodeId = 'node-journal-1';
        await database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: nodeId,
                workspaceId: wsId,
                type: 'document',
                title: 'Journal: Friday, November 6, 2026',
                createdAt: now,
                updatedAt: now,
              ),
            );

        const journalId = 'journal-1';
        await database
            .into(database.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                id: journalId,
                workspaceId: wsId,
                nodeId: nodeId,
                journalDate: '2026-11-06',
                mood: const Value('great'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final journal = await (database.select(
          database.journalEntries,
        )..where((tbl) => tbl.id.equals(journalId))).getSingle();
        expect(journal.workspaceId, wsId);
        expect(journal.nodeId, nodeId);
        expect(journal.journalDate, '2026-11-06');
        expect(journal.mood, 'great');
      },
    );

    test(
      'Habit unique constraint on (habitId, logDate) prevents duplicate logs',
      () async {
        final now = DateTime.now();
        const wsId = 'ws-uniq';
        const habitId = 'habit-uniq';

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: wsId,
                name: 'Workspace Uniq',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.habits)
            .insert(
              HabitsCompanion.insert(
                id: habitId,
                workspaceId: wsId,
                title: 'Drink Water',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.habitLogs)
            .insert(
              HabitLogsCompanion.insert(
                id: 'log-u1',
                habitId: habitId,
                logDate: '2026-11-06',
                createdAt: now,
              ),
            );

        // Inserting second log for same habit and date must throw
        expect(
          () async => database
              .into(database.habitLogs)
              .insert(
                HabitLogsCompanion.insert(
                  id: 'log-u2',
                  habitId: habitId,
                  logDate: '2026-11-06',
                  createdAt: now,
                ),
              ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('Journal unique constraint on (workspaceId, journalDate) enforces 1 entry per day', () async {
      final now = DateTime.now();
      const wsId = 'ws-j-uniq';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Workspace J Uniq',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'node-j1',
              workspaceId: wsId,
              type: 'document',
              title: 'Journal 1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'node-j2',
              workspaceId: wsId,
              type: 'document',
              title: 'Journal 2',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.journalEntries)
          .insert(
            JournalEntriesCompanion.insert(
              id: 'j-entry-1',
              workspaceId: wsId,
              nodeId: 'node-j1',
              journalDate: '2026-11-06',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Duplicate date for same workspace must throw
      expect(
        () async => database
            .into(database.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                id: 'j-entry-2',
                workspaceId: wsId,
                nodeId: 'node-j2',
                journalDate: '2026-11-06',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'HabitsDao toggleHabit handles create and toggle idempotently',
      () async {
        final now = DateTime.now();
        const wsId = 'ws-toggle';

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: wsId,
                name: 'Workspace Toggle',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final habit = await database.habitsDao.createHabit(
          HabitsCompanion.insert(
            id: 'habit-toggle',
            workspaceId: wsId,
            title: 'Daily Meditation',
            createdAt: now,
            updatedAt: now,
          ),
        );

        // 1. First toggle -> completed = true
        final state1 = await database.habitsDao.toggleHabit(
          habit.id,
          '2026-11-06',
        );
        expect(state1, isTrue);

        // 2. Second toggle -> completed = false
        final state2 = await database.habitsDao.toggleHabit(
          habit.id,
          '2026-11-06',
        );
        expect(state2, isFalse);

        // 3. Third toggle -> completed = true
        final state3 = await database.habitsDao.toggleHabit(
          habit.id,
          '2026-11-06',
        );
        expect(state3, isTrue);
      },
    );

    test(
      'HabitsDao streak math accurately counts contiguous days and history',
      () {
        final habit = HabitEntry(
          id: 'h-streak',
          workspaceId: 'ws-streak',
          title: 'Deep Work',
          colorHex: '#3B82F6',
          frequency: 'daily',
          targetCountPerPeriod: 1,
          isArchived: false,
          sortOrder: 0,
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 1),
          clientModifiedAt: DateTime(2026, 11, 1),
          modifiedDeviceId: 'test-device',
          syncVersion: 1,
        );

        final today = DateTime(2026, 11, 6);

        HabitLogEntry makeLog(String id, String logDate) => HabitLogEntry(
          id: id,
          habitId: habit.id,
          logDate: logDate,
          completedCount: 1,
          isCompleted: true,
          createdAt: today,
          clientModifiedAt: today,
          modifiedDeviceId: 'test-device',
          syncVersion: 1,
        );

        // Case A: Completed today (Nov 6), yesterday (Nov 5), Nov 4 -> 3-day current streak
        final logsA = [
          makeLog('1', '2026-11-06'),
          makeLog('2', '2026-11-05'),
          makeLog('3', '2026-11-04'),
        ];
        final progA = HabitsDao.calculateProgress(habit, logsA, today);
        expect(progA.isCompletedToday, isTrue);
        expect(progA.currentStreak, 3);
        expect(progA.bestStreak, 3);

        // Case B: Not completed today, but completed yesterday (Nov 5) and Nov 4 -> 2-day current streak alive
        final logsB = [makeLog('2', '2026-11-05'), makeLog('3', '2026-11-04')];
        final progB = HabitsDao.calculateProgress(habit, logsB, today);
        expect(progB.isCompletedToday, isFalse);
        expect(progB.currentStreak, 2);
        expect(progB.bestStreak, 2);

        // Case C: Broken streak (missed yesterday Nov 5, completed Nov 4 and Nov 3) -> current streak 0, best streak 2
        final logsC = [makeLog('3', '2026-11-04'), makeLog('4', '2026-11-03')];
        final progC = HabitsDao.calculateProgress(habit, logsC, today);
        expect(progC.isCompletedToday, isFalse);
        expect(progC.currentStreak, 0);
        expect(progC.bestStreak, 2);

        // Case D: Reset with today check-in (Nov 6 done, Nov 5 missed, Nov 4-1 done) -> current streak 1, best streak 4
        final logsD = [
          makeLog('1', '2026-11-06'),
          makeLog('3', '2026-11-04'),
          makeLog('4', '2026-11-03'),
          makeLog('5', '2026-11-02'),
          makeLog('6', '2026-11-01'),
        ];
        final progD = HabitsDao.calculateProgress(habit, logsD, today);
        expect(progD.isCompletedToday, isTrue);
        expect(progD.currentStreak, 1);
        expect(progD.bestStreak, 4);
      },
    );

    test('JournalDao findEntryByDate and watchRecentJournalEntries', () async {
      final now = DateTime.now();
      const wsId = 'ws-jdao';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Workspace JDAO',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'node-j3',
              workspaceId: wsId,
              type: 'document',
              title: 'Journal Entry 3',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database.journalDao.createJournalEntry(
        JournalEntriesCompanion.insert(
          id: 'j-3',
          workspaceId: wsId,
          nodeId: 'node-j3',
          journalDate: '2026-11-06',
          mood: const Value('good'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final found = await database.journalDao.findEntryByDate(
        wsId,
        '2026-11-06',
      );
      expect(found, isNotNull);
      expect(found!.mood, 'good');

      final notFound = await database.journalDao.findEntryByDate(
        wsId,
        '2026-11-07',
      );
      expect(notFound, isNull);
    });
  });
}
