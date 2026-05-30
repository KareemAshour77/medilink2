// lib/core/utils/animation_utils.dart
//
// Central animation toolkit for the healthcare app.
// Every widget here is self-contained, stateful, and performance-friendly.
// All durations sit in the 200-400 ms sweet spot for medical UX (calm, clear).

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. FadeSlideIn
//    Fades in + slides upward from a small offset.
//    Use for any content that should "arrive" when a screen loads.
//
//    Example:
//      FadeSlideIn(delay: const Duration(milliseconds: 120), child: MyCard())
// ─────────────────────────────────────────────────────────────────────────────
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset; // vertical start offset in logical pixels (positive = from below)
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.slideOffset = 24.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(parent: _ctrl, curve: widget.curve)
        .drive(Tween(begin: 0.0, end: 1.0));

    _slide = CurvedAnimation(parent: _ctrl, curve: widget.curve).drive(
      Tween(
        begin: Offset(0, widget.slideOffset / 100),
        end: Offset.zero,
      ),
    );

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. StaggeredList
//    Wraps a list of children and staggers their FadeSlideIn appearance.
//    Handles both Column and ListView scenarios by returning a plain List<Widget>.
//
//    Example (inside Column):
//      ...StaggeredList.widgets(children: myCards, stagger: 70)
//
//    Example (inside ListView.builder):
//      child: StaggeredList(children: myCards, stagger: 70)
// ─────────────────────────────────────────────────────────────────────────────
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final int stagger; // ms between each item
  final Duration itemDuration;
  final double slideOffset;
  final MainAxisSize mainAxisSize;

  const StaggeredList({
    super.key,
    required this.children,
    this.stagger = 65,
    this.itemDuration = const Duration(milliseconds: 320),
    this.slideOffset = 20.0,
    this.mainAxisSize = MainAxisSize.min,
  });

  /// Returns a plain list you can spread into another Column/Sliver.
  static List<Widget> widgets({
    required List<Widget> children,
    int stagger = 65,
    Duration itemDuration = const Duration(milliseconds: 320),
    double slideOffset = 20.0,
  }) {
    return List.generate(
      children.length,
      (i) => FadeSlideIn(
        delay: Duration(milliseconds: i * stagger),
        duration: itemDuration,
        slideOffset: slideOffset,
        child: children[i],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      children: List.generate(
        children.length,
        (i) => FadeSlideIn(
          delay: Duration(milliseconds: i * stagger),
          duration: itemDuration,
          slideOffset: slideOffset,
          child: children[i],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. ScaleTap
//    Gives any tappable widget a tactile scale-down (0.95) + spring-back feel.
//    Drop-in replacement for GestureDetector.
//
//    Example:
//      ScaleTap(onTap: () {}, child: MyButton())
// ─────────────────────────────────────────────────────────────────────────────
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween(begin: 1.0, end: widget.scaleDown)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. AnimatedProgressBar
//    Fills from 0 → value with an ease-out curve on first build.
//    Perfect for health stats, medication adherence, etc.
//
//    Example:
//      AnimatedProgressBar(value: 0.72, color: AppColors.primary)
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 – 1.0
  final Color color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween(begin: 0.0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween(begin: _anim.value, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(widget.height);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: br,
        child: LinearProgressIndicator(
          value: _anim.value,
          minHeight: widget.height,
          valueColor: AlwaysStoppedAnimation(widget.color),
          backgroundColor:
              widget.backgroundColor ?? widget.color.withOpacity(0.12),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. ReminderTakeButton
//    Animates between "Take" (pending) and "Done ✓" (completed) states.
//    Color, icon, and text all transition smoothly in 350 ms.
//
//    Example:
//      ReminderTakeButton(taken: reminder.taken, color: reminder.color,
//                         onTap: () => setState(() => reminder.taken = true))
// ─────────────────────────────────────────────────────────────────────────────
class ReminderTakeButton extends StatelessWidget {
  final bool taken;
  final Color color;
  final VoidCallback onTap;
  static const _duration = Duration(milliseconds: 350);

  const ReminderTakeButton({
    super.key,
    required this.taken,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: taken
              ? const Color(0xFF4CAF50).withOpacity(0.13)
              : color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: taken ? const Color(0xFF4CAF50) : color,
            width: 1.2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: _duration,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: taken
              ? const Row(
                  key: ValueKey('done'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50), size: 14),
                    SizedBox(width: 5),
                    Text('Done',
                        style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                )
              : Row(
                  key: const ValueKey('take'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medication_outlined, color: color, size: 14),
                    const SizedBox(width: 5),
                    Text('Take',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. TypingIndicator
//    Three animated dots that signal the AI is thinking.
//    Uses staggered AnimationControllers for a smooth wave effect.
//
//    Example:
//      if (isTyping) const TypingIndicator()
// ─────────────────────────────────────────────────────────────────────────────
class TypingIndicator extends StatefulWidget {
  final Color color;
  final double dotSize;

  const TypingIndicator({
    super.key,
    this.color = const Color(0xFF2196F3),
    this.dotSize = 8.0,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _ctrls
        .map((c) =>
            Tween(begin: 0.0, end: -6.0).animate(
                CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    // Stagger the start of each dot
    for (int i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) {
          _ctrls[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. ChatBubble
//    Message bubble that fades + slides in from bottom.
//    Differentiates user vs. assistant visually.
//
//    Example:
//      ChatBubble(message: msg.text, isUser: msg.isUser)
// ─────────────────────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Duration delay;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: delay,
      slideOffset: 16.0,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isUser ? 56 : 0,
            right: isUser ? 0 : 56,
            bottom: 8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? const Color(0xFF2196F3)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: TextStyle(
              color: isUser ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. PulsingFAB
//    A floating action button with a soft continuous pulse on the shadow.
//    Great for the AI chat button on HomeScreen.
//
//    Example:
//      PulsingFAB(onTap: () {}, child: Icon(Icons.chat_bubble_outline))
// ─────────────────────────────────────────────────────────────────────────────
class PulsingFAB extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const PulsingFAB({
    super.key,
    required this.child,
    required this.onTap,
    this.color = const Color(0xFF2196F3),
    this.size = 62.0,
  });

  @override
  State<PulsingFAB> createState() => _PulsingFABState();
}

class _PulsingFABState extends State<PulsingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _pulse = Tween(begin: 0.35, end: 0.65)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withBlue(200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_pulse.value),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. AnimatedCountUp
//    Animates an integer value from 0 → target.
//    Use for "X of Y taken" or stats counters.
//
//    Example:
//      AnimatedCountUp(value: 5, style: TextStyle(...))
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedCountUp extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String suffix;

  const AnimatedCountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.suffix = '',
  });

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = IntTween(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = IntTween(begin: _anim.value, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) =>
          Text('${_anim.value}${widget.suffix}', style: widget.style),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. AppPageRoute
//     Standard page route used across the app: soft fade + slide from bottom.
//     Replace MaterialPageRoute with this everywhere.
//
//     Example:
//       Navigator.push(context, AppPageRoute(builder: (_) => MyScreen()))
// ─────────────────────────────────────────────────────────────────────────────
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  AppPageRoute({required this.builder})
      : super(
          pageBuilder: (ctx, anim, __) => builder(ctx),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (_, anim, __, child) {
            final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
            final slide = Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. AnimatedTabIndicator
//     Sliding pill indicator for custom tab bars (Records tab, etc.).
//     Pass selectedIndex and it smoothly slides the highlight.
//
//     Example:
//       AnimatedTabIndicator(tabs: ['Lab', 'Imaging', 'Rx'], selectedIndex: _idx,
//                            onTap: (i) => setState(() => _idx = i))
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedTabIndicator extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;

  const AnimatedTabIndicator({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.activeColor = const Color(0xFF2196F3),
    this.inactiveColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: ScaleTap(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: active ? Colors.white : activeColor,
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(tabs[i]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12. ShimmerLoading
//     Skeleton shimmer placeholder while data is loading.
//     Use before list items appear.
//
//     Example:
//       if (loading) ShimmerLoading(height: 80, borderRadius: 16)
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerLoading extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 12.0,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _shimmer = Tween(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE8E8E8);
    final highlight = isDark ? const Color(0xFF3A3A50) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              math.max(0.0, _shimmer.value - 0.3),
              _shimmer.value.clamp(0.0, 1.0),
              math.min(1.0, _shimmer.value + 0.3),
            ],
          ),
        ),
      ),
    );
  }
}