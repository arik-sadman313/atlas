import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/atlas_colors.dart';
import '../../core/theme/atlas_spacing.dart';
import '../models/navigation_item.dart';
import '../presentation/command_palette/command_palette_modal.dart';
import 'atlas_sidebar.dart';

/// Global notifier to control sidebar expansion across the application
class SidebarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void setExpanded(bool value) => state = value;
  void update(bool Function(bool) updater) => state = updater(state);

  @override
  set state(bool value) => super.state = value;
}

final sidebarExpandedProvider = NotifierProvider<SidebarExpandedNotifier, bool>(
  SidebarExpandedNotifier.new,
);

class AtlasScaffold extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;
  final Widget? secondaryPane;

  const AtlasScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
    this.secondaryPane,
  });

  @override
  ConsumerState<AtlasScaffold> createState() => _AtlasScaffoldState();
}

class _AtlasScaffoldState extends ConsumerState<AtlasScaffold> {
  void _toggleSidebar() {
    ref.read(sidebarExpandedProvider.notifier).update((v) => !v);
  }

  void _showQuickCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    String selectedType = 'document';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark
                  ? AtlasColors.darkSurface
                  : AtlasColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
                side: BorderSide(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                  width: 1.0,
                ),
              ),
              title: Text(
                'Quick Create',
                style: theme.textTheme.headlineMedium,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'document',
                        label: Text('Document'),
                        icon: Icon(Icons.description_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'notebook',
                        label: Text('Notebook'),
                        icon: Icon(Icons.menu_book_outlined, size: 16),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) {
                      setDialogState(() {
                        selectedType = set.first;
                      });
                    },
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: selectedType == 'document'
                          ? 'e.g. Architecture Strategy'
                          : 'e.g. Meeting Notes',
                    ),
                    onSubmitted: (_) => _createAndNavigate(
                      context,
                      titleController.text,
                      selectedType,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _createAndNavigate(
                    dialogCtx,
                    titleController.text,
                    selectedType,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createAndNavigate(
    BuildContext dialogContext,
    String title,
    String type,
  ) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'node_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: type,
        title: cleanTitle,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }

    if (mounted) {
      if (type == 'document') {
        context.go('/documents/$newId');
      } else {
        context.go('/notebooks');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AtlasSpacing.desktopBreakpoint;
    final isTablet = width >= AtlasSpacing.mobileBreakpoint && !isDesktop;
    final isMobile = width < AtlasSpacing.mobileBreakpoint;
    final canGoBack = context.canPop();
    final isRootHome = widget.currentRoute == '/dashboard';

    // Android Predictive Back gesture support via PopScope
    return PopScope(
      canPop: !canGoBack && isRootHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else if (!isRootHome) {
          context.go('/dashboard');
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.backslash, control: true):
              _toggleSidebar,
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              _showQuickCreateDialog(context),
          const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
              context.go('/settings'),
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              CommandPaletteModal.show(context),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              CommandPaletteModal.show(context),
        },
        child: Focus(
          autofocus: true,
          child: isMobile
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context, isTablet: isTablet),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, {required bool isTablet}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarExpanded = ref.watch(sidebarExpandedProvider);
    final isNotebookEditor =
        widget.currentRoute.startsWith('/notebooks/') &&
        widget.currentRoute != '/notebooks';

    return Scaffold(
      body: Row(
        children: [
          // Collapsible Left Navigation Sidebar
          if (sidebarExpanded) AtlasSidebar(currentRoute: widget.currentRoute),

          // Collapsed Rail Toggle Button when sidebar is hidden (hidden in notebook editor for 100% canvas)
          if (!sidebarExpanded && !isNotebookEditor)
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkSurface
                    : AtlasColors.lightSurface,
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AtlasSpacing.md),
                  IconButton(
                    tooltip: 'Expand Sidebar (Ctrl+\\)',
                    icon: const Icon(Icons.menu_open, size: 20),
                    onPressed: _toggleSidebar,
                  ),
                  const Divider(),
                  ...atlasNavigationItems.map((item) {
                    final isSelected = widget.currentRoute.startsWith(
                      item.route,
                    );
                    return IconButton(
                      tooltip: item.label,
                      icon: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 20,
                        color: isSelected ? AtlasColors.accentBlue : null,
                      ),
                      onPressed: () {
                        if (!isSelected) {
                          context.go(item.route);
                        }
                      },
                    );
                  }),
                ],
              ),
            ),

          // Optional Secondary Outline Pane (for 3-Column views)
          if (widget.secondaryPane != null) ...[
            Container(
              width: AtlasSpacing.secondaryPaneWidth,
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkElevated
                    : AtlasColors.lightElevated,
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                    width: 1.0,
                  ),
                ),
              ),
              child: widget.secondaryPane!,
            ),
          ],

          // Main Content Workspace
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Map active route to navigation bar index
    int selectedIndex = 0;
    if (widget.currentRoute.startsWith('/notebooks')) {
      selectedIndex = 1;
    } else if (widget.currentRoute.startsWith('/documents')) {
      selectedIndex = 2;
    } else if (widget.currentRoute.startsWith('/tasks')) {
      selectedIndex = 3;
    } else if (widget.currentRoute.startsWith('/search')) {
      selectedIndex = 4;
    }

    return Scaffold(
      body: widget.child,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => CommandPaletteModal.show(context),
        tooltip: 'Command Palette (Ctrl+K)',
        child: const Icon(Icons.terminal, size: 18),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/notebooks');
              break;
            case 2:
              context.go('/documents');
              break;
            case 3:
              context.go('/tasks');
              break;
            case 4:
              context.go('/search');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Notebooks',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
