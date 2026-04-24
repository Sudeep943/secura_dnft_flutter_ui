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
import 'create_receipt_page.dart';
import 'home_page.dart';
import 'view_all_notices_page.dart';
import 'view_transactions_page.dart';
import 'view_update_payments_page.dart';
import 'create_ledger_entry_page.dart';

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
        embedded: true,
        onBack: () {
          setState(() {
            _showViewAllNotices = false;
          });
        },
      );
    }

    return _ModuleHubPage(
      embedded: widget.embedded,
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
            setState(() {
              _showViewAllNotices = true;
            });
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

    return _ModuleHubPage(
      embedded: widget.embedded,
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
        _ModuleHubItem(
          'Update Society Details',
          Icons.apartment_outlined,
          onTap: () {
            setState(() {
              _showUpdateSocietyDetails = true;
            });
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
      subtitle: 'Choose one of the staff management actions below.',
      items: const [
        _ModuleHubItem('Add Staff', Icons.person_add_alt_1),
        _ModuleHubItem('Update Staff', Icons.manage_accounts_outlined),
        _ModuleHubItem('View Staff', Icons.badge_outlined),
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
      subtitle: 'Choose one of the vendor management actions below.',
      items: const [
        _ModuleHubItem('Add Vendor', Icons.storefront_outlined),
        _ModuleHubItem('Update Vendor', Icons.edit_note_outlined),
        _ModuleHubItem('View Vendors', Icons.list_alt_outlined),
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
      if (!mounted) {
        return;
      }

      final normalizedDueList = duePaymentList is List
          ? duePaymentList
          : const <dynamic>[];
      if (normalizedDueList.isEmpty) {
        _showSnack('No due payments found.');
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => PaymentDetailsModal(
          duePaymentList: normalizedDueList,
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

    return _ModuleHubPage(
      embedded: widget.embedded,
      section: AppSection.finance,
      title: 'Finance',
      subtitle: 'Choose one of the finance actions below.',
      items: [
        _ModuleHubItem(
          'Ledger Entry',
          Icons.credit_card_off,
          onTap: () {
            setState(() {
              _showCreateLedgerEntry = true;
            });
          },
        ),
        _ModuleHubItem(
          'Create New Payment',
          Icons.payment,
          onTap: () {
            setState(() {
              _showCreatePayment = true;
            });
          },
        ),
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

  final List<_ExecutiveMemberInput> _executiveMembers =
      <_ExecutiveMemberInput>[];
  final List<_BankAccountInput> _bankAccounts = <_BankAccountInput>[];

  bool _loading = true;
  bool _updating = false;
  String? _error;
  bool _expandApartmentIdentity = false;
  bool _expandAddress = false;
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
          return AlertDialog(
            title: Text(isSuccess ? 'Update Successful' : 'Update Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
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
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.accountNumber,
                  decoration: _decoration('Account Number'),
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
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: input.razorPayKey,
                  decoration: _decoration('Razor Pay Key'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: input.razorPaySecret,
            decoration: _decoration('Razor Pay Secret'),
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
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branch,
    required this.accountName,
    required this.razorPayKey,
    required this.razorPaySecret,
  });

  factory _BankAccountInput.empty() {
    return _BankAccountInput(
      bankName: TextEditingController(),
      accountNumber: TextEditingController(),
      ifscCode: TextEditingController(),
      branch: TextEditingController(),
      accountName: TextEditingController(),
      razorPayKey: TextEditingController(),
      razorPaySecret: TextEditingController(),
    );
  }

  factory _BankAccountInput.fromMap(Map<String, dynamic> map) {
    return _BankAccountInput(
      bankName: TextEditingController(text: map['bankName']?.toString() ?? ''),
      accountNumber: TextEditingController(
        text: map['accountNumber']?.toString() ?? '',
      ),
      ifscCode: TextEditingController(text: map['ifscCode']?.toString() ?? ''),
      branch: TextEditingController(text: map['branch']?.toString() ?? ''),
      accountName: TextEditingController(
        text: map['accountName']?.toString() ?? '',
      ),
      razorPayKey: TextEditingController(
        text: map['razorPayKey']?.toString() ?? '',
      ),
      razorPaySecret: TextEditingController(
        text: map['razorPaySecret']?.toString() ?? '',
      ),
    );
  }

  final TextEditingController bankName;
  final TextEditingController accountNumber;
  final TextEditingController ifscCode;
  final TextEditingController branch;
  final TextEditingController accountName;
  final TextEditingController razorPayKey;
  final TextEditingController razorPaySecret;

  bool get hasAnyValue {
    return bankName.text.trim().isNotEmpty ||
        accountNumber.text.trim().isNotEmpty ||
        ifscCode.text.trim().isNotEmpty ||
        branch.text.trim().isNotEmpty ||
        accountName.text.trim().isNotEmpty ||
        razorPayKey.text.trim().isNotEmpty ||
        razorPaySecret.text.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName.text.trim(),
      'accountNumber': accountNumber.text.trim(),
      'ifscCode': ifscCode.text.trim(),
      'branch': branch.text.trim(),
      'accountName': accountName.text.trim(),
      'razorPayKey': razorPayKey.text.trim(),
      'razorPaySecret': razorPaySecret.text.trim(),
    };
  }

  void dispose() {
    bankName.dispose();
    accountNumber.dispose();
    ifscCode.dispose();
    branch.dispose();
    accountName.dispose();
    razorPayKey.dispose();
    razorPaySecret.dispose();
  }
}
