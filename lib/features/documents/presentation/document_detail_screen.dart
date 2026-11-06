import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/atlas_colors.dart';
import '../../../core/theme/atlas_spacing.dart';
import '../../../shared/widgets/atlas_button.dart';
import '../../../shared/widgets/atlas_card.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final TextEditingController _blockInputController = TextEditingController();

  Future<void> _addBlock(String type) async {
    final text = _blockInputController.text.trim();
    if (text.isEmpty) return;

    final nodesDao = ref.read(nodesDaoProvider);
    final now = DateTime.now();

    await nodesDao.createBlock(
      NodeBlocksCompanion.insert(
        id: 'blk_${DateTime.now().microsecondsSinceEpoch}',
        nodeId: widget.documentId,
        type: type,
        contentJson: Value('{"text": "$text"}'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    _blockInputController.clear();
  }

  @override
  void dispose() {
    _blockInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nodesDao = ref.watch(nodesDaoProvider);

    return Scaffold(
      backgroundColor: isDark ? AtlasColors.darkBg : AtlasColors.lightBg,
      body: SafeArea(
        child: FutureBuilder<NodeEntry?>(
          future: nodesDao.getNode(widget.documentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final node = snapshot.data;
            if (node == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 36),
                    const SizedBox(height: AtlasSpacing.md),
                    Text(
                      'Document not found',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    AtlasButton(
                      label: 'Back to Documents',
                      onPressed: () => context.go('/documents'),
                    ),
                  ],
                ),
              );
            }

            final formattedDate = DateFormat.yMMMd().add_jm().format(
              node.updatedAt,
            );

            return CustomScrollView(
              slivers: [
                // Top Navigation Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AtlasSpacing.xl,
                      AtlasSpacing.md,
                      AtlasSpacing.xl,
                      AtlasSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          tooltip: 'Back to Documents',
                          onPressed: () => context.go('/documents'),
                        ),
                        const SizedBox(width: AtlasSpacing.sm),
                        Text(
                          'Documents / ${node.title}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          'Last saved $formattedDate',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),

                // Document Title Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AtlasSpacing.xl,
                      vertical: AtlasSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.title,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.sm),
                        const Divider(),
                      ],
                    ),
                  ),
                ),

                // Document Blocks Stream
                StreamBuilder<List<NodeBlockEntry>>(
                  stream: nodesDao.watchBlocksForNode(widget.documentId),
                  builder: (context, blockSnapshot) {
                    final blocks = blockSnapshot.data ?? [];

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AtlasSpacing.xl,
                        vertical: AtlasSpacing.sm,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final block = blocks[index];
                          final isHeading = block.type == 'heading_1';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AtlasSpacing.xs,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _extractBlockText(block.contentJson),
                                    style: isHeading
                                        ? theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              )
                                        : theme.textTheme.bodyLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  onPressed: () =>
                                      nodesDao.deleteBlock(block.id),
                                ),
                              ],
                            ),
                          );
                        }, childCount: blocks.length),
                      ),
                    );
                  },
                ),

                // Add Block Composer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpacing.xl),
                    child: AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _blockInputController,
                            decoration: const InputDecoration(
                              hintText: 'Add a new block to this document...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: AtlasSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AtlasButton.ghost(
                                label: 'Heading',
                                icon: Icons.title,
                                onPressed: () => _addBlock('heading_1'),
                              ),
                              const SizedBox(width: AtlasSpacing.sm),
                              AtlasButton.primary(
                                label: 'Add Paragraph',
                                icon: Icons.add,
                                onPressed: () => _addBlock('paragraph'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _extractBlockText(String json) {
    try {
      if (json.contains('"text":')) {
        final start = json.indexOf('"text":') + 7;
        final raw = json
            .substring(start)
            .replaceAll('"', '')
            .replaceAll('}', '')
            .trim();
        return raw.isEmpty ? 'Empty block' : raw;
      }
      return json;
    } catch (_) {
      return json;
    }
  }
}
