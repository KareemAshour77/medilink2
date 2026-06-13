import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'chat_service.dart';
import 'notification_service.dart';

// ---------------------------------------------------------------------------
// Background FCM handler — runs in a separate isolate.
// Data-only messages on Android require us to show the local notification
// here ourselves so we can use MessagingStyle + inline-reply actions.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM_BG] handler fired — notification=${message.notification?.title} data=${message.data}');
  await NotificationService.init();

  final data = message.data;
  final type = data['type'] ?? '';

  // Appointment accept / reject
  if (type == 'appointment_accepted' || type == 'appointment_rejected') {
    await NotificationService.showAppointmentUpdate(
      accepted:        type == 'appointment_accepted',
      doctorName:      data['doctorName'] ?? 'Your doctor',
      appointmentType: data['appointmentType'] ?? 'appointment',
    );
    return;
  }

  final conversationId = data['conversationId'] ?? '';
  debugPrint('[FCM_BG] conversationId=$conversationId');
  if (conversationId.isEmpty) return;

  final senderImageUrl = data['senderImageUrl'] ?? '';
  final Uint8List? imageBytes = senderImageUrl.isNotEmpty
      ? await _downloadImage(senderImageUrl)
      : null;

  await NotificationService.showChatMessage(
    senderName: data['senderName'] ?? 'New message',
    body: data['body'] ?? '',
    conversationId: conversationId,
    messageId: data['messageId'] ?? '',
    messageType: data['messageType'] ?? 'text',
    senderImageBytes: imageBytes,
  );
}

Future<Uint8List?> _downloadImage(String url) async {
  try {
    final res =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return res.bodyBytes;
  } catch (_) {}
  return null;
}

// ---------------------------------------------------------------------------
// PendingNavigation — holds a conversationId set by notification tap.
// Home screens check this in initState and navigate to the correct chat.
// ---------------------------------------------------------------------------
class PendingNavigation {
  static String? chatConversationId;
}

// ---------------------------------------------------------------------------
// FcmService
// ---------------------------------------------------------------------------
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  // Set by chat screens to suppress redundant local notifications when the
  // user is already viewing that conversation.
  static String? activeChatConversationId;

  // Home screens listen to this ValueNotifier and navigate to the chat screen
  // when it fires with a non-null conversationId. Works for both foreground
  // heads-up taps and background-to-foreground FCM notification taps.
  static final chatNavNotifier = ValueNotifier<String?>(null);

  // Patient screens listen to this to react to appointment accept/reject FCM taps.
  // Value is 'accepted' or 'rejected'.
  static final appointmentNavNotifier = ValueNotifier<String?>(null);

  // ── Startup init — handler registration only, no token upload ─────────────
  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    // Mark-as-Read uses socket in foreground (fast), REST in background.
    // Reply always uses REST (see notification_service.dart — socket is
    // unreliable from a notification isolate so REST is the only safe path).
    // onChatTap fires when the user taps a local notification body while the
    // app is in the foreground (main isolate) — navigate without SharedPrefs.
    NotificationService.registerChatCallbacks(
      onMarkRead: (conversationId) async {
        ChatService.instance.markRead(conversationId);
        NotificationService.clearConvHistory(conversationId);
      },
      onChatTap: (conversationId) {
        chatNavNotifier.value = conversationId;
      },
    );

    NotificationService.registerAppointmentCallback(
      onTap: (accepted) {
        appointmentNavNotifier.value = accepted ? 'accepted' : 'rejected';
      },
    );

    // Terminated-state FCM notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onTap(initial);
  }

  // ── Logout — remove token from backend so no more pushes arrive ───────────
  Future<void> clearToken() async {
    try {
      final authToken = await ApiService.getToken();
      if (authToken == null) return;
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/users/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: '{"token":null}',
      ).timeout(const Duration(seconds: 5));
      debugPrint('FcmService: token cleared');
    } catch (e) {
      debugPrint('FcmService: token clear failed — $e');
    }
  }

  // ── Post-login — request permission + upload token ──────────────────────
  Future<void> uploadToken() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token != null) await _uploadToken(token);
    messaging.onTokenRefresh.listen(_uploadToken);
  }

  Future<void> _uploadToken(String token) async {
    try {
      final authToken = await ApiService.getToken();
      if (authToken == null) return;
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/users/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: '{"token":"$token"}',
      );
      debugPrint('FcmService: token uploaded');
    } catch (e) {
      debugPrint('FcmService: token upload failed — $e');
    }
  }

  // ── Foreground message handler ──────────────────────────────────────────
  void _onForeground(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] ?? '';

    // Appointment accept / reject
    if (type == 'appointment_accepted' || type == 'appointment_rejected') {
      await NotificationService.showAppointmentUpdate(
        accepted:        type == 'appointment_accepted',
        doctorName:      data['doctorName'] ?? 'Your doctor',
        appointmentType: data['appointmentType'] ?? 'appointment',
      );
      return;
    }

    final conversationId = data['conversationId'] ?? '';

    // Suppress if the user is already in this chat
    if (activeChatConversationId == conversationId &&
        conversationId.isNotEmpty) {
      return;
    }

    final senderName  = data['senderName'] ?? 'New message';
    final body        = data['body'] ?? '';
    final messageId   = data['messageId'] ?? '';
    final messageType = data['messageType'] ?? 'text';

    final senderImageUrl = data['senderImageUrl'] ?? '';
    final Uint8List? imageBytes = senderImageUrl.isNotEmpty
        ? await _downloadImage(senderImageUrl)
        : null;

    await NotificationService.showChatMessage(
      senderName:      senderName,
      body:            body,
      conversationId:  conversationId,
      messageId:       messageId,
      messageType:     messageType,
      senderImageBytes: imageBytes,
    );
  }

  // ── Notification tap (background → foreground) ──────────────────────────
  void _onTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';

    if (type == 'appointment_accepted' || type == 'appointment_rejected') {
      appointmentNavNotifier.value = type == 'appointment_accepted' ? 'accepted' : 'rejected';
      return;
    }

    final conversationId = data['conversationId'];
    if (conversationId != null && conversationId.isNotEmpty) {
      final convId = conversationId as String;
      // PendingNavigation covers the terminated-state path (read by main.dart).
      // chatNavNotifier covers the backgrounded-app path (home screens listen).
      PendingNavigation.chatConversationId = convId;
      chatNavNotifier.value = convId;
    }
  }
}
