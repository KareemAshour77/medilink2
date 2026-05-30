// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/ai_thinking_card.dart
//
// Transient card injected into the messages list while the
// AI is processing a file (prescription, X-ray, or doc).
// It pulses via a repeating fade animation and shows a
// spinner + contextual label (e.g. "🔬 Analyzing your X-ray…").
// Removed from the list by ChatScreen once the API responds.
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'typing_indicator.dart'; // re-uses BotAvatar

class AIThinkingCard extends StatefulWidget {
  /// Contextual label, e.g. "💊 Reading prescription…"
  final String label;

  const AIThinkingCard({required this.label, super.key});

  @override
  State<AIThinkingCard> createState() => _AIThinkingCardState();
}

class _AIThinkingCardState extends State<AIThinkingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _fade = Tween<double>(begin: 0.45, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
        // ── Bot avatar ───────────────────────────────────
        const BotAvatar(),
        const SizedBox(width: 8),

        // ── Pulsing bubble ───────────────────────────────
        FadeTransition(
          opacity: _fade,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              // Spinner
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              // Contextual label
              Text(
                widget.label,
                style: TextStyle(
                  color: context.text.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
