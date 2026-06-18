import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/utils/record_labels.dart';

/// Patient's own appointments — pending / confirmed / rejected, with the
/// requested slot time and doctor info.
class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
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
      final list = await AppointmentService.getMine();
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

  ({Color color, IconData icon, String label}) _statusOf(Map<String, dynamic> a) {
    final l = context.l;
    if (a['endedAt'] != null) {
      return (color: AppColors.grey, icon: Icons.do_not_disturb_on_outlined, label: l.apptEnded);
    }
    switch (a['status']) {
      case 'confirmed':
        return (color: Colors.green, icon: Icons.check_circle_rounded, label: l.apptConfirmed);
      case 'rejected':
        return (color: Colors.red, icon: Icons.cancel_rounded, label: l.apptRejected);
      default:
        return (color: Colors.orange, icon: Icons.schedule_rounded, label: l.apptPending);
    }
  }

  String _formatSchedule(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return 'No time set';
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${wd[d.weekday - 1]} ${d.day} ${mo[d.month - 1]} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.myAppointments, style: TextStyle(color: context.text)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: AppColors.grey)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: Text(context.l.retry)),
        ]),
      );
    }
    if (_appts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 140),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(context.l.noAppointmentsYet,
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey)),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _appts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final a = _appts[i];
          final st = _statusOf(a);
          final doctor = a['doctorName'] as String? ?? 'Doctor';
          final specialty = a['specialty'] as String?;
          final type = a['type'] as String? ?? '';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: st.color.withOpacity(0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.medical_services_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doctor,
                        style: TextStyle(
                            color: context.text, fontWeight: FontWeight.w700, fontSize: 15)),
                    if (specialty != null && specialty.isNotEmpty)
                      Text(specialty, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: st.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(st.icon, color: st.color, size: 12),
                    const SizedBox(width: 4),
                    Text(st.label,
                        style: TextStyle(color: st.color, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.event_outlined, size: 15, color: AppColors.grey),
                const SizedBox(width: 6),
                Text(_formatSchedule(a['scheduledAt']),
                    style: TextStyle(color: context.text.withOpacity(0.8), fontSize: 13)),
                if (type.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Text('·', style: TextStyle(color: AppColors.grey)),
                  const SizedBox(width: 10),
                  Text(apptTypeLabelL10n(context.l, type),
                      style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                ],
              ]),
            ]),
          );
        },
      ),
    );
  }
}
