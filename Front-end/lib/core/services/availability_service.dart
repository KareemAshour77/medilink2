import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Doctor availability + bookable slots.
///
///   GET  /availability/me                  → doctor's own template (or null)
///   PUT  /availability                     → doctor sets/updates own template
///   GET  /doctors/:id/availability         → a doctor's template
///   GET  /doctors/:id/slots?date=YYYY-MM-DD → bookable slots for a date
class AvailabilityService {
  // Doctor: read own availability (null if not configured yet).
  static Future<Map<String, dynamic>?> getMine() async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/availability/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty || body == 'null') return null;
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Doctor: set / update own availability.
  static Future<void> setMine({
    required List<String> workDays,
    required String startTime,
    required String endTime,
    required int slotMinutes,
    String? breakStart,
    String? breakEnd,
  }) async {
    final token = await ApiService.getToken();
    final res = await http.put(
      Uri.parse('${ApiService.baseUrl}/availability'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'work_days': workDays,
        'start_time': startTime,
        'end_time': endTime,
        'slot_minutes': slotMinutes,
        if (breakStart != null) 'break_start': breakStart,
        if (breakEnd != null) 'break_end': breakEnd,
      }),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errMsg(res.statusCode, res.body));
    }
  }

  // Patient: read a doctor's availability template (null if not set).
  static Future<Map<String, dynamic>?> getForDoctor(String doctorId) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/doctors/$doctorId/availability'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty || body == 'null') return null;
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    }
    return null;
  }

  /// Patient: bookable slots for [doctorId] on [date] (YYYY-MM-DD).
  /// Returns { configured: bool, slots: [{start, label, available}] }.
  static Future<Map<String, dynamic>> getSlots(
    String doctorId,
    String date,
  ) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}/doctors/$doctorId/slots?date=$date'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return {
          'configured': decoded['configured'] == true,
          'slots': (decoded['slots'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        };
      }
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  static String _errMsg(int code, String body) {
    try {
      final b = jsonDecode(body);
      final raw = b['message'];
      if (raw is String) return raw;
      if (raw is List && raw.isNotEmpty) return raw.first.toString();
    } catch (_) {}
    return '$code';
  }
}
