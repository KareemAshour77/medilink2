import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PharmacyInventory extends StatelessWidget {
  const PharmacyInventory({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Inventory', style: TextStyle(color: context.text,
            fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Center(child: Text('Inventory management coming soon',
            style: TextStyle(color: AppColors.grey))),
      ]),
    ),
  );
}