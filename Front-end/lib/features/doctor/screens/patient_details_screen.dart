import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PatientDetailsScreen extends StatelessWidget {
  final Map<String, String> patient;
  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────
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
                    tag: 'avatar_${patient['name']}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(patient['avatar'] ?? '??',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(patient['name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('Age ${patient['age']}  ·  ${patient['condition']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ]),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Quick actions
                Row(children: [
                  Expanded(child: _ActionButton(
                    icon: Icons.chat_rounded, label: 'Start Chat',
                    color: RoleTheme.doctor, onTap: () {},
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                    icon: Icons.calendar_today_rounded, label: 'Schedule',
                    color: Colors.orange, onTap: () {},
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                    icon: Icons.call_rounded, label: 'Call',
                    color: Colors.green, onTap: () {},
                  )),
                ]),
                const SizedBox(height: 28),

                // Medical info
                _SectionLabel('Medical Information'),
                const SizedBox(height: 12),
                _InfoCard(children: [
                  _InfoRow('Condition',    patient['condition'] ?? '—'),
                  _InfoRow('Status',       patient['status']    ?? '—'),
                  _InfoRow('Age',          patient['age']       ?? '—'),
                  _InfoRow('Last Visit',   '3 days ago'),
                  _InfoRow('Next Visit',   'Tomorrow, 10:00 AM'),
                ]),
                const SizedBox(height: 24),

                _SectionLabel('Prescriptions'),
                const SizedBox(height: 12),
                _InfoCard(children: [
                  _InfoRow('Metformin 500mg',   '2x daily after meals'),
                  _InfoRow('Lisinopril 10mg',   '1x daily morning'),
                ]),
                const SizedBox(height: 24),

                _SectionLabel('Recent Notes'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RoleTheme.doctor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RoleTheme.doctor.withOpacity(0.15)),
                  ),
                  child: const Text(
                    'Patient reports improved blood pressure readings this week. '
                    'Continue current medication. Follow up in 2 weeks.',
                    style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.6),
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

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _scale = 0.94),
    onTapUp: (_) { setState(() => _scale = 1); widget.onTap(); },
    onTapCancel: () => setState(() => _scale = 1),
    child: AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(widget.icon, color: widget.color, size: 22),
          const SizedBox(height: 4),
          Text(widget.label,
              style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
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
