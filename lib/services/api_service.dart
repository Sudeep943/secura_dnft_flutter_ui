import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:8080';

  // static const String _baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://secura-dnft-production.up.railway.app',
  // );

  static String? token;
  static Map<String, dynamic>? userHeader;

  static String? getLoggedInFlatNo() {
    final header = userHeader;
    if (header == null) return null;

    const possibleKeys = [
      'flatNo',
      'flatName',
      'flatNumber',
      'flat_number',
      'flat_no',
      'unitNo',
      'unitName',
      'unitNumber',
      'apartmentFlatNo',
      'apartmentFlatName',
    ];

    for (final key in possibleKeys) {
      final value = header[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }

  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      token = data['token'];
      userHeader = data['header'];
      return token;
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getDashboardData() async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/generic/getDahboardData"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userHeader),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>?> getAllHalls() async {
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$_baseUrl/booking/getAllHalls"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['halls']);
    }

    return null;
  }

  static Future<Map<String, dynamic>?> checkHallAvailability({
    required String hallId,
    required String eventDate,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/booking/checkHallAvailability"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'genericHeader': userHeader,
        'hallId': hallId,
        'eventDate': eventDate,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getBookings() async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/booking/getBookings"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'genericHeader': userHeader}),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getBooking({
    required String bookingId,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/booking/getBooking"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'genericHeader': userHeader, 'bookingId': bookingId}),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> updateBooking({
    required String bookingId,
    required String status,
    String reason = '',
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/booking/updateBooking"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'genericHeader': userHeader,
        'bookingId': bookingId,
        'reason': reason,
        'status': status,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> createProfile(
    Map<String, dynamic> requestBody,
  ) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/createProfile"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> createRazorPayOrder({
    required String amountInPaisa,
    required String eventDate,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/payment/razorPayCreateOrder"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'genericHeader': userHeader,
        'amountInPaisa': amountInPaisa,
        'currency': 'INR',
        'eventDate': eventDate,
        'transactionType': 'BOOKING',
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/payment/verifyPayment"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> bookHall(
    Map<String, dynamic> requestBody,
  ) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/booking/bookHall"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
