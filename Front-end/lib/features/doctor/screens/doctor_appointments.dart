import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/services/chat_api_service.dart';
import '../../../core/services/record_access_service.dart';
import '../../../core/services/records_service.dart';
import '../../../core/utils/record_labels.dart';
import 'doctor_chat_screen.dart';
import 'record_details_sheet.dart';
import '../../patient/screens/add_record_screen.dart';

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

  Future<void> _accept(Map<String, dynamic> appt) async {
    final id = appt['id'] as String? ?? '';
    setState(() => appt['status'] = 'confirmed');
    try {
      await AppointmentService.accept(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => appt['status'] = 'pending');
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Accept failed: $msg');
      // If the appointment no longer exists on the server, reload to drop stale rows.
      if (msg.contains('not found') || msg == '404') _load();
    }
  }

  Future<void> _reject(Map<String, dynamic> appt) async {
    final id = appt['id'] as String? ?? '';
    setState(() => appt['status'] = 'rejected');
    try {
      await AppointmentService.reject(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => appt['status'] = 'pending');
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.show(context, 'Reject failed: $msg');
      if (msg.contains('not found') || msg == '404') _load();
    }
  }

  // ── Schedule filter ────────────────────────────────────────────────────────
  String _filter = 'All';
  static const _filters = ['All', 'Today', 'Pending', 'Confirmed'];

  bool _isToday(Map<String, dynamic> a) {
    final raw = a['scheduledAt'] ?? a['createdAt'];
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return false;
    final now = DateTime.now();
    final local = d.toLocal();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }

  List<Map<String, dynamic>> get _visible {
    switch (_filter) {
      case 'Today':
        return _appts.where(_isToday).toList();
      case 'Pending':
        return _appts.where((a) => a['status'] == 'pending' && a['endedAt'] == null).toList();
      case 'Confirmed':
        return _appts.where((a) => a['status'] == 'confirmed' && a['endedAt'] == null).toList();
      default:
        return _appts;
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

  // Gated by the 15-minute medical-record access flow: the doctor only sees
  // records once the patient has approved a live access request.
  Future<void> _viewRecords(Map<String, dynamic> appt) async {
    final patientId = appt['patientId'] as String? ?? '';
    final patientName = appt['patientName'] as String? ?? 'Patient';
    if (patientId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final granted = await RecordAccessService.check(patientId);
      if (!granted) {
        await RecordAccessService.request(patientId);
        if (!mounted) return;
        Navigator.pop(context); // loader
        _showAccessPending(appt);
        return;
      }
      final entries = await RecordsService.forPatient(patientId);
      if (!mounted) return;
      Navigator.pop(context); // loader
      _showRecordsSheet(patientName, entries);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loader
      AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showAccessPending(Map<String, dynamic> appt) {
    final l = context.l;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.accessRequestSent),
        content: Text(l.waitingPatientApproval),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.ok),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _viewRecords(appt);
            },
            child: Text(l.viewRecords),
          ),
        ],
      ),
    );
  }

  void _showRecordsSheet(String patientName, List<Map<String, dynamic>> entries) {
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
          entries: entries,
        ),
      ),
    );
  }

  Future<void> _createPrescription(Map<String, dynamic> appt) async {
    final patientId = appt['patientId'] as String? ?? '';
    final patientName = appt['patientName'] as String? ?? 'Patient';
    if (patientId.isEmpty) return;
    // Reuse the patient Add-Record UI, locked to Prescription. Saves through the
    // unified records system so it appears in the patient's medical records.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          prescriptionOnly: true,
          patientId: patientId,
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
                Text(context.l.schedule,
                    style: TextStyle(
                        color: context.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  _loading
                      ? context.l.loadingDots
                      : '$pending ${context.l.pendingApprovals}',
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
        if (!_loading && _error == null && _appts.isNotEmpty) _buildFilterChips(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  String _filterLabel(BuildContext context, String f) {
    final l = context.l;
    switch (f) {
      case 'Today':     return l.filterToday;
      case 'Pending':   return l.apptPending;
      case 'Confirmed': return l.apptConfirmed;
      default:          return l.filterAll;
    }
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? RoleTheme.doctor : context.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? RoleTheme.doctor : context.divider),
              ),
              child: Text(_filterLabel(context, f),
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.grey,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  )),
            ),
          );
        },
      ),
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
      return Center(
        child: Text(context.l.noAppointmentsYet, style: const TextStyle(color: AppColors.grey)),
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 120),
          Center(
            child: Text(context.l.noAppointmentsYet,
                style: const TextStyle(color: AppColors.grey)),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final appt = visible[i];
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
              onAccept: () => _accept(appt),
              onReject: () => _reject(appt),
              onChat: () => _chatWithPatient(appt),
              onRecords: () => _viewRecords(appt),
              onPrescribe: () => _createPrescription(appt),
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
  final VoidCallback onAccept, onReject, onChat, onRecords, onPrescribe;
  final int index;

  const _ApptCard({
    required this.data,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
    required this.onRecords,
    required this.onPrescribe,
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

  // 'Mon 17 Jun · 14:30' from an ISO scheduledAt, or '' if not scheduled.
  String _formatSchedule(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${wd[d.weekday - 1]} ${d.day} ${mo[d.month - 1]} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] as String? ?? 'pending';
    final name = widget.data['patientName'] as String?
        ?? widget.data['name'] as String?
        ?? 'Patient';
    final avatar = widget.data['avatar'] as String? ?? _initials(name);
    final time = _formatSchedule(widget.data['scheduledAt']);
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
                        [
                          if (time.isNotEmpty) time,
                          if (type.isNotEmpty) apptTypeLabelL10n(context.l, type),
                        ].join('  ·  '),
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
                        child: Text(apptStatusLabelL10n(context.l, _displayStatus)),
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
                              label: context.l.reject,
                              color: Colors.red,
                              outlined: true,
                              onTap: widget.onReject,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _TapBtn(
                              label: context.l.approve,
                              color: RoleTheme.doctor,
                              outlined: false,
                              onTap: widget.onAccept,
                            )),
                          ]),
                        )
                      : isConfirmed
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(child: _TapBtn(
                                    label: context.l.viewRecords,
                                    icon: Icons.folder_outlined,
                                    color: RoleTheme.doctor,
                                    outlined: true,
                                    onTap: widget.onRecords,
                                  )),
                                  const SizedBox(width: 10),
                                  Expanded(child: _TapBtn(
                                    label: context.l.btnChatNow,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    color: RoleTheme.doctor,
                                    outlined: false,
                                    onTap: widget.onChat,
                                  )),
                                ]),
                                const SizedBox(height: 10),
                                _TapBtn(
                                  label: context.l.createPrescription,
                                  icon: Icons.receipt_long_outlined,
                                  color: RoleTheme.doctor,
                                  outlined: true,
                                  onTap: widget.onPrescribe,
                                ),
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
  final List<Map<String, dynamic>> entries;

  const _RecordsSheet({
    required this.scrollController,
    required this.patientName,
    required this.entries,
  });

  String _fmtDate(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'prescription': return Icons.receipt_long_outlined;
      case 'lab_test':     return Icons.biotech_outlined;
      case 'imaging':      return Icons.document_scanner_outlined;
      case 'diagnosis':    return Icons.medical_information_outlined;
      default:             return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
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
              '$patientName — ${l.records}',
              style: TextStyle(
                  color: context.text, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.noRecordsForPatient,
                      style: const TextStyle(color: AppColors.grey)),
                ),
              )
            : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                itemBuilder: (_, i) => _tile(context, entries[i]),
              ),
      ),
    ]);
  }

  Widget _tile(BuildContext context, Map<String, dynamic> rec) {
    final l = context.l;
    final type = rec['type'] as String? ?? '';
    final isRx = type == 'prescription';
    final status = rec['status'] as String? ?? '';
    final items = (rec['items'] as List?) ?? const [];
    final title = isRx && items.isNotEmpty
        ? '${rec['title'] ?? l.recordTypePrescription} (${items.length})'
        : (rec['title'] as String? ?? l.recordDetails);
    return ListTile(
      onTap: () => showRecordDetailsSheet(context, rec),
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: RoleTheme.doctor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(_iconFor(type), color: RoleTheme.doctor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        '${recordTypeLabelL10n(l, type)}  •  ${_fmtDate(rec['record_date'] ?? rec['created_at'])}',
        style: const TextStyle(color: AppColors.grey, fontSize: 12),
      ),
      // Prescription status is READ-ONLY for the doctor (only the patient edits it).
      trailing: isRx && status.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RoleTheme.doctor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rxStatusLabelL10n(l, status),
                style: const TextStyle(
                    color: RoleTheme.doctor, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}
