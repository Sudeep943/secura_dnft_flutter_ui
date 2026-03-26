import 'package:flutter/material.dart';

import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';

class MeetingAndNoticeManagementPage extends StatelessWidget {
  const MeetingAndNoticeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      title: 'Meeting And Notice Management',
      subtitle:
          'Choose one of the meeting, notice, event, or poll actions below.',
      items: const [
        _ModuleHubItem('Schedule New Meeting', Icons.event_note),
        _ModuleHubItem('View Meeting Details', Icons.visibility),
        _ModuleHubItem('Update MOM', Icons.edit_document),
        _ModuleHubItem('Create Notice', Icons.campaign),
        _ModuleHubItem('View All Notice', Icons.notifications_active),
        _ModuleHubItem('Create Event', Icons.event),
        _ModuleHubItem('View Events', Icons.calendar_month),
        _ModuleHubItem('Create Poll', Icons.how_to_vote),
        _ModuleHubItem('View Poll', Icons.poll),
      ],
    );
  }
}

class TicketManagementPage extends StatelessWidget {
  const TicketManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const SecurityManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const GroupManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const StaffManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const VendorManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const RoleAndAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const ReportsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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
  const OthersManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
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

class FinanceManagementPage extends StatelessWidget {
  const FinanceManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModuleHubPage(
      title: 'Finance',
      subtitle: 'Choose one of the finance actions below.',
      items: const [
        _ModuleHubItem('Add Credit', Icons.add_card),
        _ModuleHubItem('Add Debit', Icons.credit_card_off),
        _ModuleHubItem('Create New Payment', Icons.payment),
        _ModuleHubItem('Add Bank Account', Icons.account_balance),
        _ModuleHubItem('Pay Dues', Icons.currency_rupee),
      ],
    );
  }
}

class _ModuleHubPage extends StatelessWidget {
  const _ModuleHubPage({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_ModuleHubItem> items;

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      drawer: mobile ? Drawer(child: SideBar()) : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!mobile) SideBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 1080),
                    child: Container(
                      padding: EdgeInsets.all(mobile ? 18 : 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Color(0xFF0F8F82),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF124B45),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 28),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            crossAxisCount: mobile ? 1 : 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: mobile ? 1.4 : 1.05,
                            children: [
                              for (final item in items)
                                _ModuleActionCard(
                                  title: item.title,
                                  icon: item.icon,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleHubItem {
  const _ModuleHubItem(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _ModuleActionCard extends StatefulWidget {
  const _ModuleActionCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.title} page is ready for the next step.'),
            ),
          );
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hovered ? Color(0xFFE0DA84) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 50, color: Color(0xFF0F8F82)),
              SizedBox(height: 15),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
