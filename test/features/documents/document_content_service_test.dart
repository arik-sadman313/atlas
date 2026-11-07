import 'dart:io';

import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/documents/data/services/document_content_service.dart';
import 'package:atlas/features/documents/domain/models/document_embed_models.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentContentService', () {
    late Directory tempDir;
    late CasStorageService blobStorage;
    late DocumentContentService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('atlas_doc_test_');
      blobStorage = CasStorageService(rootDirectory: tempDir);
      service = DocumentContentService(blobStorage: blobStorage);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadDocument returns default document when hash is null', () async {
      final doc = await service.loadDocument(null, defaultTitle: 'Test Note');
      expect(doc.toPlainText(), contains('Test Note'));
    });

    test(
      'saveDocument writes CAS blob and loadDocument recovers document',
      () async {
        final doc = Document();
        doc.insert(0, 'Hello ATLAS World with [[Knowledge Links]]\n');

        final hash = await service.saveDocument(doc);
        expect(hash, isNotEmpty);
        expect(hash.length, 64); // SHA-256 hex string

        // Verify blob exists
        final exists = await blobStorage.hasBlob(hash);
        expect(exists, isTrue);

        // Reload document
        final reloaded = await service.loadDocument(hash);
        final extractedText = DocumentContentService.extractPlainText(reloaded);
        expect(
          extractedText,
          contains('Hello ATLAS World with [[Knowledge Links]]'),
        );
      },
    );

    test('Callout block Delta serialization and deserialization', () async {
      final doc = Document();
      doc.insert(0, 'Leading text\n');

      final calloutEmbed = DocumentContentService.createCalloutEmbed(
        text: 'This is an important architectural note',
        icon: '⚠️',
        colorHex: '#F59E0B',
      );
      doc.insert(doc.length - 1, calloutEmbed);
      doc.insert(doc.length - 1, '\nTrailing text\n');

      // Save document to CAS
      final docHash = await service.saveDocument(doc);
      expect(docHash, isNotEmpty);

      // Reload document from CAS
      final reloaded = await service.loadDocument(docHash);
      final callouts = DocumentContentService.extractCallouts(reloaded);

      expect(callouts.length, 1);
      expect(callouts.first.text, 'This is an important architectural note');
      expect(callouts.first.icon, '⚠️');
      expect(callouts.first.colorHex, '#F59E0B');

      // Plain text extraction should include callout content
      final plainText = DocumentContentService.extractPlainText(reloaded);
      expect(plainText, contains('This is an important architectural note'));
      expect(plainText, contains('Leading text'));
      expect(plainText, contains('Trailing text'));
    });

    test('Inline ink block persistence round-trip into CAS', () async {
      // 1. Create ink document with a vector stroke
      final stroke = InkStroke(
        id: 'stroke_1',
        tool: InkToolType.ballpointPen,
        color: 0xFF6366F1,
        baseWidth: 3.0,
        points: const [
          InkPoint(x: 10.0, y: 10.0, timeOffsetMs: 0),
          InkPoint(x: 50.0, y: 50.0, timeOffsetMs: 20),
          InkPoint(x: 100.0, y: 80.0, timeOffsetMs: 40),
        ],
      );

      final inkDoc =
          AtlasInkDocument.empty(
            documentId: 'sketch_test_1',
            pageNumber: 1,
            width: 760.0,
            height: 240.0,
          ).copyWith(
            layers: [
              AtlasInkDocument.empty(documentId: 'sketch_test_1').layers.first
                  .copyWith(strokes: [stroke]),
            ],
          );

      // 2. Save ink document to CAS
      final inkHash = await service.saveInkBlockDrawing(inkDoc);
      expect(inkHash, isNotEmpty);
      expect(await blobStorage.hasBlob(inkHash), isTrue);

      // 3. Load ink document from CAS
      final loadedInkDoc = await service.loadInkBlockDrawing(
        inkHash,
        documentId: 'sketch_test_1',
        width: 760.0,
        height: 240.0,
      );

      expect(loadedInkDoc.layers.isNotEmpty, isTrue);
      expect(loadedInkDoc.layers.first.strokes.length, 1);
      expect(loadedInkDoc.layers.first.strokes.first.points.length, 3);
      expect(loadedInkDoc.layers.first.strokes.first.color, 0xFF6366F1);

      // 4. Embed ink block in a Quill document and verify roundtrip
      final quillDoc = Document();
      quillDoc.insert(0, 'Above diagram\n');
      final inkEmbed = DocumentContentService.createInkBlockEmbed(
        inkHash: inkHash,
        height: 240.0,
      );
      quillDoc.insert(quillDoc.length - 1, inkEmbed);
      quillDoc.insert(quillDoc.length - 1, '\nBelow diagram\n');

      final quillDocHash = await service.saveDocument(quillDoc);
      final reloadedQuill = await service.loadDocument(quillDocHash);
      final inkBlocks = DocumentContentService.extractInkBlocks(reloadedQuill);

      expect(inkBlocks.length, 1);
      expect(inkBlocks.first.inkHash, inkHash);
      expect(inkBlocks.first.height, 240.0);
    });

    test('Task block Delta serialization and deserialization', () async {
      final doc = Document();
      doc.insert(0, 'Project Plan:\n');

      final taskEmbed = DocumentContentService.createTaskEmbed(
        taskId: 'task_m11',
        title: 'Ship Notion Slash Commands',
        isCompleted: true,
        priority: 'high',
      );
      doc.insert(doc.length - 1, taskEmbed);
      doc.insert(doc.length - 1, '\n');

      final docHash = await service.saveDocument(doc);
      final reloaded = await service.loadDocument(docHash);
      final tasks = DocumentContentService.extractTasks(reloaded);

      expect(tasks.length, 1);
      expect(tasks.first.taskId, 'task_m11');
      expect(tasks.first.title, 'Ship Notion Slash Commands');
      expect(tasks.first.isCompleted, isTrue);
      expect(tasks.first.priority, 'high');

      final plainText = DocumentContentService.extractPlainText(reloaded);
      expect(plainText, contains('Ship Notion Slash Commands'));
    });

    test('Divider embed creates divider type embed', () {
      final divider = DocumentContentService.createDividerEmbed();
      expect(divider.type, DividerBlockEmbed.dividerType);
      expect(divider.data, 'hr');
    });
  });
}
