/*
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppUrl {
  static const String BASE = "http://13.234.119.146:8082/tokenService/Api/";

  static const String getToken = "${BASE}get/access-token";
  static const String getOtp = "${BASE}getOtpNew";
  static const String verifOtp = "${BASE}verifyOtpNew";
}

class ApiService {
  // Step 1: Get Access Token
  static Future<String?> getAccessToken() async {
    final headers = {'Header': 'HRMS00001'};

    try {
      final response = await http.get(Uri.parse(AppUrl.getToken), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['access_token']; // return only token string
      } else {
        print("Token Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Token Exception: $e");
    }
    return null;
  }

  // Step 2: Get OTP
  static Future<Map<String, dynamic>?> getOtp({
    required String token,
    required String mobile,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "mobile": mobile,
    });

    try {
      final response = await http.post(Uri.parse(AppUrl.getOtp), headers: headers, body: body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("OTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("OTP Exception: $e");
    }
    return null;
  }

  // Step 3: Verify OTP
  static Future<Map<String, dynamic>?> verifyOtp({
    required String token,
    required String mobile,
    required String otp,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "mobile": mobile,
      "otp": otp,
    });

    try {
      final response = await http.post(Uri.parse(AppUrl.verifOtp), headers: headers, body: body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Verify OTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Verify OTP Exception: $e");
    }
    return null;
  }
}
*/
