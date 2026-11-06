import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:atlas/core/errors/failures.dart';

import '../../domain/models/atlas_ink_document.dart';
import '../../domain/models/ink_layer.dart';
import '../../domain/models/ink_point.dart';
import '../../domain/models/ink_stroke.dart';
import '../../domain/models/ink_tool.dart';

class InkBinarySerializer {
  static const List<int> magicBytes = [
    0x41, 0x54, 0x4C, 0x41, 0x53, 0x49, 0x4E, 0x4B, // ATLASINK
  ];
  static const int currentVersion = 1;

  static Uint8List serialize(AtlasInkDocument doc) {
    final builder = BytesBuilder(copy: false);

    // 1. Magic (8 bytes)
    builder.add(magicBytes);

    // 2. Header
    final headerBytes = ByteData(30);
    headerBytes.setUint16(0, currentVersion);
    headerBytes.setUint16(2, doc.pageNumber);
    headerBytes.setFloat32(4, doc.width.toDouble());
    headerBytes.setFloat32(8, doc.height.toDouble());
    headerBytes.setFloat32(12, doc.dpi.toDouble());
    headerBytes.setUint32(16, doc.backgroundColor);
    headerBytes.setUint16(20, doc.layers.length);
    builder.add(headerBytes.buffer.asUint8List(0, 22));

    // Document ID string (len uint8 + bytes)
    final docIdBytes = utf8.encode(doc.documentId);
    builder.addByte(docIdBytes.length);
    builder.add(docIdBytes);

    // Template string (len uint8 + bytes)
    final templateBytes = utf8.encode(doc.backgroundTemplate);
    builder.addByte(templateBytes.length);
    builder.add(templateBytes);

    // 3. Layers
    for (final layer in doc.layers) {
      final layerIdBytes = utf8.encode(layer.id);
      builder.addByte(layerIdBytes.length);
      builder.add(layerIdBytes);

      final blendBytes = utf8.encode(layer.blendMode);
      builder.addByte(blendBytes.length);
      builder.add(blendBytes);

      final layerData = ByteData(9);
      layerData.setUint8(0, layer.visible ? 1 : 0);
      layerData.setFloat32(1, layer.opacity);
      layerData.setUint32(5, layer.strokes.length);
      builder.add(layerData.buffer.asUint8List(0, 9));

      // 4. Strokes
      for (final stroke in layer.strokes) {
        final strokeIdBytes = utf8.encode(stroke.id);
        builder.addByte(strokeIdBytes.length);
        builder.add(strokeIdBytes);

        final strokeHeader = ByteData(18);
        strokeHeader.setUint8(0, stroke.tool.index);
        strokeHeader.setUint32(1, stroke.color);
        strokeHeader.setFloat32(5, stroke.baseWidth);
        strokeHeader.setFloat32(9, stroke.opacity);
        strokeHeader.setUint8(13, stroke.blendMode == 'multiply' ? 1 : 0);
        strokeHeader.setUint32(14, stroke.points.length);
        builder.add(strokeHeader.buffer.asUint8List(0, 18));

        // 5. Sequential Packed Points (16 bytes per point)
        final pointsBuffer = ByteData(stroke.points.length * 16);
        for (int i = 0; i < stroke.points.length; i++) {
          final p = stroke.points[i];
          final offset = i * 16;
          pointsBuffer.setFloat32(offset + 0, p.x);
          pointsBuffer.setFloat32(offset + 4, p.y);
          // Normalized pressure [0.0..1.0] -> uint16
          final normPressure = (p.pressure.clamp(0.0, 1.0) * 65535.0).round();
          pointsBuffer.setUint16(offset + 8, normPressure);
          // Normalized tilt azimuth [-pi..pi] -> int16
          final normAzimuth =
              ((p.tiltAzimuth.clamp(-math.pi, math.pi) / math.pi) * 32767.0)
                  .round();
          pointsBuffer.setInt16(offset + 10, normAzimuth);
          // Normalized tilt altitude [0..pi/2] -> uint16
          final normAltitude =
              ((p.tiltAltitude.clamp(0.0, math.pi / 2) / (math.pi / 2)) *
                      65535.0)
                  .round();
          pointsBuffer.setUint16(offset + 12, normAltitude);
          pointsBuffer.setUint16(offset + 14, p.timeOffsetMs.clamp(0, 65535));
        }
        builder.add(pointsBuffer.buffer.asUint8List());
      }
    }

    return builder.takeBytes();
  }

  static AtlasInkDocument deserialize(Uint8List data) {
    if (data.length < 8) {
      throw const StorageException('Corrupt binary ink: data too short');
    }

    // Verify magic
    for (int i = 0; i < 8; i++) {
      if (data[i] != magicBytes[i]) {
        throw const StorageException(
          'Invalid binary ink: magic bytes do not match ATLASINK',
        );
      }
    }

    final byteData = ByteData.sublistView(data);
    int offset = 8;

    final version = byteData.getUint16(offset);
    offset += 2;
    if (version > currentVersion) {
      throw StorageException('Unsupported ink format version: $version');
    }

    final pageNumber = byteData.getUint16(offset);
    offset += 2;
    final width = byteData.getFloat32(offset);
    offset += 4;
    final height = byteData.getFloat32(offset);
    offset += 4;
    final dpi = byteData.getFloat32(offset);
    offset += 4;
    final bgColor = byteData.getUint32(offset);
    offset += 4;
    final layerCount = byteData.getUint16(offset);
    offset += 2;

    // Doc ID
    final docIdLen = data[offset++];
    final docId = utf8.decode(data.sublist(offset, offset + docIdLen));
    offset += docIdLen;

    // Template
    final templateLen = data[offset++];
    final template = utf8.decode(data.sublist(offset, offset + templateLen));
    offset += templateLen;

    final layers = <InkLayer>[];

    for (int l = 0; l < layerCount; l++) {
      final layerIdLen = data[offset++];
      final layerId = utf8.decode(data.sublist(offset, offset + layerIdLen));
      offset += layerIdLen;

      final blendLen = data[offset++];
      final blendMode = utf8.decode(data.sublist(offset, offset + blendLen));
      offset += blendLen;

      final visible = byteData.getUint8(offset++) == 1;
      final opacity = byteData.getFloat32(offset);
      offset += 4;
      final strokeCount = byteData.getUint32(offset);
      offset += 4;

      final strokes = <InkStroke>[];

      for (int s = 0; s < strokeCount; s++) {
        final strokeIdLen = data[offset++];
        final strokeId = utf8.decode(
          data.sublist(offset, offset + strokeIdLen),
        );
        offset += strokeIdLen;

        final toolIndex = byteData.getUint8(offset++);
        final tool = toolIndex < InkToolType.values.length
            ? InkToolType.values[toolIndex]
            : InkToolType.ballpointPen;

        final color = byteData.getUint32(offset);
        offset += 4;
        final baseWidth = byteData.getFloat32(offset);
        offset += 4;
        final strokeOpacity = byteData.getFloat32(offset);
        offset += 4;
        final blendFlag = byteData.getUint8(offset++);
        final strokeBlendMode = blendFlag == 1 ? 'multiply' : 'srcOver';
        final pointCount = byteData.getUint32(offset);
        offset += 4;

        final points = <InkPoint>[];
        for (int p = 0; p < pointCount; p++) {
          final x = byteData.getFloat32(offset);
          final y = byteData.getFloat32(offset + 4);
          final pressureRaw = byteData.getUint16(offset + 8);
          final azimuthRaw = byteData.getInt16(offset + 10);
          final altitudeRaw = byteData.getUint16(offset + 12);
          final timeMs = byteData.getUint16(offset + 14);
          offset += 16;

          points.add(
            InkPoint(
              x: x,
              y: y,
              pressure: pressureRaw / 65535.0,
              tiltAzimuth: (azimuthRaw / 32767.0) * math.pi,
              tiltAltitude: (altitudeRaw / 65535.0) * (math.pi / 2),
              timeOffsetMs: timeMs,
            ),
          );
        }

        strokes.add(
          InkStroke(
            id: strokeId,
            tool: tool,
            color: color,
            baseWidth: baseWidth,
            opacity: strokeOpacity,
            blendMode: strokeBlendMode,
            points: points,
          ),
        );
      }

      layers.add(
        InkLayer(
          id: layerId,
          name: layerId,
          visible: visible,
          opacity: opacity,
          blendMode: blendMode,
          strokes: strokes,
        ),
      );
    }

    return AtlasInkDocument(
      version: version,
      documentId: docId,
      pageNumber: pageNumber,
      width: width,
      height: height,
      dpi: dpi,
      backgroundTemplate: template,
      backgroundColor: bgColor,
      layers: layers,
    );
  }
}
