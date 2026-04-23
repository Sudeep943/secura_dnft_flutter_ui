import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────────────────────────────────────

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

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _paymentList = [];

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

  // ── helpers ──────────────────────────────────────────────────────────────

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

  // ── sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 230,
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

  Widget _buildDiscFinChips(List<dynamic> discFins) {
    if (discFins.isEmpty) {
      return const Text(
        '--',
        style: TextStyle(color: _brandTextColor, fontSize: 13),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: discFins.whereType<Map>().map((entry) {
        final m = Map<String, dynamic>.from(entry);
        final type = m['DISTFIN_TYPE']?.toString() ?? '';
        final code = m['code']?.toString() ?? '';
        final isDiscount = type.toUpperCase() == 'DISCOUNT';
        final chipColor = isDiscount ? _brandColor : const Color(0xFFCF8A2E);

        return ActionChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          label: Text(
            code,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          backgroundColor: isDiscount
              ? const Color(0xFFE2F3F0)
              : const Color(0xFFFFF4E0),
          shape: StadiumBorder(
            side: BorderSide(color: chipColor.withValues(alpha: 0.4)),
          ),
          onPressed: () => _onDiscFinCodeTapped(code, type),
        );
      }).toList(),
    );
  }

  Future<void> _onDiscFinCodeTapped(String code, String type) async {
    final header = _buildHeader();
    if (header == null) return;

    // show loading overlay
    showDialog(
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
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      final msgCode = response?['messageCode']?.toString() ?? '';
      if (!msgCode.toUpperCase().startsWith('SUCC')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response?['message']?.toString() ??
                  'Failed to load discount/fine.',
            ),
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
        return;
      }

      final rawList = response?['discFinList'];
      if (rawList is! List || rawList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No discount/fine details found.')),
        );
        return;
      }

      final discFin = Map<String, dynamic>.from(rawList.first as Map);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) =>
            _DiscFinViewEditDialog(discFin: discFin, typeHint: type),
      );
    } catch (_) {
      if (!mounted) return;
      // try to dismiss loading if still open
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load discount/fine details.'),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
    }
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paymentId = payment['paymentId']?.toString() ?? '--';
    final paymentName = payment['paymentName']?.toString() ?? '--';
    final paymentType = payment['paymentType']?.toString() ?? '';
    final isMandatory = paymentType.toUpperCase() == 'MANDATORY';
    final typeColor = isMandatory ? _brandColor : const Color(0xFFCF8A2E);

    final addedCharges = _parseJsonList(payment['addedCharges']);
    final allowedPaymentModes = _parseJsonList(payment['allowedPaymentModes']);
    final applicableFor = _parseJsonList(payment['applicableFor']);
    final discFins = _parseJsonList(payment['discFin']);

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
          initiallyExpanded: false,
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
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

            // ── basic fields ─────────────────────────────────────────────
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
              _formatValue(payment['paymentCollectionCycle']),
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

            // ── allowed payment modes ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 200,
                    child: Text(
                      'Allowed Payment Modes',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: allowedPaymentModes.isEmpty
                        ? const Text(
                            '--',
                            style: TextStyle(
                              color: _brandTextColor,
                              fontSize: 13,
                            ),
                          )
                        : Wrap(
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
                ],
              ),
            ),

            // ── applicable for ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 200,
                    child: Text(
                      'Applicable For',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      applicableFor.isEmpty ? '--' : applicableFor.join(', '),
                      style: const TextStyle(
                        color: _brandTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── disc/fine chips ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 200,
                    child: Text(
                      'Discount / Fine',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDiscFinChips(discFins)),
                ],
              ),
            ),

            // ── added charges table ──────────────────────────────────────
            if (addedCharges.isNotEmpty)
              _buildAddedChargesSection(addedCharges),
          ],
        ),
      ),
    );
  }

  // ── page scaffold ─────────────────────────────────────────────────────────

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
      return const Center(child: Text('No payments found.'));
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
                '${_paymentList.length} payment${_paymentList.length == 1 ? '' : 's'} found. '
                'Tap a card to expand details. Click a discount/fine code chip to view or edit it.',
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

// ─────────────────────────────────────────────────────────────────────────────
// Discount / Fine view + edit dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DiscFinViewEditDialog extends StatefulWidget {
  const _DiscFinViewEditDialog({required this.discFin, required this.typeHint});

  final Map<String, dynamic> discFin;

  /// Expected: "DISCOUNT" or "FINE" — used as fallback when `discFnCycleType`
  /// is absent from the API response.
  final String typeHint;

  @override
  State<_DiscFinViewEditDialog> createState() => _DiscFinViewEditDialogState();
}

class _DiscFinViewEditDialogState extends State<_DiscFinViewEditDialog> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _valueController;

  bool _editing = false;
  bool _submitting = false;
  String? _errorMessage;

  // editable fields
  late String _discFnId;
  late String _kind; // DISCOUNT | FINE
  late String _discFnType; // SIMPLE | CUMULATIVE
  late String _discFnMode; // AMOUNT | PERCENTAGE
  late bool _dueDateAsStartDateFlag;
  late DateTime? _startDate;
  late DateTime? _endDate;
  String? _discFnCumlatonCycle;

  // metadata kept for the update request
  String? _aprmtId;
  String? _creatTs;
  String? _creatUsrId;

  bool get _isFine => _kind == 'FINE';
  bool get _showCumulationCycle => _isFine && _discFnType == 'CUMULATIVE';
  bool get _isStartDateInputEnabled => !(_isFine && _dueDateAsStartDateFlag);

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    final d = widget.discFin;

    _discFnId = d['discFnId']?.toString() ?? '';
    _aprmtId = d['aprmtId']?.toString();
    _creatTs = d['creatTs']?.toString();
    _creatUsrId = d['creatUsrId']?.toString();

    // Determine kind
    final cycleType = (d['discFnCycleType']?.toString().trim() ?? '')
        .toUpperCase();
    if (cycleType == 'FINE' || cycleType == 'DISCOUNT') {
      _kind = cycleType;
    } else {
      _kind = widget.typeHint.toUpperCase() == 'FINE' ? 'FINE' : 'DISCOUNT';
    }

    _discFnType =
        (d['discFnType']?.toString().trim().toUpperCase() == 'CUMULATIVE')
        ? 'CUMULATIVE'
        : 'SIMPLE';

    _discFnMode =
        (d['discFnMode']?.toString().trim().toUpperCase() == 'PERCENTAGE')
        ? 'PERCENTAGE'
        : 'AMOUNT';

    _dueDateAsStartDateFlag =
        d['dueDateAsStartDateFlag'] == true ||
        d['dueDateAsStartDateFlag']?.toString().toLowerCase() == 'true';

    final cumulRaw = d['discFnCumlatonCycle']?.toString().trim() ?? '';
    _discFnCumlatonCycle = cumulRaw.isEmpty || cumulRaw.toLowerCase() == 'null'
        ? null
        : cumulRaw;

    final startRaw = d['discFnStrtDt']?.toString().trim() ?? '';
    _startDate = startRaw.isEmpty ? null : DateTime.tryParse(startRaw);

    final endRaw = d['discFnEndDt']?.toString().trim() ?? '';
    _endDate = endRaw.isEmpty || endRaw.toLowerCase() == 'null'
        ? null
        : DateTime.tryParse(endRaw);

    _startDateController = TextEditingController(
      text: _startDate != null ? _formatDisplayDate(_startDate!) : '',
    );
    _endDateController = TextEditingController(
      text: _endDate != null ? _formatDisplayDate(_endDate!) : '',
    );
    _valueController = TextEditingController(
      text: d['discFinValue']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  // ── formatting helpers ────────────────────────────────────────────────────

  String _formatDisplayDate(DateTime dt) {
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

  String _toIso(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T00:00:00';

  // ── date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    if (!_editing || !_isStartDateInputEnabled) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _startDateController.text = _formatDisplayDate(picked);
    });
  }

  Future<void> _pickEndDate() async {
    if (!_editing) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _endDateController.text = _formatDisplayDate(picked);
    });
  }

  // ── decoration helper ─────────────────────────────────────────────────────

  InputDecoration _dec({required String label, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: _editing ? Colors.white : const Color(0xFFF5F5F5),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brandColor, width: 1.4),
      ),
    );
  }

  // ── submit ────────────────────────────────────────────────────────────────

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null && _isStartDateInputEnabled) {
      setState(() => _errorMessage = 'Start date is required.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final header = ApiService.userHeader;
      if (header == null) {
        setState(() {
          _submitting = false;
          _errorMessage = 'Session expired. Please log in again.';
        });
        return;
      }

      final now = DateTime.now().toIso8601String();
      final discfinEntity = <String, dynamic>{
        'aprmtId': _aprmtId,
        'discFnId': _discFnId,
        'discFnType': _discFnType,
        'dueDateAsStartDateFlag': _dueDateAsStartDateFlag,
        'discFnStrtDt': _startDate != null ? _toIso(_startDate!) : null,
        'discFnEndDt': _endDate != null ? _toIso(_endDate!) : null,
        'discFnMode': _discFnMode,
        'discFnCumlatonCycle': _showCumulationCycle
            ? _discFnCumlatonCycle
            : null,
        'discFnCycleType': _kind,
        'discFinValue': _valueController.text.trim(),
        'creatTs': _creatTs,
        'creatUsrId': _creatUsrId,
        'lstUpdtTs': now,
        'lstUpdtUsrId': header['userId']?.toString(),
      };

      final response = await ApiService.updateDiscfin({
        'genericHeader': Map<String, dynamic>.from(header),
        'discFinId': _discFnId,
        'discfinEntity': discfinEntity,
      });

      if (!mounted) return;

      final code = response?['messageCode']?.toString() ?? '';
      if (code.toUpperCase().startsWith('SUCC')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response?['message']?.toString() ?? 'Updated successfully.',
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _submitting = false;
          _errorMessage = response?['message']?.toString() ?? 'Update failed.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Unable to update right now.';
      });
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accentColor = _isFine ? const Color(0xFFCF8A2E) : _brandColor;

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _isFine ? 'Fine Details' : 'Discount Details',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: _brandTextColor,
              ),
            ),
          ),
          if (!_editing && !_submitting)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: accentColor),
            ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID — always read-only
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _discFnId,
                        style: const TextStyle(
                          color: _brandTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Kind — DISCOUNT / FINE
                DropdownButtonFormField<String>(
                  value: _kind,
                  decoration: _dec(label: 'Kind'),
                  items: const [
                    DropdownMenuItem(
                      value: 'DISCOUNT',
                      child: Text('Discount'),
                    ),
                    DropdownMenuItem(value: 'FINE', child: Text('Fine')),
                  ],
                  onChanged: _editing
                      ? (v) {
                          if (v == null) return;
                          setState(() {
                            _kind = v;
                            if (!_isFine) {
                              _dueDateAsStartDateFlag = false;
                              _discFnCumlatonCycle = null;
                            }
                          });
                        }
                      : null,
                ),

                const SizedBox(height: 14),

                // Calculation Type — SIMPLE / CUMULATIVE
                DropdownButtonFormField<String>(
                  value: _discFnType,
                  decoration: _dec(label: 'Calculation Type'),
                  items: const [
                    DropdownMenuItem(value: 'SIMPLE', child: Text('Simple')),
                    DropdownMenuItem(
                      value: 'CUMULATIVE',
                      child: Text('Cumulative'),
                    ),
                  ],
                  onChanged: _editing
                      ? (v) {
                          if (v == null) return;
                          setState(() {
                            _discFnType = v;
                            if (_discFnType != 'CUMULATIVE') {
                              _discFnCumlatonCycle = null;
                            }
                          });
                        }
                      : null,
                ),

                const SizedBox(height: 14),

                // Is Due Date As Start Date (only for Fine)
                if (_isFine) ...[
                  CheckboxListTile(
                    value: _dueDateAsStartDateFlag,
                    enabled: _editing,
                    activeColor: _brandColor,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Is Due Date As Start Date'),
                    onChanged: _editing
                        ? (v) {
                            setState(() {
                              _dueDateAsStartDateFlag = v ?? false;
                              if (_dueDateAsStartDateFlag) {
                                _startDate = null;
                                _startDateController.clear();
                              }
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],

                // Start / End dates
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        enabled: _editing && _isStartDateInputEnabled,
                        readOnly: true,
                        decoration: _dec(
                          label: 'Start Date',
                          suffix: (_editing && _isStartDateInputEnabled)
                              ? const Icon(Icons.calendar_today_rounded)
                              : null,
                        ),
                        onTap: (_editing && _isStartDateInputEnabled)
                            ? _pickStartDate
                            : null,
                        validator: (_) =>
                            (_startDate == null &&
                                _isStartDateInputEnabled &&
                                _editing)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        enabled: _editing,
                        readOnly: true,
                        decoration: _dec(
                          label: 'End Date',
                          suffix: _editing
                              ? const Icon(Icons.calendar_today_rounded)
                              : null,
                        ),
                        onTap: _editing ? _pickEndDate : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Mode
                DropdownButtonFormField<String>(
                  value: _discFnMode,
                  decoration: _dec(label: 'Mode'),
                  items: const [
                    DropdownMenuItem(value: 'AMOUNT', child: Text('Amount')),
                    DropdownMenuItem(
                      value: 'PERCENTAGE',
                      child: Text('Percentage'),
                    ),
                  ],
                  onChanged: _editing
                      ? (v) {
                          if (v != null) setState(() => _discFnMode = v);
                        }
                      : null,
                ),

                // Cumulation cycle (only when CUMULATIVE fine)
                if (_showCumulationCycle) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _discFnCumlatonCycle,
                    decoration: _dec(label: 'Cumulation Cycle'),
                    items: const [
                      DropdownMenuItem(
                        value: 'MONTHLY',
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(
                        value: 'QUARTERLY',
                        child: Text('Quarterly'),
                      ),
                      DropdownMenuItem(
                        value: 'HALF_YEARLY',
                        child: Text('Half Yearly'),
                      ),
                      DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                    ],
                    onChanged: _editing
                        ? (v) => setState(() => _discFnCumlatonCycle = v)
                        : null,
                    validator: (v) =>
                        (_editing && _showCumulationCycle && v == null)
                        ? 'Select cycle'
                        : null,
                  ),
                ],

                const SizedBox(height: 14),

                // Value
                TextFormField(
                  controller: _valueController,
                  enabled: _editing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: _dec(label: 'Value'),
                  validator: (v) {
                    if (!_editing) return null;
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0)
                      return 'Enter a valid positive value';
                    return null;
                  },
                ),

                // Error banner
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1C8C5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF8B1E1E),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (_editing)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accentColor),
            onPressed: _submitting ? null : _submitUpdate,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update'),
          ),
      ],
    );
  }
}
