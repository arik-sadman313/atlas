import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/atlas_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final currentWorkspaceAsync = ref.watch(currentWorkspaceProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AtlasSpacing.xl),
          children: [
            Text('Settings', style: theme.textTheme.displayMedium),
            const SizedBox(height: AtlasSpacing.xs),
            Text(
              'Application preferences and workspace diagnostics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AtlasColors.darkTextSecondary
                    : AtlasColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AtlasSpacing.xl),

            // Section 1: Appearance
            Text(
              'APPEARANCE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AtlasColors.darkTextMuted
                    : AtlasColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            AtlasCard(
              child: RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  }
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('System Default'),
                      subtitle: Text('Matches your operating system theme'),
                      value: ThemeMode.system,
                    ),
                    Divider(),
                    RadioListTile<ThemeMode>(
                      title: Text('Light Theme'),
                      subtitle: Text('Clean high-contrast daytime interface'),
                      value: ThemeMode.light,
                    ),
                    Divider(),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark Theme'),
                      subtitle: Text(
                        'OLED-friendly low-strain charcoal surface',
                      ),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AtlasSpacing.xl),

            // Section 2: Workspace Info
            Text(
              'ACTIVE WORKSPACE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AtlasColors.darkTextMuted
                    : AtlasColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            AtlasCard(
              child: currentWorkspaceAsync.when(
                data: (ws) => Column(
                  children: [
                    _InfoRow(
                      label: 'Workspace Name',
                      value: ws?.name ?? 'Personal Workspace',
                    ),
                    const Divider(),
                    _InfoRow(
                      label: 'Identifier',
                      value: ws?.id ?? 'workspace-default-primary',
                    ),
                    const Divider(),
                    _InfoRow(
                      label: 'Local Vault Status',
                      value: 'Local-First (Offline Ready)',
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AtlasSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Text('Error: $err'),
              ),
            ),

            const SizedBox(height: AtlasSpacing.xl),

            // Section 3: Architecture & Diagnostics
            Text(
              'PLATFORM & ARCHITECTURE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AtlasColors.darkTextMuted
                    : AtlasColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: AtlasSpacing.sm),
            AtlasCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Target Platform',
                    value: Platform.operatingSystem.toUpperCase(),
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Database Engine',
                    value: 'SQLite 3 (WAL mode enabled)',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Storage Model',
                    value: 'Content-Addressable Storage (CAS / SHA-256)',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'State Management',
                    value: 'Riverpod 3.x Unidirectional Flow',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Milestone',
                    value: 'M1: Core Foundation & Shell',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AtlasSpacing.md,
        vertical: AtlasSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AtlasColors.darkTextSecondary
                  : AtlasColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
