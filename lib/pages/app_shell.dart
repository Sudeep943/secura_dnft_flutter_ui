import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'booking_page.dart';
import 'home_page.dart';
import 'login_page.dart';
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
    AppSection.skillClass,
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
    const SkillClassManagementPage(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    final visibleSections = _visibleSections();
    _selectedSection = visibleSections.contains(widget.initialSection)
        ? widget.initialSection
        : AppSection.dashboard;
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

  int _pendingWorklistCount(List<Map<String, dynamic>> worklists) {
    return worklists.where((item) {
      final status = item['status']?.toString().trim().toUpperCase() ?? '';
      return status == 'PENDING';
    }).length;
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
      _worklistCount = _pendingWorklistCount(worklists);
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

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == 'y' || text == 'yes';
  }

  Map<String, dynamic> _readAccessMap() {
    final rawAccess = ApiService.userHeader?['access'];
    if (rawAccess is Map<String, dynamic>) {
      return rawAccess;
    }
    if (rawAccess is Map) {
      return Map<String, dynamic>.from(rawAccess);
    }
    if (rawAccess is String) {
      final text = rawAccess.trim();
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

  bool _hasParentAccess(String moduleKey) {
    return true;
  }

  Set<AppSection> _visibleSections() {
    final sections = <AppSection>{AppSection.dashboard, AppSection.finance};

    if (_hasParentAccess('accountManagmentAccess')) {
      sections.add(AppSection.profileManagement);
    }
    if (_hasParentAccess('adminAccess')) {
      sections.add(AppSection.adminSection);
      // Admin child pages are launched from Admin Section cards.
      sections.add(AppSection.roleAndAccess);
      sections.add(AppSection.flatManagement);
      sections.add(AppSection.staffManagement);
    }
    if (_hasParentAccess('bookingAccess')) {
      sections.add(AppSection.bookings);
    }
    if (_hasParentAccess('meetingAndNoticeAccess')) {
      sections.add(AppSection.meetingAndNotice);
    }
    if (_hasParentAccess('ticketManagementAccess')) {
      sections.add(AppSection.ticketManagement);
    }
    if (_hasParentAccess('securityAccess')) {
      sections.add(AppSection.security);
    }
    if (_hasParentAccess('vendorManagementAccess')) {
      sections.add(AppSection.vendorManagement);
    }
    if (_hasParentAccess('reportAccess')) {
      sections.add(AppSection.reports);
    }
    if (_hasParentAccess('groupManagmentAccess')) {
      sections.add(AppSection.groupManagement);
    }
    if (_hasParentAccess('skillClassAccess')) {
      sections.add(AppSection.skillClass);
    }

    return sections;
  }

  void _selectSection(AppSection section) {
    final visibleSections = _visibleSections();
    if (!visibleSections.contains(section)) {
      _showShellMessage('You do not have access to this module.');
      return;
    }

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
      _worklistCount = _pendingWorklistCount(worklists);
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
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showShellMessage(
              'You have $_notificationCount pending community notifications.',
            ),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Worklist',
            onPressed: _openWorklistModal,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
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
          ),
          if (!_worklistCountLoading)
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
                  '$_worklistCount',
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

  Future<void> _handleSignOut() async {
    ApiService.clearSession();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: TextButton.icon(
        onPressed: _handleSignOut,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign Out'),
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
    final visibleSections = _visibleSections();
    if (!visibleSections.contains(_selectedSection)) {
      _selectedSection = AppSection.dashboard;
    }
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
          _buildSignOutButton(),
        ],
      ),
      drawer: mobile
          ? Drawer(
              child: SideBar(
                selectedSection: _selectedSection,
                onSectionSelected: _selectSection,
                visibleSections: visibleSections,
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
                visibleSections: visibleSections,
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

enum _WorklistTabKind { pending, completed }

class _WorklistDialogState extends State<_WorklistDialog>
    with SingleTickerProviderStateMixin {
  static const String _transactionReviewType = 'TRANSACTION REVIEW';
  static const Color _brandColor = Color(0xFF0F8F82);

  late List<Map<String, dynamic>> _worklists = widget.initialWorklists;
  final Map<String, bool> _loadingTransaction = {};
  final Set<String> _expandedWorklistIds = <String>{};
  final Set<String> _pendingSelectedTypes = <String>{};
  final Set<String> _pendingSelectedFlatNos = <String>{};
  final Set<String> _pendingSelectedTenders = <String>{};
  DateTime? _pendingSelectedTransactionFromDate;
  DateTime? _pendingSelectedTransactionToDate;
  final Set<String> _completedSelectedTypes = <String>{};
  final Set<String> _completedSelectedFlatNos = <String>{};
  final Set<String> _completedSelectedTenders = <String>{};
  DateTime? _completedSelectedTransactionFromDate;
  DateTime? _completedSelectedTransactionToDate;
  bool _pendingSortFromDateAscending = false;
  bool _completedSortFromDateAscending = false;
  String? _pendingFilterFallbackMessage;
  String? _completedFilterFallbackMessage;
  Timer? _pendingFilterFallbackTimer;
  Timer? _completedFilterFallbackTimer;
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
    _pendingFilterFallbackTimer?.cancel();
    _completedFilterFallbackTimer?.cancel();
    _statusGlowController.dispose();
    super.dispose();
  }

  void _showFilterFallbackMessage(_WorklistTabKind tab, String message) {
    if (tab == _WorklistTabKind.pending) {
      _pendingFilterFallbackTimer?.cancel();
      _pendingFilterFallbackMessage = message;
      _pendingFilterFallbackTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _pendingFilterFallbackMessage = null);
        }
      });
    } else {
      _completedFilterFallbackTimer?.cancel();
      _completedFilterFallbackMessage = message;
      _completedFilterFallbackTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _completedFilterFallbackMessage = null);
        }
      });
    }
  }

  void _clearFilterFallbackMessage(_WorklistTabKind tab) {
    if (tab == _WorklistTabKind.pending) {
      _pendingFilterFallbackTimer?.cancel();
      _pendingFilterFallbackMessage = null;
    } else {
      _completedFilterFallbackTimer?.cancel();
      _completedFilterFallbackMessage = null;
    }
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

  DateTime? _createdDate(Map<String, dynamic> item) {
    final raw = item['creatTs']?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  List<Map<String, dynamic>> _sortRowsByFromDate(
    List<Map<String, dynamic>> rows,
    _WorklistTabKind tab,
  ) {
    final sorted = List<Map<String, dynamic>>.from(rows);
    final ascending = tab == _WorklistTabKind.pending
        ? _pendingSortFromDateAscending
        : _completedSortFromDateAscending;

    sorted.sort((a, b) {
      final aDate = _createdDate(a);
      final bDate = _createdDate(b);

      int compare;
      if (aDate == null && bDate == null) {
        compare = 0;
      } else if (aDate == null) {
        compare = 1;
      } else if (bDate == null) {
        compare = -1;
      } else {
        compare = aDate.compareTo(bDate);
      }

      return ascending ? compare : -compare;
    });

    return sorted;
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
    final canOpenReference =
        referenceId.isNotEmpty && isTransactionReview && !isLoading;

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
            onTap: isTransactionReview
                ? null
                : () {
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
                  if (!isTransactionReview) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF26514D),
                    ),
                  ],
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: canOpenReference
                        ? () => _openTransactionDetails(item)
                        : null,
                    child: Opacity(
                      opacity: referenceId.isEmpty ? 0.55 : 1,
                      child: _metaPill(
                        icon: Icons.confirmation_number_outlined,
                        text:
                            'Reference: ${referenceId.isEmpty ? '--' : referenceId}',
                      ),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: !isTransactionReview && isExpanded
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

  String _worklistStatus(Map<String, dynamic> item) {
    return item['status']?.toString().trim().toUpperCase() ?? '';
  }

  List<Map<String, dynamic>> get _pendingWorklists {
    return _worklists
        .where((item) => _worklistStatus(item) == 'PENDING')
        .toList();
  }

  List<Map<String, dynamic>> get _completedWorklists {
    return _worklists
        .where((item) => _worklistStatus(item) == 'COMPLETE')
        .toList();
  }

  String _flatNoValue(Map<String, dynamic> item) {
    final value = item['flatNo']?.toString().trim() ?? '';
    return value.isEmpty ? '--' : value;
  }

  String _typeValue(Map<String, dynamic> item) {
    final value = item['worklistType']?.toString().trim() ?? '';
    return value.isEmpty ? '--' : value;
  }

  List<String> _distinctFlatNoOptions(List<Map<String, dynamic>> rows) {
    final values = rows.map(_flatNoValue).toSet().toList()..sort();
    return values;
  }

  List<String> _distinctTypeOptions(List<Map<String, dynamic>> rows) {
    final values = rows.map(_typeValue).toSet().toList()..sort();
    return values;
  }

  String _normalizeTenderText(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
      return '';
    }
    return normalized.replaceAll('_', ' ').toUpperCase();
  }

  DateTime? _parseWorklistDate(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    final text = rawValue.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed;
    }

    return null;
  }

  DateTime? _transactionDateValue(Map<String, dynamic> item) {
    final candidates = [
      item['trnsDate'],
      item['transactionDate'],
      item['transaction_date'],
      item['transDate'],
      item['creatTs'],
      item['createdAt'],
    ];

    for (final candidate in candidates) {
      final parsed = _parseWorklistDate(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    final nestedTransaction = item['transaction'];
    if (nestedTransaction is Map) {
      return _transactionDateValue(
        Map<String, dynamic>.from(nestedTransaction),
      );
    }

    return null;
  }

  bool _matchesTransactionDate(
    Map<String, dynamic> item,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (fromDate == null && toDate == null) {
      return true;
    }

    final transactionDate = _transactionDateValue(item);
    if (transactionDate == null) {
      return false;
    }

    if (fromDate != null) {
      final fromStart = DateTime(fromDate.year, fromDate.month, fromDate.day);
      if (transactionDate.isBefore(fromStart)) {
        return false;
      }
    }

    if (toDate != null) {
      final toEnd = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
      if (transactionDate.isAfter(toEnd)) {
        return false;
      }
    }

    return true;
  }

  Set<String> _tenderValues(Map<String, dynamic> item) {
    final values = <String>{};

    void addValue(dynamic raw) {
      final text = _normalizeTenderText(raw?.toString() ?? '');
      if (text.isNotEmpty) {
        values.add(text);
      }
    }

    final directCandidates = [
      item['tenderName'],
      item['tenderType'],
      item['paymentTenderType'],
      item['bankInstrumentTenderType'],
      item['mode'],
    ];
    for (final candidate in directCandidates) {
      addValue(candidate);
    }

    final rawTenders = item['trnsTender'];
    if (rawTenders is List) {
      for (final entry in rawTenders) {
        if (entry is Map) {
          addValue(entry['tenderName']);
          addValue(entry['tenderType']);
          addValue(entry['paymentTenderType']);
        } else {
          addValue(entry);
        }
      }
    }

    return values;
  }

  List<String> _distinctTenderOptions(List<Map<String, dynamic>> rows) {
    final values = <String>{};
    for (final row in rows) {
      values.addAll(_tenderValues(row));
    }
    final result = values.toList()..sort();
    return result;
  }

  Set<String> _selectedTypesForTab(_WorklistTabKind tab) {
    return tab == _WorklistTabKind.pending
        ? _pendingSelectedTypes
        : _completedSelectedTypes;
  }

  Set<String> _selectedFlatNosForTab(_WorklistTabKind tab) {
    return tab == _WorklistTabKind.pending
        ? _pendingSelectedFlatNos
        : _completedSelectedFlatNos;
  }

  Set<String> _selectedTendersForTab(_WorklistTabKind tab) {
    return tab == _WorklistTabKind.pending
        ? _pendingSelectedTenders
        : _completedSelectedTenders;
  }

  int _activeFilterCount(_WorklistTabKind tab) {
    final selectedFromDate = tab == _WorklistTabKind.pending
        ? _pendingSelectedTransactionFromDate
        : _completedSelectedTransactionFromDate;
    final selectedToDate = tab == _WorklistTabKind.pending
        ? _pendingSelectedTransactionToDate
        : _completedSelectedTransactionToDate;
    return _selectedTypesForTab(tab).length +
        _selectedFlatNosForTab(tab).length +
        _selectedTendersForTab(tab).length +
        (selectedFromDate == null && selectedToDate == null ? 0 : 1);
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> rows,
    _WorklistTabKind tab,
  ) {
    final selectedTypes = _selectedTypesForTab(tab);
    final selectedFlatNos = _selectedFlatNosForTab(tab);
    final selectedTenders = _selectedTendersForTab(tab);
    final selectedFromDate = tab == _WorklistTabKind.pending
        ? _pendingSelectedTransactionFromDate
        : _completedSelectedTransactionFromDate;
    final selectedToDate = tab == _WorklistTabKind.pending
        ? _pendingSelectedTransactionToDate
        : _completedSelectedTransactionToDate;
    return rows.where((item) {
      final typeMatches =
          selectedTypes.isEmpty || selectedTypes.contains(_typeValue(item));
      final flatMatches =
          selectedFlatNos.isEmpty ||
          selectedFlatNos.contains(_flatNoValue(item));
      final itemTenders = _tenderValues(item);
      final tenderMatches =
          selectedTenders.isEmpty || itemTenders.any(selectedTenders.contains);
      final dateMatches = _matchesTransactionDate(
        item,
        selectedFromDate,
        selectedToDate,
      );
      return typeMatches && flatMatches && tenderMatches && dateMatches;
    }).toList();
  }

  Future<void> _openFilterDialog(
    _WorklistTabKind tab,
    List<Map<String, dynamic>> sourceRows,
  ) async {
    final typeOptions = _distinctTypeOptions(sourceRows);
    final flatNoOptions = _distinctFlatNoOptions(sourceRows);
    final flatNoCounts = <String, int>{};
    for (final item in sourceRows) {
      final flatNo = _flatNoValue(item);
      flatNoCounts[flatNo] = (flatNoCounts[flatNo] ?? 0) + 1;
    }
    final transactionReviewRows = sourceRows
        .where(
          (item) => _typeValue(item).toUpperCase() == _transactionReviewType,
        )
        .toList(growable: false);
    final tenderOptions = _distinctTenderOptions(transactionReviewRows);
    final tempTypes = Set<String>.from(_selectedTypesForTab(tab));
    final tempFlats = Set<String>.from(_selectedFlatNosForTab(tab));
    final tempTenders = Set<String>.from(_selectedTendersForTab(tab));
    var tempTransactionFromDate = tab == _WorklistTabKind.pending
        ? _pendingSelectedTransactionFromDate
        : _completedSelectedTransactionFromDate;
    var tempTransactionToDate = tab == _WorklistTabKind.pending
        ? _pendingSelectedTransactionToDate
        : _completedSelectedTransactionToDate;
    var flatSearchText = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            final isTransactionReviewSelected = tempTypes.any(
              (value) => value.toUpperCase() == _transactionReviewType,
            );
            final normalizedFlatSearch = flatSearchText.trim().toLowerCase();
            final filteredFlatNoOptions = normalizedFlatSearch.isEmpty
                ? flatNoOptions
                : flatNoOptions
                      .where(
                        (value) =>
                            value.toLowerCase().contains(normalizedFlatSearch),
                      )
                      .toList();
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                              Icons.filter_alt_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Filter Worklists',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Filter sections ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: SizedBox(
                        width: 420,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFDCEAE7),
                                  ),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: false,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  title: const Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  children: typeOptions.isEmpty
                                      ? const [
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              12,
                                              0,
                                              12,
                                              12,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'No type values found',
                                              ),
                                            ),
                                          ),
                                        ]
                                      : typeOptions
                                            .map(
                                              (value) => CheckboxListTile(
                                                dense: true,
                                                value: tempTypes.contains(
                                                  value,
                                                ),
                                                title: Text(value),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                onChanged: (selected) {
                                                  setInnerState(() {
                                                    if (selected == true) {
                                                      tempTypes.add(value);
                                                    } else {
                                                      tempTypes.remove(value);
                                                    }
                                                  });
                                                },
                                              ),
                                            )
                                            .toList(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFDCEAE7),
                                  ),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: false,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  title: const Text(
                                    'Flat No',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  children: flatNoOptions.isEmpty
                                      ? const [
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              12,
                                              0,
                                              12,
                                              12,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'No flat values found',
                                              ),
                                            ),
                                          ),
                                        ]
                                      : [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              4,
                                              12,
                                              8,
                                            ),
                                            child: TextField(
                                              onChanged: (value) {
                                                setInnerState(() {
                                                  flatSearchText = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Search Flat No',
                                                isDense: true,
                                                prefixIcon: const Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFDCEAE7,
                                                            ),
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFF0F8F82,
                                                            ),
                                                            width: 1.2,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          if (filteredFlatNoOptions.isEmpty)
                                            const Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                12,
                                                0,
                                                12,
                                                12,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'No matching flat numbers',
                                                ),
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              height: 236,
                                              child: Scrollbar(
                                                thumbVisibility: true,
                                                child: ListView.builder(
                                                  itemCount:
                                                      filteredFlatNoOptions
                                                          .length,
                                                  itemBuilder: (context, index) {
                                                    final value =
                                                        filteredFlatNoOptions[index];
                                                    final count =
                                                        flatNoCounts[value] ??
                                                        0;
                                                    return CheckboxListTile(
                                                      dense: true,
                                                      value: tempFlats.contains(
                                                        value,
                                                      ),
                                                      title: Text(
                                                        '$value ($count)',
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                          ),
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                      onChanged: (selected) {
                                                        setInnerState(() {
                                                          if (selected ==
                                                              true) {
                                                            tempFlats.add(
                                                              value,
                                                            );
                                                          } else {
                                                            tempFlats.remove(
                                                              value,
                                                            );
                                                          }
                                                        });
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFDCEAE7),
                                  ),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: false,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  title: const Text(
                                    'Transaction Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        0,
                                        12,
                                        12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Transaction From',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              final picked = await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    tempTransactionFromDate ??
                                                    DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100),
                                              );
                                              if (picked != null) {
                                                setInnerState(() {
                                                  tempTransactionFromDate =
                                                      picked;
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFDCEAE7,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 18,
                                                    color: Color(0xFF0F8F82),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      tempTransactionFromDate ==
                                                              null
                                                          ? 'Select from date'
                                                          : '${tempTransactionFromDate!.day.toString().padLeft(2, '0')}-${tempTransactionFromDate!.month.toString().padLeft(2, '0')}-${tempTransactionFromDate!.year}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  if (tempTransactionFromDate !=
                                                      null)
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed: () {
                                                        setInnerState(() {
                                                          tempTransactionFromDate =
                                                              null;
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 18,
                                                      ),
                                                      tooltip: 'Clear date',
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Transaction To',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        tempTransactionToDate ??
                                                        DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null) {
                                                setInnerState(() {
                                                  tempTransactionToDate =
                                                      picked;
                                                });
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFDCEAE7,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 18,
                                                    color: Color(0xFF0F8F82),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      tempTransactionToDate ==
                                                              null
                                                          ? 'Select to date'
                                                          : '${tempTransactionToDate!.day.toString().padLeft(2, '0')}-${tempTransactionToDate!.month.toString().padLeft(2, '0')}-${tempTransactionToDate!.year}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  if (tempTransactionToDate !=
                                                      null)
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed: () {
                                                        setInnerState(() {
                                                          tempTransactionToDate =
                                                              null;
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.clear_rounded,
                                                        size: 18,
                                                      ),
                                                      tooltip: 'Clear date',
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isTransactionReviewSelected) ...[
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7FAFA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFDCEAE7),
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    initiallyExpanded: false,
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    title: const Text(
                                      'Tender',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    children: tenderOptions.isEmpty
                                        ? const [
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                12,
                                                0,
                                                12,
                                                12,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'No tender values found',
                                                ),
                                              ),
                                            ),
                                          ]
                                        : tenderOptions
                                              .map(
                                                (value) => CheckboxListTile(
                                                  dense: true,
                                                  value: tempTenders.contains(
                                                    value,
                                                  ),
                                                  title: Text(value),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  controlAffinity:
                                                      ListTileControlAffinity
                                                          .leading,
                                                  onChanged: (selected) {
                                                    setInnerState(() {
                                                      if (selected == true) {
                                                        tempTenders.add(value);
                                                      } else {
                                                        tempTenders.remove(
                                                          value,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              )
                                              .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ── Action buttons ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedTypesForTab(tab).clear();
                                _selectedFlatNosForTab(tab).clear();
                                _selectedTendersForTab(tab).clear();
                                if (tab == _WorklistTabKind.pending) {
                                  _pendingSelectedTransactionFromDate = null;
                                  _pendingSelectedTransactionToDate = null;
                                } else {
                                  _completedSelectedTransactionFromDate = null;
                                  _completedSelectedTransactionToDate = null;
                                }
                                _clearFilterFallbackMessage(tab);
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F8F82),
                            ),
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                final selectedTypes = _selectedTypesForTab(tab);
                                final selectedFlats = _selectedFlatNosForTab(
                                  tab,
                                );
                                final selectedTenders = _selectedTendersForTab(
                                  tab,
                                );
                                selectedTypes
                                  ..clear()
                                  ..addAll(tempTypes);
                                selectedFlats
                                  ..clear()
                                  ..addAll(tempFlats);
                                if (isTransactionReviewSelected) {
                                  selectedTenders
                                    ..clear()
                                    ..addAll(tempTenders);
                                } else {
                                  selectedTenders.clear();
                                }
                                if (tab == _WorklistTabKind.pending) {
                                  _pendingSelectedTransactionFromDate =
                                      tempTransactionFromDate;
                                  _pendingSelectedTransactionToDate =
                                      tempTransactionToDate;
                                } else {
                                  _completedSelectedTransactionFromDate =
                                      tempTransactionFromDate;
                                  _completedSelectedTransactionToDate =
                                      tempTransactionToDate;
                                }
                                _clearFilterFallbackMessage(tab);
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F8F82),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorklistTabBody({
    required _WorklistTabKind tab,
    required List<Map<String, dynamic>> sourceRows,
    required List<Map<String, dynamic>> rows,
    required String emptyMessage,
    required String? filterFallbackMessage,
  }) {
    final sortedRows = _sortRowsByFromDate(rows, tab);
    final sortAscending = tab == _WorklistTabKind.pending
        ? _pendingSortFromDateAscending
        : _completedSortFromDateAscending;

    if (rows.isEmpty) {
      return Center(
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
            Text(
              emptyMessage,
              style: const TextStyle(
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
      );
    }

    final toolbarControls = <Widget>[
      _metaPill(
        icon: Icons.format_list_bulleted_rounded,
        text: '${rows.length} total items',
      ),
      OutlinedButton.icon(
        onPressed: () => _openFilterDialog(tab, sourceRows),
        icon: const Icon(Icons.filter_alt_rounded, size: 18),
        label: Text(
          _activeFilterCount(tab) == 0
              ? 'Filter'
              : 'Filter (${_activeFilterCount(tab)})',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandColor,
          side: const BorderSide(color: Color(0xFF9FD2CB)),
        ),
      ),
      OutlinedButton.icon(
        onPressed: () {
          setState(() {
            if (tab == _WorklistTabKind.pending) {
              _pendingSortFromDateAscending = !_pendingSortFromDateAscending;
            } else {
              _completedSortFromDateAscending =
                  !_completedSortFromDateAscending;
            }
          });
        },
        icon: Icon(
          sortAscending
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 18,
        ),
        label: Text(sortAscending ? 'From Date Asc' : 'From Date Desc'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandColor,
          side: const BorderSide(color: Color(0xFF9FD2CB)),
        ),
      ),
    ];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Wrap(spacing: 8, runSpacing: 8, children: toolbarControls),
            ),
            if (filterFallbackMessage != null) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    filterFallbackMessage,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: sortedRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _buildWorklistCard(sortedRows[index]),
          ),
        ),
      ],
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
    final status = item['status']?.toString().trim().toUpperCase() ?? '';
    final canTakeAction = !status.startsWith('COMPLETE');
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
    final rawExternalDetails = response?['externalTransactionNoDetails'];
    final externalTransactionNoDetails = rawExternalDetails is Map
        ? Map<String, dynamic>.from(rawExternalDetails)
        : null;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _TransactionDetailDialog(
        transaction: transaction,
        transactionId: referenceId,
        worklistId: worklistId,
        canTakeAction: canTakeAction,
        externalTransactionNoDetails: externalTransactionNoDetails,
        onActionCompleted: _refreshWorklists,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _hasFiltersApplied(_WorklistTabKind tab) {
      final types = _selectedTypesForTab(tab);
      final flats = _selectedFlatNosForTab(tab);
      final tenders = _selectedTendersForTab(tab);
      final fromDate = tab == _WorklistTabKind.pending
          ? _pendingSelectedTransactionFromDate
          : _completedSelectedTransactionFromDate;
      final toDate = tab == _WorklistTabKind.pending
          ? _pendingSelectedTransactionToDate
          : _completedSelectedTransactionToDate;
      return types.isNotEmpty ||
          flats.isNotEmpty ||
          tenders.isNotEmpty ||
          fromDate != null ||
          toDate != null;
    }

    void _clearFilters(_WorklistTabKind tab) {
      if (tab == _WorklistTabKind.pending) {
        _pendingSelectedTypes.clear();
        _pendingSelectedFlatNos.clear();
        _pendingSelectedTenders.clear();
        _pendingSelectedTransactionFromDate = null;
        _pendingSelectedTransactionToDate = null;
      } else {
        _completedSelectedTypes.clear();
        _completedSelectedFlatNos.clear();
        _completedSelectedTenders.clear();
        _completedSelectedTransactionFromDate = null;
        _completedSelectedTransactionToDate = null;
      }
    }

    final pendingSource = _pendingWorklists;
    final completedSource = _completedWorklists;
    var pending = _applyFilters(pendingSource, _WorklistTabKind.pending);
    var completed = _applyFilters(completedSource, _WorklistTabKind.completed);

    var pendingEmptyMessage = 'No pending worklists found';
    var completedEmptyMessage = 'No completed worklists found';

    if (pending.isEmpty && _hasFiltersApplied(_WorklistTabKind.pending)) {
      _clearFilters(_WorklistTabKind.pending);
      pending = _applyFilters(pendingSource, _WorklistTabKind.pending);
      pendingEmptyMessage =
          'No Worklist Available For Applied Filter Showing All Worklist';
      _showFilterFallbackMessage(_WorklistTabKind.pending, pendingEmptyMessage);
    }

    if (completed.isEmpty && _hasFiltersApplied(_WorklistTabKind.completed)) {
      _clearFilters(_WorklistTabKind.completed);
      completed = _applyFilters(completedSource, _WorklistTabKind.completed);
      completedEmptyMessage =
          'No Worklist Available For Applied Filter Showing All Worklist';
      _showFilterFallbackMessage(
        _WorklistTabKind.completed,
        completedEmptyMessage,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: _modalMaxHeight(context),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 8),
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
                child: Column(
                  children: [
                    Row(
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
                            children: const [
                              Text(
                                'Worklists',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap each worklist to expand',
                                style: TextStyle(
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
                    const SizedBox(height: 4),
                    TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFFD7F0EC),
                      indicatorColor: Colors.white,
                      indicatorWeight: 2.6,
                      tabs: [
                        Tab(text: 'Pending (${pending.length})'),
                        Tab(text: 'Completed (${completed.length})'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FBFB),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: TabBarView(
                    children: [
                      _buildWorklistTabBody(
                        tab: _WorklistTabKind.pending,
                        sourceRows: pendingSource,
                        rows: pending,
                        emptyMessage: pendingEmptyMessage,
                        filterFallbackMessage: _pendingFilterFallbackMessage,
                      ),
                      _buildWorklistTabBody(
                        tab: _WorklistTabKind.completed,
                        sourceRows: completedSource,
                        rows: completed,
                        emptyMessage: completedEmptyMessage,
                        filterFallbackMessage: _completedFilterFallbackMessage,
                      ),
                    ],
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

class _TransactionDetailDialog extends StatefulWidget {
  const _TransactionDetailDialog({
    required this.transaction,
    required this.transactionId,
    required this.worklistId,
    required this.canTakeAction,
    this.externalTransactionNoDetails,
    required this.onActionCompleted,
  });

  final Map<String, dynamic> transaction;
  final String transactionId;
  final String worklistId;
  final bool canTakeAction;
  final Map<String, dynamic>? externalTransactionNoDetails;
  final Future<void> Function() onActionCompleted;

  @override
  State<_TransactionDetailDialog> createState() =>
      _TransactionDetailDialogState();
}

class _TransactionDetailDialogState extends State<_TransactionDetailDialog>
    with SingleTickerProviderStateMixin {
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
    'createdby',
    'createdbyname',
    'createdusername',
    'noofperson',
    'numberofperson',
  };

  int _imageIndex = 0;
  String? _loadingAction;
  bool _isEditingReferenceId = false;
  bool _isSavingReferenceId = false;
  bool _showReferenceSavedMessage = false;
  Timer? _referenceSavedMessageTimer;
  late final TextEditingController _referenceIdController;
  late Map<String, dynamic>? _externalTransactionNoDetails;
  late final AnimationController _duplicateWarningController;

  @override
  void initState() {
    super.initState();
    _referenceIdController = TextEditingController(text: _thirdPartyTrnsRef);
    _externalTransactionNoDetails = widget.externalTransactionNoDetails;
    _duplicateWarningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _referenceSavedMessageTimer?.cancel();
    _referenceIdController.dispose();
    _duplicateWarningController.dispose();
    super.dispose();
  }

  bool get _isDuplicateBankTransactionId {
    final value = _externalTransactionNoDetails?['usedInMultipleTransction'];
    return value == true || value?.toString().trim().toLowerCase() == 'true';
  }

  bool _isHeadCountKey(String key) {
    return _normalizeKey(key).contains('head');
  }

  bool _isThirdPartyTrnsRefKey(String key) {
    return _normalizeKey(key) == 'thirdpartytrnsref';
  }

  bool _isExternalTransactionReferenceKey(String key) {
    final normalized = _normalizeKey(key);
    return normalized.contains('external') &&
        (normalized.contains('reference') || normalized.contains('trnsref'));
  }

  String get _thirdPartyTrnsRef {
    for (final entry in widget.transaction.entries) {
      if (_isThirdPartyTrnsRefKey(entry.key)) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }
    for (final entry in widget.transaction.entries) {
      if (_isExternalTransactionReferenceKey(entry.key)) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }
    return '';
  }

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

  List<Map<String, String>> _tenderEntries() {
    final rawTender = widget.transaction['trnsTender'];
    if (rawTender is! List || rawTender.isEmpty) {
      return const <Map<String, String>>[];
    }

    final entries = <Map<String, String>>[];
    for (final item in rawTender) {
      if (item is! Map) {
        continue;
      }
      final tender = Map<String, dynamic>.from(item);
      final tenderName = tender['tenderName']?.toString().trim() ?? '';
      final amountPaid = tender['amountPaid']?.toString().trim() ?? '';
      if (tenderName.isEmpty && amountPaid.isEmpty) {
        continue;
      }
      entries.add({
        'tenderName': tenderName.isEmpty ? '--' : _toTitleWords(tenderName),
        'amountPaid': amountPaid.isEmpty ? '--' : _formatAmount(amountPaid),
      });
    }

    return entries;
  }

  String _joinedTenderText() {
    final tenderEntries = _tenderEntries();
    if (tenderEntries.isEmpty) {
      return '--';
    }

    return tenderEntries
        .map((entry) => entry['tenderName'] ?? '--')
        .where((value) => value.trim().isNotEmpty && value != '--')
        .join(', ');
  }

  String _displayLabelForKey(String key, Map<String, String> labels) {
    final configured = labels[key] ?? key;
    return _toTitleWords(configured);
  }

  String _normalizeKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _isPaymentNameKey(String key) {
    final normalized = _normalizeKey(key);
    return normalized == 'paymentname' ||
        normalized == 'pymntname' ||
        normalized == 'pymntnm';
  }

  bool _isTransactionIdKey(String key) {
    final normalized = _normalizeKey(key);
    return normalized == 'transactionid' ||
        normalized == 'trnscid' ||
        normalized == 'trnsid';
  }

  bool _isBankAccountKey(String key) {
    final normalized = _normalizeKey(key);
    return normalized == 'trnsbnkaccnt' ||
        normalized == 'bankaccount' ||
        normalized == 'bankaccnt';
  }

  bool _isCreatorUserIdKey(String key) {
    final normalized = _normalizeKey(key);
    return (normalized.contains('userid') || normalized.contains('usrid')) &&
        (normalized.startsWith('creat') || normalized.startsWith('create'));
  }

  String _creatorUserId() {
    for (final entry in widget.transaction.entries) {
      if (_isCreatorUserIdKey(entry.key)) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }
    return '';
  }

  bool _isOwnerNameKey(String key) {
    final normalized = _normalizeKey(key);
    return normalized.startsWith('owner') && normalized.contains('name');
  }

  bool _isFlatIdKey(String key) {
    return _normalizeKey(key) == 'flatid';
  }

  bool _isCauseKey(String key) {
    return _normalizeKey(key) == 'cause';
  }

  int _detailPriority(String key) {
    if (_isPaymentNameKey(key)) return 0;
    if (_isFlatIdKey(key)) return 1;
    if (_isOwnerNameKey(key)) return 2;
    if (_isCauseKey(key)) return 3;
    if (_isTransactionIdKey(key)) return 4;
    return 5;
  }

  bool _isTransactionDueDetailsKey(String key) {
    final normalized = _normalizeKey(key);
    return normalized == 'duedeatilslistoftransaction' ||
        normalized == 'duedetailslistoftransaction';
  }

  List<Map<String, dynamic>> _transactionDueDetails() {
    for (final entry in widget.transaction.entries) {
      final rawDues = entry.value;
      if (_isTransactionDueDetailsKey(entry.key) && rawDues is List) {
        return rawDues
            .whereType<Map>()
            .map((due) => Map<String, dynamic>.from(due))
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  String _dueDetailText(Map<String, dynamic> due, String key) {
    final text = due[key]?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? '--' : text;
  }

  bool _isZeroDueAmount(String value) {
    final normalized = value.replaceAll(',', '').replaceAll('₹', '').trim();
    final amount = double.tryParse(normalized);
    return amount != null && amount == 0;
  }

  Widget _buildTransactionDueDetailsSection() {
    final dues = _transactionDueDetails();
    if (dues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          title: const Text(
            'Due Details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF134E47),
            ),
          ),
          children: dues
              .map(_buildTransactionDueDetailTile)
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildTransactionDueDetailTile(Map<String, dynamic> due) {
    final cycle = _toTitleWords(_dueDetailText(due, 'collectionCycle'));
    final dueStartDate = _dueDetailText(due, 'dueStartDate');
    final dueEndDate = _dueDetailText(due, 'dueEndDate');
    final totalAmount = _dueDetailText(due, 'totalAmount');
    final dueAmount = totalAmount == '--'
        ? totalAmount
        : _formatAmount(totalAmount);
    final summaryFirstLine = 'Cycle: $cycle | Due Amount: $dueAmount';
    final summarySecondLine =
        'Due Start Date: $dueStartDate | Due End Date: $dueEndDate';
    final detailRows = <Map<String, String>>[];

    final grossAmount = _dueDetailText(due, 'amount');
    if (grossAmount != '--') {
      detailRows.add({
        'label': 'Gross Amount',
        'value': _formatAmount(grossAmount),
      });
    }

    const optionalAmountFields = {
      'gstAmount': 'GST Amount',
      'roundUpAmount': 'Round Up Amount',
      'discountedAmount': 'Discounted Amount',
      'fineAmount': 'Fine Amount',
    };
    for (final field in optionalAmountFields.entries) {
      final value = _dueDetailText(due, field.key);
      if (value != '--' && !_isZeroDueAmount(value)) {
        detailRows.add({
          'label': field.value,
          'value': _formatAmount(value),
        });
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1ECE9)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summaryFirstLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2A4A47),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                summarySecondLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2A4A47),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          children: detailRows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          row['label']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF134E47),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row['value']!,
                          style: const TextStyle(
                            color: Color(0xFF2A4A47),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  List<String> _formatOwnerNames(dynamic value) {
    if (value is List) {
      return value
          .expand((entry) => _formatOwnerNames(entry))
          .where((name) => name.isNotEmpty)
          .toList();
    }

    if (value is Map) {
      final name =
          value['name'] ??
          value['ownerName'] ??
          value['fullName'] ??
          value['profileName'];
      return name == null ? const <String>[] : _formatOwnerNames(name);
    }

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return const <String>[];
    }
    return [_toTitleWords(text)];
  }

  String _displayValueForKey(String key, dynamic value) {
    if (_isOwnerNameKey(key)) {
      final ownerNames = _formatOwnerNames(value);
      return ownerNames.isEmpty ? '--' : ownerNames.join('\n');
    }

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

    if (_isBankAccountKey(key)) {
      return text;
    }

    if (_looksLikeIdentifier(key)) {
      return text;
    }

    return _toTitleWords(text);
  }

  List<Map<String, String>> _details() {
    final entries = <Map<String, String>>[];
    final keyLabels = <String, String>{
      'paymentName': 'Payment Name',
      'pymntName': 'Payment Name',
      'pymntNm': 'Payment Name',
      'trnscId': 'Transaction ID',
      'transactionId': 'Transaction ID',
      'flatId': 'Flat ID',
      'ownerName': 'Owner Name',
      'ownerNames': 'Owner Name',
      'trnsDate': 'Transaction Date Time',
      'trnsType': 'Type',
      'trnsAmt': 'Amount',
      'trnsStatus': 'Status',
      'cause': 'Cause',
      'pymntId': 'Payment ID',
      'trnsBnkAccnt': 'Bank Account',
      'receiptNumber': 'Receipt Number',
      'trnsBy': 'Done By',
    };

    final transactionData = Map<String, dynamic>.from(widget.transaction);
    final responseTransactionId = transactionData.entries
        .where((entry) => _isTransactionIdKey(entry.key))
        .map((entry) => entry.value?.toString().trim() ?? '')
        .firstWhere(
          (value) => value.isNotEmpty && value.toLowerCase() != 'null',
          orElse: () => '',
        );
    transactionData.removeWhere((key, _) => _isTransactionIdKey(key));
    final transactionId = responseTransactionId.isNotEmpty
        ? responseTransactionId
        : widget.transactionId.trim();
    if (transactionId.isNotEmpty) {
      transactionData['transactionId'] = transactionId;
    }

    final transactionEntries = transactionData.entries.toList()
      ..sort((left, right) {
        final priorityCompare = _detailPriority(
          left.key,
        ).compareTo(_detailPriority(right.key));
        if (priorityCompare != 0) return priorityCompare;
        return 0;
      });

    for (final entry in transactionEntries) {
      final key = entry.key;
      final normalizedKey = _normalizeKey(entry.key);
      if (entry.key == 'trnsFiles' || entry.key == 'trnsTender') {
        continue;
      }
      if (_isTransactionDueDetailsKey(entry.key)) {
        continue;
      }
      if (_hiddenDetailKeys.contains(normalizedKey) ||
          normalizedKey.contains('createdby') ||
          _isCreatorUserIdKey(entry.key)) {
        continue;
      }
      if (normalizedKey == 'trnsby' &&
          entry.value?.toString().trim() == _creatorUserId()) {
        continue;
      }
      if (_isThirdPartyTrnsRefKey(entry.key) ||
          _isExternalTransactionReferenceKey(entry.key)) {
        continue;
      }
      if (_isHeadCountKey(entry.key)) {
        final headCount = double.tryParse(entry.value?.toString().trim() ?? '');
        if (headCount == null || headCount <= 0) {
          continue;
        }
      }
      final value = _displayValueForKey(entry.key, entry.value);
      if (value != '--') {
        entries.add({
          'label': keyLabels[key] ?? _toTitleWords(key),
          'value': value,
        });
        if (key == 'trnsAmt') {
          final tenderValue = _joinedTenderText();
          if (tenderValue != '--') {
            entries.add({'label': 'Tender', 'value': tenderValue});
          }
        }
      }
    }

    return entries;
  }

  Widget _buildTransactionDetailRow(Map<String, String> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  List<Map<String, String>> _bankInstrumentTenderDetails() {
    final tenderEntries = _tenderEntries();
    if (tenderEntries.isNotEmpty) {
      return tenderEntries
          .map(
            (entry) => {
              'Tender Name': entry['tenderName'] ?? '--',
              'Amount Paid': entry['amountPaid'] ?? '--',
            },
          )
          .toList();
    }

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

    if (action == _approveAction && _isDuplicateBankTransactionId) {
      final shouldApprove = await _confirmDuplicateReferenceApproval();
      if (!mounted || shouldApprove != true) {
        return;
      }
    }

    setState(() {
      _loadingAction = action;
    });

    final response = await ApiService.actionTransactionReviewWorkList(
      worklistId: widget.worklistId,
      action: action,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingAction = null;
    });

    final messageCode =
        response?['messageCode']?.toString().trim().toUpperCase() ?? '';
    if (action == _approveAction && messageCode == 'ERR_MESSAGE_53') {
      final shouldReject = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFFF7FCFA),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD7EAE3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _brandColor),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transaction Cannot Be Approved',
                  style: TextStyle(
                    color: Color(0xFF124B45),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '${response?['message']?.toString().trim() ?? 'Worklist cannot be approved.'}\n\n'
            'Confirm If You Want To Reject',
            style: const TextStyle(color: Color(0xFF2A4A47), height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF124B45),
                side: BorderSide(color: Color(0xFFD7EAE3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (shouldReject == true && mounted) {
        await _handleAction(_rejectAction);
      }
      return;
    }

    final isSuccess = messageCode.contains('SUCC');
    if (!isSuccess) {
      final message =
          response?['message']?.toString().trim() ??
          'Unable to update transaction review.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Unable to update transaction review.' : message,
          ),
          backgroundColor: const Color(0xFFB3261E),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    await widget.onActionCompleted();
  }

  Future<bool?> _confirmDuplicateReferenceApproval() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF7FCFA),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD7EAE3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB3261E)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Duplicate Transaction Reference',
                style: TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'The Transaction Reference No Is Used In Another Transaction In The System. Are You Sure To Approve?',
          style: TextStyle(color: Color(0xFF2A4A47), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF124B45),
              side: const BorderSide(color: Color(0xFFD7EAE3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
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

  void _startEditingReferenceId() {
    setState(() {
      _referenceIdController.text = _thirdPartyTrnsRef;
      _isEditingReferenceId = true;
    });
  }

  Future<void> _refreshTransactionDetails() async {
    final header = ApiService.userHeader;
    if (header == null) {
      return;
    }

    final response = await ApiService.getTransactions({
      'genericHeader': Map<String, dynamic>.from(header),
      'transactionId': widget.transactionId.trim(),
    });

    if (!mounted) {
      return;
    }

    final rawList = response?['transactionList'];
    if (rawList is! List || rawList.isEmpty || rawList.first is! Map) {
      return;
    }

    final refreshed = Map<String, dynamic>.from(rawList.first as Map);
    final rawExternalDetails = response?['externalTransactionNoDetails'];
    setState(() {
      widget.transaction
        ..clear()
        ..addAll(refreshed);
      _referenceIdController.text = _thirdPartyTrnsRef;
      _externalTransactionNoDetails = rawExternalDetails is Map
          ? Map<String, dynamic>.from(rawExternalDetails)
          : null;
    });
  }

  Future<void> _saveReferenceId() async {
    if (_isSavingReferenceId) {
      return;
    }

    final transactionId = widget.transactionId.trim();
    final newReferenceValue = _referenceIdController.text.trim();

    setState(() {
      _isSavingReferenceId = true;
    });

    final response = await ApiService.updateReference(
      transactionId: transactionId,
      thirdPartyTrnsRef: newReferenceValue,
    );

    if (!mounted) {
      return;
    }

    final messageCode =
        response?['messageCode']?.toString().trim().toUpperCase() ?? '';
    final isSuccess = messageCode.contains('SUCC');

    if (isSuccess) {
      await _refreshTransactionDetails();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingReferenceId = false;
      if (isSuccess) {
        _isEditingReferenceId = false;
      }
    });

    if (!isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response?['message']?.toString().trim() ??
                'Unable to save transaction reference number.',
          ),
        ),
      );
      return;
    }

    _referenceSavedMessageTimer?.cancel();
    setState(() {
      _showReferenceSavedMessage = true;
    });
    _referenceSavedMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showReferenceSavedMessage = false;
        });
      }
    });
  }

  Widget _buildReferenceIdSection() {
    final hasReferenceId = _thirdPartyTrnsRef.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transaction Reference Id',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF134E47),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isSavingReferenceId
                    ? null
                    : (_isEditingReferenceId
                          ? _saveReferenceId
                          : _startEditingReferenceId),
                icon: _isSavingReferenceId
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isEditingReferenceId
                            ? Icons.save_rounded
                            : (hasReferenceId
                                  ? Icons.edit_rounded
                                  : Icons.add_rounded),
                        size: 16,
                      ),
                label: Text(
                  _isEditingReferenceId
                      ? 'Save'
                      : (hasReferenceId ? 'Edit' : 'Add'),
                ),
                style: TextButton.styleFrom(foregroundColor: _brandColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _isEditingReferenceId
              ? TextField(
                  controller: _referenceIdController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                )
              : SelectableText(
                  hasReferenceId ? _thirdPartyTrnsRef : 'No Data Available',
                  style: const TextStyle(
                    color: Color(0xFF2A4A47),
                    fontWeight: FontWeight.w500,
                  ),
                ),
          if (_isDuplicateBankTransactionId)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: FadeTransition(
                opacity: _duplicateWarningController,
                child: const Text(
                  'Duplicate Bank Transaction Id. Verify Before Approving',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          AnimatedOpacity(
            opacity: _showReferenceSavedMessage ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Transaction Reference Number Saved Successfully',
                style: TextStyle(
                  color: Color(0xFF6ABF69),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingReferenceHint() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1D57A)),
      ),
      child: const Text(
        'Enter The Transaction Reference No To Approve The Transaction.',
        style: TextStyle(
          color: Color(0xFF8A5A00),
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
                              ...details.expand(
                                (entry) => <Widget>[
                                  _buildTransactionDetailRow(entry),
                                  if (entry['label'] == 'Transaction ID') ...[
                                    _buildTransactionDueDetailsSection(),
                                  ],
                                ],
                              ),
                              if (!details.any(
                                (entry) => entry['label'] == 'Transaction ID',
                              )) ...[
                                _buildTransactionDueDetailsSection(),
                              ],
                              _buildBankInstrumentSection(
                                bankInstrumentDetails,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                            if (files.isNotEmpty) ...[
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
                            _buildReferenceIdSection(),
                            if (_thirdPartyTrnsRef.isEmpty)
                              _buildMissingReferenceHint(),
                          ],
                        ),
                      ),
                    ),
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
                  if (widget.canTakeAction) ...[
                    const Spacer(),
                    FilledButton(
                      onPressed: _loadingAction == null &&
                              _thirdPartyTrnsRef.isNotEmpty
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
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: _loadingAction == _rejectAction
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reject'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
