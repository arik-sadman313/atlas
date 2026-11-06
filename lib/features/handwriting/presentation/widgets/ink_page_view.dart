import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/atlas_colors.dart';
import '../../domain/models/atlas_ink_document.dart';
import 'ink_document_painter.dart';
import 'ink_render_cache.dart';

/// Read-only handwritten page viewer designed for the Android productivity
/// companion and cross-platform read-only inspection (Linux & iPadOS).
///
/// Features:
/// - Smooth pinch-to-zoom and pan via [InteractiveViewer] (0.5x to 4.0x).
/// - High-fidelity vector rendering via [InkDocumentPainter].
/// - Optional raster PNG preview fallback for fast thumbnailing.
/// - Clear visual cue that this surface is read-only.
/// - ZERO stylus input, ZERO drawing gestures, ZERO touch modification.
class InkPageView extends StatefulWidget {
  final AtlasInkDocument document;
  final Uint8List? previewPngBytes;
  final Widget? backgroundWidget;
  final bool showCompanionBadge;
  final TransformationController? transformationController;

  const InkPageView({
    super.key,
    required this.document,
    this.previewPngBytes,
    this.backgroundWidget,
    this.showCompanionBadge = true,
    this.transformationController,
  });

  @override
  State<InkPageView> createState() => _InkPageViewState();
}

class _InkPageViewState extends State<InkPageView> {
  late final TransformationController _transformController;
  bool _createdLocalController = false;
  final InkRenderCache _renderCache = InkRenderCache();
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    if (widget.transformationController != null) {
      _transformController = widget.transformationController!;
    } else {
      _transformController = TransformationController();
      _createdLocalController = true;
    }
  }

  @override
  void didUpdateWidget(covariant InkPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      _revision++;
      _renderCache.invalidate();
    }
  }

  @override
  void dispose() {
    _renderCache.dispose();
    if (_createdLocalController) {
      _transformController.dispose();
    }
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Stack(
      children: [
        // Zoomable & Pannable Page Canvas
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(120),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(widget.document.backgroundColor),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 80 : 25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRect(
                child: SizedBox(
                  width: widget.document.width,
                  height: widget.document.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.backgroundWidget != null)
                        widget.backgroundWidget!,
                      if (widget.document.isEmpty &&
                          widget.previewPngBytes != null &&
                          widget.backgroundWidget == null)
                        Image.memory(
                          widget.previewPngBytes!,
                          fit: BoxFit.contain,
                          width: widget.document.width,
                          height: widget.document.height,
                        )
                      else
                        CustomPaint(
                          size: Size(
                            widget.document.width,
                            widget.document.height,
                          ),
                          painter: InkDocumentPainter(
                            document: widget.document,
                            isDrawing: false,
                            drawBackground: widget.backgroundWidget == null,
                            renderCache: _renderCache,
                            revision: _revision,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Read-Only Companion Banner (prominent on Android, subtle on other platforms)
        if (widget.showCompanionBadge)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkSurface.withAlpha(220)
                    : AtlasColors.lightSurface.withAlpha(220),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAndroid ? Icons.visibility_outlined : Icons.lock_outline,
                    size: 14,
                    color: isDark
                        ? AtlasColors.darkTextMuted
                        : AtlasColors.lightTextMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAndroid
                        ? 'Android Companion (Read-Only)'
                        : 'Read-Only Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AtlasColors.darkTextSecondary
                          : AtlasColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Floating Zoom Reset Controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Material(
            elevation: 3,
            color: isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            child: IconButton(
              icon: const Icon(Icons.fit_screen_outlined, size: 18),
              tooltip: 'Reset Zoom (100%)',
              onPressed: _resetZoom,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
