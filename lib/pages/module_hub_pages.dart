import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
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
