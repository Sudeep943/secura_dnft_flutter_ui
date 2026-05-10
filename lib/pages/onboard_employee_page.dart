import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/browser_face_detector_stub.dart'
    if (dart.library.html) '../services/browser_face_detector_web.dart'
    as browser_face_detector;
import '../services/api_service.dart';

enum StaffManagementPanel {
  onboardEmployee,
  todayAttendance,
  employeeAttendance,
}

class OnboardEmployeePage extends StatefulWidget {
  const OnboardEmployeePage({
    super.key,
    this.embedded = false,
    this.onBack,
    this.initialPanel = StaffManagementPanel.onboardEmployee,
  });

  final bool embedded;
  final VoidCallback? onBack;
  final StaffManagementPanel initialPanel;

  @override
  State<OnboardEmployeePage> createState() => _OnboardEmployeePageState();
}

class _OnboardEmployeePageState extends State<OnboardEmployeePage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final _formKey = GlobalKey<FormState>();
  final _employeeCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeSearchController = TextEditingController();

  StaffManagementPanel _selectedPanel = StaffManagementPanel.onboardEmployee;
  bool _submitting = false;
  bool _loadingToday = false;
  bool _loadingEmployeeAttendance = false;
  List<Uint8List> _selectedImages = [];
  Map<String, dynamic>? _todayAttendanceResponse;
  Map<String, dynamic>? _employeeAttendanceResponse;

  @override
  void initState() {
    super.initState();
    _selectedPanel = widget.initialPanel;
    if (_selectedPanel == StaffManagementPanel.todayAttendance) {
      _loadTodayAttendance();
    }
  }

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }

  Future<void> _captureFaceImages() async {
    final images = await showDialog<List<Uint8List>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FaceCaptureDialog(requiredPhotoCount: 50),
    );

    if (images == null) {
      return;
    }

    if (images.isEmpty) {
      _showSnackBar('No camera photos were captured.');
      return;
    }

    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.length < 50) {
      _showSnackBar('Capture at least 50 face frames for onboarding.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final response = await ApiService.onboardEmployee(
        employeeCode: _employeeCodeController.text,
        fullName: _fullNameController.text,
        department: _departmentController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        images: _selectedImages,
      );

      if (!mounted) {
        return;
      }

      final success = response?['success'] == true;
      final message =
          response?['message']?.toString() ??
          'Unable to complete employee onboarding.';

      _showSnackBar(message, success: success);
      if (success) {
        _formKey.currentState!.reset();
        _employeeCodeController.clear();
        _fullNameController.clear();
        _departmentController.clear();
        _phoneController.clear();
        _emailController.clear();
        setState(() {
          _selectedImages = [];
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Employee onboarding failed. Check the backend response.');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _loadingToday = true;
    });

    try {
      final response = await ApiService.getTodayAttendance();
      if (!mounted) {
        return;
      }
      setState(() {
        _todayAttendanceResponse = response;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingToday = false;
        });
      }
    }
  }

  Future<void> _searchEmployeeAttendance() async {
    final code = _employeeSearchController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Enter an employee code to search attendance.');
      return;
    }

    setState(() {
      _loadingEmployeeAttendance = true;
    });

    try {
      final response = await ApiService.getAttendanceByEmployeeCode(code);
      if (!mounted) {
        return;
      }
      setState(() {
        _employeeAttendanceResponse = response;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingEmployeeAttendance = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _brandColor : Colors.redAccent,
      ),
    );
  }

  List<Map<String, dynamic>> _recordsFromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawRecords = response?['records'];
    if (rawRecords is! List) {
      return const [];
    }

    return rawRecords
        .whereType<Map>()
        .map((record) => Map<String, dynamic>.from(record))
        .toList();
  }

  String _displayValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBack != null)
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee Attendance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _brandTextColor,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Onboard employees and review attendance records from the admin section.',
                style: TextStyle(color: Colors.black54, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanelSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildPanelChip(
          StaffManagementPanel.onboardEmployee,
          'Onboard Employee',
          Icons.person_add_alt_1_outlined,
        ),
        _buildPanelChip(
          StaffManagementPanel.todayAttendance,
          'Today Attendance',
          Icons.today_outlined,
        ),
        _buildPanelChip(
          StaffManagementPanel.employeeAttendance,
          'Employee Attendance',
          Icons.badge_outlined,
        ),
      ],
    );
  }

  Widget _buildPanelChip(
    StaffManagementPanel panel,
    String label,
    IconData icon,
  ) {
    final selected = panel == _selectedPanel;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        setState(() {
          _selectedPanel = panel;
        });
        if (panel == StaffManagementPanel.todayAttendance &&
            _todayAttendanceResponse == null) {
          _loadTodayAttendance();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _brandColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? _brandColor : const Color(0xFFDDE9E6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : _brandTextColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _brandTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EFED)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 59, 52, 0.07),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildOnboardPanel() {
    return Stack(
      children: [
        _buildPanelCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Onboard Employee',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _brandTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Capture employee details and upload at least 50 face frames for backend enrollment.',
                  style: TextStyle(color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 260,
                      child: _buildTextField(
                        controller: _employeeCodeController,
                        label: 'Employee Code',
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Employee code is required.'
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Full name is required.'
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: _buildTextField(
                        controller: _departmentController,
                        label: 'Department',
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Department is required.'
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _submitting ? null : _captureFaceImages,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Capture Face Photos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    Text(
                      _selectedImages.isEmpty
                          ? 'Record a short face rotation capture for onboarding (target: 50 frames).'
                          : '${_selectedImages.length} frame(s) captured',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _selectedImages[index],
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemCount: _selectedImages.length,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submitOnboarding,
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Onboarding'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_submitting)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xAAFFFFFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Submitting onboarding data...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttendanceTable(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Text('No attendance records found for the current selection.'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Log ID')),
          DataColumn(label: Text('Employee Code')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Department')),
          DataColumn(label: Text('Entry Time')),
          DataColumn(label: Text('Exit Time')),
          DataColumn(label: Text('Device ID')),
          DataColumn(label: Text('Entry Score')),
          DataColumn(label: Text('Exit Score')),
        ],
        rows: records
            .map(
              (record) => DataRow(
                cells: [
                  DataCell(Text(_displayValue(record['logId']))),
                  DataCell(Text(_displayValue(record['employeeCode']))),
                  DataCell(Text(_displayValue(record['employeeName']))),
                  DataCell(Text(_displayValue(record['department']))),
                  DataCell(Text(_displayValue(record['entryTime']))),
                  DataCell(Text(_displayValue(record['exitTime']))),
                  DataCell(Text(_displayValue(record['deviceId']))),
                  DataCell(Text(_displayValue(record['matchScoreEntry']))),
                  DataCell(Text(_displayValue(record['matchScoreExit']))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTodayAttendancePanel() {
    final response = _todayAttendanceResponse;
    final records = _recordsFromResponse(response);

    return _buildPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today Attendance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _brandTextColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Review all entry and exit records recorded for the current date.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadingToday ? null : _loadTodayAttendance,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingToday)
            const Center(child: CircularProgressIndicator())
          else ...[
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _buildSummaryTile('Date', _displayValue(response?['date'])),
                _buildSummaryTile(
                  'Total Present',
                  _displayValue(response?['totalPresent']),
                ),
                _buildSummaryTile(
                  'Status',
                  response?['success'] == true ? 'Loaded' : 'Check response',
                ),
              ],
            ),
            const SizedBox(height: 20),
            if ((response?['message']?.toString().trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  response!['message'].toString(),
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            _buildAttendanceTable(records),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeAttendancePanel() {
    final response = _employeeAttendanceResponse;
    final records = _recordsFromResponse(response);

    return _buildPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employee Attendance Lookup',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _brandTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search by employee code to fetch that employee\'s attendance records.',
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _employeeSearchController,
                  decoration: InputDecoration(
                    labelText: 'Employee Code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onSubmitted: (_) => _searchEmployeeAttendance(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _loadingEmployeeAttendance
                    ? null
                    : _searchEmployeeAttendance,
                style: FilledButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingEmployeeAttendance)
            const Center(child: CircularProgressIndicator())
          else if (response != null) ...[
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _buildSummaryTile(
                  'Employee',
                  _displayValue(response['employeeName']),
                ),
                _buildSummaryTile(
                  'Department',
                  _displayValue(response['department']),
                ),
                _buildSummaryTile(
                  'Employee Code',
                  _displayValue(response['employeeCode']),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if ((response['message']?.toString().trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  response['message'].toString(),
                  style: TextStyle(
                    color: response['success'] == true
                        ? Colors.black54
                        : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildAttendanceTable(records),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPanelSelector(),
              const SizedBox(height: 24),
              if (_selectedPanel == StaffManagementPanel.onboardEmployee)
                _buildOnboardPanel(),
              if (_selectedPanel == StaffManagementPanel.todayAttendance)
                _buildTodayAttendancePanel(),
              if (_selectedPanel == StaffManagementPanel.employeeAttendance)
                _buildEmployeeAttendancePanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceCaptureDialog extends StatefulWidget {
  const _FaceCaptureDialog({required this.requiredPhotoCount});

  final int requiredPhotoCount;

  @override
  State<_FaceCaptureDialog> createState() => _FaceCaptureDialogState();
}

class _FaceCaptureDialogState extends State<_FaceCaptureDialog> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _initializing = true;
  bool _capturing = false;
  bool _recordingRotation = false;
  bool _hasShownValidationUnavailableHint = false;
  String? _errorMessage;
  String? _captureStatus;
  final List<Uint8List> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
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
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _initializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = error.description ?? 'Unable to access the camera.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _errorMessage = 'Unable to start the camera for face capture.';
      });
    }
  }

  Future<void> _captureRotationSequence() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        _recordingRotation) {
      return;
    }

    setState(() {
      _recordingRotation = true;
      _capturing = true;
      _errorMessage = null;
      _captureStatus =
          'Capturing short rotation sequence. Slowly rotate face left to right.';
      _capturedImages.clear();
    });

    var attempts = 0;
    var validCaptured = 0;
    final targetFrames = widget.requiredPhotoCount;
    final maxAttempts = targetFrames * 3;

    try {
      while (attempts < maxAttempts && validCaptured < targetFrames) {
        attempts++;
        if (!mounted) {
          return;
        }

        if (attempts > 1) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
        }

        final picture = await controller.takePicture();
        final bytes = await picture.readAsBytes();

        final faceValidationResult = await _validateSingleFace(
          imagePath: picture.path,
          bytes: bytes,
        );

        if (faceValidationResult == false) {
          continue;
        }

        if (faceValidationResult == null &&
            !_hasShownValidationUnavailableHint) {
          _hasShownValidationUnavailableHint = true;
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Face-quality check unavailable on this device. Keep face centered and well-lit.';
            });
          }
        }

        _capturedImages.add(bytes);
        validCaptured++;

        if (mounted) {
          setState(() {
            _captureStatus =
                'Captured $validCaptured/$targetFrames frame(s). Keep rotating slowly.';
          });
        }
      }

      if (!mounted) {
        return;
      }

      if (_capturedImages.length < targetFrames) {
        setState(() {
          _errorMessage =
              'Could not capture $targetFrames valid face frames. Improve lighting and retry.';
        });
      } else {
        setState(() {
          _captureStatus =
              'Capture complete. ${_capturedImages.length} valid frame(s) ready.';
        });
      }
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.description ?? 'Unable to capture video frames.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to complete short face video capture.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _recordingRotation = false;
        });
      }
    }
  }

  void _clearCapturedPhotos() {
    setState(() {
      _capturedImages.clear();
      _captureStatus = null;
      _errorMessage = null;
    });
  }

  Future<bool?> _validateSingleFace({
    required String imagePath,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      final faceCount = await browser_face_detector.detectFacesFromBytes(bytes);
      if (faceCount == null) {
        return null;
      }
      return faceCount == 1;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.12,
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector!.processImage(inputImage);
      return faces.length == 1;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    final hasPreview = controller != null && controller.value.isInitialized;
    final remaining = widget.requiredPhotoCount - _capturedImages.length;
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 620 ? 520.0 : size.width * 0.9;
    final dialogHeight = size.height * 0.52;

    return AlertDialog(
      title: const Text('Capture Face Photos'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              remaining > 0
                  ? 'Capture $remaining more frame(s). Keep face centered, look straight, and avoid bright light behind the head.'
                  : 'All required photos captured. Review and continue.',
              style: const TextStyle(height: 1.35),
            ),
            if ((_captureStatus ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _captureStatus!,
                style: const TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFF0D1F1C),
                  child: _initializing
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : hasPreview
                      ? CameraPreview(controller)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _errorMessage ?? 'Camera preview unavailable.',
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_capturedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _capturedImages[index],
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: _capturing || _recordingRotation
              ? null
              : () => Navigator.of(context).pop<List<Uint8List>>(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _capturing || _recordingRotation || _capturedImages.isEmpty
              ? null
              : _clearCapturedPhotos,
          child: const Text('Clear Frames'),
        ),
        FilledButton.icon(
          onPressed: _capturing || _recordingRotation || !hasPreview
              ? null
              : _captureRotationSequence,
          icon: _capturing || _recordingRotation
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.videocam_outlined),
          label: Text(
            _recordingRotation ? 'Recording...' : 'Capture Short Video',
          ),
        ),
        FilledButton(
          onPressed: _capturedImages.length >= widget.requiredPhotoCount
              ? () => Navigator.of(
                  context,
                ).pop<List<Uint8List>>(List<Uint8List>.from(_capturedImages))
              : null,
          child: Text('Use ${widget.requiredPhotoCount} Frames'),
        ),
      ],
    );
  }
}
