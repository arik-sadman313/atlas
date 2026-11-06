import 'dart:typed_data';

abstract class BlobStorageService {
  /// Writes binary data into content-addressable storage, returning its SHA-256 hash.
  Future<String> writeBlob(
    Uint8List data, {
    String? fileName,
    String? mimeType,
  });

  /// Reads binary data for a given SHA-256 hash.
  Future<Uint8List> readBlob(String hash);

  /// Checks whether a blob with the given hash exists.
  Future<bool> hasBlob(String hash);

  /// Deletes a blob with the given hash. Returns true if deleted, false if did not exist.
  Future<bool> deleteBlob(String hash);

  /// Returns the absolute filesystem path for a given hash.
  Future<String> getBlobPath(String hash);

  /// Returns the byte size of the stored blob.
  Future<int> getBlobSize(String hash);
}
