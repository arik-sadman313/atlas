import 'package:atlas/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test(
      'generateNotificationId produces consistent and valid 31-bit integer',
      () {
        const id1 = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
        const id2 = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

        final hash1 = service.generateNotificationId(id1);
        final hash1Again = service.generateNotificationId(id1);
        final hash2 = service.generateNotificationId(id2);

        // Deterministic
        expect(hash1, equals(hash1Again));
        // Non-negative 31-bit signed integer
        expect(hash1, greaterThanOrEqualTo(0));
        expect(hash1, lessThan(0x7FFFFFFF));

        // Different inputs yield different outputs (with high probability)
        expect(hash1, isNot(equals(hash2)));
      },
    );

    test(
      'scheduleTaskReminder degrades gracefully when uninitialized',
      () async {
        // In headless unit test environment, native plugin is uninitialized
        expect(service.isInitialized, isFalse);

        final future = service.scheduleTaskReminder(
          taskId: 'test-task-1',
          title: 'Submit Project Proposal',
          dueDate: DateTime.now().add(const Duration(hours: 2)),
          reminderMinutesBefore: 15,
        );

        // Must complete without throwing unhandled platform exceptions
        await expectLater(future, completes);
      },
    );

    test(
      'scheduleEventReminder degrades gracefully when uninitialized',
      () async {
        expect(service.isInitialized, isFalse);

        final future = service.scheduleEventReminder(
          eventId: 'test-event-1',
          title: 'Team Retrospective',
          startTime: DateTime.now().add(const Duration(days: 1)),
          reminderMinutesBefore: 10,
        );

        await expectLater(future, completes);
      },
    );

    test(
      'cancelReminder and cancelAllReminders do not throw when uninitialized',
      () async {
        await expectLater(service.cancelReminder('task-1'), completes);
        await expectLater(service.cancelAllReminders(), completes);
      },
    );
  });
}
