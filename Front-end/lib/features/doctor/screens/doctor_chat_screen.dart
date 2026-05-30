import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/chat_widgets.dart';

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

  // Always read live from session so it never goes stale or null
  String get _myId => SessionService.currentUser?.id ?? '';

  List<ChatMsg> _messages = [];
  bool _loading = true;
  String? _error;
  bool _patientOnline = false;

  @override
  void initState() {
    super.initState();
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

      final token = await ApiService.getToken();
      debugPrint('🔵 DoctorChat init | _myId=$_myId | token=${token?.substring(0, 20)}...');
      await ChatService.instance.connect(token ?? '');
      ChatService.instance.joinRoom(widget.conversationId);
      ChatService.instance.markRead(widget.conversationId);

      ChatService.instance.onNewMessage(_onNew);
      ChatService.instance.onMessageEdited(_onEdited);
      ChatService.instance.onMessageDeletedEveryone(_onDeletedEveryone);
      ChatService.instance.onMessagesRead(_onRead);
      ChatService.instance.onUserOnline((id) {
        if (id == widget.patientId && mounted) setState(() => _patientOnline = true);
      });
      ChatService.instance.onUserOffline((id) {
        if (id == widget.patientId && mounted) setState(() => _patientOnline = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not open chat: $e'; });
    }
  }

  // ── Socket handlers ─────────────────────────────────────────────────────────
  void _onNew(Map<String, dynamic> data) {
    final msg = ChatMsg.fromJson(data);
    debugPrint('🟡 new_message | senderId=${msg.senderId} | _myId=$_myId | match=${msg.senderId == _myId}');
    if (_messages.any((m) => m.id == msg.id)) return;
    if (!mounted) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
    if (msg.senderId != _myId) ChatService.instance.markRead(widget.conversationId);
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
    if (!mounted) return;
    setState(() {
      _messages = _messages.map((m) {
        if (m.senderId == _myId && !m.isRead) return m.copyWith(isRead: true);
        return m;
      }).toList();
    });
  }

  // ── Send ────────────────────────────────────────────────────────────────────
  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ChatService.instance.sendMessage(widget.conversationId, text);
  }

  // ── Media ───────────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) await _uploadMedia(File(x.path));
  }

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x != null) await _uploadMedia(File(x.path));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      await _uploadMedia(File(result.files.single.path!));
    }
  }

  Future<void> _uploadMedia(File file) async {
    try {
      await ChatApiService.uploadMedia(widget.conversationId, file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
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
            _SheetOption(icon: Icons.photo_library_outlined, label: 'Gallery',  onTap: () { Navigator.pop(context); _pickFromGallery(); }),
            _SheetOption(icon: Icons.insert_drive_file_outlined, label: 'Document', onTap: () { Navigator.pop(context); _pickFile(); }),
          ]),
        ),
      ),
    );
  }

  // ── Long-press menu ─────────────────────────────────────────────────────────
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
              _SheetOption(icon: Icons.edit_outlined, label: 'Edit Message',
                  onTap: () { Navigator.pop(context); _editMsg(msg); }),
            if (isMe)
              _SheetOption(icon: Icons.delete_sweep_outlined, label: 'Delete for Everyone',
                  color: Colors.red,
                  onTap: () { Navigator.pop(context); ChatService.instance.deleteForEveryone(msg.id); }),
            _SheetOption(icon: Icons.delete_outline_rounded, label: 'Delete for Me',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  ChatApiService.deleteForMe(msg.id);
                  setState(() => _messages.removeWhere((m) => m.id == msg.id));
                }),
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
        content: TextField(controller: ctrl, maxLines: null, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    ChatService.instance.leaveRoom(widget.conversationId);
    ChatService.instance.offAll();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? null : const Color(0xFFF7F8FA),
      appBar: ChatAppBar(
        name: widget.patientName,
        subtitle: 'Patient',
        imageUrl: widget.patientImageUrl,
        isOnline: _patientOnline,
        isVerifiedDoctor: false,
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Expanded(child: _buildBody()),
        ChatInputBar(
          controller: _ctrl,
          onSend: _send,
          onAttach: _showAttachMenu,
          onCamera: _pickFromCamera,
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text('No messages yet.', style: TextStyle(color: AppColors.grey)),
      );
    }
    final items = buildChatItems(
      messages: _messages,
      myId: _myId,
      myColor: RoleTheme.doctor,
      baseUrl: ApiService.baseUrl,
      onLongPress: _showMsgOptions,
      onImageTap: (url) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ImageFullScreen(url: url))),
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
  const _SheetOption({required this.icon, required this.label, required this.onTap, this.color});

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
