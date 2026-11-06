import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_button.dart';
import '../../../shared/widgets/atlas_card.dart';
import '../../../shared/widgets/atlas_empty_state.dart';

class NotebooksScreen extends ConsumerWidget {
  const NotebooksScreen({super.key});

  void _showCreateNotebookDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

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
          title: Text('New Notebook', style: theme.textTheme.headlineMedium),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Notebook Title',
              hintText: 'e.g. Physics Notes, Sketchbook',
            ),
            onSubmitted: (val) => _createNotebook(dialogCtx, ref, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  _createNotebook(dialogCtx, ref, titleController.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNotebook(
    BuildContext dialogCtx,
    WidgetRef ref,
    String title,
  ) async {
    final clean = title.trim();
    if (clean.isEmpty) return;

    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'nb_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: 'notebook',
        title: clean,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
    }
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result.isEmpty) return;
      final pickedPath = result.first.path;
      if (pickedPath == null) return;

      final workspaceId = ref.read(currentWorkspaceIdProvider);
      final pdfRepo = ref.read(pdfRepositoryProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Importing PDF and scaffolding notebook pages...'),
              ],
            ),
            duration: Duration(seconds: 15),
          ),
        );
      }

      final file = File(pickedPath);
      final fileName = p.basename(pickedPath);
      final title = p.basenameWithoutExtension(fileName);

      final nodeId = await pdfRepo.importPdf(
        workspaceId: workspaceId,
        filePath: file.path,
        customTitle: title,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.go('${AtlasRoutes.notebooks}/$nodeId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import PDF: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspaceId = ref.watch(currentWorkspaceIdProvider);
    final nodesDao = ref.watch(nodesDaoProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: StreamBuilder<List<NodeEntry>>(
          stream: nodesDao.watchNodesInWorkspace(workspaceId, type: 'notebook'),
          builder: (context, snapshot) {
            final notebooks = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notebooks',
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: AtlasSpacing.xs),
                            Text(
                              'Digital notebooks and handwritten journals',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AtlasColors.darkTextSecondary
                                    : AtlasColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            AtlasButton.secondary(
                              label: 'Import PDF',
                              icon: Icons.picture_as_pdf_outlined,
                              onPressed: () => _importPdf(context, ref),
                            ),
                            const SizedBox(width: AtlasSpacing.sm),
                            AtlasButton.primary(
                              label: 'New Notebook',
                              icon: Icons.add,
                              onPressed: () =>
                                  _showCreateNotebookDialog(context, ref),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (notebooks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AtlasEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No notebooks found',
                      description: 'Organize your sketches, study material, and handwritten notes or import PDFs to annotate.',
                      actionLabel: 'Create Notebook',
                      onAction: () => _showCreateNotebookDialog(context, ref),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.xl,
                      vertical: AtlasSpacing.sm,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisSpacing: AtlasSpacing.md,
                            crossAxisSpacing: AtlasSpacing.md,
                            childAspectRatio: 1.15,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final nb = notebooks[index];
                        final formattedDate = DateFormat.yMMMd().format(
                          nb.updatedAt,
                        );

                        return AtlasCard(
                          onTap: () {
                            context.go('${AtlasRoutes.notebooks}/${nb.id}');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AtlasColors.accentSageSubtle,
                                      borderRadius: BorderRadius.circular(
                                        AtlasSpacing.radiusSm,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_outlined,
                                      size: 16,
                                      color: AtlasColors.accentSage,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 16),
                                    onSelected: (action) async {
                                      if (action == 'delete') {
                                        await nodesDao.deleteNode(nb.id);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                nb.title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AtlasSpacing.xxs),
                              Text(
                                'Modified $formattedDate',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        );
                      }, childCount: notebooks.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
