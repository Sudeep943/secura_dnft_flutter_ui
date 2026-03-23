import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? token;
  static Map<String, dynamic>? userHeader;

  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("http://localhost:8080/auth/login"),
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
      Uri.parse("http://localhost:8080/generic/getDahboardData"),
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
      Uri.parse("http://localhost:8080/booking/getAllHalls"),
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
      Uri.parse("http://localhost:8080/booking/checkHallAvailability"),
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
      Uri.parse("http://localhost:8080/booking/getBookings"),
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

  static Future<Map<String, dynamic>?> createRazorPayOrder({
    required String amountInPaisa,
    required String eventDate,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("http://localhost:8080/payment/razorPayCreateOrder"),
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
      Uri.parse("http://localhost:8080/payment/verifyPayment"),
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
      Uri.parse("http://localhost:8080/booking/bookHall"),
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
