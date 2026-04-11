import 'dart:typed_data';

bool get isBrowserFaceDetectorSupported => false;

Future<String?> getBrowserFaceDetectorUnavailableReason() async {
  return 'Browser face detection is only available on supported web browsers.';
}

Future<int?> detectFacesFromBytes(Uint8List bytes) async {
  return null;
}
