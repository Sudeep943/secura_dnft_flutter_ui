import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/receipt_downloader.dart';

class CreateLedgerEntryPage extends StatefulWidget {
  const CreateLedgerEntryPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<CreateLedgerEntryPage> createState() => _CreateLedgerEntryPageState();
}

class _CreateLedgerEntryPageState extends State<CreateLedgerEntryPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form fields
  late TextEditingController _transactionDateController;
  late TextEditingController _ledgerNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  String _transactionType = 'DEBIT'; // DEBIT or CREDIT
  String? _selectedBankAccount;
  bool _receiptRequired = false;

  // Tenders list
  List<Map<String, String>> _tendersList = [];
  String? _selectedTender;
  late TextEditingController _tenderAmountController;

  // Causes list
  List<String> _causesList = ['MAINTENANCE', 'RENT', 'EVENT'];
  String? _selectedCause;

  // Uploaded documents
  List<Map<String, dynamic>> _documentsList = [];
  late TextEditingController _docNameController;

  // Submit state
  bool _submitting = false;
  String? _errorMessage;

  // Dummy data
  final List<String> _bankAccounts = [
    'HDFC_MAIN_ACCOUNT',
    'ICICI_SAVINGS',
    'AXIS_CHECKING',
    'SBI_BUSINESS',
  ];

  final List<String> _tenderOptions = ['CASH', 'UPI', 'CHEQUE', 'NEFT', 'RTGS'];

  @override
  void initState() {
    super.initState();
    _transactionDateController = TextEditingController(
      text: _formatDisplayDate(DateTime.now()),
    );
    _ledgerNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    _tenderAmountController = TextEditingController();
    _docNameController = TextEditingController();
    _selectedBankAccount = _bankAccounts.first;
    _selectedTender = _tenderOptions.first;
    _selectedCause = _causesList.first;
  }

  @override
  void dispose() {
    _transactionDateController.dispose();
    _ledgerNameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _tenderAmountController.dispose();
    _docNameController.dispose();
    super.dispose();
  }

  // ── formatting helpers ──────────────────────────────────────────────────────

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
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';

  // ── date picker ──────────────────────────────────────────────────────────

  Future<void> _pickTransactionDate() async {
    final parsed = DateTime.tryParse(_transactionDateController.text);
    final initial = parsed ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked == null) return;
    setState(() {
      _transactionDateController.text = _formatDisplayDate(picked);
    });
  }

  // ── decoration helper ─────────────────────────────────────────────────────

  InputDecoration _dec({
    required String label,
    Widget? suffix,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
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

  // ── tender management ────────────────────────────────────────────────────

  void _updateTotalAmount() {
    double total = 0;
    for (final tender in _tendersList) {
      final amt = double.tryParse(tender['amountPaid'] ?? '0') ?? 0;
      total += amt;
    }
    setState(() {
      _amountController.text = total.toStringAsFixed(2);
    });
  }

  void _addTender() {
    final amount = _tenderAmountController.text.trim();
    if (_selectedTender == null || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select tender and enter amount')),
      );
      return;
    }

    final tenderAmount = double.tryParse(amount);
    if (tenderAmount == null || tenderAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _tendersList.add({'tenderName': _selectedTender!, 'amountPaid': amount});
      _tenderAmountController.clear();
      _selectedTender = _tenderOptions.first;
      _updateTotalAmount();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $_selectedTender - ₹$amount')),
    );
  }

  void _removeTender(int index) {
    setState(() {
      _tendersList.removeAt(index);
      _updateTotalAmount();
    });
  }

  // ── cause management ────────────────────────────────────────────────────

  Future<void> _showAddCauseModal() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFF9F6FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Add New Cause',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _brandTextColor,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: _dec(label: 'Cause Name'),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\s]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _brandColor),
            onPressed: () {
              final cause = controller.text.trim().toUpperCase();
              if (cause.isEmpty) return;

              if (_causesList.contains(cause)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$cause already exists')),
                );
                return;
              }

              setState(() {
                _causesList.add(cause);
                _selectedCause = cause;
              });

              Navigator.of(dialogContext).pop();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Added $cause')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── document management ──────────────────────────────────────────────────

  Future<void> _addDocument() async {
    final docName = _docNameController.text.trim();
    if (docName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter document name')),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file selected')));
        return;
      }

      final file = result.files.first;
      final bytes = await file.xFile.readAsBytes();
      final base64Data = _encodeToBase64(bytes);

      setState(() {
        _documentsList.add({
          'documentName': docName,
          'documentType': 'RECEIPT',
          'documentData': base64Data,
          'fileName': file.name,
        });
        _docNameController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added document: $docName (${file.name})')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: ${e.toString()}')),
      );
    }
  }

  String _encodeToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  void _removeDocument(int index) {
    setState(() {
      _documentsList.removeAt(index);
    });
  }

  String? _extractLedgerReceiptBase64(Map<String, dynamic>? response) {
    final candidates = [
      response?['receipt'],
      response?['receiptBase64'],
      response?['base64Receipt'],
      response?['trnsReceipt'],
      response?['data'] is Map ? (response?['data'] as Map)['receipt'] : null,
      response?['data'] is Map
          ? (response?['data'] as Map)['receiptBase64']
          : null,
      response?['data'] is Map
          ? (response?['data'] as Map)['trnsReceipt']
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

  String _extractLedgerTransactionId(Map<String, dynamic>? response) {
    final candidates = [
      response?['transactionId'],
      response?['trnsId'],
      response?['ledgerId'],
      response?['data'] is Map
          ? (response?['data'] as Map)['transactionId']
          : null,
      response?['data'] is Map ? (response?['data'] as Map)['trnsId'] : null,
      response?['data'] is Map ? (response?['data'] as Map)['ledgerId'] : null,
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _showLedgerEntrySuccessDialog({
    required String message,
    required String? receiptBase64,
    required String transactionId,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Ledger Entry Created'),
          content: SizedBox(
            width: 420,
            child: Text(
              message,
              style: const TextStyle(
                color: _brandTextColor,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            if (receiptBase64 != null)
              FilledButton(
                onPressed: () async {
                  final downloaded = await downloadBase64Receipt(
                    base64Data: receiptBase64,
                    fileName: 'ledger_receipt_$transactionId.pdf',
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
                child: const Text('Download Receipt'),
              ),
          ],
        );
      },
    );
  }

  // ── submit ───────────────────────────────────────────────────────────────

  Future<void> _submitLedgerEntry() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tendersList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one tender')),
      );
      return;
    }

    if (_transactionType == 'CREDIT' &&
        _receiptRequired &&
        _documentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt required - please add a document'),
        ),
      );
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

      final transDateStr = _transactionDateController.text;
      final parsed = DateTime.tryParse(transDateStr);
      final transDate = parsed ?? DateTime.now();

      // Calculate total tender amount
      double totalAmount = 0;
      for (final tender in _tendersList) {
        final amt = double.tryParse(tender['amountPaid'] ?? '0') ?? 0;
        totalAmount += amt;
      }

      final requestBody = {
        'genericHeader': Map<String, dynamic>.from(header),
        'trnsDate': _toIso(transDate),
        'ledgerfor': _selectedCause ?? 'MAINTENANCE',
        'trnsType': _transactionType,
        'trnsShrtDesc': _descriptionController.text.trim(),
        'trnsBnkAccnt': _selectedBankAccount ?? _bankAccounts.first,
        'trnsAmt': totalAmount.toString(),
        'trnsStatus': 'SUCCESS',
        'cause': _ledgerNameController.text.trim(),
        'trnsTenderList': _tendersList,
        'supportedFileList': _documentsList,
        'requiredReceiptFlag': _receiptRequired,
      };

      final response = await ApiService.ledgerEntry(requestBody);

      if (!mounted) return;

      final code = response?['messageCode']?.toString() ?? '';
      if (code.toUpperCase().startsWith('SUCC')) {
        final successMessage =
            response?['message']?.toString() ??
            'Ledger entry created successfully.';
        final receiptBase64 = _extractLedgerReceiptBase64(response);
        final transactionId = _extractLedgerTransactionId(response);

        await _showLedgerEntrySuccessDialog(
          message: successMessage,
          receiptBase64: receiptBase64,
          transactionId: transactionId,
        );

        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _submitting = false;
          _tendersList.clear();
          _documentsList.clear();
          _transactionType = 'DEBIT';
          _receiptRequired = false;
          _transactionDateController.text = _formatDisplayDate(DateTime.now());
          _ledgerNameController.clear();
          _descriptionController.clear();
          _amountController.clear();
        });

        if (widget.onBack != null) {
          widget.onBack!();
        }
      } else {
        setState(() {
          _submitting = false;
          _errorMessage =
              response?['message']?.toString() ??
              'Failed to create ledger entry.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Unable to create ledger entry right now.';
      });
    }
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody(context);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        title: const Text('Create Ledger Entry'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with card style
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F8F82), Color(0xFF15766A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.onBack != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: widget.onBack,
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            const Text(
                              'Create Ledger Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Record a transaction in your accounting ledger',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Basic Info Section ──────────────────────────────────────
                _buildSectionCard(
                  title: 'Fill Details of Ledger',
                  icon: Icons.info_outline,
                  children: [
                    // Transaction Date
                    TextFormField(
                      controller: _transactionDateController,
                      readOnly: true,
                      decoration: _dec(
                        label: 'Transaction Date',
                        suffix: const Icon(Icons.calendar_today_rounded),
                      ),
                      onTap: _pickTransactionDate,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Ledger Name
                    TextFormField(
                      controller: _ledgerNameController,
                      decoration: _dec(label: 'Ledger Name'),
                      validator: (v) => v?.trim().isEmpty ?? true
                          ? 'Enter ledger name'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _dec(label: 'Short Description'),
                      maxLines: 2,
                      validator: (v) => v?.trim().isEmpty ?? true
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Transaction Type
                    DropdownButtonFormField<String>(
                      value: _transactionType,
                      decoration: _dec(label: 'Transaction Type'),
                      items: const [
                        DropdownMenuItem(value: 'DEBIT', child: Text('Debit')),
                        DropdownMenuItem(
                          value: 'CREDIT',
                          child: Text('Credit'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _transactionType = v;
                          if (v == 'DEBIT') {
                            _receiptRequired = false;
                          }
                        });
                      },
                    ),
                    // Receipt Required checkbox (only for CREDIT)
                    if (_transactionType == 'CREDIT') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F3F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB8DDD8)),
                        ),
                        child: CheckboxListTile(
                          value: _receiptRequired,
                          activeColor: _brandColor,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Receipt Required',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _brandTextColor,
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => _receiptRequired = v ?? false),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ── Bank & Amount Section ────────────────────────────────
                _buildSectionCard(
                  title: 'Bank Account',
                  icon: Icons.account_balance_wallet,
                  children: [
                    // Bank Account
                    DropdownButtonFormField<String>(
                      value: _selectedBankAccount,
                      decoration: _dec(label: 'Bank Account'),
                      items: _bankAccounts
                          .map(
                            (ba) => DropdownMenuItem(
                              value: ba,
                              child: Text(ba.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBankAccount = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Tenders Section ──────────────────────────────────────
                _buildSectionCard(
                  title: 'Payment Tenders',
                  icon: Icons.payments,
                  children: [
                    // Tender selection row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedTender,
                            decoration: _dec(label: 'Tender Type'),
                            items: _tenderOptions
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedTender = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _tenderAmountController,
                            decoration: _dec(label: 'Amount'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                          onPressed: _addTender,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add'),
                        ),
                      ],
                    ),

                    // Tenders list
                    if (_tendersList.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFDF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4EAE0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tenders Added',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _brandTextColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._tendersList.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final tender = entry.value;
                              final tenderName = tender['tenderName'] ?? '';
                              final amount = tender['amountPaid'] ?? '0';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: _brandColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.payments_rounded,
                                            color: _brandColor,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tenderName,
                                              style: const TextStyle(
                                                color: _brandTextColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '₹$amount',
                                              style: TextStyle(
                                                color: _brandColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                      color: const Color(0xFFB3261E),
                                      onPressed: () => _removeTender(idx),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Divider(height: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _brandTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '₹${_tendersList.fold<double>(0, (sum, t) => sum + (double.tryParse(t['amountPaid'] ?? '0') ?? 0)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _brandColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ── Cause Section ──────────────────────────────────────
                _buildSectionCard(
                  title: 'Transaction Details',
                  icon: Icons.category_outlined,
                  children: [
                    // Cause dropdown with Add button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCause,
                            decoration: _dec(label: 'Cause Of Transaction'),
                            items: _causesList
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.replaceAll('_', ' ')),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCause = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _brandColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                          onPressed: _showAddCauseModal,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Documents Section ───────────────────────────────────
                _buildSectionCard(
                  title: 'Supported Files',
                  icon: Icons.attach_file_rounded,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _docNameController,
                            decoration: _dec(label: 'Document Name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFCF8A2E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                          onPressed: _addDocument,
                          icon: const Icon(Icons.upload_file, size: 20),
                          label: const Text('Upload'),
                        ),
                      ],
                    ),

                    // Documents list
                    if (_documentsList.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Added Documents:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _brandTextColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._documentsList.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final doc = entry.value;
                        final docName = doc['documentName'] ?? '';
                        final fileName = doc['fileName'] ?? 'unknown.pdf';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFAD8A8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFCF8A2E,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.attach_file_rounded,
                                          color: Color(0xFFCF8A2E),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              docName,
                                              style: const TextStyle(
                                                color: _brandTextColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              fileName,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                  ),
                                  color: const Color(0xFFB3261E),
                                  onPressed: () => _removeDocument(idx),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 28),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1C8C5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFB3261E),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF8B1E1E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitting ? null : _submitLedgerEntry,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Ledger Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: widget.onBack,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F8F82).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _brandColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _brandTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
