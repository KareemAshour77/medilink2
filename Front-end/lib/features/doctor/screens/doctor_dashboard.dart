import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const _itemCount = 6;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _itemCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );
    _fades = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slides = _controllers
        .map((c) => Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    // Staggered launch
    for (var i = 0; i < _itemCount; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 90), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──────────────────────────────────────────────
          _animated(0, _Header(name: user?.name ?? 'Doctor', greeting: greeting)),
          const SizedBox(height: 24),

          // ── Stats ───────────────────────────────────────────────
          _animated(1, const _StatsRow()),
          const SizedBox(height: 28),

          // ── Urgent Cases ────────────────────────────────────────
          _animated(2, _SectionTitle('🚨 Urgent Cases',
              badge: '2', badgeColor: Colors.red)),
          const SizedBox(height: 12),
          _animated(3, const _UrgentList()),
          const SizedBox(height: 28),

          // ── Upcoming Appointments ───────────────────────────────
          _animated(4, _SectionTitle('📅 Upcoming Appointments')),
          const SizedBox(height: 12),
          _animated(5, const _AppointmentList()),
        ]),
      ),
    );
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
          Text('Dr. $name',
              style: TextStyle(
                  color: context.text, fontSize: 24, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ]),
      ),
      Stack(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: RoleTheme.doctor.withOpacity(0.13),
            border: Border.all(color: RoleTheme.doctor.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.person_rounded, color: RoleTheme.doctor, size: 24),
        ),
        Positioned(
          top: 0, right: 0,
          child: _PulseDot(color: Colors.red),
        ),
      ]),
      const SizedBox(width: 10),
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.card,
          border: Border.all(color: context.divider),
        ),
        child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.grey),
      ),
    ]);
  }
}

// ── Pulse dot for urgent notification ─────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.3)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: widget.color, shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    ),
  );
}

// ── Stats row ──────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatCard("Today's Patients", '12', Icons.people_alt_rounded, RoleTheme.doctor),
      const SizedBox(width: 10),
      _StatCard('Pending', '4', Icons.pending_actions_rounded, Colors.orange),
      const SizedBox(width: 10),
      _StatCard('Urgent', '2', Icons.warning_amber_rounded, Colors.red),
    ]);
  }
}

class _StatCard extends StatefulWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(context.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(_scale < 1 ? 0.4 : 0.2)),
              boxShadow: _scale < 1 ? [] : [
                BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(height: 10),
              Text(widget.value,
                  style: TextStyle(color: widget.color, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(widget.label,
                  style: const TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;
  const _SectionTitle(this.title, {this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(title,
            style: TextStyle(
                color: context.text, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      if (badge != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (badgeColor ?? RoleTheme.doctor).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(badge!,
              style: TextStyle(
                  color: badgeColor ?? RoleTheme.doctor,
                  fontSize: 11, fontWeight: FontWeight.w700)),
        ),
    ]);
  }
}

// ── Urgent cases ──────────────────────────────────────────────────────────
class _UrgentList extends StatelessWidget {
  const _UrgentList();

  static const _cases = [
    {'name': 'Mona Ali',       'issue': 'Chest pain — needs immediate attention', 'age': '52'},
    {'name': 'Karim Youssef',  'issue': 'Severe allergic reaction, Epipen given',  'age': '31'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _cases.map((c) => _UrgentCard(c)).toList(),
    );
  }
}

class _UrgentCard extends StatefulWidget {
  final Map<String, String> data;
  const _UrgentCard(this.data);
  @override
  State<_UrgentCard> createState() => _UrgentCardState();
}

class _UrgentCardState extends State<_UrgentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _border;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _border = Tween<double>(begin: 0.2, end: 0.6)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: AnimatedBuilder(
          animation: _border,
          builder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(context.isDark ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(_border.value), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.06 * _border.value * 3),
                  blurRadius: 12,
                )
              ],
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.15),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.data['name']!,
                    style: TextStyle(color: context.text, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(widget.data['issue']!,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    maxLines: 2),
              ])),
              const SizedBox(width: 8),
              Column(children: [
                _ActionBtn(Icons.call_rounded, Colors.green, () {}),
                const SizedBox(height: 6),
                _ActionBtn(Icons.chat_rounded, RoleTheme.doctor, () {}),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 17),
    ),
  );
}

// ── Appointment list ──────────────────────────────────────────────────────
class _AppointmentList extends StatelessWidget {
  const _AppointmentList();

  static const _appts = [
    {'name': 'Ahmed Hassan',  'time': '10:00 AM', 'type': 'Consultation', 'status': 'confirmed'},
    {'name': 'Sara Mohamed',  'time': '11:30 AM', 'type': 'Follow-up',    'status': 'pending'},
    {'name': 'Omar Khaled',   'time': '02:00 PM', 'type': 'Check-up',     'status': 'confirmed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _appts.map((a) => _DashApptTile(a)).toList(),
    );
  }
}

class _DashApptTile extends StatefulWidget {
  final Map<String, String> data;
  const _DashApptTile(this.data);
  @override
  State<_DashApptTile> createState() => _DashApptTileState();
}

class _DashApptTileState extends State<_DashApptTile> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final confirmed = widget.data['status'] == 'confirmed';
    final statusColor = confirmed ? Colors.green : Colors.orange;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: Container(
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
              Text(widget.data['name']!,
                  style: TextStyle(color: context.text, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 3),
              Text('${widget.data['time']}  ·  ${widget.data['type']}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(widget.data['status']!,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}
