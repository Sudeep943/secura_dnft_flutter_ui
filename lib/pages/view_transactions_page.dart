import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/receipt_downloader.dart';

class ViewTransactionsPage extends StatefulWidget {
  const ViewTransactionsPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<ViewTransactionsPage> createState() => _ViewTransactionsPageState();
}

class _ViewTransactionsPageState extends State<ViewTransactionsPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableHorizontalController = ScrollController();
  final ScrollController _tableVerticalController = ScrollController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];
  Timer? _searchDebounce;
  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  DateTime? _fromDate;
  DateTime? _toDate;
  Set<String> _selectedTypes = <String>{};
  Set<String> _selectedCauses = <String>{};
  Set<String> _selectedTenders = <String>{};
  Set<String> _selectedDoneBy = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _progressTimer?.cancel();
    _searchController.dispose();
    _tableHorizontalController.dispose();
    _tableVerticalController.dispose();
    super.dispose();
  }

  bool _isSuccessResponse(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['messageCode']?.toString().trim().toUpperCase() ?? '';
    return code.startsWith('SUCC') || code.contains('SUCCESS');
  }

  void _startProgressTimer() {
    _loadingProgress = 0.0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_loadingProgress < 0.9) {
          _loadingProgress += 0.08;
        }
      });
    });
  }

  Future<void> _fetchTransactions({String? transactionId}) async {
    final header = ApiService.userHeader;
    if (header == null || header.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Session expired. Please login again.';
      });
      _progressTimer?.cancel();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    _startProgressTimer();

    final requestBody = {
      'genericHeader': Map<String, dynamic>.from(header),
      'transactionId': (transactionId == null || transactionId.trim().isEmpty)
          ? null
          : transactionId.trim(),
    };

    try {
      final response = await ApiService.getTransactions(requestBody);
      if (!mounted) return;

      _progressTimer?.cancel();
      if (!_isSuccessResponse(response)) {
        setState(() {
          _loading = false;
          _error =
              response?['message']?.toString() ??
              'Unable to fetch transactions.';
          _loadingProgress = 0.0;
        });
        return;
      }

      final rawList = response?['transactionList'];
      final list = rawList is List
          ? rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _loading = false;
        _transactions = list;
        _loadingProgress = 0.0;
      });
    } catch (_) {
      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() {
        _loading = false;
        _error = 'Unable to fetch transactions right now.';
        _loadingProgress = 0.0;
      });
    }
  }

  DateTime? _parseTxnDate(Map<String, dynamic> txn) {
    final raw = txn['trnsDate']?.toString() ?? '';
    return DateTime.tryParse(raw);
  }

  String _fmtDate(Map<String, dynamic> txn) {
    final dt = _parseTxnDate(txn);
    if (dt == null) return '--';
    final monthNames = [
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
    final date =
        '${dt.day.toString().padLeft(2, '0')}-${monthNames[dt.month - 1]}-${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  double _toAmount(dynamic value) {
    return double.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((txn) {
      final dt = _parseTxnDate(txn);
      if (_fromDate != null && dt != null) {
        final from = DateTime(
          _fromDate!.year,
          _fromDate!.month,
          _fromDate!.day,
        );
        final current = DateTime(dt.year, dt.month, dt.day);
        if (current.isBefore(from)) return false;
      }
      if (_toDate != null && dt != null) {
        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
        final current = DateTime(dt.year, dt.month, dt.day);
        if (current.isAfter(to)) return false;
      }

      final type = (txn['trnsType']?.toString() ?? '').trim();
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(type)) {
        return false;
      }

      final cause = (txn['cause']?.toString() ?? '').trim();
      if (_selectedCauses.isNotEmpty && !_selectedCauses.contains(cause)) {
        return false;
      }

      final doneBy = (txn['trnsBy']?.toString() ?? '').trim();
      if (_selectedDoneBy.isNotEmpty && !_selectedDoneBy.contains(doneBy)) {
        return false;
      }

      if (_selectedTenders.isNotEmpty) {
        final tenders = txn['trnsTender'];
        final tenderNames = tenders is List
            ? tenders
                  .whereType<Map>()
                  .map(
                    (t) =>
                        (t['tenderName']?.toString().trim().toUpperCase() ??
                        ''),
                  )
                  .toSet()
            : <String>{};

        if (tenderNames.intersection(_selectedTenders).isEmpty) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get _totalCredit {
    return _filteredTransactions
        .where(
          (txn) =>
              (txn['trnsType']?.toString().trim().toUpperCase() ?? '') ==
              'CREDIT',
        )
        .fold<double>(0, (sum, txn) => sum + _toAmount(txn['trnsAmt']));
  }

  double get _totalDebit {
    return _filteredTransactions
        .where(
          (txn) =>
              (txn['trnsType']?.toString().trim().toUpperCase() ?? '') ==
              'DEBIT',
        )
        .fold<double>(0, (sum, txn) => sum + _toAmount(txn['trnsAmt']));
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  List<String> get _typeOptions {
    return _transactions
        .map((txn) => (txn['trnsType']?.toString() ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _causeOptions {
    return _transactions
        .map((txn) => (txn['cause']?.toString() ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _doneByOptions {
    return _transactions
        .map((txn) => (txn['trnsBy']?.toString() ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _tenderOptions {
    final values = <String>{};
    for (final txn in _transactions) {
      final tenders = txn['trnsTender'];
      if (tenders is! List) continue;
      for (final t in tenders.whereType<Map>()) {
        final name = (t['tenderName']?.toString().trim().toUpperCase() ?? '');
        if (name.isNotEmpty) {
          values.add(name);
        }
      }
    }
    final list = values.toList()..sort();
    return list;
  }

  String _dateButtonLabel(String prefix, DateTime? date) {
    if (date == null) {
      return prefix;
    }
    return '${date.day}-${date.month}-${date.year}';
  }

  Future<void> _openMultiSelectPicker({
    required BuildContext context,
    required String title,
    required List<String> options,
    required Set<String> selected,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (popupContext) {
        final local = Set<String>.from(selected);
        return StatefulBuilder(
          builder: (popupContext, setPopupState) {
            return AlertDialog(
              title: Text('Select $title'),
              content: SizedBox(
                width: 360,
                child: options.isEmpty
                    ? const Text('No options available')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (_, index) {
                          final option = options[index];
                          final checked = local.contains(option);
                          return CheckboxListTile(
                            value: checked,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(option),
                            onChanged: (value) {
                              setPopupState(() {
                                if (value == true) {
                                  local.add(option);
                                } else {
                                  local.remove(option);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setPopupState(local.clear);
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(popupContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    selected
                      ..clear()
                      ..addAll(local);
                    Navigator.of(popupContext).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownSelectorField({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required VoidCallback onTap,
  }) {
    final display = selected.isEmpty ? 'Select $title' : selected.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected.isEmpty ? Colors.black45 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    var localFrom = _fromDate;
    var localTo = _toDate;
    var localTypes = Set<String>.from(_selectedTypes);
    var localCauses = Set<String>.from(_selectedCauses);
    var localTenders = Set<String>.from(_selectedTenders);
    var localDoneBy = Set<String>.from(_selectedDoneBy);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Filters'),
              content: SizedBox(
                width: 680,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: localFrom ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2101),
                                );
                                if (picked == null) return;
                                setDialogState(() => localFrom = picked);
                              },
                              icon: const Icon(Icons.calendar_today_rounded),
                              label: Text(
                                _dateButtonLabel('From Date', localFrom),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: localTo ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2101),
                                );
                                if (picked == null) return;
                                setDialogState(() => localTo = picked);
                              },
                              icon: const Icon(Icons.calendar_today_rounded),
                              label: Text(_dateButtonLabel('To Date', localTo)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDropdownSelectorField(
                        title: 'Transaction Type',
                        options: _typeOptions,
                        selected: localTypes,
                        onTap: () async {
                          await _openMultiSelectPicker(
                            context: dialogContext,
                            title: 'Transaction Type',
                            options: _typeOptions,
                            selected: localTypes,
                          );
                          setDialogState(() {
                            localTypes = Set<String>.from(localTypes);
                          });
                        },
                      ),
                      _buildDropdownSelectorField(
                        title: 'Cause',
                        options: _causeOptions,
                        selected: localCauses,
                        onTap: () async {
                          await _openMultiSelectPicker(
                            context: dialogContext,
                            title: 'Cause',
                            options: _causeOptions,
                            selected: localCauses,
                          );
                          setDialogState(() {
                            localCauses = Set<String>.from(localCauses);
                          });
                        },
                      ),
                      _buildDropdownSelectorField(
                        title: 'Tenders',
                        options: _tenderOptions,
                        selected: localTenders,
                        onTap: () async {
                          await _openMultiSelectPicker(
                            context: dialogContext,
                            title: 'Tenders',
                            options: _tenderOptions,
                            selected: localTenders,
                          );
                          setDialogState(() {
                            localTenders = Set<String>.from(localTenders);
                          });
                        },
                      ),
                      _buildDropdownSelectorField(
                        title: 'Done By',
                        options: _doneByOptions,
                        selected: localDoneBy,
                        onTap: () async {
                          await _openMultiSelectPicker(
                            context: dialogContext,
                            title: 'Done By',
                            options: _doneByOptions,
                            selected: localDoneBy,
                          );
                          setDialogState(() {
                            localDoneBy = Set<String>.from(localDoneBy);
                          });
                        },
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
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                      _selectedTypes.clear();
                      _selectedCauses.clear();
                      _selectedTenders.clear();
                      _selectedDoneBy.clear();
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Reset'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _fromDate = localFrom;
                      _toDate = localTo;
                      _selectedTypes = localTypes;
                      _selectedCauses = localCauses;
                      _selectedTenders = localTenders;
                      _selectedDoneBy = localDoneBy;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTenderMetaData(Map<String, dynamic> txn) async {
    final details = txn['bankInstrumentTenderDetails'];
    final list = details is List
        ? details
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tender Meta Data'),
          content: SizedBox(
            width: 560,
            child: list.isEmpty
                ? const Text(
                    'No tender metadata available for this transaction.',
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: list.asMap().entries.map((entry) {
                        final data = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5FAF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD9E8E4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: data.entries
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${item.key}: ${item.value ?? '--'}',
                                      style: const TextStyle(height: 1.3),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadReceipt(Map<String, dynamic> txn) async {
    final receiptNumber = (txn['receiptNumber']?.toString().trim() ?? '');
    if (receiptNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No receipt number found for this transaction.'),
        ),
      );
      return;
    }

    final genericHeader = ApiService.userHeader;
    if (genericHeader == null || genericHeader.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    try {
      final response = await ApiService.generateReceipt({
        'genericHeader': Map<String, dynamic>.from(genericHeader),
        'receiptNumber': receiptNumber,
      });

      final messageCode =
          (response?['messageCode']?.toString().trim().toUpperCase() ?? '');
      if (!messageCode.startsWith('SUCC')) {
        throw Exception('Receipt generation failed');
      }

      final receipt =
          (response?['receipt']?.toString().trim() ??
          (response?['data'] is Map
              ? (response?['data']['receipt']?.toString().trim() ?? '')
              : ''));
      if (receipt.isEmpty || receipt.toLowerCase() == 'null') {
        throw Exception('Receipt data missing');
      }

      final fileName =
          'receipt_${receiptNumber.isNotEmpty ? receiptNumber : DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloaded = await downloadBase64Receipt(
        base64Data: receipt,
        fileName: fileName,
      );
      if (!mounted) return;
      if (!downloaded) {
        throw Exception('Download failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt downloaded successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download receipt.')),
      );
    }
  }

  Widget _buildTenderCell(Map<String, dynamic> txn) {
    final tenders = txn['trnsTender'];
    final list = tenders is List
        ? tenders
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    if (list.isEmpty) {
      return const SelectableText('--');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: list
          .map(
            (t) => SelectableText(
              '${t['tenderName'] ?? '--'}: ${t['amountPaid'] ?? '0'}',
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 12.5, height: 1.3),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTotalsBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7F4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFE4DB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Credit',
                  style: TextStyle(
                    color: _brandTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(_totalCredit),
                  style: const TextStyle(
                    color: _brandColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2D1CA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Debit',
                  style: TextStyle(
                    color: Color(0xFF8B1E1E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(_totalDebit),
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    final rows = _filteredTransactions;
    if (rows.isEmpty) {
      return const Center(
        child: Text('No transactions found for current selection.'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEAE7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Scrollbar(
          controller: _tableHorizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _tableHorizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 3000,
              child: Scrollbar(
                controller: _tableVerticalController,
                thumbVisibility: true,
                trackVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  controller: _tableVerticalController,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFEAF5F2),
                    ),
                    dataRowMinHeight: 55,
                    dataRowMaxHeight: 65,
                    columnSpacing: 22,
                    horizontalMargin: 14,
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: 140,
                          child: const Text(
                            'Transaction ID',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 190,
                          child: const Text(
                            'Transaction Date',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 220,
                          child: const Text(
                            'Done By',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 250,
                          child: const Text(
                            'Tenders',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 130,
                          child: const Text(
                            'Type',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 220,
                          child: const Text(
                            'Bank Account',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: const Text(
                            'Amount',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 170,
                          child: const Text(
                            'Payment ID',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 140,
                          child: const Text(
                            'Status',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 170,
                          child: const Text(
                            'Cause',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 200,
                          child: const Text(
                            'Tender Details',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 200,
                          child: const Text(
                            'Receipt',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    rows: rows.map((txn) {
                      final receiptNo =
                          (txn['receiptNumber']?.toString().trim() ?? '');
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  txn['trnscId']?.toString() ?? '--',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 190,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  _fmtDate(txn),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              width: 220,
                              height: double.infinity,
                              alignment: Alignment.center,
                              child: SelectableText(
                                txn['trnsBy']?.toString() ?? '--',
                                maxLines: 3,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 250,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: _buildTenderCell(txn),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 130,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  txn['trnsType']?.toString() ?? '--',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              width: 220,
                              height: double.infinity,
                              alignment: Alignment.center,
                              child: SelectableText(
                                txn['trnsBnkAccnt']?.toString() ?? '--',
                                maxLines: 3,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  txn['trnsAmt']?.toString() ?? '0',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 170,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  txn['pymntId']?.toString() ?? '--',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 140,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  txn['trnsStatus']?.toString() ?? '--',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 170,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: SelectableText(
                                  txn['cause']?.toString() ?? '--',
                                  maxLines: 3,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: OutlinedButton(
                                  onPressed: () => _showTenderMetaData(txn),
                                  child: const Text('View Tender Meta Data'),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              height: double.infinity,
                              child: Container(
                                alignment: Alignment.center,
                                child: receiptNo.isEmpty
                                    ? const SelectableText(
                                        '--',
                                        textAlign: TextAlign.center,
                                      )
                                    : FilledButton(
                                        onPressed: () => _downloadReceipt(txn),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _brandColor,
                                        ),
                                        child: const Text('Download Receipt'),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.embedded && widget.onBack != null) ...[
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: _brandColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
            ],
            const Expanded(
              child: Text(
                'View Transactions',
                style: TextStyle(
                  color: _brandTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _showFilterDialog,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filter'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Transaction ID',
                  hintText: 'Type transaction id',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _fetchTransactions(
                      transactionId: _searchController.text,
                    ),
                    icon: const Icon(Icons.search),
                  ),
                ),
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 500),
                    () {
                      _fetchTransactions(transactionId: value);
                    },
                  );
                },
                onSubmitted: (value) {
                  _fetchTransactions(transactionId: value);
                },
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _fetchTransactions(transactionId: null);
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: _loadingProgress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(
              _loadingProgress > 0.95 ? Colors.green : const Color(0xFF0F8F82),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0F8F82),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(_loadingProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF124B45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Loading transactions...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  _fetchTransactions(transactionId: _searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTotalsBar(),
        const SizedBox(height: 14),
        Expanded(child: _buildTable()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          Expanded(child: _buildBody()),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        title: const Text('View Transactions'),
      ),
      body: content,
    );
  }
}
