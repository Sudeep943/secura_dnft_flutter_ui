import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

const String _experimentalFaceDetectorMessage =
    'Browser face detection is not enabled in this browser build. On desktop Chrome or Edge, this API is often unavailable unless Experimental Web Platform features is enabled.';

const String _secureContextFaceDetectorMessage =
    'Browser face detection requires a secure context. Open the web app on localhost or over HTTPS.';

const String _mediaPipeUnavailableMessage =
    'Web face detection could not be started in this browser.';

bool? _cachedBrowserFaceDetectorSupport;
String? _cachedBrowserFaceDetectorUnavailableReason;

bool get isBrowserFaceDetectorSupported =>
    _cachedBrowserFaceDetectorSupport == true;

Future<String?> getBrowserFaceDetectorUnavailableReason() async {
  if (_cachedBrowserFaceDetectorSupport != null) {
    return _cachedBrowserFaceDetectorSupport!
        ? null
        : _cachedBrowserFaceDetectorUnavailableReason ??
              _experimentalFaceDetectorMessage;
  }

  final unavailableReason = await _probeBrowserFaceDetectorUnavailableReason();
  _cachedBrowserFaceDetectorSupport = unavailableReason == null;
  _cachedBrowserFaceDetectorUnavailableReason = unavailableReason;
  return unavailableReason;
}

Future<int?> detectFacesFromBytes(Uint8List bytes) async {
  if (bytes.isEmpty) {
    return null;
  }

  if (await getBrowserFaceDetectorUnavailableReason() != null) {
    return null;
  }

  final blob = html.Blob([bytes]);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final image = html.ImageElement(src: objectUrl);

  try {
    await image.onLoad.first.timeout(const Duration(seconds: 5));

    final nativeSupportUnavailableReason =
        await _probeNativeFaceDetectorUnavailableReason();
    if (nativeSupportUnavailableReason == null) {
      final nativeFaceCount = await _detectFacesWithNativeDetector(image);
      if (nativeFaceCount != null) {
        return nativeFaceCount;
      }
    }

    return await _detectFacesWithMediaPipe(image);
  } catch (_) {
    return null;
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}

Future<String?> _probeBrowserFaceDetectorUnavailableReason() async {
  if (_jsPropertyAsBool(html.window, 'isSecureContext') == false) {
    return _secureContextFaceDetectorMessage;
  }

  final nativeSupportUnavailableReason =
      await _probeNativeFaceDetectorUnavailableReason();
  if (nativeSupportUnavailableReason == null) {
    return null;
  }

  return await _probeMediaPipeUnavailableReason();
}

Future<String?> _probeNativeFaceDetectorUnavailableReason() async {
  final windowObject = JSObject.fromInteropObject(html.window);
  if (!windowObject.has('FaceDetector')) {
    return _experimentalFaceDetectorMessage;
  }

  try {
    final detector = _createFaceDetector();
    final canvas = html.CanvasElement(width: 1, height: 1);
    await detector
        .callMethod<JSPromise<JSAny?>>(
          'detect'.toJS,
          JSObject.fromInteropObject(canvas),
        )
        .toDart;
    return null;
  } catch (error) {
    final errorText = error.toString();
    if (errorText.contains('SecurityError')) {
      return _secureContextFaceDetectorMessage;
    }
    if (errorText.contains('NotSupportedError')) {
      return _experimentalFaceDetectorMessage;
    }
    return 'Browser face detection is unavailable in this browser.';
  }
}

Future<String?> _probeMediaPipeUnavailableReason() async {
  final helper = _mediaPipeHelper();
  if (helper == null) {
    return _mediaPipeUnavailableMessage;
  }

  try {
    final result = await helper
        .callMethod<JSPromise<JSAny?>>('checkSupport'.toJS)
        .toDart;
    final dartResult = result?.dartify();
    if (dartResult is Map && dartResult['supported'] == true) {
      return null;
    }

    if (dartResult is Map && dartResult['reason'] is String) {
      final reason = dartResult['reason'] as String;
      if (reason.isNotEmpty) {
        return reason;
      }
    }

    return _mediaPipeUnavailableMessage;
  } catch (error) {
    return error.toString();
  }
}

Future<int?> _detectFacesWithNativeDetector(html.ImageElement image) async {
  try {
    final detector = _createFaceDetector();
    final faces = await detector
        .callMethod<JSPromise<JSAny?>>(
          'detect'.toJS,
          JSObject.fromInteropObject(image),
        )
        .toDart;
    final dartFaces = faces?.dartify();
    return dartFaces is List ? dartFaces.length : null;
  } catch (_) {
    return null;
  }
}

Future<int?> _detectFacesWithMediaPipe(html.ImageElement image) async {
  final helper = _mediaPipeHelper();
  if (helper == null) {
    return null;
  }

  try {
    final result = await helper
        .callMethod<JSPromise<JSAny?>>(
          'detectFaces'.toJS,
          JSObject.fromInteropObject(image),
        )
        .toDart;
    final dartResult = result?.dartify();
    if (dartResult is num) {
      return dartResult.toInt();
    }
    return null;
  } catch (_) {
    return null;
  }
}

JSObject _createFaceDetector() {
  final windowObject = JSObject.fromInteropObject(html.window);
  final constructor = windowObject.getProperty<JSFunction>('FaceDetector'.toJS);
  return constructor.callAsConstructor<JSObject>(_faceDetectorOptions());
}

JSObject? _mediaPipeHelper() {
  final windowObject = JSObject.fromInteropObject(html.window);
  if (!windowObject.has('securaFaceDetection')) {
    return null;
  }

  return windowObject.getProperty<JSObject>('securaFaceDetection'.toJS);
}

bool? _jsPropertyAsBool(Object target, String propertyName) {
  final jsTarget = JSObject.fromInteropObject(target);
  if (!jsTarget.has(propertyName)) {
    return null;
  }

  return jsTarget.getProperty<JSBoolean>(propertyName.toJS).toDart;
}

JSObject _faceDetectorOptions() {
  final options = JSObject();
  options['fastMode'] = true.toJS;
  options['maxDetectedFaces'] = 2.toJS;
  return options;
}
