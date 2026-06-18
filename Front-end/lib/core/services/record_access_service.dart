import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Time-boxed medical-record access (doctor ↔ patient, 15-minute window).
///
///   POST  /record-access/request           (doctor)  { patientId }
///   GET   /record-access/check?patientId=   (doctor)  → { granted, expires_at }
///   GET   /record-access/:patientId/records (doctor)  → records (403 if no grant)
///   GET   /record-access/pending            (patient) → pending requests
///   PATCH /record-access/:id/approve        (patient)
///   PATCH /record-access/:id/reject         (patient)
class RecordAccessService {
  static const _base = '/record-access';

  // Doctor: request access to a patient's records.
  static Future<Map<String, dynamic>> request(String patientId) async {
    final token = await ApiService.getToken();
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}$_base/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'patientId': patientId}),
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Doctor: do I currently hold a live grant for this patient?
  static Future<bool> check(String patientId) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}$_base/check?patientId=$patientId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final b = jsonDecode(res.body);
      return b is Map && b['granted'] == true;
    }
    return false;
  }

  // Doctor: fetch the patient's records (throws 403 message if not granted).
  static Future<Map<String, dynamic>?> getRecords(String patientId) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}$_base/$patientId/records'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Patient: list my pending (still-valid) access requests.
  static Future<List<Map<String, dynamic>>> pending() async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}$_base/pending'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Patient: approve a request.
  static Future<void> approve(String id) async {
    await _patch('$_base/$id/approve');
  }

  // Patient: reject a request.
  static Future<void> reject(String id) async {
    await _patch('$_base/$id/reject');
  }

  static Future<void> _patch(String path) async {
    final token = await ApiService.getToken();
    final res = await http.patch(
      Uri.parse('${ApiService.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errMsg(res.statusCode, res.body));
    }
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
