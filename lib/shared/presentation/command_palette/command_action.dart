import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommandAction {
  final String id;
  final String label;
  final String category; // 'Navigation', 'Create', 'System'
  final IconData icon;
  final List<String> keywords;
  final String? shortcut;
  final void Function(BuildContext context, WidgetRef ref) run;

  const CommandAction({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    this.keywords = const [],
    this.shortcut,
    required this.run,
  });
}
