import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/in_app_notification.dart';

class InAppNotificationStore extends ChangeNotifier {
  static final InAppNotificationStore instance = InAppNotificationStore._();

  InAppNotificationStore._();

  static const _dismissedIdsKey = 'dismissed_in_app_notification_ids';

  final List<InAppNotification> _items = [];
  final Set<String> _dismissedIds = {};

  List<InAppNotification> get items => _items;

  Future<void> loadFromServer() async {
    final notifications = await ApiService.fetchNotifications();
    _items
      ..clear()
      ..addAll(notifications);
    notifyListeners();
  }

  Future<void> loadDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissedIds
      ..clear()
      ..addAll(prefs.getStringList(_dismissedIdsKey) ?? const []);
  }

  bool isDismissed(String id) => _dismissedIds.contains(id);

  void add(InAppNotification notification) {
    if (isDismissed(notification.id)) return;
    if (_items.any((e) => e.id == notification.id)) return;

    _items.insert(0, notification);
    ApiService.saveNotification(notification);
    notifyListeners();
  }

  void dismiss(String id) {
    _dismissedIds.add(id);
    _saveDismissedIds();
    ApiService.dismissNotification(id);

    final i = _items.indexWhere((e) => e.id == id);

    if (i != -1) {
      _items[i].isDismissed = true;
      notifyListeners();
    }
  }

  void dismissAll() {
    for (final item in _items) {
      item.isDismissed = true;
      _dismissedIds.add(item.id);
    }
    _saveDismissedIds();
    ApiService.dismissAllNotifications();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<void> _saveDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissedIdsKey, _dismissedIds.toList());
  }
}
