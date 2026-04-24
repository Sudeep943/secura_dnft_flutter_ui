import 'dart:convert';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/api_service.dart';
import '../services/receipt_downloader.dart';

class CreateReceiptPage extends StatefulWidget {
  const CreateReceiptPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<CreateReceiptPage> createState() => _CreateReceiptPageState();
}

class _CreateReceiptPageState extends State<CreateReceiptPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  final TextEditingController _chargeNameController = TextEditingController();
  final TextEditingController _chargeValueController = TextEditingController();

  final TextEditingController _tenderAmountController = TextEditingController();
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

  final TextEditingController _discountValueController =
      TextEditingController();
  final TextEditingController _fineValueController = TextEditingController();

  bool _createNewLedgerEntry = false;
  bool _perHeadVoucher = false;

  final List<String> _receiptTypeOptions = ['Payment', 'Maintenance', 'Event'];
  String? _selectedReceiptType;

  List<String> _flatIdOptions = const [];
  String? _selectedFlatId;
  bool _loadingFlatIds = false;
  String? _flatIdError;

  final List<_ReceiptItemInput> _items = [];
  final List<_AddedChargeInput> _addedCharges = [];
  final List<_TenderInput> _tenders = [];

  String _newChargeType = 'amount';
  String _newTenderType = 'CASH';
  String _discountType = 'amount';
  String _fineType = 'amount';

  bool _previewLoading = false;
  bool _submitting = false;
  String? _previewError;
  String? _receiptPreview;
  Uint8List? _receiptPreviewBytes;
  String? _lastSuccessMessage;

  @override
  void initState() {
    super.initState();
    _selectedReceiptType = _receiptTypeOptions.first;
    _discountValueController.addListener(_refreshCalculatedTotals);
    _fineValueController.addListener(_refreshCalculatedTotals);
    _quantityController.text = '1';
    _refreshCalculatedTotals();
    _loadFlatIds();
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _remarksController.dispose();
    _totalAmountController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _chargeNameController.dispose();
    _chargeValueController.dispose();
    _tenderAmountController.dispose();
    _chequeNumberController.dispose();
    _chequeDateController.dispose();
    _chequeBankNameController.dispose();
    _chequeAccountHolderController.dispose();
    _chequeAccountNumberController.dispose();
    _ddBankNameController.dispose();
    _ddPayableAtController.dispose();
    _ddNumberController.dispose();
    _ddIssueDateController.dispose();
    _discountValueController.dispose();
    _fineValueController.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E5E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brandColor, width: 1.4),
      ),
    );
  }

  bool _isSuccessResponse(Map<String, dynamic>? response) {
    if (response == null) return false;
    final messageCode =
        (response['messageCode'] ?? response['message_code'] ?? '').toString();
    if (messageCode.toUpperCase().startsWith('SUCC')) {
      return true;
    }
    final status = response['status']?.toString().toLowerCase() ?? '';
    return status == 'success' || status == 'true';
  }

  String _responseMessage(Map<String, dynamic>? response, String fallback) {
    if (response == null) return fallback;
    const keys = ['message', 'statusMessage', 'description', 'result'];
    for (final key in keys) {
      final value = response[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return fallback;
  }

  List<String> _collectFlatIds(Map<String, dynamic> response) {
    final result = <String>{};

    void addFlat(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        result.add(text);
      }
    }

    void walk(dynamic node, {String? parentKey}) {
      if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        for (final entry in map.entries) {
          final key = entry.key.toLowerCase();
          final value = entry.value;
          if (key == 'flatid' ||
              key == 'flatno' ||
              key == 'flatnumber' ||
              key == 'flatname') {
            addFlat(value);
          }
          walk(value, parentKey: key);
        }
        return;
      }

      if (node is List) {
        if ((parentKey ?? '').contains('flatlist')) {
          for (final item in node) {
            if (item is String) {
              addFlat(item);
            } else if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              addFlat(
                map['flatId'] ??
                    map['flatNo'] ??
                    map['flatNumber'] ??
                    map['flatName'],
              );
            }
          }
        }

        for (final item in node) {
          walk(item, parentKey: parentKey);
        }
      }
    }

    walk(response);
    final sorted = result.toList()..sort();
    return sorted;
  }

  Future<void> _loadFlatIds() async {
    setState(() {
      _loadingFlatIds = true;
      _flatIdError = null;
    });

    try {
      final response = await ApiService.getAllFlats();
      if (!mounted) return;
      if (response == null || !_isSuccessResponse(response)) {
        setState(() {
          _flatIdOptions = const [];
          _selectedFlatId = null;
          _flatIdError = _responseMessage(
            response,
            'Unable to load flats for Flat Id dropdown.',
          );
        });
        return;
      }

      final flats = _collectFlatIds(response);
      setState(() {
        _flatIdOptions = flats;
        _selectedFlatId = flats.isEmpty ? null : flats.first;
        _flatIdError = flats.isEmpty ? 'No flats available.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _flatIdOptions = const [];
        _selectedFlatId = null;
        _flatIdError = 'Unable to load the flat list right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingFlatIds = false;
        });
      }
    }
  }

  double _parseAmount(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String _formatCurrency(double amount, {int digits = 2}) {
    return '₹${amount.toStringAsFixed(digits)}';
  }

  double _itemAmount(_ReceiptItemInput item) {
    return item.quantity * item.unitPrice;
  }

  double get _itemsTotal {
    return _items.fold<double>(0, (sum, item) => sum + _itemAmount(item));
  }

  double _chargeComputedAmount(_AddedChargeInput charge, double baseAmount) {
    if (charge.chargeType == 'percentage') {
      return baseAmount * charge.value / 100;
    }
    return charge.value;
  }

  double get _addedChargesTotal {
    final base = _itemsTotal;
    return _addedCharges.fold<double>(
      0,
      (sum, charge) => sum + _chargeComputedAmount(charge, base),
    );
  }

  double _computedAdjustmentAmount(
    String type,
    String value,
    double baseAmount,
  ) {
    final amount = _parseAmount(value);
    if (type == 'percentage') {
      return baseAmount * amount / 100;
    }
    return amount;
  }

  double get _discountAmount {
    return _computedAdjustmentAmount(
      _discountType,
      _discountValueController.text,
      _itemsTotal,
    );
  }

  double get _fineAmount {
    return _computedAdjustmentAmount(
      _fineType,
      _fineValueController.text,
      _itemsTotal,
    );
  }

  double get _totalAmount {
    final total =
        _itemsTotal + _addedChargesTotal + _fineAmount - _discountAmount;
    if (total <= 0) {
      return 0;
    }
    return total.ceilToDouble();
  }

  double get _totalAddedTenderAmount {
    return _tenders.fold<double>(0, (sum, tender) => sum + tender.amount);
  }

  double get _amountLeftToAdd {
    return _totalAmount - _totalAddedTenderAmount;
  }

  void _refreshCalculatedTotals() {
    final value = _totalAmount;
    _totalAmountController.text = value.toStringAsFixed(0);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickChequeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;
    setState(() {
      _chequeDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickDdIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked == null) return;
    setState(() {
      _ddIssueDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _showAddReceiptTypeDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Receipt Type'),
          content: TextField(
            controller: controller,
            decoration: _dec(label: 'Receipt Type'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\s-]')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                if (_receiptTypeOptions.any(
                  (type) => type.toLowerCase() == value.toLowerCase(),
                )) {
                  Navigator.of(dialogContext).pop();
                  return;
                }
                setState(() {
                  _receiptTypeOptions.add(value);
                  _selectedReceiptType = value;
                });
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: _brandColor),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addItem() {
    if (_items.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 10 items only.')),
      );
      return;
    }

    final itemName = _itemNameController.text.trim();
    final quantity = _parseAmount(_quantityController.text);
    final unitPrice = _parseAmount(_unitPriceController.text);

    if (itemName.isEmpty || quantity <= 0 || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid Item Name, Quantity and Unit Price.'),
        ),
      );
      return;
    }

    setState(() {
      _items.add(
        _ReceiptItemInput(
          itemName: itemName,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
      _itemNameController.clear();
      _quantityController.text = '1';
      _unitPriceController.clear();
      _previewError = null;
      _lastSuccessMessage = null;
    });
    _refreshCalculatedTotals();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _lastSuccessMessage = null;
    });
    _refreshCalculatedTotals();
  }

  void _addCharge() {
    if (_addedCharges.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 6 added charges only.'),
        ),
      );
      return;
    }

    final chargeName = _chargeNameController.text.trim();
    final value = _parseAmount(_chargeValueController.text);

    if (chargeName.isEmpty || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid Charge Name and Value.')),
      );
      return;
    }

    setState(() {
      _addedCharges.add(
        _AddedChargeInput(
          chargeName: chargeName,
          chargeType: _newChargeType,
          value: value,
        ),
      );
      _chargeNameController.clear();
      _chargeValueController.clear();
      _newChargeType = 'amount';
      _lastSuccessMessage = null;
    });
    _refreshCalculatedTotals();
  }

  void _removeCharge(int index) {
    setState(() {
      _addedCharges.removeAt(index);
      _lastSuccessMessage = null;
    });
    _refreshCalculatedTotals();
  }

  void _addTender() {
    final amount = _parseAmount(_tenderAmountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid tender amount.')),
      );
      return;
    }

    if (_newTenderType == 'CHEQUE') {
      final missing =
          _chequeNumberController.text.trim().isEmpty ||
          _chequeDateController.text.trim().isEmpty ||
          _chequeBankNameController.text.trim().isEmpty ||
          _chequeAccountHolderController.text.trim().isEmpty ||
          _chequeAccountNumberController.text.trim().isEmpty;
      if (missing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill all cheque details.')),
        );
        return;
      }
    }

    if (_newTenderType == 'DEMAND_DRAFT') {
      final missing =
          _ddBankNameController.text.trim().isEmpty ||
          _ddPayableAtController.text.trim().isEmpty ||
          _ddNumberController.text.trim().isEmpty ||
          _ddIssueDateController.text.trim().isEmpty;
      if (missing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill all demand draft details.')),
        );
        return;
      }
    }

    setState(() {
      _tenders.add(
        _TenderInput(
          tenderName: _newTenderType == 'DEMAND_DRAFT'
              ? 'DEMAND DRAFT'
              : _newTenderType,
          amount: amount,
          chequeNumber: _newTenderType == 'CHEQUE'
              ? _chequeNumberController.text.trim()
              : null,
          chequeDate: _newTenderType == 'CHEQUE'
              ? _chequeDateController.text.trim()
              : null,
          chequeBankName: _newTenderType == 'CHEQUE'
              ? _chequeBankNameController.text.trim()
              : null,
          chequeAccountHolder: _newTenderType == 'CHEQUE'
              ? _chequeAccountHolderController.text.trim()
              : null,
          chequeAccountNumber: _newTenderType == 'CHEQUE'
              ? _chequeAccountNumberController.text.trim()
              : null,
          ddBankName: _newTenderType == 'DEMAND_DRAFT'
              ? _ddBankNameController.text.trim()
              : null,
          ddPayableAt: _newTenderType == 'DEMAND_DRAFT'
              ? _ddPayableAtController.text.trim()
              : null,
          ddNumber: _newTenderType == 'DEMAND_DRAFT'
              ? _ddNumberController.text.trim()
              : null,
          ddIssueDate: _newTenderType == 'DEMAND_DRAFT'
              ? _ddIssueDateController.text.trim()
              : null,
        ),
      );

      _newTenderType = 'CASH';
      _tenderAmountController.clear();
      _chequeNumberController.clear();
      _chequeDateController.clear();
      _chequeBankNameController.clear();
      _chequeAccountHolderController.clear();
      _chequeAccountNumberController.clear();
      _ddBankNameController.clear();
      _ddPayableAtController.clear();
      _ddNumberController.clear();
      _ddIssueDateController.clear();
      _lastSuccessMessage = null;
    });
  }

  void _removeTender(int index) {
    setState(() {
      _tenders.removeAt(index);
      _lastSuccessMessage = null;
    });
  }

  Map<String, dynamic>? _buildGenericHeader() {
    final header = ApiService.userHeader;
    if (header == null || header.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(header);
  }

  String _extractReceipt(Map<String, dynamic>? response) {
    debugPrint('[Receipt] ===== BEGIN EXTRACTION =====');
    debugPrint(
      '[Receipt] raw response keys: ${response?.keys.toList() ?? 'null'}',
    );

    if (response != null) {
      for (final key in response.keys) {
        final value = response[key];
        if (value is String) {
          debugPrint(
            '[Receipt] $key (string): ${value.length} chars, starts with: ${value.substring(0, min(50, value.length))}',
          );
        } else if (value is Map) {
          debugPrint('[Receipt] $key (map): keys=${value.keys.toList()}');
        } else if (value is List) {
          debugPrint('[Receipt] $key (list): length=${value.length}');
        } else {
          debugPrint('[Receipt] $key: $value');
        }
      }
    }

    final data = response == null ? null : response['data'];
    final candidates = <String>[];

    void addCandidate(dynamic value) {
      final str = value?.toString().trim() ?? '';
      if (str.isEmpty || str.toLowerCase() == 'null') {
        return;
      }
      candidates.add(str);
    }

    // Explicit keys first.
    addCandidate(response?['trnsReceipt']);
    addCandidate(response?['transactionReceipt']);
    addCandidate(response?['receiptPdf']);
    addCandidate(response?['pdfReceipt']);
    addCandidate(response?['receipt']);
    addCandidate(response?['receiptBase64']);
    addCandidate(response?['base64Receipt']);
    addCandidate(response?['pdfBase64']);
    addCandidate(response?['pdf']);

    if (data is Map) {
      debugPrint('[Receipt] data is Map with keys: ${data.keys.toList()}');
      addCandidate(data['trnsReceipt']);
      addCandidate(data['transactionReceipt']);
      addCandidate(data['receiptPdf']);
      addCandidate(data['pdfReceipt']);
      addCandidate(data['receipt']);
      addCandidate(data['receiptBase64']);
      addCandidate(data['base64Receipt']);
      addCandidate(data['pdfBase64']);
      addCandidate(data['pdf']);
    } else {
      debugPrint(
        '[Receipt] data is not Map, type: ${data.runtimeType}, value preview: ${data?.toString().substring(0, min(100, data?.toString().length ?? 0)) ?? 'null'}',
      );
      addCandidate(data);
      final parsedDataMap = _tryParseJsonMap(data?.toString() ?? '');
      if (parsedDataMap != null) {
        debugPrint('[Receipt] parsed data as JSON Map');
        _collectReceiptCandidatesFromMap(parsedDataMap, addCandidate);
      }
    }

    if (response != null) {
      _collectReceiptCandidatesFromMap(response, addCandidate);

      const wrapperKeys = ['result', 'payload', 'response', 'body'];
      for (final wrapper in wrapperKeys) {
        final wrapperValue = response[wrapper];
        if (wrapperValue is Map) {
          _collectReceiptCandidatesFromMap(wrapperValue, addCandidate);
        }
      }
    }

    debugPrint('[Receipt] total candidates collected: ${candidates.length}');

    if (candidates.isEmpty) {
      debugPrint('[Receipt] NO CANDIDATES FOUND - returning empty');
      debugPrint('[Receipt] ===== END EXTRACTION (FAILED) =====');
      return '';
    }

    var best = candidates.first;
    var bestScore = _scoreReceiptCandidate(best);
    for (var i = 1; i < candidates.length; i++) {
      final current = candidates[i];
      final score = _scoreReceiptCandidate(current);
      if (score > bestScore) {
        best = current;
        bestScore = score;
      }
    }

    debugPrint(
      '[Receipt] selected candidate with score=$bestScore, length=${best.length}',
    );
    debugPrint(
      '[Receipt] candidate preview: ${best.substring(0, min(100, best.length))}',
    );
    debugPrint('[Receipt] ===== END EXTRACTION (SUCCESS) =====');
    return best;
  }

  Uint8List? _extractReceiptBytes(Map<String, dynamic>? response) {
    if (response == null) return null;

    Uint8List? best;

    void consider(Uint8List? bytes) {
      if (bytes == null || bytes.isEmpty) return;
      if (best == null) {
        best = bytes;
        return;
      }

      final current = best!;
      final currentIsDoc = _isPdfBytes(current) || _isImageBytes(current);
      final incomingIsDoc = _isPdfBytes(bytes) || _isImageBytes(bytes);

      if (!currentIsDoc && incomingIsDoc) {
        best = bytes;
        return;
      }

      if (incomingIsDoc == currentIsDoc && bytes.length > current.length) {
        best = bytes;
      }
    }

    void walk(dynamic node, {int depth = 0}) {
      if (node == null || depth > 8) return;

      if (node is Uint8List) {
        consider(node);
        return;
      }

      if (node is String) {
        final trimmed = node.trim();
        if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
          return;
        }

        final parsedMap = _tryParseJsonMap(trimmed);
        if (parsedMap != null) {
          walk(parsedMap, depth: depth + 1);
        }

        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          try {
            final parsed = jsonDecode(trimmed);
            if (parsed is List) {
              walk(parsed, depth: depth + 1);
            }
          } catch (_) {
            // Not a JSON array string.
          }
        }

        consider(_decodeReceiptBytes(trimmed));
        return;
      }

      if (node is List) {
        if (node.isNotEmpty && node.every((e) => e is num)) {
          final ints = node
              .map((e) => (e as num).toInt())
              .where((v) => v >= 0 && v <= 255)
              .toList(growable: false);
          if (ints.length == node.length && ints.length >= 4) {
            consider(Uint8List.fromList(ints));
          }
        }

        for (final item in node) {
          walk(item, depth: depth + 1);
        }
        return;
      }

      if (node is Map) {
        final map = Map<String, dynamic>.from(node);

        const priorityKeys = [
          'trnsReceipt',
          'transactionReceipt',
          'receiptPdf',
          'pdfReceipt',
          'receipt',
          'receiptBase64',
          'base64Receipt',
          'pdfBase64',
          'receiptBytes',
          'pdfBytes',
          'byteArray',
        ];

        const wrapperKeys = ['data', 'result', 'payload', 'response', 'body'];

        for (final key in priorityKeys) {
          if (map.containsKey(key)) {
            walk(map[key], depth: depth + 1);
          }
        }

        for (final key in wrapperKeys) {
          if (map.containsKey(key) && map[key] is Map) {
            walk(map[key], depth: depth + 1);
          }
        }

        for (final entry in map.entries) {
          final key = entry.key.toLowerCase();
          if (key.contains('receipt')) {
            walk(entry.value, depth: depth + 1);
          }
        }
      }
    }

    walk(response);
    return best;
  }

  Map<String, dynamic>? _tryParseJsonMap(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;
    if (!(input.startsWith('{') && input.endsWith('}'))) {
      return null;
    }
    try {
      final decoded = jsonDecode(input);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Not a JSON map string.
    }
    return null;
  }

  void _collectReceiptCandidatesFromMap(
    Map<dynamic, dynamic> map,
    void Function(dynamic value) addCandidate,
  ) {
    const directKeys = [
      'trnsreceipt',
      'transactionreceipt',
      'receiptpdf',
      'pdfreceipt',
      'receipt',
      'receiptbase64',
      'base64receipt',
      'pdfbase64',
      'pdf',
    ];
    const wrapperKeys = ['data', 'result', 'payload', 'response', 'body'];

    for (final entry in map.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value;

      final isReceiptKey = directKeys.contains(key);
      if (isReceiptKey &&
          value != null &&
          (value is String || value is num || value is bool)) {
        addCandidate(value);
      }

      if (wrapperKeys.contains(key) && value is Map) {
        _collectReceiptCandidatesFromMap(value, addCandidate);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            _collectReceiptCandidatesFromMap(item, addCandidate);
          }
        }
      }
    }
  }

  int _scoreReceiptCandidate(String candidate) {
    final trimmed = candidate.trim();
    if (trimmed.isEmpty) return -1;

    final bytes = _decodeReceiptBytes(trimmed);
    if (bytes != null && bytes.isNotEmpty) {
      if (_isPdfBytes(bytes)) {
        return 300000 + bytes.length;
      }
      if (_isImageBytes(bytes)) {
        return 200000 + bytes.length;
      }
      return 100000 + bytes.length;
    }

    final lower = trimmed.toLowerCase();
    if (_isLikelyPdfUrl(trimmed)) {
      return 250000 + trimmed.length;
    }
    if (_isLikelyImageUrl(trimmed)) {
      return 180000 + trimmed.length;
    }
    if (trimmed.startsWith('<') || trimmed.startsWith('{')) {
      return 50000 + trimmed.length;
    }
    if (lower.contains('receipt') || lower.contains('pdf')) {
      return 10000 + trimmed.length;
    }
    return 1000 + trimmed.length;
  }

  String _normalizeReceiptPayload(String value) {
    var normalized = value.trim();

    final hasDoubleQuotes =
        normalized.length >= 2 &&
        normalized.startsWith('"') &&
        normalized.endsWith('"');
    final hasSingleQuotes =
        normalized.length >= 2 &&
        normalized.startsWith("'") &&
        normalized.endsWith("'");

    if (hasDoubleQuotes || hasSingleQuotes) {
      normalized = normalized.substring(1, normalized.length - 1);
    }

    final dataUriMatch = RegExp(
      r'^data:.*?;base64,(.*)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (dataUriMatch != null) {
      normalized = dataUriMatch.group(1) ?? normalized;
    }

    normalized = normalized
        .replaceAll(r'\n', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .replaceAll('-', '+')
        .replaceAll('_', '/');

    final remainder = normalized.length % 4;
    if (remainder == 2) normalized = '$normalized==';
    if (remainder == 3) normalized = '$normalized=';

    return normalized;
  }

  String _formatReceiptForPreview(String receipt) {
    final trimmed = receipt.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('<') || trimmed.startsWith('{')) {
      return trimmed;
    }

    try {
      final decodedBytes = base64Decode(_normalizeReceiptPayload(trimmed));
      final decoded = utf8.decode(decodedBytes, allowMalformed: true).trim();
      if (decoded.isNotEmpty &&
          (decoded.startsWith('<') ||
              decoded.startsWith('{') ||
              decoded.toLowerCase().contains('receipt'))) {
        return decoded;
      }
    } catch (_) {
      // Keep raw value when not decodable.
    }

    return trimmed;
  }

  Uint8List? _decodeReceiptBytes(String receipt) {
    final trimmed = receipt.trim();
    if (trimmed.isEmpty) return null;
    try {
      return base64Decode(_normalizeReceiptPayload(trimmed));
    } catch (_) {
      return null;
    }
  }

  bool _isPdfBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  bool _isImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;

    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    if (isPng) return true;

    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    if (isJpeg) return true;

    final isGif =
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38;
    if (isGif) return true;

    final isWebP =
        bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return isWebP;
  }

  bool _isLikelyPdfUrl(String value) {
    final lower = value.trim().toLowerCase();
    return (lower.startsWith('http://') || lower.startsWith('https://')) &&
        (lower.contains('.pdf') || lower.contains('application/pdf'));
  }

  bool _isLikelyImageUrl(String value) {
    final lower = value.trim().toLowerCase();
    return (lower.startsWith('http://') || lower.startsWith('https://')) &&
        (lower.contains('.png') ||
            lower.contains('.jpg') ||
            lower.contains('.jpeg') ||
            lower.contains('.webp') ||
            lower.contains('.gif') ||
            lower.contains('image/'));
  }

  Future<bool> _showCreateReceiptSuccessModal({
    required String message,
    required String receiptBase64,
  }) async {
    final shouldClose = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Receipt Created'),
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () async {
                final id = _transactionIdController.text.trim();
                final fileName =
                    'receipt_${id.isEmpty ? DateTime.now().millisecondsSinceEpoch : id}.pdf';
                final downloaded = await downloadBase64Receipt(
                  base64Data: receiptBase64,
                  fileName: fileName,
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
              style: FilledButton.styleFrom(backgroundColor: _brandColor),
              child: const Text('Download Receipt'),
            ),
          ],
        );
      },
    );

    return shouldClose ?? false;
  }

  void _closeAfterCreateSuccess() {
    if (widget.embedded && widget.onBack != null) {
      widget.onBack!();
      return;
    }

    Navigator.of(context).maybePop();
  }

  Map<String, dynamic> _buildReceiptRequestBody({required bool isPreview}) {
    final items = _items
        .map((item) {
          final amount = _itemAmount(item);
          return {
            'itemName': item.itemName,
            'unitPrice': item.unitPrice.toStringAsFixed(2),
            _perHeadVoucher ? 'noOfPerson' : 'quantity': item.quantity
                .toStringAsFixed(2),
            'quantity': item.quantity.toStringAsFixed(2),
            'type': 'charge',
            'amount': amount.toStringAsFixed(2),
          };
        })
        .toList(growable: false);

    final baseAmount = _itemsTotal;
    final charges = _addedCharges
        .map((charge) {
          final computed = _chargeComputedAmount(charge, baseAmount);
          return {
            'chargeName': charge.chargeName,
            'chargeType': charge.chargeType,
            'value': charge.value.toStringAsFixed(2),
            'finalChargeValue': computed.toStringAsFixed(2),
          };
        })
        .toList(growable: false);

    final tenders = _tenders
        .map(
          (tender) => {
            'tenderName': tender.tenderName,
            'amountPaid': tender.amount.toStringAsFixed(2),
          },
        )
        .toList(growable: false);

    final bankInstrumentTenderDetails = _tenders
        .where(
          (tender) =>
              tender.tenderName == 'CHEQUE' ||
              tender.tenderName == 'DEMAND DRAFT',
        )
        .map((tender) {
          if (tender.tenderName == 'CHEQUE') {
            return {
              'tenderType': 'CHEQUE',
              'chequeNumber': tender.chequeNumber,
              'chequeDate': tender.chequeDate,
              'bankName': tender.chequeBankName,
              'accountHolderName': tender.chequeAccountHolder,
              'accountNumber': tender.chequeAccountNumber,
              'amount': tender.amount.toStringAsFixed(2),
              'remarks': _remarksController.text.trim(),
            };
          }

          return {
            'tenderType': 'DEMAND DRAFT',
            'ddNumber': tender.ddNumber,
            'ddIssueDate': tender.ddIssueDate,
            'bankName': tender.ddBankName,
            'ddPayAtBranch': tender.ddPayableAt,
            'amount': tender.amount.toStringAsFixed(2),
            'remarks': _remarksController.text.trim(),
          };
        })
        .toList(growable: false);

    final discountValue = _parseAmount(_discountValueController.text);
    final fineValue = _parseAmount(_fineValueController.text);

    final requestBody = {
      'genericHeader': _buildGenericHeader(),
      'createNewLedgerEntryFlag': _createNewLedgerEntry,
      'receiptType': _selectedReceiptType ?? 'Maintenance',
      'flatId': _selectedFlatId,
      'transactionId': _transactionIdController.text.trim(),
      'perheadFlag': _perHeadVoucher,
      'unitPriceRequired': true,
      'remarks': _remarksController.text.trim(),
      'items': items,
      'addedCharges': charges,
      'tenderList': tenders,
      'trnsTenderList': tenders,
      'bankInstrumentTenderDetails': bankInstrumentTenderDetails,
      'discFinReceipt': {
        'discountType': _discountType,
        'discountPercentage': _discountType == 'percentage'
            ? discountValue.toStringAsFixed(2)
            : '0',
        'discountAmount': _discountAmount.toStringAsFixed(2),
        'fineType': _fineType,
        'finePercentage': _fineType == 'percentage'
            ? fineValue.toStringAsFixed(2)
            : '0',
        'fineAmount': _fineAmount.toStringAsFixed(2),
        'fineCycleMode': isPreview ? 'simple' : 'cumulative',
      },
      'totalAmount': _totalAmount.toStringAsFixed(0),
    };

    return requestBody;
  }

  bool _validateBeforeSubmit() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedFlatId == null || _selectedFlatId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select Flat Id.')));
      return false;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item.')));
      return false;
    }

    if (_tenders.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one tender.')));
      return false;
    }

    return true;
  }

  Future<void> _invokeReceiptApi({required bool fromCreateButton}) async {
    if (!_validateBeforeSubmit()) {
      return;
    }

    final genericHeader = _buildGenericHeader();
    if (genericHeader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    setState(() {
      if (fromCreateButton) {
        _submitting = true;
      } else {
        _previewLoading = true;
      }
      _previewError = null;
      _lastSuccessMessage = null;
    });

    try {
      final requestBody = _buildReceiptRequestBody(
        isPreview: !fromCreateButton,
      );
      final response = fromCreateButton
          ? await ApiService.createReceipt(requestBody)
          : await ApiService.previewReceipt(requestBody);
      if (!mounted) return;

      final receipt = _extractReceipt(response);
      final receiptBytes =
          _extractReceiptBytes(response) ??
          (receipt.isEmpty ? null : _decodeReceiptBytes(receipt));

      // If receipt data is present, display it regardless of messageCode.
      // Only show an error when there is no receipt data at all.
      if (receipt.isEmpty && (receiptBytes == null || receiptBytes.isEmpty)) {
        setState(() {
          _previewError = _responseMessage(
            response,
            'Unable to generate receipt preview.',
          );
          _receiptPreview = null;
          _receiptPreviewBytes = null;
        });
        return;
      }

      final message = _responseMessage(
        response,
        fromCreateButton
            ? 'Receipt created successfully.'
            : 'Receipt preview loaded successfully.',
      );

      setState(() {
        _receiptPreview = receipt.isEmpty
            ? null
            : _formatReceiptForPreview(receipt);
        _receiptPreviewBytes = receiptBytes;
        _lastSuccessMessage = fromCreateButton ? message : null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      if (fromCreateButton) {
        final downloadPayload = receipt.isNotEmpty
            ? receipt
            : base64Encode(receiptBytes!);
        final shouldClose = await _showCreateReceiptSuccessModal(
          message: message,
          receiptBase64: downloadPayload,
        );
        if (shouldClose) {
          _closeAfterCreateSuccess();
        }
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewError = 'Unable to reach receipt service right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _previewLoading = false;
        });
      }
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _brandTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            'Create Receipt',
            style: TextStyle(
              color: _brandTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFields() {
    final quantityLabel = _perHeadVoucher ? 'No Of Person' : 'Quantity';

    return _buildSectionCard(
      title: 'Receipt Details',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFE4DB)),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  value: _createNewLedgerEntry,
                  title: const Text('Create A New Ledger Entry'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _brandColor,
                  onChanged: (value) {
                    setState(() {
                      _createNewLedgerEntry = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  value: _perHeadVoucher,
                  title: const Text('Per Head Vouchers'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _brandColor,
                  onChanged: (value) {
                    setState(() {
                      _perHeadVoucher = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFlatId,
                  decoration: _dec(
                    label: _loadingFlatIds ? 'Flat Id (Loading...)' : 'Flat Id',
                    suffix: IconButton(
                      onPressed: _loadingFlatIds ? null : _loadFlatIds,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  items: _flatIdOptions
                      .map(
                        (flatId) => DropdownMenuItem<String>(
                          value: flatId,
                          child: Text(flatId),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingFlatIds
                      ? null
                      : (value) {
                          setState(() {
                            _selectedFlatId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select Flat Id';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedReceiptType,
                  decoration: _dec(
                    label: 'Receipt Type',
                    suffix: IconButton(
                      onPressed: _showAddReceiptTypeDialog,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ),
                  items: _receiptTypeOptions
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReceiptType = value;
                    });
                  },
                ),
              ),
            ],
          ),
          if (_flatIdError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _flatIdError!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _transactionIdController,
                  decoration: _dec(label: 'Transaction Id'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _itemNameController,
                  decoration: _dec(label: 'Item Name'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: _dec(label: quantityLabel),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _unitPriceController,
                  decoration: _dec(label: 'Unit Price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _addItem,
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No items added yet.'),
            )
          else
            Column(
              children: _items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.itemName),
                  subtitle: Text(
                    '${_perHeadVoucher ? 'No Of Person' : 'Quantity'}: ${item.quantity.toStringAsFixed(2)}  |  Unit Price: ${_formatCurrency(item.unitPrice)}  |  Amount: ${_formatCurrency(_itemAmount(item))}',
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChargesSection() {
    return _buildSectionCard(
      title: 'Add Charges',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _chargeNameController,
                  decoration: _dec(label: 'Charge Name'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _newChargeType,
                  decoration: _dec(label: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'amount', child: Text('Amount')),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _newChargeType = value ?? 'amount';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _chargeValueController,
                  decoration: _dec(label: 'Value'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _addCharge,
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: const Icon(Icons.add),
                label: const Text('Add Charges'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_addedCharges.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No added charges yet.'),
            )
          else
            Column(
              children: _addedCharges.asMap().entries.map((entry) {
                final index = entry.key;
                final charge = entry.value;
                final computed = _chargeComputedAmount(charge, _itemsTotal);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(charge.chargeName),
                  subtitle: Text(
                    'Type: ${charge.chargeType}  |  Value: ${_formatCurrency(charge.value)}  |  Final: ${_formatCurrency(computed)}',
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeCharge(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTenderSection() {
    final needsChequeDetails = _newTenderType == 'CHEQUE';
    final needsDdDetails = _newTenderType == 'DEMAND_DRAFT';

    return _buildSectionCard(
      title: 'Add Tenders',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _newTenderType,
                  decoration: _dec(label: 'Tender'),
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                    DropdownMenuItem(
                      value: 'DEMAND_DRAFT',
                      child: Text('Demand Draft'),
                    ),
                    DropdownMenuItem(
                      value: 'BANK_TRANSFER',
                      child: Text('Bank Transfer'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _newTenderType = value ?? 'CASH';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _tenderAmountController,
                  decoration: _dec(label: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _addTender,
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: const Icon(Icons.add),
                label: const Text('Add Tender'),
              ),
            ],
          ),
          if (needsChequeDetails) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _chequeNumberController,
                    decoration: _dec(label: 'Cheque Number'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _chequeDateController,
                    readOnly: true,
                    decoration: _dec(
                      label: 'Cheque Date',
                      suffix: IconButton(
                        onPressed: _pickChequeDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _chequeBankNameController,
                    decoration: _dec(label: 'Bank Name'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _chequeAccountHolderController,
                    decoration: _dec(label: 'Account Holder Name'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _chequeAccountNumberController,
                    decoration: _dec(label: 'Account Number'),
                  ),
                ),
              ],
            ),
          ],
          if (needsDdDetails) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ddBankNameController,
                    decoration: _dec(label: 'DD Bank Name'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ddPayableAtController,
                    decoration: _dec(label: 'DD Payable At'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ddNumberController,
                    decoration: _dec(label: 'DD Number'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ddIssueDateController,
                    readOnly: true,
                    decoration: _dec(
                      label: 'DD Issue Date',
                      suffix: IconButton(
                        onPressed: _pickDdIssueDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCEAE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Added Tender Amount: ${_formatCurrency(_totalAddedTenderAmount)}',
                  style: const TextStyle(
                    color: _brandTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount Left: ${_formatCurrency(_amountLeftToAdd)}',
                  style: TextStyle(
                    color: _amountLeftToAdd < 0
                        ? const Color(0xFFB3261E)
                        : _brandTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_tenders.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No tenders added yet.'),
            )
          else
            Column(
              children: _tenders.asMap().entries.map((entry) {
                final index = entry.key;
                final tender = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(tender.tenderName),
                  subtitle: Text('Amount: ${_formatCurrency(tender.amount)}'),
                  trailing: IconButton(
                    onPressed: () => _removeTender(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountFineSection() {
    return _buildSectionCard(
      title: 'Discount And Fine',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _discountType,
                  decoration: _dec(label: 'Discount Type'),
                  items: const [
                    DropdownMenuItem(value: 'amount', child: Text('Amount')),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _discountType = value ?? 'amount';
                    });
                    _refreshCalculatedTotals();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _discountValueController,
                  decoration: _dec(label: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fineType,
                  decoration: _dec(label: 'Fine Type'),
                  items: const [
                    DropdownMenuItem(value: 'amount', child: Text('Amount')),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _fineType = value ?? 'amount';
                    });
                    _refreshCalculatedTotals();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _fineValueController,
                  decoration: _dec(label: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8E5E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount (After Rounding Off)',
                  style: TextStyle(
                    color: Color(0xFF4D6A65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(_totalAmount, digits: 0),
                  style: const TextStyle(
                    color: _brandTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _remarksController,
            decoration: _dec(label: 'Remarks'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildMainFields(),
          const SizedBox(height: 12),
          _buildChargesSection(),
          const SizedBox(height: 12),
          _buildDiscountFineSection(),
          const SizedBox(height: 12),
          _buildTenderSection(),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _invokeReceiptApi(fromCreateButton: true),
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: const Text('Create Receipt'),
              ),
            ],
          ),
          if (_lastSuccessMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F7F4),
                border: Border.all(color: const Color(0xFFBCE5DC)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _lastSuccessMessage!,
                style: const TextStyle(
                  color: _brandTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEAE7)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'View Receipt',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _brandTextColor,
                    fontSize: 16,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _previewLoading
                    ? null
                    : () => _invokeReceiptApi(fromCreateButton: false),
                style: FilledButton.styleFrom(backgroundColor: _brandColor),
                icon: _previewLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_outlined),
                label: const Text('View Receipt'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3EEEB)),
              ),
              child: Builder(
                builder: (_) {
                  if (_previewLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_previewError != null) {
                    return Center(
                      child: Text(
                        _previewError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFB3261E)),
                      ),
                    );
                  }

                  final bytes = _receiptPreviewBytes;
                  if (bytes != null && bytes.isNotEmpty) {
                    if (_isPdfBytes(bytes)) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SfPdfViewer.memory(bytes),
                      );
                    }

                    if (_isImageBytes(bytes)) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Unable to render receipt image.'),
                          ),
                        ),
                      );
                    }
                  }

                  final preview = (_receiptPreview ?? '').trim();
                  if (preview.isEmpty) {
                    return const Center(
                      child: Text(
                        'Receipt preview will appear here after clicking View Receipt.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (_isLikelyPdfUrl(preview)) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SfPdfViewer.network(preview),
                    );
                  }

                  if (_isLikelyImageUrl(preview)) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.network(
                        preview,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Unable to load receipt image URL.'),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: SelectableText(
                      preview,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        height: 1.35,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final isMobile = MediaQuery.of(context).size.width < 1100;

    if (isMobile) {
      return Column(
        children: [
          _buildLeftPanel(),
          const SizedBox(height: 12),
          SizedBox(height: 460, child: _buildRightPanel()),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: SingleChildScrollView(child: _buildLeftPanel()),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 9, child: _buildRightPanel()),
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
          const SizedBox(height: 12),
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
        title: const Text('Create Receipt'),
      ),
      body: content,
    );
  }
}

class _ReceiptItemInput {
  _ReceiptItemInput({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemName;
  final double quantity;
  final double unitPrice;
}

class _AddedChargeInput {
  _AddedChargeInput({
    required this.chargeName,
    required this.chargeType,
    required this.value,
  });

  final String chargeName;
  final String chargeType;
  final double value;
}

class _TenderInput {
  _TenderInput({
    required this.tenderName,
    required this.amount,
    this.chequeNumber,
    this.chequeDate,
    this.chequeBankName,
    this.chequeAccountHolder,
    this.chequeAccountNumber,
    this.ddBankName,
    this.ddPayableAt,
    this.ddNumber,
    this.ddIssueDate,
  });

  final String tenderName;
  final double amount;

  final String? chequeNumber;
  final String? chequeDate;
  final String? chequeBankName;
  final String? chequeAccountHolder;
  final String? chequeAccountNumber;

  final String? ddBankName;
  final String? ddPayableAt;
  final String? ddNumber;
  final String? ddIssueDate;
}
