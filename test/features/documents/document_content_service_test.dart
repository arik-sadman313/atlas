import 'dart:io';

import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/documents/data/services/document_content_service.dart';
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
  });
}
