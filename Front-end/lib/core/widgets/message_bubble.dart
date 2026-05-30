// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/message_bubble.dart
//
// Renders a single chat bubble.  Handles:
//   • User vs AI alignment & colour
//   • Image / file / text content variants
//   • Typewriter animation for bot text
//   • Expand / collapse for long messages
//   • Long-press copy to clipboard
//   • Delivery status row (sending / sent / failed + retry)
//
// Thinking-type messages are NOT rendered here; they are
// routed to AIThinkingCard by MessagesList.
// ─────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/chat_models.dart';
import 'typing_indicator.dart'; // re-uses BotAvatar

// ══════════════════════════════════════════════════════════
// MessageBubble — public API
// ══════════════════════════════════════════════════════════
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  /// Called when the user taps "retry" on a failed message.
  final VoidCallback? onRetry;

  const MessageBubble({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _expanded = false;

  /// Characters before the message is truncated with "Show more".
  static const int _collapseThreshold = 320;

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isLong = (msg.text?.length ?? 0) > _collapseThreshold;
    final displayText = (isLong && !_expanded)
        ? '${msg.text!.substring(0, _collapseThreshold)}…'
        : msg.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            msg.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // ── Bubble row ─────────────────────────────────
          Row(
            mainAxisAlignment:
                msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.isBot) ...[
                const BotAvatar(),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: GestureDetector(
                  onLongPress: msg.text != null
                      ? () => _copyText(context, msg.text!)
                      : null,
                  child: _BubbleContainer(
                    message: msg,
                    displayText: displayText,
                  ),
                ),
              ),

              if (!msg.isBot) const SizedBox(width: 8),
            ],
          ),

          // ── Show more / Show less ──────────────────────
          if (isLong) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(
                left:  msg.isBot ? 38 : 0,
                right: msg.isBot ? 0  : 8,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // ── Status row (user messages only) ───────────
          if (!msg.isBot) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MessageStatusIndicator(
                status: msg.status,
                onRetry: widget.onRetry,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Private: styled bubble container ─────────────────────
class _BubbleContainer extends StatelessWidget {
  final ChatMessage message;
  final String? displayText;

  const _BubbleContainer({required this.message, this.displayText});

  @override
  Widget build(BuildContext context) {
    final msg = message;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: msg.isBot ? context.card : AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(16),
          topRight:    const Radius.circular(16),
          bottomLeft:  Radius.circular(msg.isBot ? 4  : 16),
          bottomRight: Radius.circular(msg.isBot ? 16 : 4),
        ),
        border: (msg.isBot && context.isDark)
            ? Border.all(color: context.divider)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: _buildContent(context, msg, displayText),
    );
  }

  Widget _buildContent(BuildContext context, ChatMessage msg, String? text) {
    if (msg.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(msg.image!, width: 180),
      );
    }
    if (msg.isFile) {
      return _FileBubbleContent(message: msg);
    }
    // Text — bot uses typewriter, user uses plain Text
    if (msg.isBot) {
      return TypewriterText(
        key: ValueKey(msg.id),
        messageId: msg.id,
        text: text!,
        style: TextStyle(color: context.text, fontSize: 14, height: 1.4),
      );
    }
    return Text(
      text!,
      style: const TextStyle(
          color: Colors.white, fontSize: 14, height: 1.4),
    );
  }
}

// ── Private: file icon + name inside a bubble ─────────────
class _FileBubbleContent extends StatelessWidget {
  final ChatMessage message;
  const _FileBubbleContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final isPdf =
        message.fileName?.toLowerCase().endsWith('.pdf') ?? false;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
        color: message.isBot ? Colors.red : Colors.white,
        size: 28,
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          message.fileName ?? 'file',
          style: TextStyle(
            color: message.isBot ? context.text : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}

// ── Private: delivery status widget ──────────────────────
class _MessageStatusIndicator extends StatelessWidget {
  final MsgStatus status;
  final VoidCallback? onRetry;

  const _MessageStatusIndicator({required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MsgStatus.sending:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.grey),
          ),
          const SizedBox(width: 4),
          Text(
            'Sending',
            style: TextStyle(
                fontSize: 10, color: context.text.withOpacity(0.4)),
          ),
        ]);

      case MsgStatus.sent:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.done_all_rounded,
              size: 13, color: AppColors.success),
          const SizedBox(width: 3),
          Text(
            'Sent',
            style: TextStyle(
                fontSize: 10, color: context.text.withOpacity(0.4)),
          ),
        ]);

      case MsgStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 13, color: Colors.red),
            SizedBox(width: 3),
            Text(
              'Failed — tap to retry',
              style: TextStyle(fontSize: 10, color: Colors.red),
            ),
          ]),
        );
    }
  }
}

// ══════════════════════════════════════════════════════════
// TypewriterText — public so MessageBubble can use it
// ══════════════════════════════════════════════════════════
class TypewriterText extends StatefulWidget {
  final String messageId;
  final String text;
  final TextStyle style;

  const TypewriterText({
    required this.messageId,
    required this.text,
    required this.style,
    super.key,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  // Persists across widget recycling — IDs of messages whose animation is done.
  static final Set<String> _animatedIds = {};

  int _visibleChars = 0;
  Timer? _timer;

  static const int _charsPerTick = 3;
  static const Duration _tickInterval = Duration(milliseconds: 18);

  @override
  void initState() {
    super.initState();
    if (_animatedIds.contains(widget.messageId)) {
      // Already animated before — show instantly, no timer.
      _visibleChars = widget.text.length;
    } else {
      _startTyping();
    }
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _timer?.cancel();
      _visibleChars = 0;
      _animatedIds.remove(widget.messageId);
      _startTyping();
    }
  }

  void _startTyping() {
    if (widget.text.length <= 40) {
      if (mounted) setState(() => _visibleChars = widget.text.length);
      _animatedIds.add(widget.messageId);
      return;
    }
    _timer = Timer.periodic(_tickInterval, (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _visibleChars =
            (_visibleChars + _charsPerTick).clamp(0, widget.text.length);
      });
      if (_visibleChars >= widget.text.length) {
        t.cancel();
        _animatedIds.add(widget.messageId);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.text.substring(0, _visibleChars), style: widget.style);
}
