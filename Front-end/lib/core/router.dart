import 'package:flutter/material.dart';
import '../features/auth/model/user_model.dart';
import 'package:medilink/core/services/session_service.dart';
import 'package:medilink/features/patient/screens/home_screen.dart';
import 'package:medilink/features/doctor/screens/doctor_home.dart';
import 'package:medilink/features/pharmacy/screens/pharmacy_home.dart';
import 'package:medilink/features/labs/screens/labs_home.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionService.currentUser;
    if (user == null) return const HomeScreen();

    switch (user.role) {
      case UserRole.doctor:   return const DoctorHome();
      case UserRole.pharmacy: return const PharmacyHome();
      case UserRole.labs:     return const LabsHome();
      default:                return const HomeScreen();
    }
  }
}