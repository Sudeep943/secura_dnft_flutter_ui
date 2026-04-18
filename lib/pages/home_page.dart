import 'dart:async';

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
  Map<String, dynamic>? dueAmountData;
  bool loading = true;
  final PageController _dueSliderController = PageController();
  Timer? _dueSliderTimer;
  int _dueSliderIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  @override
  void dispose() {
    _dueSliderTimer?.cancel();
    _dueSliderController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    final results = await Future.wait<Map<String, dynamic>?>([
      ApiService.getDashboardData(),
      ApiService.getDueAmountForFlat(),
    ]);

    if (!mounted) return;
    setState(() {
      dashboardData = results[0];
      dueAmountData = results[1];
      loading = false;
    });
    _configureDueSliderAutoPlay();
  }

  String _displayName() {
    return ApiService.getDisplayName();
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

  String _formatCurrencyWithCommas(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '0';
    }

    final isNegative = trimmed.startsWith('-');
    final unsignedValue = isNegative ? trimmed.substring(1) : trimmed;
    final parts = unsignedValue.split('.');
    final integerPart = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    if (integerPart.isEmpty) {
      return value;
    }

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

  String _dashboardDueAmount() {
    final candidates = [
      dueAmountData?['totalDueAmount'],
      dashboardData?['totalDues'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        final rawAmount = text.startsWith('₹') ? text.substring(1) : text;
        return '₹${_formatCurrencyWithCommas(rawAmount)}';
      }
    }

    return '₹0';
  }

  String _sumDueByPaymentType(String paymentType) {
    final items = _duePaymentItems();
    var total = 0.0;
    for (final item in items) {
      if (item.paymentType.toUpperCase() != paymentType) {
        continue;
      }
      total += double.tryParse(item.totalAmount) ?? 0;
    }
    return _formatAsCurrency(total.toStringAsFixed(0));
  }

  String _extractTotalFromResponse({
    required String key,
    required String fallbackPaymentType,
  }) {
    final topLevel = dueAmountData?[key]?.toString().trim() ?? '';
    if (topLevel.isNotEmpty && topLevel.toLowerCase() != 'null') {
      return _formatAsCurrency(topLevel);
    }

    final rawList = dueAmountData?['duePaymentList'];
    if (rawList is List) {
      for (final entry in rawList.whereType<Map>()) {
        final value = entry[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return _formatAsCurrency(value);
        }
      }
    }

    return _sumDueByPaymentType(fallbackPaymentType);
  }

  String _totalMandatoryPaymentAmount() {
    return _extractTotalFromResponse(
      key: 'totalMandatoryPaymentAmount',
      fallbackPaymentType: 'MANDATORY',
    );
  }

  String _totalOptionalPaymentAmount() {
    return _extractTotalFromResponse(
      key: 'totalOptionalPaymentAmount',
      fallbackPaymentType: 'OPTIONAL',
    );
  }

  List<_DuePaymentItem> _duePaymentItems() {
    final rawList = dueAmountData?['duePaymentList'];
    if (rawList is! List) {
      return const [];
    }

    return rawList
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(_DuePaymentItem.fromMap)
        .toList();
  }

  DateTime? _parseDueDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final direct = DateTime.tryParse(trimmed);
    if (direct != null) {
      return direct;
    }

    final match = RegExp(
      r'^(\d{1,2})-([A-Za-z]{3})-(\d{4})$',
    ).firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    const monthMap = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final day = int.tryParse(match.group(1)!);
    final month = monthMap[match.group(2)!.toLowerCase()];
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  _DuePaymentItem? _nextUpcomingDueItem() {
    final dues = _duePaymentItems();
    if (dues.isEmpty) {
      return null;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    _DuePaymentItem? selected;
    DateTime? selectedDate;

    for (final due in dues) {
      final dueDate = _parseDueDate(due.dueDate);
      if (dueDate == null) {
        continue;
      }

      final normalizedDueDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      );
      if (normalizedDueDate.isBefore(todayDate)) {
        continue;
      }

      if (selectedDate == null || normalizedDueDate.isBefore(selectedDate)) {
        selected = due;
        selectedDate = normalizedDueDate;
      }
    }

    return selected;
  }

  bool _isPastDue(_DuePaymentItem item) {
    final dueDate = _parseDueDate(item.dueDate);
    if (dueDate == null) {
      return false;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final normalizedDueDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );
    return normalizedDueDate.isBefore(todayDate);
  }

  String _formatAsCurrency(String amount) {
    final cleaned = amount.trim();
    if (cleaned.isEmpty) {
      return '₹0';
    }

    final rawAmount = cleaned.startsWith('₹') ? cleaned.substring(1) : cleaned;
    return '₹${_formatCurrencyWithCommas(rawAmount)}';
  }

  void _configureDueSliderAutoPlay() {
    _dueSliderTimer?.cancel();
    final dueItems = _duePaymentItems();
    if (dueItems.length <= 1) {
      _dueSliderIndex = 0;
      return;
    }

    _dueSliderTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_dueSliderController.hasClients) {
        return;
      }

      final nextIndex = (_dueSliderIndex + 1) % dueItems.length;
      _dueSliderController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    });
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
    final nextDue = _nextUpcomingDueItem();

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Financial Snapshot',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _dashboardDueAmount(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Due Amount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
                if (nextDue != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Next Due: ${nextDue.dueDate} • ${_formatAsCurrency(nextDue.totalAmount)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mandatory: ${_totalMandatoryPaymentAmount()} • Optional: ${_totalOptionalPaymentAmount()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                  'Pay In Due Times To Avoid Penalities',
                  textAlign: TextAlign.center,
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
    final dueItems = _duePaymentItems();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: mobile ? double.infinity : 260.0,
          child: _DueSliderMetricCard(
            dueItems: dueItems,
            controller: _dueSliderController,
            onPageChanged: (index) {
              _dueSliderIndex = index;
            },
            isPastDue: _isPastDue,
            formatAmount: _formatAsCurrency,
          ),
        ),
        ..._metricCards().map((metric) {
          final width = mobile ? double.infinity : 260.0;
          return SizedBox(
            width: width,
            child: _MetricCard(metric: metric),
          );
        }),
      ],
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

class _DueSliderMetricCard extends StatelessWidget {
  const _DueSliderMetricCard({
    required this.dueItems,
    required this.controller,
    required this.onPageChanged,
    required this.isPastDue,
    required this.formatAmount,
  });

  final List<_DuePaymentItem> dueItems;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final bool Function(_DuePaymentItem item) isPastDue;
  final String Function(String amount) formatAmount;

  @override
  Widget build(BuildContext context) {
    if (dueItems.isEmpty) {
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Due Schedule',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              'No dues available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF124B45),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 188,
      child: PageView.builder(
        controller: controller,
        itemCount: dueItems.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final due = dueItems[index];
          final overdue = isPastDue(due);
          final backgroundColor = overdue
              ? const Color(0xFFFFF3F2)
              : Colors.white;
          final accentColor = overdue
              ? const Color(0xFFB3261E)
              : const Color(0xFF0F8F82);

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: backgroundColor,
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
                Text(
                  'Due Schedule',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  due.dueDate,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payment: ${due.displayPaymentName}',
                  style: const TextStyle(color: Colors.black87, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type: ${due.displayPaymentType}',
                  style: TextStyle(
                    color: overdue
                        ? const Color(0xFF8B1E1E)
                        : const Color(0xFF124B45),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Amount: ${formatAmount(due.totalAmount)}',
                  style: TextStyle(
                    color: overdue
                        ? const Color(0xFF8B1E1E)
                        : const Color(0xFF124B45),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DuePaymentItem {
  const _DuePaymentItem({
    required this.dueDate,
    required this.paymentName,
    required this.paymentType,
    required this.totalAmount,
  });

  factory _DuePaymentItem.fromMap(Map<String, dynamic> map) {
    final paymentName = map['paymentName']?.toString().trim() ?? '';
    final paymentType = map['paymentType']?.toString().trim() ?? '';
    return _DuePaymentItem(
      dueDate: map['dueDate']?.toString().trim() ?? '--',
      paymentName: paymentName.isEmpty || paymentName.toLowerCase() == 'null'
          ? '--'
          : paymentName,
      paymentType: paymentType.isEmpty || paymentType.toLowerCase() == 'null'
          ? '--'
          : paymentType,
      totalAmount:
          map['totalAmount']?.toString().trim() ??
          map['amount']?.toString().trim() ??
          '0',
    );
  }

  final String dueDate;
  final String paymentName;
  final String paymentType;
  final String totalAmount;

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    List<String> words = text.toLowerCase().split(' ');
    words[0] = words[0][0].toUpperCase() + words[0].substring(1);
    for (int i = 1; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1);
      }
    }
    return words.join(' ');
  }

  String get displayPaymentName => _toCamelCase(paymentName);
  String get displayPaymentType => _toCamelCase(paymentType);
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
