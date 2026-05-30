import 'package:flutter/material.dart';
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
  final DateTime createdAt;

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
    required this.createdAt,
  });

  ChatMsg copyWith({
    String? content,
    bool? isRead,
    bool? isDeletedForEveryone,
    DateTime? editedAt,
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
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
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
// DateSeparator
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(color: context.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _label(),
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
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
// Sender (isMe) → LEFT with primary/role colour
// Receiver (!isMe) → RIGHT with neutral grey
// ─────────────────────────────────────────────────────────────────────────────

class ChatBubble extends StatelessWidget {
  final ChatMsg msg;
  final String myId;
  final Color myColor;
  final String baseUrl; // ApiService.baseUrl for media
  final void Function(ChatMsg)? onLongPress;
  final void Function(String)? onImageTap;

  const ChatBubble({
    super.key,
    required this.msg,
    required this.myId,
    required this.myColor,
    required this.baseUrl,
    this.onLongPress,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.senderId == myId;

    // Deleted for everyone
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
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: _BubbleContent(
        msg: msg,
        isMe: isMe,
        textColor: textColor,
        baseUrl: baseUrl,
        onImageTap: onImageTap,
      ),
    );

    return GestureDetector(
      onLongPress: onLongPress != null ? () => onLongPress!(msg) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [bubble],
        ),
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

  const _BubbleContent({
    required this.msg,
    required this.isMe,
    required this.textColor,
    required this.baseUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
              style: TextStyle(color: textColor, fontSize: 14.5, height: 1.4),
            ),

          const SizedBox(height: 4),

          // ── Footer: timestamp + edited + read status ──────────────────────
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (msg.editedAt != null) ...[
              Text(
                'edited',
                style: TextStyle(
                  color: isMe ? Colors.white54 : AppColors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              msg.timeLabel,
              style: TextStyle(
                color: isMe ? Colors.white60 : AppColors.grey,
                fontSize: 10.5,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.done_all_rounded,
                size: 14,
                color: msg.isRead ? Colors.blue[300] : Colors.white54,
              ),
            ],
          ]),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 100,
            color: AppColors.grey.withOpacity(0.2),
            child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.grey)),
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
  const _FileContent({required this.fileName, required this.isMe, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.insert_drive_file_rounded,
          color: isMe ? Colors.white70 : AppColors.primary, size: 22),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          fileName,
          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}

// ── Deleted-for-everyone placeholder ─────────────────────────────────────────

class _DeletedBubble extends StatelessWidget {
  final bool isMe;
  const _DeletedBubble({required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
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
}) {
  final items = <Widget>[];
  DateTime? lastDate;

  for (final msg in messages) {
    final msgDate = DateTime(
        msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
    if (lastDate == null || msgDate != lastDate) {
      items.add(DateSeparator(key: ValueKey('sep_$msgDate'), date: msgDate));
      lastDate = msgDate;
    }
    items.add(ChatBubble(
      key: ValueKey(msg.id),
      msg: msg,
      myId: myId,
      myColor: myColor,
      baseUrl: baseUrl,
      onLongPress: onLongPress,
      onImageTap: onImageTap,
    ));
  }
  return items;
}

// ─────────────────────────────────────────────────────────────────────────────
// ImageFullScreen  –  tap-to-view
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
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
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
  final String? subtitle; // specialization or "Patient"
  final String? imageUrl;
  final bool isOnline;
  final bool isVerifiedDoctor;
  final List<Widget>? actions;

  const ChatAppBar({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.isOnline = false,
    this.isVerifiedDoctor = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: context.card,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(children: [
        // Avatar
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22)
                : null,
          ),
          // Online dot
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF34C759) : AppColors.grey,
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
                    name,
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
                  const Icon(Icons.verified_rounded,
                      color: AppColors.primary, size: 14),
                ],
              ]),

              const SizedBox(height: 2),

              // Subtitle row (specialty badge + status)
              Row(children: [
                if (subtitle != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF34C759) : AppColors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF34C759) : AppColors.grey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
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

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttach,
    this.onCamera,
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
          // Attachment button
          if (onAttach != null)
            _BarIconBtn(
              icon: Icons.attach_file_rounded,
              onTap: onAttach!,
            ),
          // Camera button
          if (onCamera != null)
            _BarIconBtn(
              icon: Icons.camera_alt_outlined,
              onTap: onCamera!,
            ),

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
