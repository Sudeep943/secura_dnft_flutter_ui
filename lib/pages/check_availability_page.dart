import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../services/api_service.dart';
import '../widgets/brand_artwork.dart';
import '../widgets/sidebar.dart';
import 'app_shell.dart';

class CheckAvailabilityPage extends StatefulWidget {
  const CheckAvailabilityPage({super.key});

  @override
  State<CheckAvailabilityPage> createState() => _CheckAvailabilityPageState();
}

class _CheckAvailabilityPageState extends State<CheckAvailabilityPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventDateController = TextEditingController();
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

  List<Map<String, dynamic>> halls = [];
  String? selectedHallId;
  DateTime? eventDate;
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _loadHalls();
  }

  @override
  void dispose() {
    _eventDateController.dispose();
    super.dispose();
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Future<void> _loadHalls() async {
    final data = await ApiService.getAllHalls();
    if (!mounted) return;

    setState(() {
      halls = data ?? [];
      loading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked == null) return;

    setState(() {
      eventDate = picked;
      _eventDateController.text = _formatDisplayDate(picked);
    });
  }

  String _formatRequestDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    return '$day-${_monthNames[date.month - 1]}-${date.year}';
  }

  String _hallNameForId(String? hallId) {
    if (hallId == null) return '-';

    for (final hall in halls) {
      if (hall['hallId'] == hallId) {
        return (hall['hallName'] ?? hallId) as String;
      }
    }

    return hallId;
  }

  Future<void> _submitAvailabilityCheck() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedHallId == null || eventDate == null) return;

    setState(() {
      submitting = true;
    });

    final response = await ApiService.checkHallAvailability(
      hallId: selectedHallId!,
      eventDate: _formatRequestDate(eventDate!),
    );

    if (!mounted) return;

    setState(() {
      submitting = false;
    });

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check hall availability')),
      );
      return;
    }

    _showAvailabilityResultModal(response);
  }

  void _showAvailabilityResultModal(Map<String, dynamic> response) {
    final messageCode =
        (response['message_code'] ?? response['messageCode'] ?? '') as String;
    final isSuccess = messageCode.startsWith('SUCC');
    final headerColor = isSuccess ? Colors.green : Colors.red;
    final hallName = _hallNameForId(
      response['hallId'] as String? ?? selectedHallId,
    );

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
              isSuccess ? 'Hall Available' : 'Hall Unavailable',
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
                  response['message'] ?? 'No message returned',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text('Hall Name: $hallName', textAlign: TextAlign.center),
                SizedBox(height: 4),
                Text(
                  'Event Date: ${_formatResultDate(response['eventDate'])}',
                  textAlign: TextAlign.center,
                ),
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

  String _formatResultDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return eventDate != null ? _formatDisplayDate(eventDate!) : '-';
    }

    final parsedDate = DateTime.tryParse(value);
    if (parsedDate == null) {
      return value;
    }

    return _formatDisplayDate(parsedDate.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F8F82),
        title: Text('Check Hall Availability'),
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
                                        DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText: 'Hall Name',
                                          ),
                                          value: selectedHallId,
                                          items: halls
                                              .map(
                                                (
                                                  hall,
                                                ) => DropdownMenuItem<String>(
                                                  value:
                                                      hall['hallId'] as String,
                                                  child: Text(
                                                    hall['hallName'] as String,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedHallId = value;
                                            });
                                          },
                                          validator: (value) =>
                                              value == null ? 'Required' : null,
                                        ),
                                        SizedBox(height: 10),
                                        TextFormField(
                                          controller: _eventDateController,
                                          decoration: InputDecoration(
                                            labelText: 'Event Date',
                                            suffixIcon: IconButton(
                                              icon: Icon(Icons.calendar_today),
                                              onPressed: _selectDate,
                                            ),
                                          ),
                                          readOnly: true,
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                              ? 'Required'
                                              : null,
                                        ),
                                        SizedBox(height: 34),
                                        ElevatedButton(
                                          onPressed: submitting
                                              ? null
                                              : _submitAvailabilityCheck,
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
                                              : Text('Check Availability'),
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
      ),
    );
  }
}
