import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'pharmacy_dashboard.dart';
import 'pharmacy_orders.dart';
import 'pharmacy_inventory.dart';
import 'pharmacy_delivery.dart';
import 'pharmacy_profile.dart';

class PharmacyHome extends StatefulWidget {
  const PharmacyHome({super.key});
  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  int _index = 0;
  final _tabs = const [
    PharmacyDashboard(),
    PharmacyOrders(),
    PharmacyInventory(),
    PharmacyDelivery(),
    PharmacyProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: RoleTheme.pharmacy.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: RoleTheme.pharmacy),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: RoleTheme.pharmacy),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: RoleTheme.pharmacy),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            selectedIcon: Icon(Icons.delivery_dining, color: RoleTheme.pharmacy),
            label: 'Delivery',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: RoleTheme.pharmacy),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}