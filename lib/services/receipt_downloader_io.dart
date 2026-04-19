import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> downloadBase64ReceiptImpl({
  required String base64Data,
  required String fileName,
}) async {
  try {
    final bytes = _decodeBase64Payload(base64Data);
    if (bytes == null || bytes.isEmpty) {
      return false;
    }

    final extension = _extensionFromFileName(fileName);
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Download Receipt',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: extension == null ? null : [extension],
    );

    if (savePath == null || savePath.trim().isEmpty) {
      return false;
    }

    final file = File(savePath);
    await file.writeAsBytes(bytes, flush: true);
    return true;
  } catch (_) {
    return false;
  }
}

Uint8List? _decodeBase64Payload(String rawPayload) {
  final trimmed = rawPayload.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  var payload = trimmed;
  final markerIndex = payload.indexOf('base64,');
  if (markerIndex >= 0) {
    payload = payload.substring(markerIndex + 7);
  }

  payload = payload.replaceAll('\n', '').replaceAll('\r', '');
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

String? _extensionFromFileName(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
    return null;
  }

  final extension = fileName.substring(dotIndex + 1).toLowerCase();
  return extension.isEmpty ? null : extension;
}
