import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected == true;

  final ValueNotifier<bool> connectionNotifier = ValueNotifier(false);

  // ── Connect ─────────────────────────────────────────────────────────────────
  Future<void> connect() async {
    _socket?.disconnect();
    _socket = null;
    connectionNotifier.value = false;
    final token = await ApiService.getToken() ?? '';
    _socket = io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) {
      connectionNotifier.value = true;
      debugPrint('ChatService: connected');
    });
    _socket!.onDisconnect((_) {
      connectionNotifier.value = false;
      debugPrint('ChatService: disconnected');
    });
    _socket!.on('error', (d) => debugPrint('ChatService error: $d'));
  }

  // ── Room ────────────────────────────────────────────────────────────────────
  void joinRoom(String conversationId) =>
      _socket?.emit('join_room', {'conversationId': conversationId});

  void leaveRoom(String conversationId) =>
      _socket?.emit('leave_room', {'conversationId': conversationId});

  // ── Messages ────────────────────────────────────────────────────────────────
  void sendMessage(String conversationId, String content, {String? replyToId}) =>
      _socket?.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,
      });

  void editMessage(String messageId, String content) => _socket
      ?.emit('edit_message', {'messageId': messageId, 'content': content});

  void deleteForEveryone(String messageId) =>
      _socket?.emit('delete_for_everyone', {'messageId': messageId});

  void markRead(String conversationId) =>
      _socket?.emit('mark_read', {'conversationId': conversationId});

  void ackDelivered(String messageId) =>
      _socket?.emit('message_delivered_ack', {'messageId': messageId});

  // ── Typing ──────────────────────────────────────────────────────────────────
  void startTyping(String conversationId, {String? otherId}) =>
      _socket?.emit('typing_start', {
        'conversationId': conversationId,
        if (otherId != null) 'otherId': otherId,
      });

  void stopTyping(String conversationId, {String? otherId}) =>
      _socket?.emit('typing_stop', {
        'conversationId': conversationId,
        if (otherId != null) 'otherId': otherId,
      });

  // Requests current online/offline state for a user; response via onUserStatus
  void getUserStatus(String userId) =>
      _socket?.emit('get_user_status', {'userId': userId});

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

  void onMessageDelivered(void Function(Map<String, dynamic>) handler) {
    _socket?.on('message_delivered', (d) {
      if (d is Map) handler(Map<String, dynamic>.from(d));
    });
  }

  void onConvUpdated(void Function(Map<String, dynamic>) handler) {
    _socket?.on('conv_updated', (d) {
      if (d is Map) handler(Map<String, dynamic>.from(d));
    });
  }

  void onUserOnline(void Function(String userId) handler) {
    _socket?.on('user_online', (d) {
      if (d is Map) handler(d['userId'] as String? ?? '');
    });
  }

  // lastSeen is null if the user was never seen offline or if the backend
  // is older and doesn't send it yet — callers should treat null as unknown.
  void onUserOffline(void Function(String userId, DateTime? lastSeen) handler) {
    _socket?.on('user_offline', (d) {
      if (d is Map) {
        final userId = d['userId'] as String? ?? '';
        final lsStr = d['lastSeen'] as String?;
        final lastSeen = lsStr != null ? DateTime.tryParse(lsStr) : null;
        handler(userId, lastSeen);
      }
    });
  }

  void onTypingStart(void Function(String userId) handler) {
    _socket?.on('typing_start', (d) {
      if (d is Map) handler(d['userId'] as String? ?? '');
    });
  }

  void onTypingStop(void Function(String userId) handler) {
    _socket?.on('typing_stop', (d) {
      if (d is Map) handler(d['userId'] as String? ?? '');
    });
  }

  // Response event for getUserStatus — fires once per request with current state
  void onUserStatus(
      void Function(String userId, bool online, DateTime? lastSeen) handler) {
    _socket?.on('user_status', (d) {
      if (d is Map) {
        final userId = d['userId'] as String? ?? '';
        final online = d['online'] as bool? ?? false;
        final lsStr = d['lastSeen'] as String?;
        final lastSeen = lsStr != null ? DateTime.tryParse(lsStr) : null;
        handler(userId, online, lastSeen);
      }
    });
  }

  // ── Remove all listeners ────────────────────────────────────────────────────
  void offAll() {
    _socket?.off('new_message');
    _socket?.off('message_edited');
    _socket?.off('message_deleted_everyone');
    _socket?.off('messages_read');
    _socket?.off('message_delivered');
    _socket?.off('conv_updated');
    _socket?.off('user_online');
    _socket?.off('user_offline');
    _socket?.off('typing_start');
    _socket?.off('typing_stop');
    _socket?.off('user_status');
  }

  // ── Disconnect ──────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    connectionNotifier.value = false;
  }
}
