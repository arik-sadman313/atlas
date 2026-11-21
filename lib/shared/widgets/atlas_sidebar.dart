import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/atlas_colors.dart';
import '../../core/theme/atlas_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../models/navigation_item.dart';
import '../presentation/command_palette/command_palette_modal.dart';
import 'atlas_scaffold.dart';

class AtlasSidebar extends ConsumerWidget {
  final String currentRoute;

  const AtlasSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentWorkspaceAsync = ref.watch(currentWorkspaceProvider);
    final favoriteNodesAsync = ref.watch(favoriteNodesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      width: AtlasSpacing.sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workspace Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AtlasSpacing.md,
              AtlasSpacing.lg,
              AtlasSpacing.md,
              AtlasSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AtlasColors.accentBlueSubtle,
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    border: Border.all(
                      color: AtlasColors.accentBlue.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.blur_on,
                      size: 18,
                      color: AtlasColors.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(width: AtlasSpacing.sm),
                Expanded(
                  child: currentWorkspaceAsync.when(
                    data: (ws) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATLAS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AtlasColors.accentBlue,
                          ),
                        ),
                        Text(
                          ws?.name ?? 'Personal Workspace',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AtlasColors.darkTextPrimary
                                : AtlasColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    loading: () =>
                        Text('Loading...', style: theme.textTheme.labelMedium),
                    error: (_, _) =>
                        Text('ATLAS', style: theme.textTheme.titleMedium),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu_open_rounded, size: 20),
                  tooltip: 'Collapse Sidebar (Ctrl+\\)',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(sidebarExpandedProvider.notifier).state = false;
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpacing.sm,
                vertical: AtlasSpacing.sm,
              ),
              children: [
                // Quick Command Palette Trigger
                Padding(
                  padding: const EdgeInsets.only(bottom: AtlasSpacing.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                    onTap: () => CommandPaletteModal.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AtlasColors.darkElevated
                            : AtlasColors.lightElevated,
                        borderRadius: BorderRadius.circular(
                          AtlasSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AtlasColors.darkBorder
                              : AtlasColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search / Command',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AtlasColors.darkBg
                                  : AtlasColors.lightBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark
                                    ? AtlasColors.darkBorderSubtle
                                    : AtlasColors.lightBorderSubtle,
                              ),
                            ),
                            child: Text(
                              'Ctrl+K',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                ...atlasNavigationItems.map((item) {
                  final isSelected = currentRoute.startsWith(item.route);
                  return _SidebarItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      if (!isSelected) {
                        context.go(item.route);
                      }
                    },
                  );
                }),

                const SizedBox(height: AtlasSpacing.md),
                const Divider(),
                const SizedBox(height: AtlasSpacing.sm),

                // Favorites Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtlasSpacing.md,
                    vertical: AtlasSpacing.xs,
                  ),
                  child: Text(
                    'FAVORITES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AtlasColors.darkTextMuted
                          : AtlasColors.lightTextMuted,
                    ),
                  ),
                ),

                // Favorites List
                favoriteNodesAsync.when(
                  data: (favorites) {
                    if (favorites.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AtlasSpacing.md,
                          vertical: AtlasSpacing.xs,
                        ),
                        child: Text(
                          'No starred pages yet',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AtlasColors.darkTextMuted
                                : AtlasColors.lightTextMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: favorites.map((node) {
                        final isSelected =
                            currentRoute == '/documents/${node.id}';
                        return _FavoriteItem(
                          title: node.title,
                          type: node.type,
                          isSelected: isSelected,
                          onTap: () {
                            context.go('/documents/${node.id}');
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const Divider(),

          // Footer with theme toggle and status
          Padding(
            padding: const EdgeInsets.all(AtlasSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Toggle Theme',
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : themeMode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.brightness_auto_outlined,
                    size: 18,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AtlasColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'v0.15.0 • Vaultite',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AtlasColors.accentBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final AtlasNavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fg = isSelected
        ? AtlasColors.accentBlue
        : (isDark ? AtlasColors.darkTextPrimary : AtlasColors.lightTextPrimary);
    final bg = isSelected
        ? (isDark ? AtlasColors.accentBlueSubtle : AtlasColors.accentBlueSubtle)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AtlasSpacing.md,
                vertical: AtlasSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: 18,
                    color: fg,
                  ),
                  const SizedBox(width: AtlasSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  final String title;
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavoriteItem({
    required this.title,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final icon = type == 'notebook'
        ? Icons.menu_book_outlined
        : Icons.article_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Material(
        color: isSelected ? AtlasColors.accentBlueSubtle : Colors.transparent,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpacing.md,
              vertical: AtlasSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
                const SizedBox(width: AtlasSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AtlasColors.darkTextPrimary
                          : AtlasColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
