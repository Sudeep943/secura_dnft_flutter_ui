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
  int _selectedFlatTypeIndex = 0;
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
        response.containsKey('paymentId') ||
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

  String _formatCurrencyValueOrDash(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    if (value.isEmpty) {
      return '--';
    }

    return value.startsWith('₹') ? value : '₹$value';
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

    final amount =
        response['amountExcludingGst']?.toString().trim() ??
        response['amount']?.toString().trim() ??
        '';
    final totalAmount =
        response['amountIncludingGst']?.toString().trim() ??
        response['totalAmount']?.toString().trim() ??
        '';
    final gstAmount = response['gstAmount']?.toString().trim() ?? '';
    final dueDateText = response['dueDate']?.toString().trim() ?? '';
    final gstPercent = response['gstPercent']?.toString().trim() ?? '';

    if (amount.isEmpty && totalAmount.isEmpty && gstAmount.isEmpty) {
      return null;
    }

    return _DueAmountDetail(
      amount: amount,
      dueDateText: dueDateText,
      dueDate: _parseDueDate(dueDateText),
      gstAmount: gstAmount,
      gstPercent: gstPercent,
      status: '',
      totalAmount: totalAmount,
    );
  }

  List<_FlatTypeDueAmountItem> _activeFlatTypeDueAmountDetails(
    Map<String, dynamic>? response,
  ) {
    final flatTypeDetails = _flatTypeDueAmountDetails(response);
    final entries = <_FlatTypeDueAmountItem>[];

    for (final entry in flatTypeDetails.entries) {
      final activeDetail = _resolvePrimaryActiveDueDetail(entry.value);
      if (activeDetail == null) {
        continue;
      }

      entries.add(
        _FlatTypeDueAmountItem(flatLabel: entry.key, detail: activeDetail),
      );
    }

    entries.sort(
      (left, right) => _compareNaturalValues(left.flatLabel, right.flatLabel),
    );
    return entries;
  }

  _DueAmountDetail? _resolvePrimaryActiveDueDetail(
    List<_DueAmountDetail> details,
  ) {
    final activeDetails = details
        .where((detail) => detail.status.toUpperCase() == 'ACTIVE')
        .toList();
    if (activeDetails.isEmpty) {
      return null;
    }

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

      return leftDate.compareTo(rightDate);
    });

    return activeDetails.first;
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

  _DueAmountDetail? _resolveUpcomingDueDetail(Map<String, dynamic>? response) {
    final details = _listOfDueAmountDetails(response);
    if (details.isEmpty) {
      return _singleDueAmountDetail(response);
    }

    final today = DateTime.now();
    final activeDetails = details
        .where((detail) => detail.status.toUpperCase() == 'ACTIVE')
        .toList();

    if (activeDetails.isEmpty) {
      return details.first;
    }

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

      final leftIsPast = leftDate.isBefore(
        DateTime(today.year, today.month, today.day),
      );
      final rightIsPast = rightDate.isBefore(
        DateTime(today.year, today.month, today.day),
      );

      if (leftIsPast != rightIsPast) {
        return leftIsPast ? 1 : -1;
      }

      return leftDate.compareTo(rightDate);
    });

    return activeDetails.first;
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

  DateTime? _parseDueDate(String? value) {
    return _parseStaticDueDate(value);
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
        _selectedFlatTypeIndex = 0;
      } else {
        _dueDetails = null;
        _dueDetailsError = _responseMessage(response);
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

    return nodes;
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
        label: 'Tower $towerName',
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
        .toList();
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
      _applicableFor = Set<String>.from(_allApplicableFlatIds);
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

  Widget _buildFlatTypeDueAmountSection(
    List<_FlatTypeDueAmountItem> flatTypeDetails,
    bool mobile,
    String fallbackGstPercent,
  ) {
    final selectedIndex = _resolvedFlatTypeIndex(flatTypeDetails.length);
    final selectedDetail = flatTypeDetails[selectedIndex];
    final canGoPrevious = selectedIndex > 0;
    final canGoNext = selectedIndex < flatTypeDetails.length - 1;
    final gstPercent = selectedDetail.detail.gstPercent.isNotEmpty
        ? selectedDetail.detail.gstPercent
        : fallbackGstPercent;

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
                        label: 'GST Percent',
                        value: gstPercent.isEmpty ? '--' : '$gstPercent%',
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
    final upcomingDueDetail = _resolveUpcomingDueDetail(_dueDetails);
    final flatTypeDetails = _activeFlatTypeDueAmountDetails(_dueDetails);
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
                Text(
                  flatTypeDetails.isNotEmpty
                      ? 'This panel refreshes whenever payment amount, GST, collection dates, cycle, mode, or capita changes. Flat type wise due details are shown when the API does not return a single active due snapshot.'
                      : 'This panel refreshes whenever payment amount, GST, collection dates, cycle, mode, or capita changes.',
                  style: const TextStyle(color: Colors.black54, height: 1.5),
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
          else if (flatTypeDetails.isNotEmpty && upcomingDueDetail == null)
            _buildFlatTypeDueAmountSection(flatTypeDetails, mobile, gstPercent)
          else if (_dueDetails != null &&
              upcomingDueDetail == null &&
              flatTypeDetails.isEmpty)
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
          if (flatTypeDetails.isNotEmpty && upcomingDueDetail != null) ...[
            const SizedBox(height: 20),
            _buildFlatTypeDueAmountSection(flatTypeDetails, mobile, gstPercent),
          ],
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
    required this.gstAmount,
    required this.gstPercent,
    required this.status,
    required this.totalAmount,
  });

  factory _DueAmountDetail.fromMap(Map<String, dynamic> map) {
    final dueDateText = map['dueDate']?.toString().trim() ?? '';
    return _DueAmountDetail(
      amount: map['amount']?.toString().trim() ?? '',
      dueDateText: dueDateText,
      dueDate: _CreatePaymentPageState._parseStaticDueDate(dueDateText),
      gstAmount: map['gstAmount']?.toString().trim() ?? '',
      gstPercent: map['gstPercent']?.toString().trim() ?? '',
      status: map['status']?.toString().trim() ?? '',
      totalAmount: map['totalAmount']?.toString().trim() ?? '',
    );
  }

  final String amount;
  final String dueDateText;
  final DateTime? dueDate;
  final String gstAmount;
  final String gstPercent;
  final String status;
  final String totalAmount;
}

class _FlatTypeDueAmountItem {
  const _FlatTypeDueAmountItem({required this.flatLabel, required this.detail});

  final String flatLabel;
  final _DueAmountDetail detail;
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
