import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ChatApiService {
  // ── Conversation ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getOrCreateConversation(String doctorId) async {
    final token = await ApiService.getToken();
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/chat/conversation'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'doctorId': doctorId}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('getOrCreateConversation: ${res.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final token = await ApiService.getToken();
    final res = await http
        .get(Uri.parse('${ApiService.baseUrl}/chat/conversations'),
            headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('getConversations: ${res.statusCode}');
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final token = await ApiService.getToken();
    final res = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/chat/conversation/$conversationId/messages'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('getMessages: ${res.statusCode}');
  }

  static Future<void> markRead(String conversationId) async {
    final token = await ApiService.getToken();
    await http
        .put(
          Uri.parse('${ApiService.baseUrl}/chat/conversation/$conversationId/read'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 5));
  }

  // ── Edit / Delete ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> editMessage(String messageId, String content) async {
    final token = await ApiService.getToken();
    final res = await http
        .patch(
          Uri.parse('${ApiService.baseUrl}/chat/message/$messageId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'content': content}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('editMessage: ${res.statusCode}');
  }

  static Future<void> deleteForEveryone(String messageId) async {
    final token = await ApiService.getToken();
    await http
        .delete(
          Uri.parse('${ApiService.baseUrl}/chat/message/$messageId/everyone'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> deleteForMe(String messageId) async {
    final token = await ApiService.getToken();
    await http
        .delete(
          Uri.parse('${ApiService.baseUrl}/chat/message/$messageId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
  }

  // ── Media upload ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> uploadMedia(
    String conversationId,
    File file,
  ) async {
    final token = await ApiService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/chat/conversation/$conversationId/media'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Exception('uploadMedia: ${streamed.statusCode}');
  }
}
