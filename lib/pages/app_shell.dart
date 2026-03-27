import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
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

  static const List<AppSection> _sections = [
    AppSection.dashboard,
    AppSection.bookings,
    AppSection.profileManagement,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        actions: [_buildNotificationButton(), _buildWorklistButton()],
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
