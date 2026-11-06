import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/habits/presentation/widgets/habit_edit_dialog.dart';
import 'command_action.dart';

class CommandRegistry {
  static List<CommandAction> getActions() {
    return [
      // Navigation
      CommandAction(
        id: 'nav-dashboard',
        label: 'Jump to Dashboard',
        category: 'Navigation',
        icon: Icons.dashboard_outlined,
        keywords: ['home', 'overview', 'dashboard', 'start'],
        shortcut: 'G D',
        run: (context, ref) => context.go('/dashboard'),
      ),
      CommandAction(
        id: 'nav-notebooks',
        label: 'Jump to Notebooks',
        category: 'Navigation',
        icon: Icons.menu_book_outlined,
        keywords: ['notebooks', 'canvas', 'handwriting', 'ink', 'draw'],
        shortcut: 'G N',
        run: (context, ref) => context.go('/notebooks'),
      ),
      CommandAction(
        id: 'nav-documents',
        label: 'Jump to Documents',
        category: 'Navigation',
        icon: Icons.description_outlined,
        keywords: ['documents', 'notes', 'pages', 'write', 'rich text'],
        shortcut: 'G P',
        run: (context, ref) => context.go('/documents'),
      ),
      CommandAction(
        id: 'nav-tasks',
        label: 'Jump to Tasks',
        category: 'Navigation',
        icon: Icons.check_circle_outline,
        keywords: ['tasks', 'todo', 'agenda', 'inbox', 'priorities'],
        shortcut: 'G T',
        run: (context, ref) => context.go('/tasks'),
      ),
      CommandAction(
        id: 'nav-calendar',
        label: 'Jump to Calendar',
        category: 'Navigation',
        icon: Icons.calendar_today_outlined,
        keywords: ['calendar', 'schedule', 'events', 'month', 'agenda'],
        shortcut: 'G C',
        run: (context, ref) => context.go('/calendar'),
      ),
      CommandAction(
        id: 'nav-graph',
        label: 'Open Knowledge Graph',
        category: 'Navigation',
        icon: Icons.hub_outlined,
        keywords: [
          'graph',
          'network',
          'links',
          'connections',
          'visualize',
          'obsidian',
        ],
        shortcut: 'G G',
        run: (context, ref) => context.go('/graph'),
      ),
      CommandAction(
        id: 'nav-search',
        label: 'Search Vault',
        category: 'Navigation',
        icon: Icons.search_outlined,
        keywords: ['search', 'find', 'lookup', 'query', 'filter'],
        shortcut: 'Ctrl+F',
        run: (context, ref) => context.go('/search'),
      ),
      CommandAction(
        id: 'nav-settings',
        label: 'Jump to Settings',
        category: 'Navigation',
        icon: Icons.settings_outlined,
        keywords: ['settings', 'preferences', 'vault', 'config'],
        shortcut: 'Ctrl+,',
        run: (context, ref) => context.go('/settings'),
      ),

      // Creation Actions
      CommandAction(
        id: 'create-document',
        label: 'New Document',
        category: 'Create',
        icon: Icons.add_circle_outline,
        keywords: ['new doc', 'create page', 'note', 'document', 'write'],
        shortcut: 'Ctrl+N',
        run: (context, ref) async {
          final workspaceId = ref.read(currentWorkspaceIdProvider);
          final nodesDao = ref.read(nodesDaoProvider);
          final now = DateTime.now();
          final newId = 'node_${DateTime.now().millisecondsSinceEpoch}';

          await nodesDao.createNode(
            NodesCompanion.insert(
              id: newId,
              workspaceId: workspaceId,
              type: 'document',
              title: 'Untitled Document',
              createdAt: now,
              updatedAt: now,
            ),
          );

          if (context.mounted) {
            context.go('/documents/$newId');
          }
        },
      ),
      CommandAction(
        id: 'create-notebook',
        label: 'New Notebook',
        category: 'Create',
        icon: Icons.draw_outlined,
        keywords: ['new notebook', 'canvas', 'sketch', 'draw', 'ink'],
        run: (context, ref) async {
          final workspaceId = ref.read(currentWorkspaceIdProvider);
          final nodesDao = ref.read(nodesDaoProvider);
          final now = DateTime.now();
          final newId = 'node_${DateTime.now().millisecondsSinceEpoch}';

          await nodesDao.createNode(
            NodesCompanion.insert(
              id: newId,
              workspaceId: workspaceId,
              type: 'notebook',
              title: 'Untitled Notebook',
              createdAt: now,
              updatedAt: now,
            ),
          );

          if (context.mounted) {
            context.go('/notebooks');
          }
        },
      ),
      CommandAction(
        id: 'create-task',
        label: 'New Task',
        category: 'Create',
        icon: Icons.add_task,
        keywords: ['new task', 'add todo', 'task', 'reminder'],
        run: (context, ref) async {
          final workspaceId = ref.read(currentWorkspaceIdProvider);
          final taskRepo = ref.read(taskRepositoryProvider);
          await taskRepo.createTask(
            workspaceId: workspaceId,
            title: 'New Quick Task',
            dueDate: DateTime.now(),
          );
          if (context.mounted) {
            context.go('/tasks');
          }
        },
      ),
      CommandAction(
        id: 'journal-today',
        label: "Today's Journal",
        category: 'Create',
        icon: Icons.auto_stories_outlined,
        keywords: ['journal', 'daily reflection', 'today', 'morning pages'],
        run: (context, ref) async {
          final workspaceId = ref.read(currentWorkspaceIdProvider);
          final journalRepo = ref.read(journalRepositoryProvider);
          final nodeId = await journalRepo.getOrCreateTodayJournalNode(
            workspaceId,
          );
          if (context.mounted) {
            context.go('/documents/$nodeId');
          }
        },
      ),
      CommandAction(
        id: 'create-habit',
        label: 'New Habit',
        category: 'Create',
        icon: Icons.repeat,
        keywords: ['new habit', 'routine', 'streak', 'tracker'],
        run: (context, ref) {
          HabitEditDialog.show(context);
        },
      ),

      // System Actions
      CommandAction(
        id: 'sys-toggle-theme',
        label: 'Toggle Dark / Light Theme',
        category: 'System',
        icon: Icons.brightness_6_outlined,
        keywords: ['theme', 'dark', 'light', 'mode', 'color scheme'],
        run: (context, ref) {
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
      ),
      CommandAction(
        id: 'sys-open-graph',
        label: 'Open Knowledge Graph',
        category: 'System',
        icon: Icons.hub,
        keywords: ['graph', 'nodes', 'edges', 'relations', 'backlinks'],
        run: (context, ref) => context.go('/graph'),
      ),
    ];
  }
}
