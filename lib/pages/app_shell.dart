import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'booking_page.dart';
import 'home_page.dart';
import 'module_hub_pages.dart';
import 'profile_management_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialSection = AppSection.dashboard});

  final AppSection initialSection;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppSection _selectedSection;
  static const int _notificationCount = 3;
  static const int _worklistCount = 10;
  Uint8List? _apartmentLogoBytes;

  static const List<AppSection> _sections = [
    AppSection.dashboard,
    AppSection.bookings,
    AppSection.profileManagement,
    AppSection.adminSection,
    AppSection.flatManagement,
    AppSection.meetingAndNotice,
    AppSection.ticketManagement,
    AppSection.security,
    AppSection.groupManagement,
    AppSection.staffManagement,
    AppSection.vendorManagement,
    AppSection.roleAndAccess,
    AppSection.reports,
    AppSection.others,
    AppSection.finance,
  ];

  late final List<Widget> _pages = [
    const HomePage(embedded: true),
    const BookingPage(embedded: true),
    const ProfileManagementPage(embedded: true),
    const AdminSectionPage(embedded: true),
    const FlatManagementPage(embedded: true),
    const MeetingAndNoticeManagementPage(embedded: true),
    const TicketManagementPage(embedded: true),
    const SecurityManagementPage(embedded: true),
    const GroupManagementPage(embedded: true),
    const StaffManagementPage(embedded: true),
    const VendorManagementPage(embedded: true),
    const RoleAndAccessPage(embedded: true),
    const ReportsManagementPage(embedded: true),
    const OthersManagementPage(embedded: true),
    const FinanceManagementPage(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    if (_selectedSection == AppSection.dashboard) {
      _loadHeaderApartmentLogo();
    }
  }

  Future<void> _loadHeaderApartmentLogo() async {
    final response = await ApiService.getApartmentDetails();
    if (!mounted || response == null) {
      return;
    }

    final messageCode = response['messageCode']?.toString().trim() ?? '';
    final isSuccess =
        messageCode.startsWith('SUCC') ||
        messageCode.toUpperCase().contains('SUCCESS');
    if (!isSuccess) {
      return;
    }

    final encodedLogo = response['apartmentLogo']?.toString().trim() ?? '';
    final bytes = _decodeBase64Asset(encodedLogo);
    if (bytes == null) {
      return;
    }

    setState(() {
      _apartmentLogoBytes = bytes;
    });
  }

  Uint8List? _decodeBase64Asset(String value) {
    if (value.isEmpty) {
      return null;
    }

    var normalized = value.trim();
    final commaIndex = normalized.indexOf(',');
    if (commaIndex != -1 && normalized.substring(0, commaIndex).contains(';')) {
      normalized = normalized.substring(commaIndex + 1);
    }
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');

    try {
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  void _selectSection(AppSection section) {
    if (_selectedSection == section) {
      if (_isMobile(context)) {
        Navigator.of(context).maybePop();
      }
      return;
    }

    setState(() {
      _selectedSection = section;
    });

    if (section == AppSection.dashboard) {
      _loadHeaderApartmentLogo();
    }

    if (_isMobile(context)) {
      Navigator.of(context).maybePop();
    }
  }

  void _showShellMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openWorklistModal() async {
    final response = await ApiService.getWorklists();
    if (!mounted) {
      return;
    }

    final rawWorklists = response?['worklists'];
    final worklists = rawWorklists is List
        ? rawWorklists
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .where(
                (item) =>
                    item['status']?.toString().trim().toUpperCase() ==
                    'PENDING',
              )
              .toList()
        : <Map<String, dynamic>>[];

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _WorklistDialog(initialWorklists: worklists),
    );
  }

  Widget _buildNotificationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextButton.icon(
            onPressed: () => _showShellMessage(
              'You have $_notificationCount pending community notifications.',
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
            label: const Text('Notifications'),
          ),
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0DA84),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$_notificationCount',
                style: const TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorklistButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: TextButton.icon(
        onPressed: _openWorklistModal,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
        icon: const Icon(Icons.work_outline_rounded),
        label: Text('Worklist ($_worklistCount)'),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('secura_logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _selectedSection.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApartmentLogoButton() {
    final imageWidget = _apartmentLogoBytes != null
        ? Image.memory(_apartmentLogoBytes!, fit: BoxFit.contain)
        : Image.asset('secura_logo.png', fit: BoxFit.contain);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: SizedBox(
        width: 88,
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    final currentIndex = _sections.indexOf(_selectedSection);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F82),
        titleSpacing: 12,
        title: _buildSectionTitle(),
        actions: [
          _buildApartmentLogoButton(),
          _buildNotificationButton(),
          _buildWorklistButton(),
        ],
      ),
      drawer: mobile
          ? Drawer(
              child: SideBar(
                selectedSection: _selectedSection,
                onSectionSelected: _selectSection,
              ),
            )
          : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!mobile)
              SideBar(
                selectedSection: _selectedSection,
                onSectionSelected: _selectSection,
              ),
            Expanded(
              child: IndexedStack(index: currentIndex, children: _pages),
            ),
          ],
        ),
      ),
    );
  }
}

void openAppShellSection(BuildContext context, AppSection section) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => AppShell(initialSection: section)),
    (route) => false,
  );
}

class _WorklistDialog extends StatefulWidget {
  const _WorklistDialog({required this.initialWorklists});

  final List<Map<String, dynamic>> initialWorklists;

  @override
  State<_WorklistDialog> createState() => _WorklistDialogState();
}

class _WorklistDialogState extends State<_WorklistDialog> {
  static const String _transactionReviewType = 'TRANSACTION REVIEW';

  late List<Map<String, dynamic>> _worklists = widget.initialWorklists;
  final Map<String, bool> _loadingTransaction = {};

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '--';
    }

    try {
      final parsed = DateTime.parse(raw);
      const months = [
        '',
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
      final day = parsed.day.toString().padLeft(2, '0');
      final month = months[parsed.month];
      final year = parsed.year;
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$day-$month-$year $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _refreshWorklists() async {
    final response = await ApiService.getWorklists();
    if (!mounted) {
      return;
    }

    final rawWorklists = response?['worklists'];
    setState(() {
      _worklists = rawWorklists is List
          ? rawWorklists
                .whereType<Map>()
                .map((entry) => Map<String, dynamic>.from(entry))
                .where(
                  (item) =>
                      item['status']?.toString().trim().toUpperCase() ==
                      'PENDING',
                )
                .toList()
          : <Map<String, dynamic>>[];
    });
  }

  Future<void> _openTransactionDetails(Map<String, dynamic> item) async {
    final referenceId = item['referenceId']?.toString().trim() ?? '';
    final worklistId = item['worklistId']?.toString().trim() ?? '';
    if (referenceId.isEmpty || worklistId.isEmpty) {
      return;
    }

    if (_loadingTransaction[referenceId] == true) {
      return;
    }

    setState(() {
      _loadingTransaction[referenceId] = true;
    });

    final header = ApiService.userHeader;
    if (header == null) {
      if (mounted) {
        setState(() {
          _loadingTransaction.remove(referenceId);
        });
      }
      return;
    }

    final response = await ApiService.getTransactions({
      'genericHeader': Map<String, dynamic>.from(header),
      'transactionId': referenceId,
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingTransaction.remove(referenceId);
    });

    final rawList = response?['transactionList'];
    if (rawList is! List || rawList.isEmpty || rawList.first is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch transaction details.')),
      );
      return;
    }

    final transaction = Map<String, dynamic>.from(rawList.first as Map);

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _TransactionDetailDialog(
        transaction: transaction,
        worklistId: worklistId,
        onActionCompleted: _refreshWorklists,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 560),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F8F82),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work_outline_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Worklists (${_worklists.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _worklists.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending worklists found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Table(
                        border: TableBorder.all(
                          color: const Color(0xFFE2ECE9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1.7),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(2.0),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFFE9F7F4)),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Worklist ID',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Type',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Created At',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Reference ID',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          ..._worklists.map((item) {
                            final referenceId =
                                item['referenceId']?.toString().trim() ?? '';
                            final worklistType =
                                item['worklistType']?.toString().trim() ?? '';
                            final isTransactionReview =
                                worklistType.toUpperCase() ==
                                _transactionReviewType;

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    item['worklistId']?.toString() ?? '--',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    item['worklistType']?.toString() ?? '--',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    _formatDate(item['creatTs']?.toString()),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: referenceId.isEmpty
                                      ? const Text('--')
                                      : isTransactionReview
                                      ? InkWell(
                                          onTap: () =>
                                              _openTransactionDetails(item),
                                          child: Text(
                                            referenceId,
                                            style: const TextStyle(
                                              color: Color(0xFF0F8F82),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        )
                                      : Text(referenceId),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailDialog extends StatefulWidget {
  const _TransactionDetailDialog({
    required this.transaction,
    required this.worklistId,
    required this.onActionCompleted,
  });

  final Map<String, dynamic> transaction;
  final String worklistId;
  final Future<void> Function() onActionCompleted;

  @override
  State<_TransactionDetailDialog> createState() =>
      _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<_TransactionDetailDialog> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const String _approveAction = 'APPROVE';
  static const String _rejectAction = 'REJECT';

  int _imageIndex = 0;
  String? _loadingAction;

  List<String> get _trnsFiles {
    final raw = widget.transaction['trnsFiles'];
    if (raw is List) {
      return raw
          .map((e) => e?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  List<MapEntry<String, String>> _details() {
    final entries = <MapEntry<String, String>>[];
    final keyLabels = <String, String>{
      'trnscId': 'Transaction ID',
      'trnsDate': 'Transaction Date',
      'trnsBy': 'Done By',
      'trnsType': 'Type',
      'trnsAmt': 'Amount',
      'trnsStatus': 'Status',
      'cause': 'Credit/Debit Head',
      'pymntId': 'Payment ID',
      'trnsBnkAccnt': 'Bank Account',
      'receiptNumber': 'Receipt Number',
    };

    String formatValue(String key, dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return '--';
      if (key.toLowerCase().contains('date') ||
          key.toLowerCase().endsWith('ts') ||
          key.toLowerCase().contains('time')) {
        try {
          final parsed = DateTime.parse(text);
          const months = [
            '',
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
          return '${parsed.day.toString().padLeft(2, '0')}-${months[parsed.month]}-${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        } catch (_) {
          return text;
        }
      }
      return text;
    }

    for (final key in keyLabels.keys) {
      if (widget.transaction.containsKey(key)) {
        final value = formatValue(key, widget.transaction[key]);
        if (value != '--') {
          entries.add(MapEntry(keyLabels[key]!, value));
        }
      }
    }

    for (final entry in widget.transaction.entries) {
      if (keyLabels.containsKey(entry.key) ||
          entry.key == 'trnsFiles' ||
          entry.key == 'trnsTender') {
        continue;
      }
      final value = formatValue(entry.key, entry.value);
      if (value != '--') {
        entries.add(MapEntry(entry.key, value));
      }
    }

    return entries;
  }

  Future<void> _handleAction(String action) async {
    if (_loadingAction != null) {
      return;
    }

    setState(() {
      _loadingAction = action;
    });

    await ApiService.actionTransactionReviewWorkList(
      worklistId: widget.worklistId,
      action: action,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingAction = null;
    });

    Navigator.of(context).pop();
    await widget.onActionCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final files = _trnsFiles;
    final details = _details();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 680),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: const BoxDecoration(
                color: _brandColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Transaction Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...details.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF124B45),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(entry.value)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    flex: 4,
                    child: files.isEmpty
                        ? const Center(
                            child: Text(
                              'No attachments',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Builder(
                                      builder: (_) {
                                        try {
                                          final bytes = base64Decode(
                                            files[_imageIndex],
                                          );
                                          return Image.memory(
                                            bytes,
                                            fit: BoxFit.contain,
                                          );
                                        } catch (_) {
                                          return const Center(
                                            child: Text(
                                              'Cannot display image',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      onPressed: _imageIndex == 0
                                          ? null
                                          : () => setState(() {
                                              _imageIndex--;
                                            }),
                                    ),
                                    Text(
                                      '${_imageIndex + 1} / ${files.length}',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onPressed: _imageIndex == files.length - 1
                                          ? null
                                          : () => setState(() {
                                              _imageIndex++;
                                            }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _loadingAction == null
                        ? () => Navigator.of(context).pop()
                        : null,
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _loadingAction == null
                        ? () => _handleAction(_approveAction)
                        : null,
                    child: _loadingAction == _approveAction
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _loadingAction == null
                        ? () => _handleAction(_rejectAction)
                        : null,
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: _loadingAction == _rejectAction
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reject'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
