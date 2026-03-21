import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? token;

  static Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("http://localhost:8080/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      token = response.body;
      return token;
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getDashboardData(
    Map<String, dynamic> requestBody,
  ) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("http://localhost:8080/generic/getDahboardData"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}
