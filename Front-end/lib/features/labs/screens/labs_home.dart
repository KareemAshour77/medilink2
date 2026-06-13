import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'labs_dashboard.dart';
import 'labs_profile.dart';
// import 'labs_bookings.dart';
// import 'labs_tests.dart';
// import 'labs_upload.dart';

class LabsHome extends StatefulWidget {
  const LabsHome({super.key});
  @override
  State<LabsHome> createState() => _LabsHomeState();
}

class _LabsHomeState extends State<LabsHome> {
  int _index = 0;
  // Bookings / Tests / Upload aren't built yet — placeholders keep the nav from
  // crashing; Profile is the working account menu.
  final _tabs = const [
    LabsDashboard(),
    _ComingSoon('Bookings'),
    _ComingSoon('Tests'),
    _ComingSoon('Upload'),
    LabsProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: RoleTheme.labs.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: RoleTheme.labs),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_online_outlined),
            selectedIcon: Icon(Icons.book_online, color: RoleTheme.labs),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science, color: RoleTheme.labs),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file, color: RoleTheme.labs),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: RoleTheme.labs),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon(this.title);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text('$title — coming soon',
                style: const TextStyle(color: AppColors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}