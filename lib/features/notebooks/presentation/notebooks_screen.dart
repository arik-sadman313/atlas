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

  Future<void> _createStationeryNotebook(
    BuildContext context,
    WidgetRef ref,
    String title,
    String pattern,
  ) async {
    final workspaceId = ref.read(currentWorkspaceIdProvider);
    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();
    final newId = 'nb_${DateTime.now().millisecondsSinceEpoch}';

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: newId,
        workspaceId: workspaceId,
        type: 'notebook',
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (context.mounted) {
      context.go('${AtlasRoutes.notebooks}/$newId');
    }
  }

  Widget _buildStarterScreen(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AtlasSpacing.xl,
          vertical: AtlasSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Two Main Starter Cards
                Row(
                  children: [
                    Expanded(
                      child: _StarterCard(
                        icon: Icons.edit_note,
                        accentColor: AtlasColors.accentSage,
                        title: 'Create Blank Notebook',
                        subtitle: 'Infinite vector ink canvas with fluid pen, pencil, and highlighter tools.',
                        actionLabel: 'New Notebook',
                        onTap: () => _showCreateNotebookDialog(context, ref),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Expanded(
                      child: _StarterCard(
                        icon: Icons.picture_as_pdf_outlined,
                        accentColor: AtlasColors.accentAmber,
                        title: 'Import PDF to Annotate',
                        subtitle: 'Import textbooks, slides, or documents with layered vector ink annotations.',
                        actionLabel: 'Import PDF',
                        onTap: () => _importPdf(context, ref),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AtlasSpacing.xl),

                // Paper Stationery Section
                Text(
                  'Choose Paper Stationery',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AtlasColors.darkTextPrimary
                        : AtlasColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  'Start immediately with curated paper rulings and grid spacing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AtlasColors.darkTextSecondary
                        : AtlasColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StationeryCard(
                        name: 'Dot Grid',
                        description: '5mm bullet dots for ideation & diagrams',
                        pattern: 'dot',
                        onTap: () => _createStationeryNotebook(
                          context,
                          ref,
                          'Dot Grid Notebook',
                          'dot',
                        ),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Expanded(
                      child: _StationeryCard(
                        name: 'Ruled Lines',
                        description:
                            '7mm college ruling for structured writing',
                        pattern: 'line',
                        onTap: () => _createStationeryNotebook(
                          context,
                          ref,
                          'Lined Notebook',
                          'line',
                        ),
                      ),
                    ),
                    const SizedBox(width: AtlasSpacing.md),
                    Expanded(
                      child: _StationeryCard(
                        name: 'Graph Grid',
                        description: 'Square grid for technical drawing & math',
                        pattern: 'grid',
                        onTap: () => _createStationeryNotebook(
                          context,
                          ref,
                          'Grid Notebook',
                          'grid',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  _buildStarterScreen(context, ref, theme, isDark)
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
                            childAspectRatio: 0.95,
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
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Preview Box
                              Expanded(
                                child: Container(
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
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: StationeryPreviewPainter(
                                            pattern: 'dot',
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.black12,
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Icon(
                                          Icons.menu_book_outlined,
                                          size: 28,
                                          color: AtlasColors.accentSage
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AtlasColors.accentSage
                                                .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Vector Ink',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AtlasColors.accentSage,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      nb.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              const SizedBox(height: 2),
                              Text(
                                'Modified $formattedDate',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextMuted
                                      : AtlasColors.lightTextMuted,
                                ),
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

class _StarterCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _StarterCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtlasSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: accentColor),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AtlasColors.darkTextSecondary
                  : AtlasColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AtlasSpacing.md),
          Row(
            children: [
              Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: accentColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _StationeryCard extends StatelessWidget {
  final String name;
  final String description;
  final String pattern;
  final VoidCallback onTap;

  const _StationeryCard({
    required this.name,
    required this.description,
    required this.pattern,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtlasSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? AtlasColors.darkElevated
                  : AtlasColors.lightElevated,
              borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
              border: Border.all(
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
              ),
            ),
            child: CustomPaint(
              painter: StationeryPreviewPainter(
                pattern: pattern,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
          const SizedBox(height: AtlasSpacing.sm),
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: isDark
                  ? AtlasColors.darkTextSecondary
                  : AtlasColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class StationeryPreviewPainter extends CustomPainter {
  final String pattern;
  final Color color;

  StationeryPreviewPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    if (pattern == 'dot') {
      const spacing = 12.0;
      for (double y = spacing; y < size.height; y += spacing) {
        for (double x = spacing; x < size.width; x += spacing) {
          canvas.drawCircle(Offset(x, y), 0.9, paint);
        }
      }
    } else if (pattern == 'line') {
      const spacing = 12.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
      }
    } else if (pattern == 'grid') {
      const spacing = 12.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
