import 'package:flutter/material.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_theme.dart';

/// Thin banner shown at the top of the doctor area while the account is awaiting
/// admin verification (verification_status == 'pending'). Hidden otherwise.
/// Rebuilds automatically when the session user changes.
class VerificationPendingBanner extends StatelessWidget {
  const VerificationPendingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessionService.userNotifier,
      builder: (context, _) {
        final user = SessionService.currentUser;
        if (user == null || !user.isPendingDoctor) {
          return const SizedBox.shrink();
        }
        return Material(
          color: AppColors.warning.withOpacity(0.12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verification pending',
                            style: TextStyle(
                                color: context.text,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        const Text(
                          'Your documents are under review. Some features are limited until approved.',
                          style:
                              TextStyle(color: AppColors.grey, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
