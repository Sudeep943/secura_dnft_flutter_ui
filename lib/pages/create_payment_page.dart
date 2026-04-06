import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class CreatePaymentPage extends StatefulWidget {
  const CreatePaymentPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

class _CreatePaymentPageState extends State<CreatePaymentPage> {
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _brandTextColor = Color(0xFF124B45);
  static const Color _surfaceColor = Color(0xFFFFFCF4);
  static const Color _surfaceTint = Color(0xFFE7F5F1);
  static const String _currency = 'INR';
  static const String _status = 'ACTIVE';

  static const List<_PaymentChoice> _capitaOptions = [
    _PaymentChoice(label: 'Per Flat', value: 'PER_FLAT'),
    _PaymentChoice(label: 'Per Head', value: 'PER_HEAD'),
    _PaymentChoice(label: 'Per Sqft', value: 'PER_SQFT'),
    _PaymentChoice(label: 'Per BHK', value: 'PER_BHK'),
  ];

  static const List<_PaymentChoice> _cycleOptions = [
    _PaymentChoice(label: 'Once', value: 'ONCE'),
    _PaymentChoice(label: 'Weekly', value: 'WEEKLY'),
    _PaymentChoice(label: 'Quarterly', value: 'QUARTERLY'),
    _PaymentChoice(label: 'Half Yearly', value: 'HALF_YEARLY'),
    _PaymentChoice(label: 'Yearly', value: 'YEARLY'),
  ];

  static const List<_PaymentChoice> _modeOptions = [
    _PaymentChoice(label: 'Pre', value: 'PRE'),
    _PaymentChoice(label: 'Post', value: 'POST'),
  ];

  static const List<_PaymentChoice> _paymentTypeOptions = [
    _PaymentChoice(label: 'Mandatory', value: 'MANDATORY'),
    _PaymentChoice(label: 'Optional', value: 'OPTIONAL'),
  ];

  static const List<_PaymentChoice> _bankAccountOptions = [
    _PaymentChoice(label: 'Axis Bank • 123456', value: 'BANK123456'),
    _PaymentChoice(label: 'HDFC Bank • 654321', value: 'BANK654321'),
    _PaymentChoice(label: 'ICICI Bank • 112233', value: 'BANK112233'),
  ];

  static const _allResidentsOption = _PaymentChoice(
    label: 'All Residents',
    value: 'ALL_RESIDENTS',
  );

  static const List<_PaymentChoice> _towerOptions = [
    _PaymentChoice(label: 'Tower 1', value: 'TOWER_1'),
    _PaymentChoice(label: 'Tower 2', value: 'TOWER_2'),
    _PaymentChoice(label: 'Tower 3', value: 'TOWER_3'),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _paymentNameController = TextEditingController();
  final TextEditingController _shortDetailsController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _collectionStartController =
      TextEditingController();
  final TextEditingController _collectionEndController =
      TextEditingController();

  String? _paymentCapita;
  String? _paymentCollectionCycle;
  String? _paymentCollectionMode;
  String? _paymentType;
  String? _bankAccountId;
  DateTime? _collectionStartDate;
  DateTime? _collectionEndDate;
  Set<String> _applicableFor = {_allResidentsOption.value};
  Map<String, dynamic>? _dueDetails;
  String? _dueDetailsError;
  bool _loadingDueDetails = false;
  bool _submitting = false;
  int _dueDetailsRequestId = 0;
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    _paymentAmountController.addListener(_scheduleDueDetailsRefresh);
    _gstController.addListener(_scheduleDueDetailsRefresh);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _paymentNameController.dispose();
    _shortDetailsController.dispose();
    _paymentAmountController.dispose();
    _gstController.dispose();
    _collectionStartController.dispose();
    _collectionEndController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 900;
  }

  Map<String, dynamic>? _buildGenericHeader() {
    final header = ApiService.userHeader;
    if (header == null || header.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(header);
  }

  bool _isSuccessResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return false;
    }

    final messageCode =
        (response['messageCode'] ?? response['message_code'] ?? '').toString();
    if (messageCode.toUpperCase().startsWith('SUCC')) {
      return true;
    }

    if (messageCode.toUpperCase().startsWith('ERR')) {
      return false;
    }

    final status = response['status']?.toString().toLowerCase() ?? '';
    if (status == 'success' || status == 'true') {
      return true;
    }

    return response.containsKey('amountIncludingGst') ||
        response.containsKey('paymentId');
  }

  String _responseMessage(Map<String, dynamic>? response) {
    if (response == null) {
      return 'The server did not return a valid response.';
    }

    final candidates = [
      response['message'],
      response['statusMessage'],
      response['description'],
      response['result'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    if (_isSuccessResponse(response)) {
      return 'Payment created successfully.';
    }

    return 'Unable to complete the payment request right now.';
  }

  String? _extractPaymentId(Map<String, dynamic>? response) {
    if (response == null) {
      return null;
    }

    const candidates = ['paymentId', 'paymentID', 'id', 'referenceId'];
    for (final key in candidates) {
      final value = response[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return null;
  }

  void _closeToFinancePage() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }

    openAppShellSection(context, AppSection.finance);
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatRequestStartDate(DateTime date) {
    return '${_formatApiDate(date)}T00:00:00';
  }

  String _formatRequestEndDate(DateTime date) {
    return '${_formatApiDate(date)}T23:59:59';
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

  String _formatCurrencyValue(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    if (value.isEmpty) {
      return '₹0';
    }

    return value.startsWith('₹') ? value : '₹$value';
  }

  String _buildApplicableForDisplayText() {
    if (_isAllResidentsSelected) {
      return _allResidentsOption.label;
    }

    if (_applicableFor.isEmpty) {
      return 'Select residents';
    }

    return _towerOptions
        .where((option) => _applicableFor.contains(option.value))
        .map((option) => option.label)
        .join(', ');
  }

  String _buildApplicableForRequestValue() {
    if (_isAllResidentsSelected) {
      return _allResidentsOption.value;
    }

    return _applicableFor.join(',');
  }

  bool get _isAllResidentsSelected {
    if (_applicableFor.contains(_allResidentsOption.value)) {
      return true;
    }

    return _towerOptions.every(
      (option) => _applicableFor.contains(option.value),
    );
  }

  String _previewCycleValue(String value) {
    switch (value) {
      case 'HALF_YEARLY':
        return 'half yearly';
      default:
        return value.toLowerCase();
    }
  }

  void _scheduleDueDetailsRefresh() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 450),
      _refreshDueDetails,
    );
  }

  void _onDueFieldChanged() {
    setState(() {});
    _scheduleDueDetailsRefresh();
  }

  bool _hasAllDuePreviewInputs() {
    final amount = _normalizeNumericValue(_paymentAmountController.text);
    final gst = _normalizeNumericValue(_gstController.text);
    return amount.isNotEmpty &&
        gst.isNotEmpty &&
        _paymentCapita != null &&
        _paymentCollectionCycle != null &&
        _paymentCollectionMode != null &&
        _collectionStartDate != null &&
        _collectionEndDate != null;
  }

  void _resetDueDetailsState({String? error}) {
    _dueDetailsRequestId++;
    setState(() {
      _loadingDueDetails = false;
      _dueDetails = null;
      _dueDetailsError = error;
    });
  }

  Future<void> _refreshDueDetails() async {
    final header = _buildGenericHeader();
    if (header == null) {
      _resetDueDetailsState(
        error: 'User session details are missing. Please log in again.',
      );
      return;
    }

    if (!_hasAllDuePreviewInputs()) {
      _resetDueDetailsState();
      return;
    }

    final startDate = _collectionStartDate!;
    final endDate = _collectionEndDate!;
    if (endDate.isBefore(startDate)) {
      _resetDueDetailsState(
        error: 'Collection end date must be on or after the start date.',
      );
      return;
    }

    final requestId = ++_dueDetailsRequestId;
    setState(() {
      _loadingDueDetails = true;
      _dueDetailsError = null;
    });

    final response = await ApiService.getDuePaymentAmountDetails({
      'genericHeader': header,
      'paymentAmount': _normalizeNumericValue(_paymentAmountController.text),
      'gst': _normalizeNumericValue(_gstController.text),
      'collectionStartDate': _formatApiDate(startDate),
      'collectionEndDate': _formatApiDate(endDate),
      'paymentCollectionCycle': _previewCycleValue(_paymentCollectionCycle!),
      'paymentCollectionMode': _paymentCollectionMode!.toLowerCase(),
      'paymentCapita': _paymentCapita,
      'todayDate': _formatApiDate(DateTime.now()),
    });

    if (!mounted || requestId != _dueDetailsRequestId) {
      return;
    }

    final isSuccess = _isSuccessResponse(response);
    setState(() {
      _loadingDueDetails = false;
      if (response != null && isSuccess) {
        _dueDetails = response;
        _dueDetailsError = null;
      } else {
        _dueDetails = null;
        _dueDetailsError = _responseMessage(response);
      }
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _collectionStartDate = picked;
      _collectionStartController.text = _formatDisplayDate(picked);
      if (_collectionEndDate != null && _collectionEndDate!.isBefore(picked)) {
        _collectionEndDate = null;
        _collectionEndController.clear();
      }
    });
    _scheduleDueDetailsRefresh();
  }

  Future<void> _pickEndDate() async {
    final firstDate = _collectionStartDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectionEndDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _collectionEndDate = picked;
      _collectionEndController.text = _formatDisplayDate(picked);
    });
    _scheduleDueDetailsRefresh();
  }

  Future<Set<String>?> _showApplicableForDialog() {
    return showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        var currentSelection = Set<String>.from(_applicableFor);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateSelection(String value, bool selected) {
              setDialogState(() {
                if (value == _allResidentsOption.value) {
                  if (selected) {
                    currentSelection = {_allResidentsOption.value};
                  } else {
                    currentSelection.remove(_allResidentsOption.value);
                  }
                  return;
                }

                currentSelection.remove(_allResidentsOption.value);
                if (selected) {
                  currentSelection.add(value);
                } else {
                  currentSelection.remove(value);
                }

                final allTowersSelected = _towerOptions.every(
                  (option) => currentSelection.contains(option.value),
                );
                if (allTowersSelected) {
                  currentSelection = {_allResidentsOption.value};
                }
              });
            }

            final allSelected = currentSelection.contains(
              _allResidentsOption.value,
            );

            return AlertDialog(
              backgroundColor: const Color(0xFFF9F6FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Applicable For'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      dense: true,
                      value: allSelected,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _brandColor,
                      title: const Text('All Residents'),
                      onChanged: (value) => updateSelection(
                        _allResidentsOption.value,
                        value ?? false,
                      ),
                    ),
                    const Divider(height: 8),
                    ..._towerOptions.map(
                      (option) => CheckboxListTile(
                        dense: true,
                        value:
                            allSelected ||
                            currentSelection.contains(option.value),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: _brandColor,
                        title: Text(option.label),
                        onChanged: allSelected
                            ? null
                            : (value) =>
                                  updateSelection(option.value, value ?? false),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _brandColor),
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(currentSelection),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPayment() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final header = _buildGenericHeader();
    if (header == null) {
      await _showResultDialog(
        title: 'Payment Request Failed',
        message: 'User session details are missing. Please log in again.',
        isSuccess: false,
      );
      return;
    }

    final amount = _normalizeNumericValue(_paymentAmountController.text);
    final gst = _normalizeNumericValue(_gstController.text);
    final startDate = _collectionStartDate!;
    final endDate = _collectionEndDate!;

    if (endDate.isBefore(startDate)) {
      await _showResultDialog(
        title: 'Payment Request Failed',
        message: 'Collection end date must be on or after the start date.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final response = await ApiService.createPayment({
        'genericHeader': header,
        'paymentName': _paymentNameController.text.trim(),
        'shortDetails': _shortDetailsController.text.trim(),
        'paymentCapita': _paymentCapita,
        'paymentAmount': amount,
        'gst': gst,
        'currency': _currency,
        'collectionStartDate': _formatRequestStartDate(startDate),
        'collectionEndDate': _formatRequestEndDate(endDate),
        'paymentCollectionCycle': _paymentCollectionCycle,
        'paymentCollectionMode': _paymentCollectionMode,
        'applicableFor': _buildApplicableForRequestValue(),
        'paymentType': _paymentType,
        'bankAccountId': _bankAccountId,
        'status': _status,
      });

      final isSuccess = _isSuccessResponse(response);
      final paymentId = isSuccess ? _extractPaymentId(response) : null;

      await _showResultDialog(
        title: isSuccess ? 'Payment Created' : 'Payment Request Failed',
        message: _responseMessage(response),
        isSuccess: isSuccess,
        paymentId: paymentId,
        closeToFinanceOnAcknowledge: isSuccess,
      );
    } catch (_) {
      await _showResultDialog(
        title: 'Payment Request Failed',
        message: 'Unable to create the payment right now.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _previewDebounce?.cancel();
    _formKey.currentState?.reset();
    _paymentNameController.clear();
    _shortDetailsController.clear();
    _paymentAmountController.clear();
    _gstController.clear();
    _collectionStartController.clear();
    _collectionEndController.clear();
    setState(() {
      _paymentCapita = null;
      _paymentCollectionCycle = null;
      _paymentCollectionMode = null;
      _paymentType = null;
      _bankAccountId = null;
      _collectionStartDate = null;
      _collectionEndDate = null;
      _applicableFor = {_allResidentsOption.value};
      _dueDetails = null;
      _dueDetailsError = null;
      _loadingDueDetails = false;
    });
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
    String? paymentId,
    bool closeToFinanceOnAcknowledge = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final accentColor = isSuccess
            ? const Color(0xFF0F8F82)
            : const Color(0xFFB3261E);
        final accentIcon = isSuccess
            ? Icons.check_circle_rounded
            : Icons.error_rounded;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4FB),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.12),
                  blurRadius: 30,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(accentIcon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      if (paymentId != null && paymentId.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment ID',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                paymentId,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (closeToFinanceOnAcknowledge && mounted) {
      _closeToFinancePage();
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hintText,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: _brandColor, width: 1.4),
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

  Widget _buildTopBanner(bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F8F82), Color(0xFF14685D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 143, 130, 0.18),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: mobile ? double.infinity : 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.onBack != null)
                  TextButton.icon(
                    onPressed: widget.onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Finance'),
                  ),
                Text(
                  'Create New Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mobile ? 28 : 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure the payment cycle, audience, and collection rules. The due preview updates automatically as soon as the core billing fields are ready.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currency',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'INR Only',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Status will be set to ACTIVE on submit.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _brandTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildApplicableForField() {
    return FormField<Set<String>>(
      initialValue: _applicableFor,
      validator: (_) {
        if (_applicableFor.isEmpty) {
          return 'Applicable for is required';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                final selection = await _showApplicableForDialog();
                if (selection == null) {
                  return;
                }

                setState(() {
                  _applicableFor = selection.isEmpty
                      ? {_allResidentsOption.value}
                      : selection;
                });
                field.didChange(_applicableFor);
              },
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Applicable For',
                  suffix: const Icon(Icons.keyboard_arrow_down_rounded),
                ).copyWith(errorText: field.errorText),
                child: Text(
                  _buildApplicableForDisplayText(),
                  style: TextStyle(
                    color: _applicableFor.isEmpty
                        ? Colors.black45
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormColumn(bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 26),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDCEAE7)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 75, 69, 0.06),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(
              'Payment Details',
              'These values are sent to create the new apartment payment.',
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _paymentNameController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Payment Name',
                hintText: 'Maintenance Charges Q1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Payment name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shortDetailsController,
              minLines: 3,
              maxLines: 4,
              decoration: _inputDecoration(
                label: 'Short Details',
                hintText: 'Quarterly maintenance charges for society',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Short details are required';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            _buildSectionTitle(
              'Collection Setup',
              'These fields drive the live due amount preview on the right.',
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: mobile ? double.infinity : 280,
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentCapita,
                    decoration: _inputDecoration(label: 'Payment Capita'),
                    items: _capitaOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _paymentCapita = value;
                      _onDueFieldChanged();
                    },
                    validator: (value) =>
                        value == null ? 'Payment capita is required' : null,
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: TextFormField(
                    controller: _paymentAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _inputDecoration(
                      label: 'Payment Amount',
                      prefix: const Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (value) {
                      final normalized = _normalizeNumericValue(value ?? '');
                      final number = double.tryParse(normalized);
                      if (normalized.isEmpty || number == null || number <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 180,
                  child: TextFormField(
                    controller: _gstController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _inputDecoration(
                      label: 'GST',
                      suffix: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Icon(Icons.percent_rounded),
                      ),
                    ),
                    validator: (value) {
                      final normalized = _normalizeNumericValue(value ?? '');
                      final number = double.tryParse(normalized);
                      if (normalized.isEmpty || number == null || number < 0) {
                        return 'Enter GST';
                      }
                      if (number > 100) {
                        return 'GST cannot exceed 100';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 160,
                  child: TextFormField(
                    enabled: false,
                    initialValue: _currency,
                    decoration: _inputDecoration(label: 'Currency'),
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 240,
                  child: TextFormField(
                    controller: _collectionStartController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      label: 'Collection Start Date',
                      suffix: const Icon(Icons.calendar_today_rounded),
                    ),
                    onTap: _pickStartDate,
                    validator: (_) => _collectionStartDate == null
                        ? 'Start date is required'
                        : null,
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 240,
                  child: TextFormField(
                    controller: _collectionEndController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      label: 'Collection End Date',
                      suffix: const Icon(Icons.calendar_today_rounded),
                    ),
                    onTap: _pickEndDate,
                    validator: (_) => _collectionEndDate == null
                        ? 'End date is required'
                        : null,
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentCollectionCycle,
                    decoration: _inputDecoration(label: 'Collection Cycle'),
                    items: _cycleOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _paymentCollectionCycle = value;
                      _onDueFieldChanged();
                    },
                    validator: (value) =>
                        value == null ? 'Collection cycle is required' : null,
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentCollectionMode,
                    decoration: _inputDecoration(label: 'Collection Mode'),
                    items: _modeOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _paymentCollectionMode = value;
                      _onDueFieldChanged();
                    },
                    validator: (value) =>
                        value == null ? 'Collection mode is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildSectionTitle(
              'Audience And Settlement',
              'Select who the payment applies to and where the amount is collected.',
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: mobile ? double.infinity : 320,
                  child: _buildApplicableForField(),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentType,
                    decoration: _inputDecoration(label: 'Payment Type'),
                    items: _paymentTypeOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _paymentType = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Payment type is required' : null,
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 260,
                  child: DropdownButtonFormField<String>(
                    initialValue: _bankAccountId,
                    decoration: _inputDecoration(label: 'Bank Account'),
                    items: _bankAccountOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _bankAccountId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Bank account is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Status will be submitted as ACTIVE',
                    style: TextStyle(
                      color: _brandTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brandTextColor,
                        side: const BorderSide(color: _brandColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submitPayment,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_card_rounded),
                      label: Text(
                        _submitting ? 'Creating...' : 'Create Payment',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStat({
    required String label,
    required String value,
    Color backgroundColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _brandTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewColumn(bool mobile) {
    final dueDate = _dueDetails?['dueDate']?.toString().trim() ?? '--';
    final amountExcludingGst = _formatCurrencyValue(
      _dueDetails?['amountExcludingGst'],
    );
    final gstAmount = _formatCurrencyValue(_dueDetails?['gstAmount']);
    final amountIncludingGst = _formatCurrencyValue(
      _dueDetails?['amountIncludingGst'],
    );
    final gstPercent =
        _dueDetails?['gstPercent']?.toString().trim() ??
        _normalizeNumericValue(_gstController.text);

    return Container(
      padding: EdgeInsets.all(mobile ? 20 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD7EAE3)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 75, 69, 0.06),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE9FFF7), Color(0xFFFFF2D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upcoming Due Snapshot',
                  style: TextStyle(
                    color: _brandTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This panel refreshes whenever payment amount, GST, collection dates, cycle, mode, or capita changes.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD8E8E3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        color: _brandColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Upcoming Due Date: $dueDate',
                          style: const TextStyle(
                            color: _brandTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loadingDueDetails)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: _brandColor,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Calculating due amount details...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else if (_dueDetailsError != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1C8C5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB3261E),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueDetailsError!,
                      style: const TextStyle(
                        color: Color(0xFF8B1E1E),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_dueDetails == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE1ECE8)),
              ),
              child: const Text(
                'Complete payment amount, GST, dates, cycle, mode, and capita to load the due amount preview.',
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: _buildPreviewStat(
                    label: 'Amount Excluding GST',
                    value: amountExcludingGst,
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: _buildPreviewStat(
                    label: 'GST Amount',
                    value: gstAmount,
                    backgroundColor: const Color(0xFFFFF7E8),
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: _buildPreviewStat(
                    label: 'Amount Including GST',
                    value: amountIncludingGst,
                    backgroundColor: const Color(0xFFEFFFFA),
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: _buildPreviewStat(
                    label: 'GST Percent',
                    value: gstPercent.isEmpty ? '--' : '$gstPercent%',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE0EBE8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submission Summary',
                  style: TextStyle(
                    color: _brandTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryRow(label: 'Currency', value: _currency),
                _SummaryRow(
                  label: 'Collection Mode',
                  value:
                      _modeOptions
                          .cast<_PaymentChoice?>()
                          .firstWhere(
                            (option) => option?.value == _paymentCollectionMode,
                            orElse: () => null,
                          )
                          ?.label ??
                      '--',
                ),
                _SummaryRow(
                  label: 'Collection Cycle',
                  value:
                      _cycleOptions
                          .cast<_PaymentChoice?>()
                          .firstWhere(
                            (option) =>
                                option?.value == _paymentCollectionCycle,
                            orElse: () => null,
                          )
                          ?.label ??
                      '--',
                ),
                _SummaryRow(
                  label: 'Applicable For',
                  value: _buildApplicableForDisplayText(),
                ),
                _SummaryRow(
                  label: 'Payment Type',
                  value:
                      _paymentTypeOptions
                          .cast<_PaymentChoice?>()
                          .firstWhere(
                            (option) => option?.value == _paymentType,
                            orElse: () => null,
                          )
                          ?.label ??
                      '--',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool mobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBanner(mobile),
              const SizedBox(height: 24),
              if (mobile) ...[
                _buildFormColumn(true),
                const SizedBox(height: 18),
                _buildPreviewColumn(true),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildFormColumn(false)),
                    const SizedBox(width: 20),
                    Expanded(flex: 5, child: _buildPreviewColumn(false)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);

    if (widget.embedded) {
      return _buildContent(context, mobile);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brandColor,
        title: const Text('Create New Payment'),
      ),
      drawer: mobile
          ? Drawer(
              child: SideBar(
                selectedSection: AppSection.finance,
                onSectionSelected: (selectedSection) =>
                    openAppShellSection(context, selectedSection),
              ),
            )
          : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!mobile)
              SideBar(
                selectedSection: AppSection.finance,
                onSectionSelected: (selectedSection) =>
                    openAppShellSection(context, selectedSection),
              ),
            Expanded(child: _buildContent(context, mobile)),
          ],
        ),
      ),
    );
  }
}

class _PaymentChoice {
  const _PaymentChoice({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
