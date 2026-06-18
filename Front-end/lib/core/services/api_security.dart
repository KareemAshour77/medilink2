import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Talks to the FastAPI security backend (port 8080).
/// Handles: secure auth, access control, emergency access, AI chat.
class SecurityApiService {
  // Resolved at runtime from AppConfig (default port 8080). Override with
  // --dart-define=SECURITY_BASE_URL=... or SECURITY_PORT/APP_ENV/PC_IP.
  static String get baseUrl => AppConfig.securityBaseUrl;
  static const Duration _timeout = Duration(seconds: 10);

  // ── Token helpers ────────────────────────────────────────────────────────────

  static Future<String?> getSecToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sec_access_token');
  }

  static Future<void> saveSecToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sec_access_token', token);
  }

  static Future<void> clearSecToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sec_access_token');
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Health ───────────────────────────────────────────────────────────────────

  /// Returns true if the security backend is reachable and healthy.
  static Future<bool> isHealthy() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  /// Register through the secure backend.
  /// Returns the response map (includes access_token on success).
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'name': name,
              'role': role,
            }),
          )
          .timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && data['access_token'] != null) {
        await saveSecToken(data['access_token'] as String);
      }
      return data;
    } catch (e) {
      return {'error': 'Cannot connect to security server'};
    }
  }

  /// Login through the secure backend.
  /// Pass [totpCode] when the account has 2FA enabled.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? totpCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (totpCode != null) body['totp_code'] = totpCode;

      final res = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['access_token'] != null) {
        await saveSecToken(data['access_token'] as String);
      }
      return data;
    } catch (e) {
      return {'error': 'Cannot connect to security server'};
    }
  }

  /// Get current user profile from secure backend.
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getSecToken();
      if (token == null) return {'error': 'Not authenticated'};
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/v1/auth/me'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Access Control ───────────────────────────────────────────────────────────

  /// Doctor: request access to a patient's records.
  static Future<Map<String, dynamic>> requestAccess({
    required String patientId,
    required String reason,
    int sessionMinutes = 60,
  }) async {
    try {
      final token = await getSecToken();
      if (token == null) return {'error': 'Not authenticated'};
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/v1/access-requests/'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'patient_id': patientId,
              'request_type': 'view_records',
              'reason': reason,
              'session_duration_minutes': sessionMinutes,
              'urgency_level': 1,
            }),
          )
          .timeout(_timeout);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Patient: get pending access requests waiting for approval.
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final token = await getSecToken();
      if (token == null) return [];
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/v1/access-requests/pending'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Patient: approve an access request.
  static Future<Map<String, dynamic>> approveRequest(String requestId) async {
    try {
      final token = await getSecToken();
      if (token == null) return {'error': 'Not authenticated'};
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/v1/access-requests/$requestId/approve'),
            headers: _authHeaders(token),
            body: jsonEncode({'patient_response': 'Approved'}),
          )
          .timeout(_timeout);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── AI Chat ──────────────────────────────────────────────────────────────────

  /// Send a message to the secure AI chat endpoint.
  static Future<Map<String, dynamic>> aiChat(String prompt) async {
    try {
      final token = await getSecToken();
      if (token == null) return {'error': 'Not authenticated'};
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/v1/ai/chat'),
            headers: _authHeaders(token),
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
