import 'receipt_downloader_io.dart'
    if (dart.library.html) 'receipt_downloader_web.dart';

Future<bool> downloadBase64Receipt({
  required String base64Data,
  required String fileName,
}) {
  return downloadBase64ReceiptImpl(base64Data: base64Data, fileName: fileName);
}
