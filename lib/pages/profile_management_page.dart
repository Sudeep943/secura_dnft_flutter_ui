import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

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

  static final Map<String, String> updateProfile = {};
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final _createProfileFormKey = GlobalKey<FormState>();
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

  final _updateDisplayNameController = TextEditingController();
  final _updateRoleController = TextEditingController();
  final _updateEmailController = TextEditingController();
  final _updatePhoneController = TextEditingController();
  final _updateFlatNoController = TextEditingController();
  final _updateEmergencyContactController = TextEditingController();
  final _updateAdditionalInfoController = TextEditingController();

  _ProfileManagementSection? _selectedSection;
  String? _profileType;
  String? _profilePosition;
  String? _gender;
  String _addressType = 'RESIDENTIAL';
  bool _creatingProfile = false;

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  void initState() {
    super.initState();
    _restoreDrafts();
    _attachDraftListeners();
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
    _updateDisplayNameController.dispose();
    _updateRoleController.dispose();
    _updateEmailController.dispose();
    _updatePhoneController.dispose();
    _updateFlatNoController.dispose();
    _updateEmergencyContactController.dispose();
    _updateAdditionalInfoController.dispose();
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

    _updateDisplayNameController.text =
        _ProfileManagementDraft.updateProfile['displayName'] ?? _displayName;
    _updateRoleController.text =
        _ProfileManagementDraft.updateProfile['role'] ?? _role;
    _updateEmailController.text =
        _ProfileManagementDraft.updateProfile['email'] ?? _email;
    _updatePhoneController.text =
        _ProfileManagementDraft.updateProfile['phone'] ?? _phone;
    _updateFlatNoController.text =
        _ProfileManagementDraft.updateProfile['flatNo'] ?? _flatNo;
    _updateEmergencyContactController.text =
        _ProfileManagementDraft.updateProfile['emergencyContact'] ?? _phone;
    _updateAdditionalInfoController.text =
        _ProfileManagementDraft.updateProfile['additionalInfo'] ??
        'Update address details, relationship info, or access notes.';
  }

  void _attachDraftListeners() {
    _bindDraftController(
      controller: _firstNameController,
      store: _ProfileManagementDraft.createProfile,
      key: 'firstName',
    );
    _bindDraftController(
      controller: _middleNameController,
      store: _ProfileManagementDraft.createProfile,
      key: 'middleName',
    );
    _bindDraftController(
      controller: _lastNameController,
      store: _ProfileManagementDraft.createProfile,
      key: 'lastName',
    );
    _bindDraftController(
      controller: _profileFlatNoController,
      store: _ProfileManagementDraft.createProfile,
      key: 'profileFlatNo',
    );
    _bindDraftController(
      controller: _mobileNumberController,
      store: _ProfileManagementDraft.createProfile,
      key: 'mobileNumber',
    );
    _bindDraftController(
      controller: _emailIdController,
      store: _ProfileManagementDraft.createProfile,
      key: 'emailId',
    );
    _bindDraftController(
      controller: _landlineNumberController,
      store: _ProfileManagementDraft.createProfile,
      key: 'landlineNumber',
    );
    _bindDraftController(
      controller: _addressLine1Controller,
      store: _ProfileManagementDraft.createProfile,
      key: 'addressLine1',
    );
    _bindDraftController(
      controller: _addressLine2Controller,
      store: _ProfileManagementDraft.createProfile,
      key: 'addressLine2',
    );
    _bindDraftController(
      controller: _addressLine3Controller,
      store: _ProfileManagementDraft.createProfile,
      key: 'addressLine3',
    );
    _bindDraftController(
      controller: _addressLine4Controller,
      store: _ProfileManagementDraft.createProfile,
      key: 'addressLine4',
    );
    _bindDraftController(
      controller: _landmarkController,
      store: _ProfileManagementDraft.createProfile,
      key: 'landmark',
    );
    _bindDraftController(
      controller: _cityController,
      store: _ProfileManagementDraft.createProfile,
      key: 'city',
    );
    _bindDraftController(
      controller: _stateController,
      store: _ProfileManagementDraft.createProfile,
      key: 'state',
    );
    _bindDraftController(
      controller: _postOfficeController,
      store: _ProfileManagementDraft.createProfile,
      key: 'postOffice',
    );
    _bindDraftController(
      controller: _policeStationController,
      store: _ProfileManagementDraft.createProfile,
      key: 'policeStation',
    );
    _bindDraftController(
      controller: _pinController,
      store: _ProfileManagementDraft.createProfile,
      key: 'pin',
    );

    _bindDraftController(
      controller: _updateDisplayNameController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'displayName',
    );
    _bindDraftController(
      controller: _updateRoleController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'role',
    );
    _bindDraftController(
      controller: _updateEmailController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'email',
    );
    _bindDraftController(
      controller: _updatePhoneController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'phone',
    );
    _bindDraftController(
      controller: _updateFlatNoController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'flatNo',
    );
    _bindDraftController(
      controller: _updateEmergencyContactController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'emergencyContact',
    );
    _bindDraftController(
      controller: _updateAdditionalInfoController,
      store: _ProfileManagementDraft.updateProfile,
      key: 'additionalInfo',
    );
  }

  void _bindDraftController({
    required TextEditingController controller,
    required Map<String, String> store,
    required String key,
  }) {
    controller.addListener(() {
      store[key] = controller.text;
    });
  }

  void _openSection(_ProfileManagementSection section) {
    setState(() {
      _selectedSection = section;
      _ProfileManagementDraft.selectedSection = section;
    });
  }

  void _closeSection() {
    setState(() {
      _selectedSection = null;
      _ProfileManagementDraft.selectedSection = null;
    });
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

  String get _displayName => _readHeaderValue([
    'name',
    'fullName',
    'userName',
    'username',
    'residentName',
    'memberName',
  ], fallback: 'Resident Profile');

  String get _email => _readHeaderValue([
    'email',
    'emailId',
    'mailId',
  ], fallback: 'name@example.com');

  String get _phone => _readHeaderValue([
    'phone',
    'phoneNo',
    'mobile',
    'mobileNo',
  ], fallback: '+91 98765 43210');

  String get _flatNo =>
      ApiService.getLoggedInFlatNo() ??
      _readHeaderValue(['flatId'], fallback: 'A-101');

  String get _role =>
      _readHeaderValue(['access', 'role', 'userRole'], fallback: 'Resident');

  void _showStatusModal({
    required String title,
    required String message,
    required bool isSuccess,
    String? profileId,
  }) {
    showDialog(
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
        return 'Open profile editing tools, including the profile picture update area.';
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
          displayNameController: _updateDisplayNameController,
          emailController: _updateEmailController,
          phoneController: _updatePhoneController,
          flatNoController: _updateFlatNoController,
          roleController: _updateRoleController,
          emergencyContactController: _updateEmergencyContactController,
          additionalInfoController: _updateAdditionalInfoController,
          mobile: mobile,
        );
      case _ProfileManagementSection.updatePassword:
        return _UpdatePasswordTab(mobile: mobile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('Profile Management'),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      drawer: mobile ? Drawer(child: SideBar()) : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!mobile) SideBar(),
            Expanded(
              child: SingleChildScrollView(
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
                              border: Border.all(
                                color: Color(0xFF0F8F82),
                                width: 1.5,
                              ),
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
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
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
                                        _ProfileManagementSection
                                            .updatePassword,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProfileManagementSection { createProfile, updateProfile, updatePassword }

class _EditableProfileAvatar extends StatefulWidget {
  const _EditableProfileAvatar({required this.name});

  final String name;

  @override
  State<_EditableProfileAvatar> createState() => _EditableProfileAvatarState();
}

class _EditableProfileAvatarState extends State<_EditableProfileAvatar> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: SizedBox(
          width: 156,
          height: 156,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 180),
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hovered ? Color(0xFF0F8F82) : Color(0xFFB8DDD7),
                    width: hovered ? 4 : 3,
                  ),
                  gradient: LinearGradient(
                    colors: [Color(0xFFEAF7F4), Color(0xFFD6EFEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF0F8F82).withValues(alpha: 0.14),
                      blurRadius: hovered ? 24 : 14,
                      offset: Offset(0, hovered ? 10 : 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'RP' : initials,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F8F82),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 180),
                  opacity: hovered ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !hovered,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 180),
                  opacity: hovered ? 1 : 0.75,
                  child: FilledButton.icon(
                    onPressed: hovered ? () {} : null,
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Edit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFF0F8F82),
                      disabledBackgroundColor: Color(0xFF7EAAA4),
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
    required this.displayNameController,
    required this.emailController,
    required this.phoneController,
    required this.flatNoController,
    required this.roleController,
    required this.emergencyContactController,
    required this.additionalInfoController,
    required this.mobile,
  });

  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController flatNoController;
  final TextEditingController roleController;
  final TextEditingController emergencyContactController;
  final TextEditingController additionalInfoController;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditableProfileAvatar(name: displayNameController.text),
        SizedBox(height: 18),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF4FBFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFD5EBE7)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF0F8F82)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Current profile selected for editing: ${displayNameController.text}. Profile picture update is available here only.',
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
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(
              label: 'Display Name',
              controller: displayNameController,
            ),
            _ProfileInputField(
              label: 'Resident Role',
              controller: roleController,
            ),
          ],
        ),
        SizedBox(height: 16),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(
              label: 'Email Address',
              controller: emailController,
            ),
            _ProfileInputField(
              label: 'Phone Number',
              controller: phoneController,
            ),
          ],
        ),
        SizedBox(height: 16),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(label: 'Flat No', controller: flatNoController),
            _ProfileInputField(
              label: 'Emergency Contact',
              controller: emergencyContactController,
            ),
          ],
        ),
        SizedBox(height: 16),
        _ProfileInputField(
          label: 'Additional Information',
          controller: additionalInfoController,
          maxLines: 4,
        ),
        SizedBox(height: 22),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () {},
            icon: Icon(Icons.save_outlined),
            label: Text('Save Profile Changes'),
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
    this.maxLines = 1,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final int maxLines;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Color(0xFFF9FCFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
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
    this.validator,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Color(0xFFF9FCFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD8E8E4)),
        ),
      ),
    );
  }
}
