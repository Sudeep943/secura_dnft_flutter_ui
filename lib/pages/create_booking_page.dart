import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/razorpay_checkout.dart';
import '../widgets/sidebar.dart';

class CreateBookingPage extends StatefulWidget {
  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  static const String _razorpayKey = 'rzp_test_SRxceBfBqGmeGy';

  final _formKey = GlobalKey<FormState>();
  final _eventDateController = TextEditingController();

  String flatNo = '';
  DateTime? eventDate;
  String expectedGuest = '';
  String bookingType = 'PRIVATE';
  String bookingPurpose = '';
  String? selectedHallId;
  String? selectedHallName;
  String? selectedHallPrice;
  String paymentTender = 'ONLINE';
  List<Map<String, dynamic>> halls = [];
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchHalls();
  }

  @override
  void dispose() {
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

  String _formatHallPrice(String value) {
    final trimmedValue = value.trim();
    final hasCurrency = trimmedValue.startsWith('₹');
    final hasPerDay = trimmedValue.toLowerCase().contains('per day');

    final valueWithCurrency = hasCurrency ? trimmedValue : '₹$trimmedValue';
    return hasPerDay ? valueWithCurrency : '$valueWithCurrency per day';
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

  String? _readHallPrice(Map<String, dynamic> hall) {
    const possibleKeys = [
      'hallPrice',
      'price',
      'hallAmount',
      'bookingPrice',
      'amount',
      'hallRate',
      'rate',
    ];

    for (final key in possibleKeys) {
      final value = hall[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
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
    return paymentTender == 'CASH' ? 'Cash' : 'Online';
  }

  Future<void> _submitBookingRequest({String? transactionId}) async {
    final requestBody = {
      'genericHeader': ApiService.userHeader,
      'flatNo': flatNo,
      'eventDate': eventDate!.toIso8601String(),
      'expectedGuest': expectedGuest,
      'bookingType': bookingType,
      'bookingPurpose': bookingPurpose,
      'bookingHallId': selectedHallId,
      'bookingHallName': selectedHallName,
      'tender': _apiTenderValue(),
      if (transactionId != null) 'bookingTransactionId': transactionId,
    };

    final response = await ApiService.bookHall(requestBody);
    if (!mounted) return;

    setState(() {
      submitting = false;
    });

    if (response != null) {
      showBookingResultModal(response);
    } else {
      _showStatusModal(
        title: 'Booking Failed',
        message: 'Failed to create booking',
        isSuccess: false,
      );
    }
  }

  Future<void> submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (eventDate == null || selectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (paymentTender == 'CASH') {
      setState(() {
        submitting = true;
      });
      await _submitBookingRequest();
      return;
    }

    final amountInPaise = _amountToPaise(selectedHallPrice);
    if (amountInPaise == null) {
      _showStatusModal(
        title: 'Payment Error',
        message: 'Unable to read hall amount for payment.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    final createOrderResponse = await ApiService.createRazorPayOrder(
      amountInPaisa: amountInPaise.toString(),
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
      amountInPaise: amountInPaise,
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

    await _submitBookingRequest(transactionId: paymentResult.paymentId);
  }

  void showBookingResultModal(Map<String, dynamic> response) {
    final messageCode = (response['messageCode'] ?? '') as String;
    final isSuccess = messageCode.startsWith('SUCC');
    final headerColor = isSuccess ? Colors.green : Colors.red;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('Create New Booking'),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      drawer: isMobile(context) ? Drawer(child: SideBar()) : null,
      body: Row(
        children: [
          if (!isMobile(context)) SideBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final formWidth = isMobile(context)
                    ? constraints.maxWidth * 0.92
                    : constraints.maxWidth * 0.8;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: formWidth,
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Color(0xFF0F8F82),
                              width: 1.5,
                            ),
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
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Flat No',
                                        ),
                                        validator: (value) =>
                                            value!.isEmpty ? 'Required' : null,
                                        onSaved: (value) => flatNo = value!,
                                      ),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Event Date',
                                          suffixIcon: IconButton(
                                            icon: Icon(Icons.calendar_today),
                                            onPressed: () =>
                                                _selectDate(context),
                                          ),
                                        ),
                                        readOnly: true,
                                        controller: _eventDateController,
                                        validator: (value) => eventDate == null
                                            ? 'Required'
                                            : null,
                                      ),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Expected Guests',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) =>
                                            value!.isEmpty ? 'Required' : null,
                                        onSaved: (value) =>
                                            expectedGuest = value!,
                                      ),
                                      SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: 'Booking Type',
                                        ),
                                        value: bookingType,
                                        items:
                                            ['PRIVATE', 'SOCIETY', 'COMMERCIAL']
                                                .map(
                                                  (type) => DropdownMenuItem(
                                                    value: type,
                                                    child: Text(type),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            bookingType = value!;
                                          });
                                        },
                                      ),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Booking Purpose',
                                        ),
                                        validator: (value) =>
                                            value!.isEmpty ? 'Required' : null,
                                        onSaved: (value) =>
                                            bookingPurpose = value!,
                                      ),
                                      SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: 'Select Hall',
                                        ),
                                        value: selectedHallId,
                                        items: halls
                                            .map(
                                              (
                                                hall,
                                              ) => DropdownMenuItem<String>(
                                                value: hall['hallId'] as String,
                                                child: Text(
                                                  hall['hallName'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          final hall = halls.firstWhere(
                                            (h) => h['hallId'] == value,
                                          );
                                          setState(() {
                                            selectedHallId = value;
                                            selectedHallName =
                                                hall['hallName'] as String;
                                            selectedHallPrice = _readHallPrice(
                                              hall,
                                            );
                                          });
                                        },
                                        validator: (value) =>
                                            value == null ? 'Required' : null,
                                      ),
                                      if (selectedHallPrice != null) ...[
                                        SizedBox(height: 16),
                                        Text(
                                          'Tender',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: RadioListTile<String>(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text('Online'),
                                                value: 'ONLINE',
                                                groupValue: paymentTender,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() {
                                                    paymentTender = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child: RadioListTile<String>(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text('Cash'),
                                                value: 'CASH',
                                                groupValue: paymentTender,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setState(() {
                                                    paymentTender = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Hall Price: ${_formatHallPrice(selectedHallPrice!)}',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 34),
                                      ElevatedButton(
                                        onPressed: submitting
                                            ? null
                                            : submitBooking,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0F8F82),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: submitting
                                            ? SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                paymentTender == 'ONLINE'
                                                    ? 'Pay & Submit Booking'
                                                    : 'Submit Booking',
                                              ),
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
            ),
          ),
        ],
      ),
    );
  }
}
