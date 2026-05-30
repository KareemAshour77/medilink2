// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/typing_indicator.dart
//
// Staggered 3-dot bounce that appears while the AI is
// preparing its response.  Shown/hidden by ChatScreen via
// the [isTyping] flag (wrapped in AnimatedMessageEntry by
// MessagesList so the entry animation is handled upstream).
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  // Single repeating controller — each dot gets its own staggered interval.
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  /// Builds a bouncing Y-offset animation with a staggered [delay] in 0..1.
  Animation<double> _dotAnim(double delay) => TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -5.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween(begin: -5.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: ConstantTween(0.0),
          weight: 40,
        ),
      ]).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0)),
      ));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        // ── Bot avatar icon ──────────────────────────────
        _BotAvatar(),
        const SizedBox(width: 8),

        // ── Bubble with 3 animated dots ──────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(16),
              topRight:    Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft:  Radius.circular(4),
            ),
            border: context.isDark
                ? Border.all(color: context.divider)
                : null,
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [0.0, 0.15, 0.3].map((delay) {
                return Transform.translate(
                  offset: Offset(0, _dotAnim(delay).value),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared bot avatar used by TypingIndicator & AIThinkingCard ──
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: AppColors.primary,
        size: 14,
      ),
    );
  }
}

// Private alias used within this file without the public name collision risk.
class _BotAvatar extends BotAvatar {
  const _BotAvatar();
}
