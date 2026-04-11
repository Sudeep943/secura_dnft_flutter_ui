import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';
import 'create_payment_page.dart';
import 'create_notice_page.dart';
import 'view_all_notices_page.dart';

class MeetingAndNoticeManagementPage extends StatelessWidget {
  const MeetingAndNoticeManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.meetingAndNotice,
      title: 'Meeting And Notice Management',
      subtitle:
          'Choose one of the meeting, notice, event, or poll actions below.',
      items: [
        _ModuleHubItem('Schedule New Meeting', Icons.event_note),
        _ModuleHubItem('View Meeting Details', Icons.visibility),
        _ModuleHubItem('Update MOM', Icons.edit_document),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ViewAllNoticesPage()),
            );
          },
        ),
        _ModuleHubItem('Create Event', Icons.event),
        _ModuleHubItem('View Events', Icons.calendar_month),
        _ModuleHubItem('Create Poll', Icons.how_to_vote),
        _ModuleHubItem('View Poll', Icons.poll),
      ],
    );
  }
}

class TicketManagementPage extends StatelessWidget {
  const TicketManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.ticketManagement,
      title: 'Ticket Management',
      subtitle: 'Choose one of the ticket management actions below.',
      items: const [
        _ModuleHubItem('Raise A New Ticket', Icons.support_agent),
        _ModuleHubItem('View Ticket', Icons.confirmation_number),
        _ModuleHubItem('Assign Ticket', Icons.assignment_ind),
      ],
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

class AdminSectionPage extends StatelessWidget {
  const AdminSectionPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.adminSection,
      title: 'Admin Section',
      subtitle:
          'Choose one of the administration actions below for roles, staff, and flat operations.',
      items: [
        _ModuleHubItem(
          'Role Management',
          Icons.lock_person_outlined,
          onTap: () => openAppShellSection(context, AppSection.roleAndAccess),
        ),
        _ModuleHubItem(
          'Staff Management',
          Icons.groups_outlined,
          onTap: () => openAppShellSection(context, AppSection.staffManagement),
        ),
        _ModuleHubItem(
          'Flat Management',
          Icons.door_front_door_outlined,
          onTap: () => openAppShellSection(context, AppSection.flatManagement),
        ),
      ],
    );
  }
}

class FlatManagementPage extends StatelessWidget {
  const FlatManagementPage({super.key, this.embedded = false});

  final bool embedded;

  void _showPlaceholderMessage(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title page is ready for the next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.flatManagement,
      title: 'Flat Management',
      subtitle:
          'Choose one of the flat management actions below to add, update, or upload flat details.',
      items: [
        _ModuleHubItem(
          'Add Flat',
          Icons.add_home_work_outlined,
          onTap: () => _showPlaceholderMessage(context, 'Add Flat'),
        ),
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
      ],
    );
  }
}

class StaffManagementPage extends StatelessWidget {
  const StaffManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.staffManagement,
      title: 'Staff Management',
      subtitle: 'Choose one of the staff operations below.',
      items: const [
        _ModuleHubItem('Attendance Management', Icons.fact_check),
        _ModuleHubItem('Leave Management', Icons.beach_access),
        _ModuleHubItem('Shift Management', Icons.schedule),
        _ModuleHubItem('Payroll Management', Icons.payments),
      ],
    );
  }
}

class VendorManagementPage extends StatelessWidget {
  const VendorManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.vendorManagement,
      title: 'Vendor Management',
      subtitle: 'Choose one of the vendor actions below.',
      items: const [
        _ModuleHubItem('Add Vendor', Icons.person_add_alt_1),
        _ModuleHubItem('Update Vendor', Icons.manage_accounts),
        _ModuleHubItem('View Vendor Details', Icons.storefront),
      ],
    );
  }
}

class RoleAndAccessPage extends StatelessWidget {
  const RoleAndAccessPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.roleAndAccess,
      title: 'Role And Access',
      subtitle: 'Choose one of the role and access control actions below.',
      items: const [
        _ModuleHubItem('Create Role', Icons.admin_panel_settings),
        _ModuleHubItem('Assign Role', Icons.assignment_turned_in),
        _ModuleHubItem('Manage Access', Icons.lock_open),
      ],
    );
  }
}

class ReportsManagementPage extends StatelessWidget {
  const ReportsManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      embedded: embedded,
      section: AppSection.reports,
      title: 'Reports',
      subtitle: 'Choose one of the report categories below.',
      items: const [
        _ModuleHubItem('Financial Reports', Icons.bar_chart),
        _ModuleHubItem('Booking Reports', Icons.insert_chart_outlined),
        _ModuleHubItem('Employee Reports', Icons.analytics),
      ],
    );
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

    return _ModuleHubPage(
      embedded: widget.embedded,
      section: AppSection.finance,
      title: 'Finance',
      subtitle: 'Choose one of the finance actions below.',
      items: [
        _ModuleHubItem('Add Credit', Icons.add_card),
        _ModuleHubItem('Add Debit', Icons.credit_card_off),
        _ModuleHubItem(
          'Create New Payment',
          Icons.payment,
          onTap: () {
            setState(() {
              _showCreatePayment = true;
            });
          },
        ),
        _ModuleHubItem('Add Bank Account', Icons.account_balance),
        _ModuleHubItem('Pay Dues', Icons.currency_rupee),
      ],
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
  });

  final bool embedded;
  final AppSection section;
  final String title;
  final String subtitle;
  final List<_ModuleHubItem> items;

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

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(22),
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
