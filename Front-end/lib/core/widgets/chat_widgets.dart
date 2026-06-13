import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatMsg  –  immutable message model
// ─────────────────────────────────────────────────────────────────────────────

class ChatMsg {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text' | 'image' | 'file'
  final String? mediaUrl;
  final String? fileName;
  final bool isRead;
  final bool isDeletedForEveryone;
  final DateTime? editedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;

  const ChatMsg({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.mediaUrl,
    this.fileName,
    this.isRead = false,
    this.isDeletedForEveryone = false,
    this.editedAt,
    this.deliveredAt,
    required this.createdAt,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
  });

  ChatMsg copyWith({
    String? content,
    bool? isRead,
    bool? isDeletedForEveryone,
    DateTime? editedAt,
    DateTime? deliveredAt,
  }) =>
      ChatMsg(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content ?? this.content,
        type: type,
        mediaUrl: mediaUrl,
        fileName: fileName,
        isRead: isRead ?? this.isRead,
        isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
        editedAt: editedAt ?? this.editedAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        createdAt: createdAt,
      );

  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
        id: j['id'] as String? ?? '',
        conversationId: j['conversationId'] as String? ?? '',
        senderId: (j['senderId'] ?? j['sender_id'] ?? '') as String,
        content: j['content'] as String? ?? '',
        type: j['type'] as String? ?? 'text',
        mediaUrl: j['mediaUrl'] as String?,
        fileName: j['fileName'] as String?,
        isRead: j['isRead'] as bool? ?? false,
        isDeletedForEveryone: j['isDeletedForEveryone'] as bool? ?? false,
        editedAt: j['editedAt'] != null
            ? DateTime.tryParse(j['editedAt'].toString())
            : null,
        deliveredAt: j['deliveredAt'] != null
            ? DateTime.tryParse(j['deliveredAt'].toString())
            : null,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        replyToId: j['replyToId'] as String?,
        replyToContent: j['replyToContent'] as String?,
        replyToSenderName: j['replyToSenderName'] as String?,
      );

  String get timeLabel {
    final h = createdAt.hour;
    final hh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final m = createdAt.minute.toString().padLeft(2, '0');
    final p = h >= 12 ? 'PM' : 'AM';
    return '$hh:$m $p';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DateSeparator  –  centered date chip between message groups
// ─────────────────────────────────────────────────────────────────────────────

class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: context.divider, height: 1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF2A3450)
                : const Color(0xFFEEF0F3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _label(),
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.divider, height: 1)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatBubble
// ─────────────────────────────────────────────────────────────────────────────

class ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  final String myId;
  final Color myColor;
  final String baseUrl;
  final void Function(ChatMsg)? onLongPress;
  final void Function(String)? onImageTap;
  final void Function(ChatMsg)? onSwipeReply;
  final void Function(String)? onTapReply;
  final bool isHighlighted;

  const ChatBubble({
    super.key,
    required this.msg,
    required this.myId,
    required this.myColor,
    required this.baseUrl,
    this.onLongPress,
    this.onImageTap,
    this.onSwipeReply,
    this.onTapReply,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.senderId == myId;

    if (msg.isDeletedForEveryone) {
      return _DeletedBubble(isMe: isMe);
    }

    final bubbleColor = isMe
        ? myColor
        : (context.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0));
    final textColor = isMe ? Colors.white : context.text;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _BubbleContent(
        msg: msg,
        isMe: isMe,
        textColor: textColor,
        baseUrl: baseUrl,
        onImageTap: onImageTap,
        onTapReply: onTapReply,
      ),
    );

    final row = GestureDetector(
      onLongPress: onLongPress != null ? () => onLongPress!(msg) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primary.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bubble],
          ),
        ),
      ),
    );

    if (onSwipeReply == null) return row;

    return _SwipeToReply(
      isMe: isMe,
      onReply: () => onSwipeReply!(msg),
      child: row,
    );
  }
}

// ── Swipe-to-reply wrapper ────────────────────────────────────────────────────

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback onReply;

  const _SwipeToReply({
    required this.child,
    required this.isMe,
    required this.onReply,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _dragX = 0;
  double _startX = 0;
  bool _triggered = false;
  static const _threshold = 64.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _ctrl.addListener(() {
      if (mounted) setState(() => _dragX = _startX * (1 - _ctrl.value));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _ctrl.stop();
    final next = (_dragX + d.delta.dx).clamp(0.0, _threshold * 1.2);
    setState(() => _dragX = next);
    if (!_triggered && _dragX >= _threshold) {
      _triggered = true;
      HapticFeedback.lightImpact();
      widget.onReply();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _triggered = false;
    _startX = _dragX;
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (_dragX / _threshold).clamp(0.0, 1.0);
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Reply icon appears behind the bubble
          if (_dragX > 4)
            Positioned(
              left: widget.isMe ? null : 4,
              right: widget.isMe ? 4 : null,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.reply_rounded,
                        size: 18, color: AppColors.grey),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// ── Bubble content (text / image / file) ─────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  final ChatMsg msg;
  final bool isMe;
  final Color textColor;
  final String baseUrl;
  final void Function(String)? onImageTap;
  final void Function(String)? onTapReply;

  const _BubbleContent({
    required this.msg,
    required this.isMe,
    required this.textColor,
    required this.baseUrl,
    this.onImageTap,
    this.onTapReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Reply preview ─────────────────────────────────────────────────
          if (msg.replyToContent != null) ...[
            _ReplyPreview(
              senderName: msg.replyToSenderName ?? 'Unknown',
              content: msg.replyToContent!,
              isMe: isMe,
              onTap: msg.replyToId != null
                  ? () => onTapReply?.call(msg.replyToId!)
                  : null,
            ),
            const SizedBox(height: 4),
          ],

          // ── Main content ──────────────────────────────────────────────────
          if (msg.type == 'image' && msg.mediaUrl != null)
            _ImageContent(url: '$baseUrl/${msg.mediaUrl}', onTap: onImageTap)
          else if (msg.type == 'file' && msg.mediaUrl != null)
            _FileContent(
              fileName: msg.fileName ?? 'File',
              isMe: isMe,
              textColor: textColor,
            )
          else
            Text(
              msg.content,
              style: TextStyle(color: textColor, fontSize: 14.5, height: 1.45),
            ),

          const SizedBox(height: 5),

          // ── Footer: timestamp + edited + read status ──────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (msg.editedAt != null) ...[
                Text(
                  'edited',
                  style: TextStyle(
                    color: isMe ? Colors.white54 : AppColors.grey,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                msg.timeLabel,
                style: TextStyle(
                  color: isMe ? Colors.white60 : AppColors.grey,
                  fontSize: 10.5,
                  letterSpacing: 0.1,
                ),
              ),
              // 3-state tick: single gray = sent, double gray = delivered, double blue = read
              if (isMe) ...[
                const SizedBox(width: 4),
                _MessageTick(msg: msg),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Message tick (3-state) ────────────────────────────────────────────────────

class _MessageTick extends StatelessWidget {
  final ChatMsg msg;
  const _MessageTick({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isRead) {
      return const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF34B7F1));
    } else if (msg.deliveredAt != null) {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white54);
    } else {
      return const Icon(Icons.done_rounded, size: 14, color: Colors.white54);
    }
  }
}

// ── Image bubble content ──────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final String url;
  final void Function(String)? onTap;
  const _ImageContent({required this.url, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(url) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 100,
            color: AppColors.grey.withOpacity(0.2),
            child: const Center(
                child: Icon(Icons.broken_image_rounded, color: AppColors.grey)),
          ),
        ),
      ),
    );
  }
}

// ── File bubble content ───────────────────────────────────────────────────────

class _FileContent extends StatelessWidget {
  final String fileName;
  final bool isMe;
  final Color textColor;
  const _FileContent(
      {required this.fileName, required this.isMe, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.insert_drive_file_rounded,
          color: isMe ? Colors.white70 : AppColors.primary, size: 22),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          fileName,
          style: TextStyle(
              color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}

// ── Reply preview inside bubble ───────────────────────────────────────────────

class _ReplyPreview extends StatelessWidget {
  final String senderName;
  final String content;
  final bool isMe;
  final VoidCallback? onTap;

  const _ReplyPreview({
    required this.senderName,
    required this.content,
    required this.isMe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.15)
            : AppColors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white54 : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isMe ? Colors.white70 : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isMe ? Colors.white60 : AppColors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),   // closes Container
    );   // closes GestureDetector
  }
}

// ── Reply bar (shown above input when replying) ───────────────────────────────

class ReplyBar extends StatelessWidget {
  final ChatMsg message;
  final String myId;
  final VoidCallback onCancel;

  const ReplyBar({
    super.key,
    required this.message,
    required this.myId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == myId;
    final senderLabel = isMe ? 'You' : (message.replyToSenderName ?? 'Doctor');
    final preview = message.type == 'image'
        ? '📷 Photo'
        : message.type == 'file'
            ? '📎 ${message.fileName ?? 'File'}'
            : message.content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.card,
        border: Border(top: BorderSide(color: context.divider, width: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMe ? 'You' : senderLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onCancel,
          child: const Icon(Icons.close_rounded, color: AppColors.grey, size: 20),
        ),
      ]),
    );
  }
}

// ── Deleted-for-everyone placeholder ─────────────────────────────────────────

class _DeletedBubble extends StatelessWidget {
  final bool isMe;
  const _DeletedBubble({required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.grey.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.block_rounded, size: 13, color: AppColors.grey),
              const SizedBox(width: 5),
              Text(
                'This message was deleted',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// buildChatItems  –  inserts DateSeparators between days
// ─────────────────────────────────────────────────────────────────────────────

List<Widget> buildChatItems({
  required List<ChatMsg> messages,
  required String myId,
  required Color myColor,
  required String baseUrl,
  void Function(ChatMsg)? onLongPress,
  void Function(String)? onImageTap,
  void Function(ChatMsg)? onSwipeReply,
  void Function(String)? onTapReply,
  GlobalKey Function(String)? keyFor,
  String? highlightedMessageId,
}) {
  final items = <Widget>[];
  DateTime? lastDate;

  for (final msg in messages) {
    final msgDate =
        DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
    if (lastDate == null || msgDate != lastDate) {
      items.add(DateSeparator(key: ValueKey('sep_$msgDate'), date: msgDate));
      lastDate = msgDate;
    }
    items.add(ChatBubble(
      key: keyFor != null ? keyFor(msg.id) : ValueKey(msg.id),
      msg: msg,
      myId: myId,
      myColor: myColor,
      baseUrl: baseUrl,
      onLongPress: onLongPress,
      onImageTap: onImageTap,
      onSwipeReply: onSwipeReply,
      onTapReply: onTapReply,
      isHighlighted: highlightedMessageId == msg.id,
    ));
  }
  return items;
}

// ─────────────────────────────────────────────────────────────────────────────
// ImageFullScreen  –  tap-to-view with pan & zoom
// ─────────────────────────────────────────────────────────────────────────────

class ImageFullScreen extends StatelessWidget {
  final String url;
  const ImageFullScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConnectionBanner  –  shown when socket is disconnected
// ─────────────────────────────────────────────────────────────────────────────

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.orange.shade700,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text(
            'Reconnecting…',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TypingIndicator  –  "X is typing…" shown above input bar
// ─────────────────────────────────────────────────────────────────────────────

class TypingIndicator extends StatelessWidget {
  final String name;
  const TypingIndicator({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF0F0F0),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(delay: 0),
            const SizedBox(width: 3),
            _Dot(delay: 150),
            const SizedBox(width: 3),
            _Dot(delay: 300),
          ]),
        ),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ac.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatAppBar  –  shared header for both chat screens
// ─────────────────────────────────────────────────────────────────────────────

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final bool isOnline;
  final bool isVerifiedDoctor;
  final bool isTyping;
  final DateTime? lastSeen;
  final Color? roleColor;
  final List<Widget>? actions;

  const ChatAppBar({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.isOnline = false,
    this.isVerifiedDoctor = false,
    this.isTyping = false,
    this.lastSeen,
    this.roleColor,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  Color get _role => roleColor ?? AppColors.primary;

  String _statusText() {
    if (isTyping) return 'typing…';
    if (isOnline) return 'Online';
    if (lastSeen != null) return _formatLastSeen(lastSeen!);
    return 'Offline';
  }

  Color _statusColor() {
    if (isTyping) return _role;
    if (isOnline) return const Color(0xFF34C759);
    return AppColors.grey;
  }

  static String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour;
    final hh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = h >= 12 ? 'PM' : 'AM';
    final time = '$hh:$m $p';
    if (dtDay == today) return 'last seen today at $time';
    if (dtDay == today.subtract(const Duration(days: 1))) {
      return 'last seen yesterday at $time';
    }
    return 'last seen ${dt.day}/${dt.month} at $time';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _statusText();
    final statusColor = _statusColor();

    return AppBar(
      elevation: 0.5,
      backgroundColor: context.card,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: context.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(children: [
        // Avatar with online dot
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _role.withOpacity(0.12),
            backgroundImage:
                imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Icon(Icons.person_rounded, color: _role, size: 22)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF34C759)
                    : AppColors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: context.card, width: 1.5),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 10),

        // Name + specialty + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Name row
              Row(children: [
                Flexible(
                  child: Text(
                    isVerifiedDoctor ? 'Dr. $name' : name,
                    style: TextStyle(
                      color: context.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerifiedDoctor) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.verified_rounded, color: _role, size: 14),
                ],
              ]),

              const SizedBox(height: 2),

              // Subtitle row (role badge + specialty badge + status)
              Row(children: [
                if (isVerifiedDoctor) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _role.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Doctor',
                      style: TextStyle(
                        color: _role,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          isTyping ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
      actions: actions,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatInputBar  –  shared input area
// ─────────────────────────────────────────────────────────────────────────────

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onCamera;
  final ValueChanged<String>? onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttach,
    this.onCamera,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.card,
        border: Border(top: BorderSide(color: context.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          if (onAttach != null)
            _BarIconBtn(icon: Icons.attach_file_rounded, onTap: onAttach!),
          if (onCamera != null)
            _BarIconBtn(icon: Icons.camera_alt_outlined, onTap: onCamera!),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 110),
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                onChanged: onChanged,
                style: TextStyle(color: context.text, fontSize: 14.5),
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(color: AppColors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BarIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, color: AppColors.grey, size: 22),
      ),
    );
  }
}
