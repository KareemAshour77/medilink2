import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/reminder_model.dart';
import '../models/in_app_notification.dart';

class ApiService {
  // Android emulator → use 10.0.2.2
  // Real phone → use your PC's IP (run ipconfig in CMD)
  // static const String baseUrl = 'http://192.168.1.16:5000';
  // static const String baseUrl = 'http://192.168.1.109:5000';
  static const String baseUrl = 'http://172.20.10.5:5000';

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    File? image,
  }) async {
    try {
      final token = await getToken();

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['email'] = email;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      }

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      return jsonDecode(responseBody);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Sign Up ───────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String email,
    String? password,
    required String role,
    String? name,
    File? image,
    String? specialty,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/signup'),
      );

      request.fields['email'] = email;
      // Omitted when the email already exists (backend reuses shared password).
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      request.fields['role'] = role;
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (specialty != null && specialty.isNotEmpty) {
        request.fields['specialty'] = specialty;
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 15));
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'error': 'Cannot connect to server'};
    }
  }

  // ── Register Patient (multi-step signup) ──────────────
  // Multipart so the optional profile photo can be uploaded. Backend stores the
  // row (email_verified=false) and emails an OTP, same as the legacy /auth/signup.
  static Future<Map<String, dynamic>> registerPatient({
    required String fullName,
    required String gender,
    required String nationalId,
    required String email,
    String? password,
    File? profileImage,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/register/patient'),
      );
      request.fields['full_name'] = fullName;
      request.fields['gender'] = gender;
      request.fields['national_id'] = nationalId;
      request.fields['email'] = email;
      // Omitted when the email already exists (backend reuses shared password).
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 20));
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'error': 'Cannot connect to server'};
    }
  }

  // ── Register Doctor (multi-step signup) ───────────────
  // Uploads profile photo (optional) + National ID image + Syndicate card
  // (required) alongside the professional fields.
  static Future<Map<String, dynamic>> registerDoctor({
    required String fullName,
    required String gender,
    required String nationalId,
    required String email,
    String? password,
    required String specialty,
    required String syndicateNumber,
    required int yearsOfExperience,
    String? clinicName,
    double? consultationFee,
    required bool onlineConsultation,
    File? profileImage,
    File? nationalIdImage,
    File? syndicateCardImage,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/register/doctor'),
      );
      request.fields['full_name'] = fullName;
      request.fields['gender'] = gender;
      request.fields['national_id'] = nationalId;
      request.fields['email'] = email;
      // Omitted when the email already exists (backend reuses shared password).
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      request.fields['specialty'] = specialty;
      request.fields['syndicate_number'] = syndicateNumber;
      request.fields['years_of_experience'] = yearsOfExperience.toString();
      if (clinicName != null && clinicName.isNotEmpty) {
        request.fields['clinic_name'] = clinicName;
      }
      if (consultationFee != null) {
        request.fields['consultation_fee'] = consultationFee.toString();
      }
      request.fields['online_consultation'] = onlineConsultation.toString();

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }
      if (nationalIdImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'national_id_image', nationalIdImage.path),
        );
      }
      if (syndicateCardImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
              'syndicate_card_image', syndicateCardImage.path),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 25));
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'error': 'Cannot connect to server'};
    }
  }

  // ── Google Sign-In ────────────────────────────────────
  // Called after the Google picker succeeds on the device.
  // Sends the Google ID token to the backend which:
  //   1. Verifies the token with Google
  //   2. Creates the user in PostgreSQL if first time, or updates lastLoginAt
  //   3. Returns the same { access_token, user } shape as regular login
  //
  // Backend endpoint to implement: POST /auth/google
  // Body: { "idToken": "<google id token>" }
  static Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': 'Cannot connect to server'};
    }
  }

  // ── Login ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/signin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      // A 403 (unverified email) returns a custom body { message, role } with
      // NO statusCode field, so attach the real HTTP status for the caller to
      // branch on (e.g. route to the verification screen).
      if (body is Map<String, dynamic>) {
        body['statusCode'] = res.statusCode;
        return body;
      }
      return {'statusCode': res.statusCode, 'data': body};
    } catch (e) {
      return {'error': 'Cannot connect to server'};
    }
  }

  static Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
    required String role,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'role': role}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String role,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'role': role, 'code': code}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) body['success'] = true;
      return body;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Forgot password ─────────────────────────────────────────────────────────

  // Step 1: request a reset code by email.
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) body['success'] = true;
      return body;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Step 2: validate the reset code before showing the new-password step.
  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) body['success'] = true;
      return body;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Step 3: set the new (shared) password.
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code, 'password': password}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) body['success'] = true;
      return body;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Does this email already have an account? Used by signup to skip the
  // password step (shared password per email).
  static Future<Map<String, dynamic>> accountStatus({
    required String email,
  }) async {
    try {
      final res = await http
          .get(Uri.parse(
              '$baseUrl/auth/account-status?email=${Uri.encodeComponent(email)}'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'exists': false, 'verified': false};
    }
  }

  // All role-accounts sharing the logged-in user's email (in-app switcher).
  // Pending accounts come back with email_verified=false and no access_token.
  static Future<Map<String, dynamic>> myAccounts() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/auth/my-accounts'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) body['success'] = true;
      return body;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Save & Get token ──────────────────────────────────
  // Key must match SessionService._tokenKey = 'access_token'
  static const _tokenKey = 'access_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, dynamic>> updateMyLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      final res = await http
          .put(
            Uri.parse('$baseUrl/users'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        body['success'] = true;
      }
      return body;
    } catch (e) {
      debugPrint('updateMyLocation error: $e');
      return {'error': 'Cannot save location'};
    }
  }

  // ── Doctors ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchAllPatients() async {
    final res = await http
        .get(Uri.parse('$baseUrl/users/patients'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('fetchAllPatients: ${res.statusCode} ${res.body}');
  }

  static Future<List<Map<String, dynamic>>> fetchAllDoctors() async {
    final res = await http
        .get(Uri.parse('$baseUrl/users/doctors'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('fetchAllDoctors: ${res.statusCode} ${res.body}');
  }

  static Future<List<Map<String, dynamic>>> fetchNearbyDoctors({
    required double lat,
    required double lng,
    int limit = 5,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/users/doctors/nearby?lat=$lat&lng=$lng&limit=$limit');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('fetchNearbyDoctors: ${res.statusCode} ${res.body}');
  }

  // ── Account identity ──────────────────────────────────

  /// The current account's gender + date of birth, read from the `users` table
  /// (derived from the National ID at registration). Returns null on failure.
  static Future<({String? gender, DateTime? dateOfBirth})?>
      fetchMyIdentity() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final dobRaw = j['date_of_birth'];
        return (
          gender: j['gender'] as String?,
          dateOfBirth:
              dobRaw != null ? DateTime.tryParse(dobRaw.toString()) : null,
        );
      }
      debugPrint('fetchMyIdentity: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      debugPrint('fetchMyIdentity error: $e');
      return null;
    }
  }

  // ── Reminders ─────────────────────────────────────────

  static Future<List<ReminderModel>> fetchReminders() async {
    try {
      final token = await getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body) as List<dynamic>;
        return raw
            .whereType<Map<String, dynamic>>()
            .map(_reminderFromApi)
            .toList();
      }
      debugPrint('fetchReminders: ${res.statusCode} ${res.body}');
      return [];
    } catch (e) {
      debugPrint('fetchReminders error: $e');
      return [];
    }
  }

  static Future<ReminderModel?> createReminder(ReminderModel r) async {
    try {
      final token = await getToken();
      final res = await http
          .post(
            Uri.parse('$baseUrl/reminders'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(_reminderToDto(r)),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return _reminderFromApi(json);
      }
      debugPrint('createReminder: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      debugPrint('createReminder error: $e');
      return null;
    }
  }

  static Future<bool> deleteReminder(String id) async {
    try {
      final token = await getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/reminders/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('deleteReminder error: $e');
      return false;
    }
  }

  // Notifications

  static Future<List<InAppNotification>> fetchNotifications() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body) as List<dynamic>;
        return raw
            .whereType<Map<String, dynamic>>()
            .map(_notificationFromApi)
            .toList();
      }
      debugPrint('fetchNotifications: ${res.statusCode} ${res.body}');
      return [];
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
      return [];
    }
  }

  static Future<bool> saveNotification(InAppNotification notification) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final res = await http
          .post(
            Uri.parse('$baseUrl/notifications'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(_notificationToDto(notification)),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) return true;
      debugPrint('saveNotification: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      debugPrint('saveNotification error: $e');
      return false;
    }
  }

  static Future<bool> dismissNotification(String id) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final encodedId = Uri.encodeComponent(id);
      final res = await http.patch(
        Uri.parse('$baseUrl/notifications/$encodedId/dismiss'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) return true;
      debugPrint('dismissNotification: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      debugPrint('dismissNotification error: $e');
      return false;
    }
  }

  static Future<bool> dismissAllNotifications() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final res = await http.patch(
        Uri.parse('$baseUrl/notifications/dismiss-all'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) return true;
      debugPrint('dismissAllNotifications: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      debugPrint('dismissAllNotifications error: $e');
      return false;
    }
  }

  static InAppNotification _notificationFromApi(Map<String, dynamic> j) {
    InAppNotificationType type;
    switch (j['type'] as String?) {
      case 'medication':
        type = InAppNotificationType.medication;
        break;
      case 'doctor':
        type = InAppNotificationType.doctor;
        break;
      case 'chat':
        type = InAppNotificationType.chat;
        break;
      default:
        type = InAppNotificationType.general;
        break;
    }

    DateTime time;
    try {
      time = DateTime.parse(j['time'] as String);
    } catch (_) {
      time = DateTime.now();
    }

    return InAppNotification(
      id: (j['clientId'] as String?) ?? (j['id'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      time: time,
      type: type,
      medicationName: j['medicationName'] as String?,
      doseStr: j['doseStr'] as String?,
      conversationId: j['conversationId'] as String?,
      specialty: j['specialty'] as String?,
      isDismissed: (j['isDismissed'] as bool?) ?? false,
    );
  }

  static Map<String, dynamic> _notificationToDto(InAppNotification n) {
    String type;
    switch (n.type) {
      case InAppNotificationType.medication:
        type = 'medication';
        break;
      case InAppNotificationType.doctor:
        type = 'doctor';
        break;
      case InAppNotificationType.chat:
        type = 'chat';
        break;
      case InAppNotificationType.general:
        type = 'general';
        break;
    }

    return {
      'clientId': n.id,
      'title': n.title,
      'description': n.description,
      'type': type,
      'time': n.time.toIso8601String(),
      'medicationName': n.medicationName,
      'doseStr': n.doseStr,
      'conversationId': n.conversationId,
      'specialty': n.specialty,
      'isDismissed': n.isDismissed,
    };
  }

  // ── Reminder mapping helpers ───────────────────────────

  static ReminderModel _reminderFromApi(Map<String, dynamic> j) {
    // Parse time — backend may return 'HH:MM' or 'HH:MM:SS'
    final timeParts = ((j['reminder_time'] as String?) ?? '08:00').split(':');
    final hour = int.tryParse(timeParts[0]) ?? 8;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

    // Parse color from '#RRGGBB' hex string
    Color color = const Color(0xFF6750A4);
    final colorStr = j['color'] as String?;
    if (colorStr != null && colorStr.startsWith('#')) {
      try {
        final hex = colorStr.replaceFirst('#', '');
        color = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    // Parse repeat_days → 7-entry weekDays list (index 0 = Saturday)
    final repeatDays = (j['repeat_days'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [];
    const dayOrder = [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];
    final weekDays = repeatDays.isEmpty
        ? List.filled(7, true)
        : dayOrder.map((d) => repeatDays.contains(d)).toList();

    final type = (j['type'] as String?) == 'doctor'
        ? ReminderType.doctor
        : ReminderType.medicine;
    final form = type == ReminderType.medicine
        ? ReminderModel.parseMedicineFormOrFallback(j['form'])
        : null;

    // Parse dose_times → slots; fall back to a single slot built from the
    // legacy reminder_time / take_it / taken columns (old rows).
    List<DoseTime> doseTimes = [];
    final rawSlots = j['dose_times'];
    if (rawSlots is List) {
      doseTimes = rawSlots
          .whereType<Map>()
          .map((e) => DoseTime.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    if (doseTimes.isEmpty) {
      doseTimes = [
        DoseTime(
          time: TimeOfDay(hour: hour, minute: minute),
          meal: MealRelationX.fromTakeIt(j['take_it'] as String?),
          taken: (j['taken'] as bool?) ?? false,
        ),
      ];
    }

    // Parse priority
    Priority priority = Priority.normal;
    switch (j['priority'] as String?) {
      case 'high':
        priority = Priority.high;
        break;
      case 'low':
        priority = Priority.low;
        break;
    }

    // Parse dose
    final doseStr = j['dose'] as String?;
    final dose = doseStr != null ? (double.tryParse(doseStr) ?? 1.0) : 1.0;

    // Parse dates
    DateTime? parseDate(String? s) {
      if (s == null) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return ReminderModel(
      id: (j['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: (j['name'] as String?) ?? '',
      type: type,
      form: form,
      priority: priority,
      dose: dose,
      color: color,
      doseTimes: doseTimes,
      startDate: parseDate(j['start_date'] as String?) ?? DateTime.now(),
      endDate: parseDate(j['end_date'] as String?),
      weekDays: weekDays,
    );
  }

  /// Persists the taken state of a reminder to the backend.
  static Future<void> markReminderTaken({
    required String id,
    required bool taken,
  }) async {
    try {
      final token = await getToken();
      await http
          .patch(
            Uri.parse('$baseUrl/reminders/$id/taken'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'taken': taken}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('markReminderTaken error: $e');
    }
  }

  /// Persists the taken state of a single dose-time slot (by index).
  static Future<void> markReminderSlotTaken({
    required String id,
    required int index,
    required bool taken,
  }) async {
    try {
      final token = await getToken();
      await http
          .patch(
            Uri.parse('$baseUrl/reminders/$id/slot-taken'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'index': index, 'taken': taken}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('markReminderSlotTaken error: $e');
    }
  }

  static Map<String, dynamic> _reminderToDto(ReminderModel r) {
    // Keep the backend value distinct enough to restore the same icon later.
    final form = r.type == ReminderType.medicine
        ? ReminderModel.medicineFormToApi(r.form)
        : null;

    // The first slot's meal → legacy take_it enum column (null if generic).
    final firstMeal =
        r.doseTimes.isNotEmpty ? r.doseTimes.first.meal : MealRelation.afterBreakfast;
    final String? takeIt =
        r.type == ReminderType.medicine ? firstMeal.takeItValue : null;

    // Priority
    String? priority;
    if (r.type == ReminderType.medicine) {
      switch (r.priority) {
        case Priority.high:
          priority = 'high';
          break;
        case Priority.normal:
          priority = 'normal';
          break;
        case Priority.low:
          priority = 'low';
          break;
      }
    }

    // Dose double → string enum
    String? dose;
    if (r.type == ReminderType.medicine) {
      if (r.dose == 0.5) {
        dose = '0.5';
      } else if (r.dose == 1.0) {
        dose = '1';
      } else if (r.dose == 1.5) {
        dose = '1.5';
      } else if (r.dose == 2.0) {
        dose = '2';
      } else if (r.dose == 3.0) {
        dose = '3';
      } else {
        dose = '1';
      }
    }

    // Color → '#RRGGBB'
    final colorHex =
        '#${r.color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    // TimeOfDay → 'HH:MM'
    final timeStr =
        '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';

    // weekDays List<bool> → repeat_days string[]
    const dayOrder = [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];
    final repeatDays = <String>[
      for (var i = 0; i < r.weekDays.length && i < 7; i++)
        if (r.weekDays[i]) dayOrder[i],
    ];

    String fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      'type': r.type == ReminderType.doctor ? 'doctor' : 'medicine',
      'name': r.name,
      'color': colorHex,
      'reminder_time': timeStr,
      'repeat_days': repeatDays,
      'start_date': fmtDate(r.startDate),
      'dose_times': r.doseTimes.map((d) => d.toJson()).toList(),
    };

    if (r.endDate != null) body['end_date'] = fmtDate(r.endDate!);

    if (r.type == ReminderType.medicine) {
      body['form'] = form ?? 'tablets';
      body['dose'] = dose ?? '1';
      body['take_it'] = takeIt ?? 'after_breakfast';
      body['priority'] = priority ?? 'normal';
    }

    return body;
  }
}
