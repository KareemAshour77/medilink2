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
import '../../../data/records_data.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final int reviews;
  final String experience;
  final String doctorId;
  final String? doctorImageUrl;

  const DoctorDetailsScreen({
    super.key,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.reviews,
    this.experience = '10+ years exp',
    this.doctorId = '',
    this.doctorImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Doctor Details', style: TextStyle(color: context.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _DoctorProfileHeader(
            name: name,
            specialization: specialization,
            rating: rating,
            reviews: reviews,
            experience: experience,
          ),
          const SizedBox(height: 18),
          const _InfoCards(),
          const SizedBox(height: 22),
          const _SectionTitle('About'),
          const SizedBox(height: 10),
          _AboutCard(name: name, specialization: specialization),
          const SizedBox(height: 22),
          _ReviewsHeader(count: reviews),
          const SizedBox(height: 10),
          const _ReviewTile(
            name: 'Mona Ali',
            comment:
                'Very kind and clear. The visit felt calm, organized, and helpful.',
            rating: 5,
          ),
          const _ReviewTile(
            name: 'Ahmed Hassan',
            comment:
                'Explained the diagnosis well and answered all my questions.',
            rating: 5,
          ),
          const _ReviewTile(
            name: 'Sara Mohamed',
            comment: 'Professional follow-up and easy communication.',
            rating: 4,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: _PulseChatButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDoctorChatScreen(
                    doctorId: doctorId,
                    doctorName: name,
                    specialization: specialization,
                    doctorImageUrl: doctorImageUrl,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DoctorProfileHeader extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final int reviews;
  final String experience;

  const _DoctorProfileHeader({
    required this.name,
    required this.specialization,
    required this.rating,
    required this.reviews,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
        border: context.isDark ? Border.all(color: context.divider) : null,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.18),
                AppColors.primaryDark.withOpacity(0.24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/male-doctor.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                specialization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    icon: Icons.star_rounded,
                    label: '$rating ($reviews)',
                    color: context.isDark ? Colors.white : Colors.black,
                  ),
                  _MiniBadge(
                    icon: Icons.workspace_premium_rounded,
                    label: experience,
                    color: context.isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

class _InfoCards extends StatelessWidget {
  const _InfoCards();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _InfoItem(Icons.location_on_rounded, 'Location', 'New Cairo'),
      const _InfoItem(Icons.call_rounded, 'Phone', '+20 100 123 4567'),
      const _InfoItem(Icons.schedule_rounded, 'Hours', '10:00 AM - 8:00 PM'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 520;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          return SizedBox(
            width:
                isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
            child: _InfoCard(item: item),
          );
        }).toList(),
      );
    });
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem(this.icon, this.title, this.value);
}

class _InfoCard extends StatelessWidget {
  final _InfoItem item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(context.isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String name;
  final String specialization;

  const _AboutCard({required this.name, required this.specialization});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark ? Border.all(color: context.divider) : null,
      ),
      child: Text(
        '$name is a trusted $specialization specialist focused on clear diagnosis, practical care plans, and comfortable patient communication.',
        style: TextStyle(
          color: context.text.withOpacity(0.78),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  final int count;

  const _ReviewsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const _SectionTitle('Reviews'),
      const Spacer(),
      Text(
        '$count total',
        style: const TextStyle(color: AppColors.grey, fontSize: 12),
      ),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.text,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final String comment;
  final int rating;

  const _ReviewTile({
    required this.name,
    required this.comment,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark ? Border.all(color: context.divider) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            name.substring(0, 1),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: context.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star_rounded,
                      size: 13,
                      // color: i < rating ? Colors.amber : AppColors.grey,
                      color: i < rating ? (context.isDark ? Colors.white : Colors.black) : AppColors.grey,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                comment,
                style: TextStyle(
                  color: context.text.withOpacity(0.68),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PulseChatButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PulseChatButton({required this.onPressed});

  @override
  State<_PulseChatButton> createState() => _PulseChatButtonState();
}

class _PulseChatButtonState extends State<_PulseChatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.035).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.36),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Start Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Patient-side real-time chat screen ───────────────────────────────────────

class PatientDoctorChatScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String? doctorImageUrl;

  const PatientDoctorChatScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    this.doctorImageUrl,
  });

  @override
  State<PatientDoctorChatScreen> createState() =>
      _PatientDoctorChatScreenState();
}

class _PatientDoctorChatScreenState extends State<PatientDoctorChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  String? _conversationId;
  String get _myId => SessionService.currentUser?.id ?? '';
  List<ChatMsg> _messages = [];
  bool _loading = true;
  String? _error;
  bool _doctorOnline = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.doctorId.isEmpty) {
      setState(() { _loading = false; _error = 'Chat unavailable for demo doctors.'; });
      return;
    }
    try {
      final conv = await ChatApiService.getOrCreateConversation(widget.doctorId);
      _conversationId = conv['id'] as String;

      final history = await ChatApiService.getMessages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages = history.map(ChatMsg.fromJson).toList();
        _loading = false;
      });
      _scrollToBottom();

      final token = await ApiService.getToken();
      await ChatService.instance.connect(token ?? '');
      ChatService.instance.joinRoom(_conversationId!);

      // Mark existing messages as read
      ChatService.instance.markRead(_conversationId!);

      // Listeners
      ChatService.instance.onNewMessage(_onNew);
      ChatService.instance.onMessageEdited(_onEdited);
      ChatService.instance.onMessageDeletedEveryone(_onDeletedEveryone);
      ChatService.instance.onMessagesRead(_onRead);
      ChatService.instance.onUserOnline((id) {
        if (id == widget.doctorId && mounted) setState(() => _doctorOnline = true);
      });
      ChatService.instance.onUserOffline((id) {
        if (id == widget.doctorId && mounted) setState(() => _doctorOnline = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not open chat: $e'; });
    }
  }

  void _onNew(Map<String, dynamic> data) {
    final msg = ChatMsg.fromJson(data);
    if (_messages.any((m) => m.id == msg.id)) return;
    if (!mounted) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
    // Auto-mark read since screen is open
    if (msg.senderId != _myId && _conversationId != null) {
      ChatService.instance.markRead(_conversationId!);
    }
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

  // ── Send text ───────────────────────────────────────────────────────────────
  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    _ctrl.clear();
    ChatService.instance.sendMessage(_conversationId!, text);
  }

  // ── Media picker ────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null && _conversationId != null) {
      await _uploadMedia(File(x.path));
    }
  }

  Future<void> _pickFromCamera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (x != null && _conversationId != null) {
      await _uploadMedia(File(x.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && _conversationId != null) {
      await _uploadMedia(File(result.files.single.path!));
    }
  }

  Future<void> _uploadMedia(File file) async {
    try {
      await ChatApiService.uploadMedia(_conversationId!, file);
      // Gateway broadcasts new_message to room — _onNew handles the UI update
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
            _AttachOption(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () { Navigator.pop(context); _pickFromGallery(); }),
            _AttachOption(icon: Icons.insert_drive_file_outlined, label: 'Document', onTap: () { Navigator.pop(context); _pickFile(); }),
            _AttachOption(icon: Icons.medical_information_outlined, label: 'Medical Record', onTap: () { Navigator.pop(context); _showRecordPicker(); }),
          ]),
        ),
      ),
    );
  }

  // ── Record picker ───────────────────────────────────────────────────────────
  void _showRecordPicker() {
    if (_conversationId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              const Icon(Icons.medical_information_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Share Medical Record',
                  style: TextStyle(
                      color: context.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sampleRecords.length,
              itemBuilder: (_, i) {
                final rec = sampleRecords[i];
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(rec.title,
                      style: TextStyle(
                          color: context.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  subtitle: Text(
                    '${rec.typeLabel}  •  ${rec.date.day}/${rec.date.month}/${rec.date.year}',
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.send_rounded,
                      color: AppColors.primary, size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    final content =
                        '📋 ${rec.title}\n${rec.typeLabel}  •  ${rec.doctorOrFacility}\n${rec.date.day}/${rec.date.month}/${rec.date.year}';
                    ChatService.instance.sendMessage(
                        _conversationId!, content);
                  },
                );
              },
            ),
          ),
        ]),
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
              _AttachOption(
                icon: Icons.edit_outlined,
                label: 'Edit Message',
                onTap: () { Navigator.pop(context); _editMsg(msg); },
              ),
            if (isMe)
              _AttachOption(
                icon: Icons.delete_sweep_outlined,
                label: 'Delete for Everyone',
                color: Colors.red,
                onTap: () { Navigator.pop(context); _deleteEveryone(msg); },
              ),
            _AttachOption(
              icon: Icons.delete_outline_rounded,
              label: 'Delete for Me',
              color: Colors.red,
              onTap: () { Navigator.pop(context); _deleteForMe(msg); },
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

  void _deleteEveryone(ChatMsg msg) {
    ChatService.instance.deleteForEveryone(msg.id);
  }

  void _deleteForMe(ChatMsg msg) {
    ChatApiService.deleteForMe(msg.id);
    setState(() => _messages.removeWhere((m) => m.id == msg.id));
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
    if (_conversationId != null) ChatService.instance.leaveRoom(_conversationId!);
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
        name: widget.doctorName,
        subtitle: widget.specialization,
        imageUrl: widget.doctorImageUrl,
        isOnline: _doctorOnline,
        isVerifiedDoctor: true,
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
        child: Text('No messages yet. Say hello!', style: TextStyle(color: AppColors.grey)),
      );
    }
    final items = buildChatItems(
      messages: _messages,
      myId: _myId,
      myColor: AppColors.primary,
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

// ── Helper widgets for sheets ─────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _AttachOption({required this.icon, required this.label, required this.onTap, this.color});

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

