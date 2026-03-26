import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.embedded = false, this.onSectionSelected});

  final bool embedded;
  final ValueChanged<AppSection>? onSectionSelected;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _accentColor = Color(0xFFE0DA84);
  static const Color _panelBackground = Color(0xFFF5FBF9);
  static const String _dayQuote =
      'A good day grows from calm decisions, kind words, and steady progress.';

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Map<String, dynamic>? dashboardData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  fetchDashboardData() async {
    final data = await ApiService.getDashboardData();
    if (!mounted) return;
    setState(() {
      dashboardData = data;
      loading = false;
    });
  }

  String _displayName() {
    final header = ApiService.userHeader;
    if (header == null) return 'Resident';

    final values = [
      header['name'],
      header['fullName'],
      header['userName'],
      [header['firstName'], header['lastName']]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .join(' '),
      header['userId'],
    ];

    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Resident';
  }

  String _flatNumber() {
    return ApiService.getLoggedInFlatNo() ?? 'A-904';
  }

  int _upcomingBookingCount() {
    final bookings = dashboardData?['upcomingBookings'];
    if (bookings is List) {
      return bookings.length;
    }

    return 3;
  }

  String _totalDues() {
    final candidates = [
      dashboardData?['totalDues'],
      dashboardData?['pendingDues'],
      dashboardData?['payments'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text.startsWith('₹') ? text : '₹$text';
      }
    }

    return '₹18,450';
  }

  int _pendingWorklistCount() {
    final value = dashboardData?['pendingWorklistCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 10;
  }

  int _activePollsCount() {
    final value = dashboardData?['pollsCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 4;
  }

  int _recentVisitorCount() {
    final value = dashboardData?['recentVisitorCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 18;
  }

  void _handleQuickAction(_QuickPick action) {
    if (action.section case final section?) {
      if (widget.onSectionSelected case final onSectionSelected?) {
        onSectionSelected(section);
        return;
      }

      openAppShellSection(context, section);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(action.message)));
  }

  String formatHallBookings(List<dynamic>? bookings) {
    if (bookings == null || bookings.isEmpty) return "0";
    return bookings
        .map((b) {
          DateTime date = DateTime.parse(b['bkngEvntDt']);
          String formattedDate =
              "${date.day.toString().padLeft(2, '0')}-${_monthAbbr(date.month)}-${date.year}";
          return "${formattedDate} - ${b['bkngHallId']} - ${b['bkngFltNo']}";
        })
        .join('\n');
  }

  String _monthAbbr(int month) {
    const months = [
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
    return months[month - 1];
  }

  List<_MetricCardData> _metricCards() {
    return [
      _MetricCardData(
        title: 'Total Dues',
        value: _totalDues(),
        subtitle: 'Due before 05 Apr 2026',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _MetricCardData(
        title: 'Recent Visitors',
        value: '${_recentVisitorCount()}',
        subtitle: 'Entries in the last 24 hours',
        icon: Icons.badge_outlined,
      ),
      _MetricCardData(
        title: 'Open Helpdesk',
        value: '07',
        subtitle: '3 need immediate attention',
        icon: Icons.support_agent_outlined,
      ),
      _MetricCardData(
        title: 'Active Polls',
        value: '${_activePollsCount()}',
        subtitle: '2 closing this evening',
        icon: Icons.poll_outlined,
      ),
    ];
  }

  List<_QuickPick> _quickPicks() {
    return const [
      _QuickPick(
        title: 'Polls',
        subtitle: 'Vote on community topics',
        icon: Icons.how_to_vote_outlined,
        section: AppSection.meetingAndNotice,
        message: 'Opening polls.',
      ),
      _QuickPick(
        title: 'Raise Emergency',
        subtitle: 'Send an urgent alert',
        icon: Icons.sos_rounded,
        section: AppSection.security,
        message: 'Emergency alert workflow is ready.',
      ),
      _QuickPick(
        title: 'Chat',
        subtitle: 'Reach your community team',
        icon: Icons.chat_bubble_outline_rounded,
        message: 'Chat module is ready for the next step.',
      ),
      _QuickPick(
        title: 'Connect Security',
        subtitle: 'Share gate instructions',
        icon: Icons.shield_outlined,
        section: AppSection.security,
        message: 'Opening security tools.',
      ),
      _QuickPick(
        title: 'Helpdesk',
        subtitle: 'Track service requests',
        icon: Icons.headset_mic_outlined,
        section: AppSection.ticketManagement,
        message: 'Opening helpdesk.',
      ),
      _QuickPick(
        title: 'Directory',
        subtitle: 'Find residents and staff',
        icon: Icons.apartment_outlined,
        section: AppSection.profileManagement,
        message: 'Opening directory.',
      ),
      _QuickPick(
        title: 'Visitor Entry',
        subtitle: 'Create a guest pass',
        icon: Icons.person_add_alt_1_outlined,
        section: AppSection.security,
        message: 'Opening visitor entry.',
      ),
      _QuickPick(
        title: 'Notice Board',
        subtitle: 'Read latest notices',
        icon: Icons.campaign_outlined,
        section: AppSection.meetingAndNotice,
        message: 'Opening notices.',
      ),
    ];
  }

  List<_TrendBarData> _trendBars() {
    return const [
      _TrendBarData(label: 'Mon', value: 0.42),
      _TrendBarData(label: 'Tue', value: 0.58),
      _TrendBarData(label: 'Wed', value: 0.76),
      _TrendBarData(label: 'Thu', value: 0.66),
      _TrendBarData(label: 'Fri', value: 0.88),
      _TrendBarData(label: 'Sat', value: 0.94),
      _TrendBarData(label: 'Sun', value: 0.52),
    ];
  }

  List<_VisitorEntry> _recentVisitors() {
    return const [
      _VisitorEntry('Arjun Mehta', 'Courier drop', '10:15 AM', 'Gate 2'),
      _VisitorEntry('Dr. Kavya Shah', 'Medical visit', '09:40 AM', 'Tower B'),
      _VisitorEntry(
        'Ritesh Jain',
        'Housekeeping vendor',
        '09:05 AM',
        'Clubhouse',
      ),
      _VisitorEntry('Naina Patel', 'Family guest', '08:30 AM', 'Tower A'),
    ];
  }

  List<_FeedItem> _noticeItems() {
    return const [
      _FeedItem(
        title: 'Water tank cleaning scheduled for Saturday',
        category: 'Notice',
        timestamp: 'Today, 11:00 AM',
        description:
            'Supply will be paused from 11 AM to 2 PM across Towers A and B.',
      ),
      _FeedItem(
        title: 'Security drill and emergency response check',
        category: 'Post',
        timestamp: 'Today, 08:45 AM',
        description:
            'Residents are requested to keep basement lanes clear during the drill window.',
      ),
      _FeedItem(
        title: 'Poll open: clubhouse equipment upgrade',
        category: 'Poll',
        timestamp: 'Yesterday, 06:20 PM',
        description:
            'Cast your vote on the proposed gym and indoor games refresh before Friday.',
      ),
    ];
  }

  Widget _buildHeroCard(bool mobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F8F82), Color(0xFF136B61)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 143, 130, 0.18),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 18,
        spacing: 18,
        children: [
          SizedBox(
            width: mobile ? double.infinity : 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Community Command Centre',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Good morning, ${_displayName()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mobile ? 24 : 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _dayQuote,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Flat ${_flatNumber()} has ${_pendingWorklistCount()} active worklist tasks, ${_upcomingBookingCount()} upcoming bookings, and ${_recentVisitorCount()} recent visitor entries to review.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _StatusChip(
                      label: 'Emergency line active',
                      icon: Icons.phone_in_talk_outlined,
                    ),
                    _StatusChip(
                      label: 'Security online',
                      icon: Icons.verified_user_outlined,
                    ),
                    _StatusChip(
                      label: '2 notices unread',
                      icon: Icons.mark_chat_unread_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: mobile ? double.infinity : 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Snapshot',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _totalDues(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total dues outstanding for this cycle',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  minHeight: 10,
                  value: 0.64,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 10),
                Text(
                  '64% of community dues collected this month',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(bool mobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _metricCards().map((metric) {
        final width = mobile ? double.infinity : 260.0;
        return SizedBox(
          width: width,
          child: _MetricCard(metric: metric),
        );
      }).toList(),
    );
  }

  Widget _buildQuickPickPanel(bool mobile) {
    final quickPicks = _quickPicks();

    return _DashboardPanel(
      title: 'Quick Picks',
      subtitle: 'Fast access to the most-used resident actions.',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: quickPicks.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: mobile ? 2 : 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: mobile ? 1.05 : 1.2,
        ),
        itemBuilder: (context, index) {
          final action = quickPicks[index];
          return _QuickPickCard(
            action: action,
            onTap: () => _handleQuickAction(action),
          );
        },
      ),
    );
  }

  Widget _buildTrendPanel() {
    return _DashboardPanel(
      title: 'Community Pulse',
      subtitle:
          'Seven-day activity across visitors, helpdesk, and interactions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _trendBars().map((bar) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(bar.value * 100).round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF124B45),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          height: 140 * bar.value,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_accentColor, _brandColor],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          bar.label,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _LegendChip(label: 'Visitor traffic', color: _brandColor),
              _LegendChip(label: 'Emergency readiness', color: _accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedPanel() {
    return _DashboardPanel(
      title: 'Notice & Posts',
      subtitle: 'Latest communication from the society office.',
      child: Column(
        children: _noticeItems().map((item) => _FeedTile(item: item)).toList(),
      ),
    );
  }

  Widget _buildVisitorsPanel() {
    return _DashboardPanel(
      title: 'Recent Entry Visitors',
      subtitle: 'Latest gate activity requiring visibility.',
      child: Column(
        children: _recentVisitors()
            .map((visitor) => _VisitorTile(visitor: visitor))
            .toList(),
      ),
    );
  }

  Widget _buildPollPanel() {
    return _DashboardPanel(
      title: 'Polls & Engagement',
      subtitle: 'Track participation across community decisions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _panelBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.poll_outlined, color: _brandColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Clubhouse equipment upgrade',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF124B45),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '73% residents have already voted. Poll closes in 9 hours.',
                  style: TextStyle(color: Colors.black87, height: 1.45),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: 0.73,
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  color: _brandColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ProgressRow(label: 'Emergency readiness drill', value: 0.88),
          const SizedBox(height: 12),
          const _ProgressRow(label: 'Security response SLA', value: 0.92),
          const SizedBox(height: 12),
          const _ProgressRow(label: 'Helpdesk closure rate', value: 0.69),
        ],
      ),
    );
  }

  Widget _buildPostsPanel() {
    return _DashboardPanel(
      title: 'Resident Posts',
      subtitle: 'Most recent community updates and highlights.',
      child: Column(
        children: const [
          _PostTile(
            title: 'Weekend yoga batch registrations are now open',
            author: 'Wellness Committee',
            stats: '24 comments • 58 reactions',
          ),
          _PostTile(
            title: 'Basement repainting completed in Tower C parking bay',
            author: 'Facility Team',
            stats: '8 comments • 31 reactions',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final mobile = isMobile(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = mobile ? constraints.maxWidth : 1380.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(mobile ? 16 : 22),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(mobile),
                  const SizedBox(height: 18),
                  _buildMetricGrid(mobile),
                  const SizedBox(height: 18),
                  if (mobile) ...[
                    _buildQuickPickPanel(mobile),
                    const SizedBox(height: 18),
                    _buildTrendPanel(),
                    const SizedBox(height: 18),
                    _buildVisitorsPanel(),
                    const SizedBox(height: 18),
                    _buildFeedPanel(),
                    const SizedBox(height: 18),
                    _buildPollPanel(),
                    const SizedBox(height: 18),
                    _buildPostsPanel(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 8,
                          child: Column(
                            children: [
                              _buildQuickPickPanel(mobile),
                              const SizedBox(height: 18),
                              _buildTrendPanel(),
                              const SizedBox(height: 18),
                              _buildFeedPanel(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildVisitorsPanel(),
                              const SizedBox(height: 18),
                              _buildPollPanel(),
                              const SizedBox(height: 18),
                              _buildPostsPanel(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildDashboardContent(context);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text("Dashboard"),

        actions: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: Text("Pending Dues: ₹1250")),
          ),

          Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: Text("Worklist: 10")),
          ),

          SizedBox(width: 20),
        ],
      ),

      drawer: isMobile(context)
          ? Drawer(
              child: SideBar(
                selectedSection: AppSection.dashboard,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            )
          : null,

      body: BrandBackground(
        child: Row(
          children: [
            if (!isMobile(context))
              SideBar(
                selectedSection: AppSection.dashboard,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            Expanded(child: _buildDashboardContent(context)),
          ],
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3F0ED)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(12, 71, 64, 0.06),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF124B45),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, height: 1.45),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricCardData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 59, 52, 0.05),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FBF9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(metric.icon, color: const Color(0xFF0F8F82)),
          ),
          const SizedBox(height: 16),
          Text(
            metric.title,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF124B45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.subtitle,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _QuickPick {
  const _QuickPick({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.message,
    this.section,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String message;
  final AppSection? section;
}

class _QuickPickCard extends StatelessWidget {
  const _QuickPickCard({required this.action, required this.onTap});

  final _QuickPick action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5FBF9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: const Color(0xFF0F8F82)),
              ),
              const SizedBox(height: 12),
              Text(
                action.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF124B45),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBarData {
  const _TrendBarData({required this.label, required this.value});

  final String label;
  final double value;
}

class _VisitorEntry {
  const _VisitorEntry(this.name, this.purpose, this.time, this.destination);

  final String name;
  final String purpose;
  final String time;
  final String destination;
}

class _VisitorTile extends StatelessWidget {
  const _VisitorTile({required this.visitor});

  final _VisitorEntry visitor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE0DA84),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF124B45)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF124B45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${visitor.purpose} • ${visitor.destination}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            visitor.time,
            style: const TextStyle(
              color: Color(0xFF0F8F82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedItem {
  const _FeedItem({
    required this.title,
    required this.category,
    required this.timestamp,
    required this.description,
  });

  final String title;
  final String category;
  final String timestamp;
  final String description;
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item});

  final _FeedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0DA84),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: Color(0xFF124B45),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                item.timestamp,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF124B45),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(color: Colors.black87, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.title,
    required this.author,
    required this.stats,
  });

  final String title;
  final String author;
  final String stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF124B45),
            ),
          ),
          const SizedBox(height: 8),
          Text(author, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text(
            stats,
            style: const TextStyle(
              color: Color(0xFF0F8F82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF124B45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF0F8F82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 9,
          backgroundColor: const Color(0xFFE9F2EF),
          color: const Color(0xFF0F8F82),
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
