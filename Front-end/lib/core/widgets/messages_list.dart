// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/messages_list.dart
//
// Owns the ListView and its scroll behaviour.
// Responsibilities:
//   • Render bubbles + typing indicator
//   • Wrap every item in AnimatedMessageEntry (fade+slide)
//   • Show EmptyState overlay when only the greeting exists
//   • Delegate actual bubble rendering to MessageBubble /
//     AIThinkingCard / TypingIndicator
//
// Scroll logic lives in ChatScreen (via ScrollController);
// this widget just holds the list structure.
// ─────────────────────────────────────────────────────────
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import 'ai_thinking_card.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';
import 'chat_animations.dart';

class MessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final ScrollController scrollController;

  /// Called when the user taps "retry" on a failed message.
  final void Function(ChatMessage message) onRetry;

  const MessagesList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Empty state (visible until user sends first message) ──
        if (messages.length <= 1) const Positioned.fill(child: _EmptyState()),

        // ── Message list ──────────────────────────────────────────
        ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          // +1 slot for the typing indicator when active
          itemCount: messages.length + (isTyping ? 1 : 0),
          itemBuilder: (_, i) {
            // ── Typing indicator slot ────────────────────
            if (isTyping && i == messages.length) {
              return AnimatedMessageEntry(
                key: const ValueKey('typing_indicator'),
                child: const TypingIndicator(),
              );
            }

            final msg = messages[i];

            // ── Thinking card (AI processing a file) ────
            if (msg.isThinking) {
              return AnimatedMessageEntry(
                key: ValueKey(msg.id),
                child: AIThinkingCard(label: msg.text ?? 'Analyzing...'),
              );
            }

            // ── Regular chat bubble ──────────────────────
            return AnimatedMessageEntry(
              key: ValueKey(msg.id),
              child: MessageBubble(
                message: msg,
                onRetry: msg.status == MsgStatus.failed
                    ? () => onRetry(msg)
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
// EmptyState — pulsing placeholder shown before first reply
// ══════════════════════════════════════════════════════════
class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _fade = Tween<double>(begin: 0.35, end: 0.85)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask MediBot anything',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.text.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload lab results, X-rays, or prescriptions\nfor AI-powered analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.text.withOpacity(0.4),
            ),
          ),
        ]),
      ),
    );
  }
}
