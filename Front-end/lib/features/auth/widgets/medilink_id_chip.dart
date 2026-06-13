import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../model/user_model.dart';

/// Role-adaptive label for the public account ID ("Patient ID", "Doctor ID"…).
String roleIdLabel(UserRole role) {
  switch (role) {
    case UserRole.doctor:
      return 'Doctor ID';
    case UserRole.pharmacy:
      return 'Pharmacy ID';
    case UserRole.labs:
      return 'Lab ID';
    case UserRole.patient:
      return 'Patient ID';
  }
}

/// Read-only pill showing the 7-digit MediLink ID on a colored card header.
/// Tap to copy. The value can never be edited by the user.
class MedilinkIdChip extends StatelessWidget {
  final String label;
  final String id;

  const MedilinkIdChip({super.key, required this.label, required this.id});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: id));
        final role = SessionService.currentUser?.role ?? UserRole.patient;
        AppSnackBar.show(context, '$label copied: $id',
            backgroundColor: RoleTheme().forRole(role));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text('$label · $id',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
            const SizedBox(width: 6),
            const Icon(Icons.copy_rounded, color: Colors.white70, size: 13),
          ],
        ),
      ),
    );
  }
}
