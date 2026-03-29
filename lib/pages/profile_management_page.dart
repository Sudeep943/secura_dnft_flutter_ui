import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementDraft {
  static _ProfileManagementSection? selectedSection;

  static final Map<String, String> createProfile = {};
  static String? createProfileType;
  static String? createProfilePosition;
  static String? createProfileKind;
  static String? createGender;
  static bool createHasOtherAddress = false;
  static String createAddressType = 'RESIDENTIAL';
  static String createPrimaryAddressType = 'RESIDENTIAL';
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const List<String> _createProfileTypeOptions = [
    'OWNER',
    'TENANT',
    'STAFF',
  ];
  static const List<String> _createStaffPositionOptions = [
    'Electrician',
    'Plumber',
    'Estate Manger',
  ];
  static const List<String> _profileKindOptions = [
    'Indivisual',
    'Organization',
  ];

  final _createProfileFormKey = GlobalKey<FormState>();
  final _updateProfileFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _profileFlatNoController = TextEditingController();
  final _profileDobController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _landlineNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _addressLine3Controller = TextEditingController();
  final _addressLine4Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postOfficeController = TextEditingController();
  final _policeStationController = TextEditingController();
  final _pinController = TextEditingController();
  final _primaryAddressLine1Controller = TextEditingController();
  final _primaryAddressLine2Controller = TextEditingController();
  final _primaryAddressLine3Controller = TextEditingController();
  final _primaryAddressLine4Controller = TextEditingController();
  final _primaryLandmarkController = TextEditingController();
  final _primaryCityController = TextEditingController();
  final _primaryStateController = TextEditingController();
  final _primaryPostOfficeController = TextEditingController();
  final _primaryPoliceStationController = TextEditingController();
  final _primaryPinController = TextEditingController();

  final _updateFirstNameController = TextEditingController();
  final _updateMiddleNameController = TextEditingController();
  final _updateLastNameController = TextEditingController();
  final _updateProfileIdController = TextEditingController();
  final _updateApartmentNameController = TextEditingController();
  final _updateProfileDobController = TextEditingController();
  final _updateProfileFlatNoController = TextEditingController();
  final _updateMobileNumberController = TextEditingController();
  final _updateEmailIdController = TextEditingController();
  final _updateLandlineNumberController = TextEditingController();
  final _updateAddressLine1Controller = TextEditingController();
  final _updateAddressLine2Controller = TextEditingController();
  final _updateAddressLine3Controller = TextEditingController();
  final _updateAddressLine4Controller = TextEditingController();
  final _updateLandmarkController = TextEditingController();
  final _updateCityController = TextEditingController();
  final _updateStateController = TextEditingController();
  final _updatePostOfficeController = TextEditingController();
  final _updatePoliceStationController = TextEditingController();
  final _updatePinController = TextEditingController();
  final _updatePrimaryAddressLine1Controller = TextEditingController();
  final _updatePrimaryAddressLine2Controller = TextEditingController();
  final _updatePrimaryAddressLine3Controller = TextEditingController();
  final _updatePrimaryAddressLine4Controller = TextEditingController();
  final _updatePrimaryLandmarkController = TextEditingController();
  final _updatePrimaryCityController = TextEditingController();
  final _updatePrimaryStateController = TextEditingController();
  final _updatePrimaryPostOfficeController = TextEditingController();
  final _updatePrimaryPoliceStationController = TextEditingController();
  final _updatePrimaryPinController = TextEditingController();

  _ProfileManagementSection? _selectedSection;
  String? _profileType;
  String? _profilePosition;
  String? _profileKind;
  String? _gender;
  bool _createHasOtherAddress = false;
  String _addressType = 'RESIDENTIAL';
  String _primaryAddressType = 'RESIDENTIAL';
  String? _updateGender;
  bool _updateDeleteOtherAddress = false;
  String _updateAddressType = 'RESIDENTIAL';
  String _updatePrimaryAddressType = 'RESIDENTIAL';
  String? _updateProfileType;
  String? _updateProfilePosition;
  String? _updateProfileStatus;
  String? _updateRole;
  bool _creatingProfile = false;
  bool _loadingProfile = false;
  bool _updatingProfile = false;
  Map<String, dynamic>? _loadedProfile;
  String? _currentProfilePicBase64;
  String? _selectedProfileImageBase64;
  Uint8List? _selectedProfileImageBytes;

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  void initState() {
    super.initState();
    _restoreDrafts();
    _attachCreateDraftListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedSection == _ProfileManagementSection.updateProfile ||
          _selectedSection == _ProfileManagementSection.viewProfile) {
        _loadProfileForUpdate();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _profileFlatNoController.dispose();
    _profileDobController.dispose();
    _mobileNumberController.dispose();
    _emailIdController.dispose();
    _landlineNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _addressLine3Controller.dispose();
    _addressLine4Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postOfficeController.dispose();
    _policeStationController.dispose();
    _pinController.dispose();
    _primaryAddressLine1Controller.dispose();
    _primaryAddressLine2Controller.dispose();
    _primaryAddressLine3Controller.dispose();
    _primaryAddressLine4Controller.dispose();
    _primaryLandmarkController.dispose();
    _primaryCityController.dispose();
    _primaryStateController.dispose();
    _primaryPostOfficeController.dispose();
    _primaryPoliceStationController.dispose();
    _primaryPinController.dispose();
    _updateFirstNameController.dispose();
    _updateMiddleNameController.dispose();
    _updateLastNameController.dispose();
    _updateProfileIdController.dispose();
    _updateApartmentNameController.dispose();
    _updateProfileDobController.dispose();
    _updateProfileFlatNoController.dispose();
    _updateMobileNumberController.dispose();
    _updateEmailIdController.dispose();
    _updateLandlineNumberController.dispose();
    _updateAddressLine1Controller.dispose();
    _updateAddressLine2Controller.dispose();
    _updateAddressLine3Controller.dispose();
    _updateAddressLine4Controller.dispose();
    _updateLandmarkController.dispose();
    _updateCityController.dispose();
    _updateStateController.dispose();
    _updatePostOfficeController.dispose();
    _updatePoliceStationController.dispose();
    _updatePinController.dispose();
    _updatePrimaryAddressLine1Controller.dispose();
    _updatePrimaryAddressLine2Controller.dispose();
    _updatePrimaryAddressLine3Controller.dispose();
    _updatePrimaryAddressLine4Controller.dispose();
    _updatePrimaryLandmarkController.dispose();
    _updatePrimaryCityController.dispose();
    _updatePrimaryStateController.dispose();
    _updatePrimaryPostOfficeController.dispose();
    _updatePrimaryPoliceStationController.dispose();
    _updatePrimaryPinController.dispose();
    super.dispose();
  }

  void _restoreDrafts() {
    _selectedSection = _ProfileManagementDraft.selectedSection;

    _firstNameController.text =
        _ProfileManagementDraft.createProfile['firstName'] ?? '';
    _middleNameController.text =
        _ProfileManagementDraft.createProfile['middleName'] ?? '';
    _lastNameController.text =
        _ProfileManagementDraft.createProfile['lastName'] ?? '';
    _profileFlatNoController.text =
        _ProfileManagementDraft.createProfile['profileFlatNo'] ?? '';
    _profileDobController.text =
        _ProfileManagementDraft.createProfile['profileDob'] ?? '';
    _mobileNumberController.text =
        _ProfileManagementDraft.createProfile['mobileNumber'] ?? '';
    _emailIdController.text =
        _ProfileManagementDraft.createProfile['emailId'] ?? '';
    _landlineNumberController.text =
        _ProfileManagementDraft.createProfile['landlineNumber'] ?? '';
    _addressLine1Controller.text =
        _ProfileManagementDraft.createProfile['addressLine1'] ?? '';
    _addressLine2Controller.text =
        _ProfileManagementDraft.createProfile['addressLine2'] ?? '';
    _addressLine3Controller.text =
        _ProfileManagementDraft.createProfile['addressLine3'] ?? '';
    _addressLine4Controller.text =
        _ProfileManagementDraft.createProfile['addressLine4'] ?? '';
    _landmarkController.text =
        _ProfileManagementDraft.createProfile['landmark'] ?? '';
    _cityController.text = _ProfileManagementDraft.createProfile['city'] ?? '';
    _stateController.text =
        _ProfileManagementDraft.createProfile['state'] ?? '';
    _postOfficeController.text =
        _ProfileManagementDraft.createProfile['postOffice'] ?? '';
    _policeStationController.text =
        _ProfileManagementDraft.createProfile['policeStation'] ?? '';
    _pinController.text = _ProfileManagementDraft.createProfile['pin'] ?? '';
    _primaryAddressLine1Controller.text =
        _ProfileManagementDraft.createProfile['primaryAddressLine1'] ?? '';
    _primaryAddressLine2Controller.text =
        _ProfileManagementDraft.createProfile['primaryAddressLine2'] ?? '';
    _primaryAddressLine3Controller.text =
        _ProfileManagementDraft.createProfile['primaryAddressLine3'] ?? '';
    _primaryAddressLine4Controller.text =
        _ProfileManagementDraft.createProfile['primaryAddressLine4'] ?? '';
    _primaryLandmarkController.text =
        _ProfileManagementDraft.createProfile['primaryLandmark'] ?? '';
    _primaryCityController.text =
        _ProfileManagementDraft.createProfile['primaryCity'] ?? '';
    _primaryStateController.text =
        _ProfileManagementDraft.createProfile['primaryState'] ?? '';
    _primaryPostOfficeController.text =
        _ProfileManagementDraft.createProfile['primaryPostOffice'] ?? '';
    _primaryPoliceStationController.text =
        _ProfileManagementDraft.createProfile['primaryPoliceStation'] ?? '';
    _primaryPinController.text =
        _ProfileManagementDraft.createProfile['primaryPin'] ?? '';

    _profileType = _ProfileManagementDraft.createProfileType;
    _profilePosition = _ProfileManagementDraft.createProfilePosition;
    _profileKind = _ProfileManagementDraft.createProfileKind;
    _gender = _ProfileManagementDraft.createGender;
    _createHasOtherAddress = _ProfileManagementDraft.createHasOtherAddress;
    _addressType = _ProfileManagementDraft.createAddressType;
    _primaryAddressType = _ProfileManagementDraft.createPrimaryAddressType;
  }

  void _attachCreateDraftListeners() {
    _bindCreateDraftController(_firstNameController, 'firstName');
    _bindCreateDraftController(_middleNameController, 'middleName');
    _bindCreateDraftController(_lastNameController, 'lastName');
    _bindCreateDraftController(_profileFlatNoController, 'profileFlatNo');
    _bindCreateDraftController(_profileDobController, 'profileDob');
    _bindCreateDraftController(_mobileNumberController, 'mobileNumber');
    _bindCreateDraftController(_emailIdController, 'emailId');
    _bindCreateDraftController(_landlineNumberController, 'landlineNumber');
    _bindCreateDraftController(_addressLine1Controller, 'addressLine1');
    _bindCreateDraftController(_addressLine2Controller, 'addressLine2');
    _bindCreateDraftController(_addressLine3Controller, 'addressLine3');
    _bindCreateDraftController(_addressLine4Controller, 'addressLine4');
    _bindCreateDraftController(_landmarkController, 'landmark');
    _bindCreateDraftController(_cityController, 'city');
    _bindCreateDraftController(_stateController, 'state');
    _bindCreateDraftController(_postOfficeController, 'postOffice');
    _bindCreateDraftController(_policeStationController, 'policeStation');
    _bindCreateDraftController(_pinController, 'pin');
    _bindCreateDraftController(
      _primaryAddressLine1Controller,
      'primaryAddressLine1',
    );
    _bindCreateDraftController(
      _primaryAddressLine2Controller,
      'primaryAddressLine2',
    );
    _bindCreateDraftController(
      _primaryAddressLine3Controller,
      'primaryAddressLine3',
    );
    _bindCreateDraftController(
      _primaryAddressLine4Controller,
      'primaryAddressLine4',
    );
    _bindCreateDraftController(_primaryLandmarkController, 'primaryLandmark');
    _bindCreateDraftController(_primaryCityController, 'primaryCity');
    _bindCreateDraftController(_primaryStateController, 'primaryState');
    _bindCreateDraftController(
      _primaryPostOfficeController,
      'primaryPostOffice',
    );
    _bindCreateDraftController(
      _primaryPoliceStationController,
      'primaryPoliceStation',
    );
    _bindCreateDraftController(_primaryPinController, 'primaryPin');
  }

  void _bindCreateDraftController(
    TextEditingController controller,
    String key,
  ) {
    controller.addListener(() {
      _ProfileManagementDraft.createProfile[key] = controller.text;
    });
  }

  void _openSection(_ProfileManagementSection section) {
    setState(() {
      _selectedSection = section;
      _ProfileManagementDraft.selectedSection = section;
    });

    if (section == _ProfileManagementSection.updateProfile ||
        section == _ProfileManagementSection.viewProfile) {
      _loadProfileForUpdate();
    }
  }

  void _closeSection() {
    final closingProfileSection =
        _selectedSection == _ProfileManagementSection.updateProfile ||
        _selectedSection == _ProfileManagementSection.viewProfile;

    setState(() {
      _selectedSection = null;
      _ProfileManagementDraft.selectedSection = null;
    });

    if (closingProfileSection) {
      _clearUpdateProfileForm();
    }
  }

  String _readHeaderValue(List<String> keys, {String fallback = ''}) {
    final header = ApiService.userHeader;
    if (header == null) return fallback;

    for (final key in keys) {
      final value = header[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  Future<void> _showStatusModal({
    required String title,
    required String message,
    required bool isSuccess,
    String? profileId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Color(0xFFF7F4FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            width: double.infinity,
            color: isSuccess ? Colors.green : Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (profileId != null && profileId.trim().isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'Profile ID: $profileId',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  String? _nullableValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String? _nullableControllerValue(TextEditingController controller) {
    return _nullableValue(controller.text);
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  void _setControllerValue(TextEditingController controller, dynamic value) {
    controller.text = _stringValue(value);
  }

  String _formatDate(dynamic value) {
    final raw = _stringValue(value);
    if (raw.length >= 10) {
      return raw.substring(0, 10);
    }

    return raw;
  }

  bool _hasAddressValues({
    required TextEditingController line1Controller,
    required TextEditingController line2Controller,
    required TextEditingController line3Controller,
    required TextEditingController line4Controller,
    required TextEditingController landmarkController,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController postOfficeController,
    required TextEditingController policeStationController,
    required TextEditingController pinController,
  }) {
    final controllers = [
      line1Controller,
      line2Controller,
      line3Controller,
      line4Controller,
      landmarkController,
      cityController,
      stateController,
      postOfficeController,
      policeStationController,
      pinController,
    ];

    return controllers.any((controller) => controller.text.trim().isNotEmpty);
  }

  bool _hasAddressMap(Map<String, dynamic> address) {
    const keys = [
      'addressLine1',
      'addressLine2',
      'addressLine3',
      'addressLine4',
      'landmark',
      'city',
      'state',
      'postOffice',
      'policeStation',
      'pin',
      'addressType',
    ];

    return keys.any((key) => _stringValue(address[key]).isNotEmpty);
  }

  String? _formatDateForRequest(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final parsed = DateTime.parse(trimmed);
      return parsed.toIso8601String();
    } catch (_) {
      return trimmed.contains('T') ? trimmed : '${trimmed}T00:00:00';
    }
  }

  Map<String, dynamic> _buildHeaderRequest() {
    return {
      'userId': _readHeaderValue(['userId']),
      'apartmentId': _readHeaderValue(['apartmentId']),
      'role': _readHeaderValue(['role']),
      'access': _readHeaderValue(['access']),
      'flatNo': _readHeaderValue(['flatNo']),
    };
  }

  Map<String, dynamic> _buildAddressRequest({
    required TextEditingController line1Controller,
    required TextEditingController line2Controller,
    required TextEditingController line3Controller,
    required TextEditingController line4Controller,
    required TextEditingController landmarkController,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController postOfficeController,
    required TextEditingController policeStationController,
    required TextEditingController pinController,
    required String addressType,
  }) {
    return {
      'addressLine1': _nullableControllerValue(line1Controller) ?? '',
      'addressLine2': _nullableControllerValue(line2Controller) ?? '',
      'addressLine3': _nullableControllerValue(line3Controller) ?? '',
      'addressLine4': _nullableControllerValue(line4Controller) ?? '',
      'landmark': _nullableControllerValue(landmarkController) ?? '',
      'city': _nullableControllerValue(cityController) ?? '',
      'state': _nullableControllerValue(stateController) ?? '',
      'postOffice': _nullableControllerValue(postOfficeController) ?? '',
      'policeStation': _nullableControllerValue(policeStationController) ?? '',
      'pin': _nullableControllerValue(pinController) ?? '',
      'addressType': addressType,
    };
  }

  void _populateAddressControllers({
    required Map<String, dynamic> address,
    required TextEditingController line1Controller,
    required TextEditingController line2Controller,
    required TextEditingController line3Controller,
    required TextEditingController line4Controller,
    required TextEditingController landmarkController,
    required TextEditingController cityController,
    required TextEditingController stateController,
    required TextEditingController postOfficeController,
    required TextEditingController policeStationController,
    required TextEditingController pinController,
  }) {
    _setControllerValue(line1Controller, address['addressLine1']);
    _setControllerValue(line2Controller, address['addressLine2']);
    _setControllerValue(line3Controller, address['addressLine3']);
    _setControllerValue(line4Controller, address['addressLine4']);
    _setControllerValue(landmarkController, address['landmark']);
    _setControllerValue(cityController, address['city']);
    _setControllerValue(stateController, address['state']);
    _setControllerValue(postOfficeController, address['postOffice']);
    _setControllerValue(policeStationController, address['policeStation']);
    _setControllerValue(pinController, address['pin']);
  }

  bool _isSuccessResponse(
    Map<String, dynamic> response, {
    required List<String> idKeys,
  }) {
    final messageCode = _stringValue(response['messageCode']);
    if (messageCode.isNotEmpty) {
      return messageCode.startsWith('SUCC');
    }

    for (final key in idKeys) {
      if (_stringValue(response[key]).isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  String? get _effectiveProfileImageBase64 {
    final selectedImage = _nullableValue(_selectedProfileImageBase64);
    if (selectedImage != null) {
      return selectedImage;
    }

    return _nullableValue(_currentProfilePicBase64);
  }

  Uint8List? get _effectiveProfileImageBytes {
    if (_selectedProfileImageBytes != null) {
      return _selectedProfileImageBytes;
    }

    final imageData = _effectiveProfileImageBase64;
    if (imageData == null) {
      return null;
    }

    final encodedValue = imageData.contains(',')
        ? imageData.split(',').last
        : imageData;

    try {
      return base64Decode(encodedValue);
    } catch (_) {
      return null;
    }
  }

  void _populateUpdateProfileForm(Map<String, dynamic> response) {
    final profileName = _mapValue(response['prflName']);
    final contactDetails = _mapValue(response['contactDetails']);
    final otherAddress = _mapValue(response['prflOthrAdrss']);
    final primaryAddress = _mapValue(
      response['primaryAddress'] ??
          response['profilePrimaryPostalAdrss'] ??
          response['prflPrimaryPostalAdrss'],
    );
    final effectivePrimaryAddress = primaryAddress.isNotEmpty
        ? primaryAddress
        : otherAddress;
    final flatList = response['prflFlatNo'];
    final flatValue = flatList is List
        ? flatList.where((value) => _stringValue(value).isNotEmpty).join(', ')
        : response['prflFlatNo'];

    _setControllerValue(_updateFirstNameController, profileName['firstName']);
    _setControllerValue(_updateMiddleNameController, profileName['middleName']);
    _setControllerValue(_updateLastNameController, profileName['lastName']);
    _setControllerValue(_updateProfileIdController, response['prflId']);
    _setControllerValue(
      _updateApartmentNameController,
      response['apartmentName'],
    );
    _updateProfileDobController.text = _formatDate(response['prflDob']);
    _setControllerValue(_updateProfileFlatNoController, flatValue);
    _setControllerValue(
      _updateMobileNumberController,
      contactDetails['mobileNumber'],
    );
    _setControllerValue(_updateEmailIdController, contactDetails['emailId']);
    _setControllerValue(
      _updateLandlineNumberController,
      contactDetails['landlinenumber'],
    );
    _populateAddressControllers(
      address: otherAddress,
      line1Controller: _updateAddressLine1Controller,
      line2Controller: _updateAddressLine2Controller,
      line3Controller: _updateAddressLine3Controller,
      line4Controller: _updateAddressLine4Controller,
      landmarkController: _updateLandmarkController,
      cityController: _updateCityController,
      stateController: _updateStateController,
      postOfficeController: _updatePostOfficeController,
      policeStationController: _updatePoliceStationController,
      pinController: _updatePinController,
    );
    _populateAddressControllers(
      address: effectivePrimaryAddress,
      line1Controller: _updatePrimaryAddressLine1Controller,
      line2Controller: _updatePrimaryAddressLine2Controller,
      line3Controller: _updatePrimaryAddressLine3Controller,
      line4Controller: _updatePrimaryAddressLine4Controller,
      landmarkController: _updatePrimaryLandmarkController,
      cityController: _updatePrimaryCityController,
      stateController: _updatePrimaryStateController,
      postOfficeController: _updatePrimaryPostOfficeController,
      policeStationController: _updatePrimaryPoliceStationController,
      pinController: _updatePrimaryPinController,
    );

    setState(() {
      _loadedProfile = response;
      _updateGender = _nullableValue(_stringValue(response['gender']));
      _updateDeleteOtherAddress = false;
      _updateAddressType =
          _nullableValue(_stringValue(otherAddress['addressType'])) ??
          'RESIDENTIAL';
      _updatePrimaryAddressType =
          _nullableValue(
            _stringValue(effectivePrimaryAddress['addressType']),
          ) ??
          'RESIDENTIAL';
      _updateProfileType = _nullableValue(_stringValue(response['prflType']));
      _updateProfilePosition = _nullableValue(
        _stringValue(response['prflPosition']),
      );
      _updateProfileStatus = _nullableValue(_stringValue(response['prflStus']));
      _updateRole =
          _nullableValue(_stringValue(response['role'])) ??
          _nullableValue(_readHeaderValue(['role']));
      _currentProfilePicBase64 = _nullableValue(
        _stringValue(response['profilePic']),
      );
      _selectedProfileImageBase64 = null;
      _selectedProfileImageBytes = null;
    });
  }

  void _clearUpdateProfileForm() {
    _updateProfileFormKey.currentState?.reset();
    _updateFirstNameController.clear();
    _updateMiddleNameController.clear();
    _updateLastNameController.clear();
    _updateProfileIdController.clear();
    _updateApartmentNameController.clear();
    _updateProfileDobController.clear();
    _updateProfileFlatNoController.clear();
    _updateMobileNumberController.clear();
    _updateEmailIdController.clear();
    _updateLandlineNumberController.clear();
    _updateAddressLine1Controller.clear();
    _updateAddressLine2Controller.clear();
    _updateAddressLine3Controller.clear();
    _updateAddressLine4Controller.clear();
    _updateLandmarkController.clear();
    _updateCityController.clear();
    _updateStateController.clear();
    _updatePostOfficeController.clear();
    _updatePoliceStationController.clear();
    _updatePinController.clear();
    _updatePrimaryAddressLine1Controller.clear();
    _updatePrimaryAddressLine2Controller.clear();
    _updatePrimaryAddressLine3Controller.clear();
    _updatePrimaryAddressLine4Controller.clear();
    _updatePrimaryLandmarkController.clear();
    _updatePrimaryCityController.clear();
    _updatePrimaryStateController.clear();
    _updatePrimaryPostOfficeController.clear();
    _updatePrimaryPoliceStationController.clear();
    _updatePrimaryPinController.clear();
    setState(() {
      _loadedProfile = null;
      _updateGender = null;
      _updateDeleteOtherAddress = false;
      _updateAddressType = 'RESIDENTIAL';
      _updatePrimaryAddressType = 'RESIDENTIAL';
      _updateProfileType = null;
      _updateProfilePosition = null;
      _updateProfileStatus = null;
      _updateRole = null;
      _currentProfilePicBase64 = null;
      _selectedProfileImageBase64 = null;
      _selectedProfileImageBytes = null;
    });
  }

  Future<void> _loadProfileForUpdate({bool showErrorModal = true}) async {
    final requestedProfileId = _readHeaderValue(['userId']);
    if (requestedProfileId.isEmpty) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Profile Fetch Failed',
          message: 'Unable to find the user ID required to fetch the profile.',
          isSuccess: false,
        );
      }
      return;
    }

    setState(() {
      _loadingProfile = true;
    });

    final response = await ApiService.getProfile(profileId: requestedProfileId);
    if (!mounted) return;

    setState(() {
      _loadingProfile = false;
    });

    if (response == null) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Profile Fetch Failed',
          message: 'No response was returned from the server.',
          isSuccess: false,
        );
      }
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['prflId']);
    if (!isSuccess) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Profile Fetch Failed',
          message: _stringValue(response['message']).isNotEmpty
              ? _stringValue(response['message'])
              : 'Unable to load the selected profile.',
          isSuccess: false,
          profileId: _stringValue(response['prflId']),
        );
      }
      return;
    }

    _populateUpdateProfileForm(response);
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final selectedFile = result.files.single;
    final bytes = selectedFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      await _showStatusModal(
        title: 'Profile Picture Failed',
        message: 'The selected image could not be read.',
        isSuccess: false,
      );
      return;
    }

    final editedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _ProfileImageEditorDialog(imageBytes: bytes);
      },
    );

    if (!mounted || editedBytes == null || editedBytes.isEmpty) {
      return;
    }

    setState(() {
      _selectedProfileImageBytes = editedBytes;
      _selectedProfileImageBase64 = base64Encode(editedBytes);
    });
  }

  Future<void> _submitUpdateProfile() async {
    final form = _updateProfileFormKey.currentState;
    if (form == null || !form.validate()) return;

    final header = _buildHeaderRequest();
    if (header.values.every((value) => _stringValue(value).isEmpty)) {
      await _showStatusModal(
        title: 'Profile Update Failed',
        message: 'Unable to find login header details for this request.',
        isSuccess: false,
      );
      return;
    }

    final profileId = _stringValue(_loadedProfile?['prflId']);
    if (profileId.isEmpty) {
      await _showStatusModal(
        title: 'Profile Update Failed',
        message: 'Load a profile before trying to update it.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _updatingProfile = true;
    });

    final requestBody = {
      'header': header,
      'profileId': profileId,
      'profileName': {
        'firstName': _updateFirstNameController.text.trim(),
        'middleName': _updateMiddleNameController.text.trim(),
        'lastName': _updateLastNameController.text.trim(),
      },
      'profileFlatNo': _updateProfileFlatNoController.text.trim(),
      'contact': {
        'mobileNumber': _updateMobileNumberController.text.trim(),
        'emailId': _updateEmailIdController.text.trim(),
        'landlinenumber': _nullableControllerValue(
          _updateLandlineNumberController,
        ),
      },
      'profileOthrAdrss': _updateDeleteOtherAddress
          ? null
          : (_hasAddressValues(
                  line1Controller: _updateAddressLine1Controller,
                  line2Controller: _updateAddressLine2Controller,
                  line3Controller: _updateAddressLine3Controller,
                  line4Controller: _updateAddressLine4Controller,
                  landmarkController: _updateLandmarkController,
                  cityController: _updateCityController,
                  stateController: _updateStateController,
                  postOfficeController: _updatePostOfficeController,
                  policeStationController: _updatePoliceStationController,
                  pinController: _updatePinController,
                )
                ? _buildAddressRequest(
                    line1Controller: _updateAddressLine1Controller,
                    line2Controller: _updateAddressLine2Controller,
                    line3Controller: _updateAddressLine3Controller,
                    line4Controller: _updateAddressLine4Controller,
                    landmarkController: _updateLandmarkController,
                    cityController: _updateCityController,
                    stateController: _updateStateController,
                    postOfficeController: _updatePostOfficeController,
                    policeStationController: _updatePoliceStationController,
                    pinController: _updatePinController,
                    addressType: _updateAddressType,
                  )
                : null),
      'profilePrimaryPostalAdrss': _buildAddressRequest(
        line1Controller: _updatePrimaryAddressLine1Controller,
        line2Controller: _updatePrimaryAddressLine2Controller,
        line3Controller: _updatePrimaryAddressLine3Controller,
        line4Controller: _updatePrimaryAddressLine4Controller,
        landmarkController: _updatePrimaryLandmarkController,
        cityController: _updatePrimaryCityController,
        stateController: _updatePrimaryStateController,
        postOfficeController: _updatePrimaryPostOfficeController,
        policeStationController: _updatePrimaryPoliceStationController,
        pinController: _updatePrimaryPinController,
        addressType: _updatePrimaryAddressType,
      ),
      'profileType': _updateProfileType,
      'profilePosition': _updateProfilePosition,
      'profilePic': _effectiveProfileImageBase64,
      'password': ApiService.loginPassword ?? '',
      'profileStatus': _updateProfileStatus,
      'role': _updateRole,
    };

    final response = await ApiService.updateProfile(requestBody);
    if (!mounted) return;

    setState(() {
      _updatingProfile = false;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Profile Update Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
        profileId: profileId,
      );
      return;
    }

    final responseProfileId = _stringValue(response['profileId']);
    final isSuccess = _isSuccessResponse(response, idKeys: const ['profileId']);
    final message = _stringValue(response['message']).isNotEmpty
        ? _stringValue(response['message'])
        : (isSuccess
              ? 'Profile updated successfully.'
              : 'Unable to update profile.');

    await _showStatusModal(
      title: isSuccess ? 'Profile Updated' : 'Profile Update Failed',
      message: message,
      isSuccess: isSuccess,
      profileId: responseProfileId.isNotEmpty ? responseProfileId : profileId,
    );

    await _loadProfileForUpdate(showErrorModal: false);
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _requiredValidator(value, 'Email ID');
    if (requiredError != null) return requiredError;

    final email = value!.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _mobileValidator(String? value) {
    final requiredError = _requiredValidator(value, 'Mobile number');
    if (requiredError != null) return requiredError;

    final digitsOnly = value!.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Mobile number must be 10 digits';
    }

    return null;
  }

  Future<void> _submitCreateProfile() async {
    final form = _createProfileFormKey.currentState;
    if (form == null || !form.validate()) return;

    final header = _buildHeaderRequest();
    if (header.values.every((value) => _stringValue(value).isEmpty)) {
      _showStatusModal(
        title: 'Profile Creation Failed',
        message: 'Unable to find login header details for this request.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _creatingProfile = true;
    });

    final requestBody = {
      'header': header,
      'profileName': {
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
      },
      'profileFlatNo': _profileFlatNoController.text.trim(),
      'profileDob': _formatDateForRequest(_profileDobController.text) ?? '',
      'contact': {
        'mobileNumber': _mobileNumberController.text.trim(),
        'emailId': _emailIdController.text.trim(),
        'landlinenumber': _landlineNumberController.text.trim(),
      },
      'profileOthrAdrss': _createHasOtherAddress
          ? _buildAddressRequest(
              line1Controller: _addressLine1Controller,
              line2Controller: _addressLine2Controller,
              line3Controller: _addressLine3Controller,
              line4Controller: _addressLine4Controller,
              landmarkController: _landmarkController,
              cityController: _cityController,
              stateController: _stateController,
              postOfficeController: _postOfficeController,
              policeStationController: _policeStationController,
              pinController: _pinController,
              addressType: _addressType,
            )
          : null,
      'profilePrimaryPostalAdrss': _buildAddressRequest(
        line1Controller: _primaryAddressLine1Controller,
        line2Controller: _primaryAddressLine2Controller,
        line3Controller: _primaryAddressLine3Controller,
        line4Controller: _primaryAddressLine4Controller,
        landmarkController: _primaryLandmarkController,
        cityController: _primaryCityController,
        stateController: _primaryStateController,
        postOfficeController: _primaryPostOfficeController,
        policeStationController: _primaryPoliceStationController,
        pinController: _primaryPinController,
        addressType: _primaryAddressType,
      ),
      'profileType': _profileType,
      'profilePosition': _profileType == 'STAFF' ? _profilePosition : null,
      'gender': _gender,
      'profileKind': _profileKind,
    };

    final response = await ApiService.createProfile(requestBody);
    if (!mounted) return;

    setState(() {
      _creatingProfile = false;
    });

    if (response == null) {
      _showStatusModal(
        title: 'Profile Creation Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final messageCode = (response['messageCode'] ?? '').toString();
    final message = (response['message'] ?? 'Unable to create profile')
        .toString();
    final isSuccess = messageCode.startsWith('SUCC');

    await _showStatusModal(
      title: isSuccess ? 'Profile Created' : 'Profile Creation Failed',
      message: message,
      isSuccess: isSuccess,
      profileId: response['profileId']?.toString(),
    );

    if (isSuccess) {
      _resetCreateProfileForm();
      _closeSection();
    }
  }

  void _resetCreateProfileForm() {
    _createProfileFormKey.currentState?.reset();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _profileFlatNoController.clear();
    _profileDobController.clear();
    _mobileNumberController.clear();
    _emailIdController.clear();
    _landlineNumberController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _addressLine3Controller.clear();
    _addressLine4Controller.clear();
    _landmarkController.clear();
    _cityController.clear();
    _stateController.clear();
    _postOfficeController.clear();
    _policeStationController.clear();
    _pinController.clear();
    _primaryAddressLine1Controller.clear();
    _primaryAddressLine2Controller.clear();
    _primaryAddressLine3Controller.clear();
    _primaryAddressLine4Controller.clear();
    _primaryLandmarkController.clear();
    _primaryCityController.clear();
    _primaryStateController.clear();
    _primaryPostOfficeController.clear();
    _primaryPoliceStationController.clear();
    _primaryPinController.clear();
    setState(() {
      _profileType = null;
      _profilePosition = null;
      _profileKind = null;
      _gender = null;
      _createHasOtherAddress = false;
      _addressType = 'RESIDENTIAL';
      _primaryAddressType = 'RESIDENTIAL';
    });
    _ProfileManagementDraft.createProfile.clear();
    _ProfileManagementDraft.createProfileType = null;
    _ProfileManagementDraft.createProfilePosition = null;
    _ProfileManagementDraft.createProfileKind = null;
    _ProfileManagementDraft.createGender = null;
    _ProfileManagementDraft.createHasOtherAddress = false;
    _ProfileManagementDraft.createAddressType = 'RESIDENTIAL';
    _ProfileManagementDraft.createPrimaryAddressType = 'RESIDENTIAL';
  }

  String _sectionTitle() {
    switch (_selectedSection) {
      case _ProfileManagementSection.createProfile:
        return 'Create Profile';
      case _ProfileManagementSection.viewProfile:
        return 'View Profile';
      case _ProfileManagementSection.updateProfile:
        return 'Update Profile';
      case _ProfileManagementSection.updatePassword:
        return 'Update Password';
      case null:
        return 'Account Management';
    }
  }

  String _sectionSubtitle() {
    switch (_selectedSection) {
      case _ProfileManagementSection.createProfile:
        return 'Fill in the required details and submit a new resident profile.';
      case _ProfileManagementSection.viewProfile:
        return 'Review the profile fetched from the logged-in header, including profile picture, access details, contact information, and address.';
      case _ProfileManagementSection.updateProfile:
        return 'Fetch the existing profile, edit allowed fields, update the profile picture, and submit changes.';
      case _ProfileManagementSection.updatePassword:
        return 'Update account credentials from the password management form.';
      case null:
        return 'Choose one of the account management actions below.';
    }
  }

  void _showAccountActionMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title is ready for the next step.')),
    );
  }

  Widget _buildSelectedSectionContent(bool mobile) {
    switch (_selectedSection!) {
      case _ProfileManagementSection.createProfile:
        return _CreateProfileTab(
          formKey: _createProfileFormKey,
          firstNameController: _firstNameController,
          middleNameController: _middleNameController,
          lastNameController: _lastNameController,
          profileFlatNoController: _profileFlatNoController,
          profileDobController: _profileDobController,
          mobileNumberController: _mobileNumberController,
          emailIdController: _emailIdController,
          landlineNumberController: _landlineNumberController,
          addressLine1Controller: _addressLine1Controller,
          addressLine2Controller: _addressLine2Controller,
          addressLine3Controller: _addressLine3Controller,
          addressLine4Controller: _addressLine4Controller,
          landmarkController: _landmarkController,
          cityController: _cityController,
          stateController: _stateController,
          postOfficeController: _postOfficeController,
          policeStationController: _policeStationController,
          pinController: _pinController,
          primaryAddressLine1Controller: _primaryAddressLine1Controller,
          primaryAddressLine2Controller: _primaryAddressLine2Controller,
          primaryAddressLine3Controller: _primaryAddressLine3Controller,
          primaryAddressLine4Controller: _primaryAddressLine4Controller,
          primaryLandmarkController: _primaryLandmarkController,
          primaryCityController: _primaryCityController,
          primaryStateController: _primaryStateController,
          primaryPostOfficeController: _primaryPostOfficeController,
          primaryPoliceStationController: _primaryPoliceStationController,
          primaryPinController: _primaryPinController,
          profileType: _profileType,
          profilePosition: _profilePosition,
          profileKind: _profileKind,
          gender: _gender,
          hasOtherAddress: _createHasOtherAddress,
          addressType: _addressType,
          primaryAddressType: _primaryAddressType,
          onProfileTypeChanged: (value) {
            setState(() {
              _profileType = value;
              if (value != 'STAFF') {
                _profilePosition = null;
                _ProfileManagementDraft.createProfilePosition = null;
              }
              _ProfileManagementDraft.createProfileType = value;
            });
          },
          onProfilePositionChanged: (value) {
            setState(() {
              _profilePosition = value;
              _ProfileManagementDraft.createProfilePosition = value;
            });
          },
          onProfileKindChanged: (value) {
            setState(() {
              _profileKind = value;
              _ProfileManagementDraft.createProfileKind = value;
            });
          },
          onGenderChanged: (value) {
            setState(() {
              _gender = value;
              _ProfileManagementDraft.createGender = value;
            });
          },
          onHasOtherAddressChanged: (value) {
            setState(() {
              _createHasOtherAddress = value;
              _ProfileManagementDraft.createHasOtherAddress = value;
              if (!value) {
                _addressLine1Controller.clear();
                _addressLine2Controller.clear();
                _addressLine3Controller.clear();
                _addressLine4Controller.clear();
                _landmarkController.clear();
                _cityController.clear();
                _stateController.clear();
                _postOfficeController.clear();
                _policeStationController.clear();
                _pinController.clear();
                _addressType = 'RESIDENTIAL';
                _ProfileManagementDraft.createAddressType = 'RESIDENTIAL';
              }
            });
          },
          onAddressTypeChanged: (value) {
            setState(() {
              _addressType = value ?? 'RESIDENTIAL';
              _ProfileManagementDraft.createAddressType = _addressType;
            });
          },
          onPrimaryAddressTypeChanged: (value) {
            setState(() {
              _primaryAddressType = value ?? 'RESIDENTIAL';
              _ProfileManagementDraft.createPrimaryAddressType =
                  _primaryAddressType;
            });
          },
          requiredValidator: _requiredValidator,
          mobileValidator: _mobileValidator,
          emailValidator: _emailValidator,
          submitting: _creatingProfile,
          onSubmit: _submitCreateProfile,
          mobile: mobile,
        );
      case _ProfileManagementSection.viewProfile:
        return _ViewProfileTab(
          profile: _loadedProfile,
          loading: _loadingProfile,
          profileImageBytes: _effectiveProfileImageBytes,
          onRefresh: _loadProfileForUpdate,
          mobile: mobile,
        );
      case _ProfileManagementSection.updateProfile:
        return _UpdateProfileTab(
          formKey: _updateProfileFormKey,
          firstNameController: _updateFirstNameController,
          middleNameController: _updateMiddleNameController,
          lastNameController: _updateLastNameController,
          profileIdController: _updateProfileIdController,
          apartmentNameController: _updateApartmentNameController,
          profileDobController: _updateProfileDobController,
          profileFlatNoController: _updateProfileFlatNoController,
          mobileNumberController: _updateMobileNumberController,
          emailIdController: _updateEmailIdController,
          landlineNumberController: _updateLandlineNumberController,
          addressLine1Controller: _updateAddressLine1Controller,
          addressLine2Controller: _updateAddressLine2Controller,
          addressLine3Controller: _updateAddressLine3Controller,
          addressLine4Controller: _updateAddressLine4Controller,
          landmarkController: _updateLandmarkController,
          cityController: _updateCityController,
          stateController: _updateStateController,
          postOfficeController: _updatePostOfficeController,
          policeStationController: _updatePoliceStationController,
          pinController: _updatePinController,
          primaryAddressLine1Controller: _updatePrimaryAddressLine1Controller,
          primaryAddressLine2Controller: _updatePrimaryAddressLine2Controller,
          primaryAddressLine3Controller: _updatePrimaryAddressLine3Controller,
          primaryAddressLine4Controller: _updatePrimaryAddressLine4Controller,
          primaryLandmarkController: _updatePrimaryLandmarkController,
          primaryCityController: _updatePrimaryCityController,
          primaryStateController: _updatePrimaryStateController,
          primaryPostOfficeController: _updatePrimaryPostOfficeController,
          primaryPoliceStationController: _updatePrimaryPoliceStationController,
          primaryPinController: _updatePrimaryPinController,
          gender: _updateGender,
          addressType: _updateAddressType,
          primaryAddressType: _updatePrimaryAddressType,
          profileType: _updateProfileType,
          profilePosition: _updateProfilePosition,
          profileStatus: _updateProfileStatus,
          role: _updateRole,
          loading: _loadingProfile,
          submitting: _updatingProfile,
          hasLoadedProfile: _loadedProfile != null,
          deleteOtherAddress: _updateDeleteOtherAddress,
          hasOtherAddress:
              _hasAddressMap(_mapValue(_loadedProfile?['prflOthrAdrss'])) ||
              _hasAddressValues(
                line1Controller: _updateAddressLine1Controller,
                line2Controller: _updateAddressLine2Controller,
                line3Controller: _updateAddressLine3Controller,
                line4Controller: _updateAddressLine4Controller,
                landmarkController: _updateLandmarkController,
                cityController: _updateCityController,
                stateController: _updateStateController,
                postOfficeController: _updatePostOfficeController,
                policeStationController: _updatePoliceStationController,
                pinController: _updatePinController,
              ),
          profileImageBytes: _effectiveProfileImageBytes,
          onAddressTypeChanged: (value) {
            setState(() {
              _updateAddressType = value ?? 'RESIDENTIAL';
            });
          },
          onDeleteOtherAddressChanged: (value) {
            setState(() {
              _updateDeleteOtherAddress = value;
            });
          },
          onPrimaryAddressTypeChanged: (value) {
            setState(() {
              _updatePrimaryAddressType = value ?? 'RESIDENTIAL';
            });
          },
          requiredValidator: _requiredValidator,
          mobileValidator: _mobileValidator,
          emailValidator: _emailValidator,
          onRefresh: _loadProfileForUpdate,
          onPickImage: _pickProfileImage,
          onSubmit: _submitUpdateProfile,
          mobile: mobile,
        );
      case _ProfileManagementSection.updatePassword:
        return _UpdatePasswordTab(mobile: mobile);
    }
  }

  Widget _buildProfileManagementContent(bool mobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedSection == null)
                Container(
                  padding: EdgeInsets.all(mobile ? 18 : 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _brandColor, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(18, 75, 69, 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F8F82), Color(0xFF15766A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 16,
                          spacing: 16,
                          children: [
                            SizedBox(
                              width: mobile ? double.infinity : 520,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _sectionTitle(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _sectionSubtitle(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Desk',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '9 Active Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: mobile ? 1 : 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: mobile ? 170 : 240,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final items = [
                            _ProfileActionCard(
                              title: 'Create Profile',
                              icon: Icons.person_add_alt_1,
                              selected: false,
                              onTap: () => _openSection(
                                _ProfileManagementSection.createProfile,
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'Update Profile',
                              icon: Icons.manage_accounts,
                              selected: false,
                              onTap: () => _openSection(
                                _ProfileManagementSection.updateProfile,
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'Update Password',
                              icon: Icons.password,
                              selected: false,
                              onTap: () => _openSection(
                                _ProfileManagementSection.updatePassword,
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'View Profile Details',
                              icon: Icons.badge_outlined,
                              selected: false,
                              onTap: () => _openSection(
                                _ProfileManagementSection.viewProfile,
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'Tenant Management',
                              icon: Icons.apartment_outlined,
                              selected: false,
                              onTap: () => _showAccountActionMessage(
                                'Tenant Management',
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'Owner Management',
                              icon: Icons.home_work_outlined,
                              selected: false,
                              onTap: () =>
                                  _showAccountActionMessage('Owner Management'),
                            ),
                            _ProfileActionCard(
                              title: 'Staff Management',
                              icon: Icons.groups_outlined,
                              selected: false,
                              onTap: () =>
                                  _showAccountActionMessage('Staff Management'),
                            ),
                            _ProfileActionCard(
                              title: 'Role And Access',
                              icon: Icons.lock_person_outlined,
                              selected: false,
                              onTap: () => openAppShellSection(
                                context,
                                AppSection.roleAndAccess,
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'Flat Management',
                              icon: Icons.door_front_door_outlined,
                              selected: false,
                              onTap: () =>
                                  _showAccountActionMessage('Flat Management'),
                            ),
                          ];

                          return items[index];
                        },
                      ),
                    ],
                  ),
                ),
              if (_selectedSection != null)
                _ProfileSectionCard(
                  title: _sectionTitle(),
                  subtitle: _sectionSubtitle(),
                  onBack: _closeSection,
                  child: _buildSelectedSectionContent(mobile),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    if (widget.embedded) {
      return _buildProfileManagementContent(mobile);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('Account Management'),
      ),
      drawer: mobile
          ? Drawer(
              child: SideBar(
                selectedSection: AppSection.profileManagement,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            )
          : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!mobile)
              SideBar(
                selectedSection: AppSection.profileManagement,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            Expanded(child: _buildProfileManagementContent(mobile)),
          ],
        ),
      ),
    );
  }
}

enum _ProfileManagementSection {
  createProfile,
  viewProfile,
  updateProfile,
  updatePassword,
}

class _ProfileImageEditorDialog extends StatefulWidget {
  const _ProfileImageEditorDialog({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_ProfileImageEditorDialog> createState() =>
      _ProfileImageEditorDialogState();
}

class _ProfileImageEditorDialogState extends State<_ProfileImageEditorDialog> {
  static const double _viewportSize = 240;
  static const double _outputSize = 512;

  img.Image? _decodedImage;
  double _baseWidth = _viewportSize;
  double _baseHeight = _viewportSize;
  double _baseScale = 1;
  double _zoom = 1;
  Offset _offset = Offset.zero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _decodedImage = img.decodeImage(widget.imageBytes);

    final image = _decodedImage;
    if (image != null) {
      _baseScale = _viewportSize / image.width;
      if (image.height * _baseScale < _viewportSize) {
        _baseScale = _viewportSize / image.height;
      }
      _baseWidth = image.width * _baseScale;
      _baseHeight = image.height * _baseScale;
    }
  }

  double get _scaledWidth => _baseWidth * _zoom;
  double get _scaledHeight => _baseHeight * _zoom;

  Offset _clampedOffset(Offset candidate) {
    final maxHorizontalShift = ((_scaledWidth - _viewportSize) / 2).clamp(
      0.0,
      double.infinity,
    );
    final maxVerticalShift = ((_scaledHeight - _viewportSize) / 2).clamp(
      0.0,
      double.infinity,
    );

    return Offset(
      candidate.dx.clamp(-maxHorizontalShift, maxHorizontalShift),
      candidate.dy.clamp(-maxVerticalShift, maxVerticalShift),
    );
  }

  Uint8List? _buildCroppedImage() {
    final image = _decodedImage;
    if (image == null) {
      return null;
    }

    final totalScale = _baseScale * _zoom;
    final imageLeft = (_viewportSize - _scaledWidth) / 2 + _offset.dx;
    final imageTop = (_viewportSize - _scaledHeight) / 2 + _offset.dy;
    final cropLeft = (-imageLeft / totalScale).clamp(
      0.0,
      image.width.toDouble(),
    );
    final cropTop = (-imageTop / totalScale).clamp(
      0.0,
      image.height.toDouble(),
    );
    final cropSize = (_viewportSize / totalScale).clamp(
      1.0,
      image.width < image.height
          ? image.width.toDouble()
          : image.height.toDouble(),
    );
    final maxCropLeft = (image.width - cropSize).clamp(
      0.0,
      image.width.toDouble(),
    );
    final maxCropTop = (image.height - cropSize).clamp(
      0.0,
      image.height.toDouble(),
    );

    final cropped = img.copyCrop(
      image,
      x: cropLeft.clamp(0.0, maxCropLeft).round(),
      y: cropTop.clamp(0.0, maxCropTop).round(),
      width: cropSize.round(),
      height: cropSize.round(),
    );
    final resized = img.copyResize(
      cropped,
      width: _outputSize.round(),
      height: _outputSize.round(),
    );

    return Uint8List.fromList(img.encodePng(resized));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    final croppedImage = _buildCroppedImage();
    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (croppedImage == null || croppedImage.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(croppedImage);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _decodedImage != null;
    final imageLeft = (_viewportSize - _scaledWidth) / 2 + _offset.dx;
    final imageTop = (_viewportSize - _scaledHeight) / 2 + _offset.dy;

    return AlertDialog(
      backgroundColor: Color(0xFFF7F4FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Adjust Profile Picture'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Drag the image to choose the visible area and use the slider to zoom in or out.',
              style: TextStyle(color: Colors.black54),
            ),
            SizedBox(height: 18),
            Center(
              child: Container(
                width: _viewportSize + 12,
                height: _viewportSize + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF0F8F82), width: 3),
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: SizedBox(
                    width: _viewportSize,
                    height: _viewportSize,
                    child: GestureDetector(
                      onPanUpdate: canEdit
                          ? (details) {
                              setState(() {
                                _offset = _clampedOffset(
                                  _offset + details.delta,
                                );
                              });
                            }
                          : null,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ColoredBox(color: Color(0xFFE7EFED)),
                          ),
                          if (canEdit)
                            Positioned(
                              left: imageLeft,
                              top: imageTop,
                              child: Image.memory(
                                widget.imageBytes,
                                width: _scaledWidth,
                                height: _scaledHeight,
                                fit: BoxFit.fill,
                              ),
                            )
                          else
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'This image format is not supported.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Zoom',
              style: TextStyle(
                color: Color(0xFF124B45),
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _zoom,
              min: 1,
              max: 4,
              divisions: 30,
              activeColor: Color(0xFF0F8F82),
              onChanged: canEdit
                  ? (value) {
                      setState(() {
                        _zoom = value;
                        _offset = _clampedOffset(_offset);
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: canEdit && !_saving ? _save : null,
          style: FilledButton.styleFrom(backgroundColor: Color(0xFF0F8F82)),
          child: _saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Use Image'),
        ),
      ],
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({
    required this.name,
    this.imageBytes,
    this.onEdit,
    this.busy = false,
  });

  final String name;
  final Uint8List? imageBytes;
  final VoidCallback? onEdit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Center(
      child: SizedBox(
        width: 156,
        height: 156,
        child: Stack(
          children: [
            Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF0F8F82), width: 3),
                gradient: imageBytes == null
                    ? LinearGradient(
                        colors: [Color(0xFFEAF7F4), Color(0xFFD6EFEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: imageBytes == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(imageBytes!),
                        fit: BoxFit.cover,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0F8F82).withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: imageBytes == null
                  ? Center(
                      child: Text(
                        initials.isEmpty ? 'RP' : initials,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F8F82),
                        ),
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 8,
              child: FilledButton.icon(
                onPressed: busy ? null : onEdit,
                icon: busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.edit, size: 18),
                label: Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF0F8F82),
                  disabledBackgroundColor: Color(0xFF7EAAA4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFFCFEFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFFD7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back),
                label: Text('Back'),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF124B45),
            ),
          ),
          SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.black54)),
          SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatefulWidget {
  const _ProfileActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.selected,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_ProfileActionCard> createState() => _ProfileActionCardState();
}

class _ProfileActionCardState extends State<_ProfileActionCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = hovered || widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF8F4C6) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.selected
                  ? _ProfileManagementPageState._brandColor
                  : active
                  ? const Color(0xFFE0DA84)
                  : const Color(0xFFE6EFED),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(17, 59, 52, 0.07),
                blurRadius: active ? 24 : 16,
                offset: Offset(0, active ? 12 : 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FBF9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: _ProfileManagementPageState._brandColor,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: _ProfileManagementPageState._brandTextColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Text(
                          'Open',
                          style: TextStyle(
                            color: _ProfileManagementPageState._brandColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: _ProfileManagementPageState._brandColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateProfileTab extends StatelessWidget {
  const _CreateProfileTab({
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.profileFlatNoController,
    required this.profileDobController,
    required this.mobileNumberController,
    required this.emailIdController,
    required this.landlineNumberController,
    required this.addressLine1Controller,
    required this.addressLine2Controller,
    required this.addressLine3Controller,
    required this.addressLine4Controller,
    required this.landmarkController,
    required this.cityController,
    required this.stateController,
    required this.postOfficeController,
    required this.policeStationController,
    required this.pinController,
    required this.primaryAddressLine1Controller,
    required this.primaryAddressLine2Controller,
    required this.primaryAddressLine3Controller,
    required this.primaryAddressLine4Controller,
    required this.primaryLandmarkController,
    required this.primaryCityController,
    required this.primaryStateController,
    required this.primaryPostOfficeController,
    required this.primaryPoliceStationController,
    required this.primaryPinController,
    required this.profileType,
    required this.profilePosition,
    required this.profileKind,
    required this.gender,
    required this.hasOtherAddress,
    required this.addressType,
    required this.primaryAddressType,
    required this.onProfileTypeChanged,
    required this.onProfilePositionChanged,
    required this.onProfileKindChanged,
    required this.onGenderChanged,
    required this.onHasOtherAddressChanged,
    required this.onAddressTypeChanged,
    required this.onPrimaryAddressTypeChanged,
    required this.requiredValidator,
    required this.mobileValidator,
    required this.emailValidator,
    required this.submitting,
    required this.onSubmit,
    required this.mobile,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController profileFlatNoController;
  final TextEditingController profileDobController;
  final TextEditingController mobileNumberController;
  final TextEditingController emailIdController;
  final TextEditingController landlineNumberController;
  final TextEditingController addressLine1Controller;
  final TextEditingController addressLine2Controller;
  final TextEditingController addressLine3Controller;
  final TextEditingController addressLine4Controller;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postOfficeController;
  final TextEditingController policeStationController;
  final TextEditingController pinController;
  final TextEditingController primaryAddressLine1Controller;
  final TextEditingController primaryAddressLine2Controller;
  final TextEditingController primaryAddressLine3Controller;
  final TextEditingController primaryAddressLine4Controller;
  final TextEditingController primaryLandmarkController;
  final TextEditingController primaryCityController;
  final TextEditingController primaryStateController;
  final TextEditingController primaryPostOfficeController;
  final TextEditingController primaryPoliceStationController;
  final TextEditingController primaryPinController;
  final String? profileType;
  final String? profilePosition;
  final String? profileKind;
  final String? gender;
  final bool hasOtherAddress;
  final String addressType;
  final String primaryAddressType;
  final ValueChanged<String?> onProfileTypeChanged;
  final ValueChanged<String?> onProfilePositionChanged;
  final ValueChanged<String?> onProfileKindChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<bool> onHasOtherAddressChanged;
  final ValueChanged<String?> onAddressTypeChanged;
  final ValueChanged<String?> onPrimaryAddressTypeChanged;
  final String? Function(String?, String) requiredValidator;
  final String? Function(String?) mobileValidator;
  final String? Function(String?) emailValidator;
  final bool submitting;
  final VoidCallback onSubmit;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFF3FBF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFFD6ECE7)),
            ),
            child: Text(
              'Mandatory fields: First Name, Last Name, Profile DOB, Mobile Number, Email ID, Profile Type, Gender, Profile Kind, and the starred primary address fields. Profile Position is mandatory only for STAFF.',
              style: TextStyle(
                color: Color(0xFF124B45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Profile Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'First Name *',
                controller: firstNameController,
                validator: (value) => requiredValidator(value, 'First Name'),
              ),
              _ProfileInputField(
                label: 'Middle Name',
                controller: middleNameController,
              ),
              _ProfileInputField(
                label: 'Last Name *',
                controller: lastNameController,
                validator: (value) => requiredValidator(value, 'Last Name'),
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Basic Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Flat No.',
                controller: profileFlatNoController,
              ),
              _ProfileInputField(
                label: 'Profile DOB *',
                controller: profileDobController,
                hintText: 'YYYY-MM-DD',
                validator: (value) => requiredValidator(value, 'Profile DOB'),
              ),
              _ProfileDropdownField(
                label: 'Profile Type *',
                value: profileType,
                items: _ProfileManagementPageState._createProfileTypeOptions,
                onChanged: onProfileTypeChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Profile Type is required'
                    : null,
              ),
              _ProfileDropdownField(
                label: profileType == 'STAFF'
                    ? 'Profile Position *'
                    : 'Profile Position',
                value: profilePosition,
                items: _ProfileManagementPageState._createStaffPositionOptions,
                enabled: profileType == 'STAFF',
                onChanged: profileType == 'STAFF'
                    ? onProfilePositionChanged
                    : null,
                validator: (value) =>
                    profileType == 'STAFF' && (value == null || value.isEmpty)
                    ? 'Profile Position is required for STAFF'
                    : null,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: 'Profile Kind *',
                value: profileKind,
                items: _ProfileManagementPageState._profileKindOptions,
                onChanged: onProfileKindChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Profile Kind is required'
                    : null,
              ),
              _ProfileDropdownField(
                label: 'Gender *',
                value: gender,
                items: const ['MALE', 'FEMALE', 'OTHER'],
                onChanged: onGenderChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Gender is required'
                    : null,
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Contact',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Mobile Number *',
                controller: mobileNumberController,
                keyboardType: TextInputType.phone,
                validator: mobileValidator,
              ),
              _ProfileInputField(
                label: 'Email ID *',
                controller: emailIdController,
                keyboardType: TextInputType.emailAddress,
                validator: emailValidator,
              ),
              _ProfileInputField(
                label: 'Landline Number',
                controller: landlineNumberController,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Primary Postal Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 1 *',
                controller: primaryAddressLine1Controller,
                validator: (value) =>
                    requiredValidator(value, 'Address Line 1'),
              ),
              _ProfileInputField(
                label: 'Address Line 2 *',
                controller: primaryAddressLine2Controller,
                validator: (value) =>
                    requiredValidator(value, 'Address Line 2'),
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 3',
                controller: primaryAddressLine3Controller,
              ),
              _ProfileInputField(
                label: 'Address Line 4',
                controller: primaryAddressLine4Controller,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: 'Address Type *',
                value: primaryAddressType,
                items: const ['RESIDENTIAL', 'OFFICE', 'OTHER'],
                onChanged: onPrimaryAddressTypeChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Address Type is required'
                    : null,
              ),
              _ProfileInputField(
                label: 'Landmark',
                controller: primaryLandmarkController,
              ),
              _ProfileInputField(
                label: 'City',
                controller: primaryCityController,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'State *',
                controller: primaryStateController,
                validator: (value) => requiredValidator(value, 'State'),
              ),
              _ProfileInputField(
                label: 'Post Office',
                controller: primaryPostOfficeController,
              ),
              _ProfileInputField(
                label: 'Police Station',
                controller: primaryPoliceStationController,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Pin *',
                controller: primaryPinController,
                keyboardType: TextInputType.number,
                validator: (value) => requiredValidator(value, 'Pin'),
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Other Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: hasOtherAddress,
            onChanged: (value) => onHasOtherAddressChanged(value ?? false),
            title: const Text('Have Any Other Address'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          SizedBox(height: 8),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: hasOtherAddress ? 'Address Line 1 *' : 'Address Line 1',
                controller: addressLine1Controller,
                readOnly: !hasOtherAddress,
                validator: (value) => hasOtherAddress
                    ? requiredValidator(value, 'Address Line 1')
                    : null,
              ),
              _ProfileInputField(
                label: hasOtherAddress ? 'Address Line 2 *' : 'Address Line 2',
                controller: addressLine2Controller,
                readOnly: !hasOtherAddress,
                validator: (value) => hasOtherAddress
                    ? requiredValidator(value, 'Address Line 2')
                    : null,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 3',
                controller: addressLine3Controller,
                readOnly: !hasOtherAddress,
              ),
              _ProfileInputField(
                label: 'Address Line 4',
                controller: addressLine4Controller,
                readOnly: !hasOtherAddress,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: hasOtherAddress ? 'Address Type *' : 'Address Type',
                value: addressType,
                items: const ['RESIDENTIAL', 'OFFICE', 'OTHER'],
                enabled: hasOtherAddress,
                onChanged: hasOtherAddress ? onAddressTypeChanged : null,
                validator: (value) =>
                    hasOtherAddress && (value == null || value.isEmpty)
                    ? 'Address Type is required'
                    : null,
              ),
              _ProfileInputField(
                label: 'Landmark',
                controller: landmarkController,
                readOnly: !hasOtherAddress,
              ),
              _ProfileInputField(
                label: 'City',
                controller: cityController,
                readOnly: !hasOtherAddress,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: hasOtherAddress ? 'State *' : 'State',
                controller: stateController,
                readOnly: !hasOtherAddress,
                validator: (value) =>
                    hasOtherAddress ? requiredValidator(value, 'State') : null,
              ),
              _ProfileInputField(
                label: 'Post Office',
                controller: postOfficeController,
                readOnly: !hasOtherAddress,
              ),
              _ProfileInputField(
                label: 'Police Station',
                controller: policeStationController,
                readOnly: !hasOtherAddress,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: hasOtherAddress ? 'Pin *' : 'Pin',
                controller: pinController,
                keyboardType: TextInputType.number,
                readOnly: !hasOtherAddress,
                validator: (value) =>
                    hasOtherAddress ? requiredValidator(value, 'Pin') : null,
              ),
            ],
          ),
          SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.person_add_alt_1),
              label: Text(submitting ? 'Creating...' : 'Create Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: Color(0xFF0F8F82),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateProfileTab extends StatelessWidget {
  const _UpdateProfileTab({
    required this.formKey,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.profileIdController,
    required this.apartmentNameController,
    required this.profileDobController,
    required this.profileFlatNoController,
    required this.mobileNumberController,
    required this.emailIdController,
    required this.landlineNumberController,
    required this.addressLine1Controller,
    required this.addressLine2Controller,
    required this.addressLine3Controller,
    required this.addressLine4Controller,
    required this.landmarkController,
    required this.cityController,
    required this.stateController,
    required this.postOfficeController,
    required this.policeStationController,
    required this.pinController,
    required this.primaryAddressLine1Controller,
    required this.primaryAddressLine2Controller,
    required this.primaryAddressLine3Controller,
    required this.primaryAddressLine4Controller,
    required this.primaryLandmarkController,
    required this.primaryCityController,
    required this.primaryStateController,
    required this.primaryPostOfficeController,
    required this.primaryPoliceStationController,
    required this.primaryPinController,
    required this.gender,
    required this.addressType,
    required this.primaryAddressType,
    required this.profileType,
    required this.profilePosition,
    required this.profileStatus,
    required this.role,
    required this.loading,
    required this.submitting,
    required this.hasLoadedProfile,
    required this.deleteOtherAddress,
    required this.hasOtherAddress,
    required this.profileImageBytes,
    required this.onAddressTypeChanged,
    required this.onDeleteOtherAddressChanged,
    required this.onPrimaryAddressTypeChanged,
    required this.requiredValidator,
    required this.mobileValidator,
    required this.emailValidator,
    required this.onRefresh,
    required this.onPickImage,
    required this.onSubmit,
    required this.mobile,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController profileIdController;
  final TextEditingController apartmentNameController;
  final TextEditingController profileDobController;
  final TextEditingController profileFlatNoController;
  final TextEditingController mobileNumberController;
  final TextEditingController emailIdController;
  final TextEditingController landlineNumberController;
  final TextEditingController addressLine1Controller;
  final TextEditingController addressLine2Controller;
  final TextEditingController addressLine3Controller;
  final TextEditingController addressLine4Controller;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postOfficeController;
  final TextEditingController policeStationController;
  final TextEditingController pinController;
  final TextEditingController primaryAddressLine1Controller;
  final TextEditingController primaryAddressLine2Controller;
  final TextEditingController primaryAddressLine3Controller;
  final TextEditingController primaryAddressLine4Controller;
  final TextEditingController primaryLandmarkController;
  final TextEditingController primaryCityController;
  final TextEditingController primaryStateController;
  final TextEditingController primaryPostOfficeController;
  final TextEditingController primaryPoliceStationController;
  final TextEditingController primaryPinController;
  final String? gender;
  final String addressType;
  final String primaryAddressType;
  final String? profileType;
  final String? profilePosition;
  final String? profileStatus;
  final String? role;
  final bool loading;
  final bool submitting;
  final bool hasLoadedProfile;
  final bool deleteOtherAddress;
  final bool hasOtherAddress;
  final Uint8List? profileImageBytes;
  final ValueChanged<String?> onAddressTypeChanged;
  final ValueChanged<bool> onDeleteOtherAddressChanged;
  final ValueChanged<String?> onPrimaryAddressTypeChanged;
  final String? Function(String?, String) requiredValidator;
  final String? Function(String?) mobileValidator;
  final String? Function(String?) emailValidator;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onPickImage;
  final Future<void> Function() onSubmit;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final displayName = [
      firstNameController.text,
      middleNameController.text,
      lastNameController.text,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    if (!hasLoadedProfile && loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(color: Color(0xFF0F8F82)),
        ),
      );
    }

    if (!hasLoadedProfile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Color(0xFFF4FBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFD5EBE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No profile is loaded yet.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF124B45),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Click refresh to fetch the profile using the logged-in header and open the update form.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Fetch Profile'),
            ),
          ),
        ],
      );
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading) ...[
            LinearProgressIndicator(color: Color(0xFF0F8F82)),
            SizedBox(height: 18),
          ],
          _EditableProfileAvatar(
            name: displayName.isEmpty ? 'Resident Profile' : displayName,
            imageBytes: profileImageBytes,
            busy: submitting,
            onEdit: submitting ? null : onPickImage,
          ),
          SizedBox(height: 18),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF4FBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFD5EBE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, color: Color(0xFF0F8F82)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Apartment name, gender, DOB, flat number, position, status, and type are shown as read-only. Use the avatar edit button to upload a new profile picture.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF124B45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: loading || submitting ? null : onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Refresh Profile'),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Profile Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Apartment Name',
                controller: apartmentNameController,
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Profile ID',
                controller: profileIdController,
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Date of Birth',
                controller: profileDobController,
                readOnly: true,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Flat No.',
                controller: profileFlatNoController,
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Profile Type',
                initialValue: profileType,
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Profile Position',
                initialValue: profilePosition,
                readOnly: true,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Gender',
                initialValue: gender,
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Profile Status',
                initialValue: profileStatus,
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Role',
                initialValue: role,
                readOnly: true,
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Profile Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'First Name *',
                controller: firstNameController,
                validator: (value) => requiredValidator(value, 'First Name'),
              ),
              _ProfileInputField(
                label: 'Middle Name',
                controller: middleNameController,
              ),
              _ProfileInputField(
                label: 'Last Name *',
                controller: lastNameController,
                validator: (value) => requiredValidator(value, 'Last Name'),
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Contact',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Text(
            'Primary Postal Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 1 *',
                controller: primaryAddressLine1Controller,
                validator: (value) =>
                    requiredValidator(value, 'Address Line 1'),
              ),
              _ProfileInputField(
                label: 'Address Line 2 *',
                controller: primaryAddressLine2Controller,
                validator: (value) =>
                    requiredValidator(value, 'Address Line 2'),
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 3',
                controller: primaryAddressLine3Controller,
              ),
              _ProfileInputField(
                label: 'Address Line 4',
                controller: primaryAddressLine4Controller,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: 'Address Type *',
                value: primaryAddressType,
                items: const ['RESIDENTIAL', 'OFFICE', 'OTHER'],
                onChanged: onPrimaryAddressTypeChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Address Type is required'
                    : null,
              ),
              _ProfileInputField(
                label: 'Landmark',
                controller: primaryLandmarkController,
              ),
              _ProfileInputField(
                label: 'City',
                controller: primaryCityController,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'State *',
                controller: primaryStateController,
                validator: (value) => requiredValidator(value, 'State'),
              ),
              _ProfileInputField(
                label: 'Post Office',
                controller: primaryPostOfficeController,
              ),
              _ProfileInputField(
                label: 'Police Station',
                controller: primaryPoliceStationController,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Pin *',
                controller: primaryPinController,
                keyboardType: TextInputType.number,
                validator: (value) => requiredValidator(value, 'Pin'),
              ),
            ],
          ),
          SizedBox(height: 24),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Mobile Number *',
                controller: mobileNumberController,
                keyboardType: TextInputType.phone,
                validator: mobileValidator,
              ),
              _ProfileInputField(
                label: 'Email ID *',
                controller: emailIdController,
                keyboardType: TextInputType.emailAddress,
                validator: emailValidator,
              ),
              _ProfileInputField(
                label: 'Landline Number',
                controller: landlineNumberController,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            'Other Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: deleteOtherAddress,
            onChanged: hasOtherAddress
                ? (value) => onDeleteOtherAddressChanged(value ?? false)
                : null,
            title: const Text('Delete Other Address'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!hasOtherAddress) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No Other Address Available',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: hasOtherAddress && !deleteOtherAddress
                    ? 'Address Line 1 *'
                    : 'Address Line 1',
                controller: addressLine1Controller,
                readOnly: deleteOtherAddress,
                validator: (value) => hasOtherAddress && !deleteOtherAddress
                    ? requiredValidator(value, 'Address Line 1')
                    : null,
              ),
              _ProfileInputField(
                label: hasOtherAddress && !deleteOtherAddress
                    ? 'Address Line 2 *'
                    : 'Address Line 2',
                controller: addressLine2Controller,
                readOnly: deleteOtherAddress,
                validator: (value) => hasOtherAddress && !deleteOtherAddress
                    ? requiredValidator(value, 'Address Line 2')
                    : null,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 3',
                controller: addressLine3Controller,
                readOnly: deleteOtherAddress,
              ),
              _ProfileInputField(
                label: 'Address Line 4',
                controller: addressLine4Controller,
                readOnly: deleteOtherAddress,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: hasOtherAddress && !deleteOtherAddress
                    ? 'Address Type *'
                    : 'Address Type',
                value: addressType,
                items: const ['RESIDENTIAL', 'OFFICE', 'OTHER'],
                enabled: !deleteOtherAddress,
                onChanged: deleteOtherAddress ? null : onAddressTypeChanged,
                validator: (value) =>
                    hasOtherAddress &&
                        !deleteOtherAddress &&
                        (value == null || value.isEmpty)
                    ? 'Address Type is required'
                    : null,
              ),
              _ProfileInputField(
                label: 'Landmark',
                controller: landmarkController,
                readOnly: deleteOtherAddress,
              ),
              _ProfileInputField(
                label: 'City',
                controller: cityController,
                readOnly: deleteOtherAddress,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: hasOtherAddress && !deleteOtherAddress
                    ? 'State *'
                    : 'State',
                controller: stateController,
                readOnly: deleteOtherAddress,
                validator: (value) => hasOtherAddress && !deleteOtherAddress
                    ? requiredValidator(value, 'State')
                    : null,
              ),
              _ProfileInputField(
                label: 'Post Office',
                controller: postOfficeController,
                readOnly: deleteOtherAddress,
              ),
              _ProfileInputField(
                label: 'Police Station',
                controller: policeStationController,
                readOnly: deleteOtherAddress,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: hasOtherAddress && !deleteOtherAddress ? 'Pin *' : 'Pin',
                controller: pinController,
                keyboardType: TextInputType.number,
                readOnly: deleteOtherAddress,
                validator: (value) => hasOtherAddress && !deleteOtherAddress
                    ? requiredValidator(value, 'Pin')
                    : null,
              ),
            ],
          ),
          SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.save_outlined),
              label: Text(submitting ? 'Updating...' : 'Update Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: Color(0xFF0F8F82),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewProfileTab extends StatelessWidget {
  const _ViewProfileTab({
    required this.profile,
    required this.loading,
    required this.profileImageBytes,
    required this.onRefresh,
    required this.mobile,
  });

  final Map<String, dynamic>? profile;
  final bool loading;
  final Uint8List? profileImageBytes;
  final Future<void> Function() onRefresh;
  final bool mobile;

  String _textValue(dynamic value, {String fallback = 'Not available'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _formatDisplayDob(dynamic value) {
    final raw = _textValue(value);
    if (raw == '-') {
      return raw;
    }

    final sanitized = raw.trim();
    if (sanitized.isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(sanitized);
    if (parsed == null) {
      return sanitized;
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${parsed.day}-${months[parsed.month - 1]}-${parsed.year}';
  }

  bool _hasAddressData(Map<String, dynamic> address) {
    const keys = [
      'addressLine1',
      'addressLine2',
      'addressLine3',
      'addressLine4',
      'landmark',
      'city',
      'state',
      'postOffice',
      'policeStation',
      'pin',
      'addressType',
    ];

    return keys.any((key) => _textValue(address[key], fallback: '').isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null && loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(color: Color(0xFF0F8F82)),
        ),
      );
    }

    if (profile == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Color(0xFFF4FBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFD5EBE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No profile has been fetched yet.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF124B45),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use the logged-in header to load the resident profile and show the response on screen.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onRefresh,
              icon: Icon(Icons.refresh),
              label: Text('Fetch Profile'),
            ),
          ),
        ],
      );
    }

    final profileName = _mapValue(profile!['prflName']);
    final contactDetails = _mapValue(profile!['contactDetails']);
    final address = _mapValue(profile!['prflOthrAdrss']);
    final primaryAddress = _mapValue(
      profile!['primaryAddress'] ??
          profile!['profilePrimaryPostalAdrss'] ??
          profile!['prflPrimaryPostalAdrss'],
    );
    final effectivePrimaryAddress = primaryAddress.isNotEmpty
        ? primaryAddress
        : address;
    final flatValue = profile!['prflFlatNo'] is List
        ? (profile!['prflFlatNo'] as List)
              .where((value) => _textValue(value, fallback: '').isNotEmpty)
              .join(', ')
        : _textValue(profile!['prflFlatNo']);
    final fullName = [
      _textValue(profileName['firstName'], fallback: ''),
      _textValue(profileName['middleName'], fallback: ''),
      _textValue(profileName['lastName'], fallback: ''),
    ].where((part) => part.isNotEmpty).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading) ...[
          LinearProgressIndicator(color: Color(0xFF0F8F82)),
          SizedBox(height: 18),
        ],
        Container(
          padding: EdgeInsets.all(mobile ? 18 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F8F82), Color(0xFF1D6D64)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF124B45).withValues(alpha: 0.18),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileOverviewAvatar(
                      name: fullName.isEmpty ? 'Resident Profile' : fullName,
                      imageBytes: profileImageBytes,
                    ),
                    SizedBox(height: 18),
                    _ProfileOverviewText(fullName: fullName, profile: profile!),
                  ],
                )
              : Row(
                  children: [
                    _ProfileOverviewAvatar(
                      name: fullName.isEmpty ? 'Resident Profile' : fullName,
                      imageBytes: profileImageBytes,
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _ProfileOverviewText(
                        fullName: fullName,
                        profile: profile!,
                      ),
                    ),
                  ],
                ),
        ),
        SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Profile'),
          ),
        ),
        SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _ProfileInfoChip(
              icon: Icons.badge_outlined,
              label: 'Profile ID',
              value: _textValue(profile!['prflId']),
            ),
            _ProfileInfoChip(
              icon: Icons.home_work_outlined,
              label: 'Flat No',
              value: flatValue,
            ),
            _ProfileInfoChip(
              icon: Icons.person_outline,
              label: 'Type',
              value: _textValue(profile!['prflType']),
            ),
            _ProfileInfoChip(
              icon: Icons.work_outline,
              label: 'Position',
              value: _textValue(profile!['prflPosition']),
            ),
            _ProfileInfoChip(
              icon: Icons.verified_user_outlined,
              label: 'Status',
              value: _textValue(profile!['prflStus']),
            ),
            _ProfileInfoChip(
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: _textValue(profile!['gender']),
            ),
            _ProfileInfoChip(
              icon: Icons.cake_outlined,
              label: 'DOB',
              value: _formatDisplayDob(profile!['prflDob']),
            ),
            _ProfileInfoChip(
              icon: Icons.apartment_outlined,
              label: 'Apartment Name',
              value: _textValue(profile!['apartmentName']),
            ),
          ],
        ),
        SizedBox(height: 22),
        _ProfileViewSection(
          title: 'Contact Details',
          icon: Icons.call_outlined,
          child: _ProfileSummaryGrid(
            mobile: mobile,
            children: [
              _ProfileSummaryTile(
                label: 'Mobile Number',
                value: _textValue(contactDetails['mobileNumber']),
              ),
              _ProfileSummaryTile(
                label: 'Email ID',
                value: _textValue(contactDetails['emailId']),
              ),
              _ProfileSummaryTile(
                label: 'Landline Number',
                value: _textValue(contactDetails['landlinenumber']),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        _ProfileViewSection(
          title: 'Primary Postal Address',
          icon: Icons.markunread_mailbox_outlined,
          child: _ProfileSummaryGrid(
            mobile: mobile,
            children: [
              _ProfileSummaryTile(
                label: 'Address Line 1',
                value: _textValue(effectivePrimaryAddress['addressLine1']),
              ),
              _ProfileSummaryTile(
                label: 'Address Line 2',
                value: _textValue(effectivePrimaryAddress['addressLine2']),
              ),
              _ProfileSummaryTile(
                label: 'Address Line 3',
                value: _textValue(effectivePrimaryAddress['addressLine3']),
              ),
              _ProfileSummaryTile(
                label: 'Address Line 4',
                value: _textValue(effectivePrimaryAddress['addressLine4']),
              ),
              _ProfileSummaryTile(
                label: 'Address Type',
                value: _textValue(effectivePrimaryAddress['addressType']),
              ),
              _ProfileSummaryTile(
                label: 'Landmark',
                value: _textValue(effectivePrimaryAddress['landmark']),
              ),
              _ProfileSummaryTile(
                label: 'City',
                value: _textValue(effectivePrimaryAddress['city']),
              ),
              _ProfileSummaryTile(
                label: 'State',
                value: _textValue(effectivePrimaryAddress['state']),
              ),
              _ProfileSummaryTile(
                label: 'Post Office',
                value: _textValue(effectivePrimaryAddress['postOffice']),
              ),
              _ProfileSummaryTile(
                label: 'Police Station',
                value: _textValue(effectivePrimaryAddress['policeStation']),
              ),
              _ProfileSummaryTile(
                label: 'Pin',
                value: _textValue(effectivePrimaryAddress['pin']),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        _ProfileViewSection(
          title: 'Other Address',
          icon: Icons.location_on_outlined,
          child: _hasAddressData(address)
              ? _ProfileSummaryGrid(
                  mobile: mobile,
                  children: [
                    _ProfileSummaryTile(
                      label: 'Address Line 1',
                      value: _textValue(address['addressLine1']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Address Line 2',
                      value: _textValue(address['addressLine2']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Address Line 3',
                      value: _textValue(address['addressLine3']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Address Line 4',
                      value: _textValue(address['addressLine4']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Address Type',
                      value: _textValue(address['addressType']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Landmark',
                      value: _textValue(address['landmark']),
                    ),
                    _ProfileSummaryTile(
                      label: 'City',
                      value: _textValue(address['city']),
                    ),
                    _ProfileSummaryTile(
                      label: 'State',
                      value: _textValue(address['state']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Post Office',
                      value: _textValue(address['postOffice']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Police Station',
                      value: _textValue(address['policeStation']),
                    ),
                    _ProfileSummaryTile(
                      label: 'Pin',
                      value: _textValue(address['pin']),
                    ),
                  ],
                )
              : Text(
                  'No Other Address Available',
                  style: TextStyle(color: Colors.black54),
                ),
        ),
      ],
    );
  }
}

class _ProfileOverviewAvatar extends StatelessWidget {
  const _ProfileOverviewAvatar({required this.name, this.imageBytes});

  final String name;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 3,
        ),
        image: imageBytes == null
            ? null
            : DecorationImage(
                image: MemoryImage(imageBytes!),
                fit: BoxFit.cover,
              ),
      ),
      child: imageBytes == null
          ? Center(
              child: Text(
                initials.isEmpty ? 'RP' : initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
    );
  }
}

class _ProfileOverviewText extends StatelessWidget {
  const _ProfileOverviewText({required this.fullName, required this.profile});

  final String fullName;
  final Map<String, dynamic> profile;

  String _textValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Not available' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName.isEmpty ? 'Resident Profile' : fullName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '${_textValue(profile['prflType'])} • ${_textValue(profile['prflPosition'])} • ${_textValue(profile['prflStus'])}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoChip extends StatelessWidget {
  const _ProfileInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 160),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFD7ECE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFF0F8F82), size: 20),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileViewSection extends StatelessWidget {
  const _ProfileViewSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFFDDEDEA)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF124B45).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(0xFFF2FBF8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Color(0xFF0F8F82)),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF124B45),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProfileSummaryGrid extends StatelessWidget {
  const _ProfileSummaryGrid({required this.children, required this.mobile});

  final List<Widget> children;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: mobile ? 1 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 92,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ProfileSummaryTile extends StatelessWidget {
  const _ProfileSummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE1F0EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF124B45),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatePasswordTab extends StatelessWidget {
  const _UpdatePasswordTab({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFF1D59D)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFB07A17)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Use a strong password with a mix of upper-case, lower-case, numeric, and special characters.',
                  style: TextStyle(
                    color: Color(0xFF6C521A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: const [
            _ProfileInputField(label: 'Current Password', obscureText: true),
            _ProfileInputField(label: 'New Password', obscureText: true),
          ],
        ),
        SizedBox(height: 16),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: const [
            _ProfileInputField(
              label: 'Confirm New Password',
              obscureText: true,
            ),
            _ProfileInputField(
              label: 'Security Hint',
              initialValue: 'Optional hint for admin reference',
            ),
          ],
        ),
        SizedBox(height: 22),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () {},
            icon: Icon(Icons.password),
            label: Text('Update Password'),
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFF0F8F82),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({required this.mobile, required this.children});

  final bool mobile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (mobile) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) SizedBox(height: 16),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index != children.length - 1) SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _ProfileInputField extends StatelessWidget {
  const _ProfileInputField({
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final bool obscureText;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: 1,
      obscureText: obscureText,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: readOnly ? Color(0xFFF1F4F3) : Color(0xFFF9FCFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD8E8E4)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD8E8E4)),
        ),
      ),
    );
  }
}

class _ProfileDropdownField extends StatelessWidget {
  const _ProfileDropdownField({
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final resolvedItems = [
      if (value != null && value!.isNotEmpty && !items.contains(value)) value!,
      ...items,
    ];

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: resolvedItems.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled && onChanged != null
            ? Color(0xFFF9FCFB)
            : Color(0xFFF1F4F3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD8E8E4)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD8E8E4)),
        ),
      ),
    );
  }
}
