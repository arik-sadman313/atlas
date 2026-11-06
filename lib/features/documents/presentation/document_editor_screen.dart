import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../journal/presentation/widgets/journal_context_day_panel.dart';
import '../../tasks/presentation/widgets/node_tasks_panel.dart';
import '../data/services/document_content_service.dart';
import 'widgets/backlinks_panel.dart';
import 'widgets/wiki_link_dialog.dart';

/// Document Editor Screen providing a Notion/Craft-like rich text editing experience.
///
/// Features:
/// - "Quiet Craft" typography and responsive layout (centered readable column on desktop/iPadOS).
/// - Block-level and inline rich-text editing (H1-H3, bullet/ordered lists, checklists, code blocks, quotes).
/// - 1-second debounced autosave to Content Addressable Storage (CAS) with mutex and PopScope safety.
/// - Inline [[Wiki-Links]] and bidirectional backlinks panel.
class DocumentEditorScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentEditorScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      DocumentEditorScreenState();
}

class DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _saveQueued = false;
  bool _hasUnsavedChanges = false;
  Timer? _autosaveTimer;
  StreamSubscription? _docChangeSub;

  NodeEntry? _node;
  QuillController? _quillController;
  late final TextEditingController _titleController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final DocumentContentService _contentService;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _loadDocumentData();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _docChangeSub?.cancel();
    _titleController.dispose();
    _quillController?.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentData() async {
    setState(() => _isLoading = true);

    final nodesDao = ref.read(nodesDaoProvider);
    final blobStorage = ref.read(blobStorageServiceProvider);
    _contentService = DocumentContentService(blobStorage: blobStorage);

    final node = await nodesDao.getNode(widget.documentId);
    if (!mounted) return;

    if (node == null) {
      setState(() {
        _node = null;
        _isLoading = false;
      });
      return;
    }

    _node = node;
    _titleController.text = node.title;

    final doc = await _contentService.loadDocument(
      node.contentHash,
      defaultTitle: node.title,
    );

    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _docChangeSub = controller.document.changes.listen((_) {
      _onContentChanged();
    });

    if (mounted) {
      setState(() {
        _quillController = controller;
        _isLoading = false;
      });
    }
  }

  void _onContentChanged() {
    _hasUnsavedChanges = true;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 1), () {
      saveDocument();
    });
    if (mounted) {
      setState(() {});
    }
  }

  /// Explicitly flushes and saves the document to CAS and database.
  Future<void> saveDocument() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;

    if (_isSaving) {
      _saveQueued = true;
      return;
    }

    final controller = _quillController;
    final node = _node;
    if (controller == null || node == null) return;

    setState(() => _isSaving = true);

    try {
      final doc = controller.document;

      // 1. Save document delta JSON to CAS
      final contentHash = await _contentService.saveDocument(doc);

      // 2. Update node record in database
      final nodesDao = ref.read(nodesDaoProvider);
      final currentTitle = _titleController.text.trim();
      final titleToSave = currentTitle.isNotEmpty ? currentTitle : node.title;

      await nodesDao.updateNodePartial(
        widget.documentId,
        NodesCompanion(
          title: drift.Value(titleToSave),
          contentHash: drift.Value(contentHash),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // 3. Extract text and synchronize [[Wiki-Links]]
      final plainText = DocumentContentService.extractPlainText(doc);
      final linkRepo = ref.read(linkRepositoryProvider);
      await linkRepo.syncLinksFromText(
        sourceNodeId: widget.documentId,
        workspaceId: node.workspaceId,
        text: plainText,
      );

      _hasUnsavedChanges = false;
    } catch (e) {
      // Avoid crashing the UI on save error, could be logged via logging service
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      if (_saveQueued) {
        _saveQueued = false;
        saveDocument();
      }
    }
  }

  Future<void> _insertWikiLink() async {
    final node = _node;
    final controller = _quillController;
    if (node == null || controller == null) return;

    final link = await WikiLinkDialog.show(
      context,
      workspaceId: node.workspaceId,
    );

    if (link != null && link.isNotEmpty) {
      final offset = controller.selection.baseOffset;
      final safeOffset = offset >= 0 ? offset : controller.document.length - 1;
      controller.document.insert(safeOffset, '$link ');
      controller.updateSelection(
        TextSelection.collapsed(offset: safeOffset + link.length + 1),
        ChangeSource.local,
      );
    }
  }

  void _handleLaunchUrl(String url) async {
    // If it's an internal Atlas node link: atlas://node/:id
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'atlas' && uri.host == 'node') {
      final targetId = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : '';
      if (targetId.isNotEmpty) {
        final nodesDao = ref.read(nodesDaoProvider);
        final targetNode = await nodesDao.getNode(targetId);
        if (targetNode != null && mounted) {
          if (targetNode.type == 'notebook') {
            context.push('/notebooks/$targetId');
          } else {
            context.push('/documents/$targetId');
          }
          return;
        }
      }
    }
  }

  int _calculateWordCount() {
    final doc = _quillController?.document;
    if (doc == null) return 0;
    final text = doc.toPlainText().trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isSaving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await saveDocument();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
        appBar: AppBar(
          backgroundColor: isDark
              ? AtlasColors.darkSurface
              : AtlasColors.lightSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Documents',
            onPressed: () async {
              if (_hasUnsavedChanges) {
                await saveDocument();
              }
              if (context.mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/documents');
                }
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              // Save Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AtlasColors.darkElevated
                      : AtlasColors.lightElevated,
                  borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 6),
                      Text('Saving...', style: theme.textTheme.labelSmall),
                    ] else if (_hasUnsavedChanges) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Unsaved', style: theme.textTheme.labelSmall),
                    ] else ...[
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text('Saved', style: theme.textTheme.labelSmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Wiki-Link Insert Action
            IconButton(
              icon: const Icon(Icons.link_rounded),
              tooltip: 'Insert Wiki-Link ([[Note]])',
              onPressed: _insertWikiLink,
            ),
            // Undo Action
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: () => _quillController?.undo(),
            ),
            // Redo Action
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: () => _quillController?.redo(),
            ),
            const SizedBox(width: AtlasSpacing.sm),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _node == null
            ? _buildNotFoundView(theme)
            : _buildEditorContent(theme, isDark),
      ),
    );
  }

  Widget _buildNotFoundView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: AtlasSpacing.md),
          Text('Document not found', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AtlasSpacing.md),
          FilledButton(
            onPressed: () => context.go('/documents'),
            child: const Text('Back to Documents'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent(ThemeData theme, bool isDark) {
    final wordCount = _calculateWordCount();
    final node = _node!;
    final formattedDate = DateFormat.yMMMd().add_jm().format(node.updatedAt);

    return Column(
      children: [
        // Formatting Toolbar (Quiet Craft styling)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AtlasColors.darkBorder
                    : AtlasColors.lightBorder,
                width: 1.0,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: QuillSimpleToolbar(
                controller: _quillController!,
                config: const QuillSimpleToolbarConfig(
                  toolbarSize: 24,
                  showFontFamily: false,
                  showFontSize: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showInlineCode: true,
                  showAlignmentButtons: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                ),
              ),
            ),
          ),
        ),

        // Scrollable Editor Body
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AtlasSpacing.md,
              vertical: AtlasSpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Document Icon & Header Area
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AtlasSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AtlasColors.darkElevated
                                : AtlasColors.lightElevated,
                            borderRadius: BorderRadius.circular(
                              AtlasSpacing.radiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            size: 28,
                            color: AtlasColors.accentBlue,
                          ),
                        ),
                        const SizedBox(width: AtlasSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Updated $formattedDate',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextSecondary
                                      : AtlasColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                '$wordCount words',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AtlasColors.darkTextSecondary
                                      : AtlasColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AtlasSpacing.lg),

                    // Editable Large Title (Quiet Craft style)
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Untitled Document',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        _onContentChanged();
                      },
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    Divider(
                      color: isDark
                          ? AtlasColors.darkBorder
                          : AtlasColors.lightBorder,
                    ),
                    const SizedBox(height: AtlasSpacing.md),

                    // Quill Editor
                    QuillEditor.basic(
                      controller: _quillController!,
                      config: QuillEditorConfig(
                        placeholder:
                            'Start typing, or insert [[Wiki-Links]]...',
                        scrollable: false,
                        autoFocus: false,
                        expands: false,
                        onLaunchUrl: _handleLaunchUrl,
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: AtlasSpacing.xxl),

                    // Contextual Day Summary (if this document is a daily journal)
                    StreamBuilder<JournalEntryData?>(
                      stream: ref
                          .watch(journalDaoProvider)
                          .watchEntryByNodeId(widget.documentId),
                      builder: (context, snapshot) {
                        final entry = snapshot.data;
                        if (entry == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AtlasSpacing.xl,
                          ),
                          child: JournalContextDayPanel(
                            journalDate: entry.journalDate,
                            initialExpanded: true,
                          ),
                        );
                      },
                    ),

                    // Node Tasks Panel
                    NodeTasksPanel(
                      nodeId: widget.documentId,
                      initialExpanded: true,
                    ),

                    const SizedBox(height: AtlasSpacing.xl),

                    // Backlinks Panel
                    BacklinksPanel(
                      nodeId: widget.documentId,
                      initialExpanded: true,
                    ),
                    const SizedBox(height: AtlasSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
