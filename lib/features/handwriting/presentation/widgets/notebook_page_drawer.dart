import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import 'ink_document_painter.dart';

class NotebookPageDrawer extends ConsumerWidget {
  final List<InkPageEntry> pages;
  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onAddPage;
  final ValueChanged<int> onInsertPageBelow;
  final ValueChanged<int> onDuplicatePage;
  final ValueChanged<int> onDeletePage;
  final void Function(int fromIndex, int toIndex) onMovePage;
  final void Function(int pageIndex, String newTemplate) onChangeTemplate;

  const NotebookPageDrawer({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onAddPage,
    required this.onInsertPageBelow,
    required this.onDuplicatePage,
    required this.onDeletePage,
    required this.onMovePage,
    required this.onChangeTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      elevation: 4,
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AtlasSpacing.md,
                AtlasSpacing.md,
                AtlasSpacing.sm,
                AtlasSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_stories_outlined,
                    size: 20,
                    color: AtlasColors.accentBlue,
                  ),
                  const SizedBox(width: AtlasSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pages (${pages.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.note_add_outlined, size: 20),
                    tooltip: 'Add Page at End',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.maybePop(context);
                      onAddPage();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Pages List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AtlasSpacing.sm),
                itemCount: pages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AtlasSpacing.sm),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final isCurrent = index == currentPageIndex;
                  final isPdf = page.pdfSourceHash != null;

                  return _PageThumbnailCard(
                    page: page,
                    index: index,
                    isCurrent: isCurrent,
                    isPdf: isPdf,
                    isDark: isDark,
                    onTap: () {
                      Navigator.maybePop(context);
                      onPageSelected(index);
                    },
                    onMoveUp: index > 0
                        ? () => onMovePage(index, index - 1)
                        : null,
                    onMoveDown: index < pages.length - 1
                        ? () => onMovePage(index, index + 1)
                        : null,
                    onInsertBelow: () => onInsertPageBelow(index),
                    onDuplicate: () => onDuplicatePage(index),
                    onDelete: pages.length > 1
                        ? () => onDeletePage(index)
                        : null,
                    onChangeTemplate: (t) => onChangeTemplate(index, t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageThumbnailCard extends ConsumerWidget {
  final InkPageEntry page;
  final int index;
  final bool isCurrent;
  final bool isPdf;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onInsertBelow;
  final VoidCallback onDuplicate;
  final VoidCallback? onDelete;
  final ValueChanged<String> onChangeTemplate;

  const _PageThumbnailCard({
    required this.page,
    required this.index,
    required this.isCurrent,
    required this.isPdf,
    required this.isDark,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onInsertBelow,
    required this.onDuplicate,
    required this.onDelete,
    required this.onChangeTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final blobStorage = ref.watch(blobStorageServiceProvider);

    final borderColor = isCurrent
        ? AtlasColors.accentBlue
        : (isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder);

    return Material(
      color: isCurrent
          ? (isDark
                ? AtlasColors.accentBlueSubtle.withValues(alpha: 0.15)
                : AtlasColors.accentBlueSubtle.withValues(alpha: 0.25))
          : (isDark ? AtlasColors.darkBg : AtlasColors.lightBg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
        side: BorderSide(color: borderColor, width: isCurrent ? 2.0 : 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AtlasSpacing.sm),
          child: Row(
            children: [
              // Miniature Thumbnail
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(page.backgroundColor),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                    width: 0.5,
                  ),
                ),
                child: ClipRect(
                  child: page.previewPngHash != null
                      ? FutureBuilder<Uint8List>(
                          future: blobStorage.readBlob(page.previewPngHash!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return _buildPatternThumbnail();
                          },
                        )
                      : _buildPatternThumbnail(),
                ),
              ),
              const SizedBox(width: AtlasSpacing.md),

              // Page Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page ${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent ? AtlasColors.accentBlue : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isPdf ? Colors.red : AtlasColors.accentSage)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPdf
                            ? 'PDF Page ${(page.pdfPageIndex ?? 0) + 1}'
                            : _formatTemplateName(page.templateType),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPdf
                              ? Colors.red.shade400
                              : AtlasColors.accentSage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Context Menu Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                tooltip: 'Page Actions',
                onSelected: (val) {
                  if (val == 'up') onMoveUp?.call();
                  if (val == 'down') onMoveDown?.call();
                  if (val == 'insert') onInsertBelow();
                  if (val == 'duplicate') onDuplicate();
                  if (val == 'delete') onDelete?.call();
                  if (val.startsWith('template:')) {
                    onChangeTemplate(val.replaceFirst('template:', ''));
                  }
                },
                itemBuilder: (ctx) => [
                  if (onMoveUp != null)
                    const PopupMenuItem(
                      value: 'up',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Move Up')),
                        ],
                      ),
                    ),
                  if (onMoveDown != null)
                    const PopupMenuItem(
                      value: 'down',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text('Move Down')),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'insert',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('Insert Below')),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('Duplicate')),
                      ],
                    ),
                  ),
                  if (!isPdf) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'template:ruled',
                      child: Text('Template: Ruled'),
                    ),
                    const PopupMenuItem(
                      value: 'template:grid',
                      child: Text('Template: Grid'),
                    ),
                    const PopupMenuItem(
                      value: 'template:dot',
                      child: Text('Template: Dot Grid'),
                    ),
                    const PopupMenuItem(
                      value: 'template:blank',
                      child: Text('Template: Blank'),
                    ),
                  ],
                  if (onDelete != null) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternThumbnail() {
    if (isPdf) {
      return const Center(
        child: Icon(Icons.picture_as_pdf, size: 24, color: Colors.redAccent),
      );
    }
    return CustomPaint(
      painter: PaperPatternPainter(
        template: page.templateType,
        backgroundColor: Color(page.backgroundColor),
        spacing: 12.0, // Scaled down for thumbnail preview
      ),
    );
  }

  String _formatTemplateName(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('dot')) return 'Dot Grid';
    if (lower.contains('grid') || lower.contains('graph')) return 'Square Grid';
    if (lower.contains('ruled') || lower.contains('line')) return 'Ruled';
    return 'Blank';
  }
}
