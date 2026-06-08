import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';
import 'home_page.dart' show PaymentDetailsModal;

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
  static const String _currency = 'INR';
  static const String _status = 'ACTIVE';
  static const int _maxAdditionalChargeRows = 5;

  static const List<_PaymentChoice> _capitaOptions = [
    _PaymentChoice(label: 'Per Flat', value: 'PER_FLAT'),
    _PaymentChoice(label: 'Per Head', value: 'PER_HEAD'),
    _PaymentChoice(label: 'Build Up Area', value: 'PER_SQFT'),
  ];

  static const List<_PaymentChoice> _cycleOptions = [
    _PaymentChoice(label: 'Once', value: 'ONCE'),
    _PaymentChoice(label: 'Monthly', value: 'MONTHLY'),
    _PaymentChoice(label: 'Quarterly', value: 'QUARTERLY'),
    _PaymentChoice(label: 'Half Yearly', value: 'HALF_YEARLY'),
    _PaymentChoice(label: 'Yearly', value: 'YEARLY'),
  ];

  static const List<_PaymentChoice> _modeOptions = [
    _PaymentChoice(label: 'Pre', value: 'PRE'),
    _PaymentChoice(label: 'Post', value: 'POST'),
  ];

  static const List<_PaymentChoice> _allowedPaymentModeOptions = [
    _PaymentChoice(label: 'CASH', value: 'CASH'),
    _PaymentChoice(label: 'CHEQUE', value: 'CHEQUE'),
    _PaymentChoice(
      label: 'OFFLINE BANK TRANSFER',
      value: 'OFFLINE_BANK_TRANSFER',
    ),
    _PaymentChoice(label: 'ONLINE', value: 'ONLINE'),
    _PaymentChoice(label: 'Credit Note', value: 'CREDIT_NOTE'),
    _PaymentChoice(label: 'QR Payment', value: 'QR_PAYMENT'),
  ];

  static const List<_PaymentChoice> _chargeTypeOptions = [
    _PaymentChoice(label: 'Amount', value: 'AMOUNT'),
    _PaymentChoice(label: 'Percentage', value: 'PERCENTAGE'),
  ];

  static const List<_PaymentChoice> _discountFineKindOptions = [
    _PaymentChoice(label: 'Discount', value: 'DISCOUNT'),
    _PaymentChoice(label: 'Fine', value: 'FINE'),
  ];

  static const List<_PaymentChoice> _discountFineTypeOptions = [
    _PaymentChoice(label: 'Simple', value: 'SIMPLE'),
    _PaymentChoice(label: 'Cumulative', value: 'CUMULATIVE'),
  ];

  static const List<_PaymentChoice> _discountFineCycleOptions = [
    _PaymentChoice(label: 'Monthly', value: 'MONTHLY'),
    _PaymentChoice(label: 'Quarterly', value: 'QUARTERLY'),
    _PaymentChoice(label: 'Half Yearly', value: 'HALF_YEARLY'),
    _PaymentChoice(label: 'Yearly', value: 'YEARLY'),
  ];

  static const List<_PaymentChoice> _paymentTypeOptions = [
    _PaymentChoice(label: 'Mandatory', value: 'MANDATORY'),
    _PaymentChoice(label: 'Optional', value: 'OPTIONAL'),
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
  final TextEditingController _customPaymentCauseController =
      TextEditingController();
  final List<_AdditionalChargeInput> _additionalChargeInputs = [];

  List<_SocietyCollectionType> _societyCollectionTypes = [];
  Map<String, _SocietyCollectionType> _societyCollectionTypeMap = {};
  bool _loadingSocietyCollectionTypes = false;
  bool _loadingBankAccounts = false;
  String? _paymentCauseTypeConstant;
  bool _isCustomPaymentCause = false;
  String? _paymentCapita;
  Set<String> _paymentCollectionCycles = <String>{};
  String? _paymentCollectionMode;
  Set<String> _allowedPaymentModes = <String>{};
  String? _paymentType;
  String? _bankAccountId;
  List<_PaymentChoice> _bankAccountOptions = const <_PaymentChoice>[];
  bool _isPartialPaymentAllowed = false;
  DateTime? _collectionStartDate;
  DateTime? _collectionEndDate;
  Set<String> _applicableFor = <String>{};
  List<_FlatSelectionNode> _applicableForOptions = const [];
  bool _loadingApplicableForOptions = false;
  bool _applicableForOptionsLoaded = false;
  String? _applicableForOptionsError;
  Map<String, dynamic>? _dueDetails;
  String? _dueDetailsError;
  bool _loadingDueDetails = false;
  bool _submitting = false;
  int _dueDetailsRequestId = 0;
  int _selectedDueCycleIndex = 0;
  int _selectedFlatTypeIndex = 0;
  Timer? _previewDebounce;
  final List<_AppliedDiscountFine> _appliedDiscountFines = [];
  final Set<String> _deletingDiscountFineIds = <String>{};
  final Set<String> _loadingDiscountFineIds = <String>{};
  bool _expandPaymentDetails = true;
  bool _expandCollectionSetup = true;
  bool _expandChargesAndAdjustments = true;
  bool _expandAudienceAndSettlement = true;
  String? _discountCycleNoticeText;
  bool _showDiscountCycleNotice = false;
  Timer? _discountCycleNoticeTimer;
  bool _loadingPayDues = false;

  bool get _isPerHeadCapita => _paymentCapita == 'PER_HEAD';

  bool get _isPaymentDetailsComplete {
    return _paymentNameController.text.trim().isNotEmpty &&
        _shortDetailsController.text.trim().isNotEmpty &&
        (_isCustomPaymentCause
            ? _customPaymentCauseController.text.trim().isNotEmpty
            : _paymentCauseTypeConstant != null) &&
        _paymentCapita != null;
  }

  bool get _isOnlyOnce =>
      _paymentCollectionCycles.length == 1 &&
      _paymentCollectionCycles.contains('ONCE');

  bool get _isCollectionDetailsComplete {
    final amount = double.tryParse(
      _normalizeNumericValue(_paymentAmountController.text),
    );
    final gst = double.tryParse(_normalizeNumericValue(_gstController.text));
    return _isPaymentDetailsComplete &&
        _collectionStartDate != null &&
        _collectionEndDate != null &&
        !_collectionEndDate!.isBefore(_collectionStartDate!) &&
        amount != null &&
        amount > 0 &&
        gst != null &&
        gst >= 0 &&
        gst <= 100 &&
        _paymentCollectionCycles.isNotEmpty &&
        _paymentCollectionMode != null &&
        _allowedPaymentModes.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _paymentAmountController.addListener(_scheduleDueDetailsRefresh);
    _gstController.addListener(_scheduleDueDetailsRefresh);
    _paymentNameController.addListener(_onSectionProgressChanged);
    _shortDetailsController.addListener(_onSectionProgressChanged);
    _fetchSocietyCollectionTypes();
    _fetchBankAccountOptions();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _discountCycleNoticeTimer?.cancel();
    for (final charge in _additionalChargeInputs) {
      charge.dispose();
    }
    _paymentNameController.dispose();
    _shortDetailsController.dispose();
    _paymentAmountController.dispose();
    _gstController.dispose();
    _collectionStartController.dispose();
    _collectionEndController.dispose();
    _customPaymentCauseController.dispose();
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
        response.containsKey('paymentId') ||
        response.containsKey('discFnId') ||
        response.containsKey('discFinId') ||
        response.containsKey('discFinList') ||
        response.containsKey('dueAmountDetailsEntityMap') ||
        response.containsKey('listOfDueAmountDetails') ||
        response.containsKey('flatTypeDueAmountDetails');
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

  String? _extractDiscFnId(Map<String, dynamic>? response) {
    if (response == null) {
      return null;
    }

    const candidates = [
      'discFnId',
      'discfnId',
      'discFinId',
      'discfinId',
      'id',
      'referenceId',
    ];
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

  String _formatUtcBoundaryDate(DateTime date, {required bool endOfDay}) {
    final utcDate = DateTime.utc(
      date.year,
      date.month,
      date.day,
      endOfDay ? 23 : 0,
      endOfDay ? 59 : 0,
      endOfDay ? 59 : 0,
    );

    final month = utcDate.month.toString().padLeft(2, '0');
    final day = utcDate.day.toString().padLeft(2, '0');
    final hour = utcDate.hour.toString().padLeft(2, '0');
    final minute = utcDate.minute.toString().padLeft(2, '0');
    final second = utcDate.second.toString().padLeft(2, '0');
    return '${utcDate.year}-$month-$day'
        'T$hour:$minute:$second'
        'Z';
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

  void _onSectionProgressChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _fetchSocietyCollectionTypes() async {
    if (_loadingSocietyCollectionTypes) {
      return;
    }

    setState(() {
      _loadingSocietyCollectionTypes = true;
    });

    try {
      final response = await ApiService.getSocietyCollectionTypes();
      if (!mounted) return;

      if (response != null && _isSuccessResponse(response)) {
        final rawList = response['societyCollectionTypes'];
        if (rawList is List) {
          final types = rawList.whereType<Map>().map((item) {
            final map = Map<String, dynamic>.from(item);
            return _SocietyCollectionType(
              collectionType: map['collectionType']?.toString() ?? '',
              purposeOfCollection: map['purposeOfCollection']?.toString() ?? '',
              sacCode: map['sacCode']?.toString() ?? '',
              taxable: map['taxable'] == true,
              typeConstant: map['typeConstant']?.toString() ?? '',
            );
          }).toList();

          final typeMap = <String, _SocietyCollectionType>{};
          for (final type in types) {
            typeMap[type.typeConstant] = type;
          }

          setState(() {
            _societyCollectionTypes = types;
            _societyCollectionTypeMap = typeMap;
          });
        }
      }
    } catch (_) {
      // Handle error silently or log it
    } finally {
      if (mounted) {
        setState(() {
          _loadingSocietyCollectionTypes = false;
        });
      }
    }
  }

  String _firstNonEmptyText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  List<_PaymentChoice> _extractBankAccountChoices(
    Map<String, dynamic>? response,
  ) {
    final payload = response ?? const <String, dynamic>{};
    dynamic rawList = payload['bankAccountDetails'];
    rawList ??= payload['bankDetails'];
    rawList ??= payload['bankAccounts'];
    rawList ??= payload['data'];

    if (rawList is! List) {
      return const <_PaymentChoice>[];
    }

    final seen = <String>{};
    final options = <_PaymentChoice>[];

    for (final entry in rawList.whereType<Map>()) {
      final item = Map<String, dynamic>.from(entry);
      final value = _firstNonEmptyText(item, [
        'BankDetailsID',
        'bankAccountId',
        'accountId',
        'bankId',
        'id',
        'accountNumber',
      ]);
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }

      final bankName = _firstNonEmptyText(item, ['bankName', 'bank', 'name']);
      final accountName = _firstNonEmptyText(item, ['accountName']);
      final accountNumber = _firstNonEmptyText(item, [
        'accountNumber',
        'accountNo',
      ]);

      var label = bankName;
      if (label.isEmpty) {
        label = accountName.isNotEmpty ? accountName : 'Bank Account';
      }

      final maskedAccount = accountNumber.isEmpty
          ? ''
          : 'XXXX${accountNumber.substring(accountNumber.length >= 4 ? accountNumber.length - 4 : 0)}';

      options.add(
        _PaymentChoice(
          label: label,
          value: value,
          trailingLabel: maskedAccount,
        ),
      );
    }

    return options;
  }

  Future<void> _fetchBankAccountOptions() async {
    if (_loadingBankAccounts) {
      return;
    }

    setState(() {
      _loadingBankAccounts = true;
    });

    try {
      final response = await ApiService.getBankDetails();
      if (!mounted) {
        return;
      }

      final messageCode = response?['messageCode']?.toString().trim() ?? '';
      if (!messageCode.toUpperCase().startsWith('SUCC_')) {
        return;
      }

      final options = _extractBankAccountChoices(response);
      if (options.isEmpty) {
        return;
      }

      final hasSelected = options.any((item) => item.value == _bankAccountId);

      setState(() {
        _bankAccountOptions = options;
        if (!hasSelected) {
          _bankAccountId = null;
        }
      });
    } catch (_) {
      // Ignore failures and keep existing options.
    } finally {
      if (mounted) {
        setState(() {
          _loadingBankAccounts = false;
        });
      }
    }
  }

  Widget _buildBankAccountDropdownItem(_PaymentChoice option) {
    final trailing = option.trailingLabel?.trim() ?? '';
    if (trailing.isEmpty) {
      return Text(option.label, overflow: TextOverflow.ellipsis);
    }

    return SizedBox(
      width: 260,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              trailing,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCauseDropdownItem(String collectionType, String sacCode) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: Text(collectionType, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('SAC CODE: $sacCode', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatCurrencyValueOrDash(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    if (value.isEmpty) {
      return '--';
    }

    final normalizedValue = value.startsWith('₹')
        ? value.substring(1).trim()
        : value;
    final formattedValue = _formatNumberWithCommas(normalizedValue);

    return '₹$formattedValue';
  }

  String _formatNumberWithCommas(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) {
      return value;
    }

    final isNegative = cleaned.startsWith('-');
    final unsigned = isNegative ? cleaned.substring(1) : cleaned;
    final parts = unsigned.split('.');
    final integerPart = parts.first;
    if (!RegExp(r'^\d+$').hasMatch(integerPart)) {
      return value;
    }

    String groupedInteger;
    if (integerPart.length <= 3) {
      groupedInteger = integerPart;
    } else {
      final lastThree = integerPart.substring(integerPart.length - 3);
      var remaining = integerPart.substring(0, integerPart.length - 3);
      final chunks = <String>[];

      while (remaining.length > 2) {
        chunks.insert(0, remaining.substring(remaining.length - 2));
        remaining = remaining.substring(0, remaining.length - 2);
      }
      if (remaining.isNotEmpty) {
        chunks.insert(0, remaining);
      }

      groupedInteger = '${chunks.join(',')},$lastThree';
    }

    final decimalPart = parts.length > 1 ? '.${parts.sublist(1).join('')}' : '';
    final sign = isNegative ? '-' : '';
    return '$sign$groupedInteger$decimalPart';
  }

  String _formatAsCurrencyForDues(String amount) {
    final cleaned = amount.trim();
    if (cleaned.isEmpty) {
      return '₹0';
    }

    final rawAmount = cleaned.startsWith('₹')
        ? cleaned.substring(1).trim()
        : cleaned;
    return '₹${_formatNumberWithCommas(rawAmount)}';
  }

  void _showPayDuesSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB3261E) : null,
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _dueDetailsByPaymentFromResponse(
    Map<String, dynamic>? response,
  ) {
    final rawDetails = response?['dueDetails'];
    if (rawDetails is! Map) {
      return const <String, List<Map<String, dynamic>>>{};
    }

    final result = <String, List<Map<String, dynamic>>>{};
    rawDetails.forEach((key, rawValue) {
      final list = <Map<String, dynamic>>[];

      if (rawValue is List) {
        for (final item in rawValue.whereType<Map>()) {
          list.add(Map<String, dynamic>.from(item));
        }
      } else if (rawValue is Map) {
        list.add(Map<String, dynamic>.from(rawValue));
      }

      if (list.isNotEmpty) {
        result[key.toString()] = list;
      }
    });

    return result;
  }

  List<Map<String, dynamic>> _flattenDueDetailsByPayment(
    Map<String, List<Map<String, dynamic>>> dueDetailsByPayment,
  ) {
    final flatList = <Map<String, dynamic>>[];
    for (final entries in dueDetailsByPayment.values) {
      for (final entry in entries) {
        flatList.add(Map<String, dynamic>.from(entry));
      }
    }
    return flatList;
  }

  // ignore: unused_element
  Future<void> _openDuePaymentsDialog() async {
    if (_loadingPayDues) return;

    setState(() {
      _loadingPayDues = true;
    });

    try {
      final response = await ApiService.getDueAmountForFlat();
      final duePaymentList = response?['duePaymentList'];
      final dueDetailsByPayment = _dueDetailsByPaymentFromResponse(response);
      if (!mounted) return;

      final normalizedDueList = duePaymentList is List
          ? duePaymentList
          : const <dynamic>[];
      final displayDueList = normalizedDueList.isNotEmpty
          ? normalizedDueList
          : _flattenDueDetailsByPayment(dueDetailsByPayment);

      if (displayDueList.isEmpty && dueDetailsByPayment.isEmpty) {
        _showPayDuesSnack('No due payments found.');
        return;
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _PayYourDuePage(
            duePaymentList: displayDueList,
            dueDetailsByPayment: dueDetailsByPayment,
            formatAsCurrency: _formatAsCurrencyForDues,
            onPaymentCompleted: () async {
              if (!mounted) return;
              _showPayDuesSnack('Payment completed successfully.');
            },
          ),
        ),
      );
    } catch (_) {
      _showPayDuesSnack('Unable to load due payment details.', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingPayDues = false;
      });
    }
  }

  List<_DueAmountDetail> _listOfDueAmountDetails(
    Map<String, dynamic>? response,
  ) {
    final rawList = response?['listOfDueAmountDetails'];
    if (rawList is! List) {
      return const [];
    }

    return rawList
        .whereType<Map>()
        .map(
          (entry) => _DueAmountDetail.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }

  List<_DueAmountCycleGroup> _dueAmountCycleGroups(
    Map<String, dynamic>? response,
  ) {
    final rawNestedMap = response?['dueAmountDetailsEntityMap'];
    if (rawNestedMap is Map) {
      final groups = <_DueAmountCycleGroup>[];

      for (final entry in rawNestedMap.entries) {
        final cycleLabel = entry.key.toString().trim();
        final rawCycleValue = entry.value;
        if (cycleLabel.isEmpty || rawCycleValue is! List) {
          continue;
        }

        final flatTypeDetails = <String, List<_DueAmountDetail>>{};
        for (final cycleItem in rawCycleValue.whereType<Map>()) {
          final mapEntry = Map<String, dynamic>.from(cycleItem);
          for (final flatEntry in mapEntry.entries) {
            final flatLabel = flatEntry.key.toString().trim();
            final rawDetails = flatEntry.value;
            if (flatLabel.isEmpty) {
              continue;
            }

            final details = <_DueAmountDetail>[];
            if (rawDetails is List) {
              details.addAll(
                rawDetails.whereType<Map>().map(
                  (item) =>
                      _DueAmountDetail.fromMap(Map<String, dynamic>.from(item)),
                ),
              );
            } else if (rawDetails is Map) {
              details.add(
                _DueAmountDetail.fromMap(Map<String, dynamic>.from(rawDetails)),
              );
            }

            if (details.isEmpty) {
              continue;
            }

            flatTypeDetails
                .putIfAbsent(flatLabel, () => <_DueAmountDetail>[])
                .addAll(details);
          }
        }

        if (flatTypeDetails.isNotEmpty) {
          groups.add(
            _DueAmountCycleGroup(
              cycleLabel: cycleLabel,
              flatTypeDetails: flatTypeDetails,
            ),
          );
        }
      }

      groups.sort(
        (left, right) => _compareCycleLabels(left.cycleLabel, right.cycleLabel),
      );
      return groups;
    }

    final flatTypeDetails = _flatTypeDueAmountDetails(response);
    if (flatTypeDetails.isNotEmpty) {
      return [
        _DueAmountCycleGroup(
          cycleLabel: 'ALL',
          flatTypeDetails: flatTypeDetails,
        ),
      ];
    }

    final details = _listOfDueAmountDetails(response);
    if (details.isNotEmpty) {
      return [
        _DueAmountCycleGroup(
          cycleLabel: 'ALL',
          flatTypeDetails: {'ALL': details},
        ),
      ];
    }

    return const [];
  }

  Map<String, List<_DueAmountDetail>> _flatTypeDueAmountDetails(
    Map<String, dynamic>? response,
  ) {
    final rawMap = response?['flatTypeDueAmountDetails'];
    if (rawMap is! Map) {
      return const {};
    }

    final result = <String, List<_DueAmountDetail>>{};
    for (final entry in rawMap.entries) {
      final key = entry.key.toString().trim();
      final value = entry.value;
      if (key.isEmpty || value is! List) {
        continue;
      }

      final details = value
          .whereType<Map>()
          .map(
            (item) => _DueAmountDetail.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
      if (details.isNotEmpty) {
        result[key] = details;
      }
    }

    return result;
  }

  _DueAmountDetail? _singleDueAmountDetail(Map<String, dynamic>? response) {
    if (response == null) {
      return null;
    }

    final detail = _DueAmountDetail.fromMap(response);
    if (detail.amount.isEmpty &&
        detail.totalAmount.isEmpty &&
        detail.gstAmount.isEmpty) {
      return null;
    }

    return detail;
  }

  List<_FlatTypeDueAmountItem> _activeFlatTypeDueAmountDetails(
    Map<String, dynamic>? response,
  ) {
    final cycleGroup = _selectedDueAmountCycleGroup(response);
    if (cycleGroup == null) {
      return const [];
    }

    final entries = <_FlatTypeDueAmountItem>[];

    final flatLabels = cycleGroup.flatTypeDetails.keys.toList()
      ..sort(_compareNaturalValues);

    for (final flatLabel in flatLabels) {
      final activeDetail = _resolveNextUpcomingDueDetail(
        cycleGroup.flatTypeDetails[flatLabel] ?? const [],
      );
      if (activeDetail == null) {
        continue;
      }

      entries.add(
        _FlatTypeDueAmountItem(flatLabel: flatLabel, detail: activeDetail),
      );
    }

    return entries;
  }

  _DueAmountDetail? _resolveNextUpcomingDueDetail(
    List<_DueAmountDetail> details,
  ) {
    final activeDetails = details
        .where(
          (detail) =>
              detail.status.isEmpty || detail.status.toUpperCase() == 'ACTIVE',
        )
        .toList();
    if (activeDetails.isEmpty) {
      return null;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    activeDetails.sort((left, right) {
      final leftDate = left.dueDate;
      final rightDate = right.dueDate;

      if (leftDate == null && rightDate == null) {
        return 0;
      }
      if (leftDate == null) {
        return 1;
      }
      if (rightDate == null) {
        return -1;
      }

      final leftIsFutureOrToday = !leftDate.isBefore(normalizedToday);
      final rightIsFutureOrToday = !rightDate.isBefore(normalizedToday);

      if (leftIsFutureOrToday != rightIsFutureOrToday) {
        return leftIsFutureOrToday ? -1 : 1;
      }

      return leftDate.compareTo(rightDate);
    });

    return activeDetails.first;
  }

  int _compareCycleLabels(String left, String right) {
    const cycleOrder = ['MONTHLY', 'QUATERLY', 'HALF YEARLY', 'YEARLY'];

    final leftIndex = cycleOrder.indexOf(left.toUpperCase());
    final rightIndex = cycleOrder.indexOf(right.toUpperCase());
    if (leftIndex != -1 || rightIndex != -1) {
      if (leftIndex == -1) {
        return 1;
      }
      if (rightIndex == -1) {
        return -1;
      }

      final comparison = leftIndex.compareTo(rightIndex);
      if (comparison != 0) {
        return comparison;
      }
    }

    return _compareNaturalValues(left, right);
  }

  int _compareNaturalValues(String left, String right) {
    final leftParts = RegExp(r'\d+|\D+').allMatches(left);
    final rightParts = RegExp(r'\d+|\D+').allMatches(right);
    final maxLength = leftParts.length < rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxLength; index++) {
      final leftPart = leftParts.elementAt(index).group(0) ?? '';
      final rightPart = rightParts.elementAt(index).group(0) ?? '';
      final leftNumber = int.tryParse(leftPart);
      final rightNumber = int.tryParse(rightPart);

      if (leftNumber != null && rightNumber != null) {
        final comparison = leftNumber.compareTo(rightNumber);
        if (comparison != 0) {
          return comparison;
        }
        continue;
      }

      final comparison = leftPart.toLowerCase().compareTo(
        rightPart.toLowerCase(),
      );
      if (comparison != 0) {
        return comparison;
      }
    }

    return left.length.compareTo(right.length);
  }

  int _resolvedFlatTypeIndex(int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }

    if (_selectedFlatTypeIndex < 0) {
      return 0;
    }

    if (_selectedFlatTypeIndex >= itemCount) {
      return itemCount - 1;
    }

    return _selectedFlatTypeIndex;
  }

  int _resolvedDueCycleIndex(int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }

    if (_selectedDueCycleIndex < 0) {
      return 0;
    }

    if (_selectedDueCycleIndex >= itemCount) {
      return itemCount - 1;
    }

    return _selectedDueCycleIndex;
  }

  _DueAmountCycleGroup? _selectedDueAmountCycleGroup(
    Map<String, dynamic>? response,
  ) {
    final groups = _dueAmountCycleGroups(response);
    if (groups.isEmpty) {
      return null;
    }

    return groups[_resolvedDueCycleIndex(groups.length)];
  }

  List<_DueAmountCycleGroup> _availableDueAmountCycleGroups(
    Map<String, dynamic>? response,
  ) {
    return _dueAmountCycleGroups(response);
  }

  String _formatCycleLabel(String value) {
    final normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'MONTHLY':
        return 'Monthly';
      case 'QUATERLY':
        return 'Quarterly';
      case 'HALF YEARLY':
        return 'Half Yearly';
      case 'YEARLY':
        return 'Yearly';
      case 'ALL':
        return 'All';
      default:
        return value;
    }
  }

  _DueAmountDetail? _resolveUpcomingDueDetail(Map<String, dynamic>? response) {
    final selectedCycleGroup = _selectedDueAmountCycleGroup(response);
    if (selectedCycleGroup != null) {
      final flatTypeItems = selectedCycleGroup.flatTypeDetails.entries.toList()
        ..sort((left, right) => _compareNaturalValues(left.key, right.key));

      if (flatTypeItems.isNotEmpty) {
        final selectedFlatIndex = _resolvedFlatTypeIndex(flatTypeItems.length);
        final selectedFlatItem = flatTypeItems[selectedFlatIndex];
        final detail = _resolveNextUpcomingDueDetail(selectedFlatItem.value);
        if (detail != null) {
          return detail;
        }

        for (final item in flatTypeItems) {
          final fallback = _resolveNextUpcomingDueDetail(item.value);
          if (fallback != null) {
            return fallback;
          }
        }
      }
    }

    final details = _listOfDueAmountDetails(response);
    if (details.isEmpty) {
      return _singleDueAmountDetail(response);
    }

    final selected = _resolveNextUpcomingDueDetail(details);
    if (selected != null) {
      return selected;
    }

    return details.first;
  }

  String _formatDueDateValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '--' : trimmed;
  }

  static DateTime? _parseStaticDueDate(String? value) {
    final trimmed = value?.trim() ?? '';
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

  String _buildApplicableForDisplayText() {
    if (_loadingApplicableForOptions) {
      return 'Loading flats...';
    }

    if (_applicableFor.isEmpty) {
      return 'Select flats';
    }

    if (_areAllFlatsSelected) {
      return 'All Flats';
    }

    final selected = _applicableFor.toList()..sort();
    if (selected.length <= 3) {
      return selected.join(', ');
    }

    return '${selected.length} flats selected';
  }

  List<String> _buildApplicableForRequestValue() {
    final selected = _applicableFor.toList()..sort();
    return selected;
  }

  Set<String> get _allApplicableFlatIds {
    return _collectFlatIds(_applicableForOptions).toSet();
  }

  bool get _areAllFlatsSelected {
    final allFlatIds = _allApplicableFlatIds;
    return allFlatIds.isNotEmpty && _applicableFor.containsAll(allFlatIds);
  }

  List<String> _buildAllowedPaymentModesRequestValue() {
    final selected = _allowedPaymentModes.toList()..sort();
    return selected;
  }

  List<String> _buildPaymentCollectionCyclesRequestValue() {
    return _cycleOptions
        .where((option) => _paymentCollectionCycles.contains(option.value))
        .map((option) => _mapCollectionCycleForRequest(option.value))
        .toList();
  }

  List<_DiscountCycleOption> _buildDiscountCycleOptionsForSelection(
    Set<String> selectedCollectionCycles,
  ) {
    final selectedOptions = _cycleOptions
        .where((option) => selectedCollectionCycles.contains(option.value))
        .toList();

    return [
      for (final option in selectedOptions)
        _DiscountCycleOption(
          cycle: option.value,
          sourceCycle: option.value,
          label: option.label,
        ),
    ];
  }

  List<_DiscountCycleOption> _buildDiscountCycleOptionsForCurrentSelection() {
    return _buildDiscountCycleOptionsForSelection(_paymentCollectionCycles);
  }

  void _syncDiscountCyclesAfterCollectionCycleChange(
    Set<String> previousSelection,
    Set<String> updatedSelection,
  ) {
    if (previousSelection.length == updatedSelection.length &&
        previousSelection.containsAll(updatedSelection)) {
      return;
    }

    final discount = _appliedDiscountFineByKind('DISCOUNT');
    if (discount == null || discount.cycleDiscounts.isEmpty) {
      return;
    }

    final allowedCycles = _buildDiscountCycleOptionsForSelection(
      updatedSelection,
    ).map((entry) => entry.cycle).toSet();
    final removedCycles = discount.cycleDiscounts
        .where((entry) => !allowedCycles.contains(entry.cycle))
        .map((entry) => entry.cycle)
        .toSet();
    final retainedRows = discount.cycleDiscounts
        .where((entry) => allowedCycles.contains(entry.cycle))
        .toList();
    final removedCount = discount.cycleDiscounts.length - retainedRows.length;
    if (removedCount <= 0) {
      return;
    }

    setState(() {
      _appliedDiscountFines.removeWhere((entry) => entry.kind == 'DISCOUNT');
      _appliedDiscountFines.add(
        discount.copyWith(cycleDiscounts: retainedRows),
      );
      _appliedDiscountFines.sort(
        (left, right) => left.kind.compareTo(right.kind),
      );
    });

    final removedCycleLabels = removedCycles.map(_collectionCycleLabel).toList()
      ..sort();
    final noticeText = removedCycleLabels.length == 1
        ? '${removedCycleLabels.first} removed from discount because the cycle was unselected.'
        : '${removedCycleLabels.join(', ')} removed from discount because these cycles were unselected.';
    _triggerDiscountCycleNotice(noticeText);
  }

  String _collectionCycleLabel(String value) {
    for (final option in _cycleOptions) {
      if (option.value == value) {
        return option.label;
      }
    }
    return value;
  }

  void _triggerDiscountCycleNotice(String message) {
    _discountCycleNoticeTimer?.cancel();
    if (!mounted) {
      return;
    }

    setState(() {
      _discountCycleNoticeText = message;
      _showDiscountCycleNotice = true;
    });

    _discountCycleNoticeTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showDiscountCycleNotice = false;
      });
    });
  }

  String _buildAllowedPaymentModesDisplayText() {
    if (_allowedPaymentModes.isEmpty) {
      return 'Select modes';
    }

    final selected = _allowedPaymentModes.toList()..sort();
    if (selected.length <= 2) {
      return selected.map((item) => item.replaceAll('_', ' ')).join(', ');
    }

    return '${selected.length} modes selected';
  }

  String _buildPaymentCollectionCyclesDisplayText() {
    if (_paymentCollectionCycles.isEmpty) {
      return 'Select cycles';
    }

    final selectedLabels = _cycleOptions
        .where((option) => _paymentCollectionCycles.contains(option.value))
        .map((option) => option.label)
        .toList();
    if (selectedLabels.length <= 2) {
      return selectedLabels.join(', ');
    }

    return '${selectedLabels.length} cycles selected';
  }

  Future<void> _openAllowedPaymentModesDialog(
    FormFieldState<Set<String>> field,
  ) async {
    final selection = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => _AllowedPaymentModesDialog(
        options: _allowedPaymentModeOptions,
        initialSelection: _allowedPaymentModes,
      ),
    );

    if (selection == null) {
      return;
    }

    final validValues = _allowedPaymentModeOptions
        .map((option) => option.value)
        .toSet();
    setState(() {
      _allowedPaymentModes = selection.intersection(validValues);
    });
    field.didChange(_allowedPaymentModes);
    field.validate();
  }

  Future<void> _openCollectionCyclesDialog(
    FormFieldState<Set<String>> field,
  ) async {
    final previousSelection = Set<String>.from(_paymentCollectionCycles);
    final selection = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => _CollectionCyclesDialog(
        options: _cycleOptions,
        initialSelection: _paymentCollectionCycles,
      ),
    );

    if (selection == null) {
      return;
    }

    final validValues = _cycleOptions.map((option) => option.value).toSet();
    final updatedSelection = selection.intersection(validValues);
    setState(() {
      _paymentCollectionCycles = updatedSelection;
    });
    _syncDiscountCyclesAfterCollectionCycleChange(
      previousSelection,
      updatedSelection,
    );
    field.didChange(_paymentCollectionCycles);
    field.validate();
    _onDueFieldChanged();
  }

  String _mapCollectionCycleForRequest(String value) {
    switch (value) {
      case 'ONCE':
        return 'once';
      case 'MONTHLY':
        return 'monthly';
      case 'QUARTERLY':
        return 'quarterly';
      case 'HALF_YEARLY':
        return 'halfyearly';
      case 'YEARLY':
        return 'yearly';
      default:
        return value.toLowerCase().replaceAll('_', '');
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
        _paymentCollectionCycles.isNotEmpty &&
        _paymentCollectionMode != null &&
        _collectionStartDate != null &&
        _collectionEndDate != null;
  }

  void _handleAdditionalChargeChanged(
    _AdditionalChargeInput charge, {
    required bool valueChanged,
  }) {
    final normalizedValue = _normalizeNumericValue(charge.valueController.text);
    final hadValue = charge.lastNormalizedValue.isNotEmpty;
    charge.lastNormalizedValue = normalizedValue;

    if (!valueChanged && normalizedValue.isEmpty) {
      return;
    }

    if (valueChanged && normalizedValue.isEmpty && !hadValue) {
      return;
    }

    _scheduleDueDetailsRefresh();
  }

  void _addAdditionalChargeRow() {
    if (_additionalChargeInputs.length >= _maxAdditionalChargeRows) {
      return;
    }

    final charge = _AdditionalChargeInput();
    charge.nameController.addListener(
      () => _handleAdditionalChargeChanged(charge, valueChanged: false),
    );
    charge.valueController.addListener(
      () => _handleAdditionalChargeChanged(charge, valueChanged: true),
    );

    setState(() {
      _additionalChargeInputs.add(charge);
    });
  }

  void _removeAdditionalChargeRow(int index) {
    if (index < 0 || index >= _additionalChargeInputs.length) {
      return;
    }

    final charge = _additionalChargeInputs.removeAt(index);
    charge.dispose();
    setState(() {});
    _scheduleDueDetailsRefresh();
  }

  bool _isAdditionalChargeRowEmpty(_AdditionalChargeInput charge) {
    return charge.nameController.text.trim().isEmpty &&
        charge.chargeType == null &&
        _normalizeNumericValue(charge.valueController.text).isEmpty;
  }

  String _mapChargeTypeForRequest(String chargeType) {
    switch (chargeType) {
      case 'PERCENTAGE':
        return 'percentage';
      case 'AMOUNT':
      default:
        return 'amount';
    }
  }

  String _formatDecimalValue(double value) {
    final formatted = value.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    if (formatted.endsWith('0')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  String _calculateFinalChargeValue(String rawValue) {
    final value = double.tryParse(rawValue) ?? 0;
    final gstPercent =
        double.tryParse(_normalizeNumericValue(_gstController.text)) ?? 0;
    final finalValue = value + ((value * gstPercent) / 100);
    return _formatDecimalValue(finalValue);
  }

  List<Map<String, dynamic>> _buildAdditionalChargesRequest() {
    final charges = <Map<String, dynamic>>[];

    for (final charge in _additionalChargeInputs) {
      final name = charge.nameController.text.trim();
      final value = _normalizeNumericValue(charge.valueController.text);
      final type = charge.chargeType;
      if (name.isEmpty || value.isEmpty || type == null) {
        continue;
      }

      charges.add({
        'chargeName': name,
        'chargeType': _mapChargeTypeForRequest(type),
        'value': value,
        'finalChargeValue': _calculateFinalChargeValue(value),
      });
    }

    return charges;
  }

  void _resetDueDetailsState({String? error}) {
    _dueDetailsRequestId++;
    setState(() {
      _loadingDueDetails = false;
      _dueDetails = null;
      _dueDetailsError = error;
      _selectedDueCycleIndex = 0;
      _selectedFlatTypeIndex = 0;
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
      'paymentCollectionCycleList': _buildPaymentCollectionCyclesRequestValue(),
      'paymentCollectionMode': _paymentCollectionMode!.toLowerCase(),
      'paymentCapita': _paymentCapita,
      'addedCharges': _buildAdditionalChargesRequest(),
      'addLeftOverPayment': true,
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
        _selectedDueCycleIndex = 0;
        _selectedFlatTypeIndex = 0;
      } else {
        _dueDetails = null;
        _dueDetailsError = _responseMessage(response);
        _selectedDueCycleIndex = 0;
        _selectedFlatTypeIndex = 0;
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

  Future<bool> _ensureApplicableForOptionsLoaded({
    bool forceRefresh = false,
  }) async {
    if (_loadingApplicableForOptions) {
      return false;
    }

    if (_applicableForOptionsLoaded && !forceRefresh) {
      return true;
    }

    setState(() {
      _loadingApplicableForOptions = true;
      _applicableForOptionsError = null;
    });

    try {
      final response = await ApiService.getAllFlats();
      if (!mounted) {
        return false;
      }

      if (response == null || !_isSuccessResponse(response)) {
        setState(() {
          _applicableForOptionsLoaded = false;
          _applicableForOptions = const [];
          _applicableFor = <String>{};
          _applicableForOptionsError = _responseMessage(response);
        });
        return false;
      }

      final options = _buildApplicableForNodes(response);
      final allFlatIds = _collectFlatIds(options).toSet();

      setState(() {
        _applicableForOptionsLoaded = true;
        _applicableForOptions = options;
        _applicableForOptionsError = options.isEmpty
            ? 'No flats were returned for this apartment.'
            : null;
        _applicableFor = _applicableFor.intersection(allFlatIds);
        if (_applicableFor.isEmpty) {
          _applicableFor = Set<String>.from(allFlatIds);
        }
      });
      return options.isNotEmpty;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _applicableForOptionsLoaded = false;
        _applicableForOptions = const [];
        _applicableForOptionsError = 'Unable to load the flat list right now.';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _loadingApplicableForOptions = false;
        });
      }
    }
  }

  Future<void> _openApplicableForDialog(
    FormFieldState<Set<String>> field,
  ) async {
    final loaded = await _ensureApplicableForOptionsLoaded();
    if (!mounted) {
      return;
    }

    if (!loaded) {
      field.validate();
      return;
    }

    final selection = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => _ApplicableForDialog(
        nodes: _applicableForOptions,
        initialSelection: _applicableFor,
      ),
    );

    if (selection == null) {
      return;
    }

    final validSelection = selection.intersection(_allApplicableFlatIds);
    setState(() {
      _applicableFor = validSelection;
      _applicableForOptionsError = null;
    });
    field.didChange(_applicableFor);
    field.validate();
  }

  List<_FlatSelectionNode> _buildApplicableForNodes(
    Map<String, dynamic> response,
  ) {
    final nodes = <_FlatSelectionNode>[];
    final blockList = _asMapList(response['blockList']);
    for (var index = 0; index < blockList.length; index++) {
      nodes.addAll(_nodesFromBlock(blockList[index], 'block_$index'));
    }

    final towerList = _asMapList(response['towerList']);
    for (var index = 0; index < towerList.length; index++) {
      nodes.addAll(_nodesFromTower(towerList[index], 'top_tower_$index'));
    }

    return _sortFlatSelectionNodesRecursively(nodes);
  }

  List<_FlatSelectionNode> _sortFlatSelectionNodesRecursively(
    List<_FlatSelectionNode> nodes,
  ) {
    final sorted = nodes
        .map(
          (node) => _FlatSelectionNode(
            key: node.key,
            label: node.label,
            flatId: node.flatId,
            children: _sortFlatSelectionNodesRecursively(node.children),
          ),
        )
        .toList();

    sorted.sort(
      (left, right) => _compareNaturalValues(left.label, right.label),
    );
    return sorted;
  }

  List<_FlatSelectionNode> _nodesFromBlock(
    Map<String, dynamic> block,
    String keyBase,
  ) {
    final blockName = _safeText(block['blockName']);
    final flatChildren = _flatLeafNodes(
      _asStringList(block['flatList']),
      '$keyBase-flat',
    );
    final towerChildren = <_FlatSelectionNode>[];
    final towerList = _asMapList(block['towerList']);
    for (var index = 0; index < towerList.length; index++) {
      towerChildren.addAll(
        _nodesFromTower(towerList[index], '$keyBase-tower_$index'),
      );
    }

    final children = [...flatChildren, ...towerChildren];
    if (blockName.isEmpty) {
      return children;
    }

    if (children.isEmpty) {
      return const [];
    }

    return [
      _FlatSelectionNode(
        key: keyBase,
        label: 'Block $blockName',
        children: children,
      ),
    ];
  }

  List<_FlatSelectionNode> _nodesFromTower(
    Map<String, dynamic> tower,
    String keyBase,
  ) {
    final towerName = _safeText(tower['towerName']);
    final flatChildren = _flatLeafNodes(
      _asStringList(tower['flatList']),
      '$keyBase-flat',
    );

    if (towerName.isEmpty) {
      return flatChildren;
    }

    if (flatChildren.isEmpty) {
      return const [];
    }

    return [
      _FlatSelectionNode(
        key: keyBase,
        label: towerName,
        children: flatChildren,
      ),
    ];
  }

  List<_FlatSelectionNode> _flatLeafNodes(
    List<String> flatIds,
    String keyBase,
  ) {
    return [
      for (var index = 0; index < flatIds.length; index++)
        _FlatSelectionNode(
          key: '$keyBase-$index',
          label: flatIds[index],
          flatId: flatIds[index],
        ),
    ];
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList()
      ..sort(_compareNaturalValues);
  }

  String _safeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.toLowerCase() == 'null' ? '' : text;
  }

  List<String> _collectFlatIds(List<_FlatSelectionNode> nodes) {
    final flatIds = <String>[];
    for (final node in nodes) {
      flatIds.addAll(node.flatIds);
    }
    return flatIds;
  }

  _AppliedDiscountFine? _appliedDiscountFineByKind(String kind) {
    for (final item in _appliedDiscountFines) {
      if (item.kind == kind) {
        return item;
      }
    }
    return null;
  }

  String? get _nextDiscountFineKind {
    final hasDiscount = _appliedDiscountFineByKind('DISCOUNT') != null;
    final hasFine = _appliedDiscountFineByKind('FINE') != null;

    if (!hasDiscount && !hasFine) {
      return null;
    }
    if (hasDiscount && !hasFine) {
      return 'FINE';
    }
    if (!hasDiscount && hasFine) {
      return 'DISCOUNT';
    }
    return null;
  }

  String get _discountFineButtonLabel {
    final nextKind = _nextDiscountFineKind;
    if (nextKind == 'DISCOUNT') {
      return 'Add Discount';
    }
    if (nextKind == 'FINE') {
      return 'Add Fine';
    }
    if (_appliedDiscountFineByKind('DISCOUNT') != null &&
        _appliedDiscountFineByKind('FINE') != null) {
      return 'Discount/Fine Added';
    }
    return 'Add Discount/Fine';
  }

  bool get _canAddDiscountFine {
    return !(_appliedDiscountFineByKind('DISCOUNT') != null &&
        _appliedDiscountFineByKind('FINE') != null);
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
        'cause': _isCustomPaymentCause
            ? _customPaymentCauseController.text.trim()
            : _paymentCauseTypeConstant,
        'paymentCapita': _paymentCapita,
        'paymentAmount': amount,
        'gst': gst,
        'currency': _currency,
        'collectionStartDate': _formatRequestStartDate(startDate),
        'collectionEndDate': _formatRequestEndDate(endDate),
        'paymentCollectionCycleList':
            _buildPaymentCollectionCyclesRequestValue(),
        'paymentCollectionMode': _paymentCollectionMode,
        'allowedPaymentModes': _buildAllowedPaymentModesRequestValue(),
        'addedCharges': _buildAdditionalChargesRequest(),
        'addLeftOverPayment': true,
        'applicableFor': _buildApplicableForRequestValue(),
        'paymentType': _paymentType,
        'bankAccountId': _bankAccountId,
        'partialPaymentAllowed': _isPartialPaymentAllowed,
        'discountCode': _appliedDiscountFineByKind('DISCOUNT')?.discFnId ?? '',
        'fineCode': _appliedDiscountFineByKind('FINE')?.discFnId ?? '',
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

  Future<_DiscountFineSubmitResult> _createDiscountFine(
    _DiscountFineDraft draft,
  ) async {
    final header = _buildGenericHeader();
    if (header == null) {
      return const _DiscountFineSubmitResult(
        isSuccess: false,
        message: 'User session details are missing. Please log in again.',
      );
    }

    final requestBody = <String, dynamic>{
      'genericHeader': header,
      'discFnType': draft.kind,
      'dueDateAsStartDateFlag': draft.isFine ? draft.dueDateAsStartDate : false,
      'discFnStrtDt': _formatUtcBoundaryDate(draft.startDate, endOfDay: false),
      'discFnEndDt': _formatUtcBoundaryDate(draft.endDate, endOfDay: false),
      'discFnMode': draft.mode,
      'discFnValue': draft.value,
      'discFnCycleType': draft.isFine ? draft.calculationType : null,
    };

    if (draft.isFine) {
      requestBody['discFnCumlatonCycle'] = draft.calculationType == 'CUMULATIVE'
          ? draft.cumulationCycle
          : null;
    } else {
      requestBody['discFinCycleDiscountList'] = draft.cycleDiscounts
          .map(
            (item) => {
              'cycle': item.cycle,
              'type': item.type == 'PERCENTAGE' ? 'PERCENTAGE' : 'FIXED_AMOUNT',
              'value': item.value,
            },
          )
          .toList();

      final minimumPaymentAmount = draft.minimumPaymentAmount;
      if (minimumPaymentAmount != null && minimumPaymentAmount.isNotEmpty) {
        requestBody['minimumPaymentAmount'] = minimumPaymentAmount;
      }
    }

    try {
      final response = await ApiService.addDiscfin(requestBody);
      final isSuccess = _isSuccessResponse(response);
      final message = _responseMessage(response);
      final discFnId = _extractDiscFnId(response) ?? '';

      return _DiscountFineSubmitResult(
        isSuccess: isSuccess,
        message: message,
        appliedDiscountFine: isSuccess
            ? _AppliedDiscountFine(
                kind: draft.kind,
                discFnId: discFnId,
                mode: draft.mode,
                value: draft.value,
                calculationType: draft.calculationType,
                dueDateAsStartDate: draft.isFine
                    ? draft.dueDateAsStartDate
                    : false,
                startDateText: _formatUtcBoundaryDate(
                  draft.startDate,
                  endOfDay: false,
                ),
                endDateText: _formatUtcBoundaryDate(
                  draft.endDate,
                  endOfDay: true,
                ),
                cumulationCycle: draft.cumulationCycle,
                cycleDiscounts: draft.cycleDiscounts,
                minimumPaymentAmount: draft.minimumPaymentAmount,
              )
            : null,
      );
    } catch (_) {
      return const _DiscountFineSubmitResult(
        isSuccess: false,
        message: 'Unable to create the discount/fine right now.',
      );
    }
  }

  Future<void> _openDiscountFineDialog(String initialKind) async {
    final lockedKind = _nextDiscountFineKind;
    final appliedDiscountFine = await showDialog<_AppliedDiscountFine>(
      context: context,
      builder: (dialogContext) => _DiscountFineDialog(
        initialKind: lockedKind ?? initialKind,
        kindLocked: lockedKind != null,
        availableCollectionCycles:
            _buildDiscountCycleOptionsForCurrentSelection(),
        onSubmit: _createDiscountFine,
      ),
    );

    if (!mounted || appliedDiscountFine == null) {
      return;
    }

    setState(() {
      _appliedDiscountFines.removeWhere(
        (item) => item.kind == appliedDiscountFine.kind,
      );
      _appliedDiscountFines.add(appliedDiscountFine);
      _appliedDiscountFines.sort(
        (left, right) => left.kind.compareTo(right.kind),
      );
    });
  }

  Future<void> _deleteDiscountFine(_AppliedDiscountFine item) async {
    if (_deletingDiscountFineIds.contains(item.discFnId)) {
      return;
    }

    final header = _buildGenericHeader();
    if (header == null) {
      await _showResultDialog(
        title: 'Delete Discount/Fine Failed',
        message: 'User session details are missing. Please log in again.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _deletingDiscountFineIds.add(item.discFnId);
    });

    try {
      final response = await ApiService.deleteDiscfin({
        'genericHeader': header,
        'discFinId': item.discFnId,
      });

      if (!mounted) {
        return;
      }

      if (_isSuccessResponse(response)) {
        setState(() {
          _appliedDiscountFines.removeWhere(
            (entry) => entry.discFnId == item.discFnId,
          );
        });
        return;
      }

      await _showResultDialog(
        title: 'Delete Discount/Fine Failed',
        message: _responseMessage(response),
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _showResultDialog(
        title: 'Delete Discount/Fine Failed',
        message: 'Unable to delete the discount/fine right now.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingDiscountFineIds.remove(item.discFnId);
        });
      }
    }
  }

  Future<void> _openDiscountFineDetails(_AppliedDiscountFine item) async {
    if (_loadingDiscountFineIds.contains(item.discFnId)) {
      return;
    }

    final header = _buildGenericHeader();
    if (header == null) {
      await _showResultDialog(
        title: 'Load Discount/Fine Failed',
        message: 'User session details are missing. Please log in again.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _loadingDiscountFineIds.add(item.discFnId);
    });

    try {
      final response = await ApiService.getDiscfin({
        'genericHeader': header,
        'discFinId': item.discFnId,
      });

      if (!mounted) {
        return;
      }

      if (!_isSuccessResponse(response)) {
        await _showResultDialog(
          title: 'Load Discount/Fine Failed',
          message: _responseMessage(response),
          isSuccess: false,
        );
        return;
      }

      final detail = _DiscountFineDetail.fromResponse(response, item);
      if (detail == null) {
        await _showResultDialog(
          title: 'Load Discount/Fine Failed',
          message: 'No matching discount/fine details were returned.',
          isSuccess: false,
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _DiscountFineDetailsDialog(detail: detail),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _showResultDialog(
        title: 'Load Discount/Fine Failed',
        message: 'Unable to load the discount/fine details right now.',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingDiscountFineIds.remove(item.discFnId);
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
    _customPaymentCauseController.clear();
    for (final charge in _additionalChargeInputs) {
      charge.dispose();
    }
    setState(() {
      _additionalChargeInputs.clear();
      _paymentCauseTypeConstant = null;
      _isCustomPaymentCause = false;
      _paymentCapita = null;
      _paymentCollectionCycles = <String>{};
      _paymentCollectionMode = null;
      _allowedPaymentModes = <String>{};
      _paymentType = null;
      _bankAccountId = null;
      _isPartialPaymentAllowed = false;
      _collectionStartDate = null;
      _collectionEndDate = null;
      _applicableFor = Set<String>.from(_allApplicableFlatIds);
      _dueDetails = null;
      _dueDetailsError = null;
      _loadingDueDetails = false;
      _appliedDiscountFines.clear();
      _deletingDiscountFineIds.clear();
      _loadingDiscountFineIds.clear();
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
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
      prefixIcon: prefix,
      suffixIcon: suffix,
      floatingLabelBehavior: FloatingLabelBehavior.always,
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

  Widget _buildCollapsibleFormSection({
    required String title,
    required String subtitle,
    required bool expanded,
    required bool enabled,
    required ValueChanged<bool> onExpansionChanged,
    required Widget child,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCEAE7)),
          ),
          child: ExpansionTile(
            initiallyExpanded: expanded,
            onExpansionChanged: onExpansionChanged,
            collapsedShape: const RoundedRectangleBorder(),
            shape: const RoundedRectangleBorder(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            title: _buildSectionTitle(title, subtitle),
            children: [child],
          ),
        ),
      ),
    );
  }

  Widget _buildThreeFieldRow({
    required Widget first,
    required Widget second,
    required Widget third,
    int firstFlex = 5,
    int secondFlex = 4,
    int thirdFlex = 3,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: firstFlex, child: first),
        const SizedBox(width: 16),
        Expanded(flex: secondFlex, child: second),
        const SizedBox(width: 16),
        Expanded(flex: thirdFlex, child: third),
      ],
    );
  }

  Widget _buildTwoFieldRow({required Widget first, required Widget second}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildAdditionalChargesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed:
                _additionalChargeInputs.length >= _maxAdditionalChargeRows
                ? null
                : _addAdditionalChargeRow,
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandColor,
              side: const BorderSide(color: _brandColor),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Tax'),
          ),
        ),
        if (_additionalChargeInputs.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (
            var index = 0;
            index < _additionalChargeInputs.length;
            index++
          ) ...[
            _buildAdditionalChargeRow(_additionalChargeInputs[index], index),
            if (index < _additionalChargeInputs.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  Widget _buildAdditionalChargeRow(_AdditionalChargeInput charge, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: TextFormField(
            controller: charge.nameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(label: 'Charges Name'),
            validator: (value) {
              if (_isAdditionalChargeRowEmpty(charge)) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return 'Enter charges name';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<String>(
            initialValue: charge.chargeType,
            decoration: _inputDecoration(label: 'Charges Type'),
            items: _chargeTypeOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                charge.chargeType = value;
              });
              _handleAdditionalChargeChanged(charge, valueChanged: false);
            },
            validator: (value) {
              if (_isAdditionalChargeRowEmpty(charge)) {
                return null;
              }
              return value == null ? 'Select charges type' : null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: charge.valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: _inputDecoration(label: 'Value'),
            validator: (value) {
              if (_isAdditionalChargeRowEmpty(charge)) {
                return null;
              }
              final normalized = _normalizeNumericValue(value ?? '');
              final number = double.tryParse(normalized);
              if (normalized.isEmpty || number == null) {
                return 'Enter value';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IconButton(
            onPressed: () => _removeAdditionalChargeRow(index),
            tooltip: 'Delete charge',
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFB3261E),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountFineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_discountCycleNoticeText != null) ...[
          AnimatedOpacity(
            opacity: _showDiscountCycleNotice ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7C787)),
              ),
              child: Text(
                _discountCycleNoticeText!,
                style: const TextStyle(
                  color: Color(0xFF8A5A00),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _canAddDiscountFine
                ? () => _openDiscountFineDialog('DISCOUNT')
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandColor,
              side: const BorderSide(color: _brandColor),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.local_offer_outlined),
            label: Text(_discountFineButtonLabel),
          ),
        ),
        if (_appliedDiscountFines.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _appliedDiscountFines
                .map(_buildAppliedDiscountFineCard)
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAppliedDiscountFineCard(_AppliedDiscountFine item) {
    final isFine = item.kind == 'FINE';
    final accentColor = isFine ? const Color(0xFFCF8A2E) : _brandColor;
    final isDeleting = _deletingDiscountFineIds.contains(item.discFnId);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  isFine ? 'Fine Applied' : 'Discount Applied',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: isDeleting ? null : () => _deleteDiscountFine(item),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: isDeleting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Icon(Icons.close_rounded, size: 18, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openDiscountFineDetails(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                item.discFnId.isEmpty
                    ? 'Reference not returned'
                    : item.discFnId,
                style: const TextStyle(
                  color: _brandTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.mode == 'PERCENTAGE' ? 'Percentage' : 'Amount'} • ${item.value}',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
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
              onTap: _loadingApplicableForOptions
                  ? null
                  : () => _openApplicableForDialog(field),
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Applicable For',
                  suffix: _loadingApplicableForOptions
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.keyboard_arrow_down_rounded),
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
            if (_applicableForOptionsError != null &&
                _applicableForOptionsError!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _applicableForOptionsError!,
                style: const TextStyle(
                  color: Color(0xFFB3261E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAllowedPaymentModesField() {
    return FormField<Set<String>>(
      initialValue: _allowedPaymentModes,
      validator: (_) {
        if (_allowedPaymentModes.isEmpty) {
          return 'Allowed payment mode is required';
        }
        return null;
      },
      builder: (field) {
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openAllowedPaymentModesDialog(field),
          child: InputDecorator(
            decoration: _inputDecoration(
              label: 'Allowed Tender',
              suffix: const Icon(Icons.keyboard_arrow_down_rounded),
            ).copyWith(errorText: field.errorText),
            child: Text(
              _buildAllowedPaymentModesDisplayText(),
              style: TextStyle(
                color: _allowedPaymentModes.isEmpty
                    ? Colors.black45
                    : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionCyclesField() {
    return FormField<Set<String>>(
      initialValue: _paymentCollectionCycles,
      validator: (_) {
        if (_paymentCollectionCycles.isEmpty) {
          return 'Collection cycle is required';
        }
        return null;
      },
      builder: (field) {
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openCollectionCyclesDialog(field),
          child: InputDecorator(
            decoration: _inputDecoration(
              label: 'Collection Cycle',
              suffix: const Icon(Icons.keyboard_arrow_down_rounded),
            ).copyWith(errorText: field.errorText),
            child: Text(
              _buildPaymentCollectionCyclesDisplayText(),
              style: TextStyle(
                color: _paymentCollectionCycles.isEmpty
                    ? Colors.black45
                    : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
            _buildCollapsibleFormSection(
              title: 'Payment Details',
              subtitle:
                  'These values are sent to create the new apartment payment.',
              expanded: _expandPaymentDetails,
              enabled: true,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandPaymentDetails = expanded;
                });
              },
              child: Column(
                children: [
                  TextFormField(
                    controller: _paymentNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: 'Payment Name',
                      hintText: 'e.g. Maintenance Charges Q1',
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
                      hintText:
                          'e.g. Quarterly maintenance charges for society',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Short details are required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentCauseTypeConstant,
                    decoration: _inputDecoration(label: 'Payment Cause'),
                    isExpanded: true,
                    items: _loadingSocietyCollectionTypes
                        ? [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Loading...'),
                            ),
                          ]
                        : [
                            ..._societyCollectionTypes.map(
                              (type) => DropdownMenuItem<String>(
                                value: type.typeConstant,
                                child: _buildPaymentCauseDropdownItem(
                                  type.collectionType,
                                  type.sacCode,
                                ),
                              ),
                            ),
                            const DropdownMenuItem<String>(
                              value: '__OTHER__',
                              child: Text('Other'),
                            ),
                          ],
                    onChanged: _loadingSocietyCollectionTypes
                        ? null
                        : (value) {
                            setState(() {
                              if (value == '__OTHER__') {
                                _isCustomPaymentCause = true;
                                _paymentCauseTypeConstant = null;
                                _customPaymentCauseController.clear();
                              } else {
                                _isCustomPaymentCause = false;
                                _paymentCauseTypeConstant = value;
                                _customPaymentCauseController.clear();
                              }
                            });
                          },
                    validator: (value) =>
                        value == null ? 'Payment cause is required' : null,
                  ),
                  if (_isCustomPaymentCause) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customPaymentCauseController,
                      decoration: _inputDecoration(
                        label: 'Enter Payment Cause',
                        hintText: 'e.g. Custom Maintenance Charge',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Payment cause is required';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
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
                      setState(() {
                        _paymentCapita = value;
                        if (_isPerHeadCapita) {
                          _paymentType = 'OPTIONAL';
                        }
                      });
                      _scheduleDueDetailsRefresh();
                    },
                    validator: (value) =>
                        value == null ? 'Payment capita is required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildCollapsibleFormSection(
              title: 'Collection Details',
              subtitle:
                  'These fields drive the live due amount preview on the right.',
              expanded: _expandCollectionSetup,
              enabled: _isPaymentDetailsComplete,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandCollectionSetup = expanded;
                });
              },
              child: Column(
                children: [
                  _buildThreeFieldRow(
                    first: _buildCollectionCyclesField(),
                    second: _buildAllowedPaymentModesField(),
                    third: DropdownButtonFormField<String>(
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
                  const SizedBox(height: 16),
                  _buildTwoFieldRow(
                    first: TextFormField(
                      controller: _collectionStartController,
                      readOnly: true,
                      decoration: _inputDecoration(
                        label: 'Start Date',
                        suffix: const Icon(Icons.calendar_today_rounded),
                      ),
                      onTap: _pickStartDate,
                      validator: (_) => _collectionStartDate == null
                          ? 'Start date is required'
                          : null,
                    ),
                    second: TextFormField(
                      controller: _collectionEndController,
                      readOnly: true,
                      decoration: _inputDecoration(
                        label: 'End Date',
                        suffix: const Icon(Icons.calendar_today_rounded),
                      ),
                      onTap: _pickEndDate,
                      validator: (_) => _collectionEndDate == null
                          ? 'End date is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTwoFieldRow(
                    first: TextFormField(
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
                        if (normalized.isEmpty ||
                            number == null ||
                            number < 0) {
                          return 'Enter GST';
                        }
                        if (number > 100) {
                          return 'GST cannot exceed 100';
                        }
                        return null;
                      },
                    ),
                    second: TextFormField(
                      controller: _paymentAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: _inputDecoration(
                        label: _isOnlyOnce ? 'Amount' : 'Amount Per Month',
                        prefix: const Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (value) {
                        final normalized = _normalizeNumericValue(value ?? '');
                        final number = double.tryParse(normalized);
                        if (normalized.isEmpty ||
                            number == null ||
                            number <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildCollapsibleFormSection(
              title: 'Added Charges And Discount',
              subtitle:
                  'Add additional tax or charge entries that will be included in this payment.',
              expanded: _expandChargesAndAdjustments,
              enabled: _isCollectionDetailsComplete,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandChargesAndAdjustments = expanded;
                });
              },
              child: Column(
                children: [
                  _buildAdditionalChargesSection(),
                  const SizedBox(height: 22),
                  _buildDiscountFineSection(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildCollapsibleFormSection(
              title: 'Audience And Configuration',
              subtitle:
                  'Select who the payment applies to and where the amount is collected.',
              expanded: _expandAudienceAndSettlement,
              enabled: _isCollectionDetailsComplete,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandAudienceAndSettlement = expanded;
                });
              },
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: mobile ? double.infinity : 360,
                    child: _buildApplicableForField(),
                  ),
                  SizedBox(
                    width: mobile ? double.infinity : 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: _isPerHeadCapita
                          ? 'OPTIONAL'
                          : _paymentType,
                      decoration: _inputDecoration(label: 'Payment Type'),
                      items: _paymentTypeOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: _isPerHeadCapita
                          ? null
                          : (value) {
                              setState(() {
                                _paymentType = value;
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Payment type is required' : null,
                    ),
                  ),
                  SizedBox(
                    width: mobile ? double.infinity : 320,
                    child: DropdownButtonFormField<String>(
                      initialValue: (() {
                        final matches = _bankAccountOptions
                            .where((option) => option.value == _bankAccountId)
                            .length;
                        return matches == 1 ? _bankAccountId : null;
                      })(),
                      decoration: _inputDecoration(label: 'Bank Account'),
                      items: _bankAccountOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: _buildBankAccountDropdownItem(option),
                            ),
                          )
                          .toList(),
                      onTap: _fetchBankAccountOptions,
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
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
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
                  label: Text(_submitting ? 'Creating...' : 'Create Payment'),
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

  Widget _buildFlatTypeDueAmountSection(
    List<_FlatTypeDueAmountItem> flatTypeDetails,
    bool mobile,
  ) {
    final selectedIndex = _resolvedFlatTypeIndex(flatTypeDetails.length);
    final selectedDetail = flatTypeDetails[selectedIndex];
    final canGoPrevious = selectedIndex > 0;
    final canGoNext = selectedIndex < flatTypeDetails.length - 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Flat Type Wise Amount',
                  style: TextStyle(
                    color: _brandTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildFlatTypeNavigationButton(
                icon: Icons.chevron_left_rounded,
                enabled: canGoPrevious,
                onPressed: () {
                  if (!canGoPrevious) {
                    return;
                  }

                  setState(() {
                    _selectedFlatTypeIndex = selectedIndex - 1;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFlatTypeNavigationButton(
                icon: Icons.chevron_right_rounded,
                enabled: canGoNext,
                onPressed: () {
                  if (!canGoNext) {
                    return;
                  }

                  setState(() {
                    _selectedFlatTypeIndex = selectedIndex + 1;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Showing flat ${selectedIndex + 1} of ${flatTypeDetails.length} in ascending order. Only the active due record is displayed for the selected flat.',
            style: TextStyle(color: Colors.black54, height: 1.45),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBFA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDEAE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flat Type: ${selectedDetail.flatLabel}',
                  style: const TextStyle(
                    color: _brandTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: mobile ? double.infinity : 180,
                      child: _buildPreviewStat(
                        label: 'Amount',
                        value: _formatCurrencyValueOrDash(
                          selectedDetail.detail.amount,
                        ),
                        backgroundColor: const Color(0xFFFFFCF4),
                      ),
                    ),
                    SizedBox(
                      width: mobile ? double.infinity : 180,
                      child: _buildPreviewStat(
                        label: 'GST Amount',
                        value: _formatCurrencyValueOrDash(
                          selectedDetail.detail.gstAmount,
                        ),
                        backgroundColor: const Color(0xFFFFF7E8),
                      ),
                    ),
                    SizedBox(
                      width: mobile ? double.infinity : 180,
                      child: _buildPreviewStat(
                        label: 'Total Added Charges',
                        value: _formatCurrencyValueOrDash(
                          selectedDetail.detail.totalAddedCharges,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: mobile ? double.infinity : 180,
                      child: _buildPreviewStat(
                        label: 'Total Amount',
                        value: _formatCurrencyValueOrDash(
                          selectedDetail.detail.totalAmount,
                        ),
                        backgroundColor: const Color(0xFFEFFFFA),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatTypeNavigationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE8F5F1) : const Color(0xFFF3F6F5),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? const Color(0xFFC9E4DD) : const Color(0xFFE1ECE8),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? _brandColor : const Color(0xFF9BA9A6),
        ),
      ),
    );
  }

  Widget _buildPreviewColumn(bool mobile) {
    final isBuildUpAreaCapita = _paymentCapita == 'PER_SQFT';
    final cycleGroups = _availableDueAmountCycleGroups(_dueDetails);
    final selectedCycleIndex = _resolvedDueCycleIndex(cycleGroups.length);
    final selectedCycleGroup = cycleGroups.isEmpty
        ? null
        : cycleGroups[selectedCycleIndex];
    final selectedCycleLabel = selectedCycleGroup == null
        ? '--'
        : _formatCycleLabel(selectedCycleGroup.cycleLabel);
    final canGoPreviousCycle = selectedCycleIndex > 0;
    final canGoNextCycle = selectedCycleIndex < cycleGroups.length - 1;
    final upcomingDueDetail = _resolveUpcomingDueDetail(_dueDetails);
    final flatTypeDetails = _activeFlatTypeDueAmountDetails(_dueDetails);
    final hasFlatTypeWiseEntries = flatTypeDetails.any(
      (entry) => entry.flatLabel.toUpperCase() != 'ALL',
    );
    final selectedFlatIndex = _resolvedFlatTypeIndex(flatTypeDetails.length);
    final selectedFlatDetail = flatTypeDetails.isEmpty
        ? null
        : flatTypeDetails[selectedFlatIndex];
    final dueDate = _formatDueDateValue(
      upcomingDueDetail?.dueDateText ?? selectedFlatDetail?.detail.dueDateText,
    );
    final amountExcludingGst = _formatCurrencyValueOrDash(
      upcomingDueDetail?.amount,
    );
    final gstAmount = _formatCurrencyValueOrDash(upcomingDueDetail?.gstAmount);
    final amountIncludingGst = _formatCurrencyValueOrDash(
      upcomingDueDetail?.totalAmount,
    );
    final totalAddedCharges = _formatCurrencyValueOrDash(
      upcomingDueDetail?.totalAddedCharges,
    );
    final selectedEstimatedCollectionAmount = _formatCurrencyValueOrDash(
      upcomingDueDetail?.estimatedCollectionAmount ??
          selectedFlatDetail?.detail.estimatedCollectionAmount,
    );

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Due Details',
                      style: TextStyle(
                        color: _brandTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Cycle: $selectedCycleLabel',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _buildFlatTypeNavigationButton(
                          icon: Icons.chevron_left_rounded,
                          enabled: canGoPreviousCycle,
                          onPressed: () {
                            if (!canGoPreviousCycle) return;
                            setState(() {
                              _selectedDueCycleIndex = selectedCycleIndex - 1;
                              _selectedFlatTypeIndex = 0;
                            });
                          },
                        ),
                        _buildFlatTypeNavigationButton(
                          icon: Icons.chevron_right_rounded,
                          enabled: canGoNextCycle,
                          onPressed: () {
                            if (!canGoNextCycle) return;
                            setState(() {
                              _selectedDueCycleIndex = selectedCycleIndex + 1;
                              _selectedFlatTypeIndex = 0;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expected Collection Amount: $selectedEstimatedCollectionAmount (approx)',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review the upcoming due breakdown based on the details filled in — including amount split, applicable charges, and due date as per the selected cycle.',
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
          else if (isBuildUpAreaCapita && !hasFlatTypeWiseEntries)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE0EBE8)),
              ),
              child: const Text(
                'No active flat-wise due amount details are available for the selected inputs.',
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
            )
          else if (isBuildUpAreaCapita)
            _buildFlatTypeDueAmountSection(flatTypeDetails, mobile)
          else if (upcomingDueDetail == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE0EBE8)),
              ),
              child: const Text(
                'No active due amount details are available for the selected inputs.',
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
                    label: 'Total Payble Amount',
                    value: amountIncludingGst,
                    backgroundColor: const Color(0xFFEFFFFA),
                  ),
                ),
                SizedBox(
                  width: mobile ? double.infinity : 220,
                  child: _buildPreviewStat(
                    label: 'Total Added Charges',
                    value: totalAddedCharges,
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
                  label: 'Payment Cause',
                  value: _isCustomPaymentCause
                      ? _customPaymentCauseController.text.trim()
                      : (_paymentCauseTypeConstant != null
                            ? (_societyCollectionTypeMap[_paymentCauseTypeConstant]
                                      ?.collectionType ??
                                  '--')
                            : '--'),
                ),
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
                  value: _buildPaymentCollectionCyclesDisplayText(),
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
          constraints: const BoxConstraints(maxWidth: 1440),
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
  const _PaymentChoice({
    required this.label,
    required this.value,
    this.trailingLabel,
  });

  final String label;
  final String value;
  final String? trailingLabel;
}

class _SocietyCollectionType {
  const _SocietyCollectionType({
    required this.collectionType,
    required this.purposeOfCollection,
    required this.sacCode,
    required this.taxable,
    required this.typeConstant,
  });

  final String collectionType;
  final String purposeOfCollection;
  final String sacCode;
  final bool taxable;
  final String typeConstant;
}

class _FlatSelectionNode {
  const _FlatSelectionNode({
    required this.key,
    required this.label,
    this.children = const [],
    this.flatId,
  });

  final String key;
  final String label;
  final List<_FlatSelectionNode> children;
  final String? flatId;

  bool get isFlat => flatId != null;

  List<String> get flatIds {
    if (flatId != null) {
      return [flatId!];
    }

    final flatIds = <String>[];
    for (final child in children) {
      flatIds.addAll(child.flatIds);
    }
    return flatIds;
  }
}

class _DueAmountDetail {
  const _DueAmountDetail({
    required this.amount,
    required this.dueDateText,
    required this.dueDate,
    required this.dueId,
    required this.gstAmount,
    required this.gstPercent,
    required this.status,
    required this.collectionCycle,
    required this.estimatedCollectionAmount,
    required this.totalAddedCharges,
    required this.totalAmount,
  });

  factory _DueAmountDetail.fromMap(Map<String, dynamic> map) {
    final dueDateText = map['dueDate']?.toString().trim() ?? '';
    return _DueAmountDetail(
      amount:
          map['amount']?.toString().trim() ??
          map['amountExcludingGst']?.toString().trim() ??
          '',
      dueDateText: dueDateText,
      dueDate: _CreatePaymentPageState._parseStaticDueDate(dueDateText),
      dueId: map['dueId']?.toString().trim() ?? '',
      gstAmount: map['gstAmount']?.toString().trim() ?? '',
      gstPercent: map['gstPercent']?.toString().trim() ?? '',
      status: map['status']?.toString().trim() ?? '',
      collectionCycle: map['collectionCycle']?.toString().trim() ?? '',
      estimatedCollectionAmount:
          map['estimatedCollectionAmount']?.toString().trim() ?? '',
      totalAddedCharges:
          map['totalAddedCharges']?.toString().trim() ??
          _sumAddedChargeValues(map['addedCharges']),
      totalAmount:
          map['totalAmount']?.toString().trim() ??
          map['amountIncludingGst']?.toString().trim() ??
          '',
    );
  }

  static String _sumAddedChargeValues(dynamic rawCharges) {
    if (rawCharges is! List) {
      return '';
    }

    var total = 0.0;
    var hasValue = false;
    for (final charge in rawCharges.whereType<Map>()) {
      final rawValue =
          charge['finalChargeValue']?.toString().trim() ??
          charge['value']?.toString().trim() ??
          '';
      final parsedValue = double.tryParse(rawValue);
      if (parsedValue == null) {
        continue;
      }

      total += parsedValue;
      hasValue = true;
    }

    if (!hasValue) {
      return '';
    }

    final formatted = total.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    if (formatted.endsWith('0')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  final String amount;
  final String dueDateText;
  final DateTime? dueDate;
  final String dueId;
  final String gstAmount;
  final String gstPercent;
  final String status;
  final String collectionCycle;
  final String estimatedCollectionAmount;
  final String totalAddedCharges;
  final String totalAmount;
}

class _FlatTypeDueAmountItem {
  const _FlatTypeDueAmountItem({required this.flatLabel, required this.detail});

  final String flatLabel;
  final _DueAmountDetail detail;
}

class _DueAmountCycleGroup {
  const _DueAmountCycleGroup({
    required this.cycleLabel,
    required this.flatTypeDetails,
  });

  final String cycleLabel;
  final Map<String, List<_DueAmountDetail>> flatTypeDetails;
}

class _AdditionalChargeInput {
  _AdditionalChargeInput();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  String? chargeType;
  String lastNormalizedValue = '';

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class _DiscountCycleOption {
  const _DiscountCycleOption({
    required this.cycle,
    required this.sourceCycle,
    required this.label,
  });

  final String cycle;
  final String sourceCycle;
  final String label;
}

class _DiscFinCycleDiscount {
  const _DiscFinCycleDiscount({
    required this.cycle,
    required this.type,
    required this.value,
  });

  final String cycle;
  final String type;
  final String value;
}

class _CycleDiscountInput {
  _CycleDiscountInput({required this.cycle, required this.label})
    : valueController = TextEditingController();

  final String cycle;
  final String label;
  final TextEditingController valueController;
  String type = 'AMOUNT';

  void dispose() {
    valueController.dispose();
  }
}

class _DiscountFineDraft {
  const _DiscountFineDraft({
    required this.kind,
    required this.dueDateAsStartDate,
    required this.startDate,
    required this.endDate,
    required this.mode,
    required this.value,
    this.calculationType,
    this.cumulationCycle,
    this.cycleDiscounts = const [],
    this.minimumPaymentAmount,
  });

  final String kind;
  final bool dueDateAsStartDate;
  final DateTime startDate;
  final DateTime endDate;
  final String mode;
  final String value;
  final String? calculationType;
  final String? cumulationCycle;
  final List<_DiscFinCycleDiscount> cycleDiscounts;
  final String? minimumPaymentAmount;

  bool get isFine => kind == 'FINE';
}

class _AppliedDiscountFine {
  const _AppliedDiscountFine({
    required this.kind,
    required this.discFnId,
    required this.mode,
    required this.value,
    this.calculationType,
    required this.dueDateAsStartDate,
    required this.startDateText,
    required this.endDateText,
    this.cumulationCycle,
    this.cycleDiscounts = const [],
    this.minimumPaymentAmount,
  });

  final String kind;
  final String discFnId;
  final String mode;
  final String value;
  final String? calculationType;
  final bool dueDateAsStartDate;
  final String startDateText;
  final String endDateText;
  final String? cumulationCycle;
  final List<_DiscFinCycleDiscount> cycleDiscounts;
  final String? minimumPaymentAmount;

  _AppliedDiscountFine copyWith({
    List<_DiscFinCycleDiscount>? cycleDiscounts,
    String? minimumPaymentAmount,
  }) {
    return _AppliedDiscountFine(
      kind: kind,
      discFnId: discFnId,
      mode: mode,
      value: value,
      calculationType: calculationType,
      dueDateAsStartDate: dueDateAsStartDate,
      startDateText: startDateText,
      endDateText: endDateText,
      cumulationCycle: cumulationCycle,
      cycleDiscounts: cycleDiscounts ?? this.cycleDiscounts,
      minimumPaymentAmount: minimumPaymentAmount ?? this.minimumPaymentAmount,
    );
  }
}

class _DiscountFineSubmitResult {
  const _DiscountFineSubmitResult({
    required this.isSuccess,
    required this.message,
    this.appliedDiscountFine,
  });

  final bool isSuccess;
  final String message;
  final _AppliedDiscountFine? appliedDiscountFine;
}

class _DiscountFineDetail {
  const _DiscountFineDetail({
    required this.kind,
    required this.discFnId,
    required this.discFnType,
    required this.discFinValue,
    required this.discFnCycleType,
    required this.dueDateAsStartDateFlag,
    required this.discFnStrtDt,
    required this.discFnEndDt,
    required this.discFnCumlatonCycle,
    required this.discFnMode,
  });

  factory _DiscountFineDetail.fromApplied(_AppliedDiscountFine item) {
    return _DiscountFineDetail(
      kind: item.kind,
      discFnId: item.discFnId,
      discFnType: item.kind,
      discFinValue: item.value,
      dueDateAsStartDateFlag: item.dueDateAsStartDate,
      discFnCycleType: item.calculationType,
      discFnStrtDt: item.startDateText,
      discFnEndDt: item.endDateText,
      discFnCumlatonCycle: item.cumulationCycle,
      discFnMode: item.mode,
    );
  }

  static String? _normalizedValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  static _DiscountFineDetail? fromResponse(
    Map<String, dynamic>? response,
    _AppliedDiscountFine item,
  ) {
    if (response == null) {
      return null;
    }

    final rawList = response['discFinList'];
    if (rawList is! List) {
      return _DiscountFineDetail.fromApplied(item);
    }

    Map<String, dynamic>? matched;
    for (final entry in rawList.whereType<Map>()) {
      final record = Map<String, dynamic>.from(entry);
      final recordId = record['discFnId']?.toString().trim() ?? '';
      if (recordId == item.discFnId) {
        matched = record;
        break;
      }
    }

    if (matched == null) {
      return null;
    }

    return _DiscountFineDetail(
      kind: item.kind,
      discFnId: item.discFnId,
      dueDateAsStartDateFlag:
          matched['dueDateAsStartDateFlag'] == true ||
          matched['dueDateAsStartDateFlag']?.toString().toLowerCase() == 'true',
      discFnType: _normalizedValue(matched['discFnType']) ?? item.kind,
      discFinValue: _normalizedValue(matched['discFinValue']) ?? item.value,
      discFnCycleType:
          _normalizedValue(matched['discFnCycleType']) ?? item.calculationType,
      discFnStrtDt:
          _normalizedValue(matched['discFnStrtDt']) ?? item.startDateText,
      discFnEndDt: _normalizedValue(matched['discFnEndDt']) ?? item.endDateText,
      discFnCumlatonCycle:
          _normalizedValue(matched['discFnCumlatonCycle']) ??
          item.cumulationCycle,
      discFnMode: _normalizedValue(matched['discFnMode']) ?? item.mode,
    );
  }

  final String kind;
  final String discFnId;
  final String discFnType;
  final String? discFinValue;
  final String? discFnCycleType;
  final bool dueDateAsStartDateFlag;
  final String? discFnStrtDt;
  final String? discFnEndDt;
  final String? discFnCumlatonCycle;
  final String? discFnMode;
}

class _DiscountFineDetailsDialog extends StatelessWidget {
  const _DiscountFineDetailsDialog({required this.detail});

  final _DiscountFineDetail detail;

  @override
  Widget build(BuildContext context) {
    final isFine = detail.kind == 'FINE';
    final accentColor = isFine
        ? const Color(0xFFCF8A2E)
        : _CreatePaymentPageState._brandColor;
    final summaryRows = <Widget>[
      _SummaryRow(label: 'Type', value: detail.discFnType),
    ];

    if (detail.discFinValue != null) {
      summaryRows.add(_SummaryRow(label: 'Value', value: detail.discFinValue!));
    }

    if (detail.discFnCycleType != null) {
      summaryRows.add(
        _SummaryRow(label: 'Cycle Type', value: detail.discFnCycleType!),
      );
    }

    summaryRows.add(
      _SummaryRow(
        label: 'Start Date',
        value: detail.dueDateAsStartDateFlag
            ? 'As Due Date'
            : (detail.discFnStrtDt ?? ''),
      ),
    );

    if (detail.discFnEndDt != null) {
      summaryRows.add(
        _SummaryRow(label: 'End Date', value: detail.discFnEndDt!),
      );
    }

    if (detail.discFnCumlatonCycle != null) {
      summaryRows.add(
        _SummaryRow(
          label: 'Cummilation Cycle',
          value: detail.discFnCumlatonCycle!,
        ),
      );
    }

    if (detail.discFnMode != null) {
      summaryRows.add(_SummaryRow(label: 'Mode', value: detail.discFnMode!));
    }

    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(isFine ? 'Fine Details' : 'Discount Details'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.22)),
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
                    detail.discFnId,
                    style: const TextStyle(
                      color: _CreatePaymentPageState._brandTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...summaryRows,
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accentColor),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DiscountFineDialog extends StatefulWidget {
  const _DiscountFineDialog({
    required this.initialKind,
    required this.kindLocked,
    required this.availableCollectionCycles,
    required this.onSubmit,
  });

  final String initialKind;
  final bool kindLocked;
  final List<_DiscountCycleOption> availableCollectionCycles;
  final Future<_DiscountFineSubmitResult> Function(_DiscountFineDraft draft)
  onSubmit;

  @override
  State<_DiscountFineDialog> createState() => _DiscountFineDialogState();
}

class _DiscountFineDialogState extends State<_DiscountFineDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _minimumPaymentAmountController =
      TextEditingController();
  final List<_CycleDiscountInput> _cycleDiscountInputs = [];

  late String _kind;
  String _mode = 'AMOUNT';
  String? _calculationType;
  String? _cumulationCycle;
  bool _dueDateAsStartDate = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _errorMessage;
  String _discountModeSelection = 'FIXED'; // 'FIXED' or 'CYCLE_LEVEL'

  bool get _isFine => _kind == 'FINE';
  bool get _showCycleType => _isFine;
  bool get _showCumulationCycle => _isFine && _calculationType == 'CUMULATIVE';
  bool get _isStartDateInputEnabled => !(_isFine && _dueDateAsStartDate);
  bool get _isDiscount => _kind == 'DISCOUNT';
  bool get _showDiscountModeRadio =>
      _isDiscount &&
      widget.availableCollectionCycles.any((c) => c.cycle != 'ONCE');
  bool get _isCycleLevelDiscountMode =>
      _showDiscountModeRadio && _discountModeSelection == 'CYCLE_LEVEL';
  bool get _isBaseDiscountFieldLocked => _isCycleLevelDiscountMode;
  bool get _hasDirectBaseDiscountValue {
    if (!_isDiscount) {
      return false;
    }
    final normalized = _normalizeNumericValue(_valueController.text);
    final number = double.tryParse(normalized);
    return normalized.isNotEmpty && number != null && number > 0;
  }

  bool get _disableAddCycleDiscountButton {
    return _remainingCycleOptions.isEmpty || _hasDirectBaseDiscountValue;
  }

  List<_DiscountCycleOption> get _remainingCycleOptions {
    final usedCycles = _cycleDiscountInputs.map((entry) => entry.cycle).toSet();
    return widget.availableCollectionCycles
        .where((entry) => !usedCycles.contains(entry.cycle))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _valueController.addListener(_onBaseDiscountValueChanged);
  }

  @override
  void dispose() {
    _valueController.removeListener(_onBaseDiscountValueChanged);
    _startDateController.dispose();
    _endDateController.dispose();
    _valueController.dispose();
    _minimumPaymentAmountController.dispose();
    for (final row in _cycleDiscountInputs) {
      row.dispose();
    }
    super.dispose();
  }

  void _onBaseDiscountValueChanged() {
    if (!mounted || !_isDiscount) {
      return;
    }
    setState(() {});
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
          color: _CreatePaymentPageState._brandColor,
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

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
    IconData icon = Icons.tune_rounded,
    Color accentColor = _CreatePaymentPageState._brandColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F8F82),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _CreatePaymentPageState._brandTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF5D7A76),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
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

  Future<void> _addCycleDiscountRow() async {
    final remaining = _remainingCycleOptions;
    if (remaining.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All available collection cycles are already added.'),
        ),
      );
      return;
    }

    final selectedCycle = await showDialog<_DiscountCycleOption>(
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
        _CycleDiscountInput(
          cycle: selectedCycle.cycle,
          label: selectedCycle.label,
        ),
      );
    });
  }

  void _removeCycleDiscountRow(int index) {
    if (index < 0 || index >= _cycleDiscountInputs.length) {
      return;
    }

    setState(() {
      final row = _cycleDiscountInputs.removeAt(index);
      row.dispose();
    });
  }

  List<_DiscFinCycleDiscount> _buildCycleDiscountDraftRows() {
    return _cycleDiscountInputs
        .map(
          (row) => _DiscFinCycleDiscount(
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
      _DiscountFineDraft(
        kind: _kind,
        dueDateAsStartDate: _dueDateAsStartDate,
        startDate: startDate,
        endDate: endDate,
        mode: _mode,
        value: _normalizeNumericValue(_valueController.text),
        calculationType: _isFine ? _calculationType : null,
        cumulationCycle: _isFine ? _cumulationCycle : null,
        cycleDiscounts: _isFine ? const [] : _buildCycleDiscountDraftRows(),
        minimumPaymentAmount: _isFine
            ? null
            : _normalizeNumericValue(_minimumPaymentAmountController.text),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop(result.appliedDiscountFine);
      return;
    }

    setState(() {
      _errorMessage = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Create Discount / Fine'),
          SizedBox(height: 4),
          Text(
            'Configure the adjustment with dates, values, and optional cycle-wise discounts.',
            style: TextStyle(
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E7), Color(0xFFFFF2D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7C787)),
                  ),
                  child: const Text(
                    'Discount/Fine Will Not Be Applicable For Due Dates In Past',
                    style: TextStyle(
                      color: Color(0xFF8A5A00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildSectionCard(
                  title: 'Fill Details',
                  icon: Icons.auto_awesome_rounded,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _kind,
                        decoration: _inputDecoration(label: 'Type'),
                        items: _CreatePaymentPageState._discountFineKindOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option.value,
                                child: Text(option.label),
                              ),
                            )
                            .toList(),
                        onChanged: widget.kindLocked
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _kind = value;
                                  if (!_isFine) {
                                    _dueDateAsStartDate = false;
                                    _calculationType = null;
                                    _cumulationCycle = null;
                                  }
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
                          activeColor: _CreatePaymentPageState._brandColor,
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
                          child: RadioGroup<String>(
                            groupValue: _discountModeSelection,
                            onChanged: (v) {
                              if (v == 'FIXED') {
                                setState(() {
                                  _discountModeSelection = 'FIXED';
                                  for (final row in _cycleDiscountInputs) {
                                    row.dispose();
                                  }
                                  _cycleDiscountInputs.clear();
                                });
                              } else if (v == 'CYCLE_LEVEL') {
                                setState(() {
                                  _discountModeSelection = 'CYCLE_LEVEL';
                                  _valueController.clear();
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Fixed Discount'),
                                    value: 'FIXED',
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Cycle Level Discount'),
                                    value: 'CYCLE_LEVEL',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_isDiscount) ...[],
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _mode,
                              decoration: _inputDecoration(label: 'Mode'),
                              items: _CreatePaymentPageState._chargeTypeOptions
                                  .map(
                                    (option) => DropdownMenuItem<String>(
                                      value: option.value,
                                      child: Text(option.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isBaseDiscountFieldLocked
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }

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
                                items: _CreatePaymentPageState
                                    ._discountFineTypeOptions
                                    .map(
                                      (option) => DropdownMenuItem<String>(
                                        value: option.value,
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
                          items: _CreatePaymentPageState
                              ._discountFineCycleOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.value,
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
                            if (!_showCumulationCycle) {
                              return null;
                            }
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
                if (_isCycleLevelDiscountMode) ...[
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: 'Cycle-wise Discount',
                    subtitle:
                        'Add different discount values for specific collection cycles when needed.',
                    icon: Icons.view_timeline_rounded,
                    accentColor: const Color(0xFF0A7E73),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FBF9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD6ECE7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        _CreatePaymentPageState._brandColor,
                                    side: const BorderSide(
                                      color: Color(0xFFB8D8D1),
                                    ),
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
                              if (_cycleDiscountInputs.isNotEmpty) ...[
                                for (
                                  var index = 0;
                                  index < _cycleDiscountInputs.length;
                                  index++
                                ) ...[
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _cycleDiscountInputs[index]
                                                    .label,
                                                style: const TextStyle(
                                                  color: Color(0xFF124B45),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeCycleDiscountRow(
                                                    index,
                                                  ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                initialValue:
                                                    _cycleDiscountInputs[index]
                                                        .type,
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
                                                  if (value == null) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    _cycleDiscountInputs[index]
                                                            .type =
                                                        value;
                                                  });
                                                },
                                                validator: (value) =>
                                                    value == null
                                                    ? 'Select type'
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _cycleDiscountInputs[index]
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
                                                  final number =
                                                      double.tryParse(
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
                              ],
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
            backgroundColor: _CreatePaymentPageState._brandColor,
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

class _ApplicableForDialog extends StatefulWidget {
  const _ApplicableForDialog({
    required this.nodes,
    required this.initialSelection,
  });

  final List<_FlatSelectionNode> nodes;
  final Set<String> initialSelection;

  @override
  State<_ApplicableForDialog> createState() => _ApplicableForDialogState();
}

class _AllowedPaymentModesDialog extends StatefulWidget {
  const _AllowedPaymentModesDialog({
    required this.options,
    required this.initialSelection,
  });

  final List<_PaymentChoice> options;
  final Set<String> initialSelection;

  @override
  State<_AllowedPaymentModesDialog> createState() =>
      _AllowedPaymentModesDialogState();
}

class _AllowedPaymentModesDialogState
    extends State<_AllowedPaymentModesDialog> {
  late Set<String> _selectedValues;

  bool get _allSelected =>
      widget.options.isNotEmpty &&
      widget.options.every((option) => _selectedValues.contains(option.value));

  void _toggleAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedValues = widget.options.map((option) => option.value).toSet();
      } else {
        _selectedValues.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedValues = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Allowed Payment Modes'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6ECE7)),
              ),
              child: CheckboxListTile(
                value: _allSelected,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                activeColor: _CreatePaymentPageState._brandColor,
                title: const Text(
                  'All',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Select every payment mode'),
                onChanged: (checked) => _toggleAll(checked ?? false),
              ),
            ),
            const SizedBox(height: 10),
            for (final option in widget.options)
              CheckboxListTile(
                value: _selectedValues.contains(option.value),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: _CreatePaymentPageState._brandColor,
                title: Text(option.label),
                onChanged: (checked) {
                  setState(() {
                    if (checked ?? false) {
                      _selectedValues.add(option.value);
                    } else {
                      _selectedValues.remove(option.value);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _CreatePaymentPageState._brandColor,
          ),
          onPressed: () => Navigator.of(context).pop(_selectedValues),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _CollectionCyclesDialog extends StatefulWidget {
  const _CollectionCyclesDialog({
    required this.options,
    required this.initialSelection,
  });

  final List<_PaymentChoice> options;
  final Set<String> initialSelection;

  @override
  State<_CollectionCyclesDialog> createState() =>
      _CollectionCyclesDialogState();
}

class _CollectionCyclesDialogState extends State<_CollectionCyclesDialog> {
  static const String _onceValue = 'ONCE';

  late Set<String> _selectedValues;

  Iterable<_PaymentChoice> get _allEligibleOptions =>
      widget.options.where((option) => option.value != _onceValue);

  bool get _allSelected =>
      !_selectedValues.contains(_onceValue) &&
      _allEligibleOptions.isNotEmpty &&
      _allEligibleOptions.every(
        (option) => _selectedValues.contains(option.value),
      );

  @override
  void initState() {
    super.initState();
    _selectedValues = Set<String>.from(widget.initialSelection);
  }

  bool _isOptionDisabled(String value) {
    if (value == _onceValue) {
      return _selectedValues.any((item) => item != _onceValue);
    }

    return _selectedValues.contains(_onceValue);
  }

  void _toggleValue(String value, bool selected) {
    setState(() {
      if (selected) {
        if (value == _onceValue) {
          _selectedValues = <String>{_onceValue};
        } else {
          _selectedValues.remove(_onceValue);
          _selectedValues.add(value);
        }
      } else {
        _selectedValues.remove(value);
      }
    });
  }

  void _toggleAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedValues = _allEligibleOptions
            .map((option) => option.value)
            .toSet();
      } else {
        _selectedValues.removeAll(
          _allEligibleOptions.map((option) => option.value),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Collection Cycle'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6ECE7)),
              ),
              child: CheckboxListTile(
                value: _allSelected,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                activeColor: _CreatePaymentPageState._brandColor,
                title: const Text(
                  'All',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Select all recurring cycles'),
                onChanged: (checked) => _toggleAll(checked ?? false),
              ),
            ),
            const SizedBox(height: 10),
            for (final option in widget.options)
              CheckboxListTile(
                value: _selectedValues.contains(option.value),
                enabled: !_isOptionDisabled(option.value),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: _CreatePaymentPageState._brandColor,
                title: Text(option.label),
                onChanged: (checked) {
                  _toggleValue(option.value, checked ?? false);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _CreatePaymentPageState._brandColor,
          ),
          onPressed: () => Navigator.of(context).pop(_selectedValues),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ApplicableForDialogState extends State<_ApplicableForDialog> {
  late Set<String> _selectedFlatIds;
  final Set<String> _expandedNodeKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedFlatIds = Set<String>.from(widget.initialSelection);
  }

  Set<String> get _allFlatIds {
    final flatIds = <String>{};
    for (final node in widget.nodes) {
      flatIds.addAll(node.flatIds);
    }
    return flatIds;
  }

  bool get _areAllSelected {
    final allFlatIds = _allFlatIds;
    return allFlatIds.isNotEmpty && _selectedFlatIds.containsAll(allFlatIds);
  }

  bool get _areSomeSelected {
    return _selectedFlatIds.isNotEmpty && !_areAllSelected;
  }

  bool _isNodeSelected(_FlatSelectionNode node) {
    final flatIds = node.flatIds;
    return flatIds.isNotEmpty && flatIds.every(_selectedFlatIds.contains);
  }

  bool _isNodePartiallySelected(_FlatSelectionNode node) {
    final flatIds = node.flatIds;
    if (flatIds.isEmpty) {
      return false;
    }

    final selectedCount = flatIds.where(_selectedFlatIds.contains).length;
    return selectedCount > 0 && selectedCount < flatIds.length;
  }

  void _toggleAllFlats(bool selected) {
    setState(() {
      if (selected) {
        _selectedFlatIds = Set<String>.from(_allFlatIds);
      } else {
        _selectedFlatIds.clear();
      }
    });
  }

  void _toggleNode(_FlatSelectionNode node, bool selected) {
    setState(() {
      if (selected) {
        _selectedFlatIds.addAll(node.flatIds);
      } else {
        _selectedFlatIds.removeAll(node.flatIds);
      }
    });
  }

  void _toggleFlat(String flatId, bool selected) {
    setState(() {
      if (selected) {
        _selectedFlatIds.add(flatId);
      } else {
        _selectedFlatIds.remove(flatId);
      }
    });
  }

  void _toggleExpansion(String nodeKey) {
    setState(() {
      if (_expandedNodeKeys.contains(nodeKey)) {
        _expandedNodeKeys.remove(nodeKey);
      } else {
        _expandedNodeKeys.add(nodeKey);
      }
    });
  }

  Widget _buildNode(_FlatSelectionNode node, {double indent = 0}) {
    if (node.isFlat) {
      final flatId = node.flatId!;
      return Padding(
        padding: EdgeInsets.only(left: indent),
        child: CheckboxListTile(
          dense: true,
          value: _selectedFlatIds.contains(flatId),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _CreatePaymentPageState._brandColor,
          contentPadding: EdgeInsets.zero,
          title: Text(node.label),
          onChanged: (value) => _toggleFlat(flatId, value ?? false),
        ),
      );
    }

    final expanded = _expandedNodeKeys.contains(node.key);
    final selected = _isNodeSelected(node);
    final partiallySelected = _isNodePartiallySelected(node);

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                tristate: true,
                value: selected ? true : (partiallySelected ? null : false),
                activeColor: _CreatePaymentPageState._brandColor,
                onChanged: (value) => _toggleNode(node, value ?? false),
              ),
              Expanded(
                child: Text(
                  node.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _toggleExpansion(node.key),
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                tooltip: expanded ? 'Collapse' : 'Expand',
              ),
            ],
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in node.children)
                    _buildNode(child, indent: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9F6FB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Applicable For'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              dense: true,
              tristate: true,
              value: _areAllSelected ? true : (_areSomeSelected ? null : false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _CreatePaymentPageState._brandColor,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'All Flats',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onChanged: (value) => _toggleAllFlats(value ?? false),
            ),
            const Divider(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final node in widget.nodes) _buildNode(node)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _CreatePaymentPageState._brandColor,
          ),
          onPressed: () => Navigator.of(context).pop(_selectedFlatIds),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _PayYourDuePage extends StatelessWidget {
  const _PayYourDuePage({
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFA),
      appBar: AppBar(
        backgroundColor: _CreatePaymentPageState._brandColor,
        foregroundColor: Colors.white,
        title: const Text('Pay Your Due'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: PaymentDetailsModal(
                duePaymentList: duePaymentList,
                dueDetailsByPayment: dueDetailsByPayment,
                formatAsCurrency: formatAsCurrency,
                onPaymentCompleted: onPaymentCompleted,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
