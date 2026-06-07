import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String? _hoveredDiscFinKey;
  final Set<String> _deTagInProgressKeys = <String>{};
  final Set<String> _expandedPaymentIds = <String>{};

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

  String _formatUtcBoundaryDate(DateTime date, {required bool endOfDay}) {
    final utcDate = endOfDay
        ? DateTime.utc(date.year, date.month, date.day, 23, 59, 59)
        : DateTime.utc(date.year, date.month, date.day);
    return utcDate.toIso8601String();
  }

  Future<void> _showErrorModal(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unable to Update'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deTagDiscFinFromPayment({
    required String paymentId,
    required String discFinType,
  }) async {
    final normalizedPaymentId = paymentId.trim();
    final normalizedType = discFinType.trim().toUpperCase();
    if (normalizedPaymentId.isEmpty || normalizedType.isEmpty) {
      return;
    }

    final key = '$normalizedPaymentId:$normalizedType';
    if (_deTagInProgressKeys.contains(key)) {
      return;
    }

    final header = _buildHeader();
    if (header == null) {
      await _showErrorModal('Session expired. Please log in again.');
      return;
    }

    setState(() {
      _deTagInProgressKeys.add(key);
    });

    try {
      final response = await ApiService.deTagDiscFinFromPayment({
        'genericHeader': header,
        'paymentId': normalizedPaymentId,
        'discFinType': normalizedType,
      });

      final messageCode =
          response?['messageCode']?.toString().trim().toUpperCase() ?? '';
      final message =
          response?['message']?.toString().trim() ??
          'Unable to detach $normalizedType from payment.';

      if (messageCode.contains('SUC')) {
        await _loadPayments();
        return;
      }

      await _showErrorModal(message.isEmpty ? 'Request failed.' : message);
    } catch (_) {
      await _showErrorModal('Unable to update payment details right now.');
    } finally {
      if (mounted) {
        setState(() {
          _deTagInProgressKeys.remove(key);
        });
      }
    }
  }

  Widget _buildDetaggableDiscFinValue({
    required String paymentId,
    required String code,
    required String discFinType,
    required Map<String, dynamic> payment,
  }) {
    if (code == '--') {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _openTagDiscFinDialog(
            paymentId: paymentId,
            payment: payment,
            discFinType: discFinType,
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(discFinType == 'FINE' ? 'Add Fine' : 'Add Discount'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandColor,
            side: const BorderSide(color: _brandColor),
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    final hoverKey = '$paymentId:$discFinType';
    final inProgress = _deTagInProgressKeys.contains(hoverKey);
    final showAction = (_hoveredDiscFinKey == hoverKey) || inProgress;

    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hoveredDiscFinKey = hoverKey;
          });
        },
        onExit: (_) {
          setState(() {
            if (_hoveredDiscFinKey == hoverKey) {
              _hoveredDiscFinKey = null;
            }
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _onDiscFinCodeTapped(code),
              style: TextButton.styleFrom(
                foregroundColor: _brandColor,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                code,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showAction) ...[
              const SizedBox(width: 6),
              inProgress
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : InkWell(
                      onTap: () => _deTagDiscFinFromPayment(
                        paymentId: paymentId,
                        discFinType: discFinType,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  List<_DiscFinCycleOption> _buildDiscFinCycleOptions(
    Map<String, dynamic> payment,
  ) {
    final rawCycles = _parseJsonList(payment['paymentCollectionCycleList']);
    final cycles = rawCycles
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
        .toList();

    if (cycles.isEmpty) {
      final singleCycle = _formatValue(payment['paymentCollectionCycle']);
      if (singleCycle != '--') {
        cycles.add(singleCycle);
      }
    }

    return cycles
        .map((cycle) => _DiscFinCycleOption(cycle: cycle, label: cycle))
        .toList();
  }

  Future<void> _openTagDiscFinDialog({
    required String paymentId,
    required Map<String, dynamic> payment,
    required String discFinType,
  }) async {
    final header = _buildHeader();
    if (header == null) {
      await _showErrorModal('Session expired. Please log in again.');
      return;
    }

    final applied = await showDialog<_TaggedDiscFinApplied>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TagDiscFinDialog(
        initialKind: discFinType,
        kindLocked: true,
        availableCollectionCycles: _buildDiscFinCycleOptions(payment),
        onSubmit: (draft) async {
          final requestBody = <String, dynamic>{
            'genericHeader': header,
            'paymentId': paymentId,
            'discfinRequestData': {
              'discFnType': draft.kind,
              'dueDateAsStartDateFlag': draft.isFine
                  ? draft.dueDateAsStartDate
                  : false,
              'discFnStrtDt': _formatUtcBoundaryDate(
                draft.startDate,
                endOfDay: false,
              ),
              'discFnEndDt': _formatUtcBoundaryDate(
                draft.endDate,
                endOfDay: false,
              ),
              'discFnMode': draft.mode,
              'discFnValue': draft.value,
              'discFnCycleType': draft.isFine ? draft.calculationType : null,
              if (draft.isFine && draft.calculationType == 'CUMULATIVE')
                'discFnCumlatonCycle': draft.cumulationCycle,
              if (!draft.isFine)
                'discFinCycleDiscountList': draft.cycleDiscounts
                    .map(
                      (item) => {
                        'cycle': item.cycle,
                        'type': item.type == 'PERCENTAGE'
                            ? 'PERCENTAGE'
                            : 'FIXED_AMOUNT',
                        'value': item.value,
                      },
                    )
                    .toList(),
            },
          };

          try {
            final response = await ApiService.tagDiscFinFromPayment(
              requestBody,
            );
            final success =
                response != null &&
                (response['messageCode']?.toString().toUpperCase().contains(
                      'SUCC',
                    ) ??
                    false);
            final message =
                response?['message']?.toString() ??
                (success
                    ? 'Discount/Fine tagged successfully.'
                    : 'Request failed.');

            return _TaggedDiscFinSubmitResult(
              isSuccess: success,
              message: message,
              applied: success ? _TaggedDiscFinApplied(kind: draft.kind) : null,
            );
          } catch (_) {
            return const _TaggedDiscFinSubmitResult(
              isSuccess: false,
              message: 'Unable to tag the discount/fine right now.',
            );
          }
        },
      ),
    );

    if (!mounted || applied == null) {
      return;
    }

    setState(() {
      _expandedPaymentIds.add(paymentId);
    });
    await _loadPayments();
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
          key: ValueKey(paymentId),
          initiallyExpanded: _expandedPaymentIds.contains(paymentId),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedPaymentIds.add(paymentId);
              } else {
                _expandedPaymentIds.remove(paymentId);
              }
            });
          },
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
              child: _buildDetaggableDiscFinValue(
                paymentId: paymentId,
                code: discountCode,
                discFinType: 'DISCOUNT',
                payment: payment,
              ),
            ),
            _buildLabeledRow(
              label: 'FineCode',
              child: _buildDetaggableDiscFinValue(
                paymentId: paymentId,
                code: fineCode,
                discFinType: 'FINE',
                payment: payment,
              ),
            ),
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

class _DiscFinCycleOption {
  const _DiscFinCycleOption({required this.cycle, required this.label});

  final String cycle;
  final String label;
}

class _TagDiscFinCycleDiscount {
  const _TagDiscFinCycleDiscount({
    required this.cycle,
    required this.type,
    required this.value,
  });

  final String cycle;
  final String type;
  final String value;
}

class _TaggedDiscFinDraft {
  const _TaggedDiscFinDraft({
    required this.kind,
    required this.dueDateAsStartDate,
    required this.startDate,
    required this.endDate,
    required this.mode,
    required this.value,
    required this.calculationType,
    required this.cumulationCycle,
    required this.cycleDiscounts,
  });

  final String kind;
  final bool dueDateAsStartDate;
  final DateTime startDate;
  final DateTime endDate;
  final String mode;
  final String value;
  final String? calculationType;
  final String? cumulationCycle;
  final List<_TagDiscFinCycleDiscount> cycleDiscounts;

  bool get isFine => kind == 'FINE';
}

class _TaggedDiscFinApplied {
  const _TaggedDiscFinApplied({required this.kind});

  final String kind;
}

class _TaggedDiscFinSubmitResult {
  const _TaggedDiscFinSubmitResult({
    required this.isSuccess,
    required this.message,
    this.applied,
  });

  final bool isSuccess;
  final String message;
  final _TaggedDiscFinApplied? applied;
}

class _TagCycleDiscountInput {
  _TagCycleDiscountInput({required this.cycle, required this.label})
    : valueController = TextEditingController();

  final String cycle;
  final String label;
  final TextEditingController valueController;
  String type = 'AMOUNT';

  void dispose() {
    valueController.dispose();
  }
}

class _TagDiscFinDialog extends StatefulWidget {
  const _TagDiscFinDialog({
    required this.initialKind,
    required this.kindLocked,
    required this.availableCollectionCycles,
    required this.onSubmit,
  });

  final String initialKind;
  final bool kindLocked;
  final List<_DiscFinCycleOption> availableCollectionCycles;
  final Future<_TaggedDiscFinSubmitResult> Function(_TaggedDiscFinDraft draft)
  onSubmit;

  @override
  State<_TagDiscFinDialog> createState() => _TagDiscFinDialogState();
}

class _TagDiscFinDialogState extends State<_TagDiscFinDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final List<_TagCycleDiscountInput> _cycleDiscountInputs = [];

  late String _kind;
  String _mode = 'AMOUNT';
  String? _calculationType;
  String? _cumulationCycle;
  bool _dueDateAsStartDate = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _errorMessage;
  String _discountModeSelection = 'FIXED';

  static const List<_DiscFinCycleOption> _chargeTypeOptions = [
    _DiscFinCycleOption(cycle: 'AMOUNT', label: 'Amount'),
    _DiscFinCycleOption(cycle: 'PERCENTAGE', label: 'Percentage'),
  ];

  static const List<_DiscFinCycleOption> _fineTypeOptions = [
    _DiscFinCycleOption(cycle: 'SIMPLE', label: 'Simple'),
    _DiscFinCycleOption(cycle: 'CUMULATIVE', label: 'Cumulative'),
  ];

  static const List<_DiscFinCycleOption> _fineCycleOptions = [
    _DiscFinCycleOption(cycle: 'MONTHLY', label: 'Monthly'),
    _DiscFinCycleOption(cycle: 'QUARTERLY', label: 'Quarterly'),
    _DiscFinCycleOption(cycle: 'HALF_YEARLY', label: 'Half Yearly'),
    _DiscFinCycleOption(cycle: 'YEARLY', label: 'Yearly'),
  ];

  bool get _isFine => _kind == 'FINE';
  bool get _isDiscount => _kind == 'DISCOUNT';
  bool get _showDiscountModeRadio =>
      _isDiscount && widget.availableCollectionCycles.isNotEmpty;
  bool get _isCycleLevelDiscountMode =>
      _showDiscountModeRadio && _discountModeSelection == 'CYCLE_LEVEL';
  bool get _isBaseDiscountFieldLocked => _isCycleLevelDiscountMode;
  bool get _showCycleType => _isFine;
  bool get _showCumulationCycle => _isFine && _calculationType == 'CUMULATIVE';
  bool get _isStartDateInputEnabled => !(_isFine && _dueDateAsStartDate);

  bool get _hasDirectBaseDiscountValue {
    if (!_isDiscount) {
      return false;
    }
    final normalized = _normalizeNumericValue(_valueController.text);
    return normalized.isNotEmpty && double.tryParse(normalized) != null;
  }

  bool get _disableAddCycleDiscountButton {
    return _remainingCycleOptions.isEmpty || _hasDirectBaseDiscountValue;
  }

  List<_DiscFinCycleOption> get _remainingCycleOptions {
    final usedCycles = _cycleDiscountInputs.map((entry) => entry.cycle).toSet();
    return widget.availableCollectionCycles
        .where((entry) => !usedCycles.contains(entry.cycle))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _valueController.dispose();
    for (final row in _cycleDiscountInputs) {
      row.dispose();
    }
    super.dispose();
  }

  String _formatDisplayDate(DateTime date) {
    const monthNames = [
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

    final day = date.day.toString().padLeft(2, '0');
    return '$day-${monthNames[date.month - 1]}-${date.year}';
  }

  String _normalizeNumericValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) {
      return '';
    }

    final firstDot = cleaned.indexOf('.');
    if (firstDot < 0) {
      return cleaned;
    }

    final integerPart = cleaned.substring(0, firstDot + 1);
    final decimalPart = cleaned.substring(firstDot + 1).replaceAll('.', '');
    return '$integerPart$decimalPart';
  }

  InputDecoration _inputDecoration({required String label, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: _ViewUpdatePaymentsPageState._brandColor,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.4),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    if (!_isStartDateInputEnabled) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;
      _startDateController.text = _formatDisplayDate(picked);
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final firstDate = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _endDate = picked;
      _endDateController.text = _formatDisplayDate(picked);
    });
  }

  void _addCycleDiscountRow() async {
    final remaining = _remainingCycleOptions;
    if (remaining.isEmpty) {
      return;
    }

    final selectedCycle = await showDialog<_DiscFinCycleOption>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF9F6FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Collection Cycle'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in remaining)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(option.label),
                    onTap: () => Navigator.of(dialogContext).pop(option),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedCycle == null) {
      return;
    }

    setState(() {
      _cycleDiscountInputs.add(
        _TagCycleDiscountInput(
          cycle: selectedCycle.cycle,
          label: selectedCycle.label,
        ),
      );
    });
  }

  List<_TagDiscFinCycleDiscount> _buildCycleDiscountDraftRows() {
    return _cycleDiscountInputs
        .map(
          (row) => _TagDiscFinCycleDiscount(
            cycle: row.cycle,
            type: row.type,
            value: _normalizeNumericValue(row.valueController.text),
          ),
        )
        .where((row) => row.value.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final startDate = _startDate;
    final endDate = _endDate;
    if (startDate == null || endDate == null) {
      return;
    }

    if (endDate.isBefore(startDate)) {
      setState(() {
        _errorMessage = 'End date must be on or after the start date.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await widget.onSubmit(
      _TaggedDiscFinDraft(
        kind: _kind,
        dueDateAsStartDate: _dueDateAsStartDate,
        startDate: startDate,
        endDate: endDate,
        mode: _mode,
        value: _normalizeNumericValue(_valueController.text),
        calculationType: _isFine ? _calculationType : null,
        cumulationCycle: _isFine ? _cumulationCycle : null,
        cycleDiscounts: _isFine ? const [] : _buildCycleDiscountDraftRows(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(result.applied);
      return;
    }

    setState(() {
      _errorMessage = result.message;
    });
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _ViewUpdatePaymentsPageState._brandColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ViewUpdatePaymentsPageState._brandTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF5D7A76), height: 1.35),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isFine ? 'Add Fine' : 'Add Discount'),
          const SizedBox(height: 4),
          Text(
            _isFine
                ? 'Configure the fine with dates and value.'
                : 'Configure the discount with dates, value, and optional cycle-wise discounts.',
            style: const TextStyle(
              color: Color(0xFF5D7A76),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Fill Details',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _kind,
                        decoration: _inputDecoration(label: 'Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'DISCOUNT',
                            child: Text('Discount'),
                          ),
                          DropdownMenuItem(value: 'FINE', child: Text('Fine')),
                        ],
                        onChanged: widget.kindLocked
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _kind = value;
                                });
                              },
                        validator: (value) =>
                            value == null ? 'Select type' : null,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FBF9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD6ECE7)),
                        ),
                        child: CheckboxListTile(
                          value: _dueDateAsStartDate,
                          enabled: _isFine,
                          activeColor: _ViewUpdatePaymentsPageState._brandColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Is Due Date As Start Date'),
                          onChanged: _isFine
                              ? (value) {
                                  setState(() {
                                    _dueDateAsStartDate = value ?? false;
                                    if (_dueDateAsStartDate) {
                                      _startDate = null;
                                      _startDateController.clear();
                                    }
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateController,
                              enabled: _isStartDateInputEnabled,
                              readOnly: true,
                              decoration: _inputDecoration(
                                label: 'Start Date',
                                suffix: const Icon(
                                  Icons.calendar_today_rounded,
                                ),
                              ),
                              onTap: _isStartDateInputEnabled
                                  ? _pickStartDate
                                  : null,
                              validator: (_) => _startDate == null
                                  ? 'Start date is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDateController,
                              readOnly: true,
                              decoration: _inputDecoration(
                                label: 'End Date',
                                suffix: const Icon(
                                  Icons.calendar_today_rounded,
                                ),
                              ),
                              onTap: _pickEndDate,
                              validator: (_) => _endDate == null
                                  ? 'End date is required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (_showDiscountModeRadio) ...[
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FBF9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD6ECE7)),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text('Fixed Discount'),
                                value: 'FIXED',
                                groupValue: _discountModeSelection,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _discountModeSelection = value;
                                    for (final row in _cycleDiscountInputs) {
                                      row.dispose();
                                    }
                                    _cycleDiscountInputs.clear();
                                  });
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('Cycle Level Discount'),
                                value: 'CYCLE_LEVEL',
                                groupValue: _discountModeSelection,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _discountModeSelection = value;
                                    _valueController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _mode,
                              decoration: _inputDecoration(label: 'Mode'),
                              items: _chargeTypeOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option.cycle,
                                      child: Text(option.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isBaseDiscountFieldLocked
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _mode = value;
                                      });
                                    },
                              validator: (value) =>
                                  value == null ? 'Select mode' : null,
                            ),
                          ),
                          if (_showCycleType) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _calculationType,
                                decoration: _inputDecoration(
                                  label: 'Cycle Type',
                                ),
                                items: _fineTypeOptions
                                    .map(
                                      (option) => DropdownMenuItem<String>(
                                        value: option.cycle,
                                        child: Text(option.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _calculationType = value;
                                    if (_calculationType != 'CUMULATIVE') {
                                      _cumulationCycle = null;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_showCumulationCycle) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _cumulationCycle,
                          decoration: _inputDecoration(
                            label: 'Cummilation Cycle',
                          ),
                          items: _fineCycleOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.cycle,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _cumulationCycle = value;
                            });
                          },
                          validator: (value) {
                            if (!_showCumulationCycle) return null;
                            return value == null ? 'Select cycle' : null;
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _valueController,
                        enabled: !_isBaseDiscountFieldLocked,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: _inputDecoration(label: 'Value'),
                        validator: (value) {
                          if (_isBaseDiscountFieldLocked) {
                            return null;
                          }
                          final normalized = _normalizeNumericValue(
                            value ?? '',
                          );
                          final number = double.tryParse(normalized);
                          if (normalized.isEmpty ||
                              number == null ||
                              number <= 0) {
                            return 'Enter a valid value';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (_isDiscount && _isCycleLevelDiscountMode) ...[
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: 'Cycle-wise Discount',
                    subtitle:
                        'Add different discount values for specific collection cycles.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  _ViewUpdatePaymentsPageState._brandColor,
                              side: const BorderSide(color: Color(0xFFB8D8D1)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _disableAddCycleDiscountButton
                                ? null
                                : _addCycleDiscountRow,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Cycle Discount'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (
                          var index = 0;
                          index < _cycleDiscountInputs.length;
                          index++
                        )
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFDCEAE7),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _cycleDiscountInputs[index].label,
                                        style: const TextStyle(
                                          color: Color(0xFF124B45),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          final row = _cycleDiscountInputs
                                              .removeAt(index);
                                          row.dispose();
                                        });
                                      },
                                      tooltip: 'Delete row',
                                      color: const Color(0xFFB3261E),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue:
                                            _cycleDiscountInputs[index].type,
                                        decoration: _inputDecoration(
                                          label: 'Type',
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'AMOUNT',
                                            child: Text('Amount'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'PERCENTAGE',
                                            child: Text('Percentage'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _cycleDiscountInputs[index].type =
                                                value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _cycleDiscountInputs[index]
                                            .valueController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9.]'),
                                          ),
                                        ],
                                        decoration: _inputDecoration(
                                          label: 'Value',
                                        ),
                                        validator: (value) {
                                          final normalized =
                                              _normalizeNumericValue(
                                                value ?? '',
                                              );
                                          final number = double.tryParse(
                                            normalized,
                                          );
                                          if (normalized.isEmpty ||
                                              number == null ||
                                              number <= 0) {
                                            return 'Enter value';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1C8C5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF8B1E1E),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ViewUpdatePaymentsPageState._brandColor,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(_isFine ? 'Add Fine' : 'Add Discount'),
        ),
      ],
    );
  }
}
