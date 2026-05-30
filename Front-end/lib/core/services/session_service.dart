import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/model/user_model.dart';
import 'in_app_notification_store.dart';
import 'chat_service.dart';

class SessionService {
  static const _userKey = 'current_user';
  static const _tokenKey = 'access_token';

  /// Global notifier — any widget that wraps itself in AnimatedBuilder(animation:
  /// SessionService.userNotifier) will rebuild automatically when user data changes.
  static final userNotifier = ValueNotifier<UserModel?>(null);

  static UserModel? get currentUser => userNotifier.value;
  static bool get isLoggedIn => userNotifier.value != null;

  /// Called on login — saves full user (including token) to memory + prefs.
  static Future<void> save(UserModel user) async {
    userNotifier.value = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _userKey,
        jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'role': user.role.name,
          'image': user.image,
          'latitude': user.latitude,
          'longitude': user.longitude,
        }));
    if (user.token != null) {
      await prefs.setString(_tokenKey, user.token!);
    }
  }

  /// Called after profile edit — updates user data without touching the token.
  static Future<void> saveUser(UserModel updatedUser) async {
    userNotifier.value = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _userKey,
        jsonEncode({
          'id': updatedUser.id,
          'name': updatedUser.name,
          'email': updatedUser.email,
          'role': updatedUser.role.name,
          'image': updatedUser.image,
          'latitude': updatedUser.latitude,
          'longitude': updatedUser.longitude,
        }));
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final token = prefs.getString(_tokenKey);
    userNotifier.value = UserModel.fromJson({...j, 'access_token': token});
  }

  static Future<void> clear() async {
    userNotifier.value = null;
    InAppNotificationStore.instance.clear();
    ChatService.instance.disconnect(); // drop stale socket auth on logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
