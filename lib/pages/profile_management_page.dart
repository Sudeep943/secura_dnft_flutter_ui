import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
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
    _primeCreateProfileDefaults();
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
    super.dispose();
  }

  void _primeCreateProfileDefaults() {
    final nameParts = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (_displayName != 'Resident Profile' && nameParts.isNotEmpty) {
      _firstNameController.text = nameParts.first;
      if (nameParts.length == 2) {
        _lastNameController.text = nameParts.last;
      } else if (nameParts.length >= 3) {
        _middleNameController.text = nameParts
            .sublist(1, nameParts.length - 1)
            .join(' ');
        _lastNameController.text = nameParts.last;
      }
    }

    _profileFlatNoController.text = _flatNo;
    if (_phone != '+91 98765 43210') {
      _mobileNumberController.text = _phone;
    }
    if (_email != 'name@example.com') {
      _emailIdController.text = _email;
    }
    _addressLine1Controller.text = 'Flat $_flatNo';
    _addressLine2Controller.text = 'Sunshine Apartment';
    _cityController.text = 'Bhubaneswar';
    _stateController.text = 'Odisha';
    _postOfficeController.text = 'Patia';
    _policeStationController.text = 'Infocity';
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
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                      child: Container(
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
                            _EditableProfileAvatar(name: _displayName),
                            SizedBox(height: 18),
                            Text(
                              _displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF124B45),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Manage profile details, updates, and password settings from one place.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF5FBFA),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Color(0xFFD2ECE7)),
                              ),
                              child: TabBar(
                                indicator: BoxDecoration(
                                  color: Color(0xFF0F8F82),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Color(0xFF124B45),
                                dividerColor: Colors.transparent,
                                padding: EdgeInsets.all(6),
                                tabs: const [
                                  Tab(text: 'Create New Profile'),
                                  Tab(text: 'Update Profile'),
                                  Tab(text: 'Update Password'),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            SizedBox(
                              height: mobile ? 1700 : 980,
                              child: TabBarView(
                                children: [
                                  _ProfileSectionCard(
                                    title: 'Create New Profile',
                                    subtitle:
                                        'Use this section to onboard a new resident or member profile.',
                                    child: _CreateProfileTab(
                                      formKey: _createProfileFormKey,
                                      firstNameController: _firstNameController,
                                      middleNameController:
                                          _middleNameController,
                                      lastNameController: _lastNameController,
                                      profileFlatNoController:
                                          _profileFlatNoController,
                                      mobileNumberController:
                                          _mobileNumberController,
                                      emailIdController: _emailIdController,
                                      landlineNumberController:
                                          _landlineNumberController,
                                      addressLine1Controller:
                                          _addressLine1Controller,
                                      addressLine2Controller:
                                          _addressLine2Controller,
                                      addressLine3Controller:
                                          _addressLine3Controller,
                                      addressLine4Controller:
                                          _addressLine4Controller,
                                      landmarkController: _landmarkController,
                                      cityController: _cityController,
                                      stateController: _stateController,
                                      postOfficeController:
                                          _postOfficeController,
                                      policeStationController:
                                          _policeStationController,
                                      pinController: _pinController,
                                      profileType: _profileType,
                                      profilePosition: _profilePosition,
                                      gender: _gender,
                                      addressType: _addressType,
                                      onProfileTypeChanged: (value) {
                                        setState(() {
                                          _profileType = value;
                                        });
                                      },
                                      onProfilePositionChanged: (value) {
                                        setState(() {
                                          _profilePosition = value;
                                        });
                                      },
                                      onGenderChanged: (value) {
                                        setState(() {
                                          _gender = value;
                                        });
                                      },
                                      onAddressTypeChanged: (value) {
                                        setState(() {
                                          _addressType = value ?? 'RESIDENTIAL';
                                        });
                                      },
                                      requiredValidator: _requiredValidator,
                                      mobileValidator: _mobileValidator,
                                      emailValidator: _emailValidator,
                                      submitting: _creatingProfile,
                                      onSubmit: _submitCreateProfile,
                                      mobile: mobile,
                                    ),
                                  ),
                                  _ProfileSectionCard(
                                    title: 'Update Profile',
                                    subtitle:
                                        'Refresh contact, role, and location details for the selected profile.',
                                    child: _UpdateProfileTab(
                                      displayName: _displayName,
                                      email: _email,
                                      phone: _phone,
                                      flatNo: _flatNo,
                                      role: _role,
                                      mobile: mobile,
                                    ),
                                  ),
                                  _ProfileSectionCard(
                                    title: 'Update Password',
                                    subtitle:
                                        'Keep your account secure by rotating the password regularly.',
                                    child: _UpdatePasswordTab(mobile: mobile),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  });

  final String title;
  final String subtitle;
  final Widget child;

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
        children: [
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
          Expanded(child: SingleChildScrollView(child: child)),
        ],
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
    required this.displayName,
    required this.email,
    required this.phone,
    required this.flatNo,
    required this.role,
    required this.mobile,
  });

  final String displayName;
  final String email;
  final String phone;
  final String flatNo;
  final String role;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  'Current profile selected for editing: $displayName',
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
              initialValue: displayName,
            ),
            _ProfileInputField(label: 'Resident Role', initialValue: role),
          ],
        ),
        SizedBox(height: 16),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(label: 'Email Address', initialValue: email),
            _ProfileInputField(label: 'Phone Number', initialValue: phone),
          ],
        ),
        SizedBox(height: 16),
        _ResponsiveFieldRow(
          mobile: mobile,
          children: [
            _ProfileInputField(label: 'Flat No', initialValue: flatNo),
            _ProfileInputField(label: 'Emergency Contact', initialValue: phone),
          ],
        ),
        SizedBox(height: 16),
        _ProfileInputField(
          label: 'Additional Information',
          initialValue:
              'Update address details, relationship info, or access notes.',
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
