import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/ink_stroke.dart';
import '../../domain/models/ink_tool.dart';
import '../controllers/ink_canvas_controller.dart';

/// Shows an interactive, responsive editor modal for creating or re-editing
/// text elements, sticky notes, and shape text in ATLAS Notebooks.
Future<void> showInkElementEditModal({
  required BuildContext context,
  required InkCanvasController controller,
  InkStroke? existingStroke,
  Offset? createPosition,
  bool isStickyNote = false,
}) async {
  final isEditing = existingStroke != null;
  final isNote =
      isStickyNote ||
      (existingStroke != null &&
          (existingStroke.shapeType == 'stickyNote' ||
              existingStroke.tool == InkToolType.stickyNote));

  final textCtrl = TextEditingController(
    text: isEditing ? (existingStroke.text ?? '') : '',
  );

  double selectedFontSize = isEditing
      ? (existingStroke.fontSize ?? (isNote ? 16.0 : 18.0))
      : (isNote ? 16.0 : 18.0);

  String selectedAlign = isEditing
      ? (existingStroke.textAlign ?? 'left')
      : 'left';

  int selectedColor = isEditing
      ? (isNote
            ? (existingStroke.fillColor ?? 0xFFFFF9B1)
            : existingStroke.color)
      : (isNote ? 0xFFFFF9B1 : controller.activeTool.color);

  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Curated color swatches
  final stickyColors = const [
    0xFFFFF9B1, // Canary Yellow
    0xFFE0F2FE, // Sky Blue
    0xFFDCFCE7, // Mint Green
    0xFFFCE7F3, // Soft Pink
    0xFFEDE9FE, // Lavender
    0xFFFFEDD5, // Sunset Peach
  ];

  final textColors = const [
    0xFF18181B, // Obsidian Charcoal
    0xFF2563EB, // Cobalt Blue
    0xFF10B981, // Emerald Green
    0xFFF59E0B, // Amber Gold
    0xFFEF4444, // Crimson Red
    0xFF8B5CF6, // Royal Violet
  ];

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDlgState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1E232F) : Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isNote
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isNote
                      ? Icons.sticky_note_2_rounded
                      : Icons.text_fields_rounded,
                  size: 20,
                  color: isNote
                      ? const Color(0xFFD97706)
                      : const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing
                      ? (isNote ? 'Edit Sticky Note' : 'Edit Note Text')
                      : (isNote ? 'New Sticky Note' : 'Add Note Text'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                tooltip: 'Insert Wiki-Link [[Note]]',
                onPressed: () async {
                  final linkText = await showDialog<String>(
                    context: ctx,
                    builder: (linkCtx) {
                      final titleController = TextEditingController();
                      return AlertDialog(
                        title: const Text('Insert Note Wiki-Link'),
                        content: TextField(
                          controller: titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Target Note or Notebook Title',
                            hintText: 'e.g. Architecture Specs',
                          ),
                          onSubmitted: (v) => Navigator.pop(linkCtx, v.trim()),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(linkCtx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(
                              linkCtx,
                              titleController.text.trim(),
                            ),
                            child: const Text('Insert Link'),
                          ),
                        ],
                      );
                    },
                  );
                  if (linkText != null && linkText.isNotEmpty) {
                    final current = textCtrl.text;
                    final toInsert = '[[$linkText]]';
                    textCtrl.text = current.isEmpty
                        ? toInsert
                        : '$current $toInsert';
                    textCtrl.selection = TextSelection.collapsed(
                      offset: textCtrl.text.length,
                    );
                  }
                },
              ),
              if (isEditing)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  tooltip: 'Delete Element',
                  onPressed: () {
                    controller.deleteStrokeById(existingStroke.id);
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
          content: SizedBox(
            width: math.min(420, MediaQuery.of(context).size.width * 0.85),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Text Area
                  Container(
                    decoration: BoxDecoration(
                      color: isNote
                          ? Color(selectedColor).withValues(alpha: 0.25)
                          : (isDark
                                ? const Color(0xFF13161F)
                                : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF333D52)
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: textCtrl,
                      autofocus: true,
                      maxLines: isNote ? 5 : 4,
                      style: TextStyle(
                        fontSize: selectedFontSize,
                        color: isNote
                            ? (isDark ? Colors.white : const Color(0xFF18181B))
                            : Color(selectedColor),
                        fontWeight: isNote ? FontWeight.w500 : FontWeight.w600,
                      ),
                      textAlign: selectedAlign == 'center'
                          ? TextAlign.center
                          : (selectedAlign == 'right'
                                ? TextAlign.right
                                : TextAlign.left),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: isNote
                            ? 'Type note thoughts or idea...'
                            : 'Type handwritten label or text...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Font Size & Alignment Bar
                  Row(
                    children: [
                      const Text(
                        'Size:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...[14.0, 18.0, 24.0, 32.0].map((sz) {
                        final isSel = (selectedFontSize - sz).abs() < 1.0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () =>
                                setDlgState(() => selectedFontSize = sz),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF6366F1)
                                    : (isDark
                                          ? const Color(0xFF282F3E)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${sz.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel
                                      ? Colors.white
                                      : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),

                      // Alignment
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: 'left',
                            icon: Icon(
                              Icons.format_align_left_rounded,
                              size: 14,
                            ),
                          ),
                          ButtonSegment(
                            value: 'center',
                            icon: Icon(
                              Icons.format_align_center_rounded,
                              size: 14,
                            ),
                          ),
                          ButtonSegment(
                            value: 'right',
                            icon: Icon(
                              Icons.format_align_right_rounded,
                              size: 14,
                            ),
                          ),
                        ],
                        selected: {selectedAlign},
                        onSelectionChanged: (set) {
                          setDlgState(() => selectedAlign = set.first);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Color Swatches
                  Text(
                    isNote ? 'Note Color:' : 'Text Color:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: (isNote ? stickyColors : textColors).map((c) {
                      final isSel = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDlgState(() => selectedColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white24 : Colors.black12),
                              width: isSel ? 2.5 : 1.0,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSel
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Color(0xFF4F46E5),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: Icon(
                isEditing ? Icons.check_rounded : Icons.add_rounded,
                size: 18,
              ),
              label: Text(isEditing ? 'Save Changes' : 'Create'),
              onPressed: () {
                final txt = textCtrl.text.trim();
                if (txt.isNotEmpty) {
                  if (isEditing) {
                    if (isNote) {
                      controller.updateStickyNote(
                        existingStroke.id,
                        txt,
                        bgColor: selectedColor,
                        fontSize: selectedFontSize,
                        textAlign: selectedAlign,
                      );
                    } else {
                      controller.updateTextElement(
                        existingStroke.id,
                        txt,
                        fontSize: selectedFontSize,
                        color: selectedColor,
                        textAlign: selectedAlign,
                      );
                    }
                  } else {
                    final pos = createPosition ?? const Offset(200, 200);
                    if (isNote) {
                      controller.addStickyNote(
                        pos,
                        txt,
                        bgColor: selectedColor,
                      );
                    } else {
                      controller.addTextElement(
                        pos,
                        txt,
                        fontSize: selectedFontSize,
                        color: selectedColor,
                        textAlign: selectedAlign,
                      );
                    }
                  }
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}
