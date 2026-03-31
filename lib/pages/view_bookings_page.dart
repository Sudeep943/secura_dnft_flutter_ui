import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class ViewBookingsPage extends StatefulWidget {
  const ViewBookingsPage({super.key, this.embedded = false, this.onBack});

  final bool embedded;
  final VoidCallback? onBack;

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

  String? _rawBookingDocument(Map<String, dynamic> booking) {
    final value = booking['bkngDocumet'] ?? booking['bookingDocument'];
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  Uint8List? _decodeDocumentBytes(String? encodedDocument) {
    if (encodedDocument == null || encodedDocument.isEmpty) {
      return null;
    }

    final normalized = encodedDocument.contains(',')
        ? encodedDocument.split(',').last
        : encodedDocument;

    try {
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  bool _isPdfDocument(Uint8List bytes) {
    if (bytes.length < 4) {
      return false;
    }

    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  String _documentFileName(Map<String, dynamic> booking, Uint8List bytes) {
    final bookingId = _bookingId(
      booking,
    ).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final extension = _isPdfDocument(bytes) ? 'pdf' : 'png';
    return '${bookingId == '-' ? 'booking_document' : bookingId}.$extension';
  }

  Future<void> _downloadBookingDocument(Map<String, dynamic> booking) async {
    final rawDocument = _rawBookingDocument(booking);
    final bytes = _decodeDocumentBytes(rawDocument);
    if (bytes == null || bytes.isEmpty) {
      _showMessageModal(
        'Unable to read the selected booking document.',
        false,
        title: 'Document Error',
      );
      return;
    }

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Download Booking Document',
      fileName: _documentFileName(booking, bytes),
      type: FileType.custom,
      allowedExtensions: _isPdfDocument(bytes)
          ? ['pdf']
          : ['png', 'jpg', 'jpeg', 'webp'],
      bytes: bytes,
      lockParentWindow: true,
    );

    if (!mounted || savedPath == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document downloaded successfully.')),
    );
  }

  Future<void> _showDocumentModal(Map<String, dynamic> booking) async {
    final rawDocument = _rawBookingDocument(booking);
    final bytes = _decodeDocumentBytes(rawDocument);
    if (bytes == null || bytes.isEmpty) {
      _showMessageModal(
        'No Documents Available',
        false,
        title: 'Document Unavailable',
      );
      return;
    }

    final isPdf = _isPdfDocument(bytes);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          clipBehavior: Clip.antiAlias,
          backgroundColor: const Color(0xFFF7F4FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            color: _brandColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: const Text(
              'Booking Document',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          content: SizedBox(
            width: 520,
            child: isPdf
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 96,
                        color: Color(0xFFB3261E),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Preview is not available for PDF documents. Use Download to save the file.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _downloadBookingDocument(booking);
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download'),
            ),
          ],
        );
      },
    );
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
      DataColumn(label: Text('Event Date', style: headingStyle)),
      DataColumn(label: Text('Hall Name', style: headingStyle)),
      DataColumn(label: Text('Booking Type', style: headingStyle)),
      DataColumn(label: Text('Tender', style: headingStyle)),
      DataColumn(label: Text('Booking Status', style: headingStyle)),
      DataColumn(
        label: Center(child: Text('Document', style: headingStyle)),
      ),
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
      return const Text('No Action Required');
    }

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
            label: 'Cancel',
            backgroundColor: const Color(0xFFB3261E),
            onPressed: actionInProgress
                ? null
                : () async {
                    await _openReasonModal(
                      bookingId: bookingId,
                      status: 'CANCELLED',
                      title: 'Cancel Booking',
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

    return const Text('No Action Required');
  }

  Widget _buildDocumentCell(Map<String, dynamic> booking) {
    final rawDocument = _rawBookingDocument(booking);
    if (rawDocument == null) {
      return const Text('No Documents Available');
    }

    return Tooltip(
      message: 'View Document',
      child: IconButton(
        onPressed: () => _showDocumentModal(booking),
        icon: const Icon(Icons.description_rounded, color: _brandColor),
      ),
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
            Text(_formatDate(booking['bkngEvntDt'] ?? booking['eventDate'])),
          ),
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
          DataCell(Text(_bookingValue(booking, ['bkngType', 'bookingType']))),
          DataCell(Text(_bookingValue(booking, ['tender']))),
          DataCell(
            Text(
              _stringValue(status),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(_buildDocumentCell(booking)),
          DataCell(SizedBox(width: 320, child: _buildActionCell(booking))),
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

  Widget _buildEmbeddedHeader() {
    final onBack = widget.onBack;
    if (!widget.embedded || onBack == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 59, 52, 0.05),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF5FBF9),
                foregroundColor: const Color(0xFF0F8F82),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'View Bookings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF124B45),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Review approvals, payments, search results, and booking actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1680),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildEmbeddedHeader(),
                    _buildSearchBar(),
                    if (_showErrorMessage) ...[
                      const SizedBox(height: 18),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : bookings.isEmpty
                            ? Center(
                                child: Text(
                                  _showErrorMessage
                                      ? 'No bookings found'
                                      : (message ?? 'No bookings found'),
                                  style: const TextStyle(
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
                                      minWidth: isMobile(context) ? 1180 : 1260,
                                    ),
                                    child: Scrollbar(
                                      controller: _verticalScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      notificationPredicate: (notification) {
                                        return notification.metrics.axis ==
                                            Axis.vertical;
                                      },
                                      child: SingleChildScrollView(
                                        controller: _verticalScrollController,
                                        child: DataTable(
                                          headingRowColor:
                                              const WidgetStatePropertyAll(
                                                _brandColor,
                                              ),
                                          dataRowMinHeight: 70,
                                          dataRowMaxHeight: 96,
                                          columns: _buildColumns(),
                                          rows: _buildRows(),
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
        title: Text('View Bookings'),
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
}
