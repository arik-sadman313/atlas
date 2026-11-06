import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/notifications/notification_service.dart';
import 'package:atlas/features/calendar/data/repositories/calendar_repository.dart';
import 'package:atlas/features/calendar/domain/models/calendar_agenda_item.dart';
import 'package:atlas/features/calendar/presentation/calendar_screen.dart';
import 'package:atlas/features/calendar/presentation/widgets/agenda_item_card.dart';
import 'package:atlas/features/calendar/presentation/widgets/event_detail_sheet.dart';
import 'package:atlas/features/tasks/data/repositories/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

class TestWorkspaceIdNotifier extends CurrentWorkspaceIdNotifier {
  @override
  String build() => 'ws-cal-test';
}

void main() {
  group('CalendarScreen Widget Tests', () {
    late AppDatabase database;
    late NotificationService notificationService;
    late CalendarRepository calendarRepository;
    late TaskRepository taskRepository;

    setUp(() async {
      database = AppDatabase.inMemory();
      notificationService = NotificationService();
      calendarRepository = CalendarRepository(
        calendarDao: database.calendarDao,
        tasksDao: database.tasksDao,
        notificationService: notificationService,
      );
      taskRepository = TaskRepository(
        tasksDao: database.tasksDao,
        notificationService: notificationService,
      );

      final now = DateTime.now();
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-cal-test',
              name: 'Workspace Cal Test',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Pre-populate an event today
      await calendarRepository.createEvent(
        workspaceId: 'ws-cal-test',
        title: 'Atlas Product Roadmap Review',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 30),
        location: 'HQ Conference Room',
        colorHex: '#3B82F6',
      );
    });

    tearDown(() async {
      await database.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          calendarDaoProvider.overrideWithValue(database.calendarDao),
          tasksDaoProvider.overrideWithValue(database.tasksDao),
          calendarRepositoryProvider.overrideWithValue(calendarRepository),
          taskRepositoryProvider.overrideWithValue(taskRepository),
          currentWorkspaceIdProvider.overrideWith(TestWorkspaceIdNotifier.new),
          currentWorkspaceProvider.overrideWith(
            (ref) async => WorkspaceEntry(
              id: 'ws-cal-test',
              name: 'Workspace Cal Test',
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
        child: const MaterialApp(home: CalendarScreen()),
      );
    }

    testWidgets('renders TableCalendar and today agenda items', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify TableCalendar is mounted
      expect(find.byType(TableCalendar<CalendarAgendaItem>), findsOneWidget);

      // Verify header subtitle
      expect(find.text('Timeline & Day Planner'), findsOneWidget);

      // Verify Agenda item card is displayed
      expect(find.byType(AgendaItemCard), findsOneWidget);
      expect(find.text('Atlas Product Roadmap Review'), findsOneWidget);
      expect(find.text('HQ Conference Room'), findsOneWidget);

      // Clean unmount to drain Drift stream timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('tapping Event button opens EventDetailSheet modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the 'Event' button
      final eventBtn = find.text('Event');
      expect(eventBtn, findsOneWidget);
      await tester.tap(eventBtn);
      await tester.pumpAndSettle();

      // Verify EventDetailSheet is opened
      expect(find.byType(EventDetailSheet), findsOneWidget);
      expect(find.text('New Event'), findsOneWidget);
      expect(find.text('Event title'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Clean unmount to drain Drift stream timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
