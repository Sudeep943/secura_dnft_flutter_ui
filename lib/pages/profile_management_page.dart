import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
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
  static _CreateProfileExistingAction? createExistingProfileAction;
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
  final _tenantStartDateController = TextEditingController();
  final _tenantEndDateController = TextEditingController();
  final _ownerStartDateController = TextEditingController();
  final _ownerEndDateController = TextEditingController();

  _ProfileManagementSection? _selectedSection;
  String? _profileType;
  String? _profilePosition;
  String? _profileKind;
  String? _gender;
  Timer? _createProfileValidationDebounce;
  int _createProfileValidationRequestId = 0;
  bool _validatingExistingProfile = false;
  bool _existingProfileTypeFound = false;
  String? _existingProfileSelectionError;
  _CreateProfileExistingAction? _existingProfileAction;
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
  bool _loadingTenant = false;
  bool _updatingTenant = false;
  bool _validatingExistingTenant = false;
  bool _loadingOwner = false;
  bool _updatingOwner = false;
  bool _validatingExistingOwner = false;
  Map<String, dynamic>? _loadedProfile;
  Map<String, dynamic>? _loadedTenantResponse;
  Map<String, dynamic>? _loadedOwnerResponse;
  String? _currentProfilePicBase64;
  String? _selectedProfileImageBase64;
  Uint8List? _selectedProfileImageBytes;
  List<_TenantProfileData> _tenantProfiles = [];
  List<_TenantExistingDocument> _tenantExistingDocuments = [];
  final List<_TenantNewDocumentDraft> _tenantNewDocuments = [];
  List<_TenantProfileData> _ownerProfiles = [];
  List<_TenantExistingDocument> _ownerExistingDocuments = [];
  final List<_TenantNewDocumentDraft> _ownerNewDocuments = [];
  bool _tenantVerified = false;
  String _tenantStatus = '';
  String? _tenantInlineErrorMessage;
  bool _ownerVerified = false;
  String _ownerStatus = '';
  String? _tenantDocumentStatusMessage;
  String? _tenantDocumentStatusProfileId;
  bool _tenantDocumentStatusIsSuccess = false;
  String? _ownerDocumentStatusMessage;
  String? _ownerDocumentStatusProfileId;
  bool _ownerDocumentStatusIsSuccess = false;
  bool _existingTenantTypeFound = false;
  String? _existingTenantSelectionError;
  _CreateProfileExistingAction? _existingTenantAction;
  String? _removingTenantProfileId;
  bool _existingOwnerTypeFound = false;
  String? _existingOwnerSelectionError;
  _CreateProfileExistingAction? _existingOwnerAction;
  String? _removingOwnerProfileId;

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  void initState() {
    super.initState();
    _restoreDrafts();
    _attachCreateDraftListeners();
    _profileFlatNoController.addListener(_scheduleCreateProfileValidation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedSection == _ProfileManagementSection.updateProfile ||
          _selectedSection == _ProfileManagementSection.viewProfile) {
        _loadProfileForUpdate();
      } else if (_selectedSection ==
          _ProfileManagementSection.tenantManagement) {
        _loadTenantManagement();
      } else if (_selectedSection ==
          _ProfileManagementSection.ownerManagement) {
        _loadOwnerManagement();
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
    _tenantStartDateController.dispose();
    _tenantEndDateController.dispose();
    _ownerStartDateController.dispose();
    _ownerEndDateController.dispose();
    _createProfileValidationDebounce?.cancel();
    _disposeTenantDocumentDrafts();
    _disposeOwnerDocumentDrafts();
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
    _existingProfileAction =
        _ProfileManagementDraft.createExistingProfileAction;
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
    } else if (section == _ProfileManagementSection.tenantManagement) {
      _loadTenantManagement();
    } else if (section == _ProfileManagementSection.ownerManagement) {
      _loadOwnerManagement();
    }
  }

  void _closeSection() {
    final closingProfileSection =
        _selectedSection == _ProfileManagementSection.updateProfile ||
        _selectedSection == _ProfileManagementSection.viewProfile;
    final closingTenantSection =
        _selectedSection == _ProfileManagementSection.tenantManagement;
    final closingOwnerSection =
        _selectedSection == _ProfileManagementSection.ownerManagement;

    setState(() {
      _selectedSection = null;
      _ProfileManagementDraft.selectedSection = null;
    });

    if (closingProfileSection) {
      _clearUpdateProfileForm();
    }

    if (closingTenantSection) {
      _clearTenantManagementState();
    }

    if (closingOwnerSection) {
      _clearOwnerManagementState();
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

  Future<bool> _showRemoveProfileConfirmation({
    required String entityLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Remove $entityLabel Profile',
            style: TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are You Sure To Delete The Profile from $entityLabel List ?',
            style: TextStyle(color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Color(0xFFB3261E)),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
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

  bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = _stringValue(value).toLowerCase();
    return normalized == 'true' || normalized == 'y' || normalized == 'yes';
  }

  dynamic _decodeJsonValue(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonDecode(trimmed);
        } catch (_) {
          return value;
        }
      }
    }

    return value;
  }

  Map<String, dynamic> _jsonMapValue(dynamic value) {
    final decoded = _decodeJsonValue(value);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _jsonMapList(dynamic value) {
    final decoded = _decodeJsonValue(value);
    if (decoded is List) {
      return decoded
          .whereType<dynamic>()
          .map(
            (item) => item is Map<String, dynamic>
                ? item
                : item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{},
          )
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  String _composeDisplayName(Map<String, dynamic> name) {
    final parts = [
      _stringValue(name['firstName']),
      _stringValue(name['middleName']),
      _stringValue(name['lastName']),
    ].where((part) => part.isNotEmpty).toList();

    return parts.join(' ').trim();
  }

  String _formatAddressDisplay(Map<String, dynamic> address) {
    final parts = [
      _stringValue(address['addressLine1']),
      _stringValue(address['addressLine2']),
      _stringValue(address['addressLine3']),
      _stringValue(address['addressLine4']),
      _stringValue(address['landmark']),
      _stringValue(address['city']),
      _stringValue(address['state']),
      _stringValue(address['postOffice']),
      _stringValue(address['policeStation']),
      _stringValue(address['pin']),
    ].where((part) => part.isNotEmpty).toList();

    return parts.isEmpty ? '-' : parts.join(', ');
  }

  Uint8List? _decodeBase64Bytes(String? value) {
    final normalized = _nullableValue(value);
    if (normalized == null) {
      return null;
    }

    final encodedValue = normalized.contains(',')
        ? normalized.split(',').last
        : normalized;

    try {
      return base64Decode(encodedValue);
    } catch (_) {
      return null;
    }
  }

  String _matchDocumentProfileId(
    String documentName,
    List<_TenantProfileData> profiles,
  ) {
    final trimmedName = documentName.trim();
    for (final profile in profiles) {
      if (trimmedName == profile.profileId ||
          trimmedName.startsWith('${profile.profileId}_') ||
          trimmedName.startsWith('${profile.profileId} ')) {
        return profile.profileId;
      }
    }

    final prefix = trimmedName.split('_').first.trim();
    for (final profile in profiles) {
      if (profile.profileId == prefix) {
        return profile.profileId;
      }
    }

    return '';
  }

  void _disposeTenantDocumentDrafts() {
    for (final draft in _tenantNewDocuments) {
      draft.dispose();
    }
    _tenantNewDocuments.clear();
  }

  void _disposeOwnerDocumentDrafts() {
    for (final draft in _ownerNewDocuments) {
      draft.dispose();
    }
    _ownerNewDocuments.clear();
  }

  void _clearTenantManagementState() {
    _tenantStartDateController.clear();
    _tenantEndDateController.clear();
    _disposeTenantDocumentDrafts();
    _loadedTenantResponse = null;
    _tenantProfiles = [];
    _tenantExistingDocuments = [];
    _tenantVerified = false;
    _tenantStatus = '';
    _tenantInlineErrorMessage = null;
    _tenantDocumentStatusMessage = null;
    _tenantDocumentStatusProfileId = null;
    _tenantDocumentStatusIsSuccess = false;
    _validatingExistingTenant = false;
    _existingTenantTypeFound = false;
    _existingTenantSelectionError = null;
    _existingTenantAction = null;
    _removingTenantProfileId = null;
    _loadingTenant = false;
    _updatingTenant = false;
  }

  void _clearOwnerManagementState() {
    _ownerStartDateController.clear();
    _ownerEndDateController.clear();
    _disposeOwnerDocumentDrafts();
    _loadedOwnerResponse = null;
    _ownerProfiles = [];
    _ownerExistingDocuments = [];
    _ownerVerified = false;
    _ownerStatus = '';
    _ownerDocumentStatusMessage = null;
    _ownerDocumentStatusProfileId = null;
    _ownerDocumentStatusIsSuccess = false;
    _validatingExistingOwner = false;
    _existingOwnerTypeFound = false;
    _existingOwnerSelectionError = null;
    _existingOwnerAction = null;
    _removingOwnerProfileId = null;
    _loadingOwner = false;
    _updatingOwner = false;
  }

  Future<void> _removeTenantProfile(_TenantProfileData profile) async {
    final flatId = _resolveTenantFlatId();
    if (flatId.isEmpty) {
      await _showStatusModal(
        title: 'Tenant Removal Failed',
        message: 'Unable to find the flat number required to remove a tenant.',
        isSuccess: false,
      );
      return;
    }

    final confirmed = await _showRemoveProfileConfirmation(
      entityLabel: 'Tenant',
    );
    if (!confirmed) {
      return;
    }

    setState(() {
      _removingTenantProfileId = profile.profileId;
    });

    final response = await ApiService.removeProfileFromOwnerTenant(
      flatId: flatId,
      profileId: profile.profileId,
      profileType: 'TENANT',
    );

    if (!mounted) return;

    setState(() {
      _removingTenantProfileId = null;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Tenant Removal Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['message']);
    await _showStatusModal(
      title: isSuccess ? 'Tenant Removed' : 'Tenant Removal Failed',
      message: _stringValue(response['message']).isNotEmpty
          ? _stringValue(response['message'])
          : isSuccess
          ? 'Tenant profile was removed successfully.'
          : 'Unable to remove the selected tenant profile.',
      isSuccess: isSuccess,
    );

    if (isSuccess) {
      final genericHeader = _jsonMapValue(
        _loadedTenantResponse?['genericHeader'],
      );
      final tenant = _jsonMapValue(_loadedTenantResponse?['tenant']);
      _disposeTenantDocumentDrafts();
      setState(() {
        _tenantProfiles = _tenantProfiles
            .where((item) => item.profileId != profile.profileId)
            .toList();
        _tenantExistingDocuments = _tenantExistingDocuments
            .where((item) => item.profileId != profile.profileId)
            .toList();
        _tenantStartDateController.clear();
        _tenantEndDateController.clear();
        _tenantVerified = false;
        _tenantStatus = '';
        _tenantDocumentStatusMessage = null;
        _tenantDocumentStatusProfileId = null;
        _tenantDocumentStatusIsSuccess = false;
        _loadedTenantResponse = {
          'genericHeader': genericHeader,
          'tenant': {
            ...tenant,
            'flatId': flatId,
            'flatNo': _stringValue(tenant['flatNo']).isNotEmpty
                ? _stringValue(tenant['flatNo'])
                : flatId,
            'status': '',
            'startDate': '',
            'endDate': '',
            'verified': false,
            'document': <Map<String, dynamic>>[],
          },
          'profile': <Map<String, dynamic>>[],
        };
      });
      await _loadTenantManagement(showErrorModal: false);
    }
  }

  Future<void> _removeOwnerProfile(_TenantProfileData profile) async {
    final flatId = _resolveOwnerFlatId();
    if (flatId.isEmpty) {
      await _showStatusModal(
        title: 'Owner Removal Failed',
        message: 'Unable to find the flat number required to remove an owner.',
        isSuccess: false,
      );
      return;
    }

    final confirmed = await _showRemoveProfileConfirmation(
      entityLabel: 'Owner',
    );
    if (!confirmed) {
      return;
    }

    setState(() {
      _removingOwnerProfileId = profile.profileId;
    });

    final response = await ApiService.removeProfileFromOwnerTenant(
      flatId: flatId,
      profileId: profile.profileId,
      profileType: 'OWNER',
    );

    if (!mounted) return;

    setState(() {
      _removingOwnerProfileId = null;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Owner Removal Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['message']);
    await _showStatusModal(
      title: isSuccess ? 'Owner Removed' : 'Owner Removal Failed',
      message: _stringValue(response['message']).isNotEmpty
          ? _stringValue(response['message'])
          : isSuccess
          ? 'Owner profile was removed successfully.'
          : 'Unable to remove the selected owner profile.',
      isSuccess: isSuccess,
    );

    if (isSuccess) {
      await _loadOwnerManagement(showErrorModal: false);
    }
  }

  Future<void> _pickTenantDate({
    required TextEditingController controller,
    required String helpText,
  }) async {
    final initialDate = _parseDateInput(controller.text) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: helpText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _brandColor,
              secondary: _brandColor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      controller.text = _formatPickerDate(pickedDate);
    });
  }

  String _formatTenantDateForRequest(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.contains('T')) {
      return trimmed;
    }

    return '${trimmed}T00:00:00Z';
  }

  String _fileExtensionFromName(String value) {
    final trimmed = value.trim();
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot <= 0 || lastDot == trimmed.length - 1) {
      return '';
    }

    return trimmed.substring(lastDot + 1).toLowerCase();
  }

  String _fileNameWithoutExtension(String value) {
    final trimmed = value.trim();
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot <= 0) {
      return trimmed;
    }

    return trimmed.substring(0, lastDot);
  }

  String _normalizedDocumentBaseName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return _fileNameWithoutExtension(
      trimmed,
    ).replaceAll(RegExp(r'\s+'), '_').trim();
  }

  String _guessExtensionFromBytes(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'pdf';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }

    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }

    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }

    return '';
  }

  String _tenantRequestDocumentName(_TenantNewDocumentDraft draft) {
    final baseName = _normalizedDocumentBaseName(
      draft.documentNameController.text,
    );
    final selectedExtension = _fileExtensionFromName(draft.fileName ?? '');
    final normalizedName = '${draft.profileId}_$baseName';
    if (selectedExtension.isEmpty) {
      return normalizedName;
    }

    return '$normalizedName.$selectedExtension';
  }

  MimeType _mimeTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;
      case 'png':
        return MimeType.png;
      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;
      case 'txt':
        return MimeType.text;
      case 'json':
        return MimeType.json;
      case 'xml':
        return MimeType.xml;
      case 'yaml':
      case 'yml':
        return MimeType.yaml;
      case 'csv':
        return MimeType.csv;
      case 'zip':
        return MimeType.zip;
      case 'docx':
        return MimeType.microsoftWord;
      case 'xlsx':
        return MimeType.microsoftExcel;
      case 'pptx':
        return MimeType.microsoftPresentation;
      default:
        return MimeType.other;
    }
  }

  Map<String, dynamic>? _buildTenantUpdateRequest({
    Iterable<_TenantNewDocumentDraft> additionalDrafts = const [],
  }) {
    final header = _buildHeaderRequest();
    if (header.values.every((value) => _stringValue(value).isEmpty)) {
      return null;
    }

    final flatId = _readHeaderValue(['flatNo']);
    if (flatId.isEmpty || _loadedTenantResponse == null) {
      return null;
    }

    final tenant = _jsonMapValue(_loadedTenantResponse?['tenant']);

    return {
      'header': header,
      'status': _tenantStatus.isNotEmpty
          ? _tenantStatus
          : _stringValue(tenant['status']),
      'flatId': flatId,
      'startDate': _formatTenantDateForRequest(_tenantStartDateController.text),
      'endDate': _formatTenantDateForRequest(_tenantEndDateController.text),
      'verified': _tenantVerified,
      'listOfDocuments': [
        for (final document in _tenantExistingDocuments)
          {
            'documentName': document.documentName,
            'documentCode': document.documentCode,
          },
        for (final draft in additionalDrafts)
          {
            'documentName': _tenantRequestDocumentName(draft),
            'documentCode': draft.documentBase64,
          },
      ],
    };
  }

  Map<String, dynamic>? _buildOwnerUpdateRequest({
    Iterable<_TenantNewDocumentDraft> additionalDrafts = const [],
  }) {
    final header = _buildHeaderRequest();
    if (header.values.every((value) => _stringValue(value).isEmpty)) {
      return null;
    }

    final flatId = _readHeaderValue(['flatNo']);
    if (flatId.isEmpty || _loadedOwnerResponse == null) {
      return null;
    }

    final owner = _jsonMapValue(_loadedOwnerResponse?['owner']);

    return {
      'header': header,
      'status': _ownerStatus.isNotEmpty
          ? _ownerStatus
          : _stringValue(owner['status']),
      'flatId': flatId,
      'startDate': _formatTenantDateForRequest(_ownerStartDateController.text),
      'endDate': _formatTenantDateForRequest(_ownerEndDateController.text),
      'verified': _ownerVerified,
      'listOfDocuments': [
        for (final document in _ownerExistingDocuments)
          {
            'documentName': document.documentName,
            'documentCode': document.documentCode,
          },
        for (final draft in additionalDrafts)
          {
            'documentName': _tenantRequestDocumentName(draft),
            'documentCode': draft.documentBase64,
          },
      ],
    };
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

  DateTime? _parseDateInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _formatPickerDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickCreateProfileDob() async {
    final initialDate =
        _parseDateInput(_profileDobController.text) ?? DateTime.now();
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Profile DOB',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _brandColor,
              secondary: _brandColor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _profileDobController.text = _formatPickerDate(pickedDate);
    });
  }

  void _scheduleCreateProfileValidation() {
    _createProfileValidationDebounce?.cancel();

    final flatId = _profileFlatNoController.text.trim();
    final profileType = _profileType?.trim() ?? '';
    if (flatId.isEmpty || profileType.isEmpty) {
      _resetCreateProfileValidation();
      return;
    }

    final requestId = ++_createProfileValidationRequestId;
    setState(() {
      _validatingExistingProfile = true;
      _existingProfileTypeFound = false;
      _existingProfileSelectionError = null;
      _existingProfileAction = null;
      _ProfileManagementDraft.createExistingProfileAction = null;
    });

    _createProfileValidationDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        _validateCreateProfileExistingOwner(
          flatId: flatId,
          profileType: profileType,
          requestId: requestId,
        );
      },
    );
  }

  void _resetCreateProfileValidation() {
    _createProfileValidationRequestId++;
    if (!_validatingExistingProfile &&
        !_existingProfileTypeFound &&
        _existingProfileSelectionError == null &&
        _existingProfileAction == null) {
      return;
    }

    setState(() {
      _validatingExistingProfile = false;
      _existingProfileTypeFound = false;
      _existingProfileSelectionError = null;
      _existingProfileAction = null;
      _ProfileManagementDraft.createExistingProfileAction = null;
    });
  }

  Future<bool> _validateCreateProfileExistingOwner({
    required String flatId,
    required String profileType,
    int? requestId,
  }) async {
    final exists =
        await ApiService.validateCurrentOwner(
          flatId: flatId,
          profileType: profileType,
        ) ??
        false;

    if (!mounted) {
      return exists;
    }

    if (requestId != null && requestId != _createProfileValidationRequestId) {
      return exists;
    }

    setState(() {
      _validatingExistingProfile = false;
      _existingProfileTypeFound = exists;
      _existingProfileSelectionError = null;
      if (!exists) {
        _existingProfileAction = null;
        _ProfileManagementDraft.createExistingProfileAction = null;
      }
    });

    return exists;
  }

  Future<bool> _validateExistingTenantOwner({required String flatId}) async {
    final exists =
        await ApiService.validateCurrentOwner(
          flatId: flatId,
          profileType: 'TENANT',
        ) ??
        false;

    if (!mounted) {
      return exists;
    }

    setState(() {
      _validatingExistingTenant = false;
      _existingTenantTypeFound = exists;
      _existingTenantSelectionError = null;
      if (!exists) {
        _existingTenantAction = null;
      }
    });

    return exists;
  }

  Future<List<_TenantSearchResult>> _searchTenantProfiles(
    String inputKey,
  ) async {
    final response = await ApiService.searchProfile(inputKey: inputKey) ?? [];

    return response
        .map((entry) {
          final nameMap = _jsonMapValue(entry['prflName']);
          final displayName = _stringValue(entry['displayName']).isNotEmpty
              ? _stringValue(entry['displayName'])
              : _composeDisplayName(nameMap);
          final profileId = _stringValue(entry['profileId']).isNotEmpty
              ? _stringValue(entry['profileId'])
              : _stringValue(entry['prflId']);
          final profilePicUrl = _stringValue(entry['profilePic']).isNotEmpty
              ? _stringValue(entry['profilePic'])
              : _stringValue(entry['profile_pic']);

          return _TenantSearchResult(
            displayName: displayName,
            profileId: profileId,
            profilePicUrl: profilePicUrl,
            profilePicBytes: _decodeBase64Bytes(profilePicUrl),
          );
        })
        .where((entry) => entry.profileId.isNotEmpty)
        .toList();
  }

  String _resolveTenantFlatId() {
    final tenant = _jsonMapValue(_loadedTenantResponse?['tenant']);
    final tenantFlatId = _stringValue(tenant['flatId']);
    if (tenantFlatId.isNotEmpty) {
      return tenantFlatId;
    }

    final tenantFlatNo = _stringValue(tenant['flatNo']);
    if (tenantFlatNo.isNotEmpty) {
      return tenantFlatNo;
    }

    return _readHeaderValue(['flatNo']);
  }

  void _dismissExistingTenantPanel() {
    setState(() {
      _validatingExistingTenant = false;
      _existingTenantTypeFound = false;
      _existingTenantSelectionError = null;
      _existingTenantAction = null;
    });
  }

  Future<void> _handleAddTenantPressed() async {
    final flatId = _resolveTenantFlatId();
    if (flatId.isEmpty) {
      await _showStatusModal(
        title: 'Tenant Add Failed',
        message: 'Unable to find the flat number required to add a tenant.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _validatingExistingTenant = true;
      _existingTenantTypeFound = false;
      _existingTenantSelectionError = null;
      _existingTenantAction = null;
    });

    final exists = await _validateExistingTenantOwner(flatId: flatId);
    if (!mounted || exists) {
      return;
    }

    await _proceedAddTenant();
  }

  Future<void> _proceedAddTenant() async {
    final flatId = _resolveTenantFlatId();
    if (flatId.isEmpty) {
      await _showStatusModal(
        title: 'Tenant Add Failed',
        message: 'Unable to find the flat number required to add a tenant.',
        isSuccess: false,
      );
      return;
    }

    if (_existingTenantTypeFound && _existingTenantAction == null) {
      setState(() {
        _existingTenantSelectionError =
            'Please select one operation before continuing.';
      });
      return;
    }

    final addToExisting =
        _existingTenantTypeFound &&
            _existingTenantAction == _CreateProfileExistingAction.addToExisting
        ? 'Y'
        : 'N';

    await _showAddTenantSearchModal(
      flatId: flatId,
      addToExisting: addToExisting,
    );
  }

  Future<void> _showAddTenantSearchModal({
    required String flatId,
    required String addToExisting,
  }) async {
    final searchController = TextEditingController();
    Timer? searchDebounce;
    var searchRequestId = 0;
    var dialogOpen = true;
    var searching = false;
    var addingProfileId = '';
    String? errorMessage;
    var results = <_TenantSearchResult>[];

    Future<void> runSearch(String value, StateSetter setModalState) async {
      final query = value.trim();
      searchRequestId++;
      final requestId = searchRequestId;

      if (query.isEmpty) {
        if (!dialogOpen) {
          return;
        }
        setModalState(() {
          searching = false;
          errorMessage = null;
          results = [];
        });
        return;
      }

      setModalState(() {
        searching = true;
        errorMessage = null;
      });

      final response = await _searchTenantProfiles(query);
      if (!dialogOpen || requestId != searchRequestId) {
        return;
      }

      setModalState(() {
        searching = false;
        results = response;
        errorMessage = response.isEmpty
            ? 'No matching profiles were found.'
            : null;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> addTenant(_TenantSearchResult result) async {
              final navigator = Navigator.of(dialogContext);

              setModalState(() {
                addingProfileId = result.profileId;
              });

              final response = await ApiService.addTenant(
                profileId: result.profileId,
                flatId: flatId,
                addToExisting: addToExisting,
              );

              if (!mounted) {
                return;
              }

              dialogOpen = false;
              if (navigator.canPop()) {
                navigator.pop();
              }

              if (response == null) {
                await _showStatusModal(
                  title: 'Tenant Add Failed',
                  message: 'No response was returned from the server.',
                  isSuccess: false,
                );
                return;
              }

              final isSuccess = _isSuccessResponse(
                response,
                idKeys: const ['message'],
              );
              final message = _stringValue(response['message']).isNotEmpty
                  ? _stringValue(response['message'])
                  : isSuccess
                  ? 'Tenant added successfully.'
                  : 'Unable to add the selected tenant.';

              await _showStatusModal(
                title: isSuccess ? 'Tenant Added' : 'Tenant Add Failed',
                message: message,
                isSuccess: isSuccess,
              );

              if (isSuccess) {
                setState(() {
                  _validatingExistingTenant = false;
                  _existingTenantTypeFound = false;
                  _existingTenantAction = null;
                  _existingTenantSelectionError = null;
                });
                await _loadTenantManagement(showErrorModal: false);
              }
            }

            return AlertDialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Add Tenant',
                style: TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width < 800
                    ? double.maxFinite
                    : 720,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      addToExisting == 'Y'
                          ? 'Search for a profile to add to the existing tenant list.'
                          : 'Search for a profile to create a new tenant entry and replace the existing one.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search profile',
                        hintText: 'Type a name or profile ID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (value) {
                        searchDebounce?.cancel();
                        searchDebounce = Timer(
                          const Duration(milliseconds: 350),
                          () => runSearch(value, setModalState),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    if (searching)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(color: _brandColor),
                      ),
                    if (!searching &&
                        searchController.text.trim().isEmpty &&
                        results.isEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF4FBFA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFD5EBE7)),
                        ),
                        child: Text(
                          'Start typing to search profiles.',
                          style: TextStyle(
                            color: Color(0xFF124B45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF6E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFFFD6A0)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Color(0xFF7A3F0D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            ImageProvider<Object>? imageProvider;
                            if (result.profilePicUrl.startsWith('http')) {
                              imageProvider = NetworkImage(
                                result.profilePicUrl,
                              );
                            } else if (result.profilePicBytes != null) {
                              imageProvider = MemoryImage(
                                result.profilePicBytes!,
                              );
                            }
                            final initials = result.displayName
                                .split(RegExp(r'\s+'))
                                .where((part) => part.isNotEmpty)
                                .take(2)
                                .map((part) => part[0].toUpperCase())
                                .join();

                            return Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Color(0xFFF9FCFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Color(0xFFDCEBE8)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFFE7F3F0),
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null
                                        ? Text(
                                            initials.isEmpty ? 'TP' : initials,
                                            style: TextStyle(
                                              color: _brandColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.displayName,
                                          style: TextStyle(
                                            color: Color(0xFF124B45),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          result.profileId,
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: addingProfileId.isNotEmpty
                                        ? null
                                        : () => addTenant(result),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _brandColor,
                                    ),
                                    child: addingProfileId == result.profileId
                                        ? SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text('Add'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );

    dialogOpen = false;
    searchDebounce?.cancel();
    searchController.dispose();
  }

  Future<bool> _validateExistingOwnerProfile({required String flatId}) async {
    final exists =
        await ApiService.validateCurrentOwner(
          flatId: flatId,
          profileType: 'OWNER',
        ) ??
        false;

    if (!mounted) {
      return exists;
    }

    setState(() {
      _validatingExistingOwner = false;
      _existingOwnerTypeFound = exists;
      _existingOwnerSelectionError = null;
      if (!exists) {
        _existingOwnerAction = null;
      }
    });

    return exists;
  }

  String _resolveOwnerFlatId() {
    final owner = _jsonMapValue(_loadedOwnerResponse?['owner']);
    final ownerFlatId = _stringValue(owner['flatId']);
    if (ownerFlatId.isNotEmpty) {
      return ownerFlatId;
    }

    final ownerFlatNo = _stringValue(owner['flatNo']);
    if (ownerFlatNo.isNotEmpty) {
      return ownerFlatNo;
    }

    return _readHeaderValue(['flatNo']);
  }

  void _dismissExistingOwnerPanel() {
    setState(() {
      _validatingExistingOwner = false;
      _existingOwnerTypeFound = false;
      _existingOwnerSelectionError = null;
      _existingOwnerAction = null;
    });
  }

  Future<void> _handleAddOwnerPressed() async {
    final flatId = _resolveOwnerFlatId();
    if (flatId.isEmpty) {
      await _showStatusModal(
        title: 'Owner Add Failed',
        message: 'Unable to find the flat number required to add an owner.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _validatingExistingOwner = true;
      _existingOwnerTypeFound = false;
      _existingOwnerSelectionError = null;
      _existingOwnerAction = null;
    });

    final exists = await _validateExistingOwnerProfile(flatId: flatId);
    if (!mounted || exists) {
      return;
    }

    await _proceedAddOwner();
  }

  Future<void> _proceedAddOwner() async {
    final flatId = _resolveOwnerFlatId();
    if (flatId.isEmpty) {
      await _showStatusModal(
        title: 'Owner Add Failed',
        message: 'Unable to find the flat number required to add an owner.',
        isSuccess: false,
      );
      return;
    }

    if (_existingOwnerTypeFound && _existingOwnerAction == null) {
      setState(() {
        _existingOwnerSelectionError =
            'Please select one operation before continuing.';
      });
      return;
    }

    final addToExisting =
        _existingOwnerTypeFound &&
            _existingOwnerAction == _CreateProfileExistingAction.addToExisting
        ? 'Y'
        : 'N';

    await _showAddOwnerSearchModal(
      flatId: flatId,
      addToExisting: addToExisting,
    );
  }

  Future<void> _showAddOwnerSearchModal({
    required String flatId,
    required String addToExisting,
  }) async {
    final searchController = TextEditingController();
    Timer? searchDebounce;
    var searchRequestId = 0;
    var dialogOpen = true;
    var searching = false;
    var addingProfileId = '';
    String? errorMessage;
    var results = <_TenantSearchResult>[];

    Future<void> runSearch(String value, StateSetter setModalState) async {
      final query = value.trim();
      searchRequestId++;
      final requestId = searchRequestId;

      if (query.isEmpty) {
        if (!dialogOpen) {
          return;
        }
        setModalState(() {
          searching = false;
          errorMessage = null;
          results = [];
        });
        return;
      }

      setModalState(() {
        searching = true;
        errorMessage = null;
      });

      final response = await _searchTenantProfiles(query);
      if (!dialogOpen || requestId != searchRequestId) {
        return;
      }

      setModalState(() {
        searching = false;
        results = response;
        errorMessage = response.isEmpty
            ? 'No matching profiles were found.'
            : null;
      });
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> addOwner(_TenantSearchResult result) async {
              final navigator = Navigator.of(dialogContext);

              setModalState(() {
                addingProfileId = result.profileId;
              });

              final response = await ApiService.addOwner(
                profileId: result.profileId,
                flatId: flatId,
                addToExisting: addToExisting,
              );

              if (!mounted) {
                return;
              }

              dialogOpen = false;
              if (navigator.canPop()) {
                navigator.pop();
              }

              if (response == null) {
                await _showStatusModal(
                  title: 'Owner Add Failed',
                  message: 'No response was returned from the server.',
                  isSuccess: false,
                );
                return;
              }

              final isSuccess = _isSuccessResponse(
                response,
                idKeys: const ['message'],
              );
              final message = _stringValue(response['message']).isNotEmpty
                  ? _stringValue(response['message'])
                  : isSuccess
                  ? 'Owner added successfully.'
                  : 'Unable to add the selected owner.';

              await _showStatusModal(
                title: isSuccess ? 'Owner Added' : 'Owner Add Failed',
                message: message,
                isSuccess: isSuccess,
              );

              if (isSuccess) {
                setState(() {
                  _validatingExistingOwner = false;
                  _existingOwnerTypeFound = false;
                  _existingOwnerAction = null;
                  _existingOwnerSelectionError = null;
                });
                await _loadOwnerManagement(showErrorModal: false);
              }
            }

            return AlertDialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Add Owner',
                style: TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width < 800
                    ? double.maxFinite
                    : 720,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      addToExisting == 'Y'
                          ? 'Search for a profile to add to the existing owner list.'
                          : 'Search for a profile to create a new owner entry and replace the existing one.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search profile',
                        hintText: 'Type a name or profile ID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onChanged: (value) {
                        searchDebounce?.cancel();
                        searchDebounce = Timer(
                          const Duration(milliseconds: 350),
                          () => runSearch(value, setModalState),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    if (searching)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(color: _brandColor),
                      ),
                    if (!searching &&
                        searchController.text.trim().isEmpty &&
                        results.isEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF4FBFA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFD5EBE7)),
                        ),
                        child: Text(
                          'Start typing to search profiles.',
                          style: TextStyle(
                            color: Color(0xFF124B45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF6E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFFFD6A0)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Color(0xFF7A3F0D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final result = results[index];
                            ImageProvider<Object>? imageProvider;
                            if (result.profilePicUrl.startsWith('http')) {
                              imageProvider = NetworkImage(
                                result.profilePicUrl,
                              );
                            } else if (result.profilePicBytes != null) {
                              imageProvider = MemoryImage(
                                result.profilePicBytes!,
                              );
                            }
                            final initials = result.displayName
                                .split(RegExp(r'\s+'))
                                .where((part) => part.isNotEmpty)
                                .take(2)
                                .map((part) => part[0].toUpperCase())
                                .join();

                            return Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Color(0xFFF9FCFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Color(0xFFDCEBE8)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFFE7F3F0),
                                    backgroundImage: imageProvider,
                                    child: imageProvider == null
                                        ? Text(
                                            initials.isEmpty ? 'OP' : initials,
                                            style: TextStyle(
                                              color: _brandColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.displayName,
                                          style: TextStyle(
                                            color: Color(0xFF124B45),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          result.profileId,
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: addingProfileId.isNotEmpty
                                        ? null
                                        : () => addOwner(result),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _brandColor,
                                    ),
                                    child: addingProfileId == result.profileId
                                        ? SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text('Add'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );

    dialogOpen = false;
    searchDebounce?.cancel();
    searchController.dispose();
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

    return _decodeBase64Bytes(_effectiveProfileImageBase64);
  }

  void _populateUpdateProfileForm(Map<String, dynamic> response) {
    final profileName = _mapValue(response['prflName']);
    final contactDetails = _mapValue(response['contactDetails']);
    final otherAddress = _mapValue(response['prflOthrAdrss']);
    final primaryAddress = _mapValue(response['primaryAddress']);
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
      'primaryPostalAddress': _buildAddressRequest(
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

    final flatId = _profileFlatNoController.text.trim();
    final profileType = _profileType?.trim() ?? '';
    if (flatId.isNotEmpty && profileType.isNotEmpty) {
      _createProfileValidationDebounce?.cancel();
      final exists = await _validateCreateProfileExistingOwner(
        flatId: flatId,
        profileType: profileType,
      );
      if (!mounted) return;

      if (exists && _existingProfileAction == null) {
        final profileTypeLabel = _profileTypeDisplayLabel(
          profileType,
          fallback: 'profile',
        );
        setState(() {
          _existingProfileSelectionError =
              'Select how to proceed with the existing $profileTypeLabel profile.';
        });
        return;
      }
    }

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
      if (_existingProfileTypeFound && _existingProfileAction != null)
        'addToExistingProfileType':
            _existingProfileAction ==
                _CreateProfileExistingAction.createNewDeleteExisting
            ? 'N'
            : 'Y',
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

  Future<void> _loadTenantManagement({
    bool showErrorModal = true,
    bool preserveDocumentStatus = false,
  }) async {
    final flatId = _readHeaderValue(['flatNo']);
    if (flatId.isEmpty) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Tenant Fetch Failed',
          message:
              'Unable to find the logged-in flat number required to fetch tenant details.',
          isSuccess: false,
        );
      }
      return;
    }

    setState(() {
      _loadingTenant = true;
      _tenantInlineErrorMessage = null;
    });

    final response = await ApiService.getTenant(flatId: flatId);
    if (!mounted) return;

    setState(() {
      _loadingTenant = false;
    });

    if (response == null) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Tenant Fetch Failed',
          message: 'No response was returned from the server.',
          isSuccess: false,
        );
      }
      return;
    }

    final messageCode = _stringValue(response['messageCode']);
    final isSuccess = _isSuccessResponse(response, idKeys: const ['tenant']);
    if (!isSuccess) {
      final message = _stringValue(response['message']).isNotEmpty
          ? _stringValue(response['message'])
          : 'Unable to load tenant details for the current flat.';

      if (messageCode == 'ERR_MESSAGE_35') {
        _disposeTenantDocumentDrafts();
        setState(() {
          _loadedTenantResponse = null;
          _tenantProfiles = [];
          _tenantExistingDocuments = [];
          _tenantStartDateController.clear();
          _tenantEndDateController.clear();
          _tenantVerified = false;
          _tenantStatus = '';
          _tenantInlineErrorMessage = message;
          _tenantDocumentStatusMessage = null;
          _tenantDocumentStatusProfileId = null;
          _tenantDocumentStatusIsSuccess = false;
        });
        return;
      }

      if (showErrorModal) {
        await _showStatusModal(
          title: 'Tenant Fetch Failed',
          message: message,
          isSuccess: false,
        );
      }
      return;
    }

    final tenant = _jsonMapValue(response['tenant']);
    final profiles = _jsonMapList(response['profile'])
        .map(
          (entry) => _TenantProfileData(
            profileId: _stringValue(entry['prflId']),
            displayName: _composeDisplayName(_jsonMapValue(entry['prflName'])),
            profileKind: _stringValue(entry['profileKind']),
            primaryAddress: _formatAddressDisplay(
              _jsonMapValue(entry['prflPrimaryPostalAdrss']),
            ),
            gender: _stringValue(entry['gender']),
            phoneNo: _stringValue(entry['prflPhoneNo']),
            dob: _formatDate(entry['prflDob']),
            imageBytes: _decodeBase64Bytes(_stringValue(entry['profile_pic'])),
          ),
        )
        .where((profile) => profile.profileId.isNotEmpty)
        .toList();
    final documents = _jsonMapList(tenant['document'])
        .map(
          (entry) => _TenantExistingDocument(
            profileId: _matchDocumentProfileId(
              _stringValue(entry['documentName']),
              profiles,
            ),
            documentName: _stringValue(entry['documentName']),
            documentCode: _stringValue(entry['documentCode']),
          ),
        )
        .where((document) => document.documentName.isNotEmpty)
        .toList();

    _disposeTenantDocumentDrafts();
    _tenantStartDateController.text = _formatDate(tenant['startDate']);
    _tenantEndDateController.text = _formatDate(tenant['endDate']);

    setState(() {
      _loadedTenantResponse = response;
      _tenantProfiles = profiles;
      _tenantExistingDocuments = documents;
      _tenantVerified = _boolValue(tenant['verified']);
      _tenantStatus = _stringValue(tenant['status']);
      _tenantInlineErrorMessage = null;
      if (!preserveDocumentStatus) {
        _tenantDocumentStatusMessage = null;
        _tenantDocumentStatusProfileId = null;
        _tenantDocumentStatusIsSuccess = false;
      }
    });
  }

  Future<void> _pickTenantDocument(_TenantNewDocumentDraft draft) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'],
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
        title: 'Document Upload Failed',
        message: 'The selected document could not be read.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      draft.documentBase64 = base64Encode(bytes);
      draft.fileName = selectedFile.name;
    });
  }

  void _addTenantDocument(String profileId) {
    setState(() {
      _tenantNewDocuments.add(_TenantNewDocumentDraft(profileId: profileId));
      _tenantDocumentStatusMessage = null;
      _tenantDocumentStatusProfileId = null;
      _tenantDocumentStatusIsSuccess = false;
    });
  }

  void _removeTenantExistingDocument(_TenantExistingDocument document) {
    setState(() {
      _tenantExistingDocuments = _tenantExistingDocuments
          .where((item) => item != document)
          .toList();
      _tenantDocumentStatusMessage = null;
      _tenantDocumentStatusProfileId = null;
      _tenantDocumentStatusIsSuccess = false;
    });
  }

  void _removeTenantNewDocument(_TenantNewDocumentDraft draft) {
    setState(() {
      _tenantNewDocuments.remove(draft);
      _tenantDocumentStatusMessage = null;
      _tenantDocumentStatusProfileId = null;
      _tenantDocumentStatusIsSuccess = false;
    });
    draft.dispose();
  }

  Future<void> _uploadTenantDocument(_TenantNewDocumentDraft draft) async {
    final documentName = _normalizedDocumentBaseName(
      draft.documentNameController.text,
    );
    if (documentName.isEmpty ||
        draft.documentBase64 == null ||
        draft.documentBase64!.trim().isEmpty) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message:
            'Provide a document name and choose a file before uploading it.',
        isSuccess: false,
      );
      return;
    }

    final tenant = _jsonMapValue(_loadedTenantResponse?['tenant']);
    if (_stringValue(tenant['startDate']).isEmpty &&
        _tenantStartDateController.text.trim().isEmpty) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: 'Start date is required before uploading a tenant document.',
        isSuccess: false,
      );
      return;
    }

    final requestBody = _buildTenantUpdateRequest(additionalDrafts: [draft]);
    if (requestBody == null) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: 'Unable to prepare the tenant update request.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      draft.uploading = true;
    });

    final response = await ApiService.updateTenantDetails(requestBody);
    if (!mounted) return;

    setState(() {
      draft.uploading = false;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['message']);
    final message = _stringValue(response['message']).isNotEmpty
        ? _stringValue(response['message'])
        : isSuccess
        ? 'The document was uploaded successfully.'
        : 'Unable to upload the document.';

    if (!isSuccess) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: message,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _tenantDocumentStatusMessage = message;
      _tenantDocumentStatusProfileId = draft.profileId;
      _tenantDocumentStatusIsSuccess = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_tenantDocumentStatusMessage == message &&
          _tenantDocumentStatusProfileId == draft.profileId) {
        setState(() {
          _tenantDocumentStatusMessage = null;
          _tenantDocumentStatusProfileId = null;
          _tenantDocumentStatusIsSuccess = false;
        });
      }
    });

    await _loadTenantManagement(
      showErrorModal: false,
      preserveDocumentStatus: true,
    );
  }

  Future<void> _downloadTenantDocument(_TenantExistingDocument document) async {
    final bytes = _decodeBase64Bytes(document.documentCode);
    if (bytes == null || bytes.isEmpty) {
      await _showStatusModal(
        title: 'Download Failed',
        message: 'The selected document is not available for download.',
        isSuccess: false,
      );
      return;
    }

    final inferredExtension = _guessExtensionFromBytes(bytes);
    final extension = _fileExtensionFromName(document.documentName).isNotEmpty
        ? _fileExtensionFromName(document.documentName)
        : inferredExtension;
    final fileName = _fileNameWithoutExtension(document.documentName).isNotEmpty
        ? _fileNameWithoutExtension(document.documentName)
        : 'tenant_document';

    try {
      await FileSaver.instance.saveFile(
        name: fileName.isEmpty ? document.documentName : fileName,
        bytes: bytes,
        fileExtension: extension,
        mimeType: _mimeTypeForExtension(extension),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${document.documentName} downloaded successfully.'),
        ),
      );
    } catch (_) {
      await _showStatusModal(
        title: 'Download Failed',
        message: 'The document could not be downloaded on this device.',
        isSuccess: false,
      );
    }
  }

  Future<void> _submitTenantManagement() async {
    final header = _buildHeaderRequest();
    if (header.values.every((value) => _stringValue(value).isEmpty)) {
      await _showStatusModal(
        title: 'Tenant Update Failed',
        message: 'Unable to find login header details for this request.',
        isSuccess: false,
      );
      return;
    }

    final flatId = _readHeaderValue(['flatNo']);
    if (flatId.isEmpty || _loadedTenantResponse == null) {
      await _showStatusModal(
        title: 'Tenant Update Failed',
        message: 'Load tenant details before trying to update them.',
        isSuccess: false,
      );
      return;
    }

    final tenant = _jsonMapValue(_loadedTenantResponse?['tenant']);
    if (_stringValue(tenant['startDate']).isEmpty &&
        _tenantStartDateController.text.trim().isEmpty) {
      await _showStatusModal(
        title: 'Tenant Update Failed',
        message: 'Start date is required before submitting tenant details.',
        isSuccess: false,
      );
      return;
    }

    for (final draft in _tenantNewDocuments) {
      final documentName = draft.documentNameController.text.trim();
      if (documentName.isEmpty ||
          draft.documentBase64 == null ||
          draft.documentBase64!.trim().isEmpty) {
        await _showStatusModal(
          title: 'Tenant Update Failed',
          message:
              'Each added document must include a document name and an uploaded file before submit.',
          isSuccess: false,
        );
        return;
      }
    }

    final requestBody = _buildTenantUpdateRequest(
      additionalDrafts: _tenantNewDocuments,
    );
    if (requestBody == null) {
      await _showStatusModal(
        title: 'Tenant Update Failed',
        message: 'Unable to prepare the tenant update request.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _updatingTenant = true;
    });

    final response = await ApiService.updateTenantDetails(requestBody);

    if (!mounted) return;

    setState(() {
      _updatingTenant = false;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Tenant Update Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['message']);
    await _showStatusModal(
      title: isSuccess ? 'Tenant Updated' : 'Tenant Update Failed',
      message: _stringValue(response['message']).isNotEmpty
          ? _stringValue(response['message'])
          : isSuccess
          ? 'Tenant details were updated successfully.'
          : 'Unable to update tenant details.',
      isSuccess: isSuccess,
    );

    if (isSuccess) {
      await _loadTenantManagement(showErrorModal: false);
    }
  }

  Future<void> _loadOwnerManagement({
    bool showErrorModal = true,
    bool preserveDocumentStatus = false,
  }) async {
    final flatId = _readHeaderValue(['flatNo']);
    if (flatId.isEmpty) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Owner Fetch Failed',
          message:
              'Unable to find the logged-in flat number required to fetch owner details.',
          isSuccess: false,
        );
      }
      return;
    }

    setState(() {
      _loadingOwner = true;
    });

    final response = await ApiService.getOwner(flatId: flatId);
    if (!mounted) return;

    setState(() {
      _loadingOwner = false;
    });

    if (response == null) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Owner Fetch Failed',
          message: 'No response was returned from the server.',
          isSuccess: false,
        );
      }
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['owner']);
    if (!isSuccess) {
      if (showErrorModal) {
        await _showStatusModal(
          title: 'Owner Fetch Failed',
          message: _stringValue(response['message']).isNotEmpty
              ? _stringValue(response['message'])
              : 'Unable to load owner details for the current flat.',
          isSuccess: false,
        );
      }
      return;
    }

    final owner = _jsonMapValue(response['owner']);
    final profiles = _jsonMapList(response['profile'])
        .map(
          (entry) => _TenantProfileData(
            profileId: _stringValue(entry['prflId']),
            displayName: _composeDisplayName(_jsonMapValue(entry['prflName'])),
            profileKind: _stringValue(entry['profileKind']),
            primaryAddress: _formatAddressDisplay(
              _jsonMapValue(entry['prflPrimaryPostalAdrss']),
            ),
            gender: _stringValue(entry['gender']),
            phoneNo: _stringValue(entry['prflPhoneNo']),
            dob: _formatDate(entry['prflDob']),
            imageBytes: _decodeBase64Bytes(_stringValue(entry['profile_pic'])),
          ),
        )
        .where((profile) => profile.profileId.isNotEmpty)
        .toList();
    final documents = _jsonMapList(owner['document'])
        .map(
          (entry) => _TenantExistingDocument(
            profileId: _matchDocumentProfileId(
              _stringValue(entry['documentName']),
              profiles,
            ),
            documentName: _stringValue(entry['documentName']),
            documentCode: _stringValue(entry['documentCode']),
          ),
        )
        .where((document) => document.documentName.isNotEmpty)
        .toList();

    _disposeOwnerDocumentDrafts();
    _ownerStartDateController.text = _formatDate(owner['startDate']);
    _ownerEndDateController.text = _formatDate(owner['endDate']);

    setState(() {
      _loadedOwnerResponse = response;
      _ownerProfiles = profiles;
      _ownerExistingDocuments = documents;
      _ownerVerified = _boolValue(owner['verified']);
      _ownerStatus = _stringValue(owner['status']);
      if (!preserveDocumentStatus) {
        _ownerDocumentStatusMessage = null;
        _ownerDocumentStatusProfileId = null;
        _ownerDocumentStatusIsSuccess = false;
      }
    });
  }

  Future<void> _pickOwnerDocument(_TenantNewDocumentDraft draft) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'],
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
        title: 'Document Upload Failed',
        message: 'The selected document could not be read.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      draft.documentBase64 = base64Encode(bytes);
      draft.fileName = selectedFile.name;
    });
  }

  void _addOwnerDocument(String profileId) {
    setState(() {
      _ownerNewDocuments.add(_TenantNewDocumentDraft(profileId: profileId));
      _ownerDocumentStatusMessage = null;
      _ownerDocumentStatusProfileId = null;
      _ownerDocumentStatusIsSuccess = false;
    });
  }

  void _removeOwnerExistingDocument(_TenantExistingDocument document) {
    setState(() {
      _ownerExistingDocuments = _ownerExistingDocuments
          .where((item) => item != document)
          .toList();
      _ownerDocumentStatusMessage = null;
      _ownerDocumentStatusProfileId = null;
      _ownerDocumentStatusIsSuccess = false;
    });
  }

  void _removeOwnerNewDocument(_TenantNewDocumentDraft draft) {
    setState(() {
      _ownerNewDocuments.remove(draft);
      _ownerDocumentStatusMessage = null;
      _ownerDocumentStatusProfileId = null;
      _ownerDocumentStatusIsSuccess = false;
    });
    draft.dispose();
  }

  Future<void> _uploadOwnerDocument(_TenantNewDocumentDraft draft) async {
    final documentName = _normalizedDocumentBaseName(
      draft.documentNameController.text,
    );
    if (documentName.isEmpty ||
        draft.documentBase64 == null ||
        draft.documentBase64!.trim().isEmpty) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message:
            'Provide a document name and choose a file before uploading it.',
        isSuccess: false,
      );
      return;
    }

    final owner = _jsonMapValue(_loadedOwnerResponse?['owner']);
    if (_stringValue(owner['startDate']).isEmpty &&
        _ownerStartDateController.text.trim().isEmpty) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: 'Start date is required before uploading an owner document.',
        isSuccess: false,
      );
      return;
    }

    final requestBody = _buildOwnerUpdateRequest(additionalDrafts: [draft]);
    if (requestBody == null) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: 'Unable to prepare the owner update request.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      draft.uploading = true;
    });

    final response = await ApiService.updateOwnerDetails(requestBody);
    if (!mounted) return;

    setState(() {
      draft.uploading = false;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['message']);
    final message = _stringValue(response['message']).isNotEmpty
        ? _stringValue(response['message'])
        : isSuccess
        ? 'The document was uploaded successfully.'
        : 'Unable to upload the document.';

    if (!isSuccess) {
      await _showStatusModal(
        title: 'Document Upload Failed',
        message: message,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _ownerDocumentStatusMessage = message;
      _ownerDocumentStatusProfileId = draft.profileId;
      _ownerDocumentStatusIsSuccess = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_ownerDocumentStatusMessage == message &&
          _ownerDocumentStatusProfileId == draft.profileId) {
        setState(() {
          _ownerDocumentStatusMessage = null;
          _ownerDocumentStatusProfileId = null;
          _ownerDocumentStatusIsSuccess = false;
        });
      }
    });

    await _loadOwnerManagement(
      showErrorModal: false,
      preserveDocumentStatus: true,
    );
  }

  Future<void> _downloadOwnerDocument(_TenantExistingDocument document) async {
    final bytes = _decodeBase64Bytes(document.documentCode);
    if (bytes == null || bytes.isEmpty) {
      await _showStatusModal(
        title: 'Download Failed',
        message: 'The selected document is not available for download.',
        isSuccess: false,
      );
      return;
    }

    final inferredExtension = _guessExtensionFromBytes(bytes);
    final extension = _fileExtensionFromName(document.documentName).isNotEmpty
        ? _fileExtensionFromName(document.documentName)
        : inferredExtension;
    final fileName = _fileNameWithoutExtension(document.documentName).isNotEmpty
        ? _fileNameWithoutExtension(document.documentName)
        : 'owner_document';

    try {
      await FileSaver.instance.saveFile(
        name: fileName.isEmpty ? document.documentName : fileName,
        bytes: bytes,
        fileExtension: extension,
        mimeType: _mimeTypeForExtension(extension),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${document.documentName} downloaded successfully.'),
        ),
      );
    } catch (_) {
      await _showStatusModal(
        title: 'Download Failed',
        message: 'The document could not be downloaded on this device.',
        isSuccess: false,
      );
    }
  }

  Future<void> _submitOwnerManagement() async {
    final header = _buildHeaderRequest();
    if (header.values.every((value) => _stringValue(value).isEmpty)) {
      await _showStatusModal(
        title: 'Owner Update Failed',
        message: 'Unable to find login header details for this request.',
        isSuccess: false,
      );
      return;
    }

    final flatId = _readHeaderValue(['flatNo']);
    if (flatId.isEmpty || _loadedOwnerResponse == null) {
      await _showStatusModal(
        title: 'Owner Update Failed',
        message: 'Load owner details before trying to update them.',
        isSuccess: false,
      );
      return;
    }

    final owner = _jsonMapValue(_loadedOwnerResponse?['owner']);
    if (_stringValue(owner['startDate']).isEmpty &&
        _ownerStartDateController.text.trim().isEmpty) {
      await _showStatusModal(
        title: 'Owner Update Failed',
        message: 'Start date is required before submitting owner details.',
        isSuccess: false,
      );
      return;
    }

    for (final draft in _ownerNewDocuments) {
      final documentName = draft.documentNameController.text.trim();
      if (documentName.isEmpty ||
          draft.documentBase64 == null ||
          draft.documentBase64!.trim().isEmpty) {
        await _showStatusModal(
          title: 'Owner Update Failed',
          message:
              'Each added document must include a document name and an uploaded file before submit.',
          isSuccess: false,
        );
        return;
      }
    }

    final requestBody = _buildOwnerUpdateRequest(
      additionalDrafts: _ownerNewDocuments,
    );
    if (requestBody == null) {
      await _showStatusModal(
        title: 'Owner Update Failed',
        message: 'Unable to prepare the owner update request.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _updatingOwner = true;
    });

    final response = await ApiService.updateOwnerDetails(requestBody);

    if (!mounted) return;

    setState(() {
      _updatingOwner = false;
    });

    if (response == null) {
      await _showStatusModal(
        title: 'Owner Update Failed',
        message: 'No response was returned from the server.',
        isSuccess: false,
      );
      return;
    }

    final isSuccess = _isSuccessResponse(response, idKeys: const ['message']);
    await _showStatusModal(
      title: isSuccess ? 'Owner Updated' : 'Owner Update Failed',
      message: _stringValue(response['message']).isNotEmpty
          ? _stringValue(response['message'])
          : isSuccess
          ? 'Owner details were updated successfully.'
          : 'Unable to update owner details.',
      isSuccess: isSuccess,
    );

    if (isSuccess) {
      await _loadOwnerManagement(showErrorModal: false);
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
      _validatingExistingProfile = false;
      _existingProfileTypeFound = false;
      _existingProfileSelectionError = null;
      _existingProfileAction = null;
      _createHasOtherAddress = false;
      _addressType = 'RESIDENTIAL';
      _primaryAddressType = 'RESIDENTIAL';
    });
    _ProfileManagementDraft.createProfile.clear();
    _ProfileManagementDraft.createProfileType = null;
    _ProfileManagementDraft.createProfilePosition = null;
    _ProfileManagementDraft.createProfileKind = null;
    _ProfileManagementDraft.createGender = null;
    _ProfileManagementDraft.createExistingProfileAction = null;
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
      case _ProfileManagementSection.tenantManagement:
        return 'Tenant Management';
      case _ProfileManagementSection.ownerManagement:
        return 'Owner Management';
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
      case _ProfileManagementSection.tenantManagement:
        return 'Fetch tenant details for the logged-in flat, review linked profiles and documents, and submit tenant verification updates.';
      case _ProfileManagementSection.ownerManagement:
        return 'Fetch owner details for the logged-in flat, review linked profiles and documents, and submit owner verification updates.';
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
          onPickProfileDob: _pickCreateProfileDob,
          hasOtherAddress: _createHasOtherAddress,
          addressType: _addressType,
          primaryAddressType: _primaryAddressType,
          validatingExistingProfile: _validatingExistingProfile,
          existingProfileTypeFound: _existingProfileTypeFound,
          existingProfileSelectionError: _existingProfileSelectionError,
          existingProfileAction: _existingProfileAction,
          onProfileTypeChanged: (value) {
            setState(() {
              _profileType = value;
              if (value != 'STAFF') {
                _profilePosition = null;
                _ProfileManagementDraft.createProfilePosition = null;
              }
              _ProfileManagementDraft.createProfileType = value;
            });
            _scheduleCreateProfileValidation();
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
          onExistingProfileActionChanged: (value) {
            setState(() {
              _existingProfileAction = value;
              _existingProfileSelectionError = null;
              _ProfileManagementDraft.createExistingProfileAction = value;
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
      case _ProfileManagementSection.tenantManagement:
        return _TenantManagementTab(
          entityLabel: 'Tenant',
          response: _loadedTenantResponse,
          inlineErrorMessage: _tenantInlineErrorMessage,
          profiles: _tenantProfiles,
          existingDocuments: _tenantExistingDocuments,
          newDocuments: _tenantNewDocuments,
          loading: _loadingTenant,
          submitting: _updatingTenant,
          validatingExistingTenant: _validatingExistingTenant,
          verified: _tenantVerified,
          tenantStatus: _tenantStatus,
          existingTenantTypeFound: _existingTenantTypeFound,
          existingTenantSelectionError: _existingTenantSelectionError,
          existingTenantAction: _existingTenantAction,
          startDateController: _tenantStartDateController,
          endDateController: _tenantEndDateController,
          onVerifiedChanged: (value) {
            setState(() {
              _tenantVerified = value;
            });
          },
          onExistingTenantActionChanged: (value) {
            setState(() {
              _existingTenantAction = value;
              _existingTenantSelectionError = null;
            });
          },
          onPickStartDate: () => _pickTenantDate(
            controller: _tenantStartDateController,
            helpText: 'Select Start Date',
          ),
          onPickEndDate: () => _pickTenantDate(
            controller: _tenantEndDateController,
            helpText: 'Select End Date',
          ),
          onRefresh: _loadTenantManagement,
          onAddTenant: _handleAddTenantPressed,
          onProceedAddTenant: _proceedAddTenant,
          onDismissExistingTenantPanel: _dismissExistingTenantPanel,
          onSubmit: _submitTenantManagement,
          onAddDocument: _addTenantDocument,
          onRemoveExistingDocument: _removeTenantExistingDocument,
          onRemoveNewDocument: _removeTenantNewDocument,
          onPickDocument: _pickTenantDocument,
          onUploadDocument: _uploadTenantDocument,
          onDownloadDocument: _downloadTenantDocument,
          onRemoveProfile: _removeTenantProfile,
          removingProfileId: _removingTenantProfileId,
          documentStatusMessage: _tenantDocumentStatusMessage,
          documentStatusProfileId: _tenantDocumentStatusProfileId,
          documentStatusIsSuccess: _tenantDocumentStatusIsSuccess,
          mobile: mobile,
        );
      case _ProfileManagementSection.ownerManagement:
        return _TenantManagementTab(
          entityLabel: 'Owner',
          response: _loadedOwnerResponse,
          inlineErrorMessage: null,
          profiles: _ownerProfiles,
          existingDocuments: _ownerExistingDocuments,
          newDocuments: _ownerNewDocuments,
          loading: _loadingOwner,
          submitting: _updatingOwner,
          validatingExistingTenant: _validatingExistingOwner,
          verified: _ownerVerified,
          tenantStatus: _ownerStatus,
          existingTenantTypeFound: _existingOwnerTypeFound,
          existingTenantSelectionError: _existingOwnerSelectionError,
          existingTenantAction: _existingOwnerAction,
          startDateController: _ownerStartDateController,
          endDateController: _ownerEndDateController,
          onVerifiedChanged: (value) {
            setState(() {
              _ownerVerified = value;
            });
          },
          onExistingTenantActionChanged: (value) {
            setState(() {
              _existingOwnerAction = value;
              _existingOwnerSelectionError = null;
            });
          },
          onPickStartDate: () => _pickTenantDate(
            controller: _ownerStartDateController,
            helpText: 'Select Start Date',
          ),
          onPickEndDate: () => _pickTenantDate(
            controller: _ownerEndDateController,
            helpText: 'Select End Date',
          ),
          onRefresh: _loadOwnerManagement,
          onAddTenant: _handleAddOwnerPressed,
          onProceedAddTenant: _proceedAddOwner,
          onDismissExistingTenantPanel: _dismissExistingOwnerPanel,
          onSubmit: _submitOwnerManagement,
          onAddDocument: _addOwnerDocument,
          onRemoveExistingDocument: _removeOwnerExistingDocument,
          onRemoveNewDocument: _removeOwnerNewDocument,
          onPickDocument: _pickOwnerDocument,
          onUploadDocument: _uploadOwnerDocument,
          onDownloadDocument: _downloadOwnerDocument,
          onRemoveProfile: _removeOwnerProfile,
          removingProfileId: _removingOwnerProfileId,
          documentStatusMessage: _ownerDocumentStatusMessage,
          documentStatusProfileId: _ownerDocumentStatusProfileId,
          documentStatusIsSuccess: _ownerDocumentStatusIsSuccess,
          mobile: mobile,
        );
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
                              onTap: () => _openSection(
                                _ProfileManagementSection.tenantManagement,
                              ),
                            ),
                            _ProfileActionCard(
                              title: 'Owner Management',
                              icon: Icons.home_work_outlined,
                              selected: false,
                              onTap: () => _openSection(
                                _ProfileManagementSection.ownerManagement,
                              ),
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
  tenantManagement,
  ownerManagement,
}

String _profileTypeDisplayLabel(String? value, {String fallback = 'Profile'}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return fallback;
  }

  return trimmed
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

enum _CreateProfileExistingAction { createNewDeleteExisting, addToExisting }

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
    required this.onPickProfileDob,
    required this.hasOtherAddress,
    required this.addressType,
    required this.primaryAddressType,
    required this.validatingExistingProfile,
    required this.existingProfileTypeFound,
    required this.existingProfileSelectionError,
    required this.existingProfileAction,
    required this.onProfileTypeChanged,
    required this.onProfilePositionChanged,
    required this.onProfileKindChanged,
    required this.onGenderChanged,
    required this.onExistingProfileActionChanged,
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
  final VoidCallback onPickProfileDob;
  final bool hasOtherAddress;
  final String addressType;
  final String primaryAddressType;
  final bool validatingExistingProfile;
  final bool existingProfileTypeFound;
  final String? existingProfileSelectionError;
  final _CreateProfileExistingAction? existingProfileAction;
  final ValueChanged<String?> onProfileTypeChanged;
  final ValueChanged<String?> onProfilePositionChanged;
  final ValueChanged<String?> onProfileKindChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<_CreateProfileExistingAction?>
  onExistingProfileActionChanged;
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
    final profileTypeLabel = _profileTypeDisplayLabel(
      profileType,
      fallback: 'Profile',
    );

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
                suffixIcon: IconButton(
                  onPressed: onPickProfileDob,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: _ProfileManagementPageState._brandColor,
                  ),
                  tooltip: 'Choose date',
                ),
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
          if (validatingExistingProfile || existingProfileTypeFound) ...[
            SizedBox(height: 16),
            _ExistingProfileActionPanel(
              profileTypeLabel: profileTypeLabel,
              validating: validatingExistingProfile,
              found: existingProfileTypeFound,
              selectionError: existingProfileSelectionError,
              selectedAction: existingProfileAction,
              onChanged: onExistingProfileActionChanged,
            ),
          ],
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

  String _formatDisplayTimestamp(dynamic value) {
    final raw = _textValue(value);
    if (raw == 'Not available') {
      return raw;
    }

    final sanitized = raw.trim();
    if (sanitized.isEmpty) {
      return 'Not available';
    }

    final parsed = DateTime.tryParse(sanitized);
    if (parsed == null) {
      return sanitized;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
    final primaryAddress = _mapValue(profile!['primaryAddress']);
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
          title: 'Audit Details',
          icon: Icons.history_toggle_off_outlined,
          child: _ProfileSummaryGrid(
            mobile: mobile,
            children: [
              _ProfileSummaryTile(
                label: 'Created By',
                value: _textValue(profile!['creatUsrName']),
              ),
              _ProfileSummaryTile(
                label: 'Created On',
                value: _formatDisplayTimestamp(profile!['creatTsin']),
              ),
              _ProfileSummaryTile(
                label: 'Last Updated By',
                value: _textValue(profile!['lstUpdtUsrName']),
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

class _TenantProfileData {
  const _TenantProfileData({
    required this.profileId,
    required this.displayName,
    required this.profileKind,
    required this.primaryAddress,
    required this.gender,
    required this.phoneNo,
    required this.dob,
    this.imageBytes,
  });

  final String profileId;
  final String displayName;
  final String profileKind;
  final String primaryAddress;
  final String gender;
  final String phoneNo;
  final String dob;
  final Uint8List? imageBytes;
}

class _TenantExistingDocument {
  const _TenantExistingDocument({
    required this.profileId,
    required this.documentName,
    required this.documentCode,
  });

  final String profileId;
  final String documentName;
  final String documentCode;
}

class _TenantNewDocumentDraft {
  _TenantNewDocumentDraft({required this.profileId});

  final String profileId;
  final TextEditingController documentNameController = TextEditingController();
  String? documentBase64;
  String? fileName;
  bool uploading = false;

  void dispose() {
    documentNameController.dispose();
  }
}

class _ExistingProfileActionPanel extends StatelessWidget {
  const _ExistingProfileActionPanel({
    required this.profileTypeLabel,
    required this.validating,
    required this.found,
    required this.selectionError,
    required this.selectedAction,
    required this.onChanged,
    this.title,
    this.actionLabel,
    this.onAction,
    this.onTapOutside,
  });

  final String profileTypeLabel;
  final bool validating;
  final bool found;
  final String? selectionError;
  final _CreateProfileExistingAction? selectedAction;
  final ValueChanged<_CreateProfileExistingAction?> onChanged;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: onTapOutside == null ? null : (event) => onTapOutside!(),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: found ? Color(0xFFFFF6E8) : Color(0xFFF5F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: found ? Color(0xFFFFD6A0) : Color(0xFFDCE5EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              validating
                  ? 'Checking existing $profileTypeLabel for this flat...'
                  : title ?? 'Existing $profileTypeLabel already exists.',
              style: TextStyle(
                color: Color(0xFF124B45),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (validating) ...[
              SizedBox(height: 10),
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _ProfileManagementPageState._brandColor,
                ),
              ),
            ] else ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<_CreateProfileExistingAction>(
                        value: _CreateProfileExistingAction
                            .createNewDeleteExisting,
                        groupValue: selectedAction,
                        onChanged: onChanged,
                        activeColor: _ProfileManagementPageState._brandColor,
                      ),
                      Flexible(
                        child: Text(
                          'Create new $profileTypeLabel and delete the existing',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<_CreateProfileExistingAction>(
                        value: _CreateProfileExistingAction.addToExisting,
                        groupValue: selectedAction,
                        onChanged: onChanged,
                        activeColor: _ProfileManagementPageState._brandColor,
                      ),
                      Flexible(
                        child: Text('Add to existing $profileTypeLabel'),
                      ),
                    ],
                  ),
                ],
              ),
              if (selectionError != null) ...[
                SizedBox(height: 8),
                Text(
                  selectionError!,
                  style: TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (onAction != null) ...[
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFF0F8F82),
                    ),
                    child: Text(actionLabel ?? 'Add'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TenantSearchResult {
  const _TenantSearchResult({
    required this.displayName,
    required this.profileId,
    required this.profilePicUrl,
    this.profilePicBytes,
  });

  final String displayName;
  final String profileId;
  final String profilePicUrl;
  final Uint8List? profilePicBytes;
}

class _TenantManagementTab extends StatelessWidget {
  const _TenantManagementTab({
    required this.entityLabel,
    required this.response,
    required this.inlineErrorMessage,
    required this.profiles,
    required this.existingDocuments,
    required this.newDocuments,
    required this.loading,
    required this.submitting,
    required this.validatingExistingTenant,
    required this.verified,
    required this.tenantStatus,
    required this.existingTenantTypeFound,
    required this.existingTenantSelectionError,
    required this.existingTenantAction,
    required this.startDateController,
    required this.endDateController,
    required this.onVerifiedChanged,
    required this.onExistingTenantActionChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onRefresh,
    required this.onAddTenant,
    required this.onProceedAddTenant,
    required this.onDismissExistingTenantPanel,
    required this.onSubmit,
    required this.onAddDocument,
    required this.onRemoveExistingDocument,
    required this.onRemoveNewDocument,
    required this.onPickDocument,
    required this.onUploadDocument,
    required this.onDownloadDocument,
    required this.onRemoveProfile,
    required this.removingProfileId,
    required this.documentStatusMessage,
    required this.documentStatusProfileId,
    required this.documentStatusIsSuccess,
    required this.mobile,
  });

  final String entityLabel;
  final Map<String, dynamic>? response;
  final String? inlineErrorMessage;
  final List<_TenantProfileData> profiles;
  final List<_TenantExistingDocument> existingDocuments;
  final List<_TenantNewDocumentDraft> newDocuments;
  final bool loading;
  final bool submitting;
  final bool validatingExistingTenant;
  final bool verified;
  final String tenantStatus;
  final bool existingTenantTypeFound;
  final String? existingTenantSelectionError;
  final _CreateProfileExistingAction? existingTenantAction;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final ValueChanged<bool> onVerifiedChanged;
  final ValueChanged<_CreateProfileExistingAction?>
  onExistingTenantActionChanged;
  final Future<void> Function() onPickStartDate;
  final Future<void> Function() onPickEndDate;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onAddTenant;
  final Future<void> Function() onProceedAddTenant;
  final VoidCallback onDismissExistingTenantPanel;
  final Future<void> Function() onSubmit;
  final ValueChanged<String> onAddDocument;
  final ValueChanged<_TenantExistingDocument> onRemoveExistingDocument;
  final ValueChanged<_TenantNewDocumentDraft> onRemoveNewDocument;
  final Future<void> Function(_TenantNewDocumentDraft draft) onPickDocument;
  final Future<void> Function(_TenantNewDocumentDraft draft) onUploadDocument;
  final Future<void> Function(_TenantExistingDocument document)
  onDownloadDocument;
  final Future<void> Function(_TenantProfileData profile) onRemoveProfile;
  final String? removingProfileId;
  final String? documentStatusMessage;
  final String? documentStatusProfileId;
  final bool documentStatusIsSuccess;
  final bool mobile;

  String _textValue(dynamic value, {String fallback = '-'}) {
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

  @override
  Widget build(BuildContext context) {
    final entityLower = entityLabel.toLowerCase();

    if (response == null && loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: CircularProgressIndicator(color: Color(0xFF0F8F82)),
        ),
      );
    }

    if (response == null) {
      final hasInlineError =
          inlineErrorMessage != null && inlineErrorMessage!.trim().isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasInlineError ? Color(0xFFFFF1F1) : Color(0xFFF4FBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasInlineError ? Color(0xFFE58F8F) : Color(0xFFD5EBE7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasInlineError
                      ? inlineErrorMessage!
                      : 'No $entityLower data has been fetched yet.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasInlineError
                        ? Color(0xFFB42318)
                        : Color(0xFF124B45),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  hasInlineError
                      ? 'No $entityLower profile is currently linked to the logged-in flat. You can add one below.'
                      : 'Use the logged-in header flat number to load $entityLower profiles and documents.',
                  style: TextStyle(
                    color: hasInlineError ? Color(0xFFB42318) : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: loading ? null : onRefresh,
                  icon: Icon(Icons.refresh),
                  label: Text('Fetch $entityLabel Details'),
                ),
                if (entityLabel == 'Tenant')
                  FilledButton.icon(
                    onPressed: loading || validatingExistingTenant
                        ? null
                        : onAddTenant,
                    icon: validatingExistingTenant
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.person_add_alt_1),
                    label: Text('Add Tenant'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFF0F8F82),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final genericHeader = _mapValue(response!['genericHeader']);
    final profileRecord = _mapValue(response![entityLower]);
    final apartmentName = _textValue(
      genericHeader['apartmentName'],
      fallback: _textValue(ApiService.userHeader?['apartmentName']),
    );
    final profileTypeLabel = '$entityLower profile';
    final startDateLocked = startDateController.text.trim().isNotEmpty;
    final endDateLocked = endDateController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading) ...[
          LinearProgressIndicator(color: Color(0xFF0F8F82)),
          SizedBox(height: 18),
        ],
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFFFD89C)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.apartment_outlined, color: Color(0xFF9A5418)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$entityLabel details are fetched using the logged-in flat number. Profile fields stay read-only, while verification, missing dates, and documents can be updated before submit.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A3F0D),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: loading || submitting || validatingExistingTenant
                    ? null
                    : onRefresh,
                icon: Icon(Icons.refresh),
                label: Text('Refresh $entityLabel Details'),
              ),
              FilledButton.icon(
                onPressed:
                    loading ||
                        submitting ||
                        validatingExistingTenant ||
                        existingTenantTypeFound
                    ? null
                    : onAddTenant,
                icon: validatingExistingTenant
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.person_add_alt_1),
                label: Text('Add $entityLabel'),
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF0F8F82),
                ),
              ),
            ],
          ),
        ),
        if (validatingExistingTenant || existingTenantTypeFound) ...[
          SizedBox(height: 16),
          _ExistingProfileActionPanel(
            profileTypeLabel: profileTypeLabel,
            validating: validatingExistingTenant,
            found: existingTenantTypeFound,
            title: '$entityLabel Exists. Please Select From Below Operation',
            selectionError: existingTenantSelectionError,
            selectedAction: existingTenantAction,
            onChanged: onExistingTenantActionChanged,
            actionLabel: 'Add',
            onAction: () {
              onProceedAddTenant();
            },
            onTapOutside: onDismissExistingTenantPanel,
          ),
        ],
        SizedBox(height: 18),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(
              label: 'Apartment Name',
              initialValue: apartmentName,
              readOnly: true,
            ),
            _ProfileInputField(
              label: 'Flat No.',
              initialValue: _textValue(profileRecord['flatNo']),
              readOnly: true,
            ),
            _ProfileInputField(
              label: 'Status',
              initialValue: tenantStatus.isEmpty
                  ? _textValue(profileRecord['status'])
                  : tenantStatus,
              readOnly: true,
            ),
          ],
        ),
        SizedBox(height: 16),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(
              label: startDateLocked ? 'Start Date' : 'Start Date *',
              controller: startDateController,
              readOnly: startDateLocked,
              hintText: startDateLocked ? null : 'YYYY-MM-DD',
              suffixIcon: startDateLocked
                  ? null
                  : IconButton(
                      onPressed: onPickStartDate,
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF0F8F82),
                      ),
                      tooltip: 'Choose start date',
                    ),
            ),
            _ProfileInputField(
              label: 'End Date',
              controller: endDateController,
              readOnly: endDateLocked,
              hintText: endDateLocked ? null : 'YYYY-MM-DD',
              suffixIcon: endDateLocked
                  ? null
                  : IconButton(
                      onPressed: onPickEndDate,
                      icon: Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF0F8F82),
                      ),
                      tooltip: 'Choose end date',
                    ),
            ),
          ],
        ),
        SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: Color(0xFF0F8F82),
          checkColor: Colors.white,
          value: verified,
          onChanged: submitting
              ? null
              : (value) => onVerifiedChanged(value ?? false),
          title: const Text('Verified'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
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
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFF0F8F82),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            label: Text(
              submitting ? 'Submitting...' : 'Submit $entityLabel Details',
            ),
          ),
        ),
        SizedBox(height: 18),
        Text(
          '$entityLabel Profiles',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12),
        if (profiles.isEmpty)
          Text(
            'No $entityLower profiles were returned for this flat.',
            style: TextStyle(color: Colors.black54),
          )
        else
          _TenantProfilesSlider(
            entityLabel: entityLabel,
            profiles: profiles,
            existingDocuments: existingDocuments,
            newDocuments: newDocuments,
            onAddDocument: onAddDocument,
            onRemoveExistingDocument: onRemoveExistingDocument,
            onRemoveNewDocument: onRemoveNewDocument,
            onPickDocument: onPickDocument,
            onUploadDocument: onUploadDocument,
            onDownloadDocument: onDownloadDocument,
            onRemoveProfile: onRemoveProfile,
            removingProfileId: removingProfileId,
            documentStatusMessage: documentStatusMessage,
            documentStatusProfileId: documentStatusProfileId,
            documentStatusIsSuccess: documentStatusIsSuccess,
            mobile: mobile,
          ),
      ],
    );
  }
}

class _TenantProfilePanel extends StatelessWidget {
  const _TenantProfilePanel({
    required this.entityLabel,
    required this.profile,
    required this.existingDocuments,
    required this.newDocuments,
    required this.onAddDocument,
    required this.onRemoveExistingDocument,
    required this.onRemoveNewDocument,
    required this.onPickDocument,
    required this.onUploadDocument,
    required this.onDownloadDocument,
    required this.documentStatusMessage,
    required this.documentStatusProfileId,
    required this.documentStatusIsSuccess,
    required this.mobile,
  });

  final String entityLabel;
  final _TenantProfileData profile;
  final List<_TenantExistingDocument> existingDocuments;
  final List<_TenantNewDocumentDraft> newDocuments;
  final VoidCallback onAddDocument;
  final ValueChanged<_TenantExistingDocument> onRemoveExistingDocument;
  final ValueChanged<_TenantNewDocumentDraft> onRemoveNewDocument;
  final Future<void> Function(_TenantNewDocumentDraft draft) onPickDocument;
  final Future<void> Function(_TenantNewDocumentDraft draft) onUploadDocument;
  final Future<void> Function(_TenantExistingDocument document)
  onDownloadDocument;
  final String? documentStatusMessage;
  final String? documentStatusProfileId;
  final bool documentStatusIsSuccess;
  final bool mobile;

  String _displayValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _visibleDocumentName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '-';
    }

    final underscoreIndex = trimmed.indexOf('_');
    if (underscoreIndex <= 0 || underscoreIndex == trimmed.length - 1) {
      return trimmed;
    }

    return trimmed.substring(underscoreIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFDCEBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TenantProfileAvatar(
                name: profile.displayName.isEmpty
                    ? profile.profileId
                    : profile.displayName,
                imageBytes: profile.imageBytes,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName.isEmpty
                          ? '$entityLabel Profile'
                          : profile.displayName,
                      style: TextStyle(
                        color: Color(0xFF124B45),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Profile ID: ${profile.profileId}',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Profile Name',
                initialValue: _displayValue(profile.displayName),
                readOnly: true,
                maxLines: 2,
              ),
              _ProfileInputField(
                label: 'Profile Kind',
                initialValue: _displayValue(profile.profileKind),
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
                initialValue: _displayValue(profile.gender),
                readOnly: true,
              ),
              _ProfileInputField(
                label: 'Phone Number',
                initialValue: _displayValue(profile.phoneNo),
                readOnly: true,
              ),
            ],
          ),
          SizedBox(height: 16),
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Date of Birth',
                initialValue: _displayValue(profile.dob),
                readOnly: true,
              ),
            ],
          ),
          SizedBox(height: 16),
          _TenantInfoBlock(
            label: 'Primary Postal Address',
            value: _displayValue(profile.primaryAddress),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Documents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddDocument,
                icon: Icon(Icons.add),
                label: Text('Add Document'),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (documentStatusMessage != null &&
              documentStatusMessage!.trim().isNotEmpty &&
              documentStatusProfileId == profile.profileId) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: documentStatusIsSuccess
                    ? Color(0xFFEAF7F4)
                    : Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: documentStatusIsSuccess
                      ? Color(0xFFB8E0D7)
                      : Color(0xFFF4C7C3),
                ),
              ),
              child: Text(
                documentStatusMessage!,
                style: TextStyle(
                  color: documentStatusIsSuccess
                      ? Color(0xFF124B45)
                      : Color(0xFF8B1E1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 12),
          ],
          if (existingDocuments.isEmpty && newDocuments.isEmpty)
            Text(
              'No documents available for this profile.',
              style: TextStyle(color: Colors.black54),
            ),
          for (final document in existingDocuments) ...[
            _TenantExistingDocumentTile(
              document: document,
              visibleName: _visibleDocumentName(document.documentName),
              onDownload: () => onDownloadDocument(document),
              onRemove: () => onRemoveExistingDocument(document),
            ),
            SizedBox(height: 12),
          ],
          for (final draft in newDocuments) ...[
            _TenantNewDocumentTile(
              draft: draft,
              onChooseFile: () => onPickDocument(draft),
              onUpload: () => onUploadDocument(draft),
              onRemove: () => onRemoveNewDocument(draft),
              mobile: mobile,
            ),
            SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TenantProfilesSlider extends StatefulWidget {
  const _TenantProfilesSlider({
    required this.entityLabel,
    required this.profiles,
    required this.existingDocuments,
    required this.newDocuments,
    required this.onAddDocument,
    required this.onRemoveExistingDocument,
    required this.onRemoveNewDocument,
    required this.onPickDocument,
    required this.onUploadDocument,
    required this.onDownloadDocument,
    required this.onRemoveProfile,
    required this.removingProfileId,
    required this.documentStatusMessage,
    required this.documentStatusProfileId,
    required this.documentStatusIsSuccess,
    required this.mobile,
  });

  final String entityLabel;
  final List<_TenantProfileData> profiles;
  final List<_TenantExistingDocument> existingDocuments;
  final List<_TenantNewDocumentDraft> newDocuments;
  final ValueChanged<String> onAddDocument;
  final ValueChanged<_TenantExistingDocument> onRemoveExistingDocument;
  final ValueChanged<_TenantNewDocumentDraft> onRemoveNewDocument;
  final Future<void> Function(_TenantNewDocumentDraft draft) onPickDocument;
  final Future<void> Function(_TenantNewDocumentDraft draft) onUploadDocument;
  final Future<void> Function(_TenantExistingDocument document)
  onDownloadDocument;
  final Future<void> Function(_TenantProfileData profile) onRemoveProfile;
  final String? removingProfileId;
  final String? documentStatusMessage;
  final String? documentStatusProfileId;
  final bool documentStatusIsSuccess;
  final bool mobile;

  @override
  State<_TenantProfilesSlider> createState() => _TenantProfilesSliderState();
}

class _TenantProfilesSliderState extends State<_TenantProfilesSlider> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant _TenantProfilesSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.profiles.length) {
      _selectedIndex = widget.profiles.isEmpty ? 0 : widget.profiles.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProfile = widget.profiles[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < widget.profiles.length; index++) ...[
                _TenantSliderTab(
                  entityLabel: widget.entityLabel,
                  profile: widget.profiles[index],
                  selected: index == _selectedIndex,
                  showRemoveControl:
                      widget.entityLabel != 'Owner' ||
                      widget.profiles.length > 1,
                  removing:
                      widget.removingProfileId ==
                      widget.profiles[index].profileId,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  onRemove: () =>
                      widget.onRemoveProfile(widget.profiles[index]),
                ),
                if (index != widget.profiles.length - 1) SizedBox(width: 12),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        _TenantProfilePanel(
          entityLabel: widget.entityLabel,
          profile: selectedProfile,
          existingDocuments: widget.existingDocuments
              .where(
                (document) => document.profileId == selectedProfile.profileId,
              )
              .toList(),
          newDocuments: widget.newDocuments
              .where(
                (document) => document.profileId == selectedProfile.profileId,
              )
              .toList(),
          onAddDocument: () => widget.onAddDocument(selectedProfile.profileId),
          onRemoveExistingDocument: widget.onRemoveExistingDocument,
          onRemoveNewDocument: widget.onRemoveNewDocument,
          onPickDocument: widget.onPickDocument,
          onUploadDocument: widget.onUploadDocument,
          onDownloadDocument: widget.onDownloadDocument,
          documentStatusMessage: widget.documentStatusMessage,
          documentStatusProfileId: widget.documentStatusProfileId,
          documentStatusIsSuccess: widget.documentStatusIsSuccess,
          mobile: widget.mobile,
        ),
      ],
    );
  }
}

class _TenantSliderTab extends StatefulWidget {
  const _TenantSliderTab({
    required this.entityLabel,
    required this.profile,
    required this.selected,
    required this.showRemoveControl,
    required this.removing,
    required this.onTap,
    required this.onRemove,
  });

  final String entityLabel;
  final _TenantProfileData profile;
  final bool selected;
  final bool showRemoveControl;
  final bool removing;
  final VoidCallback onTap;
  final Future<void> Function() onRemove;

  @override
  State<_TenantSliderTab> createState() => _TenantSliderTabState();
}

class _TenantSliderTabState extends State<_TenantSliderTab> {
  bool _hoveringDelete = false;

  @override
  Widget build(BuildContext context) {
    final deleteTint = _hoveringDelete
        ? const Color(0xFFB3261E)
        : (widget.selected ? Colors.white : const Color(0xFF7A8F8A));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 198,
          padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: widget.selected ? Color(0xFF0F8F82) : Color(0xFFF6FBFA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected ? Color(0xFF0F8F82) : Color(0xFFD8E8E4),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: widget.showRemoveControl ? 28 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.displayName.isEmpty
                          ? '${widget.entityLabel} Profile'
                          : widget.profile.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.selected
                            ? Colors.white
                            : Color(0xFF124B45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.profile.profileId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.selected
                            ? Colors.white70
                            : Color(0xFF5E7D77),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showRemoveControl)
                Positioned(
                  top: -4,
                  right: -4,
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveringDelete = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveringDelete = false;
                      });
                    },
                    child: Material(
                      color: _hoveringDelete
                          ? const Color(0xFFFDECEA)
                          : Colors.transparent,
                      shape: CircleBorder(),
                      child: InkWell(
                        customBorder: CircleBorder(),
                        onTap: widget.removing ? null : widget.onRemove,
                        child: SizedBox(
                          height: 28,
                          width: 28,
                          child: Center(
                            child: widget.removing
                                ? SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: deleteTint,
                                    ),
                                  )
                                : Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: deleteTint,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantProfileAvatar extends StatelessWidget {
  const _TenantProfileAvatar({required this.name, this.imageBytes});

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

    return CircleAvatar(
      radius: 26,
      backgroundColor: Color(0xFFE7F3F0),
      backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes!),
      child: imageBytes == null
          ? Text(
              initials.isEmpty ? 'P' : initials,
              style: TextStyle(
                color: Color(0xFF0F8F82),
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _TenantInfoBlock extends StatelessWidget {
  const _TenantInfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FCFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFDCEBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            style: TextStyle(
              color: Color(0xFF124B45),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantExistingDocumentTile extends StatelessWidget {
  const _TenantExistingDocumentTile({
    required this.document,
    required this.visibleName,
    required this.onDownload,
    required this.onRemove,
  });

  final _TenantExistingDocument document;
  final String visibleName;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFF9FCFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFDCEBE8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Name',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  visibleName,
                  style: TextStyle(
                    color: Color(0xFF124B45),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onDownload,
                icon: Icon(Icons.download_outlined),
                label: Text('Download'),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, color: Color(0xFFB3261E)),
                label: Text(
                  'Remove',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TenantNewDocumentTile extends StatelessWidget {
  const _TenantNewDocumentTile({
    required this.draft,
    required this.onChooseFile,
    required this.onUpload,
    required this.onRemove,
    required this.mobile,
  });

  final _TenantNewDocumentDraft draft;
  final Future<void> Function() onChooseFile;
  final Future<void> Function() onUpload;
  final VoidCallback onRemove;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final fileName = draft.fileName?.trim() ?? '';

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFFE0AC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveFieldRow(
            mobile: mobile,
            children: [
              _ProfileInputField(
                label: 'Document Name',
                controller: draft.documentNameController,
                maxLines: 2,
              ),
              _TenantInfoBlock(
                label: 'Upload Document',
                value: fileName.isEmpty ? 'No file selected' : fileName,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: draft.uploading ? null : onChooseFile,
                icon: Icon(Icons.attach_file_outlined),
                label: Text('Choose Document'),
              ),
              SizedBox(width: 12),
              FilledButton.icon(
                onPressed: draft.uploading ? null : onUpload,
                icon: Icon(Icons.upload_file_outlined),
                label: Text(draft.uploading ? 'Uploading...' : 'Upload'),
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF0F8F82),
                ),
              ),
              SizedBox(width: 12),
              TextButton.icon(
                onPressed: draft.uploading ? null : onRemove,
                icon: Icon(Icons.delete_outline, color: Color(0xFFB3261E)),
                label: Text(
                  'Remove',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
              ),
            ],
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
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: maxLines,
      obscureText: obscureText,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        hintText: hintText,
        suffixIcon: suffixIcon,
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
