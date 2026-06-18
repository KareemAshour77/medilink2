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

/// Doctor's view of a single patient. Everything is loaded from the backend:
/// the patient's appointments with this doctor (filtered from /appointments),
/// chat (server-gated), records (access-gated), and prescription creation.
class PatientDetailsScreen extends StatefulWidget {
  final Map<String, String> patient;
  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  List<Map<String, dynamic>> _appts = [];
  bool _loading = true;
  String? _error;

  String get _patientId => widget.patient['id'] ?? '';
  String get _patientName =>
      (widget.patient['name']?.trim().isNotEmpty == true) ? widget.patient['name']! : 'Patient';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final all = await AppointmentService.getMyAppointments();
      if (!mounted) return;
      setState(() {
        _appts = all.where((a) => a['patientId'] == _patientId).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  DateTime? _at(Map<String, dynamic> a) =>
      DateTime.tryParse(a['scheduledAt']?.toString() ?? '')?.toLocal();

  Map<String, dynamic>? get _lastAppt {
    final now = DateTime.now();
    final past = _appts.where((a) {
      final d = _at(a);
      return d != null && d.isBefore(now);
    }).toList()
      ..sort((a, b) => _at(b)!.compareTo(_at(a)!));
    return past.isNotEmpty ? past.first : null;
  }

  Map<String, dynamic>? get _nextAppt {
    final now = DateTime.now();
    final future = _appts.where((a) {
      final d = _at(a);
      return d != null && d.isAfter(now) && a['status'] != 'rejected';
    }).toList()
      ..sort((a, b) => _at(a)!.compareTo(_at(b)!));
    return future.isNotEmpty ? future.first : null;
  }

  String _fmt(Map<String, dynamic>? a) {
    if (a == null) return '—';
    final d = _at(a);
    if (d == null) return '—';
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${mo[d.month - 1]} · $hh:$mm';
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  Future<void> _chat() async {
    if (_patientId.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final conv = await ChatApiService.getOrCreateConversationWithPatient(_patientId);
      if (!mounted) return;
      Navigator.pop(context); // loader
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DoctorChatScreen(
          conversationId: conv['id'] as String,
          patientId: _patientId,
          patientName: _patientName,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loader
      // Chat is gated server-side; show the localized "after approval" message.
      AppSnackBar.show(context, context.l.chatAfterApproval);
    }
  }

  void _schedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => _ApptsSheet(
          scrollController: ctrl,
          patientName: _patientName,
          appts: _appts,
        ),
      ),
    );
  }

  Future<void> _viewRecords() async {
    if (_patientId.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final granted = await RecordAccessService.check(_patientId);
      if (!granted) {
        await RecordAccessService.request(_patientId);
        if (!mounted) return;
        Navigator.pop(context); // loader
        AppSnackBar.show(context, context.l.waitingPatientApproval);
        return;
      }
      final entries = await RecordsService.forPatient(_patientId);
      if (!mounted) return;
      Navigator.pop(context); // loader
      await showPatientRecordsListSheet(context, _patientName, entries);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loader
      AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _createPrescription() async {
    if (_patientId.isEmpty) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddRecordScreen(
        prescriptionOnly: true,
        patientId: _patientId,
        patientName: _patientName,
      ),
    ));
  }

  String _statusLabel(String? s) {
    final l = context.l;
    return s == 'ended' ? l.apptEnded : l.filterActive;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final condition = widget.patient['condition'] ?? '';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: RoleTheme.doctor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [RoleTheme.doctor, RoleTheme.doctor.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'avatar_${widget.patient['name']}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(widget.patient['avatar'] ?? '??',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_patientName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  if (condition.isNotEmpty)
                    Text(condition,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Quick actions (all wired) ─────────────────────
                Row(children: [
                  Expanded(child: _ActionButton(
                    icon: Icons.chat_rounded, label: l.startChat,
                    color: RoleTheme.doctor, onTap: _chat,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                    icon: Icons.calendar_today_rounded, label: l.schedule,
                    color: Colors.orange, onTap: _schedule,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                    icon: Icons.folder_outlined, label: l.viewRecords,
                    color: Colors.green, onTap: _viewRecords,
                  )),
                ]),
                const SizedBox(height: 24),

                // ── Patient information (dynamic) ─────────────────
                _SectionLabel(l.patientInformation),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Column(children: [
                    Text(l.couldNotLoadData, style: const TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _load, child: Text(l.retry)),
                  ])
                else
                  _InfoCard(children: [
                    _InfoRow(l.conditionLabel, condition.isEmpty ? '—' : condition),
                    _InfoRow(l.status, _statusLabel(widget.patient['status'])),
                    _InfoRow(l.appointmentsLabel, '${_appts.length}'),
                    _InfoRow(l.lastAppointment, _fmt(_lastAppt)),
                    _InfoRow(l.nextAppointment, _fmt(_nextAppt)),
                  ]),
                const SizedBox(height: 24),

                // ── Create prescription ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _createPrescription,
                    icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                    label: Text(l.createPrescription,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoleTheme.doctor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── This patient's appointments sheet ──────────────────────────────────────
class _ApptsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String patientName;
  final List<Map<String, dynamic>> appts;
  const _ApptsSheet({
    required this.scrollController,
    required this.patientName,
    required this.appts,
  });

  String _fmt(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '—';
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${mo[d.month - 1]} · $hh:$mm';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return Colors.green;
      case 'rejected':  return Colors.red;
      default:          return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final sorted = [...appts]..sort((a, b) {
      final da = DateTime.tryParse(a['scheduledAt']?.toString() ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['scheduledAt']?.toString() ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    return Column(children: [
      const SizedBox(height: 12),
      Center(
        child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: RoleTheme.doctor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('$patientName — ${l.appointmentsLabel}',
              style: TextStyle(color: context.text, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: sorted.isEmpty
            ? Center(child: Text(l.noAppointmentsFound, style: const TextStyle(color: AppColors.grey)))
            : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final a = sorted[i];
                  final status = a['status'] as String? ?? 'pending';
                  final ended = a['endedAt'] != null;
                  final sc = ended ? AppColors.grey : _statusColor(status);
                  return ListTile(
                    leading: Icon(Icons.event_outlined, color: sc),
                    title: Text(apptTypeLabelL10n(l, a['type'] as String?),
                        style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(_fmt(a['scheduledAt']),
                        style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(ended ? l.apptEnded : apptStatusLabelL10n(l, status),
                          style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: context.text, fontSize: 15, fontWeight: FontWeight.w700));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divider, width: 0.5),
    ),
    child: Column(
      children: List.generate(children.length, (i) => Column(children: [
        children[i],
        if (i < children.length - 1) Divider(height: 1, color: context.divider),
      ])),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 13))),
      Text(value, style: TextStyle(color: context.text, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}
