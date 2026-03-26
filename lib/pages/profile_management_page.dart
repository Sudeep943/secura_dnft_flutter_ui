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
  static String? createGender;
  static String createAddressType = 'RESIDENTIAL';
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final _createProfileFormKey = GlobalKey<FormState>();
  final _updateProfileFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _profileFlatNoController = TextEditingController();
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

  final _updateFirstNameController = TextEditingController();
  final _updateMiddleNameController = TextEditingController();
  final _updateLastNameController = TextEditingController();
  final _updateProfileIdController = TextEditingController();
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

  _ProfileManagementSection? _selectedSection;
  String? _profileType;
  String? _profilePosition;
  String? _gender;
  String _addressType = 'RESIDENTIAL';
  String? _updateGender;
  String _updateAddressType = 'RESIDENTIAL';
  String? _updateProfileType;
  String? _updateProfilePosition;
  String? _updateProfileStatus;
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
      if (_selectedSection == _ProfileManagementSection.updateProfile) {
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
    _updateFirstNameController.dispose();
    _updateMiddleNameController.dispose();
    _updateLastNameController.dispose();
    _updateProfileIdController.dispose();
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

    _profileType = _ProfileManagementDraft.createProfileType;
    _profilePosition = _ProfileManagementDraft.createProfilePosition;
    _gender = _ProfileManagementDraft.createGender;
    _addressType = _ProfileManagementDraft.createAddressType;
  }

  void _attachCreateDraftListeners() {
    _bindCreateDraftController(_firstNameController, 'firstName');
    _bindCreateDraftController(_middleNameController, 'middleName');
    _bindCreateDraftController(_lastNameController, 'lastName');
    _bindCreateDraftController(_profileFlatNoController, 'profileFlatNo');
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

    if (section == _ProfileManagementSection.updateProfile) {
      _loadProfileForUpdate();
    }
  }

  void _closeSection() {
    final closingUpdateSection =
        _selectedSection == _ProfileManagementSection.updateProfile;

    setState(() {
      _selectedSection = null;
      _ProfileManagementDraft.selectedSection = null;
    });

    if (closingUpdateSection) {
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

  bool get _canEditRestrictedProfileFields {
    final loadedProfile = _loadedProfile;
    if (loadedProfile == null) return false;

    final responseHeader = _mapValue(loadedProfile['genericHeader']);
    final userId = _stringValue(responseHeader['userId']);
    final profileId = _stringValue(loadedProfile['prflId']);

    return userId.isNotEmpty && profileId.isNotEmpty && userId != profileId;
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

    _setControllerValue(_updateFirstNameController, profileName['firstName']);
    _setControllerValue(_updateMiddleNameController, profileName['middleName']);
    _setControllerValue(_updateLastNameController, profileName['lastName']);
    _setControllerValue(_updateProfileIdController, response['prflId']);
    _updateProfileDobController.text = _formatDate(response['prflDob']);
    _setControllerValue(_updateProfileFlatNoController, response['prflFlatNo']);
    _setControllerValue(
      _updateMobileNumberController,
      contactDetails['mobileNumber'],
    );
    _setControllerValue(_updateEmailIdController, contactDetails['emailId']);
    _setControllerValue(
      _updateLandlineNumberController,
      contactDetails['landlinenumber'],
    );
    _setControllerValue(
      _updateAddressLine1Controller,
      otherAddress['addressLine1'],
    );
    _setControllerValue(
      _updateAddressLine2Controller,
      otherAddress['addressLine2'],
    );
    _setControllerValue(
      _updateAddressLine3Controller,
      otherAddress['addressLine3'],
    );
    _setControllerValue(
      _updateAddressLine4Controller,
      otherAddress['addressLine4'],
    );
    _setControllerValue(_updateLandmarkController, otherAddress['landmark']);
    _setControllerValue(_updateCityController, otherAddress['city']);
    _setControllerValue(_updateStateController, otherAddress['state']);
    _setControllerValue(
      _updatePostOfficeController,
      otherAddress['postOffice'],
    );
    _setControllerValue(
      _updatePoliceStationController,
      otherAddress['policeStation'],
    );
    _setControllerValue(_updatePinController, otherAddress['pin']);

    setState(() {
      _loadedProfile = response;
      _updateGender = _nullableValue(_stringValue(response['gender']));
      _updateAddressType =
          _nullableValue(_stringValue(otherAddress['addressType'])) ??
          'RESIDENTIAL';
      _updateProfileType = _nullableValue(_stringValue(response['prflType']));
      _updateProfilePosition = _nullableValue(
        _stringValue(response['prflPosition']),
      );
      _updateProfileStatus = _nullableValue(_stringValue(response['prflStus']));
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
    setState(() {
      _loadedProfile = null;
      _updateGender = null;
      _updateAddressType = 'RESIDENTIAL';
      _updateProfileType = null;
      _updateProfilePosition = null;
      _updateProfileStatus = null;
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

    final header = ApiService.userHeader;
    if (header == null) {
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
      'header': Map<String, dynamic>.from(header),
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
      'profileOthrAdrss': {
        'addressLine1':
            _nullableControllerValue(_updateAddressLine1Controller) ?? '',
        'addressLine2':
            _nullableControllerValue(_updateAddressLine2Controller) ?? '',
        'addressLine3':
            _nullableControllerValue(_updateAddressLine3Controller) ?? '',
        'addressLine4':
            _nullableControllerValue(_updateAddressLine4Controller) ?? '',
        'landmark': _nullableControllerValue(_updateLandmarkController) ?? '',
        'city': _nullableControllerValue(_updateCityController) ?? '',
        'state': _nullableControllerValue(_updateStateController) ?? '',
        'postOffice':
            _nullableControllerValue(_updatePostOfficeController) ?? '',
        'policeStation':
            _nullableControllerValue(_updatePoliceStationController) ?? '',
        'pin': _nullableControllerValue(_updatePinController) ?? '',
        'addressType': _updateAddressType,
      },
      'profileType': _updateProfileType,
      'profilePosition': _updateProfilePosition,
      'profilePic': _effectiveProfileImageBase64,
      'password': ApiService.loginPassword ?? '',
      'profileStatus': _updateProfileStatus,
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

    final header = ApiService.userHeader;
    if (header == null) {
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
      'contact': {
        'mobileNumber': _mobileNumberController.text.trim(),
        'emailId': _emailIdController.text.trim(),
        'landlinenumber': _landlineNumberController.text.trim(),
      },
      'profileOthrAdrss': {
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'addressLine3': _addressLine3Controller.text.trim(),
        'addressLine4': _addressLine4Controller.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postOffice': _postOfficeController.text.trim(),
        'policeStation': _policeStationController.text.trim(),
        'pin': _pinController.text.trim(),
        'addressType': _addressType,
      },
      'profileType': _profileType,
      'profilePosition': _profilePosition,
      'gender': _gender,
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

    _showStatusModal(
      title: isSuccess ? 'Profile Created' : 'Profile Creation Failed',
      message: message,
      isSuccess: isSuccess,
      profileId: response['profileId']?.toString(),
    );

    if (isSuccess) {
      _resetCreateProfileForm();
    }
  }

  void _resetCreateProfileForm() {
    _createProfileFormKey.currentState?.reset();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _profileFlatNoController.clear();
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
    setState(() {
      _profileType = null;
      _profilePosition = null;
      _gender = null;
      _addressType = 'RESIDENTIAL';
    });
    _ProfileManagementDraft.createProfile.clear();
    _ProfileManagementDraft.createProfileType = null;
    _ProfileManagementDraft.createProfilePosition = null;
    _ProfileManagementDraft.createGender = null;
    _ProfileManagementDraft.createAddressType = 'RESIDENTIAL';
  }

  String _sectionTitle() {
    switch (_selectedSection) {
      case _ProfileManagementSection.createProfile:
        return 'Create Profile';
      case _ProfileManagementSection.updateProfile:
        return 'Update Profile';
      case _ProfileManagementSection.updatePassword:
        return 'Update Password';
      case null:
        return 'Profile Management';
    }
  }

  String _sectionSubtitle() {
    switch (_selectedSection) {
      case _ProfileManagementSection.createProfile:
        return 'Fill in the required details and submit a new resident profile.';
      case _ProfileManagementSection.updateProfile:
        return 'Fetch the existing profile, edit allowed fields, update the profile picture, and submit changes.';
      case _ProfileManagementSection.updatePassword:
        return 'Update account credentials from the password management form.';
      case null:
        return 'Choose one of the profile management actions below.';
    }
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
          profileType: _profileType,
          profilePosition: _profilePosition,
          gender: _gender,
          addressType: _addressType,
          onProfileTypeChanged: (value) {
            setState(() {
              _profileType = value;
              _ProfileManagementDraft.createProfileType = value;
            });
          },
          onProfilePositionChanged: (value) {
            setState(() {
              _profilePosition = value;
              _ProfileManagementDraft.createProfilePosition = value;
            });
          },
          onGenderChanged: (value) {
            setState(() {
              _gender = value;
              _ProfileManagementDraft.createGender = value;
            });
          },
          onAddressTypeChanged: (value) {
            setState(() {
              _addressType = value ?? 'RESIDENTIAL';
              _ProfileManagementDraft.createAddressType = _addressType;
            });
          },
          requiredValidator: _requiredValidator,
          mobileValidator: _mobileValidator,
          emailValidator: _emailValidator,
          submitting: _creatingProfile,
          onSubmit: _submitCreateProfile,
          mobile: mobile,
        );
      case _ProfileManagementSection.updateProfile:
        return _UpdateProfileTab(
          formKey: _updateProfileFormKey,
          firstNameController: _updateFirstNameController,
          middleNameController: _updateMiddleNameController,
          lastNameController: _updateLastNameController,
          profileIdController: _updateProfileIdController,
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
          gender: _updateGender,
          addressType: _updateAddressType,
          profileType: _updateProfileType,
          profilePosition: _updateProfilePosition,
          profileStatus: _updateProfileStatus,
          loading: _loadingProfile,
          submitting: _updatingProfile,
          hasLoadedProfile: _loadedProfile != null,
          canEditRestrictedFields: _canEditRestrictedProfileFields,
          profileImageBytes: _effectiveProfileImageBytes,
          onGenderChanged: (value) {
            setState(() {
              _updateGender = value;
            });
          },
          onAddressTypeChanged: (value) {
            setState(() {
              _updateAddressType = value ?? 'RESIDENTIAL';
            });
          },
          onProfileTypeChanged: (value) {
            setState(() {
              _updateProfileType = value;
            });
          },
          onProfilePositionChanged: (value) {
            setState(() {
              _updateProfilePosition = value;
            });
          },
          onProfileStatusChanged: (value) {
            setState(() {
              _updateProfileStatus = value;
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Color(0xFF0F8F82), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _sectionTitle(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF124B45),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        _sectionSubtitle(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      SizedBox(height: 28),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: mobile ? 1 : 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: mobile ? 2.2 : 1.18,
                        children: [
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
                        ],
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
        title: Text('Profile Management'),
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

enum _ProfileManagementSection { createProfile, updateProfile, updatePassword }

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
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: active ? Color(0xFFE0DA84) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected ? Color(0xFF0F8F82) : Color(0xFFE4ECEA),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 50, color: Color(0xFF0F8F82)),
              SizedBox(height: 15),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
    required this.profileType,
    required this.profilePosition,
    required this.gender,
    required this.addressType,
    required this.onProfileTypeChanged,
    required this.onProfilePositionChanged,
    required this.onGenderChanged,
    required this.onAddressTypeChanged,
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
  final String? profileType;
  final String? profilePosition;
  final String? gender;
  final String addressType;
  final ValueChanged<String?> onProfileTypeChanged;
  final ValueChanged<String?> onProfilePositionChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onAddressTypeChanged;
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
              'Mandatory fields: First Name, Last Name, Mobile Number, Email ID, Profile Type, Profile Position, and Gender.',
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
                label: 'Profile Flat No',
                controller: profileFlatNoController,
              ),
              _ProfileDropdownField(
                label: 'Profile Type *',
                value: profileType,
                items: const ['OWNER', 'TENANT', 'FAMILY', 'STAFF'],
                onChanged: onProfileTypeChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Profile Type is required'
                    : null,
              ),
              _ProfileDropdownField(
                label: 'Profile Position *',
                value: profilePosition,
                items: const ['MEMBER', 'OWNER', 'TENANT', 'COMMITTEE'],
                onChanged: onProfilePositionChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Profile Position is required'
                    : null,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: 'Gender *',
                value: gender,
                items: const ['MALE', 'FEMALE', 'OTHER'],
                onChanged: onGenderChanged,
                validator: (value) => value == null || value.isEmpty
                    ? 'Gender is required'
                    : null,
              ),
              _ProfileDropdownField(
                label: 'Address Type',
                value: addressType,
                items: const ['RESIDENTIAL', 'OFFICE', 'OTHER'],
                onChanged: onAddressTypeChanged,
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
            'Other Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 1',
                controller: addressLine1Controller,
              ),
              _ProfileInputField(
                label: 'Address Line 2',
                controller: addressLine2Controller,
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
              ),
              _ProfileInputField(
                label: 'Address Line 4',
                controller: addressLine4Controller,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Landmark',
                controller: landmarkController,
              ),
              _ProfileInputField(label: 'City', controller: cityController),
              _ProfileInputField(label: 'State', controller: stateController),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Post Office',
                controller: postOfficeController,
              ),
              _ProfileInputField(
                label: 'Police Station',
                controller: policeStationController,
              ),
              _ProfileInputField(
                label: 'Pin',
                controller: pinController,
                keyboardType: TextInputType.number,
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
    required this.gender,
    required this.addressType,
    required this.profileType,
    required this.profilePosition,
    required this.profileStatus,
    required this.loading,
    required this.submitting,
    required this.hasLoadedProfile,
    required this.canEditRestrictedFields,
    required this.profileImageBytes,
    required this.onGenderChanged,
    required this.onAddressTypeChanged,
    required this.onProfileTypeChanged,
    required this.onProfilePositionChanged,
    required this.onProfileStatusChanged,
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
  final String? gender;
  final String addressType;
  final String? profileType;
  final String? profilePosition;
  final String? profileStatus;
  final bool loading;
  final bool submitting;
  final bool hasLoadedProfile;
  final bool canEditRestrictedFields;
  final Uint8List? profileImageBytes;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onAddressTypeChanged;
  final ValueChanged<String?> onProfileTypeChanged;
  final ValueChanged<String?> onProfilePositionChanged;
  final ValueChanged<String?> onProfileStatusChanged;
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
                    canEditRestrictedFields
                        ? 'Profile ID and DOB stay read-only. Status, type, and position are editable because the response user ID does not match the profile ID.'
                        : 'Profile ID, DOB, status, type, and position are locked for this profile. Use the avatar edit button to upload a new profile picture.',
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
            'Profile Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
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
              _ProfileDropdownField(
                label: 'Profile Status',
                value: profileStatus,
                items: const ['ACTIVE', 'INACTIVE', 'BLOCKED'],
                enabled: canEditRestrictedFields,
                onChanged: canEditRestrictedFields
                    ? onProfileStatusChanged
                    : null,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Profile Flat No',
                controller: profileFlatNoController,
              ),
              _ProfileDropdownField(
                label: 'Profile Type',
                value: profileType,
                items: const ['OWNER', 'TENANT', 'FAMILY', 'STAFF'],
                enabled: canEditRestrictedFields,
                onChanged: canEditRestrictedFields
                    ? onProfileTypeChanged
                    : null,
              ),
              _ProfileDropdownField(
                label: 'Profile Position',
                value: profilePosition,
                items: const [
                  'MEMBER',
                  'OWNER',
                  'TENANT',
                  'SECRETARY',
                  'COMMITTEE',
                ],
                enabled: canEditRestrictedFields,
                onChanged: canEditRestrictedFields
                    ? onProfilePositionChanged
                    : null,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileDropdownField(
                label: 'Gender',
                value: gender,
                items: const ['MALE', 'FEMALE', 'OTHER'],
                onChanged: onGenderChanged,
              ),
              _ProfileDropdownField(
                label: 'Address Type',
                value: addressType,
                items: const ['RESIDENTIAL', 'OFFICE', 'OTHER'],
                onChanged: onAddressTypeChanged,
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
            'Other Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Address Line 1',
                controller: addressLine1Controller,
              ),
              _ProfileInputField(
                label: 'Address Line 2',
                controller: addressLine2Controller,
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
              ),
              _ProfileInputField(
                label: 'Address Line 4',
                controller: addressLine4Controller,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Landmark',
                controller: landmarkController,
              ),
              _ProfileInputField(label: 'City', controller: cityController),
              _ProfileInputField(label: 'State', controller: stateController),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Post Office',
                controller: postOfficeController,
              ),
              _ProfileInputField(
                label: 'Police Station',
                controller: policeStationController,
              ),
              _ProfileInputField(
                label: 'Pin',
                controller: pinController,
                keyboardType: TextInputType.number,
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
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
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
      value: value,
      items: resolvedItems.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Color(0xFFF9FCFB) : Color(0xFFF1F4F3),
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
