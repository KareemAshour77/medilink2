import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected == true;

  // ── Connect ─────────────────────────────────────────────────────────────────
  // Always disconnect and discard the previous socket before creating a new one.
  // This prevents stale patient/doctor auth when switching accounts, even if
  // the socket is in a reconnecting state (connected==false but object alive).
  Future<void> connect(String token) async {
    _socket?.disconnect();
    _socket = null;
    _socket = io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) => debugPrint('ChatService: connected'));
    _socket!.onDisconnect((_) => debugPrint('ChatService: disconnected'));
    _socket!.on('error', (d) => debugPrint('ChatService error: $d'));
  }

  // ── Room ────────────────────────────────────────────────────────────────────
  void joinRoom(String conversationId) =>
      _socket?.emit('join_room', {'conversationId': conversationId});

  void leaveRoom(String conversationId) =>
      _socket?.emit('leave_room', {'conversationId': conversationId});

  // ── Messages ────────────────────────────────────────────────────────────────
  void sendMessage(String conversationId, String content) =>
      _socket?.emit('send_message', {'conversationId': conversationId, 'content': content});

  void editMessage(String messageId, String content) =>
      _socket?.emit('edit_message', {'messageId': messageId, 'content': content});

  void deleteForEveryone(String messageId) =>
      _socket?.emit('delete_for_everyone', {'messageId': messageId});

  void markRead(String conversationId) =>
      _socket?.emit('mark_read', {'conversationId': conversationId});

  // ── Listeners ───────────────────────────────────────────────────────────────
  void onNewMessage(void Function(Map<String, dynamic>) handler) {
    _socket?.on('new_message', (d) {
      if (d is Map) handler(Map<String, dynamic>.from(d));
    });
  }

  void onMessageEdited(void Function(Map<String, dynamic>) handler) {
    _socket?.on('message_edited', (d) {
      if (d is Map) handler(Map<String, dynamic>.from(d));
    });
  }

  void onMessageDeletedEveryone(void Function(Map<String, dynamic>) handler) {
    _socket?.on('message_deleted_everyone', (d) {
      if (d is Map) handler(Map<String, dynamic>.from(d));
    });
  }

  void onMessagesRead(void Function(Map<String, dynamic>) handler) {
    _socket?.on('messages_read', (d) {
      if (d is Map) handler(Map<String, dynamic>.from(d));
    });
  }

  void onUserOnline(void Function(String userId) handler) {
    _socket?.on('user_online', (d) {
      if (d is Map) handler(d['userId'] as String? ?? '');
    });
  }

  void onUserOffline(void Function(String userId) handler) {
    _socket?.on('user_offline', (d) {
      if (d is Map) handler(d['userId'] as String? ?? '');
    });
  }

  // ── Remove all listeners for a namespace ────────────────────────────────────
  void offAll() {
    _socket?.off('new_message');
    _socket?.off('message_edited');
    _socket?.off('message_deleted_everyone');
    _socket?.off('messages_read');
    _socket?.off('user_online');
    _socket?.off('user_offline');
  }

  // ── Disconnect ──────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
