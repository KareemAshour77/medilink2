import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';

class PharmacyDashboard extends StatelessWidget {
  const PharmacyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;
    const color = RoleTheme.pharmacy;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello 👋', style: TextStyle(color: AppColors.grey, fontSize: 14)),
          Text(user?.name ?? 'Pharmacy', style: TextStyle(
              color: context.text, fontSize: 22,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Stats
          Row(children: [
            _StatCard('Today Orders',   '38', Icons.receipt_long,  color),
            const SizedBox(width: 12),
            _StatCard('Pending',        '7',  Icons.pending_actions, Colors.orange),
            const SizedBox(width: 12),
            _StatCard('Revenue',        '₤2.4K', Icons.attach_money, Colors.green),
          ]),
          const SizedBox(height: 24),

          Text('Recent Orders', style: TextStyle(
              color: context.text, fontSize: 16,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._orders.map((o) => _orderTile(o, color, context)),
        ]),
      ),
    );
  }

  static const _orders = [
    {'id': '#ORD-001', 'name': 'Ahmed Hassan',  'items': '3 items', 'status': 'pending'},
    {'id': '#ORD-002', 'name': 'Sara Mohamed',  'items': '1 item',  'status': 'delivered'},
    {'id': '#ORD-003', 'name': 'Omar Khaled',   'items': '5 items', 'status': 'pending'},
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
            color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(
            color: AppColors.grey, fontSize: 10)),
      ]),
    ),
  );
}

Widget _orderTile(Map<String, String> o, Color color, BuildContext context) =>
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
          child: Icon(Icons.receipt_long_outlined, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(o['name']!, style: TextStyle(
              color: context.text, fontWeight: FontWeight.w600)),
          Text('${o['id']}  •  ${o['items']}',
              style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: o['status'] == 'delivered'
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(o['status']!,
              style: TextStyle(
                  color: o['status'] == 'delivered'
                      ? Colors.green : Colors.orange,
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );