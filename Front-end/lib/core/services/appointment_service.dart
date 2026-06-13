import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Endpoint paths — update these to match your backend routes.
// POST   /appointments          → patient books
// GET    /appointments          → doctor gets their list
// PATCH  /appointments/:id/accept
// PATCH  /appointments/:id/reject
class AppointmentService {
  static const _path = '/appointments';

  static Future<Map<String, dynamic>> book({
    required String doctorId,
    required String type,
  }) async {
    final token = await ApiService.getToken();
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}$_path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'doctorId': doctorId, 'type': type}),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    String msg = '${res.statusCode}';
    try {
      final b = jsonDecode(res.body);
      final raw = b['message'];
      if (raw is String) msg = raw;
      if (raw is List && raw.isNotEmpty) msg = raw.first.toString();
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<List<Map<String, dynamic>>> getMyAppointments() async {
    final token = await ApiService.getToken();
    final res = await http
        .get(
          Uri.parse('${ApiService.baseUrl}$_path'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body['appointments'] is List) {
        return (body['appointments'] as List).cast<Map<String, dynamic>>();
      }
    }
    throw Exception('${res.statusCode}');
  }

  static Future<void> accept(String id) async {
    final token = await ApiService.getToken();
    final res = await http
        .patch(
          Uri.parse('${ApiService.baseUrl}$_path/$id/accept'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errMsg(res.statusCode, res.body));
    }
  }

  static Future<void> reject(String id) async {
    final token = await ApiService.getToken();
    final res = await http
        .patch(
          Uri.parse('${ApiService.baseUrl}$_path/$id/reject'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errMsg(res.statusCode, res.body));
    }
  }

  // Doctor deletes a request from their list.
  static Future<void> delete(String id) async {
    final token = await ApiService.getToken();
    final res = await http
        .delete(
          Uri.parse('${ApiService.baseUrl}$_path/$id'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errMsg(res.statusCode, res.body));
    }
  }

  // Doctor ends chat access with a patient (conversation/messages are kept).
  static Future<void> endChat(String patientId) async {
    final token = await ApiService.getToken();
    final res = await http
        .patch(
          Uri.parse('${ApiService.baseUrl}$_path/end-chat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'patientId': patientId}),
        )
        .timeout(const Duration(seconds: 12));
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
