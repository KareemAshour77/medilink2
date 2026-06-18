import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Unified medical records (NestJS `/records`).
///
///   POST  /records                  (patient) create a record
///   GET   /records/mine             (patient) own records
///   POST  /records/prescription     (doctor)  create a prescription for a patient
///   GET   /records/patient/:id      (doctor)  a patient's records (access-gated)
///   PATCH /records/:id/status       (patient) update a prescription's status
class RecordsService {
  static const _base = '/records';

  // Patient: create a record (lab_test | imaging | prescription | diagnosis).
  static Future<Map<String, dynamic>> create({
    required String type,
    required String title,
    String? doctorOrFacility,
    String? date, // ISO
    String? status,
    String? description,
    String? doctorNotes,
    List<String> attachments = const [],
    List<({String name, String dosage, String frequency})> items = const [],
  }) async {
    final token = await ApiService.getToken();
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}$_base'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'title': title,
        if (doctorOrFacility != null) 'doctorOrFacility': doctorOrFacility,
        if (date != null) 'date': date,
        if (status != null) 'status': status,
        if (description != null) 'description': description,
        if (doctorNotes != null) 'doctorNotes': doctorNotes,
        if (attachments.isNotEmpty) 'attachments': attachments,
        if (items.isNotEmpty)
          'items': [
            for (final i in items)
              {'name': i.name, 'dosage': i.dosage, 'frequency': i.frequency},
          ],
      }),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Patient: my own records.
  static Future<List<Map<String, dynamic>>> mine() async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}$_base/mine'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Doctor: create a prescription for a patient (status auto = taking_now).
  static Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required String title,
    String? doctorOrFacility,
    String? description,
    String? doctorNotes,
    List<({String name, String dosage, String frequency})> items = const [],
  }) async {
    final token = await ApiService.getToken();
    final res = await http.post(
      Uri.parse('${ApiService.baseUrl}$_base/prescription'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'patientId': patientId,
        'title': title,
        if (doctorOrFacility != null) 'doctorOrFacility': doctorOrFacility,
        if (description != null) 'description': description,
        if (doctorNotes != null) 'doctorNotes': doctorNotes,
        if (items.isNotEmpty)
          'items': [
            for (final i in items)
              {'name': i.name, 'dosage': i.dosage, 'frequency': i.frequency},
          ],
      }),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Doctor: read a patient's records (403 unless a live access grant exists).
  static Future<List<Map<String, dynamic>>> forPatient(String patientId) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}$_base/patient/$patientId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Full details of one record (patient owns it, or doctor with a live grant).
  static Future<Map<String, dynamic>?> getOne(String recordId) async {
    final token = await ApiService.getToken();
    final res = await http.get(
      Uri.parse('${ApiService.baseUrl}$_base/$recordId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  // Patient: update a prescription's status (owner-only).
  static Future<void> updateStatus(String recordId, String status) async {
    final token = await ApiService.getToken();
    final res = await http.patch(
      Uri.parse('${ApiService.baseUrl}$_base/$recordId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    ).timeout(const Duration(seconds: 15));
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
