import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/widgets/chat_widgets.dart';

// Doctor-side chat color (as specified in design)
const _kDoctorColor = Color(0xFF01A610);

class DoctorChatScreen extends StatefulWidget {
  final String conversationId;
  final String patientId;
  final String patientName;
  final String? patientImageUrl;

  const DoctorChatScreen({
    super.key,
    required this.conversationId,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  String get _myId => SessionService.currentUser?.id ?? '';

  List<ChatMsg> _messages = [];
  bool _loading = true;
  String? _error;

  bool _patientOnline = false;
  DateTime? _lastSeen;

  // Typing
  bool _patientTyping = false;
  bool _isSendingTyping = false;
  Timer? _typingDebounce;
  ChatMsg? _replyTo;
  String? _highlightedId;
  final Map<String, GlobalKey> _messageKeys = {};

  GlobalKey _keyFor(String id) =>
      _messageKeys.putIfAbsent(id, () => GlobalKey());

  Future<void> _scrollToMessage(String msgId) async {
    final key = _keyFor(msgId);

    Future<void> ensureVisible() async {
      final ctx = key.currentContext;
      if (ctx == null) return;
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.3,
      );
    }

    if (key.currentContext != null) {
      await ensureVisible();
    } else {
      final idx = _messages.indexWhere((m) => m.id == msgId);
      if (idx < 0 || !_scroll.hasClients) return;
      final ratio = idx / _messages.length;
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent * ratio,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      await Future.delayed(const Duration(milliseconds: 60));
      await ensureVisible();
    }

    if (!mounted) return;
    setState(() => _highlightedId = msgId);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _highlightedId = null);
  }

  @override
  void initState() {
    super.initState();
    FcmService.activeChatConversationId = widget.conversationId;
    _init();
  }

  Future<void> _init() async {
    try {
      final history = await ChatApiService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = history.map(ChatMsg.fromJson).toList();
        _loading  = false;
      });
      _scrollToBottom();

      await ChatService.instance.connect();
      ChatService.instance.joinRoom(widget.conversationId);
      ChatService.instance.markRead(widget.conversationId);

      ChatService.instance.onNewMessage(_onNew);
      ChatService.instance.onMessageEdited(_onEdited);
      ChatService.instance.onMessageDeletedEveryone(_onDeletedEveryone);
      ChatService.instance.onMessagesRead(_onRead);
      ChatService.instance.onMessageDelivered(_onDelivered);

      ChatService.instance.onUserOnline((id) {
        if (id == widget.patientId && mounted) {
          setState(() => _patientOnline = true);
        }
      });

      ChatService.instance.onUserOffline((id, lastSeen) {
        if (id == widget.patientId && mounted) {
          setState(() {
            _patientOnline = false;
            _lastSeen = lastSeen;
          });
        }
      });

      // Request the current status in case the patient was already online/offline
      ChatService.instance.onUserStatus((id, online, lastSeen) {
        if (id == widget.patientId && mounted) {
          setState(() {
            _patientOnline = online;
            if (!online && lastSeen != null) _lastSeen = lastSeen;
          });
        }
      });
      ChatService.instance.getUserStatus(widget.patientId);

      ChatService.instance.onTypingStart((id) {
        if (id == widget.patientId && mounted) {
          setState(() => _patientTyping = true);
        }
      });

      ChatService.instance.onTypingStop((id) {
        if (id == widget.patientId && mounted) {
          setState(() => _patientTyping = false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not open chat: $e'; });
    }
  }

  // ── Socket handlers ─────────────────────────────────────────────────────────
  void _onNew(Map<String, dynamic> data) {
    final msg = ChatMsg.fromJson(data);
    if (_messages.any((m) => m.id == msg.id)) return;
    if (!mounted) return;
    setState(() {
      _messages.add(msg);
      if (msg.senderId == widget.patientId) _patientTyping = false;
    });
    _scrollToBottom();
    if (msg.senderId != _myId) {
      ChatService.instance.ackDelivered(msg.id);
      ChatService.instance.markRead(widget.conversationId);
    }
  }

  void _onDelivered(Map<String, dynamic> data) {
    final id = data['messageId'] as String?;
    if (id == null || !mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.id == id);
      if (i >= 0 && _messages[i].deliveredAt == null) {
        _messages[i] = _messages[i].copyWith(
          deliveredAt: DateTime.tryParse(data['deliveredAt']?.toString() ?? '') ?? DateTime.now(),
        );
      }
    });
  }

  void _onEdited(Map<String, dynamic> data) {
    final updated = ChatMsg.fromJson(data);
    if (!mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.id == updated.id);
      if (i >= 0) _messages[i] = updated;
    });
  }

  void _onDeletedEveryone(Map<String, dynamic> data) {
    final id = data['messageId'] as String?;
    if (id == null || !mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.id == id);
      if (i >= 0) _messages[i] = _messages[i].copyWith(isDeletedForEveryone: true);
    });
  }

  void _onRead(Map<String, dynamic> data) {
    // Only update ticks when the OTHER person read my messages.
    // If readBy == _myId I triggered this event myself — ignore it.
    final readBy = data['readBy'] as String?;
    if (readBy == null || readBy == _myId || !mounted) return;
    setState(() {
      _messages = _messages.map((m) {
        if (m.senderId == _myId && !m.isRead) {
          return m.copyWith(isRead: true, deliveredAt: m.deliveredAt ?? DateTime.now());
        }
        return m;
      }).toList();
    });
  }

  // ── Typing detection ─────────────────────────────────────────────────────────
  void _onTextChanged(String text) {
    if (!_isSendingTyping && text.isNotEmpty) {
      _isSendingTyping = true;
      ChatService.instance.startTyping(widget.conversationId, otherId: widget.patientId);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_isSendingTyping) {
        _isSendingTyping = false;
        ChatService.instance.stopTyping(widget.conversationId, otherId: widget.patientId);
      }
    });
    if (text.isEmpty && _isSendingTyping) {
      _isSendingTyping = false;
      _typingDebounce?.cancel();
      ChatService.instance.stopTyping(widget.conversationId, otherId: widget.patientId);
    }
  }

  // ── Send ────────────────────────────────────────────────────────────────────
  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    if (_isSendingTyping) {
      _isSendingTyping = false;
      _typingDebounce?.cancel();
      ChatService.instance.stopTyping(widget.conversationId, otherId: widget.patientId);
    }
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    ChatService.instance.sendMessage(widget.conversationId, text, replyToId: replyId);
  }

  // ── Media ───────────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (x != null) await _uploadMedia(File(x.path));
  }

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (x != null) await _uploadMedia(File(x.path));
  }

  Future<void> _pickFile() async {
    final result =
        await FilePicker.pickFiles(type: FileType.any, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      await _uploadMedia(File(result.files.single.path!));
    }
  }

  Future<void> _uploadMedia(File file) async {
    try {
      await ChatApiService.uploadMedia(widget.conversationId, file);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Upload failed: $e');
      }
    }
  }

  // ── Attachment sheet ────────────────────────────────────────────────────────
  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: () { Navigator.pop(context); _pickFromGallery(); },
            ),
            _SheetOption(
              icon: Icons.insert_drive_file_outlined,
              label: 'Document',
              onTap: () { Navigator.pop(context); _pickFile(); },
            ),
          ]),
        ),
      ),
    );
  }

  // ── Long-press message options ──────────────────────────────────────────────
  void _showMsgOptions(ChatMsg msg) {
    final isMe = msg.senderId == _myId;
    if (msg.isDeletedForEveryone) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isMe && msg.type == 'text')
              _SheetOption(
                icon: Icons.edit_outlined,
                label: 'Edit Message',
                onTap: () { Navigator.pop(context); _editMsg(msg); },
              ),
            if (isMe)
              _SheetOption(
                icon: Icons.delete_sweep_outlined,
                label: 'Delete for Everyone',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  ChatService.instance.deleteForEveryone(msg.id);
                },
              ),
            _SheetOption(
              icon: Icons.delete_outline_rounded,
              label: 'Delete for Me',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                ChatApiService.deleteForMe(msg.id);
                setState(() => _messages.removeWhere((m) => m.id == msg.id));
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _editMsg(ChatMsg msg) {
    final ctrl = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Message'),
        content:
            TextField(controller: ctrl, maxLines: null, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              ChatService.instance.editMessage(msg.id, text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    FcmService.activeChatConversationId = null;
    _typingDebounce?.cancel();
    if (_isSendingTyping) {
      ChatService.instance.stopTyping(widget.conversationId, otherId: widget.patientId);
    }
    ChatService.instance.leaveRoom(widget.conversationId);
    ChatService.instance.offAll();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // End chat access for this patient. Keeps the conversation & messages;
  // the patient must send a new request to chat again.
  Future<void> _confirmEndChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End chat?'),
        content: Text(
          '${widget.patientName} will need to send a new request before they '
          'can chat with you again. Your messages will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Chat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppointmentService.endChat(widget.patientId);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        'Chat ended. ${widget.patientName} must request again.',
        backgroundColor: _kDoctorColor,
      );
      Navigator.pop(context); // leave the chat screen
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Could not end chat: $msg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.isDark ? null : const Color(0xFFF7F8FA),
      appBar: ChatAppBar(
        name: widget.patientName,
        subtitle: 'Patient',
        imageUrl: widget.patientImageUrl,
        isOnline: _patientOnline,
        isVerifiedDoctor: false,
        isTyping: _patientTyping,
        lastSeen: _lastSeen,
        roleColor: _kDoctorColor,
        actions: [
          IconButton(
              icon: const Icon(Icons.call_outlined), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'end') _confirmEndChat();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'end',
                child: Row(children: [
                  Icon(Icons.block_rounded, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('End Chat'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        ValueListenableBuilder<bool>(
          valueListenable: ChatService.instance.connectionNotifier,
          builder: (_, connected, __) {
            if (connected) return const SizedBox.shrink();
            return const ConnectionBanner();
          },
        ),
        Expanded(child: _buildBody()),
        if (_patientTyping)
          TypingIndicator(name: widget.patientName),
        if (_replyTo != null)
          ReplyBar(
            message: _replyTo!,
            myId: _myId,
            onCancel: () => setState(() => _replyTo = null),
          ),
        ChatInputBar(
          controller: _ctrl,
          onSend: _send,
          onAttach: _showAttachMenu,
          onCamera: _pickFromCamera,
          onChanged: _onTextChanged,
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: AppColors.grey),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet.',
            style: TextStyle(color: AppColors.grey)),
      );
    }
    final items = buildChatItems(
      messages: _messages,
      myId: _myId,
      myColor: _kDoctorColor,
      baseUrl: ApiService.baseUrl,
      onLongPress: _showMsgOptions,
      onImageTap: (url) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ImageFullScreen(url: url))),
      onSwipeReply: (msg) => setState(() => _replyTo = msg),
      onTapReply: _scrollToMessage,
      keyFor: _keyFor,
      highlightedMessageId: _highlightedId,
    );
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SheetOption(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.text;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontSize: 15)),
      onTap: onTap,
    );
  }
}
