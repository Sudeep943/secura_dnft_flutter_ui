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
import '../widgets/brand_artwork.dart';
import 'app_shell.dart';

enum _LoginMode { username, faceDetection }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final username = TextEditingController();
  final password = TextEditingController();
  final _passwordFocusNode = FocusNode();

  _LoginMode _loginMode = _LoginMode.username;

  bool loading = false;
  bool _obscurePassword = true;
  bool _cameraInitializing = false;
  bool _faceValidated = false;
  bool _isProcessingCameraFrame = false;
  DateTime? _lastProcessedFrameAt;
  String _faceStatusMessage =
      'Switch to face detection to activate the camera.';
  String? _cameraErrorMessage;

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  Timer? _webValidationTimer;

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
      _faceStatusMessage = mode == _LoginMode.faceDetection
          ? 'Starting the camera for face validation.'
          : 'Switch to face detection to activate the camera.';
    });

    if (mode == _LoginMode.faceDetection) {
      await _startFaceDetectionCamera();
      return;
    }

    await _stopFaceDetectionCamera();
  }

  Future<void> _startFaceDetectionCamera() async {
    await _stopFaceDetectionCamera();

    final browserFaceDetectorUnavailableReason = kIsWeb
        ? await browser_face_detector.getBrowserFaceDetectorUnavailableReason()
        : null;

    if (!await _supportsLiveFaceDetection()) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraInitializing = false;
        _cameraErrorMessage = kIsWeb
            ? browserFaceDetectorUnavailableReason ??
                  'Browser face detection is unavailable in this browser.'
            : 'Face detection is available on Android, iOS, and supported web browsers. Windows desktop needs a native desktop face-detection backend.';
        _faceValidated = false;
        _faceStatusMessage = kIsWeb
            ? 'Use username or phone login, or open the app where browser face detection is available.'
            : 'Use Android, iOS, or a supported web browser for live face validation.';
      });
      return;
    }

    setState(() {
      _cameraInitializing = true;
      _cameraErrorMessage = null;
      _faceValidated = false;
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
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (_loginMode != _LoginMode.faceDetection) {
        await controller.dispose();
        return;
      }

      final detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.12,
        ),
      );

      _cameraController = controller;
      if (!kIsWeb) {
        _faceDetector = detector;

        await controller.startImageStream((image) {
          _handleCameraFrame(image, selectedCamera);
        });
      } else {
        await detector.close();
        _startWebFaceValidationLoop();
      }

      if (!mounted || _loginMode != _LoginMode.faceDetection) {
        return;
      }

      setState(() {
        _cameraInitializing = false;
        _faceStatusMessage = kIsWeb
            ? 'Center one face in the frame while the browser validates it.'
            : 'Center one face in the frame to enable face-validated login.';
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraInitializing = false;
        _cameraErrorMessage =
            error.description ?? 'Unable to access the camera.';
        _faceStatusMessage = 'Camera access is required for face validation.';
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

    if (!mounted || _loginMode == _LoginMode.faceDetection) {
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
        _loginMode != _LoginMode.faceDetection ||
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

      if (!mounted || _loginMode != _LoginMode.faceDetection) {
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
          _faceStatusMessage =
              'Face detected. You can continue with face-validated login.';
        } else if (faceCount == 0) {
          _faceStatusMessage =
              'No face detected. Move closer and face the camera.';
        } else {
          _faceStatusMessage =
              'Multiple faces detected. Keep only one face visible.';
        }
      });
    } catch (_) {
      if (!mounted || _loginMode != _LoginMode.faceDetection) {
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
        _loginMode != _LoginMode.faceDetection ||
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
      if (!mounted || _loginMode != _LoginMode.faceDetection) {
        return;
      }

      final hasSingleFace = faces.length == 1;
      setState(() {
        _faceValidated = hasSingleFace;
        if (hasSingleFace) {
          _faceStatusMessage =
              'Face detected. You can continue with face-validated login.';
        } else if (faces.isEmpty) {
          _faceStatusMessage =
              'No face detected. Move closer and face the camera.';
        } else {
          _faceStatusMessage =
              'Multiple faces detected. Keep only one face visible.';
        }
      });
    } catch (_) {
      if (!mounted || _loginMode != _LoginMode.faceDetection) {
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
            'Face detection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _brandTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The camera starts automatically. Login is enabled after one face is visible in the frame.',
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

    final message = response?['message']?.toString() ?? 'Unable to verify OTP.';
    final messageCode = response?['messageCode']?.toString() ?? '';

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
      final updateMessage =
          updateResponse?['message']?.toString() ??
          'Unable to update password.';
      final updateCode = updateResponse?['messageCode']?.toString() ?? '';

      if (updateCode.startsWith('SUCC')) {
        password.text = newPassword;
        await _showMessageDialog(title: 'Success', message: updateMessage);
      } else {
        await _showMessageDialog(title: 'Error', message: updateMessage);
      }
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
        message: _loginMode == _LoginMode.faceDetection
            ? 'Username, password, and face validation are required.'
            : 'Username and password are required.',
      );
      return;
    }

    if (_loginMode == _LoginMode.faceDetection) {
      if (_cameraInitializing) {
        await _showMessageDialog(
          title: 'Camera Starting',
          message: 'Wait for the camera to finish starting before logging in.',
        );
        return;
      }

      if (_cameraErrorMessage != null) {
        await _showMessageDialog(
          title: 'Face Detection Unavailable',
          message: _cameraErrorMessage!,
        );
        return;
      }

      if (!_faceValidated) {
        await _showMessageDialog(
          title: 'Face Validation Required',
          message:
              'Keep exactly one face visible in the camera before continuing.',
        );
        return;
      }
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

    final message =
        response?['message']?.toString() ?? 'Unable to complete login.';
    final messageCode = response?['messageCode']?.toString() ?? '';

    if (response == null) {
      await _showMessageDialog(title: 'Error', message: message);
      return;
    }

    if (messageCode.startsWith('SUCC')) {
      await _completeLogin(trimmedUsername);
      return;
    }

    if (messageCode == 'ERR_MESSAGE_29') {
      await _handleOtpChallenge(
        loginMessage: message,
        userName: trimmedUsername,
        currentPassword: trimmedPassword,
      );
      return;
    }

    await _showMessageDialog(title: 'Error', message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF7FBFA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 64,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandLogo(width: 260),
                const SizedBox(height: 28),
                Center(
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 15),
                      ],
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F8F82),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              _buildLoginModeOption(
                                mode: _LoginMode.username,
                                label: 'Login by Username',
                                icon: Icons.person_outline,
                              ),
                              _buildLoginModeOption(
                                mode: _LoginMode.faceDetection,
                                label: 'Face Detection',
                                icon: Icons.face_outlined,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_loginMode == _LoginMode.faceDetection) ...[
                          _buildFaceDetectionPanel(),
                          const SizedBox(height: 20),
                        ],

                        TextField(
                          controller: username,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocusNode);
                          },
                          decoration: const InputDecoration(
                            labelText: "Username / Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: password,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitIfReady(),
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
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
                              ),
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: loading ? null : _submitIfReady,
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _loginMode == _LoginMode.faceDetection
                                        ? 'Validate Face & Login'
                                        : 'Login',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
