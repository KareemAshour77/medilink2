import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'labs_dashboard.dart';
// import 'labs_bookings.dart';
// import 'labs_tests.dart';
// import 'labs_upload.dart';
// import 'labs_profile.dart';

class LabsHome extends StatefulWidget {
  const LabsHome({super.key});
  @override
  State<LabsHome> createState() => _LabsHomeState();
}

class _LabsHomeState extends State<LabsHome> {
  int _index = 0;
  final _tabs = const [
    LabsDashboard(),
   // LabsBookings(),
  //LabsTests(),
  //LabsUpload(),
  //LabsProfile(),
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