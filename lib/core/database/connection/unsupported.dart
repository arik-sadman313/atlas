import 'dart:io';

import 'package:drift/drift.dart';

QueryExecutor connect({
  bool inMemory = false,
  String dbName = 'atlas.db',
  File? overrideFile,
}) => throw UnsupportedError('Platform not supported for NativeDatabase');
