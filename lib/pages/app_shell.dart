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
        onPressed: () => _showShellMessage(
          'You have $_worklistCount active worklist items.',
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
