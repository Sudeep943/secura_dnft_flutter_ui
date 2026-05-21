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
  Uint8List? _apartmentLogoBytes;
  int _worklistCount = 0;
  bool _worklistCountLoading = false;

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
    _refreshWorklistCount();
    if (_selectedSection == AppSection.dashboard) {
      _loadHeaderApartmentLogo();
    }
  }

  List<Map<String, dynamic>> _extractWorklists(dynamic rawWorklists) {
    if (rawWorklists is! List) {
      return const <Map<String, dynamic>>[];
    }
    return rawWorklists
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<void> _refreshWorklistCount() async {
    if (_worklistCountLoading) {
      return;
    }
    setState(() {
      _worklistCountLoading = true;
    });

    final response = await ApiService.getWorklists();
    if (!mounted) {
      return;
    }

    final worklists = _extractWorklists(response?['worklists']);
    setState(() {
      _worklistCount = worklists.length;
      _worklistCountLoading = false;
    });
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

    final worklists = _extractWorklists(response?['worklists']);

    setState(() {
      _worklistCount = worklists.length;
    });

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _WorklistDialog(initialWorklists: worklists),
    );

    await _refreshWorklistCount();
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
        icon: _worklistCountLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.work_outline_rounded),
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

class _WorklistDialogState extends State<_WorklistDialog>
    with SingleTickerProviderStateMixin {
  static const String _transactionReviewType = 'TRANSACTION REVIEW';
  static const Color _brandColor = Color(0xFF0F8F82);

  late List<Map<String, dynamic>> _worklists = widget.initialWorklists;
  final Map<String, bool> _loadingTransaction = {};
  final Set<String> _expandedWorklistIds = <String>{};
  late final AnimationController _statusGlowController;

  @override
  void initState() {
    super.initState();
    _statusGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _statusGlowController.dispose();
    super.dispose();
  }

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
                .toList()
          : <Map<String, dynamic>>[];
    });
  }

  Widget _metaPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _brandColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF26514D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value) {
    if (value.trim().isEmpty) {
      value = '--';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF0E7369),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.trim().toUpperCase();
    final isComplete = normalized == 'COMPLETE';
    final bg = isComplete ? const Color(0xFFE7F8EE) : const Color(0xFFFFF6D6);
    final fg = isComplete ? const Color(0xFF178F4A) : const Color(0xFF9C7700);
    final glow = isComplete ? const Color(0xFF22C55E) : const Color(0xFFF7C948);
    final label = isComplete ? 'Complete' : 'Pending';

    return AnimatedBuilder(
      animation: _statusGlowController,
      builder: (_, __) {
        final intensity = 0.30 + (_statusGlowController.value * 0.70);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: intensity * 0.45),
                blurRadius: 12,
                spreadRadius: 0.8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 9, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorklistCard(Map<String, dynamic> item) {
    final referenceId = item['referenceId']?.toString().trim() ?? '';
    final worklistId = item['worklistId']?.toString().trim() ?? '--';
    final flatNo = item['flatNo']?.toString().trim() ?? '';
    final worklistType = item['worklistType']?.toString().trim() ?? '';
    final status = item['status']?.toString().trim() ?? 'PENDING';
    final isTransactionReview =
        worklistType.toUpperCase() == _transactionReviewType;
    final isLoading = _loadingTransaction[referenceId] == true;
    final expandKey = worklistId == '--' ? referenceId : worklistId;
    final isExpanded = _expandedWorklistIds.contains(expandKey);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2ECE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14004D45),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedWorklistIds.remove(expandKey);
                } else {
                  _expandedWorklistIds.add(expandKey);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Worklist $worklistId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF143B38),
                      ),
                    ),
                  ),
                  _buildStatusBadge(status),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF26514D),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip('Flat: ${flatNo.isEmpty ? '--' : flatNo}'),
              _buildTypeChip(
                'Type: ${worklistType.isEmpty ? '--' : worklistType}',
              ),
              _metaPill(
                icon: Icons.calendar_month_rounded,
                text: 'From: ${_formatDate(item['creatTs']?.toString())}',
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 16,
                      color: Color(0xFF4C6764),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: referenceId.isEmpty
                          ? const Text(
                              'Reference ID: --',
                              style: TextStyle(color: Color(0xFF4C6764)),
                            )
                          : isTransactionReview
                          ? InkWell(
                              onTap: isLoading
                                  ? null
                                  : () => _openTransactionDetails(item),
                              child: Text(
                                'Reference ID: $referenceId',
                                style: const TextStyle(
                                  color: _brandColor,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Text(
                              'Reference ID: $referenceId',
                              style: const TextStyle(color: Color(0xFF2A4A47)),
                            ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  double _modalMaxHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final preferred = 220 + (_worklists.length * 122.0);
    final bounded = preferred.clamp(340.0, screenHeight * 0.90);
    return bounded.toDouble();
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: _modalMaxHeight(context),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F8F82), Color(0xFF11A193)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Worklists (${_worklists.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _worklists.isEmpty
                              ? 'No pending tasks currently'
                              : 'Tap each worklist to expand',
                          style: const TextStyle(
                            color: Color(0xFFE0F7F3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh worklists',
                    onPressed: _refreshWorklists,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
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
              child: Container(
                color: const Color(0xFFF8FBFB),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: _worklists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7F5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.playlist_remove_rounded,
                                color: _brandColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No pending worklists found',
                              style: TextStyle(
                                color: Color(0xFF2A4A47),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You are all caught up for now.',
                              style: TextStyle(color: Color(0xFF667B78)),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _refreshWorklists,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _brandColor,
                                side: const BorderSide(color: _brandColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _metaPill(
                                  icon: Icons.format_list_bulleted_rounded,
                                  text: '${_worklists.length} total items',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _worklists.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) =>
                                  _buildWorklistCard(_worklists[index]),
                            ),
                          ),
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
  static const Set<String> _hiddenDetailKeys = {
    'bankinstrumenttender',
    'bankinstrumenttenderdetails',
    'apartmentid',
    'aprmntid',
    'worklistid',
    'trnscurrency',
    'creatts',
    'creatuserid',
    'createuserid',
    'noofperson',
    'numberofperson',
  };

  int _imageIndex = 0;
  String? _loadingAction;

  List<String> get _trnsFiles {
    final raw = widget.transaction['trnsFiles'];

    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              final map = Map<String, dynamic>.from(e);
              final preferredKeys = [
                'fileData',
                'data',
                'content',
                'base64',
                'image',
              ];
              for (final key in preferredKeys) {
                final value = map[key]?.toString() ?? '';
                if (value.trim().isNotEmpty) {
                  return value;
                }
              }
              return '';
            }
            return e?.toString() ?? '';
          })
          .where((value) => value.isNotEmpty)
          .toList();
    }

    if (raw is String && raw.trim().isNotEmpty) {
      final text = raw.trim();
      if (text.startsWith('[')) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is List) {
            return decoded
                .map((e) => e?.toString() ?? '')
                .where((value) => value.trim().isNotEmpty)
                .toList();
          }
        } catch (_) {
          // Fallback to treat it as a single base64 payload.
        }
      }
      return [text];
    }

    return const <String>[];
  }

  Uint8List? _decodeBase64Image(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final commaIndex = value.indexOf(',');
    if (commaIndex != -1 && value.substring(0, commaIndex).contains(';')) {
      value = value.substring(commaIndex + 1);
    }

    value = value.replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(base64.normalize(value));
    } catch (_) {
      return null;
    }
  }

  String _toTitleWords(String raw) {
    final normalized = raw
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return '--';
    }
    final words = normalized.split(' ');
    return words
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  bool _looksLikeIdentifier(String key) {
    final lower = key.toLowerCase();
    return lower.endsWith('id') || lower.contains('number');
  }

  String _formatAmount(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return '--';
    }
    if (text.startsWith('₹')) {
      return text;
    }
    return '₹ $text';
  }

  String _firstTenderText() {
    final rawTender = widget.transaction['trnsTender'];
    if (rawTender is! List || rawTender.isEmpty) {
      return '--';
    }

    final first = rawTender.first;
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      final preferredKeys = ['tenderName'];
      for (final key in preferredKeys) {
        final candidate = map[key]?.toString().trim() ?? '';
        if (candidate.isNotEmpty && candidate.toLowerCase() != 'null') {
          return _toTitleWords(candidate);
        }
      }
      return '--';
    }

    final text = first.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '--';
    }
    return _toTitleWords(text);
  }

  String _displayLabelForKey(String key, Map<String, String> labels) {
    final configured = labels[key] ?? key;
    return _toTitleWords(configured);
  }

  String _normalizeKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _displayValueForKey(String key, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '--';

    final lower = key.toLowerCase();
    if (lower.contains('date') ||
        lower.endsWith('ts') ||
        lower.contains('time')) {
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
        return '${parsed.day.toString().padLeft(2, '0')}-${months[parsed.month]}-${parsed.year}, ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return text;
      }
    }

    if (key == 'trnsAmt') {
      return _formatAmount(text);
    }

    if (_looksLikeIdentifier(key)) {
      return text;
    }

    return _toTitleWords(text);
  }

  List<Map<String, String>> _details() {
    final entries = <Map<String, String>>[];
    final keyLabels = <String, String>{
      'trnscId': 'Transaction ID',
      'trnsDate': 'Transaction Date Time',
      'trnsBy': 'Done By',
      'trnsType': 'Type',
      'trnsAmt': 'Amount',
      'trnsStatus': 'Status',
      'cause': 'Cause',
      'pymntId': 'Payment ID',
      'trnsBnkAccnt': 'Bank Account',
      'receiptNumber': 'Receipt Number',
    };

    for (final key in keyLabels.keys) {
      if (widget.transaction.containsKey(key)) {
        if (_hiddenDetailKeys.contains(_normalizeKey(key))) {
          continue;
        }
        final value = _displayValueForKey(key, widget.transaction[key]);
        if (value != '--') {
          entries.add({
            'label': _displayLabelForKey(key, keyLabels),
            'value': value,
          });
          if (key == 'trnsAmt') {
            final tenderValue = _firstTenderText();
            if (tenderValue != '--') {
              entries.add({'label': 'Tender', 'value': tenderValue});
            }
          }
        }
      }
    }

    for (final entry in widget.transaction.entries) {
      if (keyLabels.containsKey(entry.key) ||
          entry.key == 'trnsFiles' ||
          entry.key == 'trnsTender') {
        continue;
      }
      if (_hiddenDetailKeys.contains(_normalizeKey(entry.key))) {
        continue;
      }
      final value = _displayValueForKey(entry.key, entry.value);
      if (value != '--') {
        entries.add({'label': _toTitleWords(entry.key), 'value': value});
      }
    }

    return entries;
  }

  List<Map<String, String>> _bankInstrumentTenderDetails() {
    dynamic raw = widget.transaction['bankInstrumentTenderDetails'];
    raw ??= widget.transaction['bankInstrumentTender'];
    raw ??= widget.transaction['trnsTender'];

    if (raw is String && raw.trim().isNotEmpty) {
      final text = raw.trim();
      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          raw = jsonDecode(text);
        } catch (_) {
          return const <Map<String, String>>[];
        }
      }
    }

    final instruments = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          instruments.add(Map<String, dynamic>.from(item));
        }
      }
    } else if (raw is Map) {
      instruments.add(Map<String, dynamic>.from(raw));
    }

    final result = <Map<String, String>>[];
    for (final instrument in instruments) {
      final values = <String, String>{};
      for (final entry in instrument.entries) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isEmpty || value.toLowerCase() == 'null') {
          continue;
        }
        final key = entry.key;
        final lowerKey = key.toLowerCase();
        String displayValue = value;
        if (lowerKey.contains('date')) {
          try {
            final parsed = DateTime.parse(value);
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
            displayValue =
                '${parsed.day}-${months[parsed.month]}-${parsed.year}';
          } catch (_) {
            displayValue = value;
          }
        }
        values[_toTitleWords(key)] = key.toLowerCase() == 'amount'
            ? _formatAmount(value)
            : displayValue;
      }
      if (values.isNotEmpty) {
        result.add(values);
      }
    }

    return result;
  }

  Widget _buildBankInstrumentSection(List<Map<String, String>> instruments) {
    if (instruments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DF),
        border: Border.all(color: const Color(0xFFF1D57A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        backgroundColor: const Color(0xFFFFF8DF),
        collapsedBackgroundColor: const Color(0xFFFFF1C6),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        iconColor: _brandColor,
        collapsedIconColor: _brandColor,
        title: const Text(
          'Tender Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF134E47),
          ),
        ),
        children: [
          ...instruments.asMap().entries.map((instrumentEntry) {
            final index = instrumentEntry.key;
            final instrument = instrumentEntry.value;
            return Container(
              margin: EdgeInsets.only(
                bottom: index == instruments.length - 1 ? 0 : 10,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE1ECE9)),
              ),
              child: Column(
                children: instrument.entries
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 170,
                              child: Text(
                                field.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF134E47),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                field.value,
                                style: const TextStyle(
                                  color: Color(0xFF2A4A47),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
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

  Future<void> _openAttachmentZoom(Uint8List bytes) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 6,
                child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = _trnsFiles;
    final safeImageIndex = files.isEmpty
        ? 0
        : _imageIndex.clamp(0, files.length - 1).toInt();
    final currentAttachmentBytes = files.isEmpty
        ? null
        : _decodeBase64Image(files[safeImageIndex]);
    final details = _details();
    final bankInstrumentDetails = _bankInstrumentTenderDetails();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F8F82), Color(0xFF11A193)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Transaction Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
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
              child: Container(
                color: const Color(0xFFF8FBFB),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE1ECE9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14004D45),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              ...details.map(
                                (entry) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7FAFA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          entry['label'] ?? '--',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF134E47),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry['value'] ?? '--',
                                          style: const TextStyle(
                                            color: Color(0xFF2A4A47),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildBankInstrumentSection(
                                bankInstrumentDetails,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (files.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE1ECE9)),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.attachment_rounded,
                                    size: 18,
                                    color: _brandColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Attachments',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF134E47),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (currentAttachmentBytes != null)
                                    IconButton(
                                      tooltip: 'Zoom image',
                                      onPressed: () => _openAttachmentZoom(
                                        currentAttachmentBytes,
                                      ),
                                      icon: const Icon(
                                        Icons.zoom_in_rounded,
                                        color: _brandColor,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    color: const Color(0xFFF4F8F8),
                                    child: Builder(
                                      builder: (_) {
                                        if (currentAttachmentBytes != null) {
                                          return Image.memory(
                                            currentAttachmentBytes,
                                            fit: BoxFit.contain,
                                          );
                                        }
                                        return const Center(
                                          child: Text(
                                            'Cannot Display Image',
                                            style: TextStyle(
                                              color: Color(0xFF6B7F7C),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7F6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      color: _brandColor,
                                      onPressed: _imageIndex == 0
                                          ? null
                                          : () => setState(() {
                                              _imageIndex--;
                                            }),
                                    ),
                                    Text(
                                      '${safeImageIndex + 1} / ${files.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF134E47),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      color: _brandColor,
                                      onPressed: _imageIndex == files.length - 1
                                          ? null
                                          : () => setState(() {
                                              _imageIndex++;
                                            }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
