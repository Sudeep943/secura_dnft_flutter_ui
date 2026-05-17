import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../services/receipt_downloader.dart';
import '../services/razorpay_checkout.dart';
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
  bool isRefreshing = false;
  final PageController _dueSliderController = PageController();
  Timer? _dueSliderTimer;
  int _dueSliderIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refetch data whenever the dashboard page comes into focus
    fetchDashboardData();
  }

  @override
  void dispose() {
    _dueSliderTimer?.cancel();
    _dueSliderController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData({bool isManualRefresh = false}) async {
    if (isManualRefresh) {
      setState(() {
        isRefreshing = true;
      });
    }

    final results = await Future.wait<Map<String, dynamic>?>([
      ApiService.getDashboardData(),
      ApiService.getDueAmountForFlat(),
    ]);

    if (!mounted) return;
    setState(() {
      dashboardData = results[0];
      dueAmountData = results[1];
      loading = false;
      isRefreshing = false;
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
    if (trimmed.isEmpty) return '0';

    final isNegative = trimmed.startsWith('-');
    final unsignedValue = isNegative ? trimmed.substring(1) : trimmed;
    final parts = unsignedValue.split('.');
    final integerPart = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    if (integerPart.isEmpty) return value;

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
      dueAmountData?['totalDue'],
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

  Map<String, List<Map<String, dynamic>>> _dueDetailsByPayment() {
    final result = <String, List<Map<String, dynamic>>>{};
    final rawDetails = dueAmountData?['dueDetails'];
    if (rawDetails is! Map) {
      return result;
    }

    rawDetails.forEach((rawKey, rawValue) {
      final key = rawKey?.toString() ?? '';
      if (key.isEmpty) {
        return;
      }

      final list = <Map<String, dynamic>>[];
      if (rawValue is List) {
        for (final item in rawValue.whereType<Map>()) {
          list.add(Map<String, dynamic>.from(item));
        }
      } else if (rawValue is Map) {
        list.add(Map<String, dynamic>.from(rawValue));
      }

      if (list.isNotEmpty) {
        result[key] = list;
      }
    });

    return result;
  }

  List<Map<String, dynamic>> _allDuePaymentMaps() {
    final dueDetailsGroups = _dueDetailsByPayment();
    if (dueDetailsGroups.isNotEmpty) {
      return dueDetailsGroups.values.expand((items) => items).toList();
    }

    final rawList = dueAmountData?['duePaymentList'];
    if (rawList is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawList
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  String _totalMandatoryPaymentAmount() {
    final amount =
        dueAmountData?['totalMandatoryPayment']?.toString().trim() ?? '0';
    return _formatAsCurrency(amount);
  }

  String _totalOptionalPaymentAmount() {
    final amount =
        dueAmountData?['totalOptionalPayment']?.toString().trim() ?? '0';
    return _formatAsCurrency(amount);
  }

  List<_DuePaymentItem> _duePaymentItems() {
    final entries = _allDuePaymentMaps();
    if (entries.isEmpty) return const [];

    return entries.map(_DuePaymentItem.fromMap).toList();
  }

  DateTime? _parseDueDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;

    final numericMatch = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
    ).firstMatch(trimmed);
    if (numericMatch != null) {
      final day = int.tryParse(numericMatch.group(1)!);
      final month = int.tryParse(numericMatch.group(2)!);
      final year = int.tryParse(numericMatch.group(3)!);
      if (day != null && month != null && year != null) {
        final parsed = DateTime(year, month, day);
        if (parsed.year == year && parsed.month == month && parsed.day == day) {
          return parsed;
        }
      }
    }

    final match = RegExp(
      r'^(\d{1,2})[-/\s]([A-Za-z]{3})[-/\s](\d{4})$',
    ).firstMatch(trimmed);
    if (match == null) return null;

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
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  _DuePaymentItem? _nextUpcomingDueItem() {
    final dues = _duePaymentItems();
    if (dues.isEmpty) return null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    _DuePaymentItem? selected;
    DateTime? selectedDate;

    for (final due in dues) {
      final dueDate = _parseDueDate(due.dueDate);
      if (dueDate == null) continue;

      final normalizedDueDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      );
      if (normalizedDueDate.isBefore(todayDate)) continue;

      if (selectedDate == null || normalizedDueDate.isBefore(selectedDate)) {
        selected = due;
        selectedDate = normalizedDueDate;
      }
    }

    return selected;
  }

  bool _isPastDue(_DuePaymentItem item) {
    final dueDate = _parseDueDate(item.dueDate);
    if (dueDate == null) return false;

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
    if (cleaned.isEmpty) return '₹0';

    final rawAmount = cleaned.startsWith('₹') ? cleaned.substring(1) : cleaned;
    return '₹${_formatCurrencyWithCommas(rawAmount)}';
  }

  bool _isDueAmountZero() {
    final candidates = [
      dueAmountData?['totalDue'],
      dueAmountData?['totalDueAmount'],
      dashboardData?['totalDues'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        final raw = text.startsWith('₹') ? text.substring(1) : text;
        final value = double.tryParse(raw.replaceAll(',', '')) ?? 0;
        return value == 0;
      }
    }
    return true;
  }

  void _showPaymentDetailsModal() {
    final groupedDues = _dueDetailsByPayment();
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentDetailsModal(
        duePaymentList: dueAmountData?['duePaymentList'] ?? [],
        dueDetailsByPayment: groupedDues,
        formatAsCurrency: _formatAsCurrency,
        onPaymentCompleted: fetchDashboardData,
      ),
    );
  }

  void _configureDueSliderAutoPlay() {
    _dueSliderTimer?.cancel();
    final dueItems = _duePaymentItems();
    if (dueItems.length <= 1) {
      _dueSliderIndex = 0;
      return;
    }

    _dueSliderTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_dueSliderController.hasClients) return;

      final nextIndex = (_dueSliderIndex + 1) % dueItems.length;
      _dueSliderController.animateToPage(
        nextIndex.toInt(),
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
    if (bookings == null || bookings.isEmpty) return '0';
    return bookings
        .map((b) {
          final date = DateTime.parse(b['bkngEvntDt']);
          final formattedDate =
              '${date.day.toString().padLeft(2, '0')}-${_monthAbbr(date.month)}-${date.year}';
          return '$formattedDate - ${b['bkngHallId']} - ${b['bkngFltNo']}';
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isDueAmountZero() ? null : _showPaymentDetailsModal,
              child: Container(
                width: mobile ? double.infinity : 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Financial Snapshot',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isRefreshing)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            color: Colors.white.withValues(alpha: 0.90),
                            onPressed: () =>
                                fetchDashboardData(isManualRefresh: true),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )
                        else
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white.withValues(alpha: 0.90),
                              ),
                            ),
                          ),
                      ],
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
                    ],
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
                      _isDueAmountZero()
                          ? 'Thank You For Paying All Dues'
                          : 'Pay In Due Times To Avoid Penalties',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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
            onPaymentCompleted: fetchDashboardData,
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('secura_logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            const Text("Dashboard"),
          ],
        ),

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
    required this.onPaymentCompleted,
  });

  final List<_DuePaymentItem> dueItems;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final bool Function(_DuePaymentItem item) isPastDue;
  final String Function(String amount) formatAmount;
  final Future<void> Function() onPaymentCompleted;

  @override
  Widget build(BuildContext context) {
    if (dueItems.isEmpty) {
      return SizedBox(
        height: 188,
        child: Container(
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
                'No Dues Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF124B45),
                ),
              ),
            ],
          ),
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

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                final parentContext = context;
                showDialog(
                  context: parentContext,
                  builder: (dialogContext) => PaymentDetailsModal(
                    duePaymentList: [due.rawData],
                    formatAsCurrency: formatAmount,
                    onPaymentCompleted: onPaymentCompleted,
                  ),
                );
              },
              child: Container(
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
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.35,
                      ),
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
              ),
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
    required this.rawData,
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
      rawData: map,
    );
  }

  final String dueDate;
  final String paymentName;
  final String paymentType;
  final String totalAmount;
  final Map<String, dynamic> rawData;

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

class PaymentDetailsModal extends StatefulWidget {
  const PaymentDetailsModal({
    required this.duePaymentList,
    required this.formatAsCurrency,
    this.dueDetailsByPayment,
    this.onPaymentCompleted,
  });

  final List<dynamic> duePaymentList;
  final Map<String, List<Map<String, dynamic>>>? dueDetailsByPayment;
  final String Function(String amount) formatAsCurrency;

  final Future<void> Function()? onPaymentCompleted;

  @override
  State<PaymentDetailsModal> createState() => _PaymentDetailsModalState();
}

enum _DueSectionTab { overdue, active }

class _DueGroupData {
  const _DueGroupData({
    required this.groupId,
    required this.paymentId,
    required this.paymentName,
    required this.dues,
  });

  final String groupId;
  final String paymentId;
  final String paymentName;
  final List<Map<String, dynamic>> dues;
}

class _PaymentDetailsModalState extends State<PaymentDetailsModal> {
  static const String _razorpayKey = 'rzp_test_SRxceBfBqGmeGy';

  final Map<String, bool> _submittingRows = <String, bool>{};
  final Map<String, _DueSectionTab> _selectedTabs = <String, _DueSectionTab>{};
  final Map<String, String> _selectedDueByGroup = <String, String>{};

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    final words = text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .toList();
    if (words.isEmpty) return '';
    words[0] = words[0][0].toUpperCase() + words[0].substring(1);
    for (var i = 1; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1);
      }
    }
    return words.join(' ');
  }

  List<Map<String, dynamic>> _normalizedPayments() {
    return widget.duePaymentList
        .whereType<Map>()
        .map((payment) => Map<String, dynamic>.from(payment))
        .toList();
  }

  String _dueId(Map<String, dynamic> payment) {
    return payment['DueId']?.toString().trim() ??
        payment['dueId']?.toString().trim() ??
        '';
  }

  String _paymentNameFromGroupKey(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return '--';
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final paymentName = decoded['paymentName']?.toString().trim() ?? '';
        if (paymentName.isNotEmpty && paymentName.toLowerCase() != 'null') {
          return paymentName;
        }
      }
    } catch (_) {
      // Not a JSON key, use fallback below.
    }

    return trimmed;
  }

  String _paymentIdFromGroupKey(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final paymentId = decoded['paymentId']?.toString().trim() ?? '';
        if (paymentId.isNotEmpty && paymentId.toLowerCase() != 'null') {
          return paymentId;
        }
      }
    } catch (_) {
      // Not a JSON key, use fallback below.
    }

    return '';
  }

  List<Map<String, dynamic>> _normalizePaymentMaps(dynamic rawValue) {
    final list = <Map<String, dynamic>>[];

    if (rawValue is List) {
      for (final payment in rawValue.whereType<Map>()) {
        list.add(Map<String, dynamic>.from(payment));
      }
    } else if (rawValue is Map) {
      list.add(Map<String, dynamic>.from(rawValue));
    }

    return list;
  }

  List<_DueGroupData> _groupedPayments() {
    final grouped = <_DueGroupData>[];
    final fromDueDetails = widget.dueDetailsByPayment;

    if (fromDueDetails != null && fromDueDetails.isNotEmpty) {
      fromDueDetails.forEach((rawKey, rawList) {
        final dues = _sortDuesByCycleSequence(_normalizePaymentMaps(rawList));
        if (dues.isEmpty) {
          return;
        }

        final paymentName = _paymentNameFromGroupKey(rawKey);
        final paymentId = _paymentIdFromGroupKey(rawKey);
        final groupId = paymentId.isNotEmpty
            ? paymentId
            : '$paymentName-${rawKey.hashCode}';

        grouped.add(
          _DueGroupData(
            groupId: groupId,
            paymentId: paymentId,
            paymentName: paymentName,
            dues: dues,
          ),
        );
      });
    }

    if (grouped.isNotEmpty) {
      grouped.sort(
        (a, b) =>
            a.paymentName.toLowerCase().compareTo(b.paymentName.toLowerCase()),
      );
      return grouped;
    }

    final normalized = _normalizedPayments();
    if (normalized.isEmpty) {
      return const <_DueGroupData>[];
    }

    final byPayment = <String, List<Map<String, dynamic>>>{};
    final paymentNames = <String, String>{};
    for (final payment in normalized) {
      final paymentId = payment['paymentId']?.toString().trim() ?? '';
      final paymentName = payment['paymentName']?.toString().trim() ?? '--';
      final groupId = paymentId.isNotEmpty
          ? paymentId
          : '$paymentName-${payment.hashCode}';
      byPayment
          .putIfAbsent(groupId, () => <Map<String, dynamic>>[])
          .add(payment);
      paymentNames[groupId] = paymentName;
    }

    byPayment.forEach((groupId, dues) {
      grouped.add(
        _DueGroupData(
          groupId: groupId,
          paymentId: groupId,
          paymentName: paymentNames[groupId] ?? '--',
          dues: _sortDuesByCycleSequence(dues),
        ),
      );
    });

    grouped.sort(
      (a, b) =>
          a.paymentName.toLowerCase().compareTo(b.paymentName.toLowerCase()),
    );
    return grouped;
  }

  List<Map<String, dynamic>> _duesForTab(
    _DueGroupData group,
    _DueSectionTab selectedTab,
  ) {
    return group.dues.where((due) {
      final isOverdue = _isPastDue(due);
      return selectedTab == _DueSectionTab.overdue ? isOverdue : !isOverdue;
    }).toList();
  }

  DateTime? _parseDueDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;

    final numericMatch = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$',
    ).firstMatch(trimmed);
    if (numericMatch != null) {
      final day = int.tryParse(numericMatch.group(1)!);
      final month = int.tryParse(numericMatch.group(2)!);
      final year = int.tryParse(numericMatch.group(3)!);
      if (day != null && month != null && year != null) {
        final parsed = DateTime(year, month, day);
        if (parsed.year == year && parsed.month == month && parsed.day == day) {
          return parsed;
        }
      }
    }

    final match = RegExp(
      r'^(\d{1,2})[-/\s]([A-Za-z]{3})[-/\s](\d{4})$',
    ).firstMatch(trimmed);
    if (match == null) return null;

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
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  bool _isPastDue(Map<String, dynamic> payment) {
    final dueEndDateText = payment['dueEndDate']?.toString().trim() ?? '';
    final dueDateText = payment['dueDate']?.toString().trim() ?? '';

    final dueEndDate = _parseDueDate(dueEndDateText);
    final dueDate = _parseDueDate(dueDateText);
    final comparisonDate = dueDate ?? dueEndDate;
    if (comparisonDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueOnly = DateTime(
      comparisonDate.year,
      comparisonDate.month,
      comparisonDate.day,
    );
    return dueOnly.isBefore(today);
  }

  List<String> _extractAllowedPaymentModes(Map<String, dynamic> payment) {
    final rawModes =
        payment['allowedTenders'] ?? payment['allowedPaymentModes'];
    final modes = <String>[];

    if (rawModes is List) {
      for (final mode in rawModes) {
        final normalized = mode?.toString().trim().toUpperCase() ?? '';
        if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
          modes.add(normalized);
        }
      }
    } else if (rawModes is String) {
      final cleaned = rawModes
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '');
      for (final mode in cleaned.split(',')) {
        final normalized = mode.trim().toUpperCase();
        if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
          modes.add(normalized);
        }
      }
    }

    if (modes.isEmpty) {
      return const ['CASH', 'OFFLINE_BANK_TRANSFER', 'ONLINE'];
    }

    return modes.toSet().toList();
  }

  String _rowPaymentKey(Map<String, dynamic> payment) {
    final dueId =
        payment['DueId']?.toString().trim() ??
        payment['dueId']?.toString().trim() ??
        '';
    if (dueId.isNotEmpty) {
      return dueId;
    }

    final paymentId = payment['paymentId']?.toString().trim() ?? '';
    if (paymentId.isNotEmpty) {
      return paymentId;
    }

    return payment.hashCode.toString();
  }

  String _formatAmountForRequest(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  int _toPaise(double amount) {
    return (amount * 100).round();
  }

  int _cycleSortRank(Map<String, dynamic> due) {
    final rawCycle =
        due['collectionCycle']?.toString().trim().toUpperCase() ?? '';
    final normalized = rawCycle.replaceAll(RegExp(r'[^A-Z]'), '');

    if (normalized == 'MONTHLY') return 0;
    if (normalized == 'QUARTERLY' || normalized == 'QUATERLY') return 1;
    if (normalized == 'HALFYEARLY') return 2;
    if (normalized == 'YEARLY') return 3;
    if (normalized == 'ONCE') return 4;
    return 5;
  }

  List<Map<String, dynamic>> _sortDuesByCycleSequence(
    List<Map<String, dynamic>> dues,
  ) {
    final sorted = List<Map<String, dynamic>>.from(dues);
    sorted.sort((a, b) {
      final rankCompare = _cycleSortRank(a).compareTo(_cycleSortRank(b));
      if (rankCompare != 0) return rankCompare;

      final startA = _parseDueDate(a['dueStartDate']?.toString().trim() ?? '');
      final startB = _parseDueDate(b['dueStartDate']?.toString().trim() ?? '');
      if (startA != null && startB != null) {
        final startCompare = startA.compareTo(startB);
        if (startCompare != 0) return startCompare;
      }

      final dueA = _parseDueDate(a['dueDate']?.toString().trim() ?? '');
      final dueB = _parseDueDate(b['dueDate']?.toString().trim() ?? '');
      if (dueA != null && dueB != null) {
        final dueCompare = dueA.compareTo(dueB);
        if (dueCompare != 0) return dueCompare;
      }

      return _displayCycle(
        a,
      ).toLowerCase().compareTo(_displayCycle(b).toLowerCase());
    });
    return sorted;
  }

  void _showStatusSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB3261E) : null,
      ),
    );
  }

  String _extractPayDuesMessage(Map<String, dynamic>? response) {
    final message = response?['message']?.toString().trim() ?? '';
    if (message.isNotEmpty && message.toLowerCase() != 'null') {
      return message;
    }
    return 'Payment completed successfully.';
  }

  String _extractPayDuesTransactionId(Map<String, dynamic>? response) {
    final candidates = [
      response?['transactionId'],
      response?['thirdPartyTransactionId'],
      response?['txnId'],
      response?['paymentTransactionId'],
      response?['data'] is Map
          ? (response?['data'] as Map)['transactionId']
          : null,
      response?['data'] is Map
          ? (response?['data'] as Map)['thirdPartyTransactionId']
          : null,
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '--';
  }

  String? _extractPayDuesReceiptBase64(Map<String, dynamic>? response) {
    final candidates = [
      response?['receipt'],
      response?['receiptBase64'],
      response?['base64Receipt'],
      response?['data'] is Map ? (response?['data'] as Map)['receipt'] : null,
      response?['data'] is Map
          ? (response?['data'] as Map)['receiptBase64']
          : null,
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return null;
  }

  Future<void> _showPayDuesSuccessDialog({
    required BuildContext hostContext,
    required String message,
    required String transactionId,
    required String? receiptBase64,
  }) async {
    await showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7FCFA),
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFD7EAE3)),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF0F8F82),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Payment Successful',
                  style: TextStyle(
                    color: Color(0xFF124B45),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF124B45),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7EAE3)),
                  ),
                  child: SelectableText(
                    'Transaction ID: $transactionId',
                    style: const TextStyle(
                      color: Color(0xFF0F8F82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF124B45),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F8F82),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: receiptBase64 == null
                  ? null
                  : () async {
                      final downloaded = await downloadBase64Receipt(
                        base64Data: receiptBase64,
                        fileName: 'receipt_$transactionId.pdf',
                      );
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            downloaded
                                ? 'Receipt downloaded successfully.'
                                : 'Unable to download receipt.',
                          ),
                          backgroundColor: downloaded
                              ? null
                              : const Color(0xFFB3261E),
                        ),
                      );
                    },
              child: const Text('Download Receipt.'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePayPressed(Map<String, dynamic> payment) async {
    final selection = await showDialog<_DueTenderSelection>(
      context: context,
      builder: (dialogContext) => _DueTenderDialog(
        duePayment: payment,
        allowedModes: _extractAllowedPaymentModes(payment),
        formatAsCurrency: widget.formatAsCurrency,
      ),
    );

    if (selection == null) {
      return;
    }

    final rowKey = _rowPaymentKey(payment);
    setState(() {
      _submittingRows[rowKey] = true;
    });

    try {
      final paymentId = payment['paymentId']?.toString().trim() ?? '';
      final dueId =
          payment['DueId']?.toString().trim() ??
          payment['dueId']?.toString().trim() ??
          '';

      if (paymentId.isEmpty || dueId.isEmpty) {
        _showStatusSnack(
          'Unable to proceed: paymentId or DueId was not provided.',
          isError: true,
        );
        return;
      }

      String transactionStatus;
      String thirdPartyTransactionId = '';
      String thirdPartyName = '';

      if (selection.tender == 'CASH') {
        transactionStatus = 'SUCCESS';
      } else if (selection.tender == 'ONLINE') {
        final onlineOutcome = await _runOnlinePayment(
          payment: payment,
          amount: selection.netPayable,
        );

        if (onlineOutcome == null) {
          return;
        }

        transactionStatus = onlineOutcome.transactionStatus;
        thirdPartyTransactionId = onlineOutcome.thirdPartyTransactionId;
        thirdPartyName = 'RAZORPAY';
      } else {
        transactionStatus = 'ONHOLD';
      }

      final requestBody = {
        'genericHeader': ApiService.userHeader != null
            ? Map<String, dynamic>.from(ApiService.userHeader!)
            : <String, dynamic>{},
        'paymentId': paymentId,
        'DueId': dueId,
        'amount': _formatAmountForRequest(selection.netPayable),
        'paymentTenderDataList': [
          {
            'tenderName': selection.tender,
            'amountPaid': _formatAmountForRequest(selection.netPayable),
          },
        ],
        'paymentCycle': payment['collectionCycle']?.toString().trim() ?? '',
        'paymentName': payment['paymentName']?.toString().trim() ?? '',
        'dueDate': payment['dueDate']?.toString().trim() ?? '',
        'dueStartDate': payment['dueStartDate']?.toString().trim() ?? '',
        'dueEndDate': payment['dueEndDate']?.toString().trim() ?? '',
        'bankInstrumentTenderDetails': selection.bankInstrumentTenderDetails,
        'thirdPartyTransactionId': thirdPartyTransactionId,
        'transactionStatus': transactionStatus,
        'thirdPartyName': thirdPartyName,
        'noOfPersons': selection.noOfPersons.toString(),
        'files': selection.listOfFiles,
      };

      final response = await ApiService.payDues(requestBody);
      final messageCode = response?['messageCode']?.toString() ?? '';
      final isSuccess = messageCode.startsWith('SUCC');

      if (isSuccess) {
        final hostContext = Navigator.of(context, rootNavigator: true).context;
        final successMessage = _extractPayDuesMessage(response);
        final transactionId = _extractPayDuesTransactionId(response);
        final receiptBase64 = _extractPayDuesReceiptBase64(response);
        if (widget.onPaymentCompleted != null) {
          await widget.onPaymentCompleted!.call();
        }
        if (!mounted) {
          await _showPayDuesSuccessDialog(
            hostContext: hostContext,
            message: successMessage,
            transactionId: transactionId,
            receiptBase64: receiptBase64,
          );
          return;
        }
        Navigator.of(context).pop();
        await _showPayDuesSuccessDialog(
          hostContext: hostContext,
          message: successMessage,
          transactionId: transactionId,
          receiptBase64: receiptBase64,
        );
      } else {
        _showStatusSnack(
          response?['message']?.toString() ?? 'Payment request failed.',
          isError: true,
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _submittingRows[rowKey] = false;
      });
    }
  }

  Future<_OnlinePaymentOutcome?> _runOnlinePayment({
    required Map<String, dynamic> payment,
    required double amount,
  }) async {
    final amountInPaise = _toPaise(amount);
    if (amountInPaise <= 0) {
      _showStatusSnack('Invalid amount for online payment.', isError: true);
      return null;
    }

    final dueDateText = payment['dueDate']?.toString().trim() ?? '';
    final parsedDueDate = _parseDueDate(dueDateText);
    final eventDate = (parsedDueDate ?? DateTime.now()).toIso8601String();

    final createOrderResponse = await ApiService.createRazorPayOrder(
      amountInPaisa: amountInPaise.toString(),
      eventDate: eventDate,
      transactionType: 'DUE_PAYMENT',
    );

    final createOrderCode =
        createOrderResponse?['messageCode']?.toString().trim() ?? '';
    if (!createOrderCode.startsWith('SUCC')) {
      _showStatusSnack(
        createOrderResponse?['message']?.toString() ??
            'Unable to create Razorpay order.',
        isError: true,
      );
      return null;
    }

    final order = createOrderResponse?['order'];
    final orderMap = order is Map
        ? Map<String, dynamic>.from(order)
        : <String, dynamic>{};
    final orderId = orderMap['id']?.toString().trim() ?? '';
    if (orderId.isEmpty) {
      _showStatusSnack('Payment order ID was not returned.', isError: true);
      return null;
    }

    final paymentResult = await openRazorpayCheckout(
      key: _razorpayKey,
      orderId: orderId,
      amountInPaise: amountInPaise,
      name: 'Secura Due Payment',
      description: payment['paymentName']?.toString().trim().isNotEmpty == true
          ? '${payment['paymentName']} Due'
          : 'Due payment',
      customerName: ApiService.getDisplayName(),
    );

    final failedMessage = (paymentResult.errorMessage ?? '').toLowerCase();
    var transactionStatus = 'FAILED';
    if (paymentResult.success) {
      transactionStatus = 'SUCCESS';
    } else if (failedMessage.contains('cancel')) {
      transactionStatus = 'ONHOLD';
    }

    if (paymentResult.success &&
        (paymentResult.paymentId?.isNotEmpty ?? false) &&
        (paymentResult.signature?.isNotEmpty ?? false)) {
      final verifyResponse = await ApiService.verifyPayment(
        razorpayOrderId: paymentResult.orderId ?? orderId,
        razorpayPaymentId: paymentResult.paymentId!,
        razorpaySignature: paymentResult.signature!,
      );
      final verifyCode = verifyResponse?['messageCode']?.toString() ?? '';
      if (!verifyCode.startsWith('SUCC')) {
        transactionStatus = 'FAILED';
      }
    }

    return _OnlinePaymentOutcome(
      transactionStatus: transactionStatus,
      thirdPartyTransactionId: paymentResult.paymentId ?? '',
    );
  }

  Widget _buildSelectedDueSummary(Map<String, dynamic> due) {
    final amount = due['amount']?.toString().trim() ?? '0';
    final gstAmount = due['gstAmount']?.toString().trim() ?? '0';
    final gstPercentage = due['gstPercentage']?.toString().trim() ?? '';
    final totalAmount = due['totalAmount']?.toString().trim() ?? '0';
    final totalAddedCharges =
        due['totalAddedCharges']?.toString().trim() ?? '0';
    final dueStartDate = due['dueStartDate']?.toString().trim() ?? '--';
    final dueEndDate = due['dueEndDate']?.toString().trim() ?? '--';
    final dueDate = due['dueDate']?.toString().trim() ?? '--';
    final paymentType = due['paymentType']?.toString().trim() ?? '--';
    final discountCode = due['discountCode']?.toString().trim() ?? '';
    final discountedAmount = due['discountedAmount']?.toString().trim() ?? '';
    final fineCode = due['fineCode']?.toString().trim() ?? '';
    final fineAmount = due['fineAmount']?.toString().trim() ?? '';
    final rowKey = _rowPaymentKey(due);
    final isSubmitting = _submittingRows[rowKey] ?? false;

    final hasDiscountAmount =
        discountedAmount.isNotEmpty &&
        discountedAmount.toLowerCase() != 'null' &&
        discountedAmount != '0';
    final hasDiscountCode =
        discountCode.isNotEmpty && discountCode.toLowerCase() != 'null';

    final discountText = hasDiscountAmount
        ? hasDiscountCode
              ? '${widget.formatAsCurrency(discountedAmount)} ($discountCode)'
              : widget.formatAsCurrency(discountedAmount)
        : '--';

    final fineText =
        fineAmount.isNotEmpty &&
            fineAmount.toLowerCase() != 'null' &&
            fineAmount != '0'
        ? widget.formatAsCurrency(fineAmount)
        : fineCode.isNotEmpty && fineCode.toLowerCase() != 'null'
        ? fineCode
        : '--';

    final totalSavingsText = hasDiscountAmount
        ? widget.formatAsCurrency(discountedAmount)
        : '--';

    final gstText =
        gstPercentage.isNotEmpty && gstPercentage.toLowerCase() != 'null'
        ? '${widget.formatAsCurrency(gstAmount)} ($gstPercentage%)'
        : widget.formatAsCurrency(gstAmount);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7EAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Due Details',
            style: TextStyle(
              color: Color(0xFF124B45),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const headerTextStyle = TextStyle(
                color: Color(0xFF124B45),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              );
              const rowTextStyle = TextStyle(
                color: Color(0xFF124B45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );

              Widget buildCell(
                String value, {
                TextStyle? style,
                bool isHeader = false,
              }) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style:
                          style ?? (isHeader ? headerTextStyle : rowTextStyle),
                    ),
                  ),
                );
              }

              return Container(
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7EAE3)),
                ),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xFFE2EEEA)),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                    3: FlexColumnWidth(),
                    4: FlexColumnWidth(),
                    5: FlexColumnWidth(),
                    6: FlexColumnWidth(),
                    7: FlexColumnWidth(),
                    8: FlexColumnWidth(),
                    9: FlexColumnWidth(),
                    10: FlexColumnWidth(),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFE4F3F0)),
                      children: [
                        buildCell('Cycle Start Date', isHeader: true),
                        buildCell('Cycle End Date', isHeader: true),
                        buildCell('Due Date', isHeader: true),
                        buildCell('Amount', isHeader: true),
                        buildCell('Discount', isHeader: true),
                        buildCell('GST', isHeader: true),
                        buildCell('Added Charges', isHeader: true),
                        buildCell('Fine', isHeader: true),
                        buildCell('Total Savings', isHeader: true),
                        buildCell('Payment Type', isHeader: true),
                        buildCell('Net Payable', isHeader: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        buildCell(dueStartDate),
                        buildCell(dueEndDate),
                        buildCell(dueDate),
                        buildCell(widget.formatAsCurrency(amount)),
                        buildCell(discountText),
                        buildCell(gstText),
                        buildCell(widget.formatAsCurrency(totalAddedCharges)),
                        buildCell(fineText),
                        buildCell(totalSavingsText),
                        buildCell(_toCamelCase(paymentType)),
                        buildCell(
                          widget.formatAsCurrency(totalAmount),
                          style: const TextStyle(
                            color: Color(0xFF0F8F82),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F8F82),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: isSubmitting ? null : () => _handlePayPressed(due),
              child: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Pay', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueTabButton({
    required String label,
    required bool selected,
    required bool isOverdueTab,
    required VoidCallback onTap,
  }) {
    final selectedColor = isOverdueTab
        ? const Color(0xFFB3261E)
        : const Color(0xFF0F8F82);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? selectedColor : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF124B45),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueTabsSection({
    required int overdueCount,
    required int activeCount,
    required _DueSectionTab selectedTab,
    required VoidCallback onOverdueTap,
    required VoidCallback onActiveTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2E7E1)),
      ),
      child: Row(
        children: [
          _buildDueTabButton(
            label: 'Overdue ($overdueCount)',
            selected: selectedTab == _DueSectionTab.overdue,
            isOverdueTab: true,
            onTap: onOverdueTap,
          ),
          const SizedBox(width: 4),
          _buildDueTabButton(
            label: 'Active Due ($activeCount)',
            selected: selectedTab == _DueSectionTab.active,
            isOverdueTab: false,
            onTap: onActiveTap,
          ),
        ],
      ),
    );
  }

  String _displayCycle(Map<String, dynamic> due) {
    final rawCycle = due['collectionCycle']?.toString().trim() ?? '';
    if (rawCycle.isEmpty || rawCycle.toLowerCase() == 'null') {
      return '--';
    }
    return _toCamelCase(rawCycle);
  }

  Widget _buildOverdueDueItem(Map<String, dynamic> due) {
    final cycle = _displayCycle(due);
    final dueDateText = due['dueDate']?.toString().trim() ?? '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7EAE3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              cycle,
              style: const TextStyle(
                color: Color(0xFF124B45),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              dueDateText,
              style: const TextStyle(
                color: Color(0xFF124B45),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [_buildSelectedDueSummary(due)],
      ),
    );
  }

  Widget _buildGroupPanel(_DueGroupData group, int index) {
    final groupId = group.groupId;
    final selectedTab = _selectedTabs[groupId] ?? _DueSectionTab.active;
    final dues = _duesForTab(group, selectedTab);
    final overdueCount = _duesForTab(group, _DueSectionTab.overdue).length;
    final activeCount = _duesForTab(group, _DueSectionTab.active).length;
    final selectedDueId = _selectedDueByGroup[groupId];
    final selectedDue = dues.firstWhere(
      (due) => _dueId(due) == selectedDueId,
      orElse: () => dues.isNotEmpty ? dues.first : const <String, dynamic>{},
    );

    if (dues.isNotEmpty && selectedDueId == null) {
      final firstDueId = _dueId(dues.first);
      if (firstDueId.isNotEmpty) {
        _selectedDueByGroup[groupId] = firstDueId;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7EAE3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: index == 0,
        onExpansionChanged: (_) => setState(() {}),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          _toCamelCase(group.paymentName),
          style: const TextStyle(
            color: Color(0xFF124B45),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${group.dues.length} due cycle${group.dues.length == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.black54),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.30,
              alignment: Alignment.centerLeft,
              child: _buildDueTabsSection(
                overdueCount: overdueCount,
                activeCount: activeCount,
                selectedTab: selectedTab,
                onOverdueTap: () {
                  setState(() {
                    _selectedTabs[groupId] = _DueSectionTab.overdue;
                    _selectedDueByGroup.remove(groupId);
                  });
                },
                onActiveTap: () {
                  setState(() {
                    _selectedTabs[groupId] = _DueSectionTab.active;
                    _selectedDueByGroup.remove(groupId);
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (dues.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FCFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7EAE3)),
              ),
              child: Text(
                selectedTab == _DueSectionTab.overdue
                    ? 'No overdue dues in this payment.'
                    : 'No active dues in this payment.',
                style: const TextStyle(color: Colors.black54),
              ),
            )
          else if (selectedTab == _DueSectionTab.overdue)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dues.map((due) => _buildOverdueDueItem(due)).toList(),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: dues.map((due) {
                  final currentDueId = _dueId(due);
                  final isSelected =
                      currentDueId.isNotEmpty &&
                      currentDueId == _selectedDueByGroup[groupId];
                  final label = _displayCycle(due);

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      if (currentDueId.isEmpty) {
                        return;
                      }
                      setState(() {
                        _selectedDueByGroup[groupId] = currentDueId;
                      });
                    },
                    selectedColor: const Color(0xFF0F8F82),
                    side: const BorderSide(color: Color(0xFF0F8F82)),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF124B45),
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedDue.isNotEmpty) _buildSelectedDueSummary(selectedDue),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedPayments = _groupedPayments();
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.92;
    final maxDialogWidth = MediaQuery.of(context).size.width * 0.96;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
          minWidth: 340,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE9FFF7), Color(0xFFFFF2D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7EAE3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F8F82),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF124B45),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Choose overdue/active dues and complete payment by cycle.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: groupedPayments.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FCFA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD7EAE3),
                                ),
                              ),
                              child: const Text(
                                'No due payments found.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : Column(
                              children: [
                                ...groupedPayments.asMap().entries.map(
                                  (entry) =>
                                      _buildGroupPanel(entry.value, entry.key),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlinePaymentOutcome {
  const _OnlinePaymentOutcome({
    required this.transactionStatus,
    required this.thirdPartyTransactionId,
  });

  final String transactionStatus;
  final String thirdPartyTransactionId;
}

class _DueTenderSelection {
  const _DueTenderSelection({
    required this.tender,
    required this.netPayable,
    required this.noOfPersons,
    required this.listOfFiles,
    required this.bankInstrumentTenderDetails,
  });

  final String tender;
  final double netPayable;
  final int noOfPersons;
  final List<String> listOfFiles;
  final List<Map<String, dynamic>> bankInstrumentTenderDetails;
}

class _PickedReceipt {
  const _PickedReceipt({required this.fileName, required this.filePayload});

  final String fileName;
  final String filePayload;
}

class _DueTenderDialog extends StatefulWidget {
  const _DueTenderDialog({
    required this.duePayment,
    required this.allowedModes,
    required this.formatAsCurrency,
  });

  final Map<String, dynamic> duePayment;
  final List<String> allowedModes;
  final String Function(String amount) formatAsCurrency;

  @override
  State<_DueTenderDialog> createState() => _DueTenderDialogState();
}

class _DueTenderDialogState extends State<_DueTenderDialog> {
  final TextEditingController _personCountController = TextEditingController(
    text: '1',
  );
  final List<_PickedReceipt> _receipts = <_PickedReceipt>[];
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _chequeDateController = TextEditingController();
  final TextEditingController _chequeBankNameController =
      TextEditingController();
  final TextEditingController _chequeAccountHolderController =
      TextEditingController();
  final TextEditingController _chequeAccountNumberController =
      TextEditingController();
  final TextEditingController _ddBankNameController = TextEditingController();
  final TextEditingController _ddPayableAtController = TextEditingController();
  final TextEditingController _ddNumberController = TextEditingController();
  final TextEditingController _ddIssueDateController = TextEditingController();
  final TextEditingController _transferBankNameController =
      TextEditingController();
  final TextEditingController _transferAccountNumberController =
      TextEditingController();
  final TextEditingController _transferDateController = TextEditingController();

  late String _selectedTender;
  late int _personCount;
  Timer? _perHeadDebounce;
  bool _loadingPerHeadAmount = false;
  String? _perHeadAmountError;
  double? _perHeadTotalAmount;
  int _perHeadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _selectedTender = widget.allowedModes.isNotEmpty
        ? widget.allowedModes.first
        : 'ONLINE';
    _personCount = 1;
    if (_isPerHeadCapita) {
      _schedulePerHeadAmountRefresh(immediate: true);
    }
  }

  @override
  void dispose() {
    _perHeadDebounce?.cancel();
    _personCountController.dispose();
    _chequeNumberController.dispose();
    _chequeDateController.dispose();
    _chequeBankNameController.dispose();
    _chequeAccountHolderController.dispose();
    _chequeAccountNumberController.dispose();
    _ddBankNameController.dispose();
    _ddPayableAtController.dispose();
    _ddNumberController.dispose();
    _ddIssueDateController.dispose();
    _transferBankNameController.dispose();
    _transferAccountNumberController.dispose();
    _transferDateController.dispose();
    super.dispose();
  }

  bool get _isPerHeadCapita {
    final capita = widget.duePayment['paymentCapita']?.toString().trim() ?? '';
    return capita.toUpperCase() == 'PER_HEAD';
  }

  double get _baseAmount {
    final totalAmount =
        widget.duePayment['totalAmount']?.toString().trim() ?? '';
    final normalized = totalAmount.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  double get _netPayable {
    if (_isPerHeadCapita) {
      return _perHeadTotalAmount ?? (_baseAmount * _personCount);
    }
    return _baseAmount;
  }

  String get _dueId {
    final fromUpper = widget.duePayment['DueId']?.toString().trim() ?? '';
    if (fromUpper.isNotEmpty) {
      return fromUpper;
    }
    return widget.duePayment['dueId']?.toString().trim() ?? '';
  }

  bool get _requiresReceipts =>
      _selectedTender == 'CHEQUE' ||
      _selectedTender == 'DEMAND_DRAFT' ||
      _selectedTender == 'OFFLINE_BANK_TRANSFER';

  bool get _suppressPerHeadApiMessage => _personCount == 3;

  bool get _requiresBankInstrumentDetails => _requiresReceipts;

  String _formatAmountForRequestValue(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  String get _requestAmountText => _formatAmountForRequestValue(_netPayable);

  String get _tenderDetailsHeader {
    switch (_selectedTender) {
      case 'CHEQUE':
        return 'Fill Cheque Details';
      case 'DEMAND_DRAFT':
        return 'Fill Demand Draft Details';
      case 'OFFLINE_BANK_TRANSFER':
        return 'Fill Transfer Details';
      default:
        return 'Fill Tender Details';
    }
  }

  String _displayMode(String mode) {
    final normalized = mode.replaceAll('_', ' ');
    final words = normalized
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .toList();
    return words.join(' ');
  }

  String _formatSummaryAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return widget.formatAsCurrency(amount.toInt().toString());
    }

    return widget.formatAsCurrency(amount.toStringAsFixed(2));
  }

  void _schedulePerHeadAmountRefresh({bool immediate = false}) {
    _perHeadDebounce?.cancel();
    if (!_isPerHeadCapita) {
      return;
    }

    if (immediate) {
      _refreshPerHeadAmount();
      return;
    }

    _perHeadDebounce = Timer(
      const Duration(milliseconds: 350),
      _refreshPerHeadAmount,
    );
  }

  Future<void> _refreshPerHeadAmount() async {
    if (!_isPerHeadCapita) {
      return;
    }

    final dueId = _dueId;
    if (dueId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _perHeadAmountError = 'Due ID is missing for this payment.';
        _perHeadTotalAmount = null;
      });
      return;
    }

    final requestId = ++_perHeadRequestId;
    if (mounted) {
      setState(() {
        _loadingPerHeadAmount = true;
        _perHeadAmountError = null;
      });
    }

    final response = await ApiService.getDueAmountForPerHeadCalculation(
      noOfPerson: _personCount.toString(),
      dueId: dueId,
    );

    if (!mounted || requestId != _perHeadRequestId) {
      return;
    }

    final messageCode = response?['messageCode']?.toString().trim() ?? '';
    final details = response?['dueAmountDetails'];
    if (messageCode.startsWith('SUCC') && details is Map) {
      final detailMap = Map<String, dynamic>.from(details);
      final totalAmountText = detailMap['totalAmount']?.toString().trim() ?? '';
      final normalized = totalAmountText.replaceAll(RegExp(r'[^0-9.]'), '');
      final totalAmount = double.tryParse(normalized);

      setState(() {
        _loadingPerHeadAmount = false;
        _perHeadAmountError = null;
        _perHeadTotalAmount = totalAmount;
      });
      return;
    }

    setState(() {
      _loadingPerHeadAmount = false;
      _perHeadAmountError = null;
      _perHeadTotalAmount = null;
    });
  }

  Future<void> _pickReceipts() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'],
      allowMultiple: true,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final pickedReceipts = <_PickedReceipt>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      final extension = (file.extension ?? '').toLowerCase();
      final mimeType = _mimeTypeFromExtension(extension);
      final encoded = base64Encode(bytes);
      pickedReceipts.add(
        _PickedReceipt(
          fileName: file.name,
          filePayload: 'data:$mimeType;name=${file.name};base64,$encoded',
        ),
      );
    }

    if (pickedReceipts.isEmpty) {
      return;
    }

    setState(() {
      _receipts.addAll(pickedReceipts);
    });
  }

  String _mimeTypeFromExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  void _clearTenderSpecificState() {
    _receipts.clear();
    _chequeNumberController.clear();
    _chequeDateController.clear();
    _chequeBankNameController.clear();
    _chequeAccountHolderController.clear();
    _chequeAccountNumberController.clear();
    _ddBankNameController.clear();
    _ddPayableAtController.clear();
    _ddNumberController.clear();
    _ddIssueDateController.clear();
    _transferBankNameController.clear();
    _transferAccountNumberController.clear();
    _transferDateController.clear();
  }

  bool _validateBankInstrumentDetails() {
    if (_selectedTender == 'CHEQUE') {
      return _chequeNumberController.text.trim().isNotEmpty &&
          _chequeDateController.text.trim().isNotEmpty &&
          _chequeBankNameController.text.trim().isNotEmpty &&
          _chequeAccountHolderController.text.trim().isNotEmpty &&
          _chequeAccountNumberController.text.trim().isNotEmpty;
    }

    if (_selectedTender == 'DEMAND_DRAFT') {
      return _ddBankNameController.text.trim().isNotEmpty &&
          _ddPayableAtController.text.trim().isNotEmpty &&
          _ddNumberController.text.trim().isNotEmpty &&
          _ddIssueDateController.text.trim().isNotEmpty;
    }

    if (_selectedTender == 'OFFLINE_BANK_TRANSFER') {
      return _transferBankNameController.text.trim().isNotEmpty &&
          _transferAccountNumberController.text.trim().isNotEmpty &&
          _transferDateController.text.trim().isNotEmpty;
    }

    return true;
  }

  List<Map<String, dynamic>> _buildBankInstrumentTenderDetails() {
    if (_selectedTender == 'CHEQUE') {
      return [
        {
          'tenderType': 'CHEQUE',
          'chequeNumber': _chequeNumberController.text.trim(),
          'chequeDate': _chequeDateController.text.trim(),
          'bankName': _chequeBankNameController.text.trim(),
          'accountHolderName': _chequeAccountHolderController.text.trim(),
          'accountNumber': _chequeAccountNumberController.text.trim(),
          'amount': _requestAmountText,
          'ddPayAtBranch': null,
          'ddNumber': null,
          'ddIssueDate': null,
          'remarks': '',
        },
      ];
    }

    if (_selectedTender == 'DEMAND_DRAFT') {
      return [
        {
          'tenderType': 'DEMAND_DRAFT',
          'chequeNumber': null,
          'chequeDate': null,
          'bankName': _ddBankNameController.text.trim(),
          'accountHolderName': null,
          'amount': _requestAmountText,
          'ddPayAtBranch': _ddPayableAtController.text.trim(),
          'ddNumber': _ddNumberController.text.trim(),
          'ddIssueDate': _ddIssueDateController.text.trim(),
          'remarks': '',
        },
      ];
    }

    if (_selectedTender == 'OFFLINE_BANK_TRANSFER') {
      return [
        {
          'tenderType': 'OFFLINE_BANK_TRANSFER',
          'chequeNumber': null,
          'chequeDate': _transferDateController.text.trim(),
          'bankName': _transferBankNameController.text.trim(),
          'accountHolderName': null,
          'accountNumber': _transferAccountNumberController.text.trim(),
          'amount': _requestAmountText,
          'ddPayAtBranch': null,
          'ddNumber': null,
          'ddIssueDate': null,
          'transferDate': _transferDateController.text.trim(),
          'remarks': '',
        },
      ];
    }

    return const <Map<String, dynamic>>[];
  }

  Widget _buildInstrumentField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: readOnly ? const Color(0xFFF0F5F4) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7EAE3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7EAE3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0F8F82), width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyAmountField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: _requestAmountText,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Amount',
          filled: true,
          fillColor: const Color(0xFFF0F5F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7EAE3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7EAE3)),
          ),
        ),
      ),
    );
  }

  Widget _buildBankInstrumentDetailsSection() {
    if (!_requiresBankInstrumentDetails) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      Text(
        _tenderDetailsHeader,
        style: const TextStyle(
          color: Color(0xFF124B45),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
    ];

    if (_selectedTender == 'CHEQUE') {
      children.addAll([
        _buildInstrumentField(
          label: 'Cheque Number',
          controller: _chequeNumberController,
          keyboardType: TextInputType.number,
        ),
        _buildInstrumentField(
          label: 'Cheque Date',
          controller: _chequeDateController,
        ),
        _buildInstrumentField(
          label: 'Bank Name',
          controller: _chequeBankNameController,
        ),
        _buildInstrumentField(
          label: 'Account Holder Name',
          controller: _chequeAccountHolderController,
        ),
        _buildInstrumentField(
          label: 'Account Number',
          controller: _chequeAccountNumberController,
        ),
      ]);
    } else if (_selectedTender == 'DEMAND_DRAFT') {
      children.addAll([
        _buildInstrumentField(
          label: 'DD Bank Name',
          controller: _ddBankNameController,
        ),
        _buildInstrumentField(
          label: 'DD Payable At',
          controller: _ddPayableAtController,
        ),
        _buildInstrumentField(
          label: 'DD Number',
          controller: _ddNumberController,
        ),
        _buildInstrumentField(
          label: 'DD Issue Date',
          controller: _ddIssueDateController,
        ),
      ]);
    } else if (_selectedTender == 'OFFLINE_BANK_TRANSFER') {
      children.addAll([
        _buildInstrumentField(
          label: 'From Bank Name',
          controller: _transferBankNameController,
        ),
        _buildInstrumentField(
          label: 'Account Number',
          controller: _transferAccountNumberController,
        ),
        _buildInstrumentField(
          label: 'Transfer Date',
          controller: _transferDateController,
        ),
      ]);
    }

    children.add(_buildReadOnlyAmountField());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7EAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  void _confirmSelection() {
    if (_isPerHeadCapita && _loadingPerHeadAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, amount calculation is in progress.'),
        ),
      );
      return;
    }

    // For PER_HEAD dues, allow payment with entered person count even when
    // per-head calculation API is unavailable; _netPayable will fall back to
    // baseAmount * personCount.

    if (_requiresBankInstrumentDetails && !_validateBankInstrumentDetails()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all ${_displayMode(_selectedTender)} details.',
          ),
          backgroundColor: const Color(0xFFB3261E),
        ),
      );
      return;
    }

    if (_requiresReceipts && _receipts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one receipt file.'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _DueTenderSelection(
        tender: _selectedTender,
        netPayable: _netPayable,
        noOfPersons: _isPerHeadCapita ? _personCount : 1,
        listOfFiles: _receipts.map((receipt) => receipt.filePayload).toList(),
        bankInstrumentTenderDetails: _buildBankInstrumentTenderDetails(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentName =
        widget.duePayment['paymentName']?.toString().trim() ?? '--';

    return AlertDialog(
      backgroundColor: const Color(0xFFF7FCFA),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD7EAE3)),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE2F3EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF0F8F82),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Choose Tender',
              style: TextStyle(
                color: Color(0xFF124B45),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7EAE3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment: $paymentName',
                      style: const TextStyle(
                        color: Color(0xFF124B45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Amount: ${_formatSummaryAmount(_netPayable)}',
                      style: const TextStyle(
                        color: Color(0xFF0F8F82),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPerHeadCapita && _loadingPerHeadAmount)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Fetching amount for entered person count...',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              if (_isPerHeadCapita &&
                  !_suppressPerHeadApiMessage &&
                  _perHeadAmountError != null &&
                  _perHeadAmountError!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _perHeadAmountError!,
                    style: const TextStyle(
                      color: Color(0xFFB3261E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: widget.allowedModes.map((mode) {
                  final isSelected = _selectedTender == mode;
                  return ChoiceChip(
                    label: Text(_displayMode(mode)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        if (_selectedTender != mode) {
                          _clearTenderSpecificState();
                        }
                        _selectedTender = mode;
                      });
                    },
                    selectedColor: const Color(0xFF0F8F82),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0F8F82)),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF124B45),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              if (_isPerHeadCapita) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _personCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number Of Persons',
                    helperText: 'Total amount is fetched based on person count',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7EAE3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7EAE3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F8F82),
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim()) ?? 1;
                    setState(() {
                      _personCount = parsed < 1 ? 1 : parsed;
                    });
                    _schedulePerHeadAmountRefresh();
                  },
                ),
              ],
              _buildBankInstrumentDetailsSection(),
              if (_requiresReceipts) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickReceipts,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Document'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F8F82),
                    side: const BorderSide(color: Color(0xFF0F8F82)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_receipts.isEmpty)
                  const Text(
                    'Accepted formats: image or PDF',
                    style: TextStyle(color: Color(0xFF51605F), fontSize: 13),
                  )
                else
                  ..._receipts.asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD7EAE3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attachment_rounded,
                            size: 16,
                            color: Color(0xFF0F8F82),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value.fileName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF124B45),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _receipts.removeAt(entry.key);
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF5E6D6B),
                            ),
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF124B45),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F8F82),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _confirmSelection,
          child: const Text('Pay'),
        ),
      ],
    );
  }
}
