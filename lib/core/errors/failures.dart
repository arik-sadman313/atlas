class AtlasException implements Exception {
  final String message;
  final dynamic cause;

  const AtlasException(this.message, [this.cause]);

  @override
  String toString() =>
      'AtlasException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

class StorageException extends AtlasException {
  const StorageException(super.message, [super.cause]);
}

class BlobNotFoundException extends StorageException {
  final String hash;
  BlobNotFoundException(this.hash) : super('Blob with hash $hash not found');
}

class DatabaseException extends AtlasException {
  const DatabaseException(super.message, [super.cause]);
}
