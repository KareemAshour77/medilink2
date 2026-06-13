// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../models/reminder_model.dart' hide Priority;
import '../models/in_app_notification.dart';
import 'api_service.dart';
import 'in_app_notification_store.dart';

// ---------------------------------------------------------------------------
// Background notification response — MUST be a top-level function.
// flutter_local_notifications registers it as a Dart VM entry point; static
// methods are not supported for this callback in v14+.
// Top-level functions in the same file can access library-private members.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Synchronous print fires even if the isolate exits before async work runs.
  debugPrint('[NOTIF] background ENTRY actionId=${response.actionId} payload=${response.payload}');
  // Call async helper directly — the returned Future is registered with the
  // Dart event loop, keeping the isolate alive until the HTTP send completes.
  _runBackgroundNotificationResponse(response);
}

// Separate async top-level function so the Future is properly awaited by
// the Dart event loop rather than being fire-and-forget from a void callback.
@pragma('vm:entry-point')
Future<void> _runBackgroundNotificationResponse(NotificationResponse response) async {
  debugPrint('[NOTIF] background → actionId=${response.actionId} input=${response.input} payload=${response.payload}');
  final payload = response.payload ?? '';
  if (!payload.startsWith('chat|')) return;

  // Initialize the plugin in this isolate so _plugin.cancel() works
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await NotificationService.plugin.initialize(
    settings: InitializationSettings(android: android),
  );

  await NotificationService.handleChatActionPublic(response, payload);
}

// ---------------------------------------------------------------------------
// Notification action identifiers
// ---------------------------------------------------------------------------
class NotificationActions {
  static const String taken = 'MEDICATION_TAKEN';
  static const String snooze = 'MEDICATION_SNOOZE';
}

class ChatNotificationActions {
  static const String reply = 'CHAT_REPLY';
  static const String markRead = 'CHAT_MARK_READ';
}

// ---------------------------------------------------------------------------
// Notification channel identifiers
// ---------------------------------------------------------------------------
class _Channels {
  static const String reminders    = 'medilink_reminders';
  static const String medication   = 'medilink_medication';
  static const String chat         = 'medilink_chat';
  static const String appointments = 'medilink_appointments';
}

const String _iosMedicationCategory = 'MEDICATION_CATEGORY';

// ---------------------------------------------------------------------------
// Callback types — medication
// ---------------------------------------------------------------------------
typedef OnMedicationTaken = Future<void> Function({
  required int notificationId,
  required String reminderId,
});

typedef OnMedicationSnoozed = Future<void> Function({
  required int notificationId,
  required String reminderId,
  required String medicationName,
  required String doseStr,
});

// ---------------------------------------------------------------------------
// In-memory chat message history for MessagingStyle grouping
// ---------------------------------------------------------------------------
class _ChatMsg {
  final String senderName;
  final String text;
  final DateTime timestamp;
  _ChatMsg({required this.senderName, required this.text, required this.timestamp});
}

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Medication callbacks ─────────────────────────────────────────────────
  static OnMedicationTaken? _onTaken;
  static OnMedicationSnoozed? _onSnoozed;

  static void registerActionCallbacks({
    required OnMedicationTaken onTaken,
    required OnMedicationSnoozed onSnoozed,
  }) {
    _onTaken = onTaken;
    _onSnoozed = onSnoozed;
  }

  // ── Chat callbacks ───────────────────────────────────────────────────────
  // Reply always uses REST (reliable in both foreground and background).
  // Mark as Read uses socket in foreground, REST in background.
  // onChatTap fires when the notification body is tapped in the main isolate
  // (foreground) so the home screen can navigate without SharedPreferences.
  static Future<void> Function(String conversationId)? _onChatMarkRead;
  static void Function(String conversationId)? _onChatTap;

  static void registerChatCallbacks({
    Future<void> Function(String conversationId)? onMarkRead,
    void Function(String conversationId)? onChatTap,
  }) {
    _onChatMarkRead = onMarkRead;
    _onChatTap = onChatTap;
  }

  // ── Appointment tap callback ─────────────────────────────────────────────
  // Fires when the patient taps an appointment accept/reject local notification.
  static void Function(bool accepted)? _onAppointmentTap;

  static void registerAppointmentCallback({
    required void Function(bool accepted) onTap,
  }) {
    _onAppointmentTap = onTap;
  }

  // ── Per-conversation message history for MessagingStyle ──────────────────
  static final Map<String, List<_ChatMsg>> _convMessages = {};
  static const int _maxHistory = 5;

  static void clearConvHistory(String conversationId) {
    _convMessages.remove(conversationId);
  }

  // ── Initialisation ───────────────────────────────────────────────────────
  static Future<void> init() async {
    tz_data.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset;
    tz.Location? match;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.zones.isNotEmpty &&
          loc.currentTimeZone.offset.inMilliseconds == offset.inMilliseconds) {
        match = loc;
        break;
      }
    }
    tz.setLocalLocation(match ?? tz.UTC);

    // iOS: medication actionable category
    final medicationCategory = DarwinNotificationCategory(
      _iosMedicationCategory,
      actions: [
        DarwinNotificationAction.plain(NotificationActions.taken, '✅ Taken',
            options: {DarwinNotificationActionOption.foreground}),
        DarwinNotificationAction.plain(NotificationActions.snooze, '⏰ Snooze'),
      ],
      options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [medicationCategory],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    // Chat channel — high importance for heads-up display
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.chat,
        'MediLink Chat',
        description: 'Incoming chat messages from doctors and patients',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Appointments channel — accept / reject updates
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _Channels.appointments,
        'MediLink Appointments',
        description: 'Appointment accept and reject notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    _startForegroundWatcher();
  }

  // ── Foreground handler ───────────────────────────────────────────────────
  static void _onNotificationResponse(NotificationResponse response) async {
    debugPrint('[NOTIF] foreground → actionId=${response.actionId} input=${response.input} payload=${response.payload}');
    final payload = response.payload ?? '';

    if (payload.startsWith('chat|')) {
      await _handleChatAction(response, payload);
      return;
    }

    if (payload.startsWith('appointment|')) {
      final accepted = payload.split('|')[1] == 'accepted';
      _onAppointmentTap?.call(accepted);
      return;
    }

    // Medication / reminder path (unchanged)
    final parts = (response.payload ?? '').split('|');
    final reminderId = parts.isNotEmpty ? parts[0] : '';
    final medicationName = parts.length > 1 ? parts[1] : 'Medication';
    final doseStr = parts.length > 2 ? parts[2] : '1';

    InAppNotificationStore.instance.add(
      InAppNotification(
        id: reminderId,
        title: 'Medicine Time',
        description: '$medicationName • $doseStr dose',
        time: DateTime.now(),
        type: InAppNotificationType.medication,
        medicationName: medicationName,
        doseStr: doseStr,
      ),
    );
    await handleNotificationAction(response);
  }


  // ── Chat action dispatcher ───────────────────────────────────────────────

  // Public entry point used by the top-level background handler (same file,
  // but background isolate cannot call private members by class name).
  static Future<void> handleChatActionPublic(
    NotificationResponse response,
    String payload,
  ) => _handleChatAction(response, payload);

  static Future<void> _handleChatAction(
    NotificationResponse response,
    String payload,
  ) async {
    final parts = payload.split('|');
    final conversationId = parts.length > 1 ? parts[1] : '';
    debugPrint('[NOTIF] _handleChatAction → convId=$conversationId actionId=${response.actionId} input=${response.input}');
    if (conversationId.isEmpty) return;

    switch (response.actionId) {
      case ChatNotificationActions.reply:
        final text = response.input?.trim() ?? '';
        debugPrint('[NOTIF] reply text="$text"');
        if (text.isEmpty) return;
        // Always use REST — reliable in both foreground and background:
        // • no socket connection needed
        // • backend emits new_message + conv_updated via socket to recipient
        await _restSendMessage(conversationId, text);
        // Dismiss the notification — clears Android "Sending…" spinner
        try { await _plugin.cancel(id: conversationId.hashCode); } catch (_) {}
        clearConvHistory(conversationId);
        break;

      case ChatNotificationActions.markRead:
        if (_onChatMarkRead != null) {
          await _onChatMarkRead!(conversationId);
        } else {
          await _restMarkRead(conversationId);
        }
        try { await _plugin.cancel(id: conversationId.hashCode); } catch (_) {}
        clearConvHistory(conversationId);
        break;

      // null actionId = user tapped the notification body (not an action button).
      // Foreground (main isolate): _onChatTap callback is registered — call it
      //   directly so the home screen can navigate without SharedPreferences.
      // Background isolate: callback is null — write to SharedPreferences so
      //   the home screen's resume observer picks it up when the app re-focuses.
      default:
        if (response.actionId == null) {
          if (_onChatTap != null) {
            _onChatTap!(conversationId);
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('pending_chat_nav', conversationId);
          }
        }
    }
  }

  // ── REST helpers for background actions ──────────────────────────────────

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> _restSendMessage(String conversationId, String text) async {
    final token = await _getAuthToken();
    debugPrint('[NOTIF] _restSendMessage → token=${token != null ? "found" : "NULL"} conv=$conversationId');
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/chat/conversation/$conversationId/message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': text}),
      ).timeout(const Duration(seconds: 10));
      debugPrint('[NOTIF] _restSendMessage → status=${res.statusCode} body=${res.body}');
    } catch (e) {
      debugPrint('[NOTIF] _restSendMessage → ERROR: $e');
    }
  }

  static Future<void> _restMarkRead(String conversationId) async {
    final token = await _getAuthToken();
    if (token == null) return;
    try {
      await http.put(
        Uri.parse('${ApiService.baseUrl}/chat/conversation/$conversationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Chat notification — MessagingStyle with avatar + actions ─────────────

  static Future<void> showChatMessage({
    required String senderName,
    required String body,
    required String conversationId,
    required String messageId,
    String messageType = 'text',
    Uint8List? senderImageBytes,
  }) async {
    // Accumulate history for MessagingStyle grouping
    final history = _convMessages.putIfAbsent(conversationId, () => []);
    history.add(_ChatMsg(
      senderName: senderName,
      text: body,
      timestamp: DateTime.now(),
    ));
    if (history.length > _maxHistory) history.removeAt(0);

    // Build MessagingStyle
    final senderPerson = Person(name: senderName, key: conversationId);
    final styleMessages = history
        .map((m) => Message(m.text, m.timestamp, senderPerson))
        .toList();

    late final AndroidBitmap<Object> largeIcon;
    if (senderImageBytes != null) {
      largeIcon = ByteArrayAndroidBitmap(senderImageBytes);
    } else {
      largeIcon = const DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
    }

    await _plugin.show(
      // Same id per conversation so messages update (group) instead of stacking
      id: conversationId.hashCode,
      title: senderName,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _Channels.chat,
          'MediLink Chat',
          channelDescription: 'Incoming chat messages',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          playSound: true,
          enableVibration: true,
          largeIcon: largeIcon,
          styleInformation: MessagingStyleInformation(
            // "You" represents the receiver (the notification reader)
            const Person(name: 'You', key: 'me'),
            conversationTitle: senderName,
            groupConversation: false,
            messages: styleMessages,
          ),
          actions: [
            AndroidNotificationAction(
              ChatNotificationActions.reply,
              '💬 Reply',
              inputs: [const AndroidNotificationActionInput(
                label: 'Type a reply...',
              )],
              showsUserInterface: false,
              cancelNotification: false,
            ),
            AndroidNotificationAction(
              ChatNotificationActions.markRead,
              '✓ Mark as Read',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'chat|$conversationId|$messageId',
    );
  }

  // ── Appointment accept / reject notification ─────────────────────────────

  static Future<void> showAppointmentUpdate({
    required bool accepted,
    required String doctorName,
    required String appointmentType,
  }) async {
    final title = accepted ? '✅ Appointment Accepted' : '❌ Appointment Rejected';
    final body = accepted
        ? '$doctorName accepted your $appointmentType request. You can now chat with them.'
        : '$doctorName declined your $appointmentType request.';

    await _plugin.show(
      id: 'appointment'.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _Channels.appointments,
          'MediLink Appointments',
          channelDescription: 'Appointment accept and reject updates',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'appointment|${accepted ? 'accepted' : 'rejected'}',
    );
  }

  // ── Medication public API (unchanged) ────────────────────────────────────

  static Future<void> handleNotificationAction(NotificationResponse response) async {
    final actionId = response.actionId;
    final notificationId = response.id ?? 0;
    final parts = (response.payload ?? '||').split('|');
    final reminderId = parts.isNotEmpty ? parts[0] : '';
    final medicationName = parts.length > 1 ? parts[1] : 'Medication';
    final doseStr = parts.length > 2 ? parts[2] : '1';

    if (actionId == NotificationActions.taken) {
      await _plugin.cancel(id: notificationId);
      await _onTaken?.call(notificationId: notificationId, reminderId: reminderId);
    } else if (actionId == NotificationActions.snooze) {
      await _plugin.cancel(id: notificationId);
      await _scheduleSnooze(
        notificationId: notificationId,
        reminderId: reminderId,
        medicationName: medicationName,
        doseStr: doseStr,
      );
      await _onSnoozed?.call(
        notificationId: notificationId,
        reminderId: reminderId,
        medicationName: medicationName,
        doseStr: doseStr,
      );
    }
  }

  static Future<void> _scheduleSnooze({
    required int notificationId,
    required String reminderId,
    required String medicationName,
    required String doseStr,
  }) async {
    final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));
    await _plugin.zonedSchedule(
      id: notificationId,
      title: '⏰ Snoozed Reminder',
      body: '$medicationName  •  $doseStr dose',
      scheduledDate: snoozeTime,
      notificationDetails: _buildMedicationDetails(
        reminderId: reminderId,
        medicationName: medicationName,
        doseStr: doseStr,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$reminderId|$medicationName|$doseStr|${snoozeTime.millisecondsSinceEpoch}',
    );
  }

  static Future<void> scheduleMedicationNotification({
    required String reminderId,
    required String medicationName,
    required double dose,
    required DateTime time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day,
        time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final doseStr = dose == dose.truncateToDouble()
        ? dose.toInt().toString()
        : dose.toString();
    final notificationId = reminderId.hashCode;
    final payload =
        '$reminderId|$medicationName|$doseStr|${scheduled.millisecondsSinceEpoch}';
    await _plugin.zonedSchedule(
      id: notificationId,
      title: '💊 Time to take your medication',
      body: '$medicationName  •  $doseStr dose',
      scheduledDate: scheduled,
      notificationDetails: _buildMedicationDetails(
        reminderId: reminderId,
        medicationName: medicationName,
        doseStr: doseStr,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static NotificationDetails _buildMedicationDetails({
    required String reminderId,
    required String medicationName,
    required String doseStr,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _Channels.medication,
        'MediLink Medication Reminders',
        channelDescription: 'Actionable medication reminders with Taken / Snooze',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        actions: [
          AndroidNotificationAction(NotificationActions.taken, '✅ Taken',
              showsUserInterface: false, cancelNotification: true),
          AndroidNotificationAction(NotificationActions.snooze, '⏰ Snooze',
              showsUserInterface: false, cancelNotification: true),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: _iosMedicationCategory,
      ),
    );
  }

  static Future<void> schedule(ReminderModel r) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day,
        r.time.hour, r.time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final title =
        r.type == ReminderType.doctor ? '🩺 Doctor Appointment' : '💊 Medicine Time';
    final doseStr = r.dose == r.dose.truncateToDouble()
        ? r.dose.toInt().toString()
        : r.dose.toString();
    await _plugin.zonedSchedule(
      id: r.id.hashCode,
      title: title,
      body: '${r.name}  •  $doseStr dose',
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _Channels.reminders,
          'MediLink Reminders',
          channelDescription: 'Medicine and appointment reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(String id) async => _plugin.cancel(id: id.hashCode);

  static Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Multi-slot scheduling (one alarm per dose-time) ──────────────────────────
  // Distinct, stable notification id per (reminder, slot).
  static int _slotId(String reminderId, int index) =>
      '$reminderId#$index'.hashCode;

  // Schedule one daily alarm for each dose-time slot of a medicine reminder.
  static Future<void> scheduleReminderAllSlots(ReminderModel r) async {
    final doseStr = r.dose == r.dose.truncateToDouble()
        ? r.dose.toInt().toString()
        : r.dose.toString();
    for (var i = 0; i < r.doseTimes.length; i++) {
      final slot = r.doseTimes[i];
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, slot.time.hour, slot.time.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final payload =
          '${r.id}|${r.name}|$doseStr|${scheduled.millisecondsSinceEpoch}';
      try {
        await _plugin.zonedSchedule(
          id: _slotId(r.id, i),
          title: '💊 Time to take your medication',
          body: '${r.name}  •  $doseStr dose  •  ${slot.meal.label}',
          scheduledDate: scheduled,
          notificationDetails: _buildMedicationDetails(
            reminderId: r.id,
            medicationName: r.name,
            doseStr: doseStr,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
      } catch (_) {
        // best-effort per slot
      }
    }
  }

  // Cancel every slot alarm for a reminder (plus the legacy single id).
  static Future<void> cancelReminderAllSlots(ReminderModel r) async {
    try {
      await _plugin.cancel(id: r.id.hashCode);
    } catch (_) {}
    // Cancel a generous range in case the slot count shrank since scheduling.
    final count = r.doseTimes.length < 12 ? 12 : r.doseTimes.length;
    for (var i = 0; i < count; i++) {
      try {
        await _plugin.cancel(id: _slotId(r.id, i));
      } catch (_) {}
    }
  }

  // Re-schedules the given reminders (the current account's own reminders).
  // Called after login so that cancelAll() on logout/account-switch doesn't
  // leave a returning user with no scheduled reminders. Scheduling by the same
  // id replaces any existing one, so this is safe to call repeatedly.
  static Future<void> rescheduleAll(List<ReminderModel> reminders) async {
    for (final r in reminders) {
      try {
        if (r.type == ReminderType.medicine) {
          await scheduleReminderAllSlots(r);
        } else {
          await schedule(r);
        }
      } catch (_) {
        // best-effort — one bad reminder shouldn't block the rest
      }
    }
  }

  // ── Foreground reminder watcher (unchanged) ──────────────────────────────
  static Timer? _foregroundWatcher;

  static void _startForegroundWatcher() {
    _foregroundWatcher?.cancel();
    _foregroundWatcher = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        final parts = (p.payload ?? '').split('|');
        if (parts.length < 3) continue;
        final reminderId = parts[0];
        final medicationName = parts[1];
        final doseStr = parts[2];
        final scheduledMs = parts.length > 3 ? int.tryParse(parts[3]) : null;
        if (scheduledMs != null &&
            DateTime.now().millisecondsSinceEpoch < scheduledMs) { continue; }
        final alreadyExists =
            InAppNotificationStore.instance.items.any((e) => e.id == reminderId);
        if (alreadyExists) continue;
        InAppNotificationStore.instance.add(InAppNotification(
          id: reminderId,
          title: 'Medicine Time',
          description: '$medicationName • $doseStr dose',
          time: DateTime.now(),
          type: InAppNotificationType.medication,
          medicationName: medicationName,
          doseStr: doseStr,
        ));
      }
    });
  }

  static FlutterLocalNotificationsPlugin get plugin => _plugin;
}
