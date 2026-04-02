import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;

class ApiService {
  //static const String _baseUrl = 'http://localhost:8080';
  static const String _authEncryptionKeyBase64 =
      'U2VjdXJhTG9naW5LZXlBRVMyNTZWYWx1ZTEyMzQ1Njc=';
  static const String _authEncryptionIvBase64 = 'U2VjdXJhSW5pdFZlYzEyMw==';

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://secura-dnft-production.up.railway.app',
  );

  static String? token;
  static String? loginPassword;
  static Map<String, dynamic>? userHeader;
  static String? dashboardProfilePic;
  static Map<String, dynamic>? profileData;

  static void clearSession() {
    token = null;
    loginPassword = null;
    userHeader = null;
    dashboardProfilePic = null;
    profileData = null;
  }

  static String? get currentUserId {
    final userId = userHeader?['userId']?.toString().trim();
    return userId != null && userId.isNotEmpty ? userId : null;
  }

  static String getDisplayName() {
    final profileName = _composeProfileName(profileData?['prflName']);
    if (profileName != null) {
      return profileName;
    }

    final header = userHeader;
    if (header == null) {
      return 'Resident';
    }

    final candidates = [
      header['profileName'],
      header['name'],
      header['fullName'],
      header['userName'],
      header['username'],
      _composeProfileName(header['prflName']),
      [header['firstName'], header['middleName'], header['lastName']]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .join(' '),
      header['userId'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Resident';
  }

  static String? _composeProfileName(dynamic rawName) {
    if (rawName is Map) {
      final parts = [
        rawName['firstName'],
        rawName['middleName'],
        rawName['lastName'],
      ].where((value) => value != null && value.toString().trim().isNotEmpty);
      final value = parts.join(' ').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    final value = rawName?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }

    return null;
  }

  static Map<String, dynamic> _normalizeSessionHeader({
    Map<String, dynamic>? loginHeader,
    Map<String, dynamic>? profile,
  }) {
    final profileHeader = profile?['genericHeader'] is Map<String, dynamic>
        ? profile!['genericHeader'] as Map<String, dynamic>
        : (profile?['genericHeader'] is Map
              ? Map<String, dynamic>.from(profile?['genericHeader'] as Map)
              : <String, dynamic>{});

    final flatList = profile?['prflFlatNo'];
    final firstFlat = flatList is List && flatList.isNotEmpty
        ? flatList.first?.toString()
        : null;
    final profileName = _composeProfileName(profile?['prflName']);

    return {
      'access':
          profileHeader['access'] ??
          loginHeader?['access'] ??
          profile?['prflAccess'],
      'apartmentId':
          profileHeader['apartmentId'] ??
          loginHeader?['apartmentId'] ??
          profile?['aprmntId'],
      'apartmentName':
          profile?['apartmentName'] ??
          loginHeader?['apartmentName'] ??
          profileHeader['apartmentName'],
      'flatNo': profileHeader['flatNo'] ?? loginHeader?['flatNo'] ?? firstFlat,
      'position':
          loginHeader?['position'] ??
          profileHeader['position'] ??
          profile?['prflPosition'],
      'profileName': profileName ?? loginHeader?['profileName'],
      'profilepic':
          profile?['profilePic'] ??
          loginHeader?['profilepic'] ??
          profileHeader['profilepic'],
      'role':
          profileHeader['role'] ?? loginHeader?['role'] ?? profile?['prflType'],
      'userId':
          loginHeader?['userId'] ??
          profile?['prflId'] ??
          profileHeader['userId'],
      'prflName': profile?['prflName'],
    };
  }

  static Map<String, dynamic>? _buildGenericHeader() {
    final header = userHeader;
    if (header == null) {
      return null;
    }

    return {
      'userId': header['userId'],
      'apartmentId': header['apartmentId'],
      'role': header['role'],
      'access': header['access'],
      'flatNo': header['flatNo'],
    };
  }

  static void _storeLoginSession({
    required Map<String, dynamic> responseData,
    required String password,
  }) {
    token = responseData['token']?.toString();
    loginPassword = password;

    final header = responseData['header'];
    userHeader = header is Map<String, dynamic>
        ? _normalizeSessionHeader(loginHeader: header)
        : (header is Map
              ? _normalizeSessionHeader(
                  loginHeader: Map<String, dynamic>.from(header),
                )
              : userHeader);
  }

  static void _storeProfile(Map<String, dynamic> profile) {
    profileData = profile;
    dashboardProfilePic = profile['profilePic']?.toString();
    userHeader = _normalizeSessionHeader(
      loginHeader: userHeader,
      profile: profile,
    );
  }

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

  static String _encryptAuthValue(String value) {
    final key = encrypt.Key(base64Decode(_authEncryptionKeyBase64));
    final iv = encrypt.IV(base64Decode(_authEncryptionIvBase64));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    return encrypter.encrypt(value, iv: iv).base64;
  }

  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
    String? otp,
  }) async {
    final encryptedPassword = _encryptAuthValue(password);
    final requestBody = <String, dynamic>{
      'username': username,
      'password': encryptedPassword,
    };
    if (otp != null && otp.trim().isNotEmpty) {
      requestBody['otp'] = otp.trim();
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.body.isEmpty) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is! Map) {
      return null;
    }

    final responseData = Map<String, dynamic>.from(data);
    final messageCode = responseData['messageCode']?.toString() ?? '';
    if (response.statusCode == 200 && messageCode.startsWith('SUCC')) {
      _storeLoginSession(responseData: responseData, password: password);
    }

    return responseData;
  }

  static Future<Map<String, dynamic>?> fetchAndStoreProfile({
    String? profileId,
  }) async {
    final response = await getProfile(profileId: profileId);
    if (response == null) {
      return null;
    }

    final messageCode = response['messageCode']?.toString() ?? '';
    if (messageCode.startsWith('SUCC')) {
      _storeProfile(response);
    }

    return response;
  }

  static Future<Map<String, dynamic>?> updatePassword({
    required String profileId,
    required String newPassword,
    required bool otpVerified,
  }) async {
    final encryptedPassword = _encryptAuthValue(newPassword);
    final response = await http.post(
      Uri.parse("$_baseUrl/auth/updatePassword"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'profileId': profileId,
        'newPassword': encryptedPassword,
        'otpVerified': otpVerified,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(data);
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      dashboardProfilePic = data['profilePic']?.toString();
      return data;
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>?> getAllHalls() async {
    if (token == null || userHeader == null) return null;

    final apartmentId = userHeader?['apartmentId']?.toString().trim();
    if (apartmentId == null || apartmentId.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse("$_baseUrl/booking/getAllHalls/$apartmentId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.body.isEmpty) {
      return null;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['halls'] is List) {
        return List<Map<String, dynamic>>.from(data['halls']);
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> checkHallAvailability({
    required String hallId,
    required String eventDate,
  }) async {
    if (token == null || userHeader == null) return null;

    final genericHeader = _buildGenericHeader();
    if (genericHeader == null) {
      return null;
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/booking/checkHallAvailability"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'genericHeader': genericHeader,
        'hallId': hallId,
        'eventDate': eventDate,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getUpcomingHallBookings() async {
    if (userHeader == null) return null;

    final response = await _postBookingEndpoint(
      path: '/booking/getUpcomingHallBookings',
      requestBody: {'header': userHeader},
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<http.Response> _postBookingEndpoint({
    required String path,
    required Map<String, dynamic> requestBody,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    var response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        headers.containsKey('Authorization')) {
      response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
    }

    return response;
  }

  static Future<Map<String, dynamic>?> getBookings() async {
    if (token == null || userHeader == null) return null;

    final response = await _postBookingEndpoint(
      path: '/booking/getBookings',
      requestBody: {'genericHeader': userHeader},
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

    final response = await _postBookingEndpoint(
      path: '/booking/getBooking',
      requestBody: {'genericHeader': userHeader, 'bookingId': bookingId},
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

    final response = await _postBookingEndpoint(
      path: '/booking/updateBooking',
      requestBody: {
        'genericHeader': userHeader,
        'bookingId': bookingId,
        'reason': reason,
        'status': status,
      },
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

  static Future<bool?> validateCurrentOwner({
    required String flatId,
    required String profileType,
  }) async {
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/profile/validateCurrentOwner/${Uri.encodeComponent(flatId)}/${Uri.encodeComponent(profileType)}',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.body.isEmpty) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is bool) {
      return data;
    }

    if (data is String) {
      final value = data.trim().toLowerCase();
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getProfile({String? profileId}) async {
    if (token == null || userHeader == null) return null;

    final genericHeader = _buildGenericHeader();
    if (genericHeader == null) return null;

    final resolvedProfileId = (profileId != null && profileId.trim().isNotEmpty)
        ? profileId.trim()
        : userHeader?['userId']?.toString().trim();

    if (resolvedProfileId == null || resolvedProfileId.isEmpty) {
      return null;
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/getProfile"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'genericHeader': genericHeader,
        'profileID': resolvedProfileId,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getTenant({
    required String flatId,
  }) async {
    if (token == null || userHeader == null) return null;

    final genericHeader = _buildGenericHeader();
    if (genericHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/getTenant"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'genericHeader': genericHeader, 'flatId': flatId}),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getOwner({
    required String flatId,
  }) async {
    if (token == null || userHeader == null) return null;

    final genericHeader = _buildGenericHeader();
    if (genericHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/getOwner"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'genericHeader': genericHeader, 'flatId': flatId}),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>?> searchProfile({
    required String inputKey,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/searchProfile"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'genericHeader': Map<String, dynamic>.from(userHeader!),
        'inputKey': inputKey,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }

    return null;
  }

  static Future<Map<String, dynamic>?> addTenant({
    required String profileId,
    required String flatId,
    required String addToExisting,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/addTenant"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'header': Map<String, dynamic>.from(userHeader!),
        'profileId': profileId,
        'flatId': flatId,
        'addtoExisting': addToExisting,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> addOwner({
    required String profileId,
    required String flatId,
    required String addToExisting,
  }) async {
    if (token == null || userHeader == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/addOwner"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'header': Map<String, dynamic>.from(userHeader!),
        'profileId': profileId,
        'flatId': flatId,
        'addtoExisting': addToExisting,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> removeProfileFromOwnerTenant({
    required String flatId,
    required String profileId,
    required String profileType,
  }) async {
    if (token == null || userHeader == null) return null;

    final header =
        _buildGenericHeader() ?? Map<String, dynamic>.from(userHeader!);

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/removeProfileFromOwnerTenant"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'header': header,
        'flatId': flatId,
        'id': profileId,
        'profileType': profileType,
      }),
    );

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> requestBody,
  ) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/updateProfile"),
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

  static Future<Map<String, dynamic>?> updateTenantDetails(
    Map<String, dynamic> requestBody,
  ) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/updateTenantDetails"),
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

  static Future<Map<String, dynamic>?> updateOwnerDetails(
    Map<String, dynamic> requestBody,
  ) async {
    if (token == null) return null;

    final response = await http.post(
      Uri.parse("$_baseUrl/profile/updateOwnerDetails"),
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
