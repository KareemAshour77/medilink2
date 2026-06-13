import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// "Professional Account / Verified doctors only" badge shown on the doctor
/// registration steps.
class DoctorProBadge extends StatelessWidget {
  const DoctorProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.14),
            AppColors.primaryDark.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Text('🩺', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional Account',
                style: TextStyle(
                    color: context.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Text('Verified doctors only',
                style: TextStyle(color: AppColors.grey, fontSize: 12.5)),
          ],
        ),
      ]),
    );
  }
}
