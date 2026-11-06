import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/atlas_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;
  bool _isExportingVault = false;
  bool _isRestoringVault = false;
  bool _isExportingMarkdown = false;
  bool _isExportingPdf = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final currentWorkspaceAsync = ref.watch(currentWorkspaceProvider);
    final currentWorkspaceId = ref.watch(currentWorkspaceIdProvider);
    final deviceIdAsync = ref.watch(deviceIdFutureProvider);
    final deviceNameAsync = ref.watch(deviceNameFutureProvider);
    final syncDirAsync = ref.watch(syncDirectoryFutureProvider);
    final syncHistoryAsync = ref.watch(syncHistoryStreamProvider);
    final storageMetricsAsync = ref.watch(storageMetricsProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.all(AtlasSpacing.xl),
              children: [
                Text('Settings', style: theme.textTheme.displayMedium),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  'Application preferences, vault synchronization, and storage diagnostics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AtlasColors.darkTextSecondary
                        : AtlasColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xl),

                // Section 1: Appearance
                _buildSectionHeader(context, 'APPEARANCE'),
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
                          subtitle: Text(
                            'Clean high-contrast daytime interface',
                          ),
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

                // Section 2: Device Identity
                _buildSectionHeader(context, 'DEVICE IDENTITY'),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasCard(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AtlasSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Device Name',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AtlasColors.darkTextSecondary
                                        : AtlasColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: AtlasSpacing.xxs),
                                deviceNameAsync.when(
                                  data: (name) => Text(
                                    name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  loading: () => const Text('Loading...'),
                                  error: (_, _) => const Text('Unknown'),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit Device Name',
                              onPressed: () => _showEditDeviceNameDialog(
                                context,
                                deviceNameAsync.value ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Client ID',
                        value: deviceIdAsync.value ?? 'Loading...',
                        isMonospace: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AtlasSpacing.xl),

                // Section 3: Local-First Synchronization
                _buildSectionHeader(context, 'LOCAL-FIRST SYNCHRONIZATION'),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AtlasSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Designated Sync Directory',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: AtlasSpacing.xs),
                            syncDirAsync.when(
                              data: (dirPath) => Text(
                                dirPath != null && dirPath.isNotEmpty
                                    ? dirPath
                                    : 'Not configured (Operating in standalone mode)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: dirPath == null
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  color: dirPath != null
                                      ? (isDark
                                            ? AtlasColors.darkTextPrimary
                                            : AtlasColors.lightTextPrimary)
                                      : (isDark
                                            ? AtlasColors.darkTextMuted
                                            : AtlasColors.lightTextMuted),
                                ),
                              ),
                              loading: () => const Text('Loading...'),
                              error: (_, _) =>
                                  const Text('Error loading folder'),
                            ),
                            const SizedBox(height: AtlasSpacing.md),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Choose Folder'),
                                  onPressed: _pickSyncDirectory,
                                ),
                                const SizedBox(width: AtlasSpacing.sm),
                                if (syncDirAsync.value != null &&
                                    syncDirAsync.value!.isNotEmpty) ...[
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Clear'),
                                    onPressed: _clearSyncDirectory,
                                  ),
                                  const SizedBox(width: AtlasSpacing.sm),
                                ],
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AtlasColors.accentBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: _isSyncing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(Icons.sync),
                                  label: Text(
                                    _isSyncing ? 'Syncing...' : 'Sync Now',
                                  ),
                                  onPressed: _isSyncing ? null : _runSync,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AtlasSpacing.md,
                          vertical: AtlasSpacing.sm,
                        ),
                        child: Text(
                          'RECENT SYNC HISTORY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AtlasColors.darkTextMuted
                                : AtlasColors.lightTextMuted,
                          ),
                        ),
                      ),
                      syncHistoryAsync.when(
                        data: (history) {
                          if (history.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AtlasSpacing.md),
                              child: Text(
                                'No sync runs recorded yet.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            );
                          }
                          return Column(
                            children: history.take(3).map((entry) {
                              final isSuccess =
                                  entry.status.toLowerCase() == 'completed';
                              final statusColor = isSuccess
                                  ? Colors.green
                                  : (entry.status.toLowerCase() == 'in_progress'
                                        ? Colors.orange
                                        : Colors.red);
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isSuccess ? Icons.check_circle : Icons.error,
                                  color: statusColor,
                                  size: 20,
                                ),
                                title: Text(
                                  '${entry.syncType.toUpperCase()} - ${entry.status}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Exported: ${entry.recordsExported} | Imported: ${entry.recordsImported} | Blobs: ${entry.blobsTransferred}'
                                  '${entry.errorMessage != null ? '\nError: ${entry.errorMessage}' : ''}',
                                ),
                                trailing: Text(
                                  _formatTime(entry.syncStartedAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AtlasSpacing.md),
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(AtlasSpacing.md),
                          child: Text('Error: $e'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AtlasSpacing.xl),

                // Section 4: Vault Archive (.atlas_vault)
                _buildSectionHeader(context, 'VAULT ARCHIVE (.atlas_vault)'),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export or restore a complete offline vault snapshot including SQLite relational data, CAS content blobs, and a cryptographically verified SHA-256 manifest.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        Wrap(
                          spacing: AtlasSpacing.sm,
                          runSpacing: AtlasSpacing.sm,
                          children: [
                            ElevatedButton.icon(
                              icon: _isExportingVault
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.archive),
                              label: Text(
                                _isExportingVault
                                    ? 'Exporting...'
                                    : 'Export Full Vault (.atlas_vault)',
                              ),
                              onPressed: _isExportingVault
                                  ? null
                                  : () => _exportVault(currentWorkspaceId),
                            ),
                            OutlinedButton.icon(
                              icon: _isRestoringVault
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.unarchive),
                              label: Text(
                                _isRestoringVault
                                    ? 'Restoring...'
                                    : 'Restore Vault (.atlas_vault)',
                              ),
                              onPressed: _isRestoringVault
                                  ? null
                                  : _restoreVault,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AtlasSpacing.xl),

                // Section 5: Universal Portability & Bulk Export
                _buildSectionHeader(context, 'DATA PORTABILITY & BULK EXPORT'),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export your knowledge base into vendor-neutral standard formats for seamless portability into Obsidian, Logseq, or local PDF viewers.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AtlasColors.darkTextSecondary
                                : AtlasColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        Wrap(
                          spacing: AtlasSpacing.sm,
                          runSpacing: AtlasSpacing.sm,
                          children: [
                            ElevatedButton.icon(
                              icon: _isExportingMarkdown
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.description),
                              label: Text(
                                _isExportingMarkdown
                                    ? 'Exporting...'
                                    : 'Export Notes to Markdown (.zip)',
                              ),
                              onPressed: _isExportingMarkdown
                                  ? null
                                  : () => _exportMarkdown(currentWorkspaceId),
                            ),
                            ElevatedButton.icon(
                              icon: _isExportingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: Text(
                                _isExportingPdf
                                    ? 'Exporting...'
                                    : 'Export Notebooks to PDF (.zip)',
                              ),
                              onPressed: _isExportingPdf
                                  ? null
                                  : () =>
                                        _exportNotebooksPdf(currentWorkspaceId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AtlasSpacing.xl),

                // Section 6: Storage Metrics
                _buildSectionHeader(context, 'STORAGE BREAKDOWN & METRICS'),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasCard(
                  child: storageMetricsAsync.when(
                    data: (metrics) => Column(
                      children: [
                        _InfoRow(
                          label: 'SQLite Database',
                          value: metrics.formattedDatabaseSize,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Content-Addressable Storage (CAS)',
                          value:
                              '${metrics.formattedCasSize} (${metrics.casBlobCount} blobs)',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Total Vault Storage',
                          value: metrics.formattedTotalSize,
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Tracked Attachments',
                          value: '${metrics.attachmentsCount}',
                        ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AtlasSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(AtlasSpacing.md),
                      child: Text('Error loading storage metrics: $e'),
                    ),
                  ),
                ),

                const SizedBox(height: AtlasSpacing.xl),

                // Section 7: Workspace Info
                _buildSectionHeader(context, 'ACTIVE WORKSPACE'),
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
                          value: ws?.id ?? currentWorkspaceId,
                        ),
                        const Divider(),
                        const _InfoRow(
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

                // Section 8: Platform & Architecture
                _buildSectionHeader(context, 'PLATFORM & ARCHITECTURE'),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Target Platform',
                        value: Platform.operatingSystem.toUpperCase(),
                      ),
                      const Divider(),
                      const _InfoRow(
                        label: 'Database Engine',
                        value: 'SQLite 3 (WAL mode enabled)',
                      ),
                      const Divider(),
                      const _InfoRow(
                        label: 'Storage Model',
                        value: 'Content-Addressable Storage (CAS / SHA-256)',
                      ),
                      const Divider(),
                      const _InfoRow(
                        label: 'Sync Protocol',
                        value: 'Folder-Based LWW Changesets + CAS Blobs',
                      ),
                      const Divider(),
                      const _InfoRow(
                        label: 'Archive Format',
                        value: 'ATLAS Vault Archive (.atlas_vault v1.0)',
                      ),
                      const Divider(),
                      const _InfoRow(
                        label: 'State Management',
                        value: 'Riverpod 3.x Unidirectional Flow',
                      ),
                      const Divider(),
                      const _InfoRow(
                        label: 'Milestone',
                        value:
                            'M8: Local-First Sync, Vault Portability & Backup',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
        color: isDark ? AtlasColors.darkTextMuted : AtlasColors.lightTextMuted,
      ),
    );
  }

  Future<void> _pickSyncDirectory() async {
    try {
      final selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Sync Directory',
      );
      if (selectedPath != null && selectedPath.isNotEmpty) {
        await ref
            .read(deviceIdentityServiceProvider)
            .setSyncDirectoryPath(selectedPath);
        ref.invalidate(syncDirectoryFutureProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync directory set to $selectedPath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick directory: $e')));
      }
    }
  }

  Future<void> _clearSyncDirectory() async {
    await ref.read(deviceIdentityServiceProvider).setSyncDirectoryPath(null);
    ref.invalidate(syncDirectoryFutureProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sync directory cleared.')));
    }
  }

  Future<void> _runSync() async {
    setState(() => _isSyncing = true);
    try {
      final engine = ref.read(folderSyncEngineProvider);
      final result = await engine.sync();
      ref.invalidate(storageMetricsProvider);
      ref.invalidate(syncHistoryStreamProvider);

      if (mounted) {
        final message = result.success
            ? 'Sync complete: ${result.recordsExported} exported, ${result.recordsImported} imported, ${result.blobsTransferred} blobs transferred'
            : 'Sync failed: ${result.errorMessage}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.success
                ? Colors.green[800]
                : Colors.red[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _exportVault(String workspaceId) async {
    setState(() => _isExportingVault = true);
    try {
      final defaultName =
          'atlas_vault_${DateTime.now().millisecondsSinceEpoch}.atlas_vault';
      final tempFile = File('${Directory.systemTemp.path}/$defaultName');

      final exporter = ref.read(vaultExportServiceProvider);
      final exported = await exporter.exportVault(
        destinationFile: tempFile,
        workspaceId: workspaceId,
      );

      final bytes = await exported.readAsBytes();
      Uri? savedUri;
      try {
        savedUri = await FilePicker.saveFile(
          dialogTitle: 'Save ATLAS Vault Archive',
          fileName: defaultName,
          bytes: bytes,
        );
      } catch (_) {
        savedUri = null;
      }

      ref.invalidate(storageMetricsProvider);
      ref.invalidate(syncHistoryStreamProvider);

      if (mounted) {
        final pathDisplay = savedUri?.path ?? exported.path;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vault exported to $pathDisplay (${_formatBytes(exported.lengthSync())})',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vault export failed: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingVault = false);
    }
  }

  Future<void> _restoreVault() async {
    // 1. Confirm with warning dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Vault Archive?'),
        content: const Text(
          'Restoring a vault replaces the current SQLite database and restores content blobs from the archive snapshot.\n\nA safety rollback backup will be preserved in case of checksum errors. Do you wish to continue?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text(
              'Restore Vault',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoringVault = true);
    try {
      List<PlatformFile> picked = const [];
      try {
        picked = await FilePicker.pickFiles(
          dialogTitle: 'Select .atlas_vault Archive',
          type: FileType.custom,
          allowedExtensions: ['atlas_vault', 'zip'],
        );
      } catch (_) {
        picked = const [];
      }

      if (picked.isEmpty || picked.first.path == null) {
        return;
      }

      final vaultFile = File(picked.first.path!);
      final importer = ref.read(vaultImportServiceProvider);
      final result = await importer.restoreVault(vaultFile);

      ref.invalidate(currentWorkspaceProvider);
      ref.invalidate(storageMetricsProvider);
      ref.invalidate(syncHistoryStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vault restored successfully: ${result.restoredRecordsCount} records, ${result.restoredBlobsCount} blobs.',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vault restore failed: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoringVault = false);
    }
  }

  Future<void> _exportMarkdown(String workspaceId) async {
    setState(() => _isExportingMarkdown = true);
    try {
      final exporter = ref.read(markdownExportServiceProvider);
      final zip = await exporter.exportWorkspaceToMarkdownZip(
        workspaceId: workspaceId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Markdown notes exported to ${zip.path} (${_formatBytes(zip.lengthSync())})',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Markdown export failed: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingMarkdown = false);
    }
  }

  Future<void> _exportNotebooksPdf(String workspaceId) async {
    setState(() => _isExportingPdf = true);
    try {
      final exporter = ref.read(notebookBulkPdfExportServiceProvider);
      final zip = await exporter.exportWorkspaceNotebooksToZip(
        workspaceId: workspaceId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notebooks PDF exported to ${zip.path} (${_formatBytes(zip.lengthSync())})',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notebooks export failed: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _showEditDeviceNameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            hintText: 'e.g. Workstation, iPad Pro',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(deviceIdentityServiceProvider)
          .setDeviceName(controller.text.trim());
      ref.invalidate(deviceNameFutureProvider);
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

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
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AtlasColors.darkTextSecondary
                    : AtlasColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: AtlasSpacing.sm),
          if (isMonospace)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkElevated
                    : AtlasColors.lightElevated,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $label to clipboard'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy,
                        size: 13,
                        color: isDark
                            ? AtlasColors.darkTextSecondary
                            : AtlasColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
