import '../../../../core/database/app_database.dart';

enum CalendarItemType { event, task }

class CalendarAgendaItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? colorHex;
  final String? location;
  final String? nodeId;
  final CalendarItemType type;
  final bool isCompleted;
  final int? priority;
  final CalendarEventEntry? rawEvent;
  final TaskEntry? rawTask;

  const CalendarAgendaItem({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.colorHex,
    this.location,
    this.nodeId,
    required this.type,
    this.isCompleted = false,
    this.priority,
    this.rawEvent,
    this.rawTask,
  });

  factory CalendarAgendaItem.fromEvent(CalendarEventEntry event) {
    return CalendarAgendaItem(
      id: event.id,
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      isAllDay: event.isAllDay,
      colorHex: event.colorHex,
      location: event.location,
      nodeId: event.nodeId,
      type: CalendarItemType.event,
      rawEvent: event,
    );
  }

  factory CalendarAgendaItem.fromTask(TaskEntry task) {
    return CalendarAgendaItem(
      id: task.id,
      title: task.title,
      description: task.description,
      startTime: task.dueDate ?? DateTime.now(),
      endTime: null,
      isAllDay: !task.hasTime,
      colorHex: task.priority == 1
          ? '#EF4444' // Red
          : task.priority == 2
          ? '#F59E0B' // Amber
          : task.priority == 3
          ? '#3B82F6' // Blue
          : '#10B981', // Green
      nodeId: task.nodeId,
      type: CalendarItemType.task,
      isCompleted: task.isCompleted,
      priority: task.priority,
      rawTask: task,
    );
  }
}
