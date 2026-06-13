import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import 'chatbot_screen.dart';
import 'doctor_details_screen.dart';

// ── Conversation model ────────────────────────────────────────────────────────

class _Conv {
  final String id;
  final String otherId;
  final String otherName;
  final String? otherSpecialty;
  final String? otherImageUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const _Conv({
    required this.id,
    required this.otherId,
    required this.otherName,
    this.otherSpecialty,
    this.otherImageUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  String get initials {
    final parts = otherName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
  }

  String get timeLabel {
    if (lastMessageAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);
    if (diff.inDays == 0) {
      final h = lastMessageAt!.hour;
      final hh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      final m = lastMessageAt!.minute.toString().padLeft(2, '0');
      final p = h >= 12 ? 'PM' : 'AM';
      return '$hh:$m $p';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[lastMessageAt!.weekday - 1];
    }
    return '${lastMessageAt!.day}/${lastMessageAt!.month}';
  }

  _Conv copyWith({String? lastMessage, DateTime? lastMessageAt, int? unreadCount}) =>
      _Conv(
        id: id,
        otherId: otherId,
        otherName: otherName,
        otherSpecialty: otherSpecialty,
        otherImageUrl: otherImageUrl,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );

  factory _Conv.fromJson(Map<String, dynamic> j) {
    final other = j['other'] as Map<String, dynamic>? ?? {};
    final imgPath = other['image'] as String?;
    return _Conv(
      id: j['id'] as String? ?? '',
      otherId: other['id'] as String? ?? '',
      otherName: other['name'] as String? ?? 'Doctor',
      otherSpecialty: other['specialty'] as String?,
      otherImageUrl: imgPath != null ? '${ApiService.baseUrl}/$imgPath' : null,
      lastMessage: j['lastMessage'] as String?,
      lastMessageAt: j['lastMessageAt'] != null
          ? DateTime.tryParse(j['lastMessageAt'].toString())
          : null,
      unreadCount: j['unreadCount'] as int? ?? 0,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _search = TextEditingController();
  List<_Conv> _convs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    ChatService.instance.onConvUpdated(_onConvUpdated);
  }

  @override
  void dispose() {
    _search.dispose();
    ChatService.instance.offAll();
    super.dispose();
  }

  void _onConvUpdated(Map<String, dynamic> data) {
    if (!mounted) return;
    final convId      = data['conversationId'] as String?;
    final lastMessage = data['lastMessage'] as String?;
    final senderId    = data['senderId'] as String?;
    final lastMsgAt   = data['lastMessageAt'] != null
        ? DateTime.tryParse(data['lastMessageAt'].toString())
        : null;

    setState(() {
      final i = _convs.indexWhere((c) => c.id == convId);
      if (i < 0) {
        _loadConversations();
        return;
      }
      final myId = SessionService.currentUser?.id ?? '';
      final updated = _convs[i].copyWith(
        lastMessage: lastMessage,
        lastMessageAt: lastMsgAt,
        unreadCount: senderId != myId
            ? _convs[i].unreadCount + 1
            : _convs[i].unreadCount,
      );
      _convs
        ..removeAt(i)
        ..insert(0, updated);
    });
  }

  Future<void> _loadConversations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await ChatApiService.getConversations();
      if (!mounted) return;
      setState(() {
        _convs = raw.map(_Conv.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Could not load conversations.'; _loading = false; });
    }
  }

  List<_Conv> get _filtered {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return List.from(_convs);
    return _convs.where((c) => c.otherName.toLowerCase().contains(q)).toList();
  }

  Future<bool> _confirmDeleteConv(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove chat?'),
        content: Text('This deletes your conversation with $name and its messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteConv(_Conv c) async {
    final idx = _convs.indexOf(c);
    setState(() => _convs.remove(c));
    try {
      await ChatApiService.deleteConversation(c.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _convs.insert(idx < 0 ? 0 : idx, c));
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Delete failed: $msg');
    }
  }

  Widget _swipeBg(Alignment align) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      );

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: context.bg,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: context.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loading
                        ? 'Loading…'
                        : '${_convs.length} conversation${_convs.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // ── Search bar ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.divider),
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search messages…',
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(child: _buildBody(context, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<_Conv> filtered) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.grey)),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadConversations, child: const Text('Retry')),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── MediLink Bot — always pinned at top ───────────────────────
          _BotTile(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const ChatbotScreen(),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            ),
          ),

          Divider(height: 1, color: context.divider.withOpacity(0.5)),

          // ── Doctor conversations ──────────────────────────────────────
          if (_convs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 56, color: AppColors.grey),
                const SizedBox(height: 12),
                const Text('No conversations yet.',
                    style: TextStyle(color: AppColors.grey, fontSize: 15)),
                const SizedBox(height: 6),
                const Text(
                  'Doctors will appear here once you start a chat.',
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ]),
            )
          else if (filtered.isEmpty && _search.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No results for "${_search.text}"',
                    style: const TextStyle(color: AppColors.grey)),
              ),
            )
          else
            ...filtered.asMap().entries.expand((e) => [
                  Dismissible(
                    key: ValueKey(e.value.id),
                    direction: DismissDirection.horizontal,
                    background: _swipeBg(Alignment.centerLeft),
                    secondaryBackground: _swipeBg(Alignment.centerRight),
                    confirmDismiss: (_) => _confirmDeleteConv(e.value.otherName),
                    onDismissed: (_) => _deleteConv(e.value),
                    child: _ConvTile(
                      conv: e.value,
                      index: e.key,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientDoctorChatScreen(
                              doctorId: e.value.otherId,
                              doctorName: e.value.otherName,
                              specialization: e.value.otherSpecialty ?? '',
                              doctorImageUrl: e.value.otherImageUrl,
                            ),
                          ),
                        );
                        setState(() {
                          final idx = _convs.indexWhere((c) => c.id == e.value.id);
                          if (idx >= 0) {
                            _convs[idx] = _convs[idx].copyWith(unreadCount: 0);
                          }
                        });
                        ChatService.instance.onConvUpdated(_onConvUpdated);
                      },
                    ),
                  ),
                  if (e.key < filtered.length - 1)
                    Divider(
                      height: 1,
                      indent: 76,
                      color: context.divider.withOpacity(0.5),
                    ),
                ]),
        ],
      ),
    );
  }
}

// ── MediLink Bot tile ─────────────────────────────────────────────────────────

class _BotTile extends StatelessWidget {
  final VoidCallback onTap;
  const _BotTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('MediLink Bot',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('AI',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 3),
                Text('Ask me anything about your health',
                    style: TextStyle(
                        color: context.text.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.grey, size: 20),
        ]),
      ),
    );
  }
}

// ── Doctor conversation tile ──────────────────────────────────────────────────

class _ConvTile extends StatefulWidget {
  final _Conv conv;
  final int index;
  final VoidCallback onTap;
  const _ConvTile(
      {required this.conv, required this.index, required this.onTap});
  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 55),
        () { if (mounted) _ac.forward(); });
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.conv;
    final hasUnread = c.unreadCount > 0;

    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) { setState(() => _scale = 1); widget.onTap(); },
        onTapCancel: () => setState(() => _scale = 1),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 130),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.13),
                backgroundImage: c.otherImageUrl != null
                    ? NetworkImage(c.otherImageUrl!)
                    : null,
                child: c.otherImageUrl == null
                    ? Text(c.initials,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.otherName,
                        style: TextStyle(
                            color: context.text,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14)),
                    if (c.otherSpecialty != null &&
                        c.otherSpecialty!.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(c.otherSpecialty!,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 11)),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      c.lastMessage ?? 'Tap to open conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: hasUnread
                              ? context.text.withOpacity(0.85)
                              : c.lastMessage != null
                                  ? context.text.withOpacity(0.55)
                                  : AppColors.grey,
                          fontSize: 12,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.timeLabel,
                      style: TextStyle(
                          color:
                              hasUnread ? AppColors.primary : AppColors.grey,
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  const SizedBox(height: 5),
                  if (hasUnread)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
