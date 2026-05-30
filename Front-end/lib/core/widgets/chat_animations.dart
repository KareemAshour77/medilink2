// ignore_for_file: prefer_const_constructors
// ─────────────────────────────────────────────────────────
// shared/chat_animations.dart
//
// Reusable animation wrappers used by MessagesList and
// AttachmentPreview.  No business-logic dependencies.
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
// AnimatedMessageEntry
// Wraps any chat row with a fade-in + upward slide.
// Used for every bubble AND the typing indicator.
// ══════════════════════════════════════════════════════════
class AnimatedMessageEntry extends StatefulWidget {
  final Widget child;
  const AnimatedMessageEntry({required this.child, super.key});

  @override
  State<AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ══════════════════════════════════════════════════════════
// AnimatedThumbnail
// Wraps each file thumbnail card in the AttachmentPreview
// with a fade + easeOutBack scale entrance.
// ══════════════════════════════════════════════════════════
class AnimatedThumbnail extends StatefulWidget {
  final Widget child;
  const AnimatedThumbnail({required this.child, super.key});

  @override
  State<AnimatedThumbnail> createState() => _AnimatedThumbnailState();
}

class _AnimatedThumbnailState extends State<AnimatedThumbnail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<double> _scale =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
