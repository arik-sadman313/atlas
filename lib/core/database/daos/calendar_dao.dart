import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/calendar_events_table.dart';
import '../tables/nodes_table.dart';
import '../tables/tasks_table.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(tables: [CalendarEvents, Tasks, Nodes])
class CalendarDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarDaoMixin {
  CalendarDao(super.db);

  Stream<List<CalendarEventEntry>> watchAllEvents(String workspaceId) {
    return (select(calendarEvents)
          ..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) & tbl.deletedAt.isNull(),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<List<CalendarEventEntry>> watchEventsForRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    return (select(calendarEvents)
          ..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.deletedAt.isNull() &
                tbl.endTime.isBiggerOrEqualValue(start) &
                tbl.startTime.isSmallerOrEqualValue(end),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.title, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<CalendarEventEntry>> getEventsForRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    return (select(calendarEvents)
          ..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) &
                tbl.deletedAt.isNull() &
                tbl.endTime.isBiggerOrEqualValue(start) &
                tbl.startTime.isSmallerOrEqualValue(end),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.title, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Stream<List<CalendarEventEntry>> watchEventsForDay(
    String workspaceId,
    DateTime day,
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return watchEventsForRange(workspaceId, startOfDay, endOfDay);
  }

  Future<List<CalendarEventEntry>> getEventsForDay(
    String workspaceId,
    DateTime day,
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return getEventsForRange(workspaceId, startOfDay, endOfDay);
  }

  Stream<List<CalendarEventEntry>> watchEventsForNode(String nodeId) {
    return (select(calendarEvents)
          ..where((tbl) => tbl.nodeId.equals(nodeId) & tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<CalendarEventEntry?> getEvent(String id) {
    return (select(calendarEvents)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<void> createEvent(CalendarEventsCompanion event) {
    return into(calendarEvents).insert(event);
  }

  Future<bool> updateEvent(CalendarEventsCompanion event) {
    return update(calendarEvents).replace(event);
  }

  Future<int> deleteEvent(String id, {bool hardDelete = false}) {
    if (hardDelete) {
      return (delete(calendarEvents)..where((tbl) => tbl.id.equals(id))).go();
    }
    final now = DateTime.now().toUtc();
    return (update(calendarEvents)..where((tbl) => tbl.id.equals(id))).write(
      CalendarEventsCompanion(
        deletedAt: Value(now),
        clientModifiedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
