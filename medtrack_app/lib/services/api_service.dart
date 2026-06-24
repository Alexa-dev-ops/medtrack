import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static const String baseUrl = 'https://medtrack-app-backend.onrender.com/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── HELPER: SAFE LIST EXTRACTOR ──────────────────────────────────
  // This shields your app from type-mismatch crashes if the server
  // returns an error object (Map) instead of an array (List).
  static List<dynamic> _decodeList(http.Response res) {
    final decoded = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is List) {
        return decoded;
      } else if (decoded is Map) {
        // If your backend wraps lists in { "data": [...] }
        if (decoded.containsKey('data') && decoded['data'] is List) {
          return decoded['data'];
        }
        return []; // Safe fallback
      }
      return [];
    } else {
      // Extract the error message safely and throw it so the UI can catch it
      final errorMsg = decoded is Map
          ? (decoded['message'] ??
              decoded['error'] ??
              'Server error ${res.statusCode}')
          : 'Server error ${res.statusCode}';

      // ignore: avoid_print
      print(
          'API Error (${res.request?.url}): $errorMsg'); // Helps with debugging
      throw Exception(errorMsg);
    }
  }

  // ── AUTH ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'name': name, 'email': email, 'password': password, 'role': role}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  // ── MEDICATIONS ──────────────────────────────────────────────────

  static Future<List<dynamic>> getMedications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/medications'),
      headers: await _authHeaders(),
    );
    return _decodeList(res); // Used safe extractor here
  }

  static Future<Map<String, dynamic>> addMedication(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/medications'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateMedication(
      int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/medications/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<void> deleteMedication(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/medications/$id'),
      headers: await _authHeaders(),
    );
  }

  // ── ADHERENCE ────────────────────────────────────────────────────

  static Future<List<dynamic>> getAdherence({String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().split('T')[0];
    final res = await http.get(
      Uri.parse('$baseUrl/adherence?date=$d'),
      headers: await _authHeaders(),
    );
    return _decodeList(res); // Used safe extractor here
  }

  static Future<void> markTaken(int logId) async {
    await http.patch(
      Uri.parse('$baseUrl/adherence/$logId/take'),
      headers: await _authHeaders(),
    );
  }

  static Future<void> markSkipped(int logId) async {
    await http.patch(
      Uri.parse('$baseUrl/adherence/$logId/skip'),
      headers: await _authHeaders(),
    );
  }

  static Future<List<dynamic>> getAdherenceStats() async {
    final res = await http.get(
      Uri.parse('$baseUrl/adherence/stats'),
      headers: await _authHeaders(),
    );
    return _decodeList(res); // Used safe extractor here
  }

  // ── CAREGIVER ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> linkCaregiver(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/caregiver/link'),
      headers: await _authHeaders(),
      body: jsonEncode({'caregiver_code': code}),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getPatients() async {
    final res = await http.get(
      Uri.parse('$baseUrl/caregiver/patients'),
      headers: await _authHeaders(),
    );
    return _decodeList(res); // Used safe extractor here
  }

  static Future<List<dynamic>> getPatientAdherence(int patientId,
      {String? date}) async {
    final d = date ?? DateTime.now().toIso8601String().split('T')[0];
    final res = await http.get(
      Uri.parse('$baseUrl/caregiver/patients/$patientId/adherence?date=$d'),
      headers: await _authHeaders(),
    );
    return _decodeList(res); // Used safe extractor here
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────────

  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _authHeaders(),
    );
    return _decodeList(res); // Used safe extractor here
  }

  static Future<void> markNotificationRead(int id) async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _authHeaders(),
    );
  }

  static Future<void> markAllNotificationsRead() async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _authHeaders(),
    );
  }
}
