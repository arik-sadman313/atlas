import 'dart:convert';

import 'package:atlas/features/documents/domain/models/document_embed_models.dart';
import 'package:atlas/features/documents/presentation/embeds/callout_embed_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalloutBlockEmbed Serialization & Deserialization Tests', () {
    test('serializes callout attributes to Delta embed payload', () {
      final callout = CalloutBlockEmbed.fromAttributes(
        content: 'Important security advisory',
        icon: '⚠️',
        colorHex: '#F59E0B',
      );

      expect(callout.type, 'callout');
      final map = callout.toMap();
      expect(map['content'], 'Important security advisory');
      expect(map['text'], 'Important security advisory');
      expect(map['icon'], '⚠️');
      expect(map['colorHex'], '#F59E0B');
      expect(callout.content, 'Important security advisory');
    });

    test(
      'deserializes callout payload from raw Map and nested Delta format',
      () {
        // 1. From raw attribute map with 'content'
        final fromMapContent = CalloutBlockEmbed.fromData({
          'content': 'Sprint goals for Q4',
          'icon': '🎯',
          'colorHex': '#10B981',
        });
        expect(fromMapContent.content, 'Sprint goals for Q4');
        expect(fromMapContent.icon, '🎯');
        expect(fromMapContent.colorHex, '#10B981');

        // 2. From raw attribute map with 'text'
        final fromMapText = CalloutBlockEmbed.fromData({
          'text': 'Meeting notes',
          'icon': '📝',
          'colorHex': '#6366F1',
        });
        expect(fromMapText.content, 'Meeting notes');
        expect(fromMapText.icon, '📝');

        // 3. From nested Delta embed map
        final nestedDeltaMap = {
          'callout': jsonEncode({
            'content': 'Nested delta payload',
            'icon': '🚀',
            'colorHex': '#3B82F6',
          }),
        };
        final fromNested = CalloutBlockEmbed.fromData(nestedDeltaMap);
        expect(fromNested.content, 'Nested delta payload');
        expect(fromNested.icon, '🚀');
        expect(fromNested.colorHex, '#3B82F6');
      },
    );

    test('copyWith creates modified instance with updated attributes', () {
      final original = CalloutBlockEmbed.fromAttributes(
        content: 'Original alert',
        icon: '💡',
        colorHex: '#6366F1',
      );

      final updated = original.copyWith(
        content: 'Updated critical notice',
        icon: '🔥',
        colorHex: '#EF4444',
      );

      expect(updated.content, 'Updated critical notice');
      expect(updated.icon, '🔥');
      expect(updated.colorHex, '#EF4444');
      // Original remains immutable
      expect(original.content, 'Original alert');
    });

    test(
      'CalloutEmbedBuilder extracts plaintext correctly for search indexing',
      () {
        const builder = CalloutEmbedBuilder();
        final calloutEmbed = CalloutBlockEmbed.fromAttributes(
          content: 'Searchable content string',
        );
        final embedNode = Embed(
          BlockEmbed(CalloutBlockEmbed.calloutType, calloutEmbed.data),
        );
        final plainText = builder.toPlainText(embedNode);

        expect(plainText, contains('Searchable content string'));
      },
    );

    testWidgets(
      'renders CalloutBlockWidget with icon, accent stripe, and editable text',
      (tester) async {
        final calloutEmbed = CalloutBlockEmbed.fromAttributes(
          content: 'Live widget callout text',
          icon: '💡',
          colorHex: '#6366F1',
        );

        final doc = Document();
        doc.insert(
          0,
          BlockEmbed(CalloutBlockEmbed.calloutType, calloutEmbed.data),
        );
        final controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuillEditor.basic(
                controller: controller,
                config: QuillEditorConfig(
                  embedBuilders: [const CalloutEmbedBuilder()],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('💡'), findsOneWidget);
        expect(find.text('Live widget callout text'), findsOneWidget);
      },
    );
  });
}
