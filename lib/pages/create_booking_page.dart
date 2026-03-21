import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

class CreateBookingPage extends StatefulWidget {
  @override
  _CreateBookingPageState createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final _formKey = GlobalKey<FormState>();
  String flatNo = '';
  DateTime? eventDate;
  String expectedGuest = '';
  String bookingType = 'PRIVATE';
  String bookingPurpose = '';
  String? selectedHallId;
  String? selectedHallName;
  List<Map<String, dynamic>> halls = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHalls();
  }

  fetchHalls() async {
    final data = await ApiService.getAllHalls();
    setState(() {
      halls = data ?? [];
      loading = false;
    });
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != eventDate) {
      setState(() {
        eventDate = picked;
      });
    }
  }

  submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (eventDate == null || selectedHallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final requestBody = {
      "genericHeader": ApiService.userHeader,
      "flatNo": flatNo,
      "eventDate": eventDate!.toIso8601String(),
      "expectedGuest": expectedGuest,
      "bookingType": bookingType,
      "bookingPurpose": bookingPurpose,
      "bookingHallId": selectedHallId,
      "bookingHallName": selectedHallName,
    };

    final response = await ApiService.bookHall(requestBody);
    if (response != null) {
      showBookingResultModal(response);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create booking')));
    }
  }

  void showBookingResultModal(Map<String, dynamic> response) {
    final messageCode = response['messageCode'] as String;
    final isSuccess = messageCode.startsWith('SUCC');
    final headerColor = isSuccess ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
        title: Text("Create New Booking"),
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
                  : Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Flat No'),
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
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: eventDate != null
                                  ? eventDate!.toLocal().toString().split(
                                      ' ',
                                    )[0]
                                  : '',
                            ),
                            validator: (value) =>
                                eventDate == null ? 'Required' : null,
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Expected Guests',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                            onSaved: (value) => expectedGuest = value!,
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Booking Type',
                            ),
                            value: bookingType,
                            items: ['PRIVATE']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => bookingType = value!),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Booking Purpose',
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                            onSaved: (value) => bookingPurpose = value!,
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Hall',
                            ),
                            value: selectedHallId,
                            items: halls
                                .map(
                                  (hall) => DropdownMenuItem<String>(
                                    value: hall['hallId'] as String,
                                    child: Text(hall['hallName'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              final hall = halls.firstWhere(
                                (h) => h['hallId'] == value,
                              );
                              setState(() {
                                selectedHallId = value;
                                selectedHallName = hall['hallName'] as String;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: submitBooking,
                            child: Text('Submit Booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0F8F82),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
