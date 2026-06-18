import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/utils/record_labels.dart';

/// Doctor dashboard — fully dynamic. All counts and the upcoming list are
/// derived from the doctor's real appointments (GET /appointments).
class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
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
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  bool _isToday(Map<String, dynamic> a) {
    final d = DateTime.tryParse(a['scheduledAt']?.toString() ?? '')?.toLocal();
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  // ── Derived counts ──────────────────────────────────────────────────────────
  int get _todayCount =>
      _appts.where((a) => _isToday(a) && a['status'] != 'rejected').length;
  int get _pendingCount =>
      _appts.where((a) => a['status'] == 'pending').length;
  int get _confirmedCount =>
      _appts.where((a) => a['status'] == 'confirmed' && a['endedAt'] == null).length;

  // Upcoming = pending/confirmed (not ended), soonest first. Undated rows last.
  List<Map<String, dynamic>> get _upcoming {
    final list = _appts.where((a) {
      final s = a['status'];
      return (s == 'pending' || s == 'confirmed') && a['endedAt'] == null;
    }).toList();
    DateTime key(Map<String, dynamic> a) =>
        DateTime.tryParse(a['scheduledAt']?.toString() ?? '') ??
        DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => key(a).compareTo(key(b)));
    return list.take(8).toList();
  }

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    if (h < 12) return context.l.goodMorning;
    if (h < 17) return context.l.goodAfternoon;
    return context.l.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final user = SessionService.currentUser;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _Header(name: user?.name ?? l.drPrefix, greeting: _greeting(context)),
            const SizedBox(height: 24),

            // ── Stats (dynamic) ───────────────────────────────────
            Row(children: [
              _StatCard(l.todaysPatients, '${_loading ? '—' : _todayCount}',
                  Icons.people_alt_rounded, RoleTheme.doctor),
              const SizedBox(width: 10),
              _StatCard(l.apptPending, '${_loading ? '—' : _pendingCount}',
                  Icons.pending_actions_rounded, Colors.orange),
              const SizedBox(width: 10),
              _StatCard(l.apptConfirmed, '${_loading ? '—' : _confirmedCount}',
                  Icons.check_circle_outline_rounded, Colors.green),
            ]),
            const SizedBox(height: 28),

            // ── Upcoming appointments (dynamic) ───────────────────
            Text('📅 ${l.upcomingAppointments}',
                style: TextStyle(color: context.text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildUpcoming(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcoming(BuildContext context) {
    final l = context.l;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(children: [
          Text(l.couldNotLoadData,
              style: const TextStyle(color: AppColors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          TextButton(onPressed: _load, child: Text(l.retry)),
        ]),
      );
    }
    final upcoming = _upcoming;
    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(l.noUpcomingAppointments, style: const TextStyle(color: AppColors.grey)),
        ),
      );
    }
    return Column(children: upcoming.map((a) => _DashApptTile(a)).toList());
  }
}

// ── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String name, greeting;
  const _Header({required this.name, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          const SizedBox(height: 2),
          Text('${context.l.drPrefix} $name',
              style: TextStyle(
                  color: context.text, fontSize: 24, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ]),
      ),
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: RoleTheme.doctor.withOpacity(0.13),
          border: Border.all(color: RoleTheme.doctor.withOpacity(0.3), width: 1.5),
        ),
        child: const Icon(Icons.person_rounded, color: RoleTheme.doctor, size: 24),
      ),
    ]);
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(context.isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ── Appointment tile (dynamic) ─────────────────────────────────────────────
class _DashApptTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DashApptTile(this.data);

  String _formatTime(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${wd[d.weekday - 1]} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final status = data['status'] as String? ?? 'pending';
    final confirmed = status == 'confirmed';
    final statusColor = confirmed ? Colors.green : Colors.orange;
    final name = data['patientName'] as String? ?? 'Patient';
    final time = _formatTime(data['scheduledAt']);
    final type = apptTypeLabelL10n(l, data['type'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider, width: 0.5),
        boxShadow: context.isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: RoleTheme.doctor.withOpacity(0.12),
          child: const Icon(Icons.person_rounded, color: RoleTheme.doctor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 3),
          Text([
            if (time.isNotEmpty) time,
            if (type.isNotEmpty) type,
          ].join('  ·  '),
              style: const TextStyle(color: AppColors.grey, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(apptStatusLabelL10n(l, status),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
