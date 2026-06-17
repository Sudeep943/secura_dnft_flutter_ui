import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:xml/xml.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../services/receipt_downloader.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';
import 'create_payment_page.dart';
import 'create_notice_page.dart';
import 'create_receipt_page.dart';
import 'reports_dashboard_page.dart';
import 'home_page.dart';
import 'onboard_employee_page.dart';
import 'view_all_notices_page.dart';
import 'view_transactions_page.dart';
import 'view_update_payments_page.dart';
import 'create_ledger_entry_page.dart';

bool _accessBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == 'y' || text == 'yes';
}

Map<String, dynamic> _accessMapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  if (value is String) {
    final text = value.trim();
    if (text.startsWith('{')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
  }
  return <String, dynamic>{};
}

bool _hasAccessFlag(String moduleKey, String flagKey) {
  final access = _accessMapValue(ApiService.userHeader?['access']);
  final module = _accessMapValue(access[moduleKey]);
  return _accessBool(module[flagKey]);
}

bool _hasAnyAccessFlag(String moduleKey, List<String> flagKeys) {
  final access = _accessMapValue(ApiService.userHeader?['access']);
  final module = _accessMapValue(access[moduleKey]);
  for (final key in flagKeys) {
    if (_accessBool(module[key])) {
      return true;
    }
  }
  return false;
}

class MeetingAndNoticeManagementPage extends StatefulWidget {
  const MeetingAndNoticeManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MeetingAndNoticeManagementPage> createState() =>
      _MeetingAndNoticeManagementPageState();
}

class _MeetingAndNoticeManagementPageState
    extends State<MeetingAndNoticeManagementPage> {
  bool _showViewAllNotices = false;

  @override
  Widget build(BuildContext context) {
    if (_showViewAllNotices) {
      return ViewAllNoticesPage(
        onBack: () {
          setState(() {
            _showViewAllNotices = false;
          });
        },
      );
    }

    final canScheduleMeeting = _hasAccessFlag(
      'meetingAndNoticeAccess',
      'scheduleMeetingAccess',
    );
    final canUpdateMom = _hasAnyAccessFlag('meetingAndNoticeAccess', const [
      'updateMOMAccess',
      'updateMOMgAccess',
    ]);
    final canCreateNotice = _hasAccessFlag(
      'meetingAndNoticeAccess',
      'createNoticeAccess',
    );
    final canCreateEvent = _hasAccessFlag(
      'meetingAndNoticeAccess',
      'createEventAccess',
    );
    final canCreatePoll = _hasAccessFlag(
      'meetingAndNoticeAccess',
      'createPollAccess',
    );

    final items = <_ModuleHubItem>[
      if (canScheduleMeeting)
        _ModuleHubItem('Schedule New Meeting', Icons.event_note),
      _ModuleHubItem('View Meeting Details', Icons.visibility),
      if (canUpdateMom) _ModuleHubItem('Update MOM', Icons.edit_document),
      if (canCreateNotice)
        _ModuleHubItem(
          'Create Notice',
          Icons.campaign,
          onTap: () {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const CreateNoticeDialog(),
            );
          },
        ),
      _ModuleHubItem(
        'View All Notice',
        Icons.notifications_active,
        onTap: () {
          setState(() {
            _showViewAllNotices = true;
          });
        },
      ),
      if (canCreateEvent) _ModuleHubItem('Create Event', Icons.event),
      _ModuleHubItem('View Events', Icons.calendar_month),
      if (canCreatePoll) _ModuleHubItem('Create Poll', Icons.how_to_vote),
      _ModuleHubItem('View Poll', Icons.poll),
    ];

    return _ModuleHubPage(
      embedded: widget.embedded,
      section: AppSection.meetingAndNotice,
      title: 'Meeting And Notice Management',
      subtitle:
          'Choose one of the meeting, notice, event, or poll actions below.',
      items: items,
    );
  }
}

class TicketManagementPage extends StatelessWidget {
  const TicketManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final canAssignTicket = _hasAccessFlag(
      'ticketManagementAccess',
      'reAsignTicketAccess',
    );

    final items = <_ModuleHubItem>[
      const _ModuleHubItem('Raise A New Ticket', Icons.support_agent),
      const _ModuleHubItem('View Ticket', Icons.confirmation_number),
      if (canAssignTicket)
        const _ModuleHubItem('Assign Ticket', Icons.assignment_ind),
    ];

    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.ticketManagement,
      title: 'Ticket Management',
      subtitle: 'Choose one of the ticket management actions below.',
      items: items,
    );
  }
}

class SecurityManagementPage extends StatelessWidget {
  const SecurityManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.security,
      title: 'Security',
      subtitle:
          'Choose one of the security and guard coordination actions below.',
      items: const [
        _ModuleHubItem(
          'Create Visitor Entry by Security/Owner/Tenant',
          Icons.badge,
        ),
        _ModuleHubItem('Create Daily Worker Entry', Icons.engineering),
        _ModuleHubItem('Create Vehicle Pass', Icons.directions_car),
        _ModuleHubItem('Message Guard', Icons.message),
      ],
    );
  }
}

class GroupManagementPage extends StatelessWidget {
  const GroupManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.groupManagement,
      title: 'Group Management',
      subtitle: 'Choose one of the group and community actions below.',
      items: const [
        _ModuleHubItem('Create Group/Community', Icons.groups),
        _ModuleHubItem('Update Group', Icons.group_add),
      ],
    );
  }
}

class FlatManagementPage extends StatelessWidget {
  const FlatManagementPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  void _showPlaceholderMessage(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title page is ready for the next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddUpdateFlat = _hasAccessFlag(
      'adminAccess',
      'addUpdateFlatAccess',
    );

    final items = <_ModuleHubItem>[
      if (canAddUpdateFlat)
        _ModuleHubItem(
          'Add Flat',
          Icons.add_home_work_outlined,
          onTap: () => _showPlaceholderMessage(context, 'Add Flat'),
        ),
      if (canAddUpdateFlat)
        _ModuleHubItem(
          'Update Flat',
          Icons.edit_outlined,
          onTap: () => _showPlaceholderMessage(context, 'Update Flat'),
        ),
      _ModuleHubItem(
        'Upload Flat Details',
        Icons.upload_file_outlined,
        onTap: () {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _UploadFlatDetailsDialog(),
          );
        },
      ),
    ];

    return _ModuleHubPage(
      embedded: embedded,
      onBack:
          onBack ??
          (embedded
              ? () => openAppShellSection(context, AppSection.adminSection)
              : null),
      section: AppSection.flatManagement,
      title: 'Flat Management',
      subtitle:
          'Choose one of the flat management actions below to add, update, or upload flat details.',
      items: items,
    );
  }
}

class AdminSectionPage extends StatefulWidget {
  const AdminSectionPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminSectionPage> createState() => _AdminSectionPageState();
}

class _AdminSectionPageState extends State<AdminSectionPage> {
  bool _showUpdateSocietyDetails = false;

  @override
  Widget build(BuildContext context) {
    if (_showUpdateSocietyDetails) {
      return UpdateSocietyDetailsPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showUpdateSocietyDetails = false;
          });
        },
      );
    }

    final items = <_ModuleHubItem>[
      if (_hasAccessFlag('adminAccess', 'roleManagmentparentAccess'))
        _ModuleHubItem(
          'Role Management',
          Icons.lock_person_outlined,
          onTap: () => openAppShellSection(context, AppSection.roleAndAccess),
        ),
      if (_hasAccessFlag('adminAccess', 'staffeManagmentparentAccess'))
        _ModuleHubItem(
          'Staff Management',
          Icons.groups_outlined,
          onTap: () => openAppShellSection(context, AppSection.staffManagement),
        ),
      if (_hasAccessFlag('adminAccess', 'flateManagmentparentAccess'))
        _ModuleHubItem(
          'Flat Management',
          Icons.door_front_door_outlined,
          onTap: () => openAppShellSection(context, AppSection.flatManagement),
        ),
      if (_hasAccessFlag('adminAccess', 'societyDetailsManagmentparentAccess'))
        _ModuleHubItem(
          'Update Society Details',
          Icons.apartment_outlined,
          onTap: () {
            setState(() {
              _showUpdateSocietyDetails = true;
            });
          },
        ),
    ];

    return _ModuleHubPage(
      embedded: widget.embedded,
      section: AppSection.adminSection,
      title: 'Admin Section',
      subtitle:
          'Choose one of the administration actions below for roles, staff, and flat operations.',
      items: items,
    );
  }
}

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  bool _showEmployeeAttendance = false;
  StaffManagementPanel _initialPanel = StaffManagementPanel.onboardEmployee;

  @override
  Widget build(BuildContext context) {
    if (_showEmployeeAttendance) {
      return OnboardEmployeePage(
        embedded: widget.embedded,
        initialPanel: _initialPanel,
        onBack: () {
          setState(() {
            _showEmployeeAttendance = false;
          });
        },
      );
    }

    final canOnboard = _hasAccessFlag('adminAccess', 'onboardStaffAccess');
    final canAttendance = _hasAccessFlag(
      'adminAccess',
      'staffAttendanceAccess',
    );

    final items = <_ModuleHubItem>[
      if (canOnboard)
        _ModuleHubItem(
          'Onboard Employee',
          Icons.person_add_alt_1,
          onTap: () {
            setState(() {
              _initialPanel = StaffManagementPanel.onboardEmployee;
              _showEmployeeAttendance = true;
            });
          },
        ),
      if (canAttendance)
        _ModuleHubItem(
          'Today Attendance',
          Icons.today_outlined,
          onTap: () {
            setState(() {
              _initialPanel = StaffManagementPanel.todayAttendance;
              _showEmployeeAttendance = true;
            });
          },
        ),
      if (canAttendance)
        _ModuleHubItem(
          'Employee Attendance',
          Icons.badge_outlined,
          onTap: () {
            setState(() {
              _initialPanel = StaffManagementPanel.employeeAttendance;
              _showEmployeeAttendance = true;
            });
          },
        ),
    ];

    return _ModuleHubPage(
      embedded: widget.embedded,
      onBack:
          widget.onBack ??
          (widget.embedded
              ? () => openAppShellSection(context, AppSection.adminSection)
              : null),
      section: AppSection.staffManagement,
      title: 'Staff Management',
      subtitle: 'Choose one of the staff management actions below.',
      items: items,
    );
  }
}

class VendorManagementPage extends StatelessWidget {
  const VendorManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final canAddVendor = _hasAccessFlag(
      'vendorManagementAccess',
      'addNewVendorAccess',
    );
    final canUpdateVendor = _hasAccessFlag(
      'vendorManagementAccess',
      'updateVendorAccess',
    );
    final canViewVendors = _hasAccessFlag(
      'vendorManagementAccess',
      'viewVendorsAccess',
    );

    final items = <_ModuleHubItem>[
      if (canAddVendor)
        const _ModuleHubItem('Add Vendor', Icons.storefront_outlined),
      if (canUpdateVendor)
        const _ModuleHubItem('Update Vendor', Icons.edit_note_outlined),
      if (canViewVendors)
        const _ModuleHubItem('View Vendors', Icons.list_alt_outlined),
    ];

    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.vendorManagement,
      title: 'Vendor Management',
      subtitle: 'Choose one of the vendor management actions below.',
      items: items,
    );
  }
}

class RoleAndAccessPage extends StatefulWidget {
  const RoleAndAccessPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<RoleAndAccessPage> createState() => _RoleAndAccessPageState();
}

class _RoleAndAccessPageState extends State<RoleAndAccessPage> {
  bool _showManageAccess = false;

  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  Widget _dialogHeader(String title) {
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

  InputDecoration _dialogInputDecoration({
    required String labelText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _brandTextColor),
      errorText: errorText,
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

  ButtonStyle _filledButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _brandColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  ButtonStyle _textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: _brandColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  Future<void> _showCreateRoleDialog() async {
    final roleController = TextEditingController();
    String? validationMessage;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              title: _dialogHeader('Create Role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: roleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    cursorColor: _brandColor,
                    onChanged: (_) {
                      if (validationMessage != null) {
                        setDialogState(() => validationMessage = null);
                      }
                    },
                    onSubmitted: (_) {},
                    decoration: _dialogInputDecoration(
                      labelText: 'Role Name',
                      errorText: validationMessage,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: _textButtonStyle(),
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: _filledButtonStyle(),
                  onPressed: submitting
                      ? null
                      : () async {
                          final roleName = roleController.text
                              .trim()
                              .toUpperCase();
                          if (roleName.isEmpty) {
                            setDialogState(() {
                              validationMessage = 'Please provide role name.';
                            });
                            return;
                          }

                          setDialogState(() {
                            submitting = true;
                            validationMessage = null;
                          });

                          final response = await ApiService.createRole(
                            roleName: roleName,
                          );
                          if (!mounted) return;

                          final message =
                              response?['message']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? response!['message'].toString()
                              : 'Unable to create role.';
                          final code =
                              response?['messageCode']?.toString().trim() ?? '';
                          final isSuccess = code.toUpperCase().contains('SUCC');

                          if (isSuccess) {
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }
                          } else {
                            setDialogState(() {
                              submitting = false;
                              validationMessage = message;
                            });
                            return;
                          }

                          await showDialog<void>(
                            context: context,
                            builder: (statusContext) => AlertDialog(
                              titlePadding: EdgeInsets.zero,
                              title: _dialogHeader('Create Role'),
                              content: Text(message),
                              actions: [
                                TextButton(
                                  style: _textButtonStyle(),
                                  onPressed: () =>
                                      Navigator.of(statusContext).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Role'),
                ),
              ],
            );
          },
        );
      },
    );

    roleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showManageAccess) {
      return ManageAccessPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showManageAccess = false;
          });
        },
      );
    }

    final items = <_ModuleHubItem>[
      if (_hasAccessFlag('adminAccess', 'createRoleAccess'))
        _ModuleHubItem(
          'Create Role',
          Icons.admin_panel_settings,
          onTap: _showCreateRoleDialog,
        ),
      if (_hasAccessFlag('adminAccess', 'assigneRoleAccess'))
        const _ModuleHubItem('Assign Role', Icons.assignment_turned_in),
      if (_hasAccessFlag('adminAccess', 'manageRoleAccess'))
        _ModuleHubItem(
          'Manage Access',
          Icons.lock_open,
          onTap: () {
            setState(() {
              _showManageAccess = true;
            });
          },
        ),
    ];

    return _ModuleHubPage(
      embedded: widget.embedded,
      onBack:
          widget.onBack ??
          (widget.embedded
              ? () => openAppShellSection(context, AppSection.adminSection)
              : null),
      section: AppSection.roleAndAccess,
      title: 'Role And Access',
      subtitle: 'Choose one of the role and access control actions below.',
      items: items,
    );
  }
}

class ManageAccessPage extends StatefulWidget {
  const ManageAccessPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ManageAccessPage> createState() => _ManageAccessPageState();
}

class _ManageAccessPageState extends State<ManageAccessPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _roles = const [];

  // Edit mode tracking
  String? _editingRoleId;
  Map<String, dynamic>? _editingAccess;
  bool _isUpdating = false;
  String? _updateError;
  final Set<String> _expandedRoleIds = {};

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await ApiService.getAllRoles();
    if (!mounted) {
      return;
    }

    final messageCode = response?['messageCode']?.toString().trim() ?? '';
    final isSuccess = messageCode.toUpperCase().contains('SUCC');
    if (!isSuccess) {
      setState(() {
        _loading = false;
        _roles = const [];
        _error = response?['message']?.toString().trim().isNotEmpty == true
            ? response!['message'].toString()
            : 'Unable to load roles.';
      });
      return;
    }

    final rawRoles = response?['roles'];
    final roles = rawRoles is List
        ? rawRoles
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _loading = false;
      _roles = roles;
      _error = roles.isEmpty ? 'No roles found.' : null;
    });
  }

  String _readValue(Map<String, dynamic> role, String key) {
    final value = role[key]?.toString().trim() ?? '';
    return value;
  }

  /// Parses the access JSON string into a list of section entries.
  /// Each entry is a MapEntry<String, Map<String, bool>>:
  ///   key   → section name (e.g. "accountManagmentAccess")
  ///   value → field name → bool value
  List<MapEntry<String, Map<String, bool>>> _parseAccessSections(
    Map<String, dynamic> role,
  ) {
    final raw = _readValue(role, 'access');
    if (raw.isEmpty) return const [];

    Map<String, dynamic> decoded;
    try {
      decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const [];
    }

    final sections = <MapEntry<String, Map<String, bool>>>[];
    decoded.forEach((sectionKey, sectionValue) {
      if (sectionValue is! Map) return;
      final fields = <String, bool>{};
      sectionValue.forEach((fieldKey, fieldValue) {
        if (fieldValue is bool) {
          fields[fieldKey] = fieldValue;
        }
      });
      if (fields.isNotEmpty) {
        sections.add(MapEntry(sectionKey, fields));
      }
    });
    return sections;
  }

  Future<void> _handleUpdateAccess(Map<String, dynamic> role) async {
    final roleId = _readValue(role, 'roleId');
    final rawAccess = _readValue(role, 'access');

    if (roleId.isEmpty || rawAccess.isEmpty) {
      return;
    }

    try {
      final decodedAccess = Map<String, dynamic>.from(
        jsonDecode(rawAccess) as Map,
      );
      setState(() {
        _editingRoleId = roleId;
        _editingAccess = decodedAccess;
      });
    } catch (_) {
      // Ignore parsing errors
    }
  }

  Future<void> _handleUpdateRoleAccess(Map<String, dynamic> role) async {
    final roleId = _readValue(role, 'roleId');
    if (roleId.isEmpty || _editingAccess == null) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    final response = await ApiService.updateRoleAccess(
      roleId: roleId,
      access: _editingAccess!,
    );

    if (!mounted) {
      return;
    }

    final messageCode = response?['messageCode']?.toString().trim() ?? '';
    final isSuccess = messageCode.toUpperCase().contains('SUCC');
    final responseMessage =
        response?['message']?.toString().trim() ?? 'Operation completed';

    if (!isSuccess) {
      setState(() {
        _isUpdating = false;
        _updateError = responseMessage;
      });
      return;
    }

    // Show success modal and reload on OK
    setState(() {
      _editingRoleId = null;
      _editingAccess = null;
      _isUpdating = false;
    });

    await _showResponseModal('Success', responseMessage, true);
  }

  Future<void> _handleUpdateRoleStatus(
    Map<String, dynamic> role,
    String newStatus,
  ) async {
    final roleId = _readValue(role, 'roleId');
    if (roleId.isEmpty) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    final response = await ApiService.updateRoleStatus(
      roleId: roleId,
      status: newStatus,
    );

    if (!mounted) {
      return;
    }

    final messageCode = response?['messageCode']?.toString().trim() ?? '';
    final isSuccess = messageCode.toUpperCase().contains('SUCC');
    final responseMessage =
        response?['message']?.toString().trim() ?? 'Operation completed';

    if (!isSuccess) {
      setState(() {
        _isUpdating = false;
        _updateError = responseMessage;
      });
      return;
    }

    // Show success modal and reload on OK
    setState(() {
      _isUpdating = false;
    });

    await _showResponseModal('Success', responseMessage, true);
  }

  void _cancelEditMode() {
    setState(() {
      _editingRoleId = null;
      _editingAccess = null;
      _updateError = null;
    });
  }

  Future<void> _showResponseModal(
    String title,
    String message,
    bool isSuccess,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final headerColor = isSuccess
            ? const Color(0xFF0F8F82)
            : const Color(0xFFB3261E);

        return AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
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
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: headerColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  _loadRoles();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateAccessField(String sectionKey, String fieldKey, bool value) {
    if (_editingAccess == null) return;

    setState(() {
      if (_editingAccess![sectionKey] is Map) {
        final section = Map<String, dynamic>.from(
          _editingAccess![sectionKey] as Map,
        );
        section[fieldKey] = value;
        _editingAccess![sectionKey] = section;
      }
    });
  }

  void _selectAllSectionFields(String sectionKey, bool value) {
    if (_editingAccess == null) return;
    setState(() {
      if (_editingAccess![sectionKey] is Map) {
        final section = Map<String, dynamic>.from(
          _editingAccess![sectionKey] as Map,
        );
        for (final k in section.keys.toList()) {
          section[k] = value;
        }
        _editingAccess![sectionKey] = section;
      }
    });
  }

  void _selectAllFields(bool value) {
    if (_editingAccess == null) return;
    setState(() {
      _editingAccess!.forEach((sectionKey, sectionValue) {
        if (sectionValue is Map) {
          final section = Map<String, dynamic>.from(sectionValue);
          for (final k in section.keys.toList()) {
            section[k] = value;
          }
          _editingAccess![sectionKey] = section;
        }
      });
    });
  }

  List<MapEntry<String, Map<String, bool>>> _parseAccessFromMap(
    Map<String, dynamic> accessMap,
  ) {
    final sections = <MapEntry<String, Map<String, bool>>>[];
    accessMap.forEach((sectionKey, sectionValue) {
      if (sectionValue is! Map) return;
      final fields = <String, bool>{};
      sectionValue.forEach((fieldKey, fieldValue) {
        if (fieldValue is bool) {
          fields[fieldKey] = fieldValue;
        }
      });
      if (fields.isNotEmpty) {
        sections.add(MapEntry(sectionKey, fields));
      }
    });
    return sections;
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final roleName = _readValue(role, 'roleName');
    final roleStatus = _readValue(role, 'roleStatus');
    final roleId = _readValue(role, 'roleId');
    final title = roleName.isEmpty ? 'Role' : roleName;
    final isEditing = _editingRoleId == roleId;
    final accessSections = isEditing && _editingAccess != null
        ? _parseAccessFromMap(_editingAccess!)
        : _parseAccessSections(role);
    final isStatusActive = roleStatus.toUpperCase() == 'ACTIVE';

    final isExpanded = _expandedRoleIds.contains(roleId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedRoleIds.add(roleId);
            } else {
              _expandedRoleIds.remove(roleId);
              // Cancel edit mode when tile collapses
              if (_editingRoleId == roleId) {
                _editingRoleId = null;
                _editingAccess = null;
                _updateError = null;
              }
            }
          });
        },
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Status: $roleStatus',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isEditing) ...[
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: (!isExpanded || _isUpdating)
                      ? null
                      : () => _handleUpdateAccess(role),
                  child: const Text(
                    'Update Access',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: _isUpdating
                      ? null
                      : () => _handleUpdateRoleStatus(
                          role,
                          isStatusActive ? 'INACTIVE' : 'ACTIVE',
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isStatusActive
                        ? const Color(0xFFB3261E)
                        : const Color(0xFF0F8F82),
                  ),
                  child: Text(
                    isStatusActive ? 'Disable' : 'Activate',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (_updateError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB3261E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB3261E)),
                ),
                child: Text(
                  _updateError!,
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          // Role-level "Select All" — only visible when editing
          if (isEditing && accessSections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Text(
                    'Select All Sections',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF124B45),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Builder(
                    builder: (context) {
                      // Compute tri-state across all fields
                      final allValues = <bool>[];
                      if (_editingAccess != null) {
                        _editingAccess!.forEach((_, sectionValue) {
                          if (sectionValue is Map) {
                            sectionValue.forEach((_, v) {
                              if (v is bool) allValues.add(v);
                            });
                          }
                        });
                      }
                      final allSelected =
                          allValues.isNotEmpty && allValues.every((v) => v);
                      final anySelected = allValues.any((v) => v);
                      final bool? triState = allSelected
                          ? true
                          : anySelected
                          ? null
                          : false;
                      return Checkbox(
                        value: triState,
                        tristate: true,
                        onChanged: (value) => _selectAllFields(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: WidgetStateBorderSide.resolveWith(
                          (states) => const BorderSide(
                            color: Color(0xFF0F8F82),
                            width: 1.8,
                          ),
                        ),
                        activeColor: const Color(0xFF0F8F82),
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          if (accessSections.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                const spacing = 10.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final rows = <Widget>[];
                for (var i = 0; i < accessSections.length; i += columns) {
                  final rowItems = accessSections.sublist(
                    i,
                    (i + columns).clamp(0, accessSections.length),
                  );
                  rows.add(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var j = 0; j < rowItems.length; j++) ...[
                          if (j > 0) const SizedBox(width: spacing),
                          SizedBox(
                            width: itemWidth,
                            child: _AccessSectionTile(
                              sectionKey: rowItems[j].key,
                              fields: rowItems[j].value,
                              isEditing: isEditing,
                              onFieldChanged: (fieldKey, value) =>
                                  _updateAccessField(
                                    rowItems[j].key,
                                    fieldKey,
                                    value,
                                  ),
                              onSelectAllChanged: (value) =>
                                  _selectAllSectionFields(
                                    rowItems[j].key,
                                    value,
                                  ),
                            ),
                          ),
                        ],
                        if (rowItems.length < columns)
                          SizedBox(
                            width:
                                (columns - rowItems.length) * itemWidth +
                                (columns - rowItems.length - 1).clamp(
                                      0,
                                      columns,
                                    ) *
                                    spacing,
                          ),
                      ],
                    ),
                  );
                  if (i + columns < accessSections.length) {
                    rows.add(const SizedBox(height: spacing));
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No access defined for this role.'),
            ),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isUpdating ? null : _cancelEditMode,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _handleUpdateRoleAccess(role),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Update'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadRoles, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRoles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (context, index) => _buildRoleCard(_roles[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildBody();
    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Manage Access',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Access'),
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: content,
    );
  }
}

/// Converts a camelCase access key to a readable label.
/// e.g. "createUpdateProfileAccess" → "Create Update Profile Access"
String _formatAccessKey(String key) {
  // Remove trailing 'Access' word if present
  var cleaned = key.replaceAll(RegExp(r'Access$'), '');
  if (cleaned.isEmpty) cleaned = key;
  // Insert spaces before uppercase letters
  final spaced = cleaned.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (m) => ' ${m[0]}',
  );
  final trimmed = spaced.trim();
  if (trimmed.isEmpty) return key;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

class _AccessSectionTile extends StatefulWidget {
  const _AccessSectionTile({
    required this.sectionKey,
    required this.fields,
    this.isEditing = false,
    this.onFieldChanged,
    this.onSelectAllChanged,
  });

  final String sectionKey;
  final Map<String, bool> fields;
  final bool isEditing;
  final Function(String fieldKey, bool value)? onFieldChanged;
  final Function(bool value)? onSelectAllChanged;

  @override
  State<_AccessSectionTile> createState() => _AccessSectionTileState();
}

class _AccessSectionTileState extends State<_AccessSectionTile> {
  bool _isExpanded = false;

  Checkbox _styledCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
    bool tristate = false,
  }) {
    return Checkbox(
      value: value,
      tristate: tristate,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: WidgetStateBorderSide.resolveWith(
        (states) => const BorderSide(color: Color(0xFF0F8F82), width: 1.8),
      ),
      activeColor: const Color(0xFF0F8F82),
      checkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentAccess = widget.fields['parentAccess'] ?? false;
    final childFields = Map.of(widget.fields)..remove('parentAccess');
    final sectionLabel = _formatAccessKey(widget.sectionKey);

    // Compute section-level select-all state (tristate: all/none/some)
    final allChildValues = childFields.values.toList();
    final allChildSelected =
        allChildValues.isNotEmpty && allChildValues.every((v) => v);
    final anyChildSelected = allChildValues.any((v) => v);
    final sectionAllSelected = allChildSelected && parentAccess;
    final sectionAnySelected = anyChildSelected || parentAccess;
    // tri-state: null = some, true = all, false = none
    final bool? sectionSelectAllValue = sectionAllSelected
        ? true
        : sectionAnySelected
        ? null
        : false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: const Color(0xFFF5F8F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFD0E4E1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          title: Row(
            children: [
              widget.isEditing
                  ? _styledCheckbox(
                      value: parentAccess,
                      onChanged: (value) {
                        if (value != null && widget.onFieldChanged != null) {
                          widget.onFieldChanged!('parentAccess', value);
                        }
                      },
                    )
                  : IgnorePointer(
                      child: _styledCheckbox(
                        value: parentAccess,
                        onChanged: null,
                      ),
                    ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sectionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Section-level Select All — only visible when expanded and editing
              if (_isExpanded && widget.isEditing && childFields.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'All',
                      style: TextStyle(fontSize: 11, color: Color(0xFF124B45)),
                    ),
                    _styledCheckbox(
                      value: sectionSelectAllValue,
                      tristate: true,
                      onChanged: (value) {
                        if (widget.onSelectAllChanged != null) {
                          widget.onSelectAllChanged!(value ?? true);
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
          children: childFields.isEmpty
              ? const [SizedBox.shrink()]
              : childFields.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
                        child: Row(
                          children: [
                            widget.isEditing
                                ? _styledCheckbox(
                                    value: e.value,
                                    onChanged: (value) {
                                      if (value != null &&
                                          widget.onFieldChanged != null) {
                                        widget.onFieldChanged!(e.key, value);
                                      }
                                    },
                                  )
                                : IgnorePointer(
                                    child: _styledCheckbox(
                                      value: e.value,
                                      onChanged: null,
                                    ),
                                  ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatAccessKey(e.key),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }
}

class _RoleDetailRow extends StatelessWidget {
  const _RoleDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class ReportsManagementPage extends StatelessWidget {
  const ReportsManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ReportsDashboardPage(embedded: embedded);
  }
}

class OthersManagementPage extends StatelessWidget {
  const OthersManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.others,
      title: 'Others',
      subtitle: 'Choose one of the additional service categories below.',
      items: const [
        _ModuleHubItem('Lost And Found', Icons.search),
        _ModuleHubItem('Store', Icons.shopping_bag),
        _ModuleHubItem('Paid Service', Icons.miscellaneous_services),
      ],
    );
  }
}

class FinanceManagementPage extends StatefulWidget {
  const FinanceManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FinanceManagementPage> createState() => _FinanceManagementPageState();
}

class _FinanceManagementPageState extends State<FinanceManagementPage> {
  bool _showCreatePayment = false;
  bool _showViewPayments = false;
  bool _showCreateLedgerEntry = false;
  bool _showCreateReceipt = false;
  bool _showViewTransactions = false;
  bool _loadingDueDetails = false;

  String _formatCurrencyWithCommas(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '0';

    final isNegative = trimmed.startsWith('-');
    final unsignedValue = isNegative ? trimmed.substring(1) : trimmed;
    final parts = unsignedValue.split('.');
    final integerPart = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    if (integerPart.isEmpty) return value;

    final buffer = StringBuffer();
    for (var index = 0; index < integerPart.length; index++) {
      final reverseIndex = integerPart.length - index;
      buffer.write(integerPart[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    final decimalPart = parts.length > 1
        ? '.${parts.sublist(1).join().replaceAll(RegExp(r'[^0-9]'), '')}'
        : '';
    return '${isNegative ? '-' : ''}${buffer.toString()}$decimalPart';
  }

  String _formatAsCurrency(String amount) {
    final cleaned = amount.trim();
    if (cleaned.isEmpty) return '₹0';

    final rawAmount = cleaned.startsWith('₹') ? cleaned.substring(1) : cleaned;
    return '₹${_formatCurrencyWithCommas(rawAmount)}';
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB3261E) : null,
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _dueDetailsByPaymentFromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawDetails = response?['dueDetails'];
    if (rawDetails is! Map) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final result = <String, List<Map<String, dynamic>>>{};
    rawDetails.forEach((key, rawValue) {
      final list = <Map<String, dynamic>>[];

      if (rawValue is List) {
        for (final item in rawValue.whereType<Map>()) {
          list.add(Map<String, dynamic>.from(item));
        }
      } else if (rawValue is Map) {
        list.add(Map<String, dynamic>.from(rawValue));
      }

      if (list.isNotEmpty) {
        result[key.toString()] = list;
      }
    });

    return result;
  }

  List<Map<String, dynamic>> _flattenDueDetailsByPayment(
    Map<String, List<Map<String, dynamic>>> dueDetailsByPayment,
  ) {
    final flatList = <Map<String, dynamic>>[];
    for (final entries in dueDetailsByPayment.values) {
      for (final entry in entries) {
        flatList.add(Map<String, dynamic>.from(entry));
      }
    }
    return flatList;
  }

  Future<void> _openDuePaymentsDialog() async {
    if (_loadingDueDetails) {
      return;
    }

    setState(() {
      _loadingDueDetails = true;
    });

    try {
      final response = await ApiService.getDueAmountForFlat();
      final duePaymentList = response?['duePaymentList'];
      final dueDetailsByPayment = _dueDetailsByPaymentFromResponse(response);
      if (!mounted) {
        return;
      }

      final normalizedDueList = duePaymentList is List
          ? duePaymentList
          : const <dynamic>[];
      final displayDueList = normalizedDueList.isNotEmpty
          ? normalizedDueList
          : _flattenDueDetailsByPayment(dueDetailsByPayment);

      if (displayDueList.isEmpty && dueDetailsByPayment.isEmpty) {
        _showSnack('No due payments found.');
        return;
      }

      await showDialog<void>(
        context: context,
        useRootNavigator: false,
        builder: (_) => PaymentDetailsModal(
          duePaymentList: displayDueList,
          dueDetailsByPayment: dueDetailsByPayment,
          formatAsCurrency: _formatAsCurrency,
          onPaymentCompleted: () async {
            if (!mounted) {
              return;
            }
            _showSnack('Payment completed successfully.');
          },
        ),
      );
    } catch (_) {
      _showSnack('Unable to load due payment details.', isError: true);
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingDueDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCreatePayment) {
      return CreatePaymentPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showCreatePayment = false;
          });
        },
      );
    }

    if (_showViewPayments) {
      return ViewUpdatePaymentsPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showViewPayments = false;
          });
        },
      );
    }

    if (_showCreateLedgerEntry) {
      return CreateLedgerEntryPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showCreateLedgerEntry = false;
          });
        },
      );
    }

    if (_showCreateReceipt) {
      return CreateReceiptPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showCreateReceipt = false;
          });
        },
      );
    }

    if (_showViewTransactions) {
      return ViewTransactionsPage(
        embedded: widget.embedded,
        onBack: () {
          setState(() {
            _showViewTransactions = false;
          });
        },
      );
    }

    final canLedgerEntry = _hasAccessFlag('financeAccess', 'ledgerEntryAccess');
    final canCreatePayment = _hasAccessFlag(
      'financeAccess',
      'createNewPaymentAccess',
    );
    final canUpdatePayment = _hasAccessFlag(
      'financeAccess',
      'updatePaymentAccess',
    );
    final canCreateReceipt = _hasAccessFlag(
      'financeAccess',
      'createReceiptAccess',
    );
    final canUploadPastPayments = _hasAccessFlag(
      'financeAccess',
      'uploadPastPaymentAccess',
    );
    final canReconcile = _hasAccessFlag(
      'financeAccess',
      'reconcilePaymentAccess',
    );
    final canBudget = _hasAccessFlag('financeAccess', 'budgetManagment');

    final items = <_ModuleHubItem>[
      if (canLedgerEntry)
        _ModuleHubItem(
          'Ledger Entry',
          Icons.credit_card_off,
          onTap: () {
            setState(() {
              _showCreateLedgerEntry = true;
            });
          },
        ),
      if (canCreatePayment)
        _ModuleHubItem(
          'Create New Payment',
          Icons.payment,
          onTap: () {
            setState(() {
              _showCreatePayment = true;
            });
          },
        ),
      if (canUpdatePayment)
        _ModuleHubItem(
          'View/Update Payments',
          Icons.account_balance,
          onTap: () {
            setState(() {
              _showViewPayments = true;
            });
          },
        ),
      _ModuleHubItem(
        _loadingDueDetails ? 'Loading Dues...' : 'Pay Dues',
        Icons.currency_rupee,
        onTap: _loadingDueDetails ? null : _openDuePaymentsDialog,
      ),
      if (canCreateReceipt)
        _ModuleHubItem(
          'Create Receipt',
          Icons.receipt_long_outlined,
          onTap: () {
            setState(() {
              _showCreateReceipt = true;
            });
          },
        ),
      _ModuleHubItem(
        'View Transactions',
        Icons.receipt_outlined,
        onTap: () {
          setState(() {
            _showViewTransactions = true;
          });
        },
      ),
      if (canUploadPastPayments)
        _ModuleHubItem(
          'Upload Other Due Payments',
          Icons.upload_file_rounded,
          onTap: () {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const _UploadOtherDuesDialog(),
            );
          },
        ),
      if (canReconcile)
        _ModuleHubItem(
          'Reconcile QR Payments',
          Icons.qr_code_scanner_rounded,
          onTap: () {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const _ReconcileQrPaymentsDialog(),
            );
          },
        ),
      if (canBudget)
        const _ModuleHubItem('Budget Management', Icons.assessment_rounded),
    ];

    return _ModuleHubPage(
      embedded: widget.embedded,
      section: AppSection.finance,
      title: 'Finance',
      subtitle: 'Choose one of the finance actions below.',
      items: items,
    );
  }
}

class _UploadOtherDuesDialog extends StatefulWidget {
  const _UploadOtherDuesDialog();

  @override
  State<_UploadOtherDuesDialog> createState() => _UploadOtherDuesDialogState();
}

class _UploadOtherDuesDialogState extends State<_UploadOtherDuesDialog> {
  final TextEditingController _fileController = TextEditingController();
  bool _downloadingSample = false;
  bool _downloadingResponseFile = false;
  bool _uploading = false;
  String? _selectedFileName;
  String? _selectedFileBase64;
  String? _uploadMessage;
  int? _successRows;
  int? _failedRows;
  String? _responseFileBase64;

  // Dropdown data for sample Excel
  List<String> _collectionTypes = [];
  List<String> _bankAccountIds = [];
  late Future<void> _dataFetchFuture;

  @override
  void initState() {
    super.initState();
    _dataFetchFuture = _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    // Fetch collection types independently so a bank-details failure doesn't
    // also lose the collection types (and vice-versa).
    try {
      final response = await ApiService.getSocietyCollectionTypes();
      if (mounted && response != null) {
        final rawList = response['societyCollectionTypes'];
        if (rawList is List) {
          final types = rawList
              .whereType<Map>()
              .map((item) => item['collectionType']?.toString().trim() ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          if (mounted) setState(() => _collectionTypes = types);
        }
      }
    } catch (_) {}

    try {
      final response = await ApiService.getBankDetails();
      if (mounted && response != null) {
        final rawList = response['bankAccountDetails'];
        if (rawList is List) {
          final ids = rawList
              .whereType<Map>()
              .map((item) => item['BankDetailsID']?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          if (mounted) setState(() => _bankAccountIds = ids);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fileController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnackBar('Unable to read the selected Excel file.');
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFileBase64 = base64Encode(bytes);
      _fileController.text = file.name;
    });
  }

  List<String> _extractSharedStrings(Archive archive) {
    final shared = archive.files.where((file) {
      return file.isFile && file.name == 'xl/sharedStrings.xml';
    }).toList();
    if (shared.isEmpty) {
      return const <String>[];
    }

    final content = shared.first.content as List<int>;

    final document = XmlDocument.parse(utf8.decode(content));
    final values = <String>[];
    final items = document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'si',
    );

    for (final item in items) {
      final parts = item.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText)
          .toList();
      values.add(parts.join());
    }

    return values;
  }

  XmlElement? _cellByColumn(XmlElement rowElement, String columnLetter) {
    for (final cell in rowElement.children.whereType<XmlElement>().where(
      (element) => element.name.local == 'c',
    )) {
      final reference = cell.getAttribute('r')?.trim() ?? '';
      if (reference.startsWith(columnLetter)) {
        return cell;
      }
    }
    return null;
  }

  double? _parseCellToDouble(XmlElement? cell, List<String> sharedStrings) {
    if (cell == null) {
      return null;
    }

    final type = cell.getAttribute('t')?.trim() ?? '';
    final valueNode = cell.children.whereType<XmlElement>().firstWhere(
      (element) => element.name.local == 'v',
      orElse: () => XmlElement(XmlName('v')),
    );
    final rawValue = valueNode.innerText.trim();

    String parsedSource = rawValue;
    if (type == 's' && rawValue.isNotEmpty) {
      final sharedIndex = int.tryParse(rawValue);
      if (sharedIndex != null &&
          sharedIndex >= 0 &&
          sharedIndex < sharedStrings.length) {
        parsedSource = sharedStrings[sharedIndex];
      }
    }

    if (parsedSource.isEmpty) {
      final inlineText = cell.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText)
          .join()
          .trim();
      parsedSource = inlineText;
    }

    if (parsedSource.isEmpty) {
      return null;
    }

    final normalized = parsedSource.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(normalized);
  }

  bool _replaceFormulaWithValue(
    XmlDocument document,
    List<String> sharedStrings,
  ) {
    var updated = false;

    final rows = document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'row',
    );

    for (final row in rows) {
      final rowNumber = int.tryParse(row.getAttribute('r')?.trim() ?? '');
      if (rowNumber == null || rowNumber < 2) {
        continue;
      }

      final totalCell = _cellByColumn(row, 'G');
      if (totalCell == null) {
        continue;
      }

      final formulaElements = totalCell.children
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'f')
          .toList();
      if (formulaElements.isEmpty) {
        continue;
      }

      final dueAmount = _parseCellToDouble(
        _cellByColumn(row, 'E'),
        sharedStrings,
      );
      final gstPercent =
          _parseCellToDouble(_cellByColumn(row, 'F'), sharedStrings) ?? 0;

      for (final formula in formulaElements) {
        formula.parent?.children.remove(formula);
      }

      totalCell.removeAttribute('t');

      final valueElements = totalCell.children
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'v')
          .toList();

      if (dueAmount == null) {
        for (final valueElement in valueElements) {
          valueElement.parent?.children.remove(valueElement);
        }
        updated = true;
        continue;
      }

      final totalDue = dueAmount + (dueAmount * gstPercent / 100);
      final totalDueText = totalDue.toStringAsFixed(2);

      if (valueElements.isNotEmpty) {
        valueElements.first.innerText = totalDueText;
      } else {
        totalCell.children.add(
          XmlElement(XmlName('v'), [], [XmlText(totalDueText)]),
        );
      }

      updated = true;
    }

    return updated;
  }

  String _sanitizeUploadExcelBase64(String fileName, String fileBase64) {
    final normalizedName = fileName.trim().toLowerCase();
    if (!normalizedName.endsWith('.xlsx')) {
      return fileBase64;
    }

    try {
      final bytes = base64Decode(fileBase64);
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final sharedStrings = _extractSharedStrings(archive);
      final updatedEntries = <String, List<int>>{};
      var changed = false;

      for (final file in archive.files) {
        if (!file.isFile) {
          continue;
        }
        final content = file.content as List<int>;

        if (file.name.startsWith('xl/worksheets/sheet') &&
            file.name.endsWith('.xml')) {
          final document = XmlDocument.parse(utf8.decode(content));
          final updated = _replaceFormulaWithValue(document, sharedStrings);
          if (updated) {
            updatedEntries[file.name] = utf8.encode(
              document.toXmlString(pretty: false),
            );
            changed = true;
          }
        }
      }

      if (!changed) {
        return fileBase64;
      }

      final sanitized = Archive();
      for (final file in archive.files) {
        if (!file.isFile) {
          continue;
        }
        final originalContent = file.content as List<int>;
        final outputContent = updatedEntries[file.name] ?? originalContent;
        sanitized.addFile(
          ArchiveFile(file.name, outputContent.length, outputContent),
        );
      }

      final outputBytes = ZipEncoder().encode(sanitized);
      if (outputBytes.isEmpty) {
        return fileBase64;
      }

      return base64Encode(outputBytes);
    } catch (_) {
      return fileBase64;
    }
  }

  Future<void> _downloadSampleExcel() async {
    if (_downloadingSample) {
      return;
    }
    _downloadingSample = true;

    // Ensure dropdown data is ready before generating the Excel file.
    // If _fetchDropdownData has already completed this returns immediately;
    // if it is still in flight we wait for it so the dropdowns are populated.
    await _dataFetchFuture;

    xlsio.Workbook? workbook;

    try {
      workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Due Details';

      final headers = <String>[
        'Flat Id',
        'Due From',
        'Due Till',
        'Due Cause',
        'Due Amount',
        'GST%',
        'Total Due Amount',
        'Cause',
        'BankAccountID',
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      final headerRange = sheet.getRangeByIndex(1, 1, 1, headers.length);
      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.backColor = '#FFF3CD';

      sheet.getRangeByIndex(2, 1).setText('A-101');
      sheet.getRangeByIndex(2, 2).setText('1-Mar-2026');
      sheet.getRangeByIndex(2, 3).setText('31-Mar-2026');
      sheet.getRangeByIndex(2, 4).setText('Maintenance');
      sheet.getRangeByIndex(2, 5).setNumber(2500);
      sheet.getRangeByIndex(2, 6).setNumber(18);
      sheet.getRangeByIndex(2, 7).formula = '=IF(E2="","",E2+(E2*F2/100))';

      sheet.getRangeByName('E2:E200').numberFormat = '0.00';
      sheet.getRangeByName('F2:F200').numberFormat = '0.00';
      sheet.getRangeByName('G2:G200').numberFormat = '0.00';

      // Write dropdown source values into a hidden sheet to avoid Excel's
      // 255-character formula1 limit that applies to inline list validation.
      // Using a range reference (dataRange) has no such limit.
      if (_collectionTypes.isNotEmpty || _bankAccountIds.isNotEmpty) {
        final dropSheet = workbook.worksheets.addWithName('_Dropdowns');
        dropSheet.visibility = xlsio.WorksheetVisibility.hidden;

        // Column A — Cause values
        for (var i = 0; i < _collectionTypes.length; i++) {
          dropSheet.getRangeByIndex(i + 1, 1).setText(_collectionTypes[i]);
        }

        // Column B — BankAccountID values
        for (var i = 0; i < _bankAccountIds.length; i++) {
          dropSheet.getRangeByIndex(i + 1, 2).setText(_bankAccountIds[i]);
        }

        // Cause dropdown (col H) → reference _Dropdowns column A
        if (_collectionTypes.isNotEmpty) {
          final causeValidation = sheet
              .getRangeByName('H2:H200')
              .dataValidation;
          causeValidation.allowType = xlsio.ExcelDataValidationType.user;
          causeValidation.dataRange = dropSheet.getRangeByIndex(
            1,
            1,
            _collectionTypes.length,
            1,
          );
        }

        // BankAccountID dropdown (col I) → reference _Dropdowns column B
        if (_bankAccountIds.isNotEmpty) {
          final bankValidation = sheet.getRangeByName('I2:I200').dataValidation;
          bankValidation.allowType = xlsio.ExcelDataValidationType.user;
          bankValidation.dataRange = dropSheet.getRangeByIndex(
            1,
            2,
            _bankAccountIds.length,
            2,
          );
        }
      }

      // Keep all cells editable in the downloaded sample.

      for (var col = 1; col <= headers.length; col++) {
        sheet.autoFitColumn(col);
      }

      final bytes = workbook.saveAsStream();
      if (bytes.isEmpty) {
        throw StateError('Generated sample Excel is empty.');
      }

      final downloaded = await downloadBase64Receipt(
        base64Data: base64Encode(bytes),
        fileName: 'due_details_sample.xlsx',
      );

      if (!mounted) {
        return;
      }
      if (!downloaded) {
        _showSnackBar(
          'Unable to download the sample Excel file. Downloader returned false.',
        );
        return;
      }
      _showSnackBar('Sample Excel downloaded successfully.');
    } catch (error, stackTrace) {
      debugPrint('UploadOtherDues sample download failed: $error\n$stackTrace');
      if (mounted) {
        _showSnackBar('Unable to download sample Excel: $error');
      }
    } finally {
      workbook?.dispose();
      _downloadingSample = false;
    }
  }

  Future<void> _handleUpload() async {
    if (_uploading || _downloadingSample) {
      return;
    }

    if ((_selectedFileName ?? '').trim().isEmpty ||
        (_selectedFileBase64 ?? '').trim().isEmpty) {
      _showSnackBar('Please choose an Excel document first.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadMessage = null;
      _successRows = null;
      _failedRows = null;
      _responseFileBase64 = null;
    });

    try {
      final sanitizedFileBase64 = _sanitizeUploadExcelBase64(
        _selectedFileName ?? '',
        _selectedFileBase64!,
      );
      final response = await ApiService.uploadPastDue(
        fileBase64: sanitizedFileBase64,
      );

      if (!mounted) {
        return;
      }

      if (response == null) {
        _showSnackBar('Unable to upload due details. Empty server response.');
        return;
      }

      final messageCode = response['messageCode']?.toString().trim() ?? '';
      final message =
          response['message']?.toString().trim() ??
          response['statusMessage']?.toString().trim() ??
          response['errorMessage']?.toString().trim() ??
          '';
      final successRows = _readIntValue(response['successRows']);
      final failedRows = _readIntValue(response['failedRows']);
      final responseFile = response['file']?.toString().trim() ?? '';
      final upperMessageCode = messageCode.toUpperCase();
      final headerStatus = response['genericHeader'] is Map
          ? response['genericHeader']['status']?.toString().trim().toUpperCase()
          : '';
      final isSuccess =
          upperMessageCode.startsWith('SUCC') ||
          upperMessageCode.contains('SUCCESS') ||
          headerStatus == 'SUCCESS';

      setState(() {
        _uploadMessage = message.isNotEmpty
            ? message
            : (isSuccess
                  ? 'Past due upload processed successfully.'
                  : 'Unable to upload due details.');
        _successRows = successRows;
        _failedRows = failedRows;
        _responseFileBase64 = responseFile.isEmpty ? null : responseFile;
      });

      if (isSuccess) {
        _showSnackBar('Due details uploaded successfully.');
        return;
      }

      _showSnackBar('Unable to upload due details.');
    } catch (error, stackTrace) {
      debugPrint('UploadOtherDues upload failed: $error\n$stackTrace');
      if (mounted) {
        _showSnackBar('Unable to upload due details: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  int? _readIntValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _downloadResponseFile() async {
    if (_downloadingResponseFile ||
        (_responseFileBase64 ?? '').trim().isEmpty) {
      return;
    }

    setState(() {
      _downloadingResponseFile = true;
    });

    try {
      final downloaded = await downloadBase64Receipt(
        base64Data: _responseFileBase64!,
        fileName: 'past_due_upload_errors.xlsx',
      );

      if (!mounted) {
        return;
      }

      if (!downloaded) {
        _showSnackBar('Unable to download response error file.');
        return;
      }

      _showSnackBar('Response error file downloaded successfully.');
    } catch (error, stackTrace) {
      debugPrint(
        'UploadOtherDues response file download failed: $error\n$stackTrace',
      );
      if (mounted) {
        _showSnackBar('Unable to download response error file: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingResponseFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _ModuleHubPage._brandColor, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(18, 75, 69, 0.14),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F8F82), Color(0xFF15766A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.request_quote_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Other Dues',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Upload due details Excel and validate format using sample file.',
                                style: TextStyle(
                                  color: Color(0xFFE9FAF6),
                                  height: 1.35,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: _downloadingSample
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD4EAE4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Document',
                          style: TextStyle(
                            color: _ModuleHubPage._brandTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _fileController,
                          readOnly: true,
                          onTap: _downloadingSample || _uploading
                              ? null
                              : _pickExcelFile,
                          decoration: InputDecoration(
                            labelText: 'Excel file',
                            hintText: 'Select .xlsx or .xls file',
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              onPressed: _downloadingSample || _uploading
                                  ? null
                                  : _pickExcelFile,
                              icon: const Icon(Icons.attach_file),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBFDCD5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _ModuleHubPage._brandColor,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_uploadMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3FAF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCFE5DF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _uploadMessage!,
                            style: const TextStyle(
                              color: _ModuleHubPage._brandTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: [
                              Text('Success Entry: ${_successRows ?? 0}'),
                              Text('Failed Entry: ${_failedRows ?? 0}'),
                            ],
                          ),
                          if ((_responseFileBase64 ?? '')
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _downloadingResponseFile || _uploading
                                    ? null
                                    : _downloadResponseFile,
                                icon: _downloadingResponseFile
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download_outlined),
                                label: Text(
                                  _downloadingResponseFile
                                      ? 'Downloading...'
                                      : 'Download Error File',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _downloadingSample ||
                                  _uploading ||
                                  _downloadingResponseFile
                              ? null
                              : _downloadSampleExcel,
                          icon: _downloadingSample
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          label: Text(
                            _downloadingSample
                                ? 'Downloading...'
                                : 'Download Sample Excel',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ModuleHubPage._brandColor,
                            backgroundColor: const Color(0xFFEFF8F5),
                            side: BorderSide(
                              color: _ModuleHubPage._brandColor.withValues(
                                alpha: 0.42,
                              ),
                            ),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _downloadingSample ||
                                  _uploading ||
                                  _downloadingResponseFile
                              ? null
                              : _handleUpload,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(_uploading ? 'Uploading...' : 'Upload'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _ModuleHubPage._brandColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReconcileQrPaymentsDialog extends StatefulWidget {
  const _ReconcileQrPaymentsDialog();

  @override
  State<_ReconcileQrPaymentsDialog> createState() =>
      _ReconcileQrPaymentsDialogState();
}

class _ReconcileQrPaymentsDialogState
    extends State<_ReconcileQrPaymentsDialog> {
  final TextEditingController _fileController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  bool _uploading = false;
  String? _selectedFileName;
  String? _selectedFileBase64;

  @override
  void dispose() {
    _fileController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB3261E) : null,
      ),
    );
  }

  String _formatPickerDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text.trim()) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF0F8F82),
              onPrimary: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return;
    }

    controller.text = _formatPickerDate(picked);
  }

  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnackBar('Unable to read the selected Excel file.', isError: true);
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFileBase64 = base64Encode(bytes);
      _fileController.text = file.name;
    });
  }

  Future<void> _submit() async {
    if (_uploading) {
      return;
    }

    if ((_selectedFileBase64 ?? '').trim().isEmpty) {
      _showSnackBar('Please upload an Excel file first.', isError: true);
      return;
    }

    setState(() {
      _uploading = true;
    });

    final hostContext = Navigator.of(context, rootNavigator: true).context;

    try {
      final fromDate = _fromDateController.text.trim();
      final toDate = _toDateController.text.trim();
      final response = await ApiService.reconcileQrPayment(
        fromDate: fromDate,
        toDate: toDate,
        base64EncodedStatementFile: _selectedFileBase64!,
      );

      if (!mounted) {
        return;
      }

      if (response == null) {
        _showSnackBar('Unable to reconcile QR payments.', isError: true);
        return;
      }

      final messageCode = response['messageCode']?.toString().trim() ?? '';
      final isSuccess =
          messageCode.toUpperCase().contains('SUCC') ||
          messageCode.toUpperCase().contains('SUCCESS');
      final foundRaw = response['foundCount'];
      final foundCount = foundRaw is int
          ? foundRaw
          : (foundRaw is num
                ? foundRaw.toInt()
                : int.tryParse(foundRaw?.toString() ?? '') ?? 0);
      final foundRowsRaw = response['foundTransactionsList'];
      final foundRowsCount = foundRowsRaw is List ? foundRowsRaw.length : 0;
      final shouldShowResultModal =
          isSuccess || foundCount > 0 || foundRowsCount > 0;
      if (!shouldShowResultModal) {
        _showSnackBar(
          response['message']?.toString().trim().isNotEmpty == true
              ? response['message'].toString()
              : 'Unable to reconcile QR payments.',
          isError: true,
        );
        return;
      }

      Navigator.of(context).pop();
      await showDialog<void>(
        context: hostContext,
        barrierDismissible: false,
        builder: (_) => _ReconcileQrResultDialog(
          response: response,
          fromDate: fromDate,
          toDate: toDate,
          base64EncodedStatementFile: _selectedFileBase64!,
        ),
      );
    } catch (error) {
      _showSnackBar('Unable to reconcile QR payments: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FBFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD6E7E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F8F82), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _ModuleHubPage._brandColor, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(18, 75, 69, 0.14),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F8F82), Color(0xFF15766A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reconcile QR Payments',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Please Upload Bank Statement In .xlsx Format',
                              style: TextStyle(
                                color: Color(0xFFE9FAF6),
                                height: 1.35,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _uploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _fileController,
                  readOnly: true,
                  decoration: _decoration('Upload File').copyWith(
                    suffixIcon: IconButton(
                      onPressed: _uploading ? null : _pickExcelFile,
                      icon: const Icon(Icons.upload_file_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromDateController,
                        readOnly: true,
                        onTap: _uploading
                            ? null
                            : () => _pickDate(_fromDateController),
                        decoration: _decoration('From Date').copyWith(
                          suffixIcon: const Icon(Icons.calendar_month_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _toDateController,
                        readOnly: true,
                        onTap: _uploading
                            ? null
                            : () => _pickDate(_toDateController),
                        decoration: _decoration('To Date').copyWith(
                          suffixIcon: const Icon(Icons.calendar_month_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                if ((_selectedFileName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Selected file: $_selectedFileName',
                    style: const TextStyle(
                      color: Color(0xFF506461),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _uploading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _uploading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F8F82),
                        foregroundColor: Colors.white,
                      ),
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.playlist_add_check_rounded),
                      label: Text(_uploading ? 'Processing...' : 'Upload'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ReconcileQrTab { found, notFound }

class _ReconcileQrResultDialog extends StatefulWidget {
  const _ReconcileQrResultDialog({
    required this.response,
    required this.fromDate,
    required this.toDate,
    required this.base64EncodedStatementFile,
  });

  final Map<String, dynamic> response;
  final String fromDate;
  final String toDate;
  final String base64EncodedStatementFile;

  @override
  State<_ReconcileQrResultDialog> createState() =>
      _ReconcileQrResultDialogState();
}

class _ReconcileQrResultDialogState extends State<_ReconcileQrResultDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Map<String, dynamic> _latestResponse;
  final Set<String> _selectedFoundIds = <String>{};
  final Set<String> _selectedNotFoundIds = <String>{};
  bool _downloadingFile = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _latestResponse = Map<String, dynamic>.from(widget.response);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _readRows(String key) {
    final raw = _latestResponse[key];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  List<Map<String, dynamic>> get _foundRows =>
      _readRows('foundTransactionsList');
  List<Map<String, dynamic>> get _notFoundRows =>
      _readRows('notFoundTransactionsList');

  Set<String> _selectionSet(_ReconcileQrTab tab) {
    return tab == _ReconcileQrTab.found
        ? _selectedFoundIds
        : _selectedNotFoundIds;
  }

  List<Map<String, dynamic>> _rowsForTab(_ReconcileQrTab tab) {
    return tab == _ReconcileQrTab.found ? _foundRows : _notFoundRows;
  }

  String _rowId(Map<String, dynamic> row) {
    final trnscId = row['trnscId']?.toString().trim() ?? '';
    if (trnscId.isNotEmpty) {
      return trnscId;
    }
    return row.hashCode.toString();
  }

  String _formatTxnDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '--';
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return trimmed;
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
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day}-${months[parsed.month - 1]}-${parsed.year} ${parsed.hour}:$minute';
  }

  String _displayValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '--';
    }
    return text;
  }

  String _formatAmount(dynamic value) {
    final amount = _displayValue(value);
    if (amount == '--') {
      return amount;
    }
    return amount.startsWith('₹') ? amount : '₹$amount';
  }

  int _countValue(String key, int fallback) {
    final value = _latestResponse[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String? get _highlightedFile {
    final direct =
        _latestResponse['highlithedBase64EncodedFile']?.toString().trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }
    final alternate =
        _latestResponse['highlightedBase64EncodedFile']?.toString().trim() ??
        '';
    return alternate.isEmpty ? null : alternate;
  }

  Future<void> _refreshReconcileResultAfterAction() async {
    final refreshed = await ApiService.reconcileQrPayment(
      fromDate: widget.fromDate,
      toDate: widget.toDate,
      base64EncodedStatementFile: widget.base64EncodedStatementFile,
    );

    if (!mounted) {
      return;
    }

    if (refreshed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to refresh QR reconciliation results.'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
      return;
    }

    final refreshedMap = Map<String, dynamic>.from(refreshed);
    final foundCount = _parseCount(
      refreshedMap['foundCount'],
      refreshedMap['foundTransactionsList'],
    );
    final notFoundCount = _parseCount(
      refreshedMap['notFoundCount'],
      refreshedMap['notFoundTransactionsList'],
    );

    setState(() {
      _latestResponse = refreshedMap;
      _selectedFoundIds.clear();
      _selectedNotFoundIds.clear();
      _tabController.animateTo(0);
    });

    if (foundCount == 0 && notFoundCount == 0) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _AllPendingQrAcknowledgedDialog(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  int _parseCount(dynamic rawCount, dynamic rawList) {
    if (rawCount is int) {
      return rawCount;
    }
    if (rawCount is num) {
      return rawCount.toInt();
    }
    final parsed = int.tryParse(rawCount?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
    if (rawList is List) {
      return rawList.length;
    }
    return 0;
  }

  bool get _hasActiveSelection {
    final currentTab = _tabController.index == 0
        ? _ReconcileQrTab.found
        : _ReconcileQrTab.notFound;
    return _selectionSet(currentTab).isNotEmpty;
  }

  void _toggleSelectAll(_ReconcileQrTab tab, bool? checked) {
    final rows = _rowsForTab(tab);
    final target = _selectionSet(tab);
    setState(() {
      if (checked == true) {
        target
          ..clear()
          ..addAll(rows.map(_rowId));
      } else {
        target.clear();
      }
    });
  }

  void _toggleRow(_ReconcileQrTab tab, String rowId, bool? checked) {
    final target = _selectionSet(tab);
    setState(() {
      if (checked == true) {
        target.add(rowId);
      } else {
        target.remove(rowId);
      }
    });
  }

  Future<void> _downloadFile() async {
    final file = _highlightedFile;
    if (_downloadingFile || file == null || file.isEmpty) {
      return;
    }

    setState(() {
      _downloadingFile = true;
    });

    try {
      final downloaded = await downloadBase64Receipt(
        base64Data: file,
        fileName: 'reconciled_qr_sheet.xlsx',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Reconciled sheet downloaded successfully.'
                : 'Unable to download reconciled sheet.',
          ),
          backgroundColor: downloaded ? null : const Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFile = false;
        });
      }
    }
  }

  Future<void> _handleSelectionAction(String actionLabel) async {
    if (_actionInProgress) {
      return;
    }

    final currentTab = _tabController.index == 0
        ? _ReconcileQrTab.found
        : _ReconcileQrTab.notFound;
    final selectedIds = _selectionSet(currentTab);
    final selectedRows = _rowsForTab(currentTab)
        .where((row) => selectedIds.contains(_rowId(row)))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    if (selectedRows.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one transaction.'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
      return;
    }

    setState(() {
      _actionInProgress = true;
    });

    try {
      final action = actionLabel.trim().toUpperCase();
      final response = await ApiService.actionQrPayment(
        transactionsList: selectedRows,
        action: action,
      );

      if (!mounted) {
        return;
      }

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to process selected QR transactions.'),
            backgroundColor: Color(0xFFB3261E),
          ),
        );
        return;
      }

      final acknowledged =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _QrPaymentActionResultDialog(response: response),
          ) ??
          false;

      if (acknowledged) {
        await _refreshReconcileResultAfterAction();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to process selected QR transactions.'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
        });
      }
    }
  }

  Widget _buildTabTable(_ReconcileQrTab tab) {
    final rows = _rowsForTab(tab);
    final selected = _selectionSet(tab);
    final allSelected = rows.isNotEmpty && selected.length == rows.length;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          tab == _ReconcileQrTab.found
              ? 'No found transactions.'
              : 'No not found transactions.',
          style: const TextStyle(color: Color(0xFF647775)),
        ),
      );
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              Container(
                width: 1180,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD5E7E3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Checkbox(
                        value: allSelected,
                        tristate: false,
                        onChanged: (value) => _toggleSelectAll(tab, value),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Flat ID',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Transaction ID',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Payment Id',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Transaction Type',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Bank Id',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Amount',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Transaction Date',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = rows[index];
              final id = _rowId(row);
              final isChecked = selected.contains(id);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 1180,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCEAE7)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Checkbox(
                          value: isChecked,
                          onChanged: (value) => _toggleRow(tab, id, value),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_displayValue(row['flatId'])),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_displayValue(row['trnscId'])),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_displayValue(row['pymntId'])),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_displayValue(row['trnsType'])),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_displayValue(row['trnsBnkAccnt'])),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_formatAmount(row['trnsAmt'])),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatTxnDate(
                            row['creatTs']?.toString().trim() ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final message =
        _latestResponse['message']?.toString().trim() ??
        'QR Payment Reconciliation Completed';
    final foundCount = _countValue('foundCount', _foundRows.length);
    final notFoundCount = _countValue('notFoundCount', _notFoundRows.length);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCEAE7)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(18, 75, 69, 0.14),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: Color(0xFF0F8F82),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Payment Reconciliation',
                            style: TextStyle(
                              color: Color(0xFF124B45),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Color(0xFF506461),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ReconcileMetricChip(
                      label: 'Found',
                      value: '$foundCount',
                      color: const Color(0xFF0F8F82),
                    ),
                    _ReconcileMetricChip(
                      label: 'Not Found',
                      value: '$notFoundCount',
                      color: const Color(0xFFB3261E),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if ((_highlightedFile ?? '').isNotEmpty)
                      FilledButton.icon(
                        onPressed: _downloadingFile ? null : _downloadFile,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F8F82),
                          foregroundColor: Colors.white,
                        ),
                        icon: _downloadingFile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: const Text('Download Reconsiled Sheet'),
                      ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: _tabController,
                      builder: (context, _) {
                        return Row(
                          children: [
                            OutlinedButton(
                              onPressed:
                                  _hasActiveSelection && !_actionInProgress
                                  ? () => _handleSelectionAction('Reject')
                                  : null,
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed:
                                  _hasActiveSelection && !_actionInProgress
                                  ? () => _handleSelectionAction('Approve')
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F8F82),
                                foregroundColor: Colors.white,
                              ),
                              child: _actionInProgress
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Approve'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0F8F82),
                  unselectedLabelColor: const Color(0xFF5E6F6D),
                  indicatorColor: const Color(0xFF0F8F82),
                  tabs: [
                    Tab(text: 'Found Transactions ($foundCount)'),
                    Tab(text: 'Not Found Transactions ($notFoundCount)'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabTable(_ReconcileQrTab.found),
                      _buildTabTable(_ReconcileQrTab.notFound),
                    ],
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

class _ReconcileMetricChip extends StatelessWidget {
  const _ReconcileMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QrPaymentActionResultDialog extends StatefulWidget {
  const _QrPaymentActionResultDialog({required this.response});

  final Map<String, dynamic> response;

  @override
  State<_QrPaymentActionResultDialog> createState() =>
      _QrPaymentActionResultDialogState();
}

class _QrPaymentActionResultDialogState
    extends State<_QrPaymentActionResultDialog> {
  bool _downloading = false;

  List<Map<String, dynamic>> get _failedTransactions {
    final raw = widget.response['notCompltedTransactionList'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String get _message {
    final value = widget.response['message']?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
    return 'QR payment transactions processed.';
  }

  String? get _failedFileBase64 {
    final value =
        widget.response['filedWorklistActionFileBase64Encoded']
            ?.toString()
            .trim() ??
        '';
    return value.isEmpty ? null : value;
  }

  Future<void> _downloadFailedFile() async {
    final base64Data = _failedFileBase64;
    if (_downloading || base64Data == null || base64Data.isEmpty) {
      return;
    }

    setState(() {
      _downloading = true;
    });

    try {
      final downloaded = await downloadBase64Receipt(
        base64Data: base64Data,
        fileName: 'qr_payment_action_failed_rows.xlsx',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Failed worklist file downloaded successfully.'
                : 'Unable to download failed worklist file.',
          ),
          backgroundColor: downloaded ? null : const Color(0xFFB3261E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final failedCount = _failedTransactions.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCEAE7)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(18, 75, 69, 0.14),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: Color(0xFF0F8F82),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'QR Payment Action Result',
                        style: TextStyle(
                          color: Color(0xFF124B45),
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _message,
                  style: const TextStyle(
                    color: Color(0xFF344A47),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF2D1CA)),
                  ),
                  child: Text(
                    'Upadtation Failed: $failedCount',
                    style: const TextStyle(
                      color: Color(0xFFB3261E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if ((_failedFileBase64 ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _downloading ? null : _downloadFailedFile,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F8F82),
                      foregroundColor: Colors.white,
                    ),
                    icon: _downloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('Download Failed Worklist File'),
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F8F82),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
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

class _AllPendingQrAcknowledgedDialog extends StatelessWidget {
  const _AllPendingQrAcknowledgedDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCEAE7)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(18, 75, 69, 0.14),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0F8F82),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'QR Payment Reconciliation',
                      style: TextStyle(
                        color: Color(0xFF124B45),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'All Pending QR Payment Are Acknowledged',
                style: TextStyle(
                  color: Color(0xFF344A47),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F8F82),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleHubPage extends StatelessWidget {
  const _ModuleHubPage({
    required this.embedded,
    required this.section,
    required this.title,
    required this.subtitle,
    required this.items,
    this.onBack,
  });

  final bool embedded;
  final AppSection section;
  final String title;
  final String subtitle;
  final List<_ModuleHubItem> items;
  final VoidCallback? onBack;

  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Widget _buildContent(BuildContext context, bool mobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1080),
          child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (embedded && onBack != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: IconButton(
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            iconSize: 28,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      Wrap(
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
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${items.length} Active Actions',
                                  style: const TextStyle(
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
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: mobile ? 1 : 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: mobile ? 170 : 240,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ModuleActionCard(
                      title: item.title,
                      icon: item.icon,
                      onTap: item.onTap,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);

    if (embedded) {
      return _buildContent(context, mobile);
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF0F8F82), title: Text(title)),
      drawer: mobile
          ? Drawer(
              child: SideBar(
                selectedSection: section,
                onSectionSelected: (selectedSection) =>
                    openAppShellSection(context, selectedSection),
              ),
            )
          : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!mobile)
              SideBar(
                selectedSection: section,
                onSectionSelected: (selectedSection) =>
                    openAppShellSection(context, selectedSection),
              ),
            Expanded(child: _buildContent(context, mobile)),
          ],
        ),
      ),
    );
  }
}

class _ModuleHubItem {
  const _ModuleHubItem(this.title, this.icon, {this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
}

class _ModuleActionCard extends StatefulWidget {
  const _ModuleActionCard({
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_ModuleActionCard> createState() => _ModuleActionCardState();
}

class _ModuleActionCardState extends State<_ModuleActionCard> {
  bool hovered = false;

  IconData _backgroundIconForTitle(String title, IconData fallback) {
    final key = title.trim().toLowerCase();
    if (key.contains('ledger')) return Icons.request_quote_rounded;
    if (key.contains('create new payment')) {
      return Icons.payments_rounded;
    }
    if (key.contains('view/update payments')) {
      return Icons.account_balance_rounded;
    }
    if (key.contains('pay dues')) return Icons.currency_rupee_rounded;
    if (key.contains('create receipt')) return Icons.receipt_long_rounded;
    if (key.contains('view transactions')) {
      return Icons.swap_horiz_rounded;
    }
    if (key.contains('upload other due payments')) {
      return Icons.upload_file_rounded;
    }
    if (key.contains('reconcile qr payments')) {
      return Icons.qr_code_scanner_rounded;
    }
    if (key.contains('budget management')) return Icons.pie_chart_rounded;

    if (key.contains('schedule new meeting')) {
      return Icons.event_note_rounded;
    }
    if (key.contains('view meeting details')) {
      return Icons.visibility_rounded;
    }
    if (key.contains('update mom')) return Icons.fact_check_rounded;
    if (key == 'create notice') return Icons.campaign_rounded;
    if (key.contains('view all notice')) {
      return Icons.notifications_active_rounded;
    }
    if (key.contains('create event')) return Icons.event_rounded;
    if (key.contains('view events')) return Icons.calendar_month_rounded;
    if (key.contains('create poll')) return Icons.how_to_vote_rounded;
    if (key.contains('view poll')) return Icons.poll_rounded;

    if (key.contains('raise a new ticket')) {
      return Icons.add_comment_rounded;
    }
    if (key == 'view ticket') return Icons.confirmation_number_rounded;
    if (key.contains('assign ticket')) return Icons.assignment_ind_rounded;

    if (key.contains('visitor entry')) return Icons.badge_rounded;
    if (key.contains('daily worker')) return Icons.engineering_rounded;
    if (key.contains('vehicle pass')) return Icons.directions_car_rounded;
    if (key.contains('message guard')) return Icons.forum_rounded;

    if (key.contains('create group/community')) return Icons.groups_rounded;
    if (key.contains('update group')) return Icons.group_add_rounded;

    if (key == 'add flat') return Icons.add_home_work_rounded;
    if (key == 'update flat') return Icons.edit_note_rounded;
    if (key.contains('upload flat details')) {
      return Icons.domain_verification_rounded;
    }

    if (key.contains('role management')) return Icons.manage_accounts_rounded;
    if (key.contains('staff management')) return Icons.badge_rounded;
    if (key == 'flat management') return Icons.apartment_rounded;
    if (key.contains('update society details')) {
      return Icons.location_city_rounded;
    }

    if (key.contains('onboard employee')) return Icons.person_add_alt_1_rounded;
    if (key.contains('today attendance')) return Icons.today_rounded;
    if (key.contains('employee attendance')) {
      return Icons.checklist_rtl_rounded;
    }

    if (key == 'add vendor') return Icons.storefront_rounded;
    if (key == 'update vendor') return Icons.edit_note_rounded;
    if (key.contains('view vendors')) return Icons.view_list_rounded;

    if (key == 'create role') return Icons.admin_panel_settings_rounded;
    if (key == 'assign role') return Icons.assignment_turned_in_rounded;
    if (key.contains('manage access')) return Icons.key_rounded;

    if (key.contains('lost and found')) return Icons.search_rounded;
    if (key == 'store') return Icons.shopping_bag_rounded;
    if (key.contains('paid service'))
      return Icons.miscellaneous_services_rounded;

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundIcon = _backgroundIconForTitle(widget.title, widget.icon);

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final action = widget.onTap;
          if (action != null) {
            action();
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.title} page is ready for the next step.'),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: hovered ? const Color(0xFFF8F4C6) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hovered
                  ? const Color(0xFFE0DA84)
                  : const Color(0xFFE6EFED),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(17, 59, 52, 0.07),
                blurRadius: hovered ? 24 : 16,
                offset: Offset(0, hovered ? 12 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -2,
                top: -4,
                child: Icon(
                  backgroundIcon,
                  size: 132,
                  color: _ModuleHubPage._brandColor.withValues(
                    alpha: hovered ? 0.18 : 0.12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
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
                        color: _ModuleHubPage._brandColor,
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
                              color: _ModuleHubPage._brandTextColor,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Text(
                                'Open',
                                style: TextStyle(
                                  color: _ModuleHubPage._brandColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: _ModuleHubPage._brandColor,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadFlatDetailsDialog extends StatefulWidget {
  const _UploadFlatDetailsDialog();

  @override
  State<_UploadFlatDetailsDialog> createState() =>
      _UploadFlatDetailsDialogState();
}

class _UploadFlatDetailsDialogState extends State<_UploadFlatDetailsDialog> {
  final TextEditingController _fileController = TextEditingController();
  String? _selectedFileName;
  String? _selectedFileBase64;
  bool _uploading = false;
  bool _downloadingSample = false;
  String? _uploadMessage;
  int? _totalRows;
  int? _successRows;
  int? _failedRows;
  String? _failedRowsReportDocument;
  String? _failedRowsReportDocumentName;

  @override
  void dispose() {
    _fileController.dispose();
    super.dispose();
  }

  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnackBar('Unable to read the selected Excel file.');
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFileBase64 = base64Encode(bytes);
      _fileController.text = file.name;
    });
  }

  Future<void> _downloadSampleExcel() async {
    setState(() {
      _downloadingSample = true;
    });

    try {
      final response = await ApiService.getSampleExcelToUploadFlatData();
      if (!mounted) {
        return;
      }

      if (response == null) {
        _showSnackBar('No sample Excel file was returned from the server.');
        return;
      }

      final documentData =
          response['sampleDocumentData']?.toString().trim() ?? '';
      final documentName =
          response['sampleDocumentName']?.toString().trim() ??
          'sample_upload_template.xlsx';

      if (documentData.isEmpty) {
        _showSnackBar('The sample Excel file was empty.');
        return;
      }

      final bytes = base64Decode(documentData);
      final extension = _fileExtensionFromName(documentName);
      final fileName = _fileNameWithoutExtension(documentName);

      await FileSaver.instance.saveFile(
        name: fileName.isEmpty ? documentName : fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: extension,
        mimeType: _mimeTypeForExtension(extension),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Sample Excel downloaded successfully.');
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to download the sample Excel file.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingSample = false;
        });
      }
    }
  }

  Future<void> _uploadFlatDetails() async {
    if (_selectedFileName == null ||
        _selectedFileBase64 == null ||
        _selectedFileBase64!.trim().isEmpty) {
      _showSnackBar('Select an Excel file before uploading.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadMessage = null;
      _totalRows = null;
      _successRows = null;
      _failedRows = null;
      _failedRowsReportDocument = null;
      _failedRowsReportDocumentName = null;
    });

    try {
      final response = await ApiService.uploadFlatDetails(
        documentName: _selectedFileName!,
        documentData: _selectedFileBase64!,
      );

      if (!mounted) {
        return;
      }

      if (response == null) {
        _showSnackBar('Unable to upload flat details.');
        return;
      }

      setState(() {
        _uploadMessage = response['message']?.toString().trim();
        _totalRows = _readIntValue(response['totalRows']);
        _successRows = _readIntValue(response['successRows']);
        _failedRows = _readIntValue(response['failedRows']);
        _failedRowsReportDocument = response['failedRowsReportDocument']
            ?.toString()
            .trim();
        _failedRowsReportDocumentName = response['failedRowsReportDocumentName']
            ?.toString()
            .trim();
      });
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to upload flat details.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _downloadFailedRowsReport() async {
    final documentData = _failedRowsReportDocument?.trim() ?? '';
    if (documentData.isEmpty) {
      _showSnackBar('No failed rows report is available for download.');
      return;
    }

    try {
      final bytes = base64Decode(documentData);
      final documentName =
          _failedRowsReportDocumentName?.trim().isNotEmpty == true
          ? _failedRowsReportDocumentName!.trim()
          : 'flat_upload_failed_rows.xlsx';
      final extension = _fileExtensionFromName(documentName);
      final fileName = _fileNameWithoutExtension(documentName);

      await FileSaver.instance.saveFile(
        name: fileName.isEmpty ? documentName : fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: extension,
        mimeType: _mimeTypeForExtension(extension),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Failed rows report downloaded successfully.');
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to download the failed rows report.');
      }
    }
  }

  int? _readIntValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Expanded(child: Text('Upload Flat Details')),
          IconButton(
            onPressed: _uploading || _downloadingSample
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload flat details Excel.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileController,
              readOnly: true,
              onTap: _uploading || _downloadingSample ? null : _pickExcelFile,
              decoration: InputDecoration(
                labelText: 'Excel File',
                hintText: 'Select .xlsx or .xls file',
                suffixIcon: IconButton(
                  onPressed: _uploading || _downloadingSample
                      ? null
                      : _pickExcelFile,
                  icon: const Icon(Icons.attach_file),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (_uploadMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FBF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD5E8E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Result',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ModuleHubPage._brandTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_uploadMessage!),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (_successRows != null)
                          Text('Success Rows: $_successRows'),
                        if (_failedRows != null)
                          Text('Failed Rows: $_failedRows'),
                        if (_totalRows != null) Text('Total Rows: $_totalRows'),
                      ],
                    ),
                    if ((_failedRowsReportDocument?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _downloadFailedRowsReport,
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Download Failed Rows Report'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: _uploading || _downloadingSample
              ? null
              : _uploadFlatDetails,
          icon: _uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(_uploading ? 'Uploading...' : 'Upload'),
        ),
        OutlinedButton.icon(
          onPressed: _uploading || _downloadingSample
              ? null
              : _downloadSampleExcel,
          icon: _downloadingSample
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(
            _downloadingSample ? 'Downloading...' : 'Download Sample Excell',
          ),
        ),
      ],
    );
  }
}

String _fileExtensionFromName(String value) {
  final trimmedValue = value.trim();
  final dotIndex = trimmedValue.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == trimmedValue.length - 1) {
    return '';
  }

  return trimmedValue.substring(dotIndex + 1).toLowerCase();
}

String _fileNameWithoutExtension(String value) {
  final trimmedValue = value.trim();
  final dotIndex = trimmedValue.lastIndexOf('.');
  if (dotIndex <= 0) {
    return trimmedValue;
  }

  return trimmedValue.substring(0, dotIndex);
}

MimeType _mimeTypeForExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'xlsx':
    case 'xls':
      return MimeType.microsoftExcel;
    default:
      return MimeType.other;
  }
}

class UpdateSocietyDetailsPage extends StatefulWidget {
  const UpdateSocietyDetailsPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<UpdateSocietyDetailsPage> createState() =>
      _UpdateSocietyDetailsPageState();
}

class _UpdateSocietyDetailsPageState extends State<UpdateSocietyDetailsPage> {
  static const List<String> _paymentGatewayOptions = <String>[
    'RazorPay',
    'PhonePay',
    'NTT Atoms',
  ];

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _apartmentNameController =
      TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _addressLine3Controller = TextEditingController();
  final TextEditingController _addressLine4Controller = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postOfficeController = TextEditingController();
  final TextEditingController _policeStationController =
      TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _addressTypeController = TextEditingController();

  // Contact details controllers
  final TextEditingController _contactMobileController =
      TextEditingController();
  final TextEditingController _contactLandlineController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();

  final List<_ExecutiveMemberInput> _executiveMembers =
      <_ExecutiveMemberInput>[];
  final List<_BankAccountInput> _bankAccounts = <_BankAccountInput>[];

  bool _loading = true;
  bool _updating = false;
  String? _error;
  bool _expandApartmentIdentity = false;
  bool _expandAddress = false;
  bool _expandContactDetails = false;
  bool _expandExecutiveMembers = false;
  bool _expandBankAccounts = false;
  String _apartmentLogoData = '';
  String _apartmentLetterHeadData = '';
  String? _apartmentLogoName;
  String? _apartmentLetterHeadName;
  Map<String, dynamic>? _requestHeader;

  @override
  void initState() {
    super.initState();
    _loadApartmentDetails();
  }

  @override
  void dispose() {
    _apartmentNameController.dispose();
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
    _addressTypeController.dispose();
    _contactMobileController.dispose();
    _contactLandlineController.dispose();
    _contactEmailController.dispose();
    for (final member in _executiveMembers) {
      member.dispose();
    }
    for (final account in _bankAccounts) {
      account.dispose();
    }
    super.dispose();
  }

  Future<void> _loadApartmentDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await ApiService.getApartmentDetails();
    if (!mounted) return;

    if (response == null) {
      setState(() {
        _loading = false;
        _error = 'Unable to fetch apartment details.';
      });
      return;
    }

    final messageCode = response['messageCode']?.toString().trim() ?? '';
    if (!messageCode.startsWith('SUCC') &&
        !messageCode.toUpperCase().contains('SUCCESS')) {
      setState(() {
        _loading = false;
        _error = response['message']?.toString().trim().isNotEmpty == true
            ? response['message'].toString()
            : 'Unable to fetch apartment details.';
      });
      return;
    }

    final genericHeader = response['genericHeader'];
    _requestHeader = genericHeader is Map
        ? Map<String, dynamic>.from(genericHeader)
        : (ApiService.rawLoginHeader ?? ApiService.userHeader);

    _apartmentLogoData = response['apartmentLogo']?.toString().trim() ?? '';
    _apartmentLetterHeadData =
        response['apartmentLetterHead']?.toString().trim() ?? '';
    _apartmentNameController.text =
        response['apartmentName']?.toString().trim() ?? '';

    final address = response['address'];
    final addressMap = address is Map
        ? Map<String, dynamic>.from(address)
        : <String, dynamic>{};
    _setAddressControllers(addressMap);

    for (final member in _executiveMembers) {
      member.dispose();
    }
    _executiveMembers.clear();
    final executiveMembers = response['executiveMemberList'];
    if (executiveMembers is List) {
      for (final entry in executiveMembers.whereType<Map>()) {
        _executiveMembers.add(
          _ExecutiveMemberInput.fromMap(Map<String, dynamic>.from(entry)),
        );
      }
    }
    if (_executiveMembers.isEmpty) {
      _executiveMembers.add(_ExecutiveMemberInput.empty());
    }

    for (final account in _bankAccounts) {
      account.dispose();
    }
    _bankAccounts.clear();
    final bankAccountDetails = response['bankAccountDetails'];
    if (bankAccountDetails is List) {
      for (final entry in bankAccountDetails.whereType<Map>()) {
        _bankAccounts.add(
          _BankAccountInput.fromMap(Map<String, dynamic>.from(entry)),
        );
      }
    }
    if (_bankAccounts.isEmpty) {
      _bankAccounts.add(_BankAccountInput.empty());
    }

    // Contact details
    final contactDetails = response['contactDetails'];
    if (contactDetails is Map) {
      final c = Map<String, dynamic>.from(contactDetails);
      _contactMobileController.text = c['mobileNumber']?.toString() ?? '';
      _contactLandlineController.text = c['landlinenumber']?.toString() ?? '';
      _contactEmailController.text = c['emailId']?.toString() ?? '';
    }

    setState(() {
      _loading = false;
    });
  }

  void _setAddressControllers(Map<String, dynamic> address) {
    _addressLine1Controller.text = address['addressLine1']?.toString() ?? '';
    _addressLine2Controller.text = address['addressLine2']?.toString() ?? '';
    _addressLine3Controller.text = address['addressLine3']?.toString() ?? '';
    _addressLine4Controller.text = address['addressLine4']?.toString() ?? '';
    _landmarkController.text = address['landmark']?.toString() ?? '';
    _cityController.text = address['city']?.toString() ?? '';
    _stateController.text = address['state']?.toString() ?? '';
    _postOfficeController.text = address['postOffice']?.toString() ?? '';
    _policeStationController.text = address['policeStation']?.toString() ?? '';
    _pinController.text = address['pin']?.toString() ?? '';
    _addressTypeController.text = address['addressType']?.toString() ?? '';
  }

  Future<void> _pickApartmentDocument({required bool isLogo}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'],
      withData: true,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.files.single;
    final bytes = selected.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read selected file.')),
      );
      return;
    }

    setState(() {
      if (isLogo) {
        _apartmentLogoData = base64Encode(bytes);
        _apartmentLogoName = selected.name;
      } else {
        _apartmentLetterHeadData = base64Encode(bytes);
        _apartmentLetterHeadName = selected.name;
      }
    });
  }

  Map<String, dynamic> _buildContactDetailsRequest() {
    return {
      'mobileNumber': _contactMobileController.text.trim(),
      'landlinenumber': _contactLandlineController.text.trim(),
      'emailId': _contactEmailController.text.trim(),
    };
  }

  Map<String, dynamic> _buildAddressRequest() {
    return {
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
      'addressType': _addressTypeController.text.trim(),
    };
  }

  List<Map<String, dynamic>> _buildExecutiveMembersRequest() {
    return _executiveMembers
        .where((item) => item.hasAnyValue)
        .map((item) => item.toMap())
        .toList();
  }

  List<Map<String, dynamic>> _buildBankAccountRequest() {
    return _bankAccounts
        .where((item) => item.hasAnyValue)
        .map((item) => item.toMap())
        .toList();
  }

  Future<void> _submitUpdate() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final requestHeader =
        _requestHeader ?? ApiService.rawLoginHeader ?? ApiService.userHeader;
    if (requestHeader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login header is not available.')),
      );
      return;
    }

    setState(() {
      _updating = true;
    });

    final requestBody = {
      'genericHeader': Map<String, dynamic>.from(requestHeader),
      'apartmentLogo': _apartmentLogoData,
      'bankAccountDetails': _buildBankAccountRequest(),
      'address': _buildAddressRequest(),
      'executiveMemberList': _buildExecutiveMembersRequest(),
      'apartmentLetterHead': _apartmentLetterHeadData,
      'contactDetails': _buildContactDetailsRequest(),
    };

    try {
      final response = await ApiService.updateApartmentDetails(requestBody);
      if (!mounted) return;

      final message = response?['message']?.toString().trim().isNotEmpty == true
          ? response!['message'].toString()
          : 'Apartment details updated.';
      final messageCode = response?['messageCode']?.toString().trim() ?? '';
      final isSuccess =
          messageCode.startsWith('SUCC') ||
          messageCode.toUpperCase().contains('SUCCESS');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final accentColor = isSuccess
              ? const Color(0xFF0F8F82)
              : const Color(0xFFB3261E);
          final iconData = isSuccess
              ? Icons.check_circle_rounded
              : Icons.error_rounded;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDCEAE7)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isSuccess ? 'Update Successful' : 'Update Failed',
                            style: const TextStyle(
                              color: Color(0xFF124B45),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FBFA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF2B3F3B),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F8F82),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required bool expanded,
    required ValueChanged<bool> onExpansionChanged,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEAE7)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 75, 69, 0.06),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 14),
          collapsedShape: const RoundedRectangleBorder(),
          shape: const RoundedRectangleBorder(),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF124B45),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F8F82), width: 1.4),
      ),
    );
  }

  Uint8List? _tryDecodeBase64(String data) {
    if (data.trim().isEmpty) {
      return null;
    }

    final payload = data.contains(',') ? data.split(',').last.trim() : data;
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  bool _isLikelyHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return false;
    }
    return uri.hasScheme &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
  }

  Widget _buildDocumentPreview({
    required String data,
    required IconData fallbackIcon,
  }) {
    final bytes = _tryDecodeBase64(data);

    Widget preview;
    if (bytes != null && bytes.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 150,
          height: 110,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 150,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(fallbackIcon, color: const Color(0xFF0F8F82)),
          ),
        ),
      );
    } else if (_isLikelyHttpUrl(data)) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          data,
          width: 150,
          height: 110,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 150,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(fallbackIcon, color: const Color(0xFF0F8F82)),
          ),
        ),
      );
    } else {
      preview = Container(
        width: 150,
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(fallbackIcon, color: const Color(0xFF0F8F82)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFDFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E8E4)),
      ),
      child: Center(child: preview),
    );
  }

  Widget _buildTopSection() {
    return _buildSection(
      title: 'Apartment Identity',
      expanded: _expandApartmentIdentity,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandApartmentIdentity = expanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDocumentPreview(
                  data: _apartmentLogoData,
                  fallbackIcon: Icons.image_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDocumentPreview(
                  data: _apartmentLetterHeadData,
                  fallbackIcon: Icons.description_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _updating
                      ? null
                      : () => _pickApartmentDocument(isLogo: true),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Upload Apartment Logo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _updating
                      ? null
                      : () => _pickApartmentDocument(isLogo: false),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Upload Apartment Letter Head'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _apartmentLogoName != null
                  ? 'Apartment Logo: $_apartmentLogoName'
                  : (_apartmentLogoData.isEmpty
                        ? 'Apartment Logo: Not Available'
                        : 'Apartment Logo: Existing Value Loaded'),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _apartmentLetterHeadName != null
                  ? 'Apartment Letter Head: $_apartmentLetterHeadName'
                  : (_apartmentLetterHeadData.isEmpty
                        ? 'Apartment Letter Head: Not Available'
                        : 'Apartment Letter Head: Existing Value Loaded'),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _apartmentNameController,
            readOnly: true,
            decoration: _decoration('Apartment Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetailsSection() {
    return _buildSection(
      title: 'Contact Details',
      expanded: _expandContactDetails,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandContactDetails = expanded;
        });
      },
      child: Column(
        children: [
          TextFormField(
            controller: _contactMobileController,
            keyboardType: TextInputType.phone,
            decoration: _decoration('Mobile Number'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _contactLandlineController,
            keyboardType: TextInputType.phone,
            decoration: _decoration('Landline Number'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _contactEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration('Email Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildSection(
      title: 'Address',
      expanded: _expandAddress,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandAddress = expanded;
        });
      },
      child: Column(
        children: [
          TextFormField(
            controller: _addressLine1Controller,
            decoration: _decoration('Address Line 1'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: _decoration('Address Line 2'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressLine3Controller,
            decoration: _decoration('Address Line 3'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressLine4Controller,
            decoration: _decoration('Address Line 4'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _landmarkController,
                  decoration: _decoration('Landmark'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: _decoration('City'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: _decoration('State'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _pinController,
                  decoration: _decoration('Pin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _postOfficeController,
                  decoration: _decoration('Post Office'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _policeStationController,
                  decoration: _decoration('Police Station'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _addressTypeController,
            decoration: _decoration('Address Type'),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveMemberCard(_ExecutiveMemberInput input, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E8E4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Executive Member ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _executiveMembers.length <= 1 || _updating
                    ? null
                    : () {
                        setState(() {
                          final member = _executiveMembers.removeAt(index);
                          member.dispose();
                        });
                      },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.positionName,
                  decoration: _decoration('Position Name'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.positionType,
                  decoration: _decoration('Position Type'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.memberId,
                  decoration: _decoration('Member Id'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.status,
                  decoration: _decoration('Status'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.startDate,
                  decoration: _decoration('Start Date'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.endDate,
                  decoration: _decoration('End Date'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveMembersSection() {
    return _buildSection(
      title: 'Executive Member List',
      expanded: _expandExecutiveMembers,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandExecutiveMembers = expanded;
        });
      },
      child: Column(
        children: [
          ..._executiveMembers.asMap().entries.map(
            (entry) => _buildExecutiveMemberCard(entry.value, entry.key),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _updating
                  ? null
                  : () {
                      setState(() {
                        _executiveMembers.add(_ExecutiveMemberInput.empty());
                      });
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add Executive Member'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(_BankAccountInput input, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E8E4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bank Account ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _bankAccounts.length <= 1 || _updating
                    ? null
                    : () {
                        setState(() {
                          final item = _bankAccounts.removeAt(index);
                          item.dispose();
                        });
                      },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.bankName,
                  decoration: _decoration('Bank Name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.accountNumber,
                  decoration: _decoration('Account Number'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.upiId,
                  decoration: _decoration('Upi Id'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.ifscCode,
                  decoration: _decoration('Ifsc Code'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.branch,
                  decoration: _decoration('Branch'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: input.accountName,
                  decoration: _decoration('Account Name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      _paymentGatewayOptions.contains(
                        input.paymentGateway.text.trim(),
                      )
                      ? input.paymentGateway.text.trim()
                      : null,
                  decoration: _decoration('Payment Gateway'),
                  items: _paymentGatewayOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: _updating
                      ? null
                      : (value) {
                          setState(() {
                            input.paymentGateway.text = value ?? '';
                          });
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.paymentGatewayKey,
                  decoration: _decoration('Payment Gateway Key'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.paymentGatewaySecret,
                  decoration: _decoration('Payment Gateway Secret'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection() {
    return _buildSection(
      title: 'Bank Account Details',
      expanded: _expandBankAccounts,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandBankAccounts = expanded;
        });
      },
      child: Column(
        children: [
          ..._bankAccounts.asMap().entries.map(
            (entry) => _buildBankAccountCard(entry.value, entry.key),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _updating
                  ? null
                  : () {
                      setState(() {
                        _bankAccounts.add(_BankAccountInput.empty());
                      });
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add Bank Account'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent({required bool embedded}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1C8C5)),
          ),
          child: Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFF8B1E1E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F8F82), Color(0xFF15766A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  if (embedded && widget.onBack != null)
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Update Society Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTopSection(),
            _buildAddressSection(),
            _buildContactDetailsSection(),
            _buildExecutiveMembersSection(),
            _buildBankAccountsSection(),
            const SizedBox(height: 6),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F8F82),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _updating ? null : _submitUpdate,
              icon: _updating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _updating ? 'Updating...' : 'Update Apartment Details',
              ),
            ),
            if (embedded && widget.onBack != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _updating ? null : widget.onBack,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = BrandBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildFormContent(embedded: widget.embedded),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F82),
        title: const Text('Update Society Details'),
      ),
      body: content,
    );
  }
}

class _ExecutiveMemberInput {
  _ExecutiveMemberInput({
    required this.positionName,
    required this.positionType,
    required this.memberId,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory _ExecutiveMemberInput.empty() {
    return _ExecutiveMemberInput(
      positionName: TextEditingController(),
      positionType: TextEditingController(),
      memberId: TextEditingController(),
      status: TextEditingController(),
      startDate: TextEditingController(),
      endDate: TextEditingController(),
    );
  }

  factory _ExecutiveMemberInput.fromMap(Map<String, dynamic> map) {
    return _ExecutiveMemberInput(
      positionName: TextEditingController(
        text: map['positionName']?.toString() ?? '',
      ),
      positionType: TextEditingController(
        text: map['positiontype']?.toString() ?? '',
      ),
      memberId: TextEditingController(text: map['memberId']?.toString() ?? ''),
      status: TextEditingController(text: map['status']?.toString() ?? ''),
      startDate: TextEditingController(
        text: map['startDate']?.toString() ?? '',
      ),
      endDate: TextEditingController(text: map['endDate']?.toString() ?? ''),
    );
  }

  final TextEditingController positionName;
  final TextEditingController positionType;
  final TextEditingController memberId;
  final TextEditingController status;
  final TextEditingController startDate;
  final TextEditingController endDate;

  bool get hasAnyValue {
    return positionName.text.trim().isNotEmpty ||
        positionType.text.trim().isNotEmpty ||
        memberId.text.trim().isNotEmpty ||
        status.text.trim().isNotEmpty ||
        startDate.text.trim().isNotEmpty ||
        endDate.text.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'positionName': positionName.text.trim(),
      'positiontype': positionType.text.trim(),
      'memberId': memberId.text.trim(),
      'status': status.text.trim(),
      'startDate': startDate.text.trim(),
      'endDate': endDate.text.trim().isEmpty ? null : endDate.text.trim(),
    };
  }

  void dispose() {
    positionName.dispose();
    positionType.dispose();
    memberId.dispose();
    status.dispose();
    startDate.dispose();
    endDate.dispose();
  }
}

class _BankAccountInput {
  _BankAccountInput({
    required this.bankDetailsId,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branch,
    required this.accountName,
    required this.paymentGatewayKey,
    required this.paymentGatewaySecret,
    required this.paymentGateway,
    required this.upiId,
  });

  factory _BankAccountInput.empty() {
    return _BankAccountInput(
      bankDetailsId: '',
      bankName: TextEditingController(),
      accountNumber: TextEditingController(),
      ifscCode: TextEditingController(),
      branch: TextEditingController(),
      accountName: TextEditingController(),
      paymentGatewayKey: TextEditingController(),
      paymentGatewaySecret: TextEditingController(),
      paymentGateway: TextEditingController(),
      upiId: TextEditingController(),
    );
  }

  factory _BankAccountInput.fromMap(Map<String, dynamic> map) {
    return _BankAccountInput(
      bankDetailsId:
          map['bankDetailsID']?.toString().trim() ??
          map['bankDetailsId']?.toString().trim() ??
          map['BankDetailsID']?.toString().trim() ??
          '',
      bankName: TextEditingController(text: map['bankName']?.toString() ?? ''),
      accountNumber: TextEditingController(
        text: map['accountNumber']?.toString() ?? '',
      ),
      ifscCode: TextEditingController(text: map['ifscCode']?.toString() ?? ''),
      branch: TextEditingController(text: map['branch']?.toString() ?? ''),
      accountName: TextEditingController(
        text: map['accountName']?.toString() ?? '',
      ),
      paymentGatewayKey: TextEditingController(
        text: map['pgKey']?.toString() ?? map['razorPayKey']?.toString() ?? '',
      ),
      paymentGatewaySecret: TextEditingController(
        text:
            map['pgSecret']?.toString() ??
            map['razorPaySecret']?.toString() ??
            '',
      ),
      paymentGateway: TextEditingController(
        text: map['pgName']?.toString() ?? '',
      ),
      upiId: TextEditingController(text: map['upiId']?.toString() ?? ''),
    );
  }

  final String bankDetailsId;
  final TextEditingController bankName;
  final TextEditingController accountNumber;
  final TextEditingController ifscCode;
  final TextEditingController branch;
  final TextEditingController accountName;
  final TextEditingController paymentGatewayKey;
  final TextEditingController paymentGatewaySecret;
  final TextEditingController paymentGateway;
  final TextEditingController upiId;

  bool get hasAnyValue {
    return bankName.text.trim().isNotEmpty ||
        accountNumber.text.trim().isNotEmpty ||
        ifscCode.text.trim().isNotEmpty ||
        branch.text.trim().isNotEmpty ||
        accountName.text.trim().isNotEmpty ||
        paymentGatewayKey.text.trim().isNotEmpty ||
        paymentGatewaySecret.text.trim().isNotEmpty ||
        paymentGateway.text.trim().isNotEmpty ||
        upiId.text.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'bankName': bankName.text.trim(),
      'accountNumber': accountNumber.text.trim(),
      'ifscCode': ifscCode.text.trim(),
      'branch': branch.text.trim(),
      'accountName': accountName.text.trim(),
      'pgKey': paymentGatewayKey.text.trim(),
      'pgSecret': paymentGatewaySecret.text.trim(),
      'pgName': paymentGateway.text.trim(),
      'upiId': upiId.text.trim(),
    };

    if (bankDetailsId.trim().isNotEmpty) {
      map['bankDetailsID'] = bankDetailsId.trim();
      map['BankDetailsID'] = bankDetailsId.trim();
    }

    return map;
  }

  void dispose() {
    bankName.dispose();
    accountNumber.dispose();
    ifscCode.dispose();
    branch.dispose();
    accountName.dispose();
    paymentGatewayKey.dispose();
    paymentGatewaySecret.dispose();
    paymentGateway.dispose();
    upiId.dispose();
  }
}
