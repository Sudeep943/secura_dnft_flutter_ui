import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class ViewBookingsPage extends StatefulWidget {
  const ViewBookingsPage({super.key});

  @override
  State<ViewBookingsPage> createState() => _ViewBookingsPageState();
}

class _ViewBookingsPageState extends State<ViewBookingsPage> {
  static const List<String> _monthNames = [
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
  static const Color _brandColor = Color(0xFF0F8F82);
  static const Color _hoverColor = Color(0xFFE0DA84);

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  bool loading = true;
  bool actionInProgress = false;
  String? message;
  String _lastMessageCode = '';
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _loadBookings() async {
    setState(() {
      loading = true;
    });

    final response = await ApiService.getBookings();
    _applyBookingResponse(
      response,
      fallbackMessage: 'Failed to load bookings',
      showErrorModal: true,
    );
  }

  Future<void> _searchBookings() async {
    final bookingId = _searchController.text.trim();
    if (bookingId.isEmpty) {
      await _loadBookings();
      return;
    }

    setState(() {
      loading = true;
    });

    final response = await ApiService.getBooking(bookingId: bookingId);
    _applyBookingResponse(
      response,
      fallbackMessage: 'Failed to search booking',
      showErrorModal: true,
    );
  }

  void _applyBookingResponse(
    Map<String, dynamic>? response, {
    required String fallbackMessage,
    required bool showErrorModal,
  }) {
    if (!mounted) return;

    if (response == null) {
      setState(() {
        loading = false;
        message = fallbackMessage;
        _lastMessageCode = 'ERR';
        bookings = [];
      });
      return;
    }

    final messageCode = (response['messageCode'] ?? '') as String;
    final resultMessage =
        (response['message'] ?? 'No message returned') as String;

    if (messageCode.startsWith('SUCC')) {
      setState(() {
        loading = false;
        message = null;
        _lastMessageCode = messageCode;
        bookings = _extractBookings(response);
      });
      return;
    }

    setState(() {
      loading = false;
      message = resultMessage;
      _lastMessageCode = messageCode;
      bookings = [];
    });

    if (!showErrorModal) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showMessageModal(resultMessage, false);
    });
  }

  List<Map<String, dynamic>> _extractBookings(Map<String, dynamic> response) {
    final bookingList = response['bookingList'];
    if (bookingList is List) {
      return List<Map<String, dynamic>>.from(bookingList);
    }

    final booking = response['booking'];
    if (booking is Map<String, dynamic>) {
      return [booking];
    }

    final bookingDetail = response['bookingDetail'];
    if (bookingDetail is Map<String, dynamic>) {
      return [bookingDetail];
    }

    if (_looksLikeBooking(response)) {
      return [response];
    }

    return [];
  }

  bool _looksLikeBooking(Map<String, dynamic> candidate) {
    return candidate.containsKey('bkngId') ||
        candidate.containsKey('bookingId') ||
        candidate.containsKey('bkngSts');
  }

  String _formatDate(dynamic value) {
    if (value is! String || value.isEmpty) return '-';

    final parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) return value;

    final localDate = parsedDate.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    return '$day-${_monthNames[localDate.month - 1]}-${localDate.year}';
  }

  Color _statusColor(String? status) {
    switch (_normalizedStatus(status)) {
      case 'CANCELED':
      case 'CANCELLED':
        return Colors.red;
      case 'APPROVED':
        return Colors.green;
      case 'REQUEST RECEIVED':
        return Colors.amber.shade800;
      case 'REJECTED':
        return Colors.red.shade700;
      default:
        return Colors.black;
    }
  }

  String _normalizedStatus(String? status) {
    return status?.trim().toUpperCase() ?? '';
  }

  bool get _isAdminAccess {
    return (ApiService.userHeader?['access']?.toString().trim().toUpperCase() ??
            '') ==
        'ADMIN';
  }

  String _stringValue(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _bookingValue(Map<String, dynamic> booking, List<String> keys) {
    for (final key in keys) {
      final value = booking[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '-';
  }

  String _bookingId(Map<String, dynamic> booking) {
    return _bookingValue(booking, ['bkngId', 'bookingId']);
  }

  String _receiptValue(Map<String, dynamic> booking) {
    return _bookingValue(booking, [
      'receipt',
      'receiptNo',
      'receiptNumber',
      'receiptId',
      'rcptNo',
      'rcptId',
    ]);
  }

  void _showMessageModal(
    String resultMessage,
    bool isSuccess, {
    String? title,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          clipBehavior: Clip.antiAlias,
          backgroundColor: Color(0xFFF7F4FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            color: isSuccess ? Colors.green : Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text(
              title ?? (isSuccess ? 'Success' : 'Error'),
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
              resultMessage,
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

  List<DataColumn> _buildColumns() {
    const headingStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    return const [
      DataColumn(label: Text('Booking Id', style: headingStyle)),
      DataColumn(label: Text('Booking Hall', style: headingStyle)),
      DataColumn(label: Text('Booking By', style: headingStyle)),
      DataColumn(label: Text('Flat No', style: headingStyle)),
      DataColumn(label: Text('Event Date', style: headingStyle)),
      DataColumn(label: Text('Booking Date', style: headingStyle)),
      DataColumn(label: Text('Booking Type', style: headingStyle)),
      DataColumn(label: Text('Purpose', style: headingStyle)),
      DataColumn(label: Text('Amount Paid', style: headingStyle)),
      DataColumn(label: Text('Payment Id', style: headingStyle)),
      DataColumn(label: Text('Tender', style: headingStyle)),
      DataColumn(label: Text('Receipt', style: headingStyle)),
      DataColumn(label: Text('Booking Status', style: headingStyle)),
      DataColumn(label: Text('Action', style: headingStyle)),
    ];
  }

  Future<void> _refreshBookings() async {
    if (_searchController.text.trim().isEmpty) {
      await _loadBookings();
      return;
    }

    await _searchBookings();
  }

  Future<void> _submitBookingUpdate({
    required String bookingId,
    required String status,
    String reason = '',
  }) async {
    setState(() {
      actionInProgress = true;
    });

    final response = await ApiService.updateBooking(
      bookingId: bookingId,
      status: status,
      reason: reason,
    );

    if (!mounted) return;

    setState(() {
      actionInProgress = false;
    });

    if (response == null) {
      _showMessageModal(
        'Failed to update booking',
        false,
        title: 'Booking Update Failed',
      );
      return;
    }

    final messageCode = (response['messageCode'] ?? '') as String;
    final responseMessage =
        (response['message'] ?? 'No message returned') as String;
    final isSuccess = messageCode.startsWith('SUCC');

    _showMessageModal(
      responseMessage,
      isSuccess,
      title: isSuccess ? 'Booking Updated' : 'Booking Update Failed',
    );

    if (isSuccess) {
      await _refreshBookings();
    }
  }

  Future<void> _openReasonModal({
    required String bookingId,
    required String status,
    required String title,
  }) async {
    final reasonController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              clipBehavior: Clip.antiAlias,
              backgroundColor: Color(0xFFF7F4FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                width: double.infinity,
                color: _brandColor,
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
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        alignLabelWithHint: true,
                        errorText: errorText,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Close'),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return _hoverColor;
                      }
                      return _brandColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    }),
                  ),
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      setModalState(() {
                        errorText = 'Reason is required';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    await _submitBookingUpdate(
                      bookingId: bookingId,
                      status: status,
                      reason: reason,
                    );
                  },
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();
  }

  Widget _actionButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildActionCell(Map<String, dynamic> booking) {
    final bookingId = _bookingId(booking);
    final status = _normalizedStatus(booking['bkngSts']?.toString());

    if (bookingId == '-') {
      return Text('No Action Can Be Performed');
    }

    if (_isAdminAccess) {
      if (status == 'REQUEST RECEIVED') {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionButton(
              label: 'Approve',
              backgroundColor: Colors.green,
              onPressed: actionInProgress
                  ? null
                  : () async {
                      await _submitBookingUpdate(
                        bookingId: bookingId,
                        status: 'APPROVED',
                      );
                    },
            ),
            _actionButton(
              label: 'Reject',
              backgroundColor: Colors.red,
              onPressed: actionInProgress
                  ? null
                  : () async {
                      await _openReasonModal(
                        bookingId: bookingId,
                        status: 'REJECTED',
                        title: 'Reject Booking',
                      );
                    },
            ),
          ],
        );
      }

      if (status == 'APPROVED') {
        return _actionButton(
          label: 'Cancel',
          backgroundColor: Colors.red,
          onPressed: actionInProgress
              ? null
              : () async {
                  await _openReasonModal(
                    bookingId: bookingId,
                    status: 'CANCELLED',
                    title: 'Cancel Booking',
                  );
                },
        );
      }

      return Text('No Action Can Be Performed');
    }

    return _actionButton(
      label: 'Cancel',
      backgroundColor: Colors.red,
      onPressed: actionInProgress
          ? null
          : () async {
              await _openReasonModal(
                bookingId: bookingId,
                status: 'CANCELLED',
                title: 'Cancel Booking',
              );
            },
    );
  }

  List<DataRow> _buildRows() {
    return bookings.map((booking) {
      final status = booking['bkngSts'] as String?;
      final statusColor = _statusColor(status);

      return DataRow(
        cells: [
          DataCell(Text(_bookingId(booking))),
          DataCell(
            Text(
              _bookingValue(booking, [
                'hallName',
                'bookingHallName',
                'bkngHallName',
                'bkngHallId',
              ]),
            ),
          ),
          DataCell(Text(_bookingValue(booking, ['bkngBy', 'bookingBy']))),
          DataCell(Text(_bookingValue(booking, ['bkngFltNo', 'flatNo']))),
          DataCell(
            Text(_formatDate(booking['bkngEvntDt'] ?? booking['eventDate'])),
          ),
          DataCell(
            Text(_formatDate(booking['creatTs'] ?? booking['bkngDate'])),
          ),
          DataCell(Text(_bookingValue(booking, ['bkngType', 'bookingType']))),
          DataCell(
            Text(_bookingValue(booking, ['bkngPros', 'bookingPurpose'])),
          ),
          DataCell(Text(_bookingValue(booking, ['amountPaid']))),
          DataCell(
            Text(
              _bookingValue(booking, [
                'transaction',
                'bookingTransactionId',
                'paymentId',
                'transactionId',
              ]),
            ),
          ),
          DataCell(Text(_bookingValue(booking, ['tender']))),
          DataCell(Text(_receiptValue(booking))),
          DataCell(
            Text(
              _stringValue(status),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(SizedBox(width: 240, child: _buildActionCell(booking))),
        ],
      );
    }).toList();
  }

  Widget _buildSearchBar() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: isMobile(context) ? 280 : 360,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _searchBookings(),
            decoration: InputDecoration(
              labelText: 'Search by Booking Id',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          ),
          onPressed: loading ? null : _searchBookings,
          child: Text('Search'),
        ),
        OutlinedButton(
          onPressed: loading
              ? null
              : () async {
                  _searchController.clear();
                  await _loadBookings();
                },
          child: Text('Reset'),
        ),
      ],
    );
  }

  bool get _showErrorMessage =>
      _lastMessageCode.startsWith('ERR') &&
      message != null &&
      message!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('View Bookings'),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            openAppShellSection(context, AppSection.dashboard);
          },
        ),
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
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1680),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildSearchBar(),
                        if (_showErrorMessage) ...[
                          SizedBox(height: 18),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: loading
                                ? Center(child: CircularProgressIndicator())
                                : bookings.isEmpty
                                ? Center(
                                    child: Text(
                                      _showErrorMessage
                                          ? 'No bookings found'
                                          : (message ?? 'No bookings found'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  )
                                : Scrollbar(
                                    controller: _horizontalScrollController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    notificationPredicate: (notification) {
                                      return notification.metrics.axis ==
                                          Axis.horizontal;
                                    },
                                    child: SingleChildScrollView(
                                      controller: _horizontalScrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: isMobile(context)
                                              ? 1720
                                              : 1850,
                                        ),
                                        child: Scrollbar(
                                          controller: _verticalScrollController,
                                          thumbVisibility: true,
                                          trackVisibility: true,
                                          notificationPredicate:
                                              (notification) {
                                                return notification
                                                        .metrics
                                                        .axis ==
                                                    Axis.vertical;
                                              },
                                          child: SingleChildScrollView(
                                            controller:
                                                _verticalScrollController,
                                            child: DataTable(
                                              headingRowColor:
                                                  WidgetStatePropertyAll(
                                                    _brandColor,
                                                  ),
                                              columns: _buildColumns(),
                                              rows: _buildRows(),
                                              dataRowMinHeight: 64,
                                              dataRowMaxHeight: 92,
                                              columnSpacing: 36,
                                              horizontalMargin: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
