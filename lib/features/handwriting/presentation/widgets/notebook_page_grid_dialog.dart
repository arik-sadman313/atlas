import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/storage/blob_storage_service.dart';

/// Full-screen / modal Page Overview Grid matching GoodNotes multi-page navigation.
///
/// Features:
/// - Responsive thumbnail grid (2, 3, or 4 columns)
/// - Active page badge & page number
/// - Reorder pages left / right
/// - Duplicate, Insert Before / After, Delete page actions
/// - Stationery template badges & quick template switcher
/// - Instant 1-tap navigation to any page
class NotebookPageGridDialog extends ConsumerWidget {
  final List<InkPageEntry> pages;
  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onAddPage;
  final ValueChanged<int> onInsertPageBelow;
  final ValueChanged<int> onDuplicatePage;
  final ValueChanged<int> onDeletePage;
  final void Function(int fromIndex, int toIndex) onMovePage;
  final void Function(int pageIndex, String newTemplate) onChangeTemplate;

  const NotebookPageGridDialog({
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

  static Future<void> show({
    required BuildContext context,
    required List<InkPageEntry> pages,
    required int currentPageIndex,
    required ValueChanged<int> onPageSelected,
    required VoidCallback onAddPage,
    required ValueChanged<int> onInsertPageBelow,
    required ValueChanged<int> onDuplicatePage,
    required ValueChanged<int> onDeletePage,
    required void Function(int fromIndex, int toIndex) onMovePage,
    required void Function(int pageIndex, String newTemplate) onChangeTemplate,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: NotebookPageGridDialog(
          pages: pages,
          currentPageIndex: currentPageIndex,
          onPageSelected: onPageSelected,
          onAddPage: onAddPage,
          onInsertPageBelow: onInsertPageBelow,
          onDuplicatePage: onDuplicatePage,
          onDeletePage: onDeletePage,
          onMovePage: onMovePage,
          onChangeTemplate: onChangeTemplate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    BlobStorageService? blobStorage;
    try {
      blobStorage = ref.watch(blobStorageServiceProvider);
    } catch (_) {
      // Gracefully handles test environments where blobStorageServiceProvider is not bootstrapped
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1117)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF14171F) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close Page Overview',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.grid_view_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Page Overview (${pages.length} ${pages.length == 1 ? 'Page' : 'Pages'})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onAddPage();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Page'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : (constraints.maxWidth > 600 ? 3 : 2);

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.72,
            ),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              final isCurrent = index == currentPageIndex;
              final isPdf = page.pdfSourceHash != null;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onPageSelected(index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2230) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF2563EB)
                            : (isDark
                                  ? const Color(0xFF2D3343)
                                  : const Color(0xFFE2E8F0)),
                        width: isCurrent ? 2.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCurrent
                              ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                              : Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.06,
                                ),
                          blurRadius: isCurrent ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Page Header in card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFF2563EB)
                                      : (isDark
                                            ? const Color(0xFF2A3142)
                                            : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isPdf
                                      ? 'PDF'
                                      : _formatTemplateName(page.templateType),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 16,
                                ),
                                tooltip: 'Page Options',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onSelected: (val) {
                                  if (val == 'insert') {
                                    Navigator.of(context).pop();
                                    onInsertPageBelow(index);
                                  } else if (val == 'duplicate') {
                                    Navigator.of(context).pop();
                                    onDuplicatePage(index);
                                  } else if (val == 'move_left' && index > 0) {
                                    onMovePage(index, index - 1);
                                  } else if (val == 'move_right' &&
                                      index < pages.length - 1) {
                                    onMovePage(index, index + 1);
                                  } else if (val == 'delete' &&
                                      pages.length > 1) {
                                    Navigator.of(context).pop();
                                    onDeletePage(index);
                                  } else if (val.startsWith('template:')) {
                                    onChangeTemplate(index, val.substring(9));
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'insert',
                                    child: Row(
                                      children: [
                                        Icon(Icons.add_rounded, size: 16),
                                        SizedBox(width: 8),
                                        Text('Insert Page Below'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.copy_rounded, size: 16),
                                        SizedBox(width: 8),
                                        Text('Duplicate Page'),
                                      ],
                                    ),
                                  ),
                                  if (index > 0)
                                    const PopupMenuItem(
                                      value: 'move_left',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_back_rounded,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Move Earlier (Left)'),
                                        ],
                                      ),
                                    ),
                                  if (index < pages.length - 1)
                                    const PopupMenuItem(
                                      value: 'move_right',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Move Later (Right)'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    enabled: false,
                                    child: Text(
                                      'TEMPLATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'template:ruled',
                                    child: Text('Ruled / Lined'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'template:cornell',
                                    child: Text('Cornell Notes'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'template:grid',
                                    child: Text('Square Grid'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'template:dotted',
                                    child: Text('Dotted Grid'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'template:blank',
                                    child: Text('Blank Canvas'),
                                  ),
                                  if (pages.length > 1) ...[
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete Page',
                                            style: TextStyle(color: Colors.red),
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
                        const Divider(height: 1),

                        // Thumbnail Preview Area
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(page.backgroundColor),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child:
                                  (page.previewPngHash != null &&
                                      blobStorage != null)
                                  ? FutureBuilder<Uint8List>(
                                      future: blobStorage.readBlob(
                                        page.previewPngHash!,
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return _buildThumbnailPattern(
                                          page.templateType,
                                          isDark,
                                        );
                                      },
                                    )
                                  : _buildThumbnailPattern(
                                      page.templateType,
                                      isDark,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildThumbnailPattern(String template, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            template == 'ruled'
                ? Icons.format_align_justify_rounded
                : (template == 'cornell'
                      ? Icons.view_headline_rounded
                      : (template == 'grid'
                            ? Icons.grid_4x4_rounded
                            : (template == 'dotted'
                                  ? Icons.drag_indicator_rounded
                                  : Icons.crop_portrait_rounded))),
            size: 32,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 6),
          Text(
            _formatTemplateName(template),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTemplateName(String template) {
    switch (template) {
      case 'ruled':
        return 'Ruled Paper';
      case 'cornell':
        return 'Cornell Notes';
      case 'grid':
        return 'Square Grid';
      case 'dotted':
        return 'Dotted Grid';
      case 'blank':
        return 'Blank Paper';
      default:
        return 'Stationery';
    }
  }
}
