import 'package:flutter/material.dart';
import '../../models/reminder_model.dart';
import 'api_service.dart';

/// Singleton shared between [HomeTab] and [ReminderTab].
///
/// Ensures that marking a reminder as "taken" in the Upcoming Schedule
/// immediately reflects in the Reminder tab — and is persisted to the backend.
class ReminderStore extends ChangeNotifier {
  ReminderStore._();
  static final ReminderStore instance = ReminderStore._();

  // ── State ──────────────────────────────────────────────────────────────────
  List<ReminderModel> _reminders = [];
  bool _loading = false;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get loading => _loading;

  static const _priorityOrder = {
    Priority.high: 0,
    Priority.normal: 1,
    Priority.low: 2,
  };

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await ApiService.fetchReminders();
      list.sort((a, b) =>
          (_priorityOrder[a.priority] ?? 1)
              .compareTo(_priorityOrder[b.priority] ?? 1));
      _reminders = list;
    } catch (e) {
      debugPrint('ReminderStore.load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Mark taken ─────────────────────────────────────────────────────────────
  /// Marks ALL dose-time slots of a reminder taken/untaken (whole-reminder
  /// quick action, e.g. from HomeTab). Persists to backend.
  Future<void> markTaken(String id, {bool taken = true}) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      if (_reminders[idx].allTaken == taken) return;
      for (final d in _reminders[idx].doseTimes) {
        d.taken = taken;
      }
      notifyListeners();
    }
    ApiService.markReminderTaken(id: id, taken: taken).catchError(
      (e) => debugPrint('ReminderStore.markTaken persist error: $e'),
    );
  }

  /// Marks a single dose-time slot taken/untaken. Persists to backend.
  Future<void> markSlotTaken(String id, int index, bool taken) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      final slots = _reminders[idx].doseTimes;
      if (index < 0 || index >= slots.length) return;
      if (slots[index].taken == taken) return;
      slots[index].taken = taken;
      notifyListeners();
    }
    ApiService.markReminderSlotTaken(id: id, index: index, taken: taken)
        .catchError(
      (e) => debugPrint('ReminderStore.markSlotTaken persist error: $e'),
    );
  }

  // ── Toggle eaten ───────────────────────────────────────────────────────────
  void toggleEaten(String id) {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    _reminders[idx].eaten = !_reminders[idx].eaten;
    notifyListeners();
  }

  // ── Add / Delete (called after API succeeds) ───────────────────────────────
  void addReminder(ReminderModel r) {
    _reminders.add(r);
    _reminders.sort((a, b) =>
        (_priorityOrder[a.priority] ?? 1)
            .compareTo(_priorityOrder[b.priority] ?? 1));
    notifyListeners();
  }

  void removeReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  // Count individual dose-time slots (a reminder can have several per day).
  int get takenCount =>
      _reminders.fold(0, (sum, r) => sum + r.takenSlots);
  int get slotTotal =>
      _reminders.fold(0, (sum, r) => sum + r.slotCount);

  void clear() {
    _reminders = [];
    notifyListeners();
  }
}
