import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadBase64ReceiptImpl({
  required String base64Data,
  required String fileName,
}) async {
  try {
    final bytes = _decodeBase64Payload(base64Data);
    if (bytes == null || bytes.isEmpty) {
      return false;
    }

    final blob = html.Blob([bytes]);
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(objectUrl);
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
