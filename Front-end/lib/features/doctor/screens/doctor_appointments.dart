import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../data/records_data.dart';
import 'doctor_chat_screen.dart';

class DoctorAppointments extends StatefulWidget {
  const DoctorAppointments({super.key});
  @override
  State<DoctorAppointments> createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments> {
  List<Map<String, dynamic>> _appts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await AppointmentService.getMyAppointments();
      if (!mounted) return;
      setState(() { _appts = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(int i) async {
    final id = _appts[i]['id'] as String? ?? '';
    setState(() => _appts[i]['status'] = 'confirmed');
    try {
      await AppointmentService.accept(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _appts[i]['status'] = 'pending');
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Accept failed: $msg');
      // If the appointment no longer exists on the server, reload to drop stale rows.
      if (msg.contains('not found') || msg == '404') _load();
    }
  }

  Future<void> _reject(int i) async {
    final id = _appts[i]['id'] as String? ?? '';
    setState(() => _appts[i]['status'] = 'rejected');
    try {
      await AppointmentService.reject(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _appts[i]['status'] = 'pending');
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Reject failed: $msg');
      if (msg.contains('not found') || msg == '404') _load();
    }
  }

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text('This removes the request from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _delete(Map<String, dynamic> appt) async {
    final id = appt['id'] as String? ?? '';
    final idx = _appts.indexOf(appt);
    setState(() => _appts.remove(appt));
    try {
      await AppointmentService.delete(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _appts.insert(idx < 0 ? 0 : idx, appt));
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Delete failed: $msg');
    }
  }

  Widget _swipeBg(Alignment align) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      );

  Future<void> _chatWithPatient(Map<String, dynamic> appt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final patientId = appt['patientId'] as String? ?? '';
      final patientName = appt['patientName'] as String? ?? 'Patient';
      final conv = await ChatApiService.getOrCreateConversationWithPatient(patientId);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DoctorChatScreen(
          conversationId: conv['id'] as String,
          patientId: patientId,
          patientName: patientName,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.show(context, 'Could not open chat: $e');
    }
  }

  void _viewRecords(Map<String, dynamic> appt) {
    final patientName = appt['patientName'] as String? ?? 'Patient';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => _RecordsSheet(
          scrollController: ctrl,
          patientName: patientName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _appts.where((a) => a['status'] == 'pending').length;
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Schedule',
                    style: TextStyle(
                        color: context.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  _loading ? 'Loading…' : '$pending pending approvals',
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.grey,
              onPressed: _load,
            ),
          ]),
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_appts.isEmpty) {
      return const Center(
        child: Text('No appointments yet.', style: TextStyle(color: AppColors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: _appts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final appt = _appts[i];
          return Dismissible(
            key: ValueKey(appt['id']),
            direction: DismissDirection.horizontal,
            background: _swipeBg(Alignment.centerLeft),
            secondaryBackground: _swipeBg(Alignment.centerRight),
            confirmDismiss: (_) => _confirmDelete(),
            onDismissed: (_) => _delete(appt),
            child: _ApptCard(
              data: appt,
              index: i,
              onAccept: () => _accept(i),
              onReject: () => _reject(i),
              onChat: () => _chatWithPatient(appt),
              onRecords: () => _viewRecords(appt),
            ),
          );
        },
      ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _ApptCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onReject, onChat, onRecords;
  final int index;

  const _ApptCard({
    required this.data,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
    required this.onRecords,
    required this.index,
  });

  @override
  State<_ApptCard> createState() => _ApptCardState();
}

class _ApptCardState extends State<_ApptCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  bool get _ended => widget.data['endedAt'] != null;
  String get _displayStatus =>
      _ended ? 'ended' : (widget.data['status'] as String? ?? 'pending');

  Color get _statusColor {
    if (_ended) return AppColors.grey;
    switch (widget.data['status']) {
      case 'confirmed': return Colors.green;
      case 'rejected':  return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData get _statusIcon {
    if (_ended) return Icons.do_not_disturb_on_outlined;
    switch (widget.data['status']) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'rejected':  return Icons.cancel_rounded;
      default:          return Icons.schedule_rounded;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] as String? ?? 'pending';
    final name = widget.data['patientName'] as String?
        ?? widget.data['name'] as String?
        ?? 'Patient';
    final avatar = widget.data['avatar'] as String? ?? _initials(name);
    final time = widget.data['time'] as String? ?? '';
    final type = widget.data['type'] as String? ?? '';
    final isPending = status == 'pending' && !_ended;
    final isConfirmed = status == 'confirmed' && !_ended;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.97),
          onTapUp: (_) => setState(() => _scale = 1),
          onTapCancel: () => setState(() => _scale = 1),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor.withOpacity(0.25), width: 1),
                boxShadow: context.isDark ? null : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Patient row ──────────────────────────────
                Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: RoleTheme.doctor.withOpacity(0.12),
                    child: Text(avatar,
                        style: const TextStyle(
                            color: RoleTheme.doctor, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          style: TextStyle(
                              color: context.text, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(
                        [if (time.isNotEmpty) time, if (type.isNotEmpty) type].join('  ·  '),
                        style: const TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ]),
                  ),
                  // ── Status badge ──────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon, color: _statusColor, size: 12),
                      const SizedBox(width: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                            color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                        child: Text(_displayStatus),
                      ),
                    ]),
                  ),
                ]),

                // ── Action buttons ───────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: isPending
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(children: [
                            Expanded(child: _TapBtn(
                              label: 'Reject',
                              color: Colors.red,
                              outlined: true,
                              onTap: widget.onReject,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _TapBtn(
                              label: 'Accept',
                              color: RoleTheme.doctor,
                              outlined: false,
                              onTap: widget.onAccept,
                            )),
                          ]),
                        )
                      : isConfirmed
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(children: [
                                Expanded(child: _TapBtn(
                                  label: 'View Records',
                                  icon: Icons.folder_outlined,
                                  color: RoleTheme.doctor,
                                  outlined: true,
                                  onTap: widget.onRecords,
                                )),
                                const SizedBox(width: 10),
                                Expanded(child: _TapBtn(
                                  label: 'Chat Now',
                                  icon: Icons.chat_bubble_outline_rounded,
                                  color: RoleTheme.doctor,
                                  outlined: false,
                                  onTap: widget.onChat,
                                )),
                              ]),
                            )
                          : const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tap button ────────────────────────────────────────────────────────────────

class _TapBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  final IconData? icon;

  const _TapBtn({
    required this.label,
    required this.color,
    required this.outlined,
    required this.onTap,
    this.icon,
  });

  @override
  State<_TapBtn> createState() => _TapBtnState();
}

class _TapBtnState extends State<_TapBtn> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _scale = 0.94),
    onTapUp: (_) { setState(() => _scale = 1); widget.onTap(); },
    onTapCancel: () => setState(() => _scale = 1),
    child: AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.outlined ? Colors.transparent : widget.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.color, width: 1.2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.icon != null) ...[
            Icon(widget.icon,
                size: 14,
                color: widget.outlined ? widget.color : Colors.white),
            const SizedBox(width: 5),
          ],
          Text(widget.label,
              style: TextStyle(
                color: widget.outlined ? widget.color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ]),
      ),
    ),
  );
}

// ── Patient records sheet ─────────────────────────────────────────────────────

class _RecordsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String patientName;

  const _RecordsSheet({required this.scrollController, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 12),
      Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: AppColors.grey.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          const Icon(Icons.folder_outlined, color: RoleTheme.doctor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$patientName — Records',
              style: TextStyle(
                  color: context.text, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sampleRecords.length,
          itemBuilder: (_, i) {
            final rec = sampleRecords[i];
            final statusColor = rec.status == RecordStatus.critical ? Colors.red : Colors.green;
            return ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: RoleTheme.doctor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.description_outlined, color: RoleTheme.doctor, size: 20),
              ),
              title: Text(rec.title,
                  style: TextStyle(
                      color: context.text, fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                '${rec.typeLabel}  •  ${rec.date.day}/${rec.date.month}/${rec.date.year}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(rec.statusLabel,
                    style: TextStyle(
                        color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
