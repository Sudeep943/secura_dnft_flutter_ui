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

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    final currentIndex = _sections.indexOf(_selectedSection);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F82),
        title: Text(_selectedSection.title),
        actions: [
          if (_selectedSection != AppSection.dashboard)
            IconButton(
              tooltip: 'Dashboard',
              icon: const Icon(Icons.home),
              onPressed: () => _selectSection(AppSection.dashboard),
            ),
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
