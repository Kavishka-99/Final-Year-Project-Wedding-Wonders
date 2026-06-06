import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://localhost:5000"; //e with Node.js API URL

  // Extended Registration
  Future<Map<String, dynamic>> registerExtended({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String weddingDate,
    required String partnerEmail,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "phone": phone,
        "wedding_date": weddingDate,
        "partner_email": partnerEmail,
        "pin": pin,
      }),
    );

    return jsonDecode(response.body);
  }

  // Email + Password Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return jsonDecode(response.body);
  }

  // PIN Login
  Future<Map<String, dynamic>> loginWithPin({
    required String email,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login-pin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "pin": pin}),
    );

    return jsonDecode(response.body);
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return jsonDecode(response.body);
  }
}
