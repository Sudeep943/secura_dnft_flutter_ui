import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/sidebar.dart';

class ViewBookingsPage extends StatefulWidget {
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

  bool loading = true;
  String? message;
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _loadBookings() async {
    final response = await ApiService.getBookings();
    if (!mounted) return;

    if (response == null) {
      setState(() {
        loading = false;
        message = 'Failed to load bookings';
      });
      return;
    }

    final messageCode = (response['messageCode'] ?? '') as String;
    final resultMessage =
        (response['message'] ?? 'No message returned') as String;

    if (messageCode.startsWith('SUCC')) {
      setState(() {
        loading = false;
        message = resultMessage;
        bookings = List<Map<String, dynamic>>.from(
          response['bookingList'] ?? [],
        );
      });
      return;
    }

    setState(() {
      loading = false;
      message = resultMessage;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showMessageModal(resultMessage, false);
    });
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
    switch (status) {
      case 'CANCELED':
        return Colors.red;
      case 'APPROVED':
        return Colors.green;
      case 'REQUEST_RECEIVED':
        return Colors.amber.shade800;
      default:
        return Colors.black;
    }
  }

  void _showMessageModal(String resultMessage, bool isSuccess) {
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
              isSuccess ? 'Bookings Found' : 'Bookings Error',
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
      DataColumn(label: Text('Flat No', style: headingStyle)),
      DataColumn(label: Text('Booking Date', style: headingStyle)),
      DataColumn(label: Text('Event Date', style: headingStyle)),
      DataColumn(label: Text('Hall', style: headingStyle)),
      DataColumn(label: Text('Status', style: headingStyle)),
      DataColumn(label: Text('Booking Type', style: headingStyle)),
    ];
  }

  List<DataRow> _buildRows() {
    return bookings.map((booking) {
      final status = booking['bkngSts'] as String?;
      final statusColor = _statusColor(status);

      return DataRow(
        cells: [
          DataCell(Text((booking['bkngFltNo'] ?? '-') as String)),
          DataCell(Text(_formatDate(booking['bkngDate']))),
          DataCell(Text(_formatDate(booking['bkngEvntDt']))),
          DataCell(Text((booking['bkngHallId'] ?? '-') as String)),
          DataCell(
            Text(
              status ?? '-',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text((booking['bkngType'] ?? '-') as String)),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('View Bookings'),
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
            child: Padding(
              padding: EdgeInsets.all(20),
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : bookings.isEmpty
                  ? Center(
                      child: Text(
                        message ?? 'No bookings found',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            message ?? 'Bookings Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F8F82),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStatePropertyAll(
                                    Color(0xFF0F8F82),
                                  ),
                                  columns: _buildColumns(),
                                  rows: _buildRows(),
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 64,
                                  columnSpacing: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
