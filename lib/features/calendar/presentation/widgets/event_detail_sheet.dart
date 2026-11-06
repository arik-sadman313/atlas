import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class EventDetailSheet extends ConsumerStatefulWidget {
  final CalendarEventEntry? event;
  final DateTime initialDate;

  const EventDetailSheet({super.key, this.event, required this.initialDate});

  static Future<void> show(
    BuildContext context, {
    CalendarEventEntry? event,
    required DateTime initialDate,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          EventDetailSheet(event: event, initialDate: initialDate),
    );
  }

  @override
  ConsumerState<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends ConsumerState<EventDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _isAllDay;
  late String _selectedColor;
  String? _nodeId;

  static const List<String> _eventColors = [
    '#3B82F6', // Blue
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#10B981', // Green
    '#06B6D4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _locationController = TextEditingController(text: ev?.location ?? '');

    if (ev != null) {
      _startDate = DateTime(
        ev.startTime.year,
        ev.startTime.month,
        ev.startTime.day,
      );
      _startTime = TimeOfDay(
        hour: ev.startTime.hour,
        minute: ev.startTime.minute,
      );
      _endDate = DateTime(ev.endTime.year, ev.endTime.month, ev.endTime.day);
      _endTime = TimeOfDay(hour: ev.endTime.hour, minute: ev.endTime.minute);
      _isAllDay = ev.isAllDay;
      _selectedColor = ev.colorHex ?? _eventColors[0];
      _nodeId = ev.nodeId;
    } else {
      final now = DateTime.now();
      final day = widget.initialDate;
      final startHour = now.hour < 23 ? now.hour + 1 : 10;
      _startDate = DateTime(day.year, day.month, day.day);
      _startTime = TimeOfDay(hour: startHour, minute: 0);
      _endDate = DateTime(day.year, day.month, day.day);
      _endTime = TimeOfDay(hour: (startHour + 1) % 24, minute: 0);
      _isAllDay = false;
      _selectedColor = _eventColors[0];
      _nodeId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime get _computedStart {
    if (_isAllDay) {
      return DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        0,
        0,
        0,
      );
    }
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  DateTime get _computedEnd {
    if (_isAllDay) {
      return DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    }
    return DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _endTime = TimeOfDay(
          hour: (picked.hour + 1) % 24,
          minute: picked.minute,
        );
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    var start = _computedStart;
    var end = _computedEnd;
    if (end.isBefore(start)) {
      end = start.add(const Duration(hours: 1));
    }

    final workspace = ref.read(currentWorkspaceProvider);
    final workspaceId = workspace.value?.id ?? 'default';
    final repo = ref.read(calendarRepositoryProvider);

    if (widget.event == null) {
      await repo.createEvent(
        workspaceId: workspaceId,
        title: title,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        startTime: start,
        endTime: end,
        isAllDay: _isAllDay,
        colorHex: _selectedColor,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        nodeId: _nodeId,
      );
    } else {
      final updated = widget.event!.copyWith(
        title: title,
        description: Value(
          _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
        ),
        startTime: start,
        endTime: end,
        isAllDay: _isAllDay,
        colorHex: Value(_selectedColor),
        location: Value(
          _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        ),
        nodeId: Value(_nodeId),
      );
      await repo.updateEvent(updated);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${widget.event!.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AtlasColors.priorityP1,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(calendarRepositoryProvider);
      await repo.deleteEvent(widget.event!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AtlasColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final workspace = ref.watch(currentWorkspaceProvider);
    final workspaceId = workspace.value?.id ?? 'default';
    final nodesAsync = ref
        .watch(nodesDaoProvider)
        .watchRecentNodes(workspaceId);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AtlasSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(_selectedColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.event == null ? 'New Event' : 'Edit Event',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.event != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AtlasColors.priorityP1,
                      ),
                      tooltip: 'Delete Event',
                      onPressed: _delete,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AtlasSpacing.md),

              // Title Field
              TextField(
                controller: _titleController,
                autofocus: widget.event == null,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Event title',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AtlasSpacing.md),
              Divider(
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
              ),
              const SizedBox(height: AtlasSpacing.md),

              // All-Day Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All-day'),
                value: _isAllDay,
                onChanged: (val) => setState(() => _isAllDay = val),
              ),

              // Date & Time Selectors
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat.yMMMd().format(_startDate)),
                      onPressed: _pickStartDate,
                    ),
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(_startTime.format(context)),
                        onPressed: _pickStartTime,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_available, size: 16),
                      label: Text(DateFormat.yMMMd().format(_endDate)),
                      onPressed: _pickEndDate,
                    ),
                  ),
                  if (!_isAllDay) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_filled, size: 16),
                        label: Text(_endTime.format(context)),
                        onPressed: _pickEndTime,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AtlasSpacing.md),

              // Location Field
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                  hintText: 'Location / Video link',
                  filled: true,
                  fillColor: isDark
                      ? AtlasColors.darkElevated
                      : AtlasColors.lightElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: AtlasSpacing.md),

              // Color Swatches
              Text(
                'Color Tag',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _eventColors.map((hex) {
                  final color = _parseColor(hex);
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2.5,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AtlasSpacing.md),

              // Linked Note Picker
              StreamBuilder<List<NodeEntry>>(
                stream: nodesAsync,
                builder: (context, snapshot) {
                  final nodes = snapshot.data ?? [];
                  return DropdownButtonFormField<String?>(
                    initialValue: _nodeId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.link, size: 18),
                      labelText: 'Linked Note',
                      filled: true,
                      fillColor: isDark
                          ? AtlasColors.darkElevated
                          : AtlasColors.lightElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No linked note'),
                      ),
                      ...nodes.map(
                        (n) => DropdownMenuItem<String?>(
                          value: n.id,
                          child: Text(
                            n.title.isEmpty ? 'Untitled Note' : n.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _nodeId = val),
                  );
                },
              ),
              const SizedBox(height: AtlasSpacing.md),

              // Description Field
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notes or agenda...',
                  filled: true,
                  fillColor: isDark
                      ? AtlasColors.darkElevated
                      : AtlasColors.lightElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: AtlasSpacing.xl),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      widget.event == null ? 'Create Event' : 'Save Changes',
                    ),
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
