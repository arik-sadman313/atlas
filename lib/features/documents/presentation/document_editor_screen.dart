import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../handwriting/domain/models/atlas_ink_document.dart';
import '../../journal/presentation/widgets/journal_context_day_panel.dart';
import '../../graph/presentation/widgets/local_graph_panel.dart';
import '../../tasks/presentation/widgets/node_tasks_panel.dart';
import '../data/services/document_content_service.dart';
import 'embeds/callout_embed_builder.dart';
import 'embeds/divider_embed_builder.dart';
import 'embeds/ink_block_embed_builder.dart';
import 'embeds/task_embed_builder.dart';
import 'widgets/backlinks_panel.dart';
import 'widgets/slash_command_menu.dart';
import 'widgets/wiki_link_dialog.dart';

/// Document Editor Screen providing a Notion/Craft-like rich text editing experience.
///
/// Features:
/// - "Quiet Craft" typography and responsive layout (centered readable column on desktop/iPadOS).
/// - Slash command popup menu (`/`) triggered on empty line or after space with keyboard navigation.
/// - Inline Callout Box cards with customizable icons and color tints.
/// - Embedded Vector Ink sketch canvas blocks serializing portable strokes to CAS (`.atlas_ink`).
/// - Actionable SQLite Database Task embeds.
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
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  final LayerLink _layerLink = LayerLink();

  // Slash Command Menu Overlay State
  OverlayEntry? _slashMenuOverlayEntry;
  final GlobalKey<SlashCommandMenuState> _slashMenuKey =
      GlobalKey<SlashCommandMenuState>();
  int _slashStartIndex = -1;
  String _slashQuery = '';

  late final DocumentContentService _contentService;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _editorFocusNode.onKeyEvent = _handleKeyEvent;
    _loadDocumentData();
  }

  @override
  void dispose() {
    _hideSlashMenu();
    _autosaveTimer?.cancel();
    _docChangeSub?.cancel();
    _titleController.dispose();
    _quillController?.removeListener(_checkSlashCommand);
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

    controller.addListener(_checkSlashCommand);

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

  // =========================================================================
  // Slash Command Trigger & Keyboard Handling
  // =========================================================================

  void _checkSlashCommand() {
    final controller = _quillController;
    if (controller == null) return;

    final selection = controller.selection;
    if (!selection.isCollapsed || selection.baseOffset <= 0) {
      if (_slashMenuOverlayEntry != null) {
        _hideSlashMenu();
      }
      return;
    }

    final cursorPos = selection.baseOffset;
    final plainText = controller.document.toPlainText();
    if (cursorPos > plainText.length) {
      if (_slashMenuOverlayEntry != null) _hideSlashMenu();
      return;
    }

    // Find start of current line
    final lineStart = plainText.lastIndexOf('\n', cursorPos - 1);
    final lineStartIndex = lineStart == -1 ? 0 : lineStart + 1;
    final linePrefix = plainText.substring(lineStartIndex, cursorPos);

    final slashIdx = linePrefix.lastIndexOf('/');
    if (slashIdx == -1) {
      if (_slashMenuOverlayEntry != null) {
        _hideSlashMenu();
      }
      return;
    }

    // Ensure '/' is at line start or preceded by a space
    final isAtLineStart = slashIdx == 0;
    final isPrecededBySpace = slashIdx > 0 && linePrefix[slashIdx - 1] == ' ';

    if (!isAtLineStart && !isPrecededBySpace) {
      if (_slashMenuOverlayEntry != null) {
        _hideSlashMenu();
      }
      return;
    }

    final query = linePrefix.substring(slashIdx + 1);
    // If query contains spaces or linebreaks, dismiss slash command
    if (query.contains(' ') || query.contains('\n')) {
      if (_slashMenuOverlayEntry != null) {
        _hideSlashMenu();
      }
      return;
    }

    _slashStartIndex = lineStartIndex + slashIdx;
    _slashQuery = query;

    if (_slashMenuOverlayEntry == null) {
      _showSlashMenu();
    } else {
      _slashMenuOverlayEntry!.markNeedsBuild();
    }
  }

  void _showSlashMenu() {
    _hideSlashMenu();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final controller = _quillController;
    Offset caretOffset = const Offset(0, 32);

    if (controller != null) {
      try {
        final endpoints = _editorKey.currentState?.renderEditor
            .getEndpointsForSelection(controller.selection);
        if (endpoints != null && endpoints.isNotEmpty) {
          final pt = endpoints.first.point;
          caretOffset = Offset(pt.dx.clamp(0.0, 480.0), pt.dy + 8);
        }
      } catch (_) {}
    }

    _slashMenuOverlayEntry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideSlashMenu,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: caretOffset,
                child: SlashCommandMenu(
                  key: _slashMenuKey,
                  query: _slashQuery,
                  items: _buildSlashCommands(),
                  onDismiss: _hideSlashMenu,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_slashMenuOverlayEntry!);
  }

  void _hideSlashMenu() {
    _slashMenuOverlayEntry?.remove();
    _slashMenuOverlayEntry = null;
    _slashStartIndex = -1;
    _slashQuery = '';
  }

  /// Public accessor to dismiss the slash command popup menu.
  void hideSlashMenu() => _hideSlashMenu();

  /// Requests focus on the Quill editor.
  void focusEditor() => _editorFocusNode.requestFocus();

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_slashMenuOverlayEntry != null) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _slashMenuKey.currentState?.selectNext();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _slashMenuKey.currentState?.selectPrevious();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.tab) {
          _slashMenuKey.currentState?.executeSelected();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _hideSlashMenu();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _executeCommand(FutureOr<void> Function(int pos) action) async {
    final controller = _quillController;
    if (controller == null) return;

    final cursor = controller.selection.baseOffset;
    final startPos = _slashStartIndex >= 0 ? _slashStartIndex : cursor;
    final lengthToDelete = cursor - startPos;

    if (startPos >= 0 && lengthToDelete > 0) {
      controller.replaceText(startPos, lengthToDelete, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: startPos),
        ChangeSource.local,
      );
    }

    _hideSlashMenu();
    await action(startPos);
  }

  List<SlashCommandItem> _buildSlashCommands() {
    final controller = _quillController;
    if (controller == null) return [];

    return [
      // Text Blocks
      SlashCommandItem(
        id: 'text',
        label: 'Plain Text',
        description: 'Regular paragraph text',
        icon: Icons.text_fields,
        keywords: const ['text', 'plain', 'p', 'paragraph', 'normal'],
        category: SlashCommandCategory.text,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.clone(Attribute.header, null));
          controller.formatSelection(Attribute.clone(Attribute.list, null));
          controller.formatSelection(
            Attribute.clone(Attribute.blockQuote, null),
          );
          controller.formatSelection(
            Attribute.clone(Attribute.codeBlock, null),
          );
        }),
      ),
      SlashCommandItem(
        id: 'h1',
        label: 'Heading 1',
        description: 'Large section heading',
        icon: Icons.title,
        keywords: const ['h1', 'heading 1', '#', 'large', 'header 1'],
        category: SlashCommandCategory.text,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.h1);
        }),
      ),
      SlashCommandItem(
        id: 'h2',
        label: 'Heading 2',
        description: 'Medium section heading',
        icon: Icons.format_size,
        keywords: const ['h2', 'heading 2', '##', 'medium', 'header 2'],
        category: SlashCommandCategory.text,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.h2);
        }),
      ),
      SlashCommandItem(
        id: 'h3',
        label: 'Heading 3',
        description: 'Small subsection heading',
        icon: Icons.text_format,
        keywords: const ['h3', 'heading 3', '###', 'small', 'header 3'],
        category: SlashCommandCategory.text,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.h3);
        }),
      ),

      // Lists
      SlashCommandItem(
        id: 'bullet_list',
        label: 'Bulleted List',
        description: 'Create an unordered bullet list',
        icon: Icons.format_list_bulleted,
        keywords: const ['bullet', 'ul', 'list', 'unordered'],
        category: SlashCommandCategory.lists,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.ul);
        }),
      ),
      SlashCommandItem(
        id: 'numbered_list',
        label: 'Numbered List',
        description: 'Create a numbered ordered list',
        icon: Icons.format_list_numbered,
        keywords: const ['numbered', 'ol', '1.', 'ordered', 'number'],
        category: SlashCommandCategory.lists,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.ol);
        }),
      ),
      SlashCommandItem(
        id: 'todo',
        label: 'To-Do Checklist',
        description: 'Track tasks with an inline checkbox',
        icon: Icons.check_box_outlined,
        keywords: const ['todo', 'checklist', 'task', 'check', 'box', '[]'],
        category: SlashCommandCategory.lists,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.unchecked);
        }),
      ),

      // Containers
      SlashCommandItem(
        id: 'quote',
        label: 'Quote Block',
        description: 'Capture a notable quote or callout',
        icon: Icons.format_quote,
        keywords: const ['quote', 'blockquote', '>', 'citation'],
        category: SlashCommandCategory.containers,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.blockQuote);
        }),
      ),
      SlashCommandItem(
        id: 'callout',
        label: 'Callout Box',
        description: 'Card container with icon and accent tint',
        icon: Icons.info_outline,
        keywords: const [
          'callout',
          'box',
          'note',
          'alert',
          'info',
          'highlight',
        ],
        category: SlashCommandCategory.containers,
        onExecute: () => _executeCommand((pos) {
          final embed = DocumentContentService.createCalloutEmbed(text: '');
          controller.replaceText(pos, 0, embed, null);
          controller.replaceText(pos + 1, 0, '\n', null);
        }),
      ),

      // Dividers & Code
      SlashCommandItem(
        id: 'divider',
        label: 'Horizontal Divider',
        description: 'Visual separation line (---)',
        icon: Icons.horizontal_rule,
        keywords: const ['divider', 'hr', '---', 'separator', 'line'],
        category: SlashCommandCategory.dividersAndCode,
        onExecute: () => _executeCommand((pos) {
          final embed = DocumentContentService.createDividerEmbed();
          controller.replaceText(pos, 0, embed, null);
          controller.replaceText(pos + 1, 0, '\n', null);
        }),
      ),
      SlashCommandItem(
        id: 'code',
        label: 'Code Block',
        description: 'Code snippet with monospace styling',
        icon: Icons.code,
        keywords: const ['code', 'pre', '```', 'syntax', 'programming'],
        category: SlashCommandCategory.dividersAndCode,
        onExecute: () => _executeCommand((pos) {
          controller.formatSelection(Attribute.codeBlock);
        }),
      ),

      // ATLAS Embeds
      SlashCommandItem(
        id: 'link',
        label: 'Wiki-Link ([[Note]])',
        description: 'Link an existing document or notebook',
        icon: Icons.link,
        keywords: const ['link', 'wikilink', 'wiki', '[[', 'note', 'document'],
        category: SlashCommandCategory.embeds,
        onExecute: () => _executeCommand((pos) async {
          await _insertWikiLink();
        }),
      ),
      SlashCommandItem(
        id: 'task',
        label: 'Database Task',
        description: 'Actionable task synced with SQLite tasks',
        icon: Icons.task_alt,
        keywords: const ['task', 'action', 'todo', 'database', 'assignment'],
        category: SlashCommandCategory.embeds,
        onExecute: () => _executeCommand((pos) async {
          final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
          const defaultTitle = 'New Task';
          final node = _node;
          if (node != null) {
            final tasksDao = ref.read(tasksDaoProvider);
            await tasksDao.createTask(
              TasksCompanion.insert(
                id: taskId,
                workspaceId: node.workspaceId,
                title: defaultTitle,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                nodeId: drift.Value(widget.documentId),
              ),
            );
          }
          final taskEmbed = DocumentContentService.createTaskEmbed(
            taskId: taskId,
            title: defaultTitle,
          );
          controller.replaceText(pos, 0, taskEmbed, null);
          controller.replaceText(pos + 1, 0, '\n', null);
        }),
      ),
      SlashCommandItem(
        id: 'ink',
        label: 'Vector Ink Canvas',
        description: 'Inline vector drawing and diagram sketch',
        icon: Icons.gesture,
        keywords: const [
          'ink',
          'draw',
          'sketch',
          'handwriting',
          'canvas',
          'pencil',
        ],
        category: SlashCommandCategory.embeds,
        onExecute: () => _executeCommand((pos) async {
          final inkDoc = AtlasInkDocument.empty(
            documentId: 'sketch_${DateTime.now().millisecondsSinceEpoch}',
            pageNumber: 1,
            width: 760.0,
            height: 260.0,
          );
          final hash = await _contentService.saveInkBlockDrawing(inkDoc);
          final inkEmbed = DocumentContentService.createInkBlockEmbed(
            inkHash: hash,
            height: 260.0,
          );
          controller.replaceText(pos, 0, inkEmbed, null);
          controller.replaceText(pos + 1, 0, '\n', null);
        }),
      ),
    ];
  }

  // =========================================================================
  // Persistence & Lifecycle
  // =========================================================================

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
    } catch (_) {
      // Avoid crashing the UI on save error
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

                    // Quill Editor with LayerLink for floating slash menu
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: QuillEditor.basic(
                        controller: _quillController!,
                        focusNode: _editorFocusNode,
                        config: QuillEditorConfig(
                          editorKey: _editorKey,
                          placeholder:
                              'Start typing, or type "/" for commands...',
                          scrollable: false,
                          autoFocus: false,
                          expands: false,
                          onLaunchUrl: _handleLaunchUrl,
                          padding: EdgeInsets.zero,
                          embedBuilders: const [
                            CalloutEmbedBuilder(),
                            InkBlockEmbedBuilder(),
                            TaskEmbedBuilder(),
                            DividerEmbedBuilder(),
                          ],
                        ),
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

                    const SizedBox(height: AtlasSpacing.xl),

                    // Local 1-Hop Knowledge Graph Panel
                    LocalGraphPanel(
                      nodeId: widget.documentId,
                      initialExpanded: false,
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
