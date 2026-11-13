import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../navigation/app_section.dart';
import '../services/browser_face_detector_stub.dart'
    if (dart.library.html) '../services/browser_face_detector_web.dart'
    as browser_face_detector;
import '../services/api_service.dart';
import 'app_shell.dart';

enum _LoginMode { adminLogin, attendanceEntry, attendanceExit }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final username = TextEditingController();
  final password = TextEditingController();
  final _deviceIdController = TextEditingController(text: 'DEVICE_001');
  final _passwordFocusNode = FocusNode();

  _LoginMode _loginMode = _LoginMode.adminLogin;

  bool loading = false;
  bool _obscurePassword = true;
  bool _cameraInitializing = false;
  bool _faceValidated = false;
  bool _liveValidationAvailable = false;
  bool _isProcessingCameraFrame = false;
  DateTime? _lastProcessedFrameAt;
  String _faceStatusMessage =
      'Switch to Submit Attendance or Mark Exit to activate the camera.';
  String? _cameraErrorMessage;

  CameraController? _cameraController;
  CameraDescription? _activeCameraDescription;
  FaceDetector? _faceDetector;
  Timer? _webValidationTimer;

  bool get _isAttendanceMode => _loginMode != _LoginMode.adminLogin;

  Future<bool> _supportsLiveFaceDetection() async {
    if (kIsWeb) {
      return await browser_face_detector
              .getBrowserFaceDetectorUnavailableReason() ==
          null;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    unawaited(_stopFaceDetectionCamera());
    username.dispose();
    password.dispose();
    _deviceIdController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleLoginMode(_LoginMode mode) async {
    if (_loginMode == mode) {
      return;
    }

    setState(() {
      _loginMode = mode;
      _cameraErrorMessage = null;
      _faceValidated = false;
      _liveValidationAvailable = false;
      _faceStatusMessage = mode == _LoginMode.adminLogin
          ? 'Switch to Submit Attendance or Mark Exit to activate the camera.'
          : 'Starting the camera for face validation.';
    });

    if (mode == _LoginMode.adminLogin) {
      await _stopFaceDetectionCamera();
      return;
    }

    await _startFaceDetectionCamera();
  }

  Future<void> _startFaceDetectionCamera() async {
    await _stopFaceDetectionCamera();

    final browserFaceDetectorUnavailableReason = kIsWeb
        ? await browser_face_detector.getBrowserFaceDetectorUnavailableReason()
        : null;
    final liveFaceDetectionSupported = await _supportsLiveFaceDetection();
    final fallbackStatusMessage = kIsWeb
        ? (browserFaceDetectorUnavailableReason ??
              'Live face guidance is unavailable in this browser. You can still capture a photo and the backend will verify it.')
        : 'Live face guidance is unavailable on this device. You can still capture a photo and the backend will verify it.';

    setState(() {
      _cameraInitializing = true;
      _cameraErrorMessage = null;
      _faceValidated = false;
      _liveValidationAvailable = liveFaceDetectionSupported;
      _faceStatusMessage = 'Starting the front camera.';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('camera-unavailable', 'No camera was found.');
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!_isAttendanceMode) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      _activeCameraDescription = selectedCamera;
      if (liveFaceDetectionSupported && !kIsWeb) {
        final detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            minFaceSize: 0.12,
          ),
        );
        _faceDetector = detector;

        await controller.startImageStream((image) {
          _handleCameraFrame(image, selectedCamera);
        });
      } else if (liveFaceDetectionSupported && kIsWeb) {
        _startWebFaceValidationLoop();
      }

      if (!mounted || !_isAttendanceMode) {
        return;
      }

      setState(() {
        _cameraInitializing = false;
        _faceValidated = !liveFaceDetectionSupported;
        _faceStatusMessage = liveFaceDetectionSupported
            ? 'Center one face in the frame to continue.'
            : fallbackStatusMessage;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraInitializing = false;
        _cameraErrorMessage =
            error.description ?? 'Unable to access the camera.';
        _faceStatusMessage = 'Camera access is required for attendance.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraInitializing = false;
        _cameraErrorMessage = 'Unable to start live face detection.';
        _faceStatusMessage = 'Camera setup failed.';
      });
    }
  }

  Future<void> _stopFaceDetectionCamera() async {
    _lastProcessedFrameAt = null;
    _isProcessingCameraFrame = false;
    _webValidationTimer?.cancel();
    _webValidationTimer = null;

    final controller = _cameraController;
    _cameraController = null;
    _activeCameraDescription = null;

    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {
        // Ignore camera stream shutdown errors during mode switches.
      }
      await controller.dispose();
    }

    final detector = _faceDetector;
    _faceDetector = null;
    await detector?.close();

    if (!mounted || _isAttendanceMode) {
      return;
    }

    setState(() {
      _cameraInitializing = false;
      _faceValidated = false;
    });
  }

  void _startWebFaceValidationLoop() {
    _webValidationTimer?.cancel();
    _webValidationTimer = Timer.periodic(const Duration(milliseconds: 1200), (
      _,
    ) {
      unawaited(_validateFaceFromWebSnapshot());
    });
    unawaited(_validateFaceFromWebSnapshot());
  }

  Future<void> _validateFaceFromWebSnapshot() async {
    final controller = _cameraController;
    if (!mounted ||
        !kIsWeb ||
        !_isAttendanceMode ||
        controller == null ||
        !controller.value.isInitialized ||
        _isProcessingCameraFrame ||
        controller.value.isTakingPicture) {
      return;
    }

    _isProcessingCameraFrame = true;
    try {
      final snapshot = await controller.takePicture();
      final bytes = await snapshot.readAsBytes();
      final faceCount = await browser_face_detector.detectFacesFromBytes(bytes);

      if (!mounted || !_isAttendanceMode) {
        return;
      }

      if (faceCount == null) {
        final browserFaceDetectorUnavailableReason = await browser_face_detector
            .getBrowserFaceDetectorUnavailableReason();
        setState(() {
          _faceValidated = false;
          _cameraErrorMessage =
              browserFaceDetectorUnavailableReason ??
              'Browser face detection failed for the current camera frame.';
        });
        return;
      }

      setState(() {
        _cameraErrorMessage = null;
        _faceValidated = faceCount == 1;
        if (faceCount == 1) {
          _faceStatusMessage = 'Face detected. You can submit attendance now.';
        } else if (faceCount == 0) {
          _faceStatusMessage =
              'No face detected. Move closer and face the camera.';
        } else {
          _faceStatusMessage =
              'Multiple faces detected. Keep only one face visible.';
        }
      });
    } catch (_) {
      if (!mounted || !_isAttendanceMode) {
        return;
      }

      setState(() {
        _cameraErrorMessage =
            'Unable to capture frames for browser face detection.';
        _faceValidated = false;
      });
    } finally {
      _isProcessingCameraFrame = false;
    }
  }

  void _handleCameraFrame(
    CameraImage image,
    CameraDescription cameraDescription,
  ) {
    if (!mounted ||
        !_isAttendanceMode ||
        _faceDetector == null ||
        _isProcessingCameraFrame) {
      return;
    }

    final now = DateTime.now();
    if (_lastProcessedFrameAt != null &&
        now.difference(_lastProcessedFrameAt!) <
            const Duration(milliseconds: 450)) {
      return;
    }

    _lastProcessedFrameAt = now;
    unawaited(_validateFaceFromFrame(image, cameraDescription));
  }

  Future<void> _validateFaceFromFrame(
    CameraImage image,
    CameraDescription cameraDescription,
  ) async {
    final inputImage = _buildInputImage(image, cameraDescription);
    if (inputImage == null || _faceDetector == null) {
      return;
    }

    _isProcessingCameraFrame = true;
    try {
      final faces = await _faceDetector!.processImage(inputImage);
      if (!mounted || !_isAttendanceMode) {
        return;
      }

      final hasSingleFace = faces.length == 1;
      setState(() {
        _faceValidated = hasSingleFace;
        if (hasSingleFace) {
          _faceStatusMessage = 'Face detected. You can submit attendance now.';
        } else if (faces.isEmpty) {
          _faceStatusMessage =
              'No face detected. Move closer and face the camera.';
        } else {
          _faceStatusMessage =
              'Multiple faces detected. Keep only one face visible.';
        }
      });
    } catch (_) {
      if (!mounted || !_isAttendanceMode) {
        return;
      }

      setState(() {
        _cameraErrorMessage =
            'Unable to process camera frames for face detection.';
        _faceValidated = false;
      });
    } finally {
      _isProcessingCameraFrame = false;
    }
  }

  InputImage? _buildInputImage(
    CameraImage image,
    CameraDescription cameraDescription,
  ) {
    final rotation = InputImageRotationValue.fromRawValue(
      cameraDescription.sensorOrientation,
    );
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (rotation == null || format == null || image.planes.isEmpty) {
      return null;
    }

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Widget _buildLoginModeOption({
    required _LoginMode mode,
    required String label,
    required IconData icon,
  }) {
    final selected = _loginMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleLoginMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x140F8F82),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? _brandColor : Colors.black54,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? _brandColor : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceDetectionPanel() {
    final controller = _cameraController;
    final hasPreview = controller != null && controller.value.isInitialized;
    final statusColor = _cameraErrorMessage != null
        ? Colors.redAccent
        : (_faceValidated ? _brandColor : const Color(0xFF9B6C00));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _faceValidated
              ? _brandColor.withValues(alpha: 0.45)
              : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Face attendance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _brandTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The camera starts automatically. Attendance is enabled after one face is visible in the frame.',
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                color: const Color(0xFF0D1F1C),
                child: _cameraInitializing
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : hasPreview
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(controller),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _faceValidated
                                      ? const Color(0xFF52E0C4)
                                      : Colors.white70,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _cameraErrorMessage ??
                                'Camera preview will appear here once face detection starts.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _cameraErrorMessage != null
                      ? Icons.error_outline
                      : (_faceValidated
                            ? Icons.verified_outlined
                            : Icons.face_retouching_natural_outlined),
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _cameraErrorMessage ?? _faceStatusMessage,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: _brandColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _buildDialogInputDecoration({
    required String labelText,
    String? errorText,
    String? counterText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _brandTextColor),
      errorText: errorText,
      counterText: counterText,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _brandColor.withValues(alpha: 0.45)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _brandColor, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _filledDialogButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brandColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  ButtonStyle _textDialogButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: _brandColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  void _submitIfReady() {
    if (_isAttendanceMode) {
      if (!loading) {
        unawaited(_submitAttendance());
      }
      return;
    }

    if (!loading) {
      login();
    }
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_cameraInitializing) {
      await _showMessageDialog(
        title: 'Camera Starting',
        message: 'Wait for the camera to finish starting before submitting.',
      );
      return;
    }

    if (_cameraErrorMessage != null) {
      await _showMessageDialog(
        title: 'Camera Unavailable',
        message: _cameraErrorMessage!,
      );
      return;
    }

    if (_isProcessingCameraFrame) {
      await _showMessageDialog(
        title: 'Validating Face',
        message: 'Wait for the current camera frame to finish processing.',
      );
      return;
    }

    if (_liveValidationAvailable && !_faceValidated) {
      await _showMessageDialog(
        title: 'Face Validation Required',
        message: 'Keep exactly one face visible before continuing.',
      );
      return;
    }

    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      await _showMessageDialog(
        title: 'Missing Device ID',
        message: 'Enter the device ID used for this attendance station.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      final imageBytes = await _captureAttendanceSnapshot();
      final response = _loginMode == _LoginMode.attendanceExit
          ? await ApiService.markAttendanceExit(
              deviceId: deviceId,
              imageBytes: imageBytes,
            )
          : await ApiService.lodgeAttendanceEntry(
              deviceId: deviceId,
              imageBytes: imageBytes,
            );

      final matched = response != null && response['matched'] == true;
      final employeeName = response == null
          ? null
          : response['employeeName']?.toString().trim();
      final actionTime = _loginMode == _LoginMode.attendanceExit
          ? (response == null ? null : response['exitTime']?.toString().trim())
          : (response == null
                ? null
                : response['entryTime']?.toString().trim());
      final message =
          (response == null ? null : response['message']?.toString().trim()) ??
          (_loginMode == _LoginMode.attendanceExit
              ? 'Unable to mark exit right now.'
              : 'Unable to submit attendance right now.');
      final matchScore = response == null
          ? null
          : response['matchScore']?.toString().trim();

      final dialogLines = <String>[];
      if ((employeeName ?? '').isNotEmpty) {
        dialogLines.add(employeeName!);
      }
      dialogLines.add(message);
      if ((matchScore ?? '').isNotEmpty) {
        dialogLines.add('Match Score: $matchScore');
      }
      if ((actionTime ?? '').isNotEmpty) {
        dialogLines.add(actionTime!);
      }

      final dialogMessage = matched ? dialogLines.join('\n') : message;

      await _showMessageDialog(
        title: matched ? 'Success' : 'Attendance Failed',
        message: dialogMessage,
      );
    } catch (_) {
      await _showMessageDialog(
        title: 'Attendance Failed',
        message: _loginMode == _LoginMode.attendanceExit
            ? 'Unable to capture the face and mark exit.'
            : 'Unable to capture the face and submit attendance.',
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<Uint8List> _captureAttendanceSnapshot() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not ready.');
    }

    final wasStreaming = !kIsWeb && controller.value.isStreamingImages;
    final cameraDescription = _activeCameraDescription;
    _webValidationTimer?.cancel();
    _webValidationTimer = null;

    _isProcessingCameraFrame = true;
    try {
      if (wasStreaming) {
        await controller.stopImageStream();
      }

      final picture = await controller.takePicture();
      return await picture.readAsBytes();
    } finally {
      _isProcessingCameraFrame = false;

      if (mounted && _isAttendanceMode) {
        if (kIsWeb) {
          _startWebFaceValidationLoop();
        } else if (wasStreaming && cameraDescription != null) {
          try {
            await controller.startImageStream((image) {
              _handleCameraFrame(image, cameraDescription);
            });
          } catch (_) {
            // Ignore restart errors if the camera mode changed while capturing.
          }
        }
      }
    }
  }

  Future<String?> _showOtpDialog(String message) async {
    final otpController = TextEditingController();
    String? validationMessage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            title: _buildDialogHeader('OTP Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    final otp = otpController.text.trim();
                    if (otp.length != 4) {
                      setDialogState(() {
                        validationMessage = 'Enter a valid 4 digit OTP.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(otp);
                  },
                  cursorColor: _brandColor,
                  decoration: _buildDialogInputDecoration(
                    labelText: '4 digit OTP',
                    errorText: validationMessage,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: _textDialogButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: _filledDialogButtonStyle(),
                onPressed: () {
                  final otp = otpController.text.trim();
                  if (otp.length != 4) {
                    setDialogState(() {
                      validationMessage = 'Enter a valid 4 digit OTP.';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(otp);
                },
                child: const Text('Verify OTP'),
              ),
            ],
          ),
        );
      },
    );

    otpController.dispose();
    return result;
  }

  Future<String?> _showPasswordUpdateDialog(String message) async {
    final passwordController = TextEditingController();
    String? validationMessage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            title: _buildDialogHeader('Update Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  autofocus: true,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    final newPassword = passwordController.text.trim();
                    if (newPassword.isEmpty) {
                      setDialogState(() {
                        validationMessage = 'Password is required.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(newPassword);
                  },
                  cursorColor: _brandColor,
                  decoration: _buildDialogInputDecoration(
                    labelText: 'New Password',
                    errorText: validationMessage,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: _textDialogButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: _filledDialogButtonStyle(),
                onPressed: () {
                  final newPassword = passwordController.text.trim();
                  if (newPassword.isEmpty) {
                    setDialogState(() {
                      validationMessage = 'Password is required.';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(newPassword);
                },
                child: const Text('Update Password'),
              ),
            ],
          ),
        );
      },
    );

    passwordController.dispose();
    return result;
  }

  Map<String, List<String>> _parseAccountDetails(dynamic accountDetails) {
    if (accountDetails is! Map) {
      return const {};
    }

    final parsed = <String, List<String>>{};
    accountDetails.forEach((key, value) {
      final apartmentId = key.toString().trim();
      if (apartmentId.isEmpty) {
        return;
      }

      if (value is! List) {
        return;
      }

      final flats = value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
      if (flats.isNotEmpty) {
        parsed[apartmentId] = flats;
      }
    });

    return parsed;
  }

  Future<Map<String, String>?> _showProfileSelectionDialog({
    required String message,
    required Map<String, List<String>> accountDetails,
  }) async {
    final apartmentIds = accountDetails.keys.toList();
    final hasSingleApartment = apartmentIds.length == 1;
    String? selectedApartmentId = hasSingleApartment
        ? apartmentIds.first
        : null;
    String? selectedFlatId = selectedApartmentId == null
        ? null
        : (() {
            final flatOptions =
                accountDetails[selectedApartmentId] ?? const <String>[];
            return flatOptions.length == 1 ? flatOptions.first : null;
          })();
    String? validationMessage;

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final flatOptions = selectedApartmentId == null
                ? const <String>[]
                : (accountDetails[selectedApartmentId] ?? const <String>[]);
            final hasSingleFlat = flatOptions.length == 1;

            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              title: _buildDialogHeader('Select Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedApartmentId,
                    decoration: _buildDialogInputDecoration(
                      labelText: 'Choose Apartment',
                    ),
                    items: apartmentIds
                        .map(
                          (apartmentId) => DropdownMenuItem<String>(
                            value: apartmentId,
                            child: Text(apartmentId),
                          ),
                        )
                        .toList(),
                    onChanged: hasSingleApartment
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedApartmentId = value;
                              final nextFlats = value == null
                                  ? const <String>[]
                                  : (accountDetails[value] ?? const <String>[]);
                              selectedFlatId = nextFlats.length == 1
                                  ? nextFlats.first
                                  : null;
                              validationMessage = null;
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedFlatId,
                    decoration: _buildDialogInputDecoration(
                      labelText: 'Choose Flat',
                    ),
                    items: flatOptions
                        .map(
                          (flatId) => DropdownMenuItem<String>(
                            value: flatId,
                            child: Text(flatId),
                          ),
                        )
                        .toList(),
                    onChanged: selectedApartmentId == null || hasSingleFlat
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedFlatId = value;
                              validationMessage = null;
                            });
                          },
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validationMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  style: _textDialogButtonStyle(),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: _filledDialogButtonStyle(),
                  onPressed: () {
                    if (selectedApartmentId == null ||
                        selectedFlatId == null ||
                        selectedFlatId!.isEmpty) {
                      setDialogState(() {
                        validationMessage =
                            'Please choose apartment and flat to continue.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop({
                      'apartmentId': selectedApartmentId!,
                      'flatID': selectedFlatId!,
                    });
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleMultipleProfileChallenge({
    required String loginMessage,
    required String userName,
    required String currentPassword,
    required Map<String, dynamic> responsePayload,
    String? otp,
  }) async {
    final accountDetails = _parseAccountDetails(
      responsePayload['accountDetails'],
    );
    if (accountDetails.isEmpty) {
      await _showMessageDialog(
        title: 'Error',
        message: 'Unable to load apartments/flats for profile selection.',
      );
      return;
    }

    final selection = await _showProfileSelectionDialog(
      message: loginMessage,
      accountDetails: accountDetails,
    );
    if (selection == null) {
      return;
    }

    setState(() => loading = true);

    Map<String, dynamic>? response;
    try {
      response = await ApiService.login(
        username: userName,
        password: currentPassword,
        otp: otp,
        apartmentId: selection['apartmentId'],
        flatId: selection['flatID'],
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }

    await _handleLoginResponse(
      response: response,
      userName: userName,
      currentPassword: currentPassword,
      fallbackErrorMessage: 'Unable to complete login.',
      otp: otp,
    );
  }

  Future<void> _handleLoginResponse({
    required Map<String, dynamic>? response,
    required String userName,
    required String currentPassword,
    required String fallbackErrorMessage,
    String? otp,
  }) async {
    final message = response == null
        ? fallbackErrorMessage
        : response['message']?.toString() ?? fallbackErrorMessage;
    final messageCode = response == null
        ? ''
        : response['messageCode']?.toString() ?? '';

    if (response == null) {
      await _showMessageDialog(title: 'Error', message: message);
      return;
    }

    if (messageCode.startsWith('SUCC')) {
      await _completeLogin(userName);
      return;
    }

    if (messageCode == 'ERR_MESSAGE_29') {
      await _handleOtpChallenge(
        loginMessage: message,
        userName: userName,
        currentPassword: currentPassword,
      );
      return;
    }

    if (messageCode == 'ERR_MESSAGE_54') {
      await _handleMultipleProfileChallenge(
        loginMessage: message,
        userName: userName,
        currentPassword: currentPassword,
        responsePayload: response,
        otp: otp,
      );
      return;
    }

    await _showMessageDialog(title: 'Error', message: message);
  }

  Future<void> _completeLogin(String fallbackProfileId) async {
    await ApiService.fetchAndStoreProfile(
      profileId: ApiService.currentUserId ?? fallbackProfileId,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppShell(initialSection: AppSection.dashboard),
      ),
    );
  }

  Future<void> _handleOtpChallenge({
    required String loginMessage,
    required String userName,
    required String currentPassword,
  }) async {
    final otp = await _showOtpDialog(loginMessage);
    if (otp == null || otp.isEmpty) {
      return;
    }

    setState(() => loading = true);

    Map<String, dynamic>? response;
    try {
      response = await ApiService.login(
        username: userName,
        password: currentPassword,
        otp: otp,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }

    final message = response == null
        ? 'Unable to verify OTP.'
        : response['message']?.toString() ?? 'Unable to verify OTP.';
    final messageCode = response == null
        ? ''
        : response['messageCode']?.toString() ?? '';

    if (response == null) {
      await _showMessageDialog(title: 'Error', message: message);
      return;
    }

    if (messageCode.startsWith('SUCC')) {
      await _completeLogin(userName);
      return;
    }

    if (messageCode == 'ERR_MESSAGE_30') {
      final newPassword = await _showPasswordUpdateDialog(message);
      if (newPassword == null || newPassword.isEmpty) {
        return;
      }

      final updateResponse = await ApiService.updatePassword(
        profileId: ApiService.currentUserId ?? userName,
        newPassword: newPassword,
        otpVerified: true,
      );
      final updateMessage = updateResponse == null
          ? 'Unable to update password.'
          : updateResponse['message']?.toString() ??
                'Unable to update password.';
      final updateCode = updateResponse == null
          ? ''
          : updateResponse['messageCode']?.toString() ?? '';

      if (updateCode.startsWith('SUCC')) {
        password.text = newPassword;
        await _showMessageDialog(title: 'Success', message: updateMessage);
      } else {
        await _showMessageDialog(title: 'Error', message: updateMessage);
      }
      return;
    }

    if (messageCode == 'ERR_MESSAGE_54') {
      await _handleMultipleProfileChallenge(
        loginMessage: message,
        userName: userName,
        currentPassword: currentPassword,
        responsePayload: response,
        otp: otp,
      );
      return;
    }

    await _showMessageDialog(title: 'Error', message: message);
  }

  Future<void> login() async {
    final trimmedUsername = username.text.trim();
    final trimmedPassword = password.text.trim();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty) {
      await _showMessageDialog(
        title: 'Error',
        message: 'Username and password are required.',
      );
      return;
    }

    setState(() => loading = true);

    Map<String, dynamic>? response;
    try {
      response = await ApiService.login(
        username: trimmedUsername,
        password: trimmedPassword,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }

    await _handleLoginResponse(
      response: response,
      userName: trimmedUsername,
      currentPassword: trimmedPassword,
      fallbackErrorMessage: 'Unable to complete login.',
    );
  }

  Widget _buildLoginTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputAction textInputAction,
    required Iterable<String> autofillHints,
    FocusNode? focusNode,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: Color(0xFF153D36),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64817B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFCFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        labelStyle: const TextStyle(color: Color(0xFF667B76), fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFD8E6E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _brandColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.6),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3ECE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180D4038),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: _brandColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Log In',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF153D36),
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),
          _buildLoginTextField(
            controller: username,
            label: 'Email / Phone Number',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocusNode),
          ),
          const SizedBox(height: 16),
          _buildLoginTextField(
            controller: password,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            onSubmitted: (_) => _submitIfReady(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF667B76),
                size: 20,
              ),
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: loading ? null : _submitIfReady,
              style: FilledButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF79AFA8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Sign In'),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE0EAE7))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'SECURE COMMUNITY ACCESS',
                  style: TextStyle(
                    color: Color(0xFF82958F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE0EAE7))),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Need help signing in? Contact your administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF667B76),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHero({required bool compact}) {
    final horizontalPadding = compact ? 22.0 : 54.0;
    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/DN_fairytale_pages/login_iamge.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: compact ? 24 : 48,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF062C27).withValues(alpha: 0.58),
              const Color(0xFF0A463F).withValues(alpha: 0.80),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: compact
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Living\nMade Better',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 30 : 46,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Manage your home, payments, and community — all in one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: compact ? 14 : 17,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 34),
                  const Wrap(
                    spacing: 22,
                    runSpacing: 14,
                    children: [
                      _LoginFeature(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Online\nPayments',
                      ),
                      _LoginFeature(
                        icon: Icons.receipt_long_outlined,
                        label: 'View\nStatements',
                      ),
                      _LoginFeature(
                        icon: Icons.notifications_none_rounded,
                        label: 'Stay\nInformed',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLogo({required bool compact}) {
    return Image.asset(
      'secura_logo.png',
      width: compact ? 248 : 320,
      height: compact ? 198 : 243,
      fit: BoxFit.contain,
    );
  }

  Widget _buildMobileLoginHeroContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Living\nMade Better',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Manage your home, payments, and community — all in one place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FBF9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 11, child: _buildLoginHero(compact: false)),
                  Expanded(
                    flex: 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF9FBF8),
                                Color(0xFFF5F6F1),
                              ],
                            ),
                          ),
                        ),
                        const CustomPaint(
                          painter: _LoginBackdropPattern(),
                        ),
                        Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 28,
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildLoginLogo(compact: false),
                                  const SizedBox(height: 8),
                                  _buildLoginForm(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return SizedBox(
              width: double.infinity,
              height: constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Image(
                    image: AssetImage('lib/DN_fairytale_pages/login_iamge.png'),
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99062C27),
                          Color(0xCC0A463F),
                          Color(0xF20A463F),
                        ],
                      ),
                    ),
                  ),
                  const CustomPaint(
                    painter: _LoginBackdropPattern(onPhoto: true),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 44,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMobileLoginHeroContent(),
                          const SizedBox(height: 8),
                          _buildLoginLogo(compact: true),
                          const SizedBox(height: 14),
                          _buildLoginForm(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginBackdropPattern extends CustomPainter {
  const _LoginBackdropPattern({this.onPhoto = false});

  final bool onPhoto;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = onPhoto
          ? Colors.white.withValues(alpha: 0.13)
          : const Color(0xFF927F68).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final topPattern = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.87, size.height * 0.13)
      ..lineTo(size.width, size.height * 0.04)
      ..moveTo(size.width * 0.68, 0)
      ..lineTo(size.width * 0.87, size.height * 0.17)
      ..lineTo(size.width, size.height * 0.08)
      ..moveTo(size.width * 0.64, 0)
      ..lineTo(size.width * 0.87, size.height * 0.21)
      ..lineTo(size.width, size.height * 0.12);
    canvas.drawPath(topPattern, paint);

    final bottomPattern = Path()
      ..moveTo(0, size.height * 0.76)
      ..lineTo(size.width * 0.17, size.height * 0.91)
      ..lineTo(size.width * 0.34, size.height * 0.80)
      ..lineTo(size.width * 0.48, size.height)
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.17, size.height * 0.97)
      ..lineTo(size.width * 0.30, size.height * 0.88)
      ..lineTo(size.width * 0.39, size.height);
    canvas.drawPath(bottomPattern, paint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPattern oldDelegate) {
    return oldDelegate.onPhoto != onPhoto;
  }
}

class _LoginFeature extends StatelessWidget {
  const _LoginFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(13),
              color: Colors.white.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
