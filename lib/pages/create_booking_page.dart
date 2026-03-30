import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../services/razorpay_checkout.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class CreateBookingPage extends StatefulWidget {
  const CreateBookingPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  static const String _razorpayKey = 'rzp_test_SRxceBfBqGmeGy';

  final _formKey = GlobalKey<FormState>();
  final _flatNoController = TextEditingController();
  final _eventDateController = TextEditingController();

  String flatNo = '';
  DateTime? eventDate;
  String expectedGuest = '';
  String bookingType = 'PRIVATE';
  String bookingPurpose = '';
  String? selectedHallId;
  String? selectedHallName;
  String? selectedHallAmount;
  String? selectedHallSecurityAmount;
  String? selectedHallTotalAmount;
  String paymentTender = 'Online';
  String? selectedBookingDocumentBase64;
  String? selectedBookingDocumentName;
  String? hallAvailabilityMessage;
  Color? hallAvailabilityMessageColor;
  List<Map<String, dynamic>> halls = [];
  bool loading = true;
  bool submitting = false;
  bool checkingHallAvailability = false;
  bool hallAvailabilityHasError = false;
  int _hallAvailabilityRequestId = 0;

  @override
  void initState() {
    super.initState();
    _flatNoController.text = ApiService.getLoggedInFlatNo() ?? '';
    flatNo = _flatNoController.text;
    fetchHalls();
  }

  @override
  void dispose() {
    _flatNoController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  Future<void> fetchHalls() async {
    final data = await ApiService.getAllHalls();
    if (!mounted) return;

    setState(() {
      halls = data ?? [];
      loading = false;
    });
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked == null || picked == eventDate) return;

    setState(() {
      eventDate = picked;
      _eventDateController.text = _formatDisplayDate(picked);
    });

    await _checkHallAvailabilityIfReady();
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  String _formatCurrency(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '₹0';
    }

    return trimmedValue.startsWith('₹') ? trimmedValue : '₹$trimmedValue';
  }

  String _readMessageCode(Map<String, dynamic>? response) {
    if (response == null) {
      return '';
    }

    return (response['messageCode'] ?? response['message_code'] ?? '')
        .toString();
  }

  void _resetHallAvailabilityState() {
    _hallAvailabilityRequestId++;
    setState(() {
      checkingHallAvailability = false;
      hallAvailabilityMessage = null;
      hallAvailabilityMessageColor = null;
      hallAvailabilityHasError = false;
    });
  }

  Future<void> _checkHallAvailabilityIfReady() async {
    final currentHallId = selectedHallId;
    final currentEventDate = eventDate;
    if (currentHallId == null ||
        currentHallId.isEmpty ||
        currentEventDate == null) {
      _resetHallAvailabilityState();
      return;
    }

    final requestId = ++_hallAvailabilityRequestId;
    setState(() {
      checkingHallAvailability = true;
      hallAvailabilityMessage = null;
      hallAvailabilityMessageColor = null;
      hallAvailabilityHasError = false;
    });

    final response = await ApiService.checkHallAvailability(
      hallId: currentHallId,
      eventDate: _formatApiDate(currentEventDate),
    );

    if (!mounted || requestId != _hallAvailabilityRequestId) {
      return;
    }

    final messageCode = _readMessageCode(response);
    final message = response?['message']?.toString().trim();
    final isSuccess = messageCode.startsWith('SUCC');
    final isError = messageCode.startsWith('ERR');

    setState(() {
      checkingHallAvailability = false;
      hallAvailabilityMessage = message?.isNotEmpty == true
          ? message
          : response == null
          ? 'Unable to check hall availability right now.'
          : null;
      hallAvailabilityMessageColor = isSuccess
          ? const Color(0xFF0B5E20)
          : isError || response == null
          ? const Color(0xFF8B1E1E)
          : null;
      hallAvailabilityHasError = isError || response == null;
    });
  }

  void _showStatusModal({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Color(0xFFF7F4FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            width: double.infinity,
            color: isSuccess ? Colors.green : Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.56,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String? _normalizeAmountString(dynamic rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    final normalizedValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalizedValue.isEmpty) {
      return null;
    }

    final parsedAmount = double.tryParse(normalizedValue);
    if (parsedAmount == null) {
      return null;
    }

    if (parsedAmount == parsedAmount.truncateToDouble()) {
      return parsedAmount.toInt().toString();
    }

    return parsedAmount.toString();
  }

  Map<String, String?> _readHallPricing(Map<String, dynamic> hall) {
    Map<String, dynamic>? pricing;
    final hallAmountValue = hall['hallAmount'];

    if (hallAmountValue is Map<String, dynamic>) {
      pricing = hallAmountValue;
    } else if (hallAmountValue is Map) {
      pricing = Map<String, dynamic>.from(hallAmountValue);
    } else if (hallAmountValue is String) {
      final trimmedValue = hallAmountValue.trim();
      if (trimmedValue.startsWith('{') && trimmedValue.endsWith('}')) {
        try {
          final decoded = jsonDecode(trimmedValue);
          if (decoded is Map<String, dynamic>) {
            pricing = decoded;
          } else if (decoded is Map) {
            pricing = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          pricing = null;
        }
      }
    }

    final normalizedHallAmount = _normalizeAmountString(
      pricing?['hallAmount'] ??
          hall['hallPrice'] ??
          hall['price'] ??
          hallAmountValue,
    );
    final normalizedSecurityAmount = _normalizeAmountString(
      pricing?['hallSecurityAmount'] ??
          hall['hallSecurityAmount'] ??
          hall['securityAmount'] ??
          hall['securityDeposit'],
    );

    return {
      'hallAmount': normalizedHallAmount,
      'securityAmount': normalizedSecurityAmount,
    };
  }

  String? _sumAmounts(String? firstAmount, String? secondAmount) {
    final first = double.tryParse(firstAmount ?? '');
    final second = double.tryParse(secondAmount ?? '');
    if (first == null && second == null) {
      return null;
    }

    final total = (first ?? 0) + (second ?? 0);
    if (total == total.truncateToDouble()) {
      return total.toInt().toString();
    }

    return total.toString();
  }

  int? _amountToPaise(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final normalizedValue = rawValue.replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalizedValue.isEmpty) {
      return null;
    }

    final parsedAmount = double.tryParse(normalizedValue);
    if (parsedAmount == null || parsedAmount <= 0) {
      return null;
    }

    return (parsedAmount * 100).round();
  }

  String _apiTenderValue() {
    return paymentTender;
  }

  String? _amountPaidFromPaise(int? amountInPaise) {
    if (amountInPaise == null || amountInPaise <= 0) {
      return null;
    }

    return (amountInPaise ~/ 100).toString();
  }

  Future<void> _submitBookingRequest({
    String? transactionId,
    int? paidAmountInPaise,
    String? bookingDocument,
  }) async {
    final trimmedFlatNo = _flatNoController.text.trim();
    final amountPaid =
        _amountPaidFromPaise(paidAmountInPaise) ?? selectedHallTotalAmount;
    final requestBody = {
      'genericHeader': ApiService.userHeader,
      'flatNo': trimmedFlatNo,
      'eventDate': eventDate!.toIso8601String(),
      'expectedGuest': expectedGuest,
      'bookingType': bookingType,
      'bookingPurpose': bookingPurpose,
      'bookingHallId': selectedHallId,
      'bookingHallName': selectedHallName,
      'hallName': selectedHallName,
      'tender': _apiTenderValue(),
      'securityDeposit': selectedHallSecurityAmount ?? '0',
      'bookingDocument': bookingDocument ?? '',
      if (transactionId case final bookingTransactionId?)
        'bookingTransactionId': bookingTransactionId,
      if (amountPaid case final normalizedAmountPaid?)
        'amountPaid': normalizedAmountPaid,
    };

    final response = await ApiService.bookHall(requestBody);
    if (!mounted) return;

    setState(() {
      submitting = false;
    });

    if (response != null) {
      final messageCode = _readMessageCode(response);
      final isSuccess = messageCode.startsWith('SUCC');
      await showBookingResultModal(response);
      if (!mounted || !isSuccess) {
        return;
      }

      openAppShellSection(context, AppSection.bookings);
    } else {
      _showStatusModal(
        title: 'Booking Failed',
        message: 'Failed to create booking',
        isSuccess: false,
      );
    }
  }

  Future<void> _pickBookingDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final selectedFile = result.files.single;
    final bytes = selectedFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showStatusModal(
        title: 'Upload Failed',
        message: 'The selected document could not be read.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      selectedBookingDocumentBase64 = base64Encode(bytes);
      selectedBookingDocumentName = selectedFile.name;
    });
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    flatNo = _flatNoController.text.trim();

    if (eventDate == null || selectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (checkingHallAvailability) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checking hall availability. Please wait.')),
      );
      return;
    }

    if (hallAvailabilityHasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hallAvailabilityMessage ??
                'Hall is not available for the selected date.',
          ),
        ),
      );
      return;
    }

    final totalAmountInPaise = _amountToPaise(selectedHallTotalAmount);
    if (totalAmountInPaise == null) {
      _showStatusModal(
        title: 'Payment Error',
        message: 'Unable to read the selected hall pricing details.',
        isSuccess: false,
      );
      return;
    }

    if (paymentTender == 'Offline Bank Transfer' &&
        (selectedBookingDocumentBase64 == null ||
            selectedBookingDocumentBase64!.isEmpty)) {
      _showStatusModal(
        title: 'Upload Required',
        message: 'Please upload the bank transfer screenshot or PDF.',
        isSuccess: false,
      );
      return;
    }

    if (paymentTender == 'Cash') {
      setState(() {
        submitting = true;
      });
      await _submitBookingRequest(paidAmountInPaise: totalAmountInPaise);
      return;
    }

    if (paymentTender == 'Offline Bank Transfer') {
      setState(() {
        submitting = true;
      });
      await _submitBookingRequest(
        paidAmountInPaise: totalAmountInPaise,
        bookingDocument: selectedBookingDocumentBase64,
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    final createOrderResponse = await ApiService.createRazorPayOrder(
      amountInPaisa: totalAmountInPaise.toString(),
      eventDate: eventDate!.toIso8601String(),
    );

    if (!mounted) return;

    if (createOrderResponse == null) {
      setState(() {
        submitting = false;
      });
      _showStatusModal(
        title: 'Payment Error',
        message: 'Unable to create Razorpay order.',
        isSuccess: false,
      );
      return;
    }

    final createOrderCode =
        (createOrderResponse['messageCode'] ?? '') as String;
    if (!createOrderCode.startsWith('SUCC')) {
      setState(() {
        submitting = false;
      });
      _showStatusModal(
        title: 'Payment Error',
        message:
            (createOrderResponse['message'] ?? 'Unable to create payment order')
                as String,
        isSuccess: false,
      );
      return;
    }

    final order = createOrderResponse['order'] as Map<String, dynamic>?;
    final orderId = order?['id']?.toString();
    final orderAmountInPaise = _parseOrderAmountInPaise(order?['amount']);
    if (orderId == null || orderId.isEmpty) {
      setState(() {
        submitting = false;
      });
      _showStatusModal(
        title: 'Payment Error',
        message: 'Payment order ID was not returned.',
        isSuccess: false,
      );
      return;
    }

    final paymentResult = await openRazorpayCheckout(
      key: _razorpayKey,
      orderId: orderId,
      amountInPaise: totalAmountInPaise,
      name: 'Secura Hall Booking',
      description: selectedHallName ?? 'Hall booking payment',
      customerName: ApiService.userHeader?['userId']?.toString(),
    );

    if (!mounted) return;

    if (!paymentResult.success) {
      setState(() {
        submitting = false;
      });
      _showStatusModal(
        title: 'Payment Error',
        message: paymentResult.errorMessage ?? 'Payment was not completed.',
        isSuccess: false,
      );
      return;
    }

    final verifyResponse = await ApiService.verifyPayment(
      razorpayOrderId: paymentResult.orderId ?? orderId,
      razorpayPaymentId: paymentResult.paymentId ?? '',
      razorpaySignature: paymentResult.signature ?? '',
    );

    if (!mounted) return;

    if (verifyResponse == null) {
      setState(() {
        submitting = false;
      });
      _showStatusModal(
        title: 'Payment Verification Failed',
        message: 'Unable to verify payment.',
        isSuccess: false,
      );
      return;
    }

    final verifyCode = (verifyResponse['messageCode'] ?? '') as String;
    if (!verifyCode.startsWith('SUCC')) {
      setState(() {
        submitting = false;
      });
      _showStatusModal(
        title: 'Payment Verification Failed',
        message:
            (verifyResponse['message'] ?? 'Payment verification failed')
                as String,
        isSuccess: false,
      );
      return;
    }

    await _submitBookingRequest(
      transactionId: paymentResult.paymentId,
      paidAmountInPaise:
          paymentResult.amountInPaise ??
          orderAmountInPaise ??
          totalAmountInPaise,
    );
  }

  int? _parseOrderAmountInPaise(dynamic rawAmount) {
    if (rawAmount == null) {
      return null;
    }

    if (rawAmount is int) {
      return rawAmount;
    }

    return int.tryParse(rawAmount.toString());
  }

  Future<void> showBookingResultModal(Map<String, dynamic> response) async {
    final messageCode = _readMessageCode(response);
    final isSuccess = messageCode.startsWith('SUCC');
    final headerColor = isSuccess ? Colors.green : Colors.red;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Color(0xFFF7F4FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            width: double.infinity,
            color: headerColor,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(
              isSuccess ? 'Booking Successful' : 'Booking Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                Text(
                  response['message'] ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                if (isSuccess) ...[
                  Text(
                    'Booking ID: ${response['bookingId']}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Booking Status: ${response['bookingStatus']}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final formWidth = isMobile(context)
            ? constraints.maxWidth * 0.92
            : constraints.maxWidth * 0.8;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Center(
              child: SizedBox(
                width: formWidth,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Color(0xFF0F8F82), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: loading
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _flatNoController,
                                decoration: InputDecoration(
                                  labelText: 'Flat No',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  flatNo = value!.trim();
                                },
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: _eventDateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Event Date',
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_today),
                                    onPressed: () => _selectDate(context),
                                  ),
                                ),
                                validator: (value) {
                                  if (eventDate == null) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                              if (checkingHallAvailability ||
                                  hallAvailabilityMessage != null) ...[
                                SizedBox(height: 6),
                                Text(
                                  checkingHallAvailability
                                      ? 'Checking hall availability...'
                                      : hallAvailabilityMessage ?? '',
                                  style: TextStyle(
                                    color: checkingHallAvailability
                                        ? Color(0xFF124B45)
                                        : hallAvailabilityMessageColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              SizedBox(height: 10),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Expected Guests',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  expectedGuest = value!.trim();
                                },
                              ),
                              SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Booking Type',
                                ),
                                value: bookingType,
                                items: ['PRIVATE', 'SOCIETY', 'COMMERCIAL'].map(
                                  (type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    );
                                  },
                                ).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    bookingType = value;
                                  });
                                },
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Booking Purpose',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  bookingPurpose = value!.trim();
                                },
                              ),
                              SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select Hall',
                                ),
                                value: selectedHallId,
                                items: halls.map((hall) {
                                  final hallId = hall['hallId']?.toString();
                                  final hallName = hall['hallName']?.toString();
                                  final pricing = _readHallPricing(hall);
                                  final hallAmount = pricing['hallAmount'];
                                  final displayText = hallAmount == null
                                      ? hallName ?? hallId ?? '-'
                                      : '${hallName ?? hallId ?? '-'} (${_formatCurrency(hallAmount)})';

                                  return DropdownMenuItem<String>(
                                    value: hallId,
                                    child: Text(displayText),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedHallId = value;

                                    Map<String, dynamic>? selectedHall;
                                    for (final hall in halls) {
                                      if (hall['hallId'] == value) {
                                        selectedHall = hall;
                                        break;
                                      }
                                    }

                                    final pricing = _readHallPricing(
                                      selectedHall ?? const <String, dynamic>{},
                                    );
                                    selectedHallName = selectedHall?['hallName']
                                        ?.toString();
                                    selectedHallAmount = pricing['hallAmount'];
                                    selectedHallSecurityAmount =
                                        pricing['securityAmount'];
                                    selectedHallTotalAmount = _sumAmounts(
                                      selectedHallAmount,
                                      selectedHallSecurityAmount,
                                    );
                                  });

                                  _checkHallAvailabilityIfReady();
                                },
                                validator: (value) =>
                                    value == null ? 'Required' : null,
                              ),
                              if (selectedHallAmount != null ||
                                  selectedHallSecurityAmount != null ||
                                  selectedHallTotalAmount != null) ...[
                                SizedBox(height: 10),
                                Container(
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF4FBF9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFFB9E4DD),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (selectedHallAmount != null)
                                        Text(
                                          'Hall Amount: ${_formatCurrency(selectedHallAmount!)}',
                                          style: TextStyle(
                                            color: Color(0xFF124B45),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      if (selectedHallSecurityAmount !=
                                          null) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Security Amount: ${_formatCurrency(selectedHallSecurityAmount!)}',
                                          style: TextStyle(
                                            color: Color(0xFF124B45),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (selectedHallTotalAmount != null) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Total Payable: ${_formatCurrency(selectedHallTotalAmount!)}',
                                          style: TextStyle(
                                            color: Color(0xFF0B5E55),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              SizedBox(height: 10),
                              Text(
                                'Payment Tender',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildTenderOption('Cash'),
                                    SizedBox(width: 12),
                                    _buildTenderOption('Online'),
                                    SizedBox(width: 12),
                                    _buildTenderOption('Offline Bank Transfer'),
                                  ],
                                ),
                              ),
                              if (paymentTender == 'Offline Bank Transfer') ...[
                                SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: submitting
                                      ? null
                                      : _pickBookingDocument,
                                  icon: Icon(Icons.upload_file),
                                  label: Text('Upload Transfer Proof'),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  selectedBookingDocumentName == null
                                      ? 'Accepted formats: image or PDF'
                                      : 'Selected file: $selectedBookingDocumentName',
                                  style: TextStyle(
                                    color: Color(0xFF51605F),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              SizedBox(height: 30),
                              ElevatedButton(
                                onPressed:
                                    submitting ||
                                        checkingHallAvailability ||
                                        hallAvailabilityHasError
                                    ? null
                                    : submitBooking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0F8F82),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: submitting
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text('Submit Booking'),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildPageContent(context);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('Create New Booking'),
      ),
      drawer: isMobile(context)
          ? Drawer(
              child: SideBar(
                selectedSection: AppSection.bookings,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            )
          : null,
      body: BrandBackground(
        child: Row(
          children: [
            if (!isMobile(context))
              SideBar(
                selectedSection: AppSection.bookings,
                onSectionSelected: (section) =>
                    openAppShellSection(context, section),
              ),
            Expanded(child: _buildPageContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTenderOption(String value) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          paymentTender = value;
          if (value != 'Offline Bank Transfer') {
            selectedBookingDocumentBase64 = null;
            selectedBookingDocumentName = null;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: paymentTender == value
                ? const Color(0xFF0F8F82)
                : const Color(0xFFD5E6E2),
          ),
          color: paymentTender == value
              ? const Color(0xFFEAF8F5)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: paymentTender,
              onChanged: (selectedValue) {
                if (selectedValue == null) return;
                setState(() {
                  paymentTender = selectedValue;
                  if (selectedValue != 'Offline Bank Transfer') {
                    selectedBookingDocumentBase64 = null;
                    selectedBookingDocumentName = null;
                  }
                });
              },
            ),
            Text(value),
          ],
        ),
      ),
    );
  }
}
