import 'dart:typed_data';

import 'package:image/image.dart' as img;

Future<Uint8List> normalizeFaceImageBytes(
  Uint8List rawBytes, {
  int maxDimension = 1280,
  int jpgQuality = 96,
}) async {
  try {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      return rawBytes;
    }

    final oriented = img.bakeOrientation(decoded);
    final longestSide = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;

    img.Image normalized = oriented;
    if (longestSide > maxDimension) {
      final scale = maxDimension / longestSide;
      final resizedWidth = (oriented.width * scale).round();
      final resizedHeight = (oriented.height * scale).round();
      normalized = img.copyResize(
        oriented,
        width: resizedWidth,
        height: resizedHeight,
        interpolation: img.Interpolation.cubic,
      );
    }

    final encoded = img.encodeJpg(normalized, quality: jpgQuality);
    return Uint8List.fromList(encoded);
  } catch (_) {
    return rawBytes;
  }
}
