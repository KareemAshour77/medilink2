import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/emergency_info_model.dart';
import 'api_service.dart';

// Talks to the NestJS `emergency-profile` module (JWT-guarded):
//   GET    /emergency-profile/me  → current user's profile, or null if none
//   POST   /emergency-profile     → upsert (create or update)
//   DELETE /emergency-profile     → delete current user's profile
class EmergencyInfoService {
  static const _path = '/emergency-profile';

  /// Returns the current user's emergency info, or `null` when none exists yet.
  static Future<EmergencyInfoModel?> fetchMine() async {
    final token = await ApiService.getToken();
    final res = await http
        .get(
          Uri.parse('${ApiService.baseUrl}$_path/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      if (res.body.trim().isEmpty || res.body.trim() == 'null') return null;
      final body = jsonDecode(res.body);
      if (body == null) return null;
      if (body is Map<String, dynamic>) {
        return EmergencyInfoModel.fromJson(body);
      }
      return null;
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  /// Upserts the profile and returns the saved record.
  static Future<EmergencyInfoModel> save(EmergencyInfoModel info) async {
    final token = await ApiService.getToken();
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}$_path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(info.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body);
      return EmergencyInfoModel.fromJson(body as Map<String, dynamic>);
    }
    throw Exception(_errMsg(res.statusCode, res.body));
  }

  static Future<void> delete() async {
    final token = await ApiService.getToken();
    final res = await http
        .delete(
          Uri.parse('${ApiService.baseUrl}$_path'),
          headers: {'Authorization': 'Bearer $token'},
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
