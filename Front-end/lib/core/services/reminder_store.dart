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
  /// Called from both HomeTab and ReminderTab.
  /// Updates in-memory state immediately, then persists to backend.
  Future<void> markTaken(String id, {bool taken = true}) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      if (_reminders[idx].taken == taken) return; // already in desired state
      _reminders[idx].taken = taken;
      notifyListeners();
    }

    // Always persist — reminder may not be in store yet (e.g. called from HomeTab)
    ApiService.markReminderTaken(id: id, taken: taken).catchError(
      (e) => debugPrint('ReminderStore.markTaken persist error: $e'),
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
  int get takenCount => _reminders.where((r) => r.taken).length;

  void clear() {
    _reminders = [];
    notifyListeners();
  }
}
