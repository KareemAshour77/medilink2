// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/in_app_notification.dart';
import '../services/notification_service.dart';

// ---------------------------------------------------------------------------
// Data model — represents an in-app notification item shown in the bell list.
// This is separate from ReminderModel so the UI layer stays decoupled from
// the domain layer.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// NotificationBellButton
// ---------------------------------------------------------------------------

/// A self-contained bell icon button that:
///   • Shows a badge with the unread count.
///   • Opens a bottom sheet listing all in-app notifications.
///   • For medication notifications, renders ✅ Taken / ⏰ Snooze actions.
///
/// Usage:
/// ```dart
/// NotificationBellButton(
///   notifications: _notifications,
///   onTaken: (n) async { /* mark as taken */ },
///   onSnoozed: (n) async { /* handle snooze */ },
///   onNotificationRead: (n) async { /* mark read */ },
/// )
/// ```
class NotificationBellButton extends StatefulWidget {
  final List<InAppNotification> notifications;
  final void Function(InAppNotification notification)? onDismissed;
  final VoidCallback? onClearedAll;

  /// Called when the user taps ✅ Taken on a medication notification.
  final Future<void> Function(InAppNotification notification)? onTaken;

  /// Called when the user taps ⏰ Snooze on a medication notification.
  final Future<void> Function(InAppNotification notification)? onSnoozed;

  /// Called when a notification item is tapped (for navigation / read state).
  final Future<void> Function(InAppNotification notification)?
      onNotificationRead;

  const NotificationBellButton({
    super.key,
    required this.notifications,
    this.onDismissed,
    this.onClearedAll,
    this.onTaken,
    this.onSnoozed,
    this.onNotificationRead,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  int get _unreadCount =>
      widget.notifications.where((n) => !n.isDismissed).length;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bellAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _animateBell() {
    _bellController.forward().then((_) => _bellController.reverse());
  }

  void _openSheet() {
    _animateBell();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        notifications: widget.notifications,
        onTaken: widget.onTaken,
        onSnoozed: widget.onSnoozed,
        onNotificationRead: widget.onNotificationRead,
        onDismissed: widget.onDismissed,
        onClearedAll: widget.onClearedAll,
        onChanged: () => setState(() {}), // rebuild badge after actions
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openSheet,
      child: AnimatedBuilder(
        animation: _bellAnimation,
        builder: (_, child) =>
            Transform.rotate(angle: _bellAnimation.value, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Bell icon ──────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 22,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            // ── Badge ──────────────────────────────────────────────────────
            if (_unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: _Badge(count: _unreadCount),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(count),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935), // medical red
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet
// ---------------------------------------------------------------------------

class _NotificationSheet extends StatefulWidget {
  final List<InAppNotification> notifications;
  final Future<void> Function(InAppNotification)? onTaken;
  final Future<void> Function(InAppNotification)? onSnoozed;
  final Future<void> Function(InAppNotification)? onNotificationRead;
  final void Function(InAppNotification)? onDismissed;
  final VoidCallback? onClearedAll;
  final VoidCallback onChanged;

  const _NotificationSheet({
    required this.notifications,
    required this.onChanged,
    this.onTaken,
    this.onSnoozed,
    this.onNotificationRead,
    this.onDismissed,
    this.onClearedAll,
  });

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(parent: _slideController, curve: Curves.easeIn);

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  List<InAppNotification> get _active =>
      widget.notifications.where((n) => !n.isDismissed).toList();

  void _dismiss(InAppNotification n) {
    widget.onDismissed?.call(n);
    if (widget.onDismissed == null) {
      setState(() => n.isDismissed = true);
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * 0.80),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      size: 22,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D1B2A),
                          ),
                    ),
                    const Spacer(),
                    if (_active.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          widget.onClearedAll?.call();
                          if (widget.onClearedAll == null) {
                            for (final n in widget.notifications) {
                              n.isDismissed = true;
                            }
                          }
                          setState(() {});
                          widget.onChanged();
                        },
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1, indent: 20, endIndent: 20),

              // ── List ─────────────────────────────────────────────────────
              Flexible(
                child: _active.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        itemCount: _active.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = _active[index];
                          return _NotificationItem(
                            notification: n,
                            onTaken: widget.onTaken != null
                                ? () async {
                                    await widget.onTaken!(n);
                                    // Also forward to the system notification handler
                                    await NotificationService
                                        .handleNotificationAction(
                                      _buildFakeResponse(
                                        n,
                                        NotificationActions.taken,
                                      ) as NotificationResponse,
                                    );
                                    _dismiss(n);
                                  }
                                : null,
                            onSnoozed: widget.onSnoozed != null
                                ? () async {
                                    await widget.onSnoozed!(n);
                                    await NotificationService
                                        .handleNotificationAction(
                                      _buildFakeResponse(
                                        n,
                                        NotificationActions.snooze,
                                      ),
                                    );
                                    _dismiss(n);
                                  }
                                : null,
                            onTap: () async {
                              await widget.onNotificationRead?.call(n);
                              _dismiss(n);
                            },
                          );
                        },
                      ),
              ),

              SizedBox(height: mq.viewInsets.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a synthetic [NotificationResponse] so [handleNotificationAction]
  /// can be reused from the in-app UI without duplicating snooze logic.
  _FakeNotificationResponse _buildFakeResponse(
    InAppNotification n,
    String actionId,
  ) {
    return _FakeNotificationResponse(
      id: n.id.hashCode,
      actionId: actionId,
      payload: '${n.id}|${n.medicationName ?? n.title}|${n.doseStr ?? '1'}',
    );
  }
}

// ---------------------------------------------------------------------------
// Synthetic NotificationResponse — lets the UI reuse handleNotificationAction
// without triggering a real system notification interaction.
// ---------------------------------------------------------------------------

/// A thin wrapper that exposes the same fields [handleNotificationAction]
/// reads, without requiring a real platform callback.
class _FakeNotificationResponse implements NotificationResponse {
  @override
  final int? id;
  @override
  final String? actionId;
  @override
  final String? payload;
  @override
  final String? input = null;
  @override
  final Map<String, dynamic> data = const <String, dynamic>{};
  @override
  final NotificationResponseType notificationResponseType =
      NotificationResponseType.selectedNotificationAction;

  _FakeNotificationResponse({
    required this.id,
    required this.actionId,
    required this.payload,
  });
}

// ---------------------------------------------------------------------------
// Individual notification item card
// ---------------------------------------------------------------------------

class _NotificationItem extends StatelessWidget {
  final InAppNotification notification;
  final VoidCallback? onTaken;
  final VoidCallback? onSnoozed;
  final VoidCallback? onTap;

  const _NotificationItem({
    required this.notification,
    this.onTaken,
    this.onSnoozed,
    this.onTap,
  });

  IconData get _icon {
    return switch (notification.type) {
      InAppNotificationType.medication => Icons.medication_outlined,
      InAppNotificationType.doctor => Icons.local_hospital_outlined,
      InAppNotificationType.general => Icons.info_outline,
    };
  }

  Color get _iconColor {
    return switch (notification.type) {
      InAppNotificationType.medication => const Color(0xFF00897B), // teal
      InAppNotificationType.doctor => const Color(0xFF1565C0), // blue
      InAppNotificationType.general => const Color(0xFF6D4C41), // brown
    };
  }

  Color get _iconBg {
    return switch (notification.type) {
      InAppNotificationType.medication => const Color(0xFFE0F2F1),
      InAppNotificationType.doctor => const Color(0xFFE3F2FD),
      InAppNotificationType.general => const Color(0xFFEFEBE9),
    };
  }

  String get _timeLabel {
    final now = DateTime.now();
    final diff = now.difference(notification.time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isMedication = notification.type == InAppNotificationType.medication;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + title + time ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon bubble
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, size: 22, color: _iconColor),
                  ),
                  const SizedBox(width: 12),

                  // Title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time label
                  const SizedBox(width: 8),
                  Text(
                    _timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // ── Action buttons (medication only) ──────────────────────────
              if (isMedication && (onTaken != null || onSnoozed != null)) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // ✅ Taken
                    if (onTaken != null)
                      Expanded(
                        child: _ActionButton(
                          label: '✅  Taken',
                          backgroundColor: const Color(0xFFE8F5E9),
                          textColor: const Color(0xFF2E7D32),
                          onPressed: onTaken!,
                        ),
                      ),
                    if (onTaken != null && onSnoozed != null)
                      const SizedBox(width: 8),
                    // ⏰ Snooze
                    if (onSnoozed != null)
                      Expanded(
                        child: _ActionButton(
                          label: '⏰  Snooze',
                          backgroundColor: const Color(0xFFFFF3E0),
                          textColor: const Color(0xFFE65100),
                          onPressed: onSnoozed!,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending notifications right now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
