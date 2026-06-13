// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../../../models/reminder_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/reminder_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import 'add_reminder_sheet.dart';

class ReminderTab extends StatefulWidget {
  const ReminderTab({super.key});

  @override
  State<ReminderTab> createState() => _ReminderTabState();
}

class _ReminderTabState extends State<ReminderTab> {
  // All reminder data lives in the shared store so HomeTab changes
  // are immediately reflected here (and vice-versa).
  final _store = ReminderStore.instance;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  // ── Fetch reminders from API (delegates to store) ─────
  Future<void> _load() => _store.load();

  // ── Add / Edit ────────────────────────────────────────
  Future<void> _openSheet({ReminderModel? existing}) async {
    final result = await showModalBottomSheet<ReminderModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReminderSheet(existing: existing),
    );

    if (result == null || !mounted) return;

    // When editing: cancel the old slot notifications and delete from backend
    if (existing != null) {
      try {
        await NotificationService.cancelReminderAllSlots(existing);
      } catch (e) {
        debugPrint('ReminderTab: cancel notification failed – $e');
      }
      await ApiService.deleteReminder(existing.id);
    }

    // POST to backend
    final created = await ApiService.createReminder(result);
    if (!mounted) return;

    if (created == null) {
      AppSnackBar.show(context, 'Failed to save reminder. Please try again.');
      return;
    }

    // Reload to reflect the canonical server state
    await _load();

    // Schedule one local notification per dose-time slot.
    try {
      await NotificationService.scheduleReminderAllSlots(created);
    } catch (e) {
      debugPrint('ReminderTab: notification scheduling failed – $e');
    }
  }

  // ── Delete ────────────────────────────────────────────
  Future<void> _delete(ReminderModel r) async {
    try {
      await NotificationService.cancelReminderAllSlots(r);
    } catch (e) {
      debugPrint('ReminderTab: cancel notification failed – $e');
    }

    final ok = await ApiService.deleteReminder(r.id);
    if (!mounted) return;

    if (ok) {
      _store.removeReminder(r.id); // updates store → both tabs rebuild
    } else {
      AppSnackBar.show(context, 'Failed to delete reminder.');
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ListenableBuilder re-renders whenever the store changes (taken, add, delete)
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final reminders = _store.reminders;

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l.reminders,
                          style: TextStyle(
                            color: context.text,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l.todaySchedule,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _openSheet(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress chip
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(context.l.takenToday(_store.takenCount, _store.slotTotal),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: _store.loading
                    ? const Center(child: CircularProgressIndicator())
                    : reminders.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: reminders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _ReminderCard(
                                reminder: reminders[i],
                                onSlotTake: (slotIndex) => _store.markSlotTaken(
                                    reminders[i].id,
                                    slotIndex,
                                    !reminders[i].doseTimes[slotIndex].taken),
                                onEat: () =>
                                    _store.toggleEaten(reminders[i].id),
                                onEdit: () =>
                                    _openSheet(existing: reminders[i]),
                                onDelete: () => _delete(reminders[i]),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: AppColors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(context.l.noRemindersYet,
              style: const TextStyle(color: AppColors.grey, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            context.l.tapToAddOne,
            style:
                TextStyle(color: AppColors.grey.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReminderCard
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final void Function(int index) onSlotTake;
  final VoidCallback onEat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onSlotTake,
    required this.onEat,
    required this.onEdit,
    required this.onDelete,
  });

  static const _formImages = <MedicineForm, String>{
    MedicineForm.tablets: 'assets/images/tablets.png',
    MedicineForm.capsules: 'assets/images/capsule.png',
    MedicineForm.syrups: 'assets/images/syrup.png',
    MedicineForm.dropsEye: 'assets/images/drops.png',
    MedicineForm.dropsEar: 'assets/images/drops.png',
    MedicineForm.dropsNasal: 'assets/images/drops.png',
    MedicineForm.injection: 'assets/images/injection.png',
    MedicineForm.inhaler: 'assets/images/inhaler.png',
    MedicineForm.cream: 'assets/images/cream.png',
    MedicineForm.powder: 'assets/images/effervescent.png',
    MedicineForm.suppository: 'assets/images/suppository.png',
    MedicineForm.lozenge: 'assets/images/lozenge.png',
    MedicineForm.sublingual: 'assets/images/Sublingual.png',
  };

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period.name.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    final imagePath = r.type == ReminderType.doctor
        ? (context.isDark
            ? 'assets/images/doctor white.png'
            : 'assets/images/doctor black.png')
        : (_formImages[r.form] ?? 'assets/images/injection.png');

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return direction == DismissDirection.endToStart;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) onDelete();
      },
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: context.isDark ? Border.all(color: context.divider) : null,
            boxShadow: context.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: icon + name/priority + "Ate" ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(context.isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      imagePath,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Missing image: $imagePath');
                        return Icon(Icons.medication, size: 24, color: r.color);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: TextStyle(
                            color: context.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: r.allTaken
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(_priorityIcon(r.priority),
                                size: 11, color: _priorityColor(r.priority)),
                            const SizedBox(width: 3),
                            Text(
                              _priorityLabel(r.priority),
                              style: TextStyle(
                                color: _priorityColor(r.priority),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (r.type == ReminderType.medicine)
                    _ActionChip(
                      label: context.l.ateAlready,
                      color: r.eaten ? AppColors.success : AppColors.grey,
                      onTap: onEat,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── One row per dose-time slot ──
              for (var i = 0; i < r.doseTimes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_outlined, size: 13, color: r.color),
                      const SizedBox(width: 5),
                      Text(
                        _fmtTime(r.doseTimes[i].time),
                        style: TextStyle(
                          color: r.color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (r.type == ReminderType.medicine) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            r.doseTimes[i].meal.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.grey.withOpacity(0.9),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _ActionChip(
                        label: r.doseTimes[i].taken
                            ? context.l.doneTick
                            : context.l.take,
                        color:
                            r.doseTimes[i].taken ? AppColors.success : r.color,
                        onTap: () => onSlotTake(i),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return Colors.red.shade400;
      case Priority.normal:
        return Colors.orange.shade400;
      case Priority.low:
        return Colors.green.shade400;
    }
  }

  IconData _priorityIcon(Priority p) {
    switch (p) {
      case Priority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case Priority.normal:
        return Icons.remove_rounded;
      case Priority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.high:
        return 'High Priority';
      case Priority.normal:
        return 'Normal Priority';
      case Priority.low:
        return 'Low Priority';
    }
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.l.editReminder),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                title: Text('Delete reminder',
                    style: TextStyle(color: Colors.red.shade400)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionChip
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
