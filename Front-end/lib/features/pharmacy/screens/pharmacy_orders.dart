import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PharmacyOrders extends StatelessWidget {
  const PharmacyOrders({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Orders', style: TextStyle(color: context.text,
            fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Tab filter
        Row(children: ['All', 'Pending', 'Delivered', 'Cancelled']
            .asMap()
            .entries
            .map((e) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: e.key == 0
                        ? RoleTheme.pharmacy
                        : RoleTheme.pharmacy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          color: e.key == 0
                              ? Colors.white : RoleTheme.pharmacy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ))
            .toList()),
        const SizedBox(height: 20),
        const Center(child: Text('Orders list will go here',
            style: TextStyle(color: AppColors.grey))),
      ]),
    ),
  );
}