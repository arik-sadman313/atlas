import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';
import '../widgets/ink_canvas.dart';
import '../widgets/ink_page_view.dart';
import '../widgets/ink_tool_palette.dart';

/// Full-featured Notebook Editor integrating the Atlas Ink Engine.
///
/// Adaptive across platforms:
/// - Android: Read-only companion viewer with pinch-to-zoom ([InkPageView]).
/// - Linux & Desktop: Vector handwriting canvas with mouse/tablet pressure support ([InkCanvas] + [InkToolPalette]).
/// - iPadOS: Prepares for native PencilKit bridge with fallback to vector canvas.
class NotebookEditorScreen extends ConsumerStatefulWidget {
  final String notebookId;

  const NotebookEditorScreen({super.key, required this.notebookId});

  @override
  ConsumerState<NotebookEditorScreen> createState() =>
      _NotebookEditorScreenState();
}

class _NotebookEditorScreenState extends ConsumerState<NotebookEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _title = 'Notebook';

  InkDocumentEntry? _documentEntry;
  List<InkPageEntry> _pages = [];
  int _currentPageIndex = 0;

  InkCanvasController? _canvasController;
  Timer? _autosaveTimer;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadNotebookData();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _canvasController?.dispose();
    super.dispose();
  }

  Future<void> _loadNotebookData() async {
    setState(() => _isLoading = true);

    final nodesDao = ref.read(nodesDaoProvider);
    final inkDao = ref.read(inkDaoProvider);
    final inkRepo = ref.read(inkRepositoryProvider);

    // 1. Fetch Notebook Title
    final node = await nodesDao.getNode(widget.notebookId);
    if (node != null) {
      _title = node.title;
    }

    // 2. Fetch or initialize Ink Document & initial page
    final doc = await inkDao.getOrCreateDocumentForNode(
      widget.notebookId,
      defaultTemplate: 'ruled',
    );
    _documentEntry = doc;

    // 3. Fetch Pages
    final pages = await inkDao.getPagesForDocument(doc.id);
    _pages = pages;
    _currentPageIndex = 0;

    // 4. Load First Page Drawing
    final firstPage = _pages.first;
    final inkDoc = await inkRepo.loadPageDrawing(firstPage);

    _initController(inkDoc);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _initController(AtlasInkDocument inkDoc) {
    _canvasController?.removeListener(_onCanvasChanged);
    _canvasController?.dispose();

    _canvasController = InkCanvasController(
      document: inkDoc,
      initialTool: const InkToolConfig(
        type: InkToolType.ballpointPen,
        color: 0xFF18181B,
        baseWidth: 3.0,
      ),
    );

    _canvasController!.addListener(_onCanvasChanged);
  }

  void _onCanvasChanged() {
    _hasUnsavedChanges = true;
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveCurrentPage();
    });
  }

  Future<void> _saveCurrentPage() async {
    if (_canvasController == null ||
        _pages.isEmpty ||
        !_hasUnsavedChanges ||
        _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final inkRepo = ref.read(inkRepositoryProvider);
      final currentPage = _pages[_currentPageIndex];
      final updatedPage = await inkRepo.savePageDrawing(
        page: currentPage,
        doc: _canvasController!.document,
      );

      _pages[_currentPageIndex] = updatedPage;
      _hasUnsavedChanges = false;
    } catch (e) {
      debugPrint('Error autosaving page ink: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _switchPage(int targetIndex) async {
    if (targetIndex < 0 ||
        targetIndex >= _pages.length ||
        targetIndex == _currentPageIndex) {
      return;
    }

    // Save active page first
    if (_hasUnsavedChanges) {
      await _saveCurrentPage();
    }

    setState(() {
      _currentPageIndex = targetIndex;
      _isLoading = true;
    });

    final targetPage = _pages[targetIndex];
    final inkRepo = ref.read(inkRepositoryProvider);
    final loadedDoc = await inkRepo.loadPageDrawing(targetPage);

    _initController(loadedDoc);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewPage() async {
    if (_hasUnsavedChanges) {
      await _saveCurrentPage();
    }

    final inkDao = ref.read(inkDaoProvider);
    final docId = _documentEntry!.id;
    final newPageNumber = _pages.length + 1;
    final newPageId = 'page_${docId}_$newPageNumber';
    final now = DateTime.now();

    final defaultTemplate = _documentEntry?.defaultTemplate ?? 'ruled';

    await inkDao.createPage(
      InkPagesCompanion.insert(
        id: newPageId,
        documentId: docId,
        pageNumber: newPageNumber,
        templateType: drift.Value(defaultTemplate),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final updatedPages = await inkDao.getPagesForDocument(docId);
    setState(() {
      _pages = updatedPages;
    });

    await _switchPage(_pages.length - 1);
  }

  Future<void> _changeTemplate(String newTemplate) async {
    if (_canvasController == null || _pages.isEmpty) return;

    final updatedDoc = _canvasController!.document.copyWith(
      backgroundTemplate: newTemplate,
    );
    _canvasController!.loadDocument(updatedDoc);

    // Also update SQLite page record
    final inkDao = ref.read(inkDaoProvider);
    final currentPage = _pages[_currentPageIndex];
    await inkDao.updatePage(
      currentPage
          .toCompanion(true)
          .copyWith(
            templateType: drift.Value(newTemplate),
            updatedAt: drift.Value(DateTime.now()),
          ),
    );

    _hasUnsavedChanges = true;
    _scheduleAutosave();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_hasUnsavedChanges) {
          _saveCurrentPage();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AtlasColors.darkBg : const Color(0xFFE4E4E7),
        appBar: _buildHeader(theme, isDark, isAndroid),
        body: _isLoading || _canvasController == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  // --- Canvas / Page Area ---
                  Positioned.fill(
                    child: isAndroid
                        ? InkPageView(
                            document: _canvasController!.document,
                            showCompanionBadge: true,
                          )
                        : _buildDesktopCanvas(isDark),
                  ),

                  // --- Floating Palette on Linux & Desktop ---
                  if (!isAndroid && _canvasController != null)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: InkToolPalette(
                          controller: _canvasController!,
                          onClearRequested: () {
                            _hasUnsavedChanges = true;
                            _scheduleAutosave();
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(
    ThemeData theme,
    bool isDark,
    bool isAndroid,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to Notebooks',
        onPressed: () async {
          if (_hasUnsavedChanges) {
            await _saveCurrentPage();
          }
          if (mounted) context.pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Page ${_currentPageIndex + 1} of ${_pages.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AtlasColors.darkTextSecondary
                  : AtlasColors.lightTextSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Save Status Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: isDark
                        ? AtlasColors.accentSage
                        : AtlasColors.accentSage,
                  ),
          ),
        ),

        // Template selector (enabled for non-android)
        if (!isAndroid)
          PopupMenuButton<String>(
            icon: const Icon(Icons.grid_4x4_outlined, size: 20),
            tooltip: 'Paper Template',
            onSelected: _changeTemplate,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'ruled', child: Text('Ruled / Lined')),
              const PopupMenuItem(value: 'dotted', child: Text('Dotted Grid')),
              const PopupMenuItem(value: 'grid', child: Text('Square Grid')),
              const PopupMenuItem(value: 'blank', child: Text('Blank Canvas')),
            ],
          ),

        // Page Navigation Group
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous Page',
          onPressed: _currentPageIndex > 0
              ? () => _switchPage(_currentPageIndex - 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next Page',
          onPressed: _currentPageIndex < _pages.length - 1
              ? () => _switchPage(_currentPageIndex + 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.note_add_outlined),
          tooltip: 'Add Page',
          onPressed: _addNewPage,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopCanvas(bool isDark) {
    final doc = _canvasController!.document;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, bottom: 96),
        child: Container(
          width: doc.width,
          height: doc.height,
          decoration: BoxDecoration(
            color: Color(doc.backgroundColor),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 80 : 25),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRect(
            child: InkCanvas(
              controller: _canvasController!,
              width: doc.width,
              height: doc.height,
            ),
          ),
        ),
      ),
    );
  }
}
