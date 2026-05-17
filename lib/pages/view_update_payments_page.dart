import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ViewUpdatePaymentsPage extends StatefulWidget {
  const ViewUpdatePaymentsPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ViewUpdatePaymentsPage> createState() => _ViewUpdatePaymentsPageState();
}

class _ViewUpdatePaymentsPageState extends State<ViewUpdatePaymentsPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const double _detailLabelWidth = 230;
  static const double _detailColumnGap = 8;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _paymentList = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Map<String, dynamic>? _buildHeader() {
    final h = ApiService.userHeader;
    if (h == null || h.isEmpty) return null;
    return Map<String, dynamic>.from(h);
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final header = _buildHeader();
      if (header == null) {
        setState(() {
          _loading = false;
          _error = 'Session expired. Please log in again.';
        });
        return;
      }

      final response = await ApiService.getPayment({
        'genericHeader': header,
        'paymentId': '',
      });

      if (!mounted) return;

      final code = response?['messageCode']?.toString() ?? '';
      if (!code.toUpperCase().startsWith('SUCC')) {
        setState(() {
          _loading = false;
          _error =
              response?['message']?.toString() ?? 'Failed to load payments.';
        });
        return;
      }

      final raw = response?['paymentList'];
      final list = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _loading = false;
        _paymentList = list;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load payments right now.';
      });
    }
  }

  List<dynamic> _parseJsonList(dynamic value) {
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return const [];
  }

  String _formatValue(dynamic value) {
    if (value == null) return '--';
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return '--';
    return s.replaceAll('_', ' ');
  }

  String _formatIsoDate(String? isoDate) {
    if (isoDate == null ||
        isoDate.trim().isEmpty ||
        isoDate.toLowerCase() == 'null') {
      return '--';
    }

    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;

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
    return '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
  }

  List<String> _toDisplayList(dynamic rawList) {
    return _parseJsonList(
      rawList,
    ).map((item) => _formatValue(item)).where((item) => item != '--').toList();
  }

  Future<void> _showValueListModal(String title, List<String> values) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 360,
          child: values.isEmpty
              ? const Text('--')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: values.length,
                  separatorBuilder: (_, _) => const Divider(height: 10),
                  itemBuilder: (_, index) => Text(
                    values[index],
                    style: const TextStyle(
                      color: _brandTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractDiscFinItems(
    dynamic rawValue,
    String code,
  ) {
    final items = <Map<String, dynamic>>[];

    void addFrom(dynamic value) {
      if (value is List) {
        for (final item in value.whereType<Map>()) {
          items.add(Map<String, dynamic>.from(item));
        }
      } else if (value is Map) {
        items.add(Map<String, dynamic>.from(value));
      }
    }

    if (rawValue is Map) {
      addFrom(rawValue[code]);
      if (items.isEmpty && rawValue.isNotEmpty) {
        addFrom(rawValue.values.first);
      }
      return items;
    }

    addFrom(rawValue);
    return items;
  }

  Future<void> _onDiscFinCodeTapped(String code) async {
    final header = _buildHeader();
    if (header == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final response = await ApiService.getDiscfin({
        'genericHeader': header,
        'discFnId': code,
      });

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final msgCode = response?['messageCode']?.toString() ?? '';
      if (!msgCode.toUpperCase().startsWith('SUCC')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response?['message']?.toString() ??
                  'Failed to load discount details.',
            ),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
        return;
      }

      final rawList = response?['discFinList'];
      final discFinItems = _extractDiscFinItems(rawList, code);
      if (discFinItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No discount details found.')),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (_) =>
            _DiscFinDetailsDialog(discFnId: code, discFinItems: discFinItems),
      );
    } catch (_) {
      if (!mounted) return;
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load discount details.'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _detailLabelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: _detailColumnGap),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _brandTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _detailLabelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: _detailColumnGap),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAddedChargesSection(List<dynamic> charges) {
    if (charges.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8DDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Added Charges',
            style: TextStyle(
              color: _brandColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFB8DDD8))),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _brandTextColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _brandTextColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Value',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _brandTextColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Final Value',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _brandTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              ...charges.whereType<Map>().map((charge) {
                final c = Map<String, dynamic>.from(charge);
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        c['chargeName']?.toString() ?? '--',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _formatValue(c['chargeType']),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        c['value']?.toString() ?? '--',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        c['finalChargeValue']?.toString() ?? '--',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paymentId = payment['paymentId']?.toString() ?? '--';
    final paymentName = payment['paymentName']?.toString() ?? '--';
    final paymentType = payment['paymentType']?.toString() ?? '';
    final isMandatory = paymentType.toUpperCase() == 'MANDATORY';
    final typeColor = isMandatory ? _brandColor : const Color(0xFFCF8A2E);

    final addedCharges = _parseJsonList(payment['addedCharges']);
    final allowedPaymentModes = _parseJsonList(payment['allowedPaymentModes']);
    final applicableFor = _toDisplayList(payment['applicableFor']);
    final collectionCycles = _toDisplayList(
      payment['paymentCollectionCycleList'],
    );
    final discountCode = _formatValue(payment['discountCode']);
    final fineCode = _formatValue(payment['fineCode']);

    final maintainance =
        payment['maintainanceFee'] == true ||
        payment['maintainanceFee']?.toString().toLowerCase() == 'true';
    final eventPay =
        payment['eventPayment'] == true ||
        payment['eventPayment']?.toString().toLowerCase() == 'true';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8EDE9)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(12, 71, 64, 0.05),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payments_outlined, color: typeColor, size: 20),
          ),
          title: Text(
            paymentName,
            style: const TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            paymentId,
            style: TextStyle(
              color: typeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFE8F3F0)),
            const SizedBox(height: 14),
            _buildInfoRow(
              'Payment Amount',
              _formatValue(payment['paymentAmount']),
            ),
            _buildInfoRow('Payment Type', _formatValue(payment['paymentType'])),
            _buildInfoRow('Status', _formatValue(payment['status'])),
            _buildInfoRow(
              'Payment Capita',
              _formatValue(payment['paymentCapita']),
            ),
            _buildInfoRow(
              'Collection Mode',
              _formatValue(payment['paymentCollectionMode']),
            ),
            _buildInfoRow(
              'Collection Cycle',
              collectionCycles.isEmpty
                  ? _formatValue(payment['paymentCollectionCycle'])
                  : collectionCycles.join(', '),
            ),
            _buildInfoRow('GST (%)', _formatValue(payment['gst'])),
            _buildInfoRow(
              'Bank Account ID',
              _formatValue(payment['bankAccountId']),
            ),
            _buildInfoRow('Created By', _formatValue(payment['creatUsrId'])),
            _buildInfoRow(
              'Collection Start Date',
              _formatIsoDate(payment['collectionStartDate']?.toString()),
            ),
            _buildInfoRow(
              'Collection End Date',
              _formatIsoDate(payment['collectionEndDate']?.toString()),
            ),
            if (maintainance) _buildInfoRow('Maintenance Fee', 'Yes'),
            if (eventPay && !maintainance)
              _buildInfoRow('Event Payment', 'Yes'),
            _buildLabeledRow(
              label: 'Allowed Payment Modes',
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: allowedPaymentModes.isEmpty
                    ? const Text(
                        '--',
                        style: TextStyle(color: _brandTextColor, fontSize: 13),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 6,
                          runSpacing: 4,
                          children: allowedPaymentModes.map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F3F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                m.toString().replaceAll('_', ' '),
                                style: const TextStyle(
                                  color: _brandColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
            _buildLabeledRow(
              label: 'Applicable For',
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: applicableFor.isEmpty
                    ? const Text(
                        '--',
                        style: TextStyle(color: _brandTextColor, fontSize: 13),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _showValueListModal(
                            'Applicable For',
                            applicableFor,
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: Text('View (${applicableFor.length})'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _brandColor,
                            side: const BorderSide(color: _brandColor),
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
              ),
            ),
            _buildLabeledRow(
              label: 'DiscountCode',
              child: discountCode == '--'
                  ? const Text(
                      '--',
                      style: TextStyle(
                        color: _brandTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _onDiscFinCodeTapped(discountCode),
                        style: TextButton.styleFrom(
                          foregroundColor: _brandColor,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          discountCode,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
            _buildInfoRow('FineCode', fineCode),
            if (addedCharges.isNotEmpty)
              _buildAddedChargesSection(addedCharges),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody(context);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F82),
        foregroundColor: Colors.white,
        title: const Text('View / Update Payments'),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB3261E)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadPayments,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_paymentList.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (widget.onBack != null) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _brandColor),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Expanded(
                      child: Text(
                        'View / Update Payments',
                        style: TextStyle(
                          color: _brandTextColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loadPayments,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'No payments found.',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: _brandColor),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Expanded(
                    child: Text(
                      'View / Update Payments',
                      style: TextStyle(
                        color: _brandTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadPayments,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_paymentList.length} payment${_paymentList.length == 1 ? '' : 's'} found. Tap a card to expand details.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 18),
              ..._paymentList.map(_buildPaymentCard),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscFinDetailsDialog extends StatefulWidget {
  const _DiscFinDetailsDialog({
    required this.discFnId,
    required this.discFinItems,
  });

  final String discFnId;
  final List<Map<String, dynamic>> discFinItems;

  @override
  State<_DiscFinDetailsDialog> createState() => _DiscFinDetailsDialogState();
}

class _DiscFinDetailsDialogState extends State<_DiscFinDetailsDialog>
    with SingleTickerProviderStateMixin {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  late final List<Map<String, dynamic>> _items;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.discFinItems);
    _items.sort((a, b) => _cycleRank(a).compareTo(_cycleRank(b)));
    _tabController = TabController(length: _items.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _cycleRank(Map<String, dynamic> item) {
    final raw = item['discFnCycleType']?.toString().trim().toUpperCase() ?? '';
    final normalized = raw.replaceAll(RegExp(r'[^A-Z]'), '');
    if (normalized == 'MONTHLY') return 0;
    if (normalized == 'QUARTERLY' || normalized == 'QUATERLY') return 1;
    if (normalized == 'HALFYEARLY') return 2;
    if (normalized == 'YEARLY') return 3;
    if (normalized == 'ONCE') return 4;
    return 5;
  }

  String _text(dynamic value) {
    if (value == null) return '--';
    final t = value.toString().trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return '--';
    return t.replaceAll('_', ' ');
  }

  String _tabLabel(Map<String, dynamic> item) {
    final cycle = _text(item['discFnCycleType']);
    return cycle;
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _brandTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemView(Map<String, dynamic> item) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD7EAE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Discount / Fine ID', _text(item['discFnId'])),
            _buildRow('Cycle Type', _text(item['discFnCycleType'])),
            _buildRow('Type', _text(item['discFnType'])),
            _buildRow('Mode', _text(item['discFnMode'])),
            _buildRow('Value', _text(item['discFinValue'])),
            _buildRow('Start Date', _text(item['discFnStrtDt'])),
            _buildRow('End Date', _text(item['discFnEndDt'])),
            _buildRow(
              'Due Date As Start Date',
              item['dueDateAsStartDateFlag'] == true ? 'Yes' : 'No',
            ),
            _buildRow('Cumulation Cycle', _text(item['discFnCumlatonCycle'])),
            _buildRow(
              'Minimum Payment Amount',
              _text(item['minimumPaymentAmount']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF7FCFA),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFD7EAE3)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
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
              Icons.discount_outlined,
              color: _brandColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Discount Details',
              style: TextStyle(
                color: _brandTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        height: 430,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7EAE3)),
              ),
              child: Text(
                'Discount Code: ${widget.discFnId}',
                style: const TextStyle(
                  color: _brandColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: _brandColor,
              unselectedLabelColor: _brandTextColor,
              indicatorColor: _brandColor,
              tabs: _items.map((item) => Tab(text: _tabLabel(item))).toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _items.map(_buildItemView).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
