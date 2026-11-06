import 'dart:io';
import 'dart:typed_data';

import 'package:atlas/core/errors/failures.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late CasStorageService storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('atlas_cas_test_');
    storage = CasStorageService(rootDirectory: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CasStorageService', () {
    test('writes blob and returns correct sha256 hash', () async {
      final sampleData = Uint8List.fromList(
        'Hello Atlas Knowledge Engine'.codeUnits,
      );
      final expectedHash = sha256.convert(sampleData).toString().toLowerCase();

      final hash = await storage.writeBlob(sampleData);

      expect(hash, equals(expectedHash));
      expect(await storage.hasBlob(hash), isTrue);

      final path = await storage.getBlobPath(hash);
      final prefix = expectedHash.substring(0, 2);
      expect(path, contains(p.join(prefix, expectedHash)));
    });

    test('deduplicates identical blobs', () async {
      final sampleData = Uint8List.fromList(
        'Duplicate Blob Content Test'.codeUnits,
      );

      final hash1 = await storage.writeBlob(sampleData);
      final hash2 = await storage.writeBlob(sampleData);

      expect(hash1, equals(hash2));

      final size = await storage.getBlobSize(hash1);
      expect(size, equals(sampleData.length));
    });

    test('reads back exact stored bytes', () async {
      final sampleData = Uint8List.fromList([0, 1, 2, 3, 255, 128, 64]);
      final hash = await storage.writeBlob(sampleData);

      final readData = await storage.readBlob(hash);
      expect(readData, equals(sampleData));
    });

    test('deletes blob correctly', () async {
      final sampleData = Uint8List.fromList('Data to delete'.codeUnits);
      final hash = await storage.writeBlob(sampleData);

      expect(await storage.hasBlob(hash), isTrue);

      final deleted = await storage.deleteBlob(hash);
      expect(deleted, isTrue);
      expect(await storage.hasBlob(hash), isFalse);

      // Second delete returns false
      expect(await storage.deleteBlob(hash), isFalse);
    });

    test('throws BlobNotFoundException for missing blob', () async {
      const nonExistentHash =
          'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
      expect(
        () => storage.readBlob(nonExistentHash),
        throwsA(isA<BlobNotFoundException>()),
      );
    });
  });
}
