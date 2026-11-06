import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';

class HabitEditDialog extends ConsumerStatefulWidget {
  final HabitEntry? habit;

  const HabitEditDialog({super.key, this.habit});

  static Future<void> show(BuildContext context, {HabitEntry? habit}) {
    return showDialog(
      context: context,
      builder: (context) => HabitEditDialog(habit: habit),
    );
  }

  @override
  ConsumerState<HabitEditDialog> createState() => _HabitEditDialogState();
}

class _HabitEditDialogState extends ConsumerState<HabitEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _selectedColorHex;
  late String _selectedIcon;
  late String _selectedFrequency;
  bool _isSaving = false;

  static const List<String> _palette = [
    '#10B981', // Sage
    '#3B82F6', // Blue
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#F43F5E', // Rose
    '#06B6D4', // Cyan
  ];

  static const List<(String, IconData)> _availableIcons = [
    ('check_circle', Icons.check_circle_outline),
    ('fitness_center', Icons.fitness_center),
    ('menu_book', Icons.menu_book_outlined),
    ('water_drop', Icons.water_drop_outlined),
    ('self_improvement', Icons.self_improvement),
    ('directions_run', Icons.directions_run),
    ('code', Icons.code),
    ('edit_note', Icons.edit_note),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _selectedColorHex = widget.habit?.colorHex ?? _palette.first;
    _selectedIcon = widget.habit?.icon ?? _availableIcons.first.$1;
    _selectedFrequency = widget.habit?.frequency ?? 'daily';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AtlasColors.accentSage;
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);
    final repo = ref.read(habitRepositoryProvider);
    final workspaceId = ref.read(currentWorkspaceIdProvider);

    try {
      if (widget.habit == null) {
        await repo.createHabit(
          workspaceId: workspaceId,
          title: title,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          colorHex: _selectedColorHex,
          icon: _selectedIcon,
          frequency: _selectedFrequency,
        );
      } else {
        await repo.updateHabit(
          widget.habit!.copyWith(
            title: title,
            description: Value(
              _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
            ),
            colorHex: _selectedColorHex,
            icon: Value(_selectedIcon),
            frequency: _selectedFrequency,
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.habit == null) return;
    final repo = ref.read(habitRepositoryProvider);
    await repo.deleteHabit(widget.habit!.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.habit != null;

    return AlertDialog(
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
        side: BorderSide(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          width: 1.0,
        ),
      ),
      title: Text(
        isEditing ? 'Edit Habit' : 'New Habit',
        style: theme.textTheme.headlineMedium,
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Habit Title',
                  hintText: 'e.g. Morning Meditation, Read 20 mins',
                ),
              ),
              const SizedBox(height: AtlasSpacing.md),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g. Quiet craft reflection before work',
                ),
              ),
              const SizedBox(height: AtlasSpacing.lg),

              // Frequency Selector
              Text('Frequency', style: theme.textTheme.labelMedium),
              const SizedBox(height: AtlasSpacing.xs),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ],
                selected: {_selectedFrequency},
                onSelectionChanged: (set) {
                  setState(() => _selectedFrequency = set.first);
                },
              ),
              const SizedBox(height: AtlasSpacing.lg),

              // Color Palette Picker
              Text('Color Accent', style: theme.textTheme.labelMedium),
              const SizedBox(height: AtlasSpacing.xs),
              Wrap(
                spacing: AtlasSpacing.sm,
                children: _palette.map((hex) {
                  final isSelected = hex == _selectedColorHex;
                  final color = _parseColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
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
              const SizedBox(height: AtlasSpacing.lg),

              // Icon Picker
              Text('Icon', style: theme.textTheme.labelMedium),
              const SizedBox(height: AtlasSpacing.xs),
              Wrap(
                spacing: AtlasSpacing.xs,
                runSpacing: AtlasSpacing.xs,
                children: _availableIcons.map((pair) {
                  final isSelected = pair.$1 == _selectedIcon;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    onTap: () => setState(() => _selectedIcon = pair.$1),
                    child: Container(
                      padding: const EdgeInsets.all(AtlasSpacing.xs),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _parseColor(_selectedColorHex)
                                  .withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? _parseColor(_selectedColorHex)
                              : (isDark
                                    ? AtlasColors.darkBorderSubtle
                                    : AtlasColors.lightBorderSubtle),
                        ),
                      ),
                      child: Icon(
                        pair.$2,
                        size: 20,
                        color: isSelected
                            ? _parseColor(_selectedColorHex)
                            : (isDark
                                  ? AtlasColors.darkTextSecondary
                                  : AtlasColors.lightTextSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: AtlasColors.accentRose,
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(isEditing ? 'Save Changes' : 'Create Habit'),
        ),
      ],
    );
  }
}
