// ignore_for_file: prefer_const_constructors

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../models/reminder_model.dart' hide Priority;
import 'dart:async';
import 'in_app_notification_store.dart';
import '../models/in_app_notification.dart';

// ---------------------------------------------------------------------------
// Action identifiers — shared between scheduling and handling so they
// never go out of sync.
// ---------------------------------------------------------------------------
class NotificationActions {
  /// User confirmed they took the medication.
  static const String taken = 'MEDICATION_TAKEN';

  /// User wants a 10-minute snooze.
  static const String snooze = 'MEDICATION_SNOOZE';
}

// ---------------------------------------------------------------------------
// Notification channel identifiers
// ---------------------------------------------------------------------------
class _Channels {
  /// Original channel — kept intact so existing reminders are unaffected.
  static const String reminders = 'medilink_reminders';

  /// New channel for actionable medication reminders.
  static const String medication = 'medilink_medication';
}

// ---------------------------------------------------------------------------
// iOS category identifier for medication actionable notifications.
// ---------------------------------------------------------------------------
const String _iosMedicationCategory = 'MEDICATION_CATEGORY';

// ---------------------------------------------------------------------------
// Callback types
// ---------------------------------------------------------------------------

/// Called when the user taps "✅ Taken".
/// [notificationId] is the hashed id used to schedule the notification.
/// [reminderId]     is the original ReminderModel.id string.
typedef OnMedicationTaken = Future<void> Function({
  required int notificationId,
  required String reminderId,
});

/// Called when the user taps "⏰ Snooze".
/// [payload] carries the original medication info so the notification can
/// be re-scheduled without hitting the database.
typedef OnMedicationSnoozed = Future<void> Function({
  required int notificationId,
  required String reminderId,
  required String medicationName,
  required String doseStr,
});

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Registered action callbacks (set once from main / DI layer) ──────────
  static OnMedicationTaken? _onTaken;
  static OnMedicationSnoozed? _onSnoozed;

  /// Register the callbacks that will be invoked when the user interacts with
  /// an actionable medication notification.  Call this before [init].
  static void registerActionCallbacks({
    required OnMedicationTaken onTaken,
    required OnMedicationSnoozed onSnoozed,
  }) {
    _onTaken = onTaken;
    _onSnoozed = onSnoozed;
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  static Future<void> init() async {
    // -- Timezone (existing logic — unchanged) --------------------------------
    tz_data.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset;
    final locations = tz.timeZoneDatabase.locations;
    tz.Location? match;
    for (final loc in locations.values) {
      if (loc.zones.isNotEmpty &&
          loc.currentTimeZone.offset.inMilliseconds == offset.inMilliseconds) {
        match = loc;
        break;
      }
    }
    tz.setLocalLocation(match ?? tz.UTC);

    // -- iOS: register the actionable category for medication -----------------
    // This must be declared before initialize() is called so iOS knows the
    // actions up-front.
    var takenAction = DarwinNotificationAction.plain(
      NotificationActions.taken,
      '✅ Taken',
      options: {DarwinNotificationActionOption.foreground},
    );
    var snoozeAction = DarwinNotificationAction.plain(
      NotificationActions.snooze,
      '⏰ Snooze',
      // background — no need to foreground the app just to snooze
    );
    final medicationCategory = DarwinNotificationCategory(
      _iosMedicationCategory,
      actions: [takenAction, snoozeAction],
      options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
    );

    // -- Android / iOS init settings ------------------------------------------
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [medicationCategory], // ← NEW: register category
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // -- Android permissions (existing logic — unchanged) --------------------
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    _startForegroundWatcher();
  }

  // ── Notification response handlers ──────────────────────────────────────

  /// Foreground handler — runs inside the Flutter isolate.
  static void _onNotificationResponse(NotificationResponse response) async {
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

  /// Background / terminated handler — must be a top-level function.
  /// We forward to the same logic; callbacks must be re-registered if the
  /// app wakes cold from a background tap (handle in main()).
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    handleNotificationAction(response);
  }

  // ── Public: handle an action ─────────────────────────────────────────────

  /// Dispatches a [NotificationResponse] to the appropriate callback.
  ///
  /// The [payload] is expected to be a pipe-separated string:
  ///   "`reminderId|medicationName|doseStr`"
  ///
  /// This method is intentionally public so it can be called from:
  ///   • The plugin callbacks above.
  ///   • The in-app notification list UI (bell button widget).
  static Future<void> handleNotificationAction(
    NotificationResponse response,
  ) async {
    final actionId = response.actionId;
    final notificationId = response.id ?? 0;

    // Parse the structured payload
    final parts = (response.payload ?? '||').split('|');
    final reminderId = parts.isNotEmpty ? parts[0] : '';
    final medicationName = parts.length > 1 ? parts[1] : 'Medication';
    final doseStr = parts.length > 2 ? parts[2] : '1';

    if (actionId == NotificationActions.taken) {
      // 1️⃣  Cancel the scheduled notification — the user has taken their dose.
      await _plugin.cancel(id: notificationId);

      // 2️⃣  Notify the app layer (update DB, show toast, etc.)
      await _onTaken?.call(
        notificationId: notificationId,
        reminderId: reminderId,
      );
    } else if (actionId == NotificationActions.snooze) {
      // 1️⃣  Cancel the current notification.
      await _plugin.cancel(id: notificationId);

      // 2️⃣  Schedule a one-off notification 10 minutes from now.
      await _scheduleSnooze(
        notificationId: notificationId,
        reminderId: reminderId,
        medicationName: medicationName,
        doseStr: doseStr,
      );

      // 3️⃣  Notify the app layer.
      await _onSnoozed?.call(
        notificationId: notificationId,
        reminderId: reminderId,
        medicationName: medicationName,
        doseStr: doseStr,
      );
    }
    // If actionId is null the user tapped the notification body — handle
    // navigation in your router/navigator using response.payload.
  }

  // ── Schedule helpers ─────────────────────────────────────────────────────

  /// Schedules a one-off snooze notification 10 minutes from now.
  static Future<void> _scheduleSnooze({
    required int notificationId,
    required String reminderId,
    required String medicationName,
    required String doseStr,
  }) async {
    final snoozeTime = tz.TZDateTime.now(tz.local).add(
      const Duration(minutes: 10),
    );

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
      // No matchDateTimeComponents — this is a one-off, not recurring
      payload: '$reminderId|$medicationName|$doseStr|${snoozeTime.millisecondsSinceEpoch}',
    );
  }

  // ── Public: schedule a medication notification ───────────────────────────

  /// Schedules a recurring daily medication notification with ✅ Taken
  /// and ⏰ Snooze action buttons.
  ///
  /// This is a new public method that sits alongside the existing [schedule]
  /// method.  Use it for medication-type reminders; use [schedule] for
  /// everything else (doctor appointments, etc.).
  static Future<void> scheduleMedicationNotification({
    required String reminderId,
    required String medicationName,
    required double dose,
    required DateTime time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Build a human-readable dose string (e.g. "2" instead of "2.0")
    final doseStr = dose == dose.truncateToDouble()
        ? dose.toInt().toString()
        : dose.toString();

    final notificationId = reminderId.hashCode;
    final payload = '$reminderId|$medicationName|$doseStr|${scheduled.millisecondsSinceEpoch}';

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
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: payload,
    );
  }

  // ── Private: build NotificationDetails with action buttons ───────────────

  /// Constructs [NotificationDetails] for a medication reminder.
  /// Includes the two action buttons on both Android and iOS.
  static NotificationDetails _buildMedicationDetails({
    required String reminderId,
    required String medicationName,
    required String doseStr,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _Channels.medication,
        'MediLink Medication Reminders',
        channelDescription:
            'Actionable medication reminders with Taken / Snooze',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        // ── Action buttons ─────────────────────────────────────────────────
        actions: [
          AndroidNotificationAction(
            NotificationActions.taken,
            '✅ Taken',
            showsUserInterface: false, // handle silently in background
            cancelNotification: true, // auto-dismiss on tap
          ),
          AndroidNotificationAction(
            NotificationActions.snooze,
            '⏰ Snooze',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier:
            _iosMedicationCategory, // ← links to registered actions
      ),
    );
  }

  static void _startForegroundWatcher() {
    _foregroundWatcher?.cancel();

    _foregroundWatcher = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final pending = await _plugin.pendingNotificationRequests();

        for (final p in pending) {
          final parts = (p.payload ?? '').split('|');

          if (parts.length < 3) continue;

          final reminderId = parts[0];
          final medicationName = parts[1];
          final doseStr = parts[2];
          final scheduledMs = parts.length > 3 ? int.tryParse(parts[3]) : null;

          // Skip if the scheduled time hasn't arrived yet
          if (scheduledMs != null &&
              DateTime.now().millisecondsSinceEpoch < scheduledMs) {
            continue;
          }

          final alreadyExists = InAppNotificationStore.instance.items.any(
            (e) => e.id == reminderId,
          );

          if (alreadyExists) continue;

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
        }
      },
    );
  }

  // ── Existing public API — UNCHANGED ──────────────────────────────────────

  /// Schedules a recurring daily reminder (doctor or medicine) without
  /// action buttons.  Preserved exactly as it was.
  static Future<void> schedule(ReminderModel r) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      r.time.hour,
      r.time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final title = r.type == ReminderType.doctor
        ? '🩺 Doctor Appointment'
        : '💊 Medicine Time';

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

  /// Cancels a scheduled notification by its original string id.
  static Future<void> cancel(String id) async {
    await _plugin.cancel(id: id.hashCode);
  }

  /// Cancels all pending notifications (useful on sign-out / account wipe).
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Timer? _foregroundWatcher;
}
