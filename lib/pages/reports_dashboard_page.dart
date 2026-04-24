import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../widgets/sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data
// ─────────────────────────────────────────────────────────────────────────────

const _months = [
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

// Monthly income & expense (in ₹ thousands)
const _incomeData = [
  120.0,
  145.0,
  132.0,
  160.0,
  155.0,
  178.0,
  165.0,
  190.0,
  175.0,
  200.0,
  188.0,
  210.0,
];
const _expenseData = [
  80.0,
  95.0,
  88.0,
  110.0,
  102.0,
  120.0,
  115.0,
  130.0,
  125.0,
  140.0,
  133.0,
  148.0,
];

// Expense categories (pie)
const _expensePieData = [
  _PieDatum('Maintenance', 32, Color(0xFF0F8F82)),
  _PieDatum('Utilities', 22, Color(0xFF26C6AD)),
  _PieDatum('Salaries', 18, Color(0xFFE0DA84)),
  _PieDatum('Security', 12, Color(0xFF124B45)),
  _PieDatum('Repairs', 10, Color(0xFFF4768A)),
  _PieDatum('Others', 6, Color(0xFFA8D8EA)),
];

// Income categories (pie)
const _incomePieData = [
  _PieDatum('Maintenance Fees', 45, Color(0xFF0F8F82)),
  _PieDatum('Parking Charges', 18, Color(0xFF26C6AD)),
  _PieDatum('Club House', 12, Color(0xFFE0DA84)),
  _PieDatum('Late Fees', 10, Color(0xFF124B45)),
  _PieDatum('Event Bookings', 9, Color(0xFFF4768A)),
  _PieDatum('Others', 6, Color(0xFFA8D8EA)),
];

// Expense per flat per month (₹)
const _expensePerFlat = [
  2400.0,
  2900.0,
  2650.0,
  3100.0,
  2950.0,
  3300.0,
  3150.0,
  3500.0,
  3250.0,
  3700.0,
  3450.0,
  3800.0,
];

// Income per flat per month (₹)
const _incomePerFlat = [
  3600.0,
  4100.0,
  3850.0,
  4400.0,
  4250.0,
  4700.0,
  4500.0,
  4900.0,
  4650.0,
  5100.0,
  4850.0,
  5300.0,
];

// Budget vs Actual (₹ thousands)
const _budgetData = [
  100.0,
  120.0,
  110.0,
  130.0,
  125.0,
  145.0,
  135.0,
  155.0,
  145.0,
  165.0,
  155.0,
  175.0,
];
const _actualData = [
  80.0,
  95.0,
  88.0,
  110.0,
  102.0,
  120.0,
  115.0,
  130.0,
  125.0,
  140.0,
  133.0,
  148.0,
];

class _PieDatum {
  const _PieDatum(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Sheet Dummy Data (tables)
// ─────────────────────────────────────────────────────────────────────────────

const _balanceSheetRows = [
  ['Assets', '', ''],
  ['Cash & Bank Balance', '₹4,85,000', '₹3,92,000'],
  ['Fixed Deposits', '₹12,00,000', '₹10,50,000'],
  ['Receivable from Owners', '₹1,20,500', '₹98,200'],
  ['Prepaid Expenses', '₹22,000', '₹18,500'],
  ['Total Assets', '₹18,27,500', '₹15,58,700'],
  ['Liabilities', '', ''],
  ['Advance from Owners', '₹2,40,000', '₹1,95,000'],
  ['Outstanding Expenses', '₹85,000', '₹72,000'],
  ['Reserve Fund', '₹8,50,000', '₹7,20,000'],
  ['Corpus Fund', '₹6,52,500', '₹5,71,700'],
  ['Total Liabilities', '₹18,27,500', '₹15,58,700'],
];

const _taxSheetRows = [
  ['Income Head', 'Gross (₹)', 'Taxable (₹)', 'Tax (₹)'],
  ['Maintenance Collection', '18,00,000', '0', '0'],
  ['Interest on FD', '72,000', '72,000', '7,200'],
  ['Club House Fees', '1,20,000', '1,20,000', '12,000'],
  ['Late Fee Income', '45,000', '45,000', '4,500'],
  ['Event Bookings', '60,000', '60,000', '6,000'],
  ['Total', '20,97,000', '2,97,000', '29,700'],
];

const _paymentCollectionRows = [
  ['Flat No', 'Owner', 'Due (₹)', 'Paid (₹)', 'Balance (₹)', 'Status'],
  ['A-101', 'Ramesh Kumar', '12,000', '12,000', '0', 'Paid'],
  ['A-102', 'Sunita Verma', '12,000', '6,000', '6,000', 'Partial'],
  ['A-103', 'Amit Shah', '12,000', '0', '12,000', 'Defaulter'],
  ['B-201', 'Priya Nair', '12,000', '12,000', '0', 'Paid'],
  ['B-202', 'Vijay Iyer', '12,000', '12,000', '0', 'Paid'],
  ['B-203', 'Meena Pillai', '12,000', '4,000', '8,000', 'Defaulter'],
  ['C-301', 'Rajan Mehta', '12,000', '12,000', '0', 'Paid'],
  ['C-302', 'Kavita Rao', '12,000', '12,000', '0', 'Paid'],
];

const _defaulterRows = [
  ['Flat No', 'Owner', 'Outstanding (₹)', 'Months Due', 'Late Fee (₹)'],
  ['A-103', 'Amit Shah', '12,000', '2', '1,200'],
  ['B-203', 'Meena Pillai', '8,000', '1', '800'],
  ['C-109', 'Rahul Nanda', '10,500', '2', '1,050'],
  ['D-402', 'Neha Rao', '7,500', '1', '750'],
];

const _penaltiesRows = [
  ['Flat No', 'Owner', 'Penalty Type', 'Amount (₹)', 'Status'],
  ['A-104', 'Sonal Desai', 'Late Payment', '500', 'Open'],
  ['B-101', 'Ritu Sinha', 'Parking Violation', '1,000', 'Paid'],
  ['C-205', 'Kiran Gupta', 'Noise Complaint', '750', 'Open'],
  ['D-301', 'Harsh Patel', 'Late Payment', '1,200', 'Paid'],
];

const _budgetVsActualRows = [
  ['Category', 'Budget (₹)', 'Actual (₹)', 'Variance (₹)', 'Status'],
  ['Maintenance', '1,20,000', '1,15,000', '+5,000', 'Under Budget'],
  ['Utilities', '80,000', '88,500', '-8,500', 'Over Budget'],
  ['Salaries', '2,00,000', '2,00,000', '0', 'On Target'],
  ['Security', '60,000', '58,000', '+2,000', 'Under Budget'],
  ['Repairs', '50,000', '72,000', '-22,000', 'Over Budget'],
  ['Events', '30,000', '24,000', '+6,000', 'Under Budget'],
  ['Total', '5,40,000', '5,57,500', '-17,500', 'Over Budget'],
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ReportsDashboardPage extends StatefulWidget {
  const ReportsDashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ReportsDashboardPage> createState() => _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends State<ReportsDashboardPage>
    with SingleTickerProviderStateMixin {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const Color _panelBg = Color(0xFFF5FBF9);

  late TabController _tabController;

  // Pie chart touch state
  int _expensePieTouched = -1;
  int _incomePieTouched = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!widget.embedded) {
      return Scaffold(
        drawer: SideBar(
          selectedSection: AppSection.reports,
          onSectionSelected: (_) {},
        ),
        body: _buildBody(context),
      );
    }
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    final isMobile = _isMobile(context);
    return Container(
      color: _panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          _buildReportOptions(isMobile),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReportDashboardTab(),
                _buildBalanceSheetTab(),
                _buildTaxSheetTab(),
                _buildPaymentCollectionTab(),
                _buildDefaulterTab(),
                _buildPenaltiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptions(bool isMobile) {
    final options = [
      _ReportOptionItem('Report Dashboard', Icons.dashboard_rounded, 0),
      _ReportOptionItem('Balance Sheet', Icons.account_balance_rounded, 1),
      _ReportOptionItem('Tax Sheet', Icons.receipt_long_rounded, 2),
      _ReportOptionItem('Payment Wise Collection', Icons.payments_rounded, 3),
      _ReportOptionItem('Defaulter Report', Icons.warning_amber_rounded, 4),
      _ReportOptionItem('Penalties Report', Icons.gavel_rounded, 5),
    ];

    final content = isMobile
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: options
                  .map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildReportOptionCard(o),
                    ),
                  )
                  .toList(),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map(_buildReportOptionCard).toList(),
            ),
          );

    return Container(color: Colors.white, child: content);
  }

  Widget _buildReportOptionCard(_ReportOptionItem option) {
    final isSelected = _tabController.index == option.tabIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _tabController.animateTo(option.tabIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(minWidth: 210),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor.withOpacity(0.12) : _panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _brandColor : const Color(0xFFDCEEEA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              color: isSelected ? _brandColor : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                option.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _brandColor : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brandColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: _brandColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Reports Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _brandTextColor,
                    ),
                  ),
                  Text(
                    'Financial insights and analytics',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildKpiRow(isMobile),
        ],
      ),
    );
  }

  // ── KPI Cards ──────────────────────────────────────────────────────────────

  Widget _buildKpiRow(bool isMobile) {
    final kpis = [
      _KpiData(
        'Total Income',
        '₹20,97,000',
        Icons.trending_up_rounded,
        const Color(0xFF0F8F82),
      ),
      _KpiData(
        'Total Expense',
        '₹13,24,500',
        Icons.trending_down_rounded,
        const Color(0xFFE57373),
      ),
      _KpiData(
        'Net Surplus',
        '₹7,72,500',
        Icons.account_balance_wallet_rounded,
        const Color(0xFF26C6AD),
      ),
      _KpiData(
        'Defaulters',
        '2 / 8',
        Icons.warning_amber_rounded,
        const Color(0xFFFFB300),
        note: 'To collect: ₹20,000',
      ),
      _KpiData(
        'Income/Expense Ratio',
        '1.6',
        Icons.balance_rounded,
        const Color(0xFF124B45),
      ),
    ];

    if (isMobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: kpis.map(_buildKpiCard).toList(),
      );
    }
    return Row(
      children: kpis
          .map(
            (k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildKpiCard(k),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard(_KpiData k) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: k.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: k.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(k.icon, color: k.color, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  k.label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  k.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: k.color,
                  ),
                ),
                if (k.note != null)
                  Text(
                    k.note!,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Graphs Section ─────────────────────────────────────────────────────────

  Widget _buildGraphsSection(bool isMobile) {
    final graphs = [
      _buildIncomeVsExpenseChart(),
      _buildExpensePieChart(),
      _buildIncomePieChart(),
      _buildExpensePerFlatChart(),
      _buildIncomePerFlatChart(),
    ];

    if (isMobile) {
      return Column(
        children: graphs
            .map(
              (g) =>
                  Padding(padding: const EdgeInsets.only(bottom: 20), child: g),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        // Full-width income vs expense
        graphs[0],
        const SizedBox(height: 20),
        // Pie charts side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: graphs[1]),
            const SizedBox(width: 16),
            Expanded(child: graphs[2]),
          ],
        ),
        const SizedBox(height: 20),
        // Per-flat charts side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: graphs[3]),
            const SizedBox(width: 16),
            Expanded(child: graphs[4]),
          ],
        ),
      ],
    );
  }

  // ── Chart: Income vs Expense ───────────────────────────────────────────────

  Widget _buildIncomeVsExpenseChart() {
    return _ChartCard(
      title: 'Month Wise Income vs Expense',
      subtitle: 'FY 2025-26  ( ₹ in thousands )',
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 240,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) {
                final label = ri == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n₹${rod.toY.toStringAsFixed(0)}K',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _months.length) return const SizedBox();
                  return Text(
                    _months[i],
                    style: const TextStyle(fontSize: 9, color: Colors.black54),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: _incomeData[i],
                  color: const Color(0xFF0F8F82),
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: _expenseData[i],
                  color: const Color(0xFFE57373),
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }),
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF0F8F82), label: 'Income'),
        _LegendItem(color: Color(0xFFE57373), label: 'Expense'),
      ],
    );
  }

  // ── Chart: Expense Pie ─────────────────────────────────────────────────────

  Widget _buildExpensePieChart() {
    return _ChartCard(
      title: 'Expense Distribution',
      subtitle: 'Percentage breakdown by category',
      height: 240,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  _expensePieTouched = -1;
                } else {
                  _expensePieTouched =
                      response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 38,
          sections: List.generate(_expensePieData.length, (i) {
            final isTouched = i == _expensePieTouched;
            final d = _expensePieData[i];
            return PieChartSectionData(
              color: d.color,
              value: d.value,
              title: '${d.value.toInt()}%',
              radius: isTouched ? 68 : 58,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
      legend: _expensePieData
          .map((d) => _LegendItem(color: d.color, label: d.label))
          .toList(),
    );
  }

  // ── Chart: Income Pie ──────────────────────────────────────────────────────

  Widget _buildIncomePieChart() {
    return _ChartCard(
      title: 'Income Distribution',
      subtitle: 'Percentage breakdown by category',
      height: 240,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  _incomePieTouched = -1;
                } else {
                  _incomePieTouched =
                      response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 38,
          sections: List.generate(_incomePieData.length, (i) {
            final isTouched = i == _incomePieTouched;
            final d = _incomePieData[i];
            return PieChartSectionData(
              color: d.color,
              value: d.value,
              title: '${d.value.toInt()}%',
              radius: isTouched ? 68 : 58,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
      legend: _incomePieData
          .map((d) => _LegendItem(color: d.color, label: d.label))
          .toList(),
    );
  }

  // ── Chart: Expense Per Flat ────────────────────────────────────────────────

  Widget _buildExpensePerFlatChart() {
    return _ChartCard(
      title: 'Expense Cost Per Flat – Month Wise',
      subtitle: 'X-axis: Cost (₹)  •  Y-axis: Month',
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 2000,
          maxX: 4200,
          minY: 0,
          maxY: 11,
          titlesData: _expenseCostXAxisMonthYAxisTitles(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(_expensePerFlat[i], i.toDouble()),
              ),
              isCurved: true,
              color: const Color(0xFFE57373),
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE57373).withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFFE57373), label: 'Expense / Flat'),
      ],
    );
  }

  // ── Chart: Income Per Flat ─────────────────────────────────────────────────

  Widget _buildIncomePerFlatChart() {
    return _ChartCard(
      title: 'Income Per Flat – Month Wise',
      subtitle: 'Average income collected per flat  ( ₹ )',
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 3000,
          maxY: 5800,
          titlesData: _lineTitles(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _incomePerFlat[i]),
              ),
              isCurved: true,
              color: const Color(0xFF0F8F82),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0F8F82).withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF0F8F82), label: 'Income / Flat'),
      ],
    );
  }

  FlTitlesData _lineTitles() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (v, _) => Text(
            '${v.toInt()}',
            style: const TextStyle(fontSize: 9, color: Colors.black45),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= _months.length) return const SizedBox();
            return Text(
              _months[i],
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlTitlesData _expenseCostXAxisMonthYAxisTitles() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 36,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= _months.length) return const SizedBox();
            return Text(
              _months[i],
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 400,
          reservedSize: 30,
          getTitlesWidget: (v, _) => Text(
            '₹${v.toInt()}',
            style: const TextStyle(fontSize: 9, color: Colors.black45),
          ),
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildReportDashboardTab() {
    final isMobile = _isMobile(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _brandTextColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Overview of income, expense, and flat-wise trends',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _buildGraphsSection(isMobile),
          const SizedBox(height: 20),
          _buildBudgetVsActualLineChart(),
        ],
      ),
    );
  }

  // ── Tab: Balance Sheet ─────────────────────────────────────────────────────

  Widget _buildBalanceSheetTab() {
    return _ReportSheetScaffold(
      title: 'Balance Sheet',
      subtitle: 'As on 31st March 2026',
      icon: Icons.account_balance_rounded,
      summaryCards: [
        _SummaryCard(
          label: 'Total Assets',
          value: '₹18,27,500',
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Total Liabilities',
          value: '₹18,27,500',
          color: const Color(0xFF124B45),
        ),
        _SummaryCard(
          label: 'Reserve Fund',
          value: '₹8,50,000',
          color: const Color(0xFF26C6AD),
        ),
      ],
      headers: const ['Particulars', 'Current Year (₹)', 'Previous Year (₹)'],
      rows: _balanceSheetRows,
      sectionRows: const {0, 6},
      statusCol: -1,
    );
  }

  // ── Tab: Tax Sheet ─────────────────────────────────────────────────────────

  Widget _buildTaxSheetTab() {
    return _ReportSheetScaffold(
      title: 'Tax Sheet',
      subtitle: 'Financial Year 2025-26',
      icon: Icons.receipt_long_rounded,
      summaryCards: [
        _SummaryCard(
          label: 'Gross Income',
          value: '₹20,97,000',
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Taxable Income',
          value: '₹2,97,000',
          color: const Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Total Tax',
          value: '₹29,700',
          color: const Color(0xFFE57373),
        ),
      ],
      headers: _taxSheetRows[0].cast<String>(),
      rows: _taxSheetRows.sublist(1),
      sectionRows: const {},
      statusCol: -1,
    );
  }

  // ── Tab: Payment Collection & Defaulters ──────────────────────────────────

  Widget _buildPaymentCollectionTab() {
    return _ReportSheetScaffold(
      title: 'Payment Wise Collection Report',
      subtitle: 'April 2026 – All units',
      icon: Icons.payments_rounded,
      summaryCards: [
        _SummaryCard(
          label: 'Total Collected',
          value: '₹84,000',
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Total Due',
          value: '₹96,000',
          color: const Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Collection Ratio',
          value: '87.5%',
          color: const Color(0xFFE57373),
        ),
      ],
      headers: _paymentCollectionRows[0].cast<String>(),
      rows: _paymentCollectionRows.sublist(1),
      sectionRows: const {},
      statusCol: 5,
    );
  }

  Widget _buildDefaulterTab() {
    return _ReportSheetScaffold(
      title: 'Defaulter Report',
      subtitle: 'April 2026 – Pending owners list',
      icon: Icons.warning_amber_rounded,
      summaryCards: const [
        _SummaryCard(
          label: 'Defaulters',
          value: '4 Units',
          color: Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Amount To Be Collected',
          value: '₹38,000',
          color: Color(0xFFE57373),
        ),
        _SummaryCard(
          label: 'Late Fee Expected',
          value: '₹3,800',
          color: Color(0xFF124B45),
        ),
      ],
      headers: _defaulterRows[0].cast<String>(),
      rows: _defaulterRows.sublist(1),
      sectionRows: const {},
      statusCol: -1,
    );
  }

  Widget _buildPenaltiesTab() {
    return _ReportSheetScaffold(
      title: 'Penalties Report',
      subtitle: 'April 2026 – Penalty audit',
      icon: Icons.gavel_rounded,
      summaryCards: const [
        _SummaryCard(
          label: 'Open Penalties',
          value: '2',
          color: Color(0xFFFFB300),
        ),
        _SummaryCard(
          label: 'Collected Penalties',
          value: '₹2,200',
          color: Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Pending Penalties',
          value: '₹1,250',
          color: Color(0xFFE57373),
        ),
      ],
      headers: _penaltiesRows[0].cast<String>(),
      rows: _penaltiesRows.sublist(1),
      sectionRows: const {},
      statusCol: 4,
    );
  }

  // ── Tab: Budget vs Actual ──────────────────────────────────────────────────

  Widget _buildBudgetVsActualTab() {
    return _ReportSheetScaffold(
      title: 'Budget vs Actual Report',
      subtitle: 'FY 2025-26 – Expense comparison',
      icon: Icons.compare_arrows_rounded,
      summaryCards: [
        _SummaryCard(
          label: 'Total Budget',
          value: '₹5,40,000',
          color: const Color(0xFF0F8F82),
        ),
        _SummaryCard(
          label: 'Total Actual',
          value: '₹5,57,500',
          color: const Color(0xFFE57373),
        ),
        _SummaryCard(
          label: 'Variance',
          value: '-₹17,500',
          color: const Color(0xFFFFB300),
        ),
      ],
      headers: _budgetVsActualRows[0].cast<String>(),
      rows: _budgetVsActualRows.sublist(1),
      sectionRows: const {},
      statusCol: 4,
      budgetChart: _buildBudgetVsActualLineChart(),
    );
  }

  // ── Chart: Budget vs Actual ────────────────────────────────────────────────

  Widget _buildBudgetVsActualLineChart() {
    return _ChartCard(
      title: 'Budget vs Actual – Month Wise',
      subtitle: 'Trend comparison  ( ₹ in thousands )',
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 60,
          maxY: 190,
          titlesData: _lineTitles(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _budgetData[i]),
              ),
              isCurved: true,
              color: const Color(0xFF0F8F82),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              dashArray: [6, 3],
            ),
            LineChartBarData(
              spots: List.generate(
                12,
                (i) => FlSpot(i.toDouble(), _actualData[i]),
              ),
              isCurved: true,
              color: const Color(0xFFE57373),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
      legend: const [
        _LegendItem(color: Color(0xFF0F8F82), label: 'Budget'),
        _LegendItem(color: Color(0xFFE57373), label: 'Actual'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color, {this.note});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? note;
}

class _SummaryCard {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
}

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

class _ReportOptionItem {
  const _ReportOptionItem(this.title, this.icon, this.tabIndex);
  final String title;
  final IconData icon;
  final int tabIndex;
}

// ── Chart Card wrapper ─────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.height,
    required this.child,
    this.legend = const [],
  });

  final String title;
  final String subtitle;
  final double height;
  final Widget child;
  final List<_LegendItem> legend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF124B45),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: legend
                  .map(
                    (l) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: l.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Report Sheet Scaffold ──────────────────────────────────────────────────

class _ReportSheetScaffold extends StatelessWidget {
  const _ReportSheetScaffold({
    this.topSection,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.summaryCards,
    required this.headers,
    required this.rows,
    required this.sectionRows,
    required this.statusCol,
    this.budgetChart,
  });

  final Widget? topSection;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_SummaryCard> summaryCards;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Set<int> sectionRows;
  final int statusCol; // column index to apply status colour, or -1
  final Widget? budgetChart;

  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topSection != null) ...[topSection!, const SizedBox(height: 20)],
          _buildTitleRow(),
          const SizedBox(height: 16),
          _buildSummaryRow(),
          const SizedBox(height: 20),
          if (budgetChart != null) ...[
            budgetChart!,
            const SizedBox(height: 20),
          ],
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _brandColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _brandColor, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _brandTextColor,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandColor,
            side: const BorderSide(color: _brandColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: summaryCards
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.color.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: c.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F0EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
          columnWidths: _columnWidths(),
          children: [
            // Header row
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFE8F7F5)),
              children: headers
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _brandTextColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Data rows
            ...List.generate(rows.length, (i) {
              final row = rows[i];
              final isSection = sectionRows.contains(i);
              return TableRow(
                decoration: BoxDecoration(
                  color: isSection
                      ? const Color(0xFFF0FAF9)
                      : (i.isOdd ? Colors.white : const Color(0xFFFAFAFA)),
                ),
                children: List.generate(row.length, (j) {
                  final cell = row[j].toString();
                  if (isSection && j == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        cell,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _brandTextColor,
                        ),
                      ),
                    );
                  }
                  if (j == statusCol) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: _StatusChip(cell),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      cell,
                      style: TextStyle(
                        fontSize: 12,
                        color: j == 0 ? Colors.black87 : Colors.black54,
                        fontWeight: j == 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _columnWidths() {
    if (headers.length <= 2) return {};
    return {0: const FlexColumnWidth(2)};
  }
}

// ── Status Chip ────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
      case 'under budget':
      case 'on target':
      case 'closed':
        color = const Color(0xFF0F8F82);
        break;
      case 'partial':
      case 'over budget':
      case 'open':
        color = const Color(0xFFE57373);
        break;
      case 'defaulter':
        color = const Color(0xFFFFB300);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
