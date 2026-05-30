import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/api_service.dart';
import 'doctor_chat_screen.dart';

// ── Conversation data from API ────────────────────────────────────────────────
class _Conv {
  final String id;
  final String otherId;
  final String otherName;
  final String? otherImageUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const _Conv({
    required this.id,
    required this.otherId,
    required this.otherName,
    this.otherImageUrl,
    this.lastMessage,
    this.lastMessageAt,
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

  factory _Conv.fromJson(Map<String, dynamic> j) {
    final other = j['other'] as Map<String, dynamic>? ?? {};
    final imgPath = other['image'] as String?;
    return _Conv(
      id: j['id'] as String? ?? '',
      otherId: other['id'] as String? ?? '',
      otherName: other['name'] as String? ?? 'Patient',
      otherImageUrl: imgPath != null ? '${ApiService.baseUrl}/$imgPath' : null,
      lastMessage: j['lastMessage'] as String?,
      lastMessageAt: j['lastMessageAt'] != null
          ? DateTime.tryParse(j['lastMessageAt'].toString())
          : null,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class DoctorChatList extends StatefulWidget {
  const DoctorChatList({super.key});
  @override
  State<DoctorChatList> createState() => _DoctorChatListState();
}

class _DoctorChatListState extends State<DoctorChatList> {
  final _search = TextEditingController();
  List<_Conv> _convs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Messages',
                style: TextStyle(
                    color: context.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(
              _loading
                  ? 'Loading…'
                  : '${_convs.length} conversation${_convs.length == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
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
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
        Expanded(child: _buildBody(context, filtered)),
      ]),
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

    if (_convs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.grey),
          const SizedBox(height: 12),
          const Text('No conversations yet.',
              style: TextStyle(color: AppColors.grey, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Patients will appear here once they start a chat.',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text('No results for "${_search.text}"',
            style: const TextStyle(color: AppColors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: filtered.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: context.divider.withOpacity(0.5)),
        itemBuilder: (_, i) => _ConvTile(
          conv: filtered[i],
          index: i,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorChatScreen(
                  conversationId: filtered[i].id,
                  patientId: filtered[i].otherId,
                  patientName: filtered[i].otherName,
                  patientImageUrl: filtered[i].otherImageUrl,
                ),
              ),
            );
            // Refresh on return so last message updates
            _loadConversations();
          },
        ),
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────
class _ConvTile extends StatefulWidget {
  final _Conv conv;
  final int index;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.index, required this.onTap});
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: RoleTheme.doctor.withOpacity(0.13),
                backgroundImage: c.otherImageUrl != null
                    ? NetworkImage(c.otherImageUrl!)
                    : null,
                child: c.otherImageUrl == null
                    ? Text(c.initials,
                        style: const TextStyle(
                            color: RoleTheme.doctor,
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
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(
                        c.lastMessage ?? 'Tap to open conversation',
                        style: TextStyle(
                            color: c.lastMessage != null
                                ? context.text.withOpacity(0.65)
                                : AppColors.grey,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
              ),
              const SizedBox(width: 10),
              Text(c.timeLabel,
                  style: const TextStyle(color: AppColors.grey, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }
}
