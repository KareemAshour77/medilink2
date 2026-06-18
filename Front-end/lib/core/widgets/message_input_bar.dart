// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// widgets/message_input_bar.dart
//
// The bottom input strip containing:
//   • Attachment icon button → opens picker sheet
//   • Styled TextField
//   • Send button with scale animation + haptic feedback
//
// The AnimationController for the send button is owned HERE
// (not in ChatScreen) because the animation is purely visual
// and local to this widget.  ChatScreen provides [onSend]
// which already handles the business logic side.
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;

  /// Triggered when the user taps Send or submits the TextField.
  final VoidCallback onSend;

  /// Triggered when the user taps the attachment clip icon.
  final VoidCallback onAttachmentTap;

  /// Localised hint text for the TextField.
  final String hintText;

  /// When false, the whole composer is disabled (e.g. while a required
  /// follow-up choice is pending).
  final bool enabled;

  const MessageInputBar({
    required this.controller,
    required this.onSend,
    required this.onAttachmentTap,
    required this.hintText,
    this.enabled = true,
    super.key,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar>
    with SingleTickerProviderStateMixin {
  // Scale animation for the send button (0.85 → 1.0)
  late final AnimationController _sendScale = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    lowerBound: 0.85,
    upperBound: 1.0,
    value: 1.0,
  );

  void _handleSend() {
    if (!widget.enabled) return;
    // 1. Haptic
    HapticFeedback.lightImpact();
    // 2. Visual: scale down then back up
    _sendScale.reverse().then((_) => _sendScale.forward());
    // 3. Delegate business logic to parent
    widget.onSend();
  }

  @override
  void dispose() {
    _sendScale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: context.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: Row(children: [
            // ── Attachment button ──────────────────────────
            GestureDetector(
              onTap: widget.enabled ? widget.onAttachmentTap : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Text field ─────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.divider),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  style: TextStyle(color: context.text, fontSize: 15),
                  textAlignVertical: TextAlignVertical.center,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: context.text.withOpacity(0.4)),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    // Balanced inner padding — text sits centered with no large
                    // left/right empty gaps.
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Send button with scale animation ───────────
            ScaleTransition(
              scale: _sendScale,
              child: GestureDetector(
                onTap: _handleSend,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
