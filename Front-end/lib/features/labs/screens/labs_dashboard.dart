import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';

class LabsDashboard extends StatelessWidget {
  const LabsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;
    const color = RoleTheme.labs;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good day 👋',
              style: TextStyle(color: AppColors.grey, fontSize: 14)),
          Text(user?.name ?? 'Lab Center',
              style: TextStyle(color: context.text, fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Row(children: [
            _StatCard('Today Bookings', '21',  Icons.book_online,    color),
            const SizedBox(width: 12),
            _StatCard('Pending Results', '6', Icons.hourglass_empty, Colors.orange),
            const SizedBox(width: 12),
            _StatCard('Completed',      '15', Icons.check_circle,    Colors.green),
          ]),
          const SizedBox(height: 24),

          Text('Pending Results',
              style: TextStyle(color: context.text, fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._pending.map((p) => _resultTile(p, color, context)),
        ]),
      ),
    );
  }

  static const _pending = [
    {'name': 'Ahmed Hassan', 'test': 'CBC + Blood Sugar', 'time': '10:00 AM'},
    {'name': 'Sara Mohamed', 'test': 'MRI Brain',         'time': '11:30 AM'},
    {'name': 'Omar Khaled',  'test': 'X-Ray Chest',       'time': '01:00 PM'},
  ];
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(
            color: AppColors.grey, fontSize: 10)),
      ]),
    ),
  );
}

Widget _resultTile(Map<String, String> p, Color color, BuildContext context) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: context.isDark ? Border.all(color: context.divider) : null,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.science_outlined, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(p['name']!, style: TextStyle(
              color: context.text, fontWeight: FontWeight.w600)),
          Text('${p['test']}  •  ${p['time']}',
              style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20)),
          child: const Text('Upload',
              style: TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );