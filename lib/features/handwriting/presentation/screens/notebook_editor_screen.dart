import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pencil_kit/pencil_kit.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/atlas_colors.dart';
import '../../../../core/theme/atlas_spacing.dart';
import '../../../documents/presentation/widgets/backlinks_panel.dart';
import '../../../graph/presentation/widgets/local_graph_panel.dart';
import '../../../pdf/presentation/widgets/pdf_page_background.dart';
import '../../../tasks/presentation/widgets/node_tasks_panel.dart';
import '../../domain/interop/excalidraw_converter.dart';
import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';
import '../platform/pencil_kit_bridge.dart';
import '../widgets/floating_tool_dock.dart';
import '../widgets/ink_canvas.dart';
import '../widgets/ink_document_painter.dart';
import '../widgets/ink_page_view.dart';
import '../widgets/ink_tool_palette.dart';
import '../widgets/notebook_page_drawer.dart';

/// Full-featured Notebook Editor integrating the Atlas Ink Engine.
///
/// Adaptive across platforms:
/// - Android: Read-only companion viewer with pinch-to-zoom ([InkPageView]).
/// - Linux & Desktop: Vector handwriting canvas with mouse/tablet pressure support ([InkCanvas] + [InkToolPalette]).
/// - iPadOS: Mounts native Apple PencilKit canvas ([PencilKit]) with hardware latency,
///   pressure/tilt telemetry, lossless CAS binary persistence, and bidirectional portable ink conversion.
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
  bool _saveQueued = false;
  Completer<bool>? _activeSaveCompleter;
  String _title = 'Notebook';

  InkDocumentEntry? _documentEntry;
  List<InkPageEntry> _pages = [];
  int _currentPageIndex = 0;

  InkCanvasController? _canvasController;
  final PencilKitBridge _pencilKitBridge = PencilKitBridge();
  Uint8List? _currentRawPkBytes;
  bool _isPencilKitReady = false;

  final TransformationController _transformController =
      TransformationController();
  double _zoomLevel = 1.0;

  Timer? _autosaveTimer;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    _loadNotebookData();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((_zoomLevel - scale).abs() > 0.02) {
      if (mounted) setState(() => _zoomLevel = scale);
    }
  }

  void _zoomIn() {
    final newScale = (_zoomLevel * 1.25).clamp(0.3, 3.5);
    _setZoom(newScale);
  }

  void _zoomOut() {
    final newScale = (_zoomLevel / 1.25).clamp(0.3, 3.5);
    _setZoom(newScale);
  }

  void _resetZoom() {
    _setZoom(1.0);
  }

  void _setZoom(double scale) {
    setState(() => _zoomLevel = scale);
    _transformController.value = Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pencilKitBridge.dispose();
    _canvasController?.removeListener(_onCanvasChanged);
    _canvasController?.dispose();
    super.dispose();
  }

  Future<void> _loadNotebookData() async {
    setState(() => _isLoading = true);

    final nodesDao = ref.read(nodesDaoProvider);
    final inkDao = ref.read(inkDaoProvider);
    final inkRepo = ref.read(inkRepositoryProvider);
    final blobStorage = ref.read(blobStorageServiceProvider);

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
    if (firstPage.rawPencilkitHash != null) {
      try {
        _currentRawPkBytes = await blobStorage.readBlob(
          firstPage.rawPencilkitHash!,
        );
      } catch (_) {
        _currentRawPkBytes = null;
      }
    } else {
      _currentRawPkBytes = null;
    }

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

    _pencilKitBridge.attachController(_canvasController!);
    _canvasController!.addListener(_onCanvasChanged);
  }

  InkToolConfig? _lastSyncedTool;

  void _onCanvasChanged() {
    if (_canvasController != null &&
        _canvasController!.activeTool != _lastSyncedTool) {
      _lastSyncedTool = _canvasController!.activeTool;
      _pencilKitBridge.setTool(_canvasController!.activeTool);
    }
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      if (mounted) setState(() {});
    }
    _scheduleAutosave();
  }

  void _onPencilKitViewCreated(PencilKitController controller) async {
    _pencilKitBridge.attachPencilKitController(controller);
    if (_canvasController != null) {
      _pencilKitBridge.attachController(_canvasController!);
      _pencilKitBridge.setTool(_canvasController!.activeTool);
    }

    // Rehydrate existing drawing
    if (_currentRawPkBytes != null && _currentRawPkBytes!.isNotEmpty) {
      await _pencilKitBridge.loadRawPencilKitBytes(_currentRawPkBytes!);
    } else if (_canvasController != null &&
        _canvasController!.document.totalStrokeCount > 0) {
      final pkBytes = await _pencilKitBridge.convertPortableDocToPkDrawing(
        _canvasController!.document,
      );
      if (pkBytes != null && pkBytes.isNotEmpty) {
        await _pencilKitBridge.loadRawPencilKitBytes(pkBytes);
      }
    }

    _isPencilKitReady = true;
  }

  void _onPencilKitDrawingChanged() {
    if (!_isPencilKitReady) return;
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
      if (mounted) setState(() {});
    }
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveCurrentPage();
    });
  }

  /// Flushes any pending autosave timers and awaits any in-flight or queued saves.
  ///
  /// Returns `true` if all pending modifications have been safely persisted,
  /// or `false` if an unrecoverable persistence error occurred.
  Future<bool> _flushPendingSaves() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;

    if (!_hasUnsavedChanges && !_isSaving) {
      return true;
    }

    while (_isSaving && _activeSaveCompleter != null) {
      _saveQueued = true;
      await _activeSaveCompleter!.future;
    }

    if (!_hasUnsavedChanges) {
      return true;
    }

    return await _saveCurrentPage();
  }

  Future<bool> _saveCurrentPage() async {
    if (_isSaving) {
      _saveQueued = true;
      if (_activeSaveCompleter != null) {
        return await _activeSaveCompleter!.future;
      }
      return false;
    }

    if (_pages.isEmpty || (!_hasUnsavedChanges && !_saveQueued)) {
      return true;
    }

    _isSaving = true;
    _saveQueued = false;
    final completer = Completer<bool>();
    _activeSaveCompleter = completer;
    if (mounted) setState(() {});

    bool success = false;
    try {
      final inkRepo = ref.read(inkRepositoryProvider);
      final currentPage = _pages[_currentPageIndex];

      Uint8List? pkBytes;
      Uint8List? previewPngBytes;
      AtlasInkDocument docToSave;

      if (defaultTargetPlatform == TargetPlatform.iOS && _isPencilKitReady) {
        pkBytes = await _pencilKitBridge.exportRawPencilKitBytes();
        previewPngBytes = await _pencilKitBridge.exportPngBytes();
        if (pkBytes != null && pkBytes.isNotEmpty) {
          _currentRawPkBytes = pkBytes;
          final portableDoc = await _pencilKitBridge
              .convertPkDrawingToPortableDoc(
                pkBytes: pkBytes,
                documentId: currentPage.documentId,
                pageNumber: currentPage.pageNumber,
                width: currentPage.width,
                height: currentPage.height,
                backgroundTemplate: currentPage.templateType,
                backgroundColor: currentPage.backgroundColor,
              );
          docToSave = portableDoc ?? _canvasController!.document;
        } else {
          docToSave = _canvasController!.document;
        }
      } else {
        docToSave = _canvasController!.document;
      }

      final updatedPage = await inkRepo.savePageDrawing(
        page: currentPage,
        doc: docToSave,
        rawPencilKitBytes: pkBytes,
        previewPngBytes: previewPngBytes,
      );

      _pages[_currentPageIndex] = updatedPage;
      _hasUnsavedChanges = false;
      success = true;
    } catch (e) {
      debugPrint('Error autosaving page ink: $e');
      success = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save drawing: $e'),
            backgroundColor: Colors.red.shade800,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _flushPendingSaves(),
            ),
          ),
        );
      }
    } finally {
      _isSaving = false;
      completer.complete(success);
      _activeSaveCompleter = null;
      if (mounted) setState(() {});

      if (_saveQueued && _hasUnsavedChanges) {
        _saveCurrentPage();
      }
    }
    return success;
  }

  Future<void> _switchPage(int targetIndex) async {
    if (targetIndex < 0 ||
        targetIndex >= _pages.length ||
        targetIndex == _currentPageIndex) {
      return;
    }

    final saved = await _flushPendingSaves();
    if (!saved) return;

    _isPencilKitReady = false;
    setState(() {
      _currentPageIndex = targetIndex;
      _isLoading = true;
    });

    final targetPage = _pages[targetIndex];
    final inkRepo = ref.read(inkRepositoryProvider);
    final blobStorage = ref.read(blobStorageServiceProvider);

    if (targetPage.rawPencilkitHash != null) {
      try {
        _currentRawPkBytes = await blobStorage.readBlob(
          targetPage.rawPencilkitHash!,
        );
      } catch (_) {
        _currentRawPkBytes = null;
      }
    } else {
      _currentRawPkBytes = null;
    }

    final loadedDoc = await inkRepo.loadPageDrawing(targetPage);
    _initController(loadedDoc);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_currentRawPkBytes != null && _currentRawPkBytes!.isNotEmpty) {
        await _pencilKitBridge.loadRawPencilKitBytes(_currentRawPkBytes!);
      } else if (loadedDoc.totalStrokeCount > 0) {
        final pkBytes = await _pencilKitBridge.convertPortableDocToPkDrawing(
          loadedDoc,
        );
        if (pkBytes != null && pkBytes.isNotEmpty) {
          await _pencilKitBridge.loadRawPencilKitBytes(pkBytes);
        } else {
          _pencilKitBridge.clear();
        }
      } else {
        _pencilKitBridge.clear();
      }
      _isPencilKitReady = true;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewPage() async {
    final saved = await _flushPendingSaves();
    if (!saved) return;

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

  Future<void> _movePage(int fromIndex, int toIndex) async {
    if (_documentEntry == null || fromIndex == toIndex) return;
    if (fromIndex < 0 ||
        fromIndex >= _pages.length ||
        toIndex < 0 ||
        toIndex >= _pages.length) {
      return;
    }

    final saved = await _flushPendingSaves();
    if (!saved) return;

    final reordered = List<InkPageEntry>.from(_pages);
    final movedPage = reordered.removeAt(fromIndex);
    reordered.insert(toIndex, movedPage);

    final inkDao = ref.read(inkDaoProvider);
    final pageIds = reordered.map((p) => p.id).toList();
    await inkDao.batchReorderPages(_documentEntry!.id, pageIds);

    final updatedPages = await inkDao.getPagesForDocument(_documentEntry!.id);
    int newCurrent = _currentPageIndex;
    if (_currentPageIndex == fromIndex) {
      newCurrent = toIndex;
    } else if (fromIndex < _currentPageIndex && toIndex >= _currentPageIndex) {
      newCurrent--;
    } else if (fromIndex > _currentPageIndex && toIndex <= _currentPageIndex) {
      newCurrent++;
    }

    setState(() {
      _pages = updatedPages;
      _currentPageIndex = newCurrent;
    });
  }

  Future<void> _insertPageBelow(int index) async {
    final saved = await _flushPendingSaves();
    if (!saved) return;
    if (_documentEntry == null) return;

    final inkDao = ref.read(inkDaoProvider);
    final defaultTemplate = _documentEntry?.defaultTemplate ?? 'ruled';
    final targetPageNumber = index + 2;
    final newPageId =
        'page_${_documentEntry!.id}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    await inkDao.insertPageAt(
      _documentEntry!.id,
      targetPageNumber,
      InkPagesCompanion.insert(
        id: newPageId,
        documentId: _documentEntry!.id,
        pageNumber: targetPageNumber,
        templateType: drift.Value(defaultTemplate),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final updatedPages = await inkDao.getPagesForDocument(_documentEntry!.id);
    setState(() {
      _pages = updatedPages;
    });

    await _switchPage(index + 1);
  }

  Future<void> _duplicatePage(int index) async {
    final saved = await _flushPendingSaves();
    if (!saved) return;
    if (_documentEntry == null || index < 0 || index >= _pages.length) return;

    final inkDao = ref.read(inkDaoProvider);
    final sourcePage = _pages[index];
    final newPageId =
        'page_${_documentEntry!.id}_${DateTime.now().millisecondsSinceEpoch}';
    await inkDao.duplicatePage(sourcePage.id, newPageId);

    final updatedPages = await inkDao.getPagesForDocument(_documentEntry!.id);
    setState(() {
      _pages = updatedPages;
    });

    await _switchPage(index + 1);
  }

  Future<void> _deletePage(int index) async {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the only page in a notebook.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page?'),
        content: Text(
          'Are you sure you want to delete Page ${index + 1}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final saved = await _flushPendingSaves();
    if (!saved) return;
    if (_documentEntry == null) return;

    final inkDao = ref.read(inkDaoProvider);
    final targetPage = _pages[index];
    await inkDao.deletePageAndReorder(targetPage.id);

    final updatedPages = await inkDao.getPagesForDocument(_documentEntry!.id);
    int nextIndex = _currentPageIndex;
    if (_currentPageIndex >= updatedPages.length) {
      nextIndex = updatedPages.length - 1;
    } else if (_currentPageIndex > index) {
      nextIndex = _currentPageIndex - 1;
    }

    setState(() {
      _pages = updatedPages;
      _currentPageIndex = nextIndex;
    });

    await _switchPage(nextIndex);
  }

  Future<void> _changeTemplate(String newTemplate) async {
    await _changePageTemplate(_currentPageIndex, newTemplate);
  }

  Future<void> _changePageTemplate(int index, String newTemplate) async {
    if (index < 0 || index >= _pages.length) return;
    final page = _pages[index];
    final inkDao = ref.read(inkDaoProvider);
    await inkDao.updatePageTemplate(page.id, newTemplate, page.templateSpacing);

    final updatedPages = await inkDao.getPagesForDocument(_documentEntry!.id);
    setState(() {
      _pages = updatedPages;
    });

    if (index == _currentPageIndex && _canvasController != null) {
      final updatedDoc = _canvasController!.document.copyWith(
        backgroundTemplate: newTemplate,
      );
      _canvasController!.loadDocument(updatedDoc);
      _hasUnsavedChanges = true;
      _scheduleAutosave();
    }
  }

  Future<void> _exportNotebookToPdf() async {
    final saved = await _flushPendingSaves();
    if (!saved) return;
    if (_documentEntry == null) return;

    if (mounted) {
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
              Text('Generating PDF document...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );
    }

    try {
      final pdfExportService = ref.read(pdfExportServiceProvider);
      final file = await pdfExportService.exportNotebookToPdf(
        documentId: _documentEntry!.id,
        title: _title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _exportExcalidraw() async {
    if (_canvasController == null) return;
    try {
      final doc = _canvasController!.document;
      final excalJson = ExcalidrawConverter.exportToExcalidraw(doc);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(excalJson);

      final baseDir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = _title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final fileName =
          '${sanitizedTitle.isEmpty ? "Notebook" : sanitizedTitle}_page_${_currentPageIndex + 1}.excalidraw';
      final file = File(p.join(baseDir.path, fileName));
      await file.writeAsString(jsonStr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excalidraw exported to: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Excalidraw: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _importExcalidraw() async {
    if (_canvasController == null) return;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['excalidraw', 'json'],
      );
      if (result.isEmpty) return;

      final path = result.first.path;
      if (path == null) return;
      final file = File(path);
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      final importedDoc = ExcalidrawConverter.importFromExcalidraw(
        decoded,
        documentId: _canvasController!.document.documentId,
        pageNumber: _currentPageIndex + 1,
      );

      _canvasController!.loadDocument(importedDoc);
      _hasUnsavedChanges = true;
      _scheduleAutosave();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excalidraw diagram imported successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import Excalidraw: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  void _popSafely() {
    if (!mounted || !context.mounted) return;
    if (GoRouter.maybeOf(context) != null) {
      context.pop();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return PopScope(
      canPop: !_hasUnsavedChanges && !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final saved = await _flushPendingSaves();
        if (saved) {
          _popSafely();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AtlasColors.darkBg : const Color(0xFFE4E4E7),
        appBar: _buildHeader(theme, isDark, isAndroid),
        endDrawer: _pages.isNotEmpty
            ? NotebookPageDrawer(
                pages: _pages,
                currentPageIndex: _currentPageIndex,
                onPageSelected: (index) async {
                  Navigator.of(context).pop();
                  await _switchPage(index);
                },
                onAddPage: () {
                  Navigator.of(context).pop();
                  _addNewPage();
                },
                onInsertPageBelow: (index) async {
                  Navigator.of(context).pop();
                  await _insertPageBelow(index);
                },
                onDuplicatePage: (index) async {
                  Navigator.of(context).pop();
                  await _duplicatePage(index);
                },
                onDeletePage: (index) async {
                  Navigator.of(context).pop();
                  await _deletePage(index);
                },
                onMovePage: (fromIndex, toIndex) async {
                  await _movePage(fromIndex, toIndex);
                },
                onChangeTemplate: (index, newTemplate) async {
                  await _changePageTemplate(index, newTemplate);
                },
              )
            : null,
        body: _isLoading || _canvasController == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  // --- Adaptive Canvas Selection ---
                  Positioned.fill(
                    child: isAndroid
                        ? InkPageView(
                            document: _canvasController!.document,
                            showCompanionBadge: true,
                            backgroundWidget:
                                _pages.isNotEmpty &&
                                    _pages[_currentPageIndex].pdfSourceHash !=
                                        null
                                ? PdfPageBackground(
                                    pdfSourceHash:
                                        _pages[_currentPageIndex].pdfSourceHash,
                                    pdfPageIndex:
                                        _pages[_currentPageIndex].pdfPageIndex,
                                    width: _canvasController!.document.width,
                                    height: _canvasController!.document.height,
                                  )
                                : null,
                          )
                        : isIOS
                        ? _buildIosPencilKitCanvas(isDark)
                        : _buildDesktopCanvas(isDark),
                  ),

                  // --- Floating Tool Dock on Linux & iPadOS ---
                  if (!isAndroid && _canvasController != null)
                    FloatingToolDock(
                      controller: _canvasController!,
                      onClearRequested: () {
                        if (isIOS) {
                          _pencilKitBridge.clear();
                        }
                        _hasUnsavedChanges = true;
                        _scheduleAutosave();
                      },
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
          final saved = await _flushPendingSaves();
          if (saved) {
            _popSafely();
          }
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
                    _hasUnsavedChanges
                        ? Icons.pending_outlined
                        : Icons.check_circle_outline,
                    size: 18,
                    color: _hasUnsavedChanges
                        ? Colors.amber
                        : AtlasColors.accentSage,
                  ),
          ),
        ),

        // Template selector (enabled for non-android)
        if (!isAndroid)
          PopupMenuButton<String>(
            icon: const Icon(Icons.grid_4x4_outlined, size: 20),
            tooltip: 'Paper Stationery Template',
            onSelected: _changeTemplate,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'ruled', child: Text('Ruled / Lined')),
              const PopupMenuItem(
                value: 'cornell',
                child: Text('Cornell Notes'),
              ),
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

        // Excalidraw & PDF Export/Import Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.ios_share_rounded, size: 20),
          tooltip: 'Share & Export Options',
          onSelected: (val) {
            switch (val) {
              case 'export_excal':
                _exportExcalidraw();
                break;
              case 'import_excal':
                _importExcalidraw();
                break;
              case 'export_pdf':
                _exportNotebookToPdf();
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'export_excal',
              child: Row(
                children: [
                  Icon(Icons.draw_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Export Page to Excalidraw (.excalidraw)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import_excal',
              child: Row(
                children: [
                  Icon(Icons.file_open_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Import Excalidraw Diagram (.excalidraw)'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Export Full Notebook to PDF'),
                ],
              ),
            ),
          ],
        ),
        // Page Manager Drawer
        Builder(
          builder: (scaffoldCtx) => IconButton(
            icon: const Icon(Icons.auto_stories_outlined),
            tooltip: 'Page Manager',
            onPressed: () => Scaffold.of(scaffoldCtx).openEndDrawer(),
          ),
        ),
        // Linked Tasks Button
        IconButton(
          icon: const Icon(Icons.check_box_outlined),
          tooltip: 'Notebook Tasks',
          onPressed: () => _showTasksSheet(context),
        ),
        // Backlinks Button
        IconButton(
          icon: const Icon(Icons.link_rounded),
          tooltip: 'Backlinks',
          onPressed: () => _showBacklinksSheet(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showTasksSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AtlasSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Notebook Tasks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AtlasSpacing.sm),
              NodeTasksPanel(nodeId: widget.notebookId, initialExpanded: true),
            ],
          ),
        ),
      ),
    );
  }

  void _showBacklinksSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AtlasColors.darkSurface
          : AtlasColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AtlasSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AtlasColors.darkBorder
                        : AtlasColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.link_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Incoming Backlinks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AtlasSpacing.sm),
              BacklinksPanel(nodeId: widget.notebookId, initialExpanded: true),
              const SizedBox(height: AtlasSpacing.md),
              LocalGraphPanel(nodeId: widget.notebookId, initialExpanded: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCanvas(bool isDark) {
    final doc = _canvasController!.document;
    final currentPage = _pages.isNotEmpty ? _pages[_currentPageIndex] : null;
    final isPdf =
        currentPage?.pdfSourceHash != null && currentPage?.pdfPageIndex != null;
    final isPan = _canvasController?.activeTool.type == InkToolType.pan;

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.3,
            maxScale: 3.5,
            panEnabled: isPan,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(400),
            child: Center(
              child: Container(
                width: doc.width,
                height: doc.height,
                margin: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Color(doc.backgroundColor),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.5 : 0.15,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: InkCanvas(
                    controller: _canvasController!,
                    width: doc.width,
                    height: doc.height,
                    drawBackground: !isPdf,
                    backgroundWidget: isPdf
                        ? PdfPageBackground(
                            pdfSourceHash: currentPage!.pdfSourceHash,
                            pdfPageIndex: currentPage.pdfPageIndex,
                            width: doc.width,
                            height: doc.height,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Zoom Navigation Pill (Bottom-Left)
        Positioned(left: 16, bottom: 20, child: _buildZoomPill(isDark)),
      ],
    );
  }

  Widget _buildZoomPill(bool isDark) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14171F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF282F3E) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              tooltip: 'Zoom Out',
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: _zoomOut,
            ),
            InkWell(
              onTap: _resetZoom,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  '${(_zoomLevel * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              tooltip: 'Zoom In',
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: _zoomIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosPencilKitCanvas(bool isDark) {
    final doc = _canvasController!.document;
    final bgColor = Color(doc.backgroundColor);
    final currentPage = _pages.isNotEmpty ? _pages[_currentPageIndex] : null;
    final isPdf =
        currentPage?.pdfSourceHash != null && currentPage?.pdfPageIndex != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, bottom: 96),
        child: Container(
          width: doc.width,
          height: doc.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 80 : 25),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: isPdf
                    ? PdfPageBackground(
                        pdfSourceHash: currentPage!.pdfSourceHash,
                        pdfPageIndex: currentPage.pdfPageIndex,
                        width: doc.width,
                        height: doc.height,
                      )
                    : CustomPaint(
                        painter: PaperPatternPainter(
                          template: doc.backgroundTemplate,
                          backgroundColor: bgColor,
                          spacing: doc.templateSpacing,
                        ),
                      ),
              ),
              Positioned.fill(
                child: PencilKit(
                  isOpaque: false,
                  backgroundColor: Colors.transparent,
                  alwaysBounceVertical: false,
                  alwaysBounceHorizontal: false,
                  drawingPolicy: PencilKitIos14DrawingPolicy.defaultInput,
                  onPencilKitViewCreated: _onPencilKitViewCreated,
                  canvasViewDrawingDidChange: _onPencilKitDrawingChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
