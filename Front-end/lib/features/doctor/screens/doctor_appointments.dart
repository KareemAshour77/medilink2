import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DoctorAppointments extends StatefulWidget {
  const DoctorAppointments({super.key});
  @override
  State<DoctorAppointments> createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments> {
  final List<Map<String, dynamic>> _appts = [
    {'name': 'Ahmed Hassan',  'time': '10:00 AM', 'type': 'Consultation', 'status': 'pending',   'avatar': 'AH'},
    {'name': 'Sara Mohamed',  'time': '11:30 AM', 'type': 'Follow-up',    'status': 'confirmed', 'avatar': 'SM'},
    {'name': 'Omar Khaled',   'time': '02:00 PM', 'type': 'Check-up',     'status': 'pending',   'avatar': 'OK'},
    {'name': 'Layla Ibrahim', 'time': '03:30 PM', 'type': 'Consultation', 'status': 'confirmed', 'avatar': 'LI'},
    {'name': 'Tarek Mahmoud', 'time': '04:45 PM', 'type': 'Emergency',    'status': 'pending',   'avatar': 'TM'},
  ];

  void _accept(int i) => setState(() => _appts[i]['status'] = 'confirmed');
  void _reject(int i) => setState(() => _appts[i]['status'] = 'rejected');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Schedule',
                style: TextStyle(color: context.text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('${_appts.where((a) => a['status'] == 'pending').length} pending approvals',
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _appts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ApptCard(
              data: _appts[i],
              onAccept: () => _accept(i),
              onReject: () => _reject(i),
              index: i,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ApptCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onReject;
  final int index;
  const _ApptCard({required this.data, required this.onAccept, required this.onReject, required this.index});
  @override
  State<_ApptCard> createState() => _ApptCardState();
}

class _ApptCardState extends State<_ApptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  Color get _statusColor {
    switch (widget.data['status']) {
      case 'confirmed': return Colors.green;
      case 'rejected':  return Colors.red;
      default:          return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (widget.data['status']) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'rejected':  return Icons.cancel_rounded;
      default:          return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] as String;
    final isPending = status == 'pending';

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
                    child: Text(widget.data['avatar'],
                        style: const TextStyle(color: RoleTheme.doctor, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.data['name'],
                        style: TextStyle(color: context.text, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text('${widget.data['time']}  ·  ${widget.data['type']}',
                        style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                  ])),
                  // ── Animated status badge ─────────────────
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
                        style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                        child: Text(status),
                      ),
                    ]),
                  ),
                ]),

                // ── Accept / Reject buttons (only for pending) ──
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

class _TapBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _TapBtn({required this.label, required this.color, required this.outlined, required this.onTap});
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
        child: Text(widget.label,
            style: TextStyle(
              color: widget.outlined ? widget.color : Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600,
            )),
      ),
    ),
  );
}
