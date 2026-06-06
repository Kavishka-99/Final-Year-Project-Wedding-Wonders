import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wedding_planning/historyModel.dart/historyModel.dart';

class HistoryService {
  static const String baseUrl = "http://localhost:5000/api/history";

  Future<List<History>> getUserHistory(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => History.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user history');
    }
  }

  Future<void> addUserHistory(int userId, String activity) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'activity': activity}),
    );
  }
}
