import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';

/// Renders the background PDF page beneath ink drawing layers.
/// Preserves exact PDF point dimensions ($1.0\text{ pt} = 1/72\text{ inch}$).
class PdfPageBackground extends ConsumerStatefulWidget {
  final String? pdfSourceHash;
  final int? pdfPageIndex;
  final double width;
  final double height;

  const PdfPageBackground({
    super.key,
    required this.pdfSourceHash,
    required this.pdfPageIndex,
    required this.width,
    required this.height,
  });

  @override
  ConsumerState<PdfPageBackground> createState() => _PdfPageBackgroundState();
}

class _PdfPageBackgroundState extends ConsumerState<PdfPageBackground> {
  Uint8List? _rasterBytes;
  bool _isLoading = false;
  String? _lastLoadedKey;

  @override
  void initState() {
    super.initState();
    _loadPageImage();
  }

  @override
  void didUpdateWidget(covariant PdfPageBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfSourceHash != widget.pdfSourceHash ||
        oldWidget.pdfPageIndex != widget.pdfPageIndex) {
      _loadPageImage();
    }
  }

  Future<void> _loadPageImage() async {
    final hash = widget.pdfSourceHash;
    final index = widget.pdfPageIndex;
    if (hash == null || index == null) {
      if (mounted) setState(() => _rasterBytes = null);
      return;
    }

    final key = '$hash:$index';
    if (key == _lastLoadedKey && _rasterBytes != null) return;

    setState(() => _isLoading = true);

    try {
      final blobStorage = ref.read(blobStorageServiceProvider);
      final pdfRenderingService = ref.read(pdfRenderingServiceProvider);

      final pdfBytes = await blobStorage.readBlob(hash);
      final imageBytes = await pdfRenderingService.renderBytesPageToImage(
        bytes: pdfBytes,
        pageIndex: index,
        scale: 2.0,
      );

      if (mounted) {
        setState(() {
          _rasterBytes = imageBytes;
          _isLoading = false;
          _lastLoadedKey = key;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rasterBytes = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pdfSourceHash == null || widget.pdfPageIndex == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _rasterBytes != null
          ? Image.memory(
              _rasterBytes!,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            )
          : Container(
              color: Colors.white,
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    )
                  : null,
            ),
    );
  }
}
