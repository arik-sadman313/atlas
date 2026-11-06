import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// High-performance cache for static committed ink strokes.
///
/// When an ink document exceeds [defaultThreshold] (500) committed strokes,
/// all committed background strokes are pre-rendered into an offscreen [ui.Picture].
/// During active user interaction (pan/zoom navigation or in-flight drawing gestures),
/// [InkDocumentPainter] blits this cached picture in a single GPU operation,
/// eliminating redundant vector tessellation of hundreds of strokes per frame.
///
/// Memory Safety & Lifecycle:
/// - The cached [ui.Picture] is disposed whenever invalidated (e.g. stroke added,
///   erased, undo/redo, or page cleared) or when the cache itself is disposed
///   (e.g. switching notebook pages or route pop).
class InkRenderCache {
  /// Default threshold of committed strokes before activating offscreen picture caching.
  static const int defaultThreshold = 500;

  ui.Picture? _picture;
  int _cachedRevision = -1;
  int _strokeCount = -1;
  Size? _cachedSize;

  /// The cached [ui.Picture], if valid and available.
  ui.Picture? get picture => _picture;

  /// Returns true if a valid picture is cached.
  bool get hasCache => _picture != null;

  /// Number of strokes represented in the current cache.
  int get strokeCount => _strokeCount;

  /// Checks if the cached picture is valid for the given document [revision] and canvas [size].
  bool isValid(int revision, Size size) {
    return _picture != null &&
        _cachedRevision == revision &&
        _cachedSize == size;
  }

  /// Updates the cached picture with a newly recorded [picture].
  /// Any previously held [ui.Picture] is immediately disposed.
  void update(ui.Picture picture, int revision, Size size, int strokeCount) {
    if (_picture != null && _picture != picture) {
      _picture!.dispose();
    }
    _picture = picture;
    _cachedRevision = revision;
    _cachedSize = size;
    _strokeCount = strokeCount;
  }

  /// Invalidates and disposes the current cached picture.
  void invalidate() {
    _picture?.dispose();
    _picture = null;
    _cachedRevision = -1;
    _strokeCount = -1;
    _cachedSize = null;
  }

  /// Releases resources. Must be called when disposing owner widgets or controllers.
  void dispose() {
    invalidate();
  }
}
