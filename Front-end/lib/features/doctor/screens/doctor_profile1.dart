// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/screens/profile_edit_screen.dart';
import '../../patient/screens/theme_picker_screen.dart';
import '../../patient/screens/language_picker_screen.dart';
import '../../../core/services/session_service.dart';
import '../../auth/screens/role_chooser_screen.dart';
import '../../auth/widgets/medilink_id_chip.dart';
import 'doctor_location_picker_screen.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Items built here so they update when language changes
    final items = [
      _MenuItem.icon(Icons.location_on_outlined, l.clinicLocation,
          const Color(0xFF4CAF50), ''),
      _MenuItem.icon(Icons.switch_account_rounded, 'Switch account',
          const Color(0xFF159E8C), ''),
      _MenuItem.icon(Icons.person_outline_rounded, l.myProfile,
          const Color(0xFF9C27B0), ''),
      _MenuItem.icon(
          Icons.nightlight_sharp, l.themes, const Color(0xFFFFC857), ''),
      _MenuItem.icon(Icons.language, l.language, const Color(0xFF2F80ED), ''),
      _MenuItem.icon(Icons.notifications_active_outlined, l.notifications,
          const Color.fromARGB(255, 130, 169, 14), ''),
      _MenuItem.icon(
          Icons.help_outline_rounded, l.helpSupport, AppColors.grey, ''),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.menu,
                    style: TextStyle(
                        color: context.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            // Profile card
            AnimatedBuilder(
              animation: SessionService.userNotifier,
              builder: (context, _) {
                final user = SessionService.currentUser;
                final email = user?.email.trim();
                final rawName = user?.name.trim();
                final displayName = (rawName != null && rawName.isNotEmpty)
                    ? rawName
                    : 'Doctor';
                final displayEmail = (email != null && email.isNotEmpty)
                    ? email
                    : 'doctor@example.com';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [RoleTheme.doctor, RoleTheme.doctor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: user?.image != null
                          ? NetworkImage(user!.image!)
                          : null,
                      child: user?.image == null
                          ? const Icon(Icons.person_rounded,
                              color: Colors.white, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(displayEmail,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          if (user?.medilinkId != null) ...[
                            const SizedBox(height: 8),
                            MedilinkIdChip(
                              label: roleIdLabel(user!.role),
                              id: user.medilinkId!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 16),
                  ]),
                );
              },
            ),
            const SizedBox(height: 16),
            // const SizedBox(height: 16),

            // Menu items list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(16),
                  border: context.isDark
                      ? Border.all(color: context.divider)
                      : null,
                  boxShadow: context.isDark
                      ? null
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12)
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: context.divider, height: 1, indent: 58),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: item.color
                                .withOpacity(context.isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: item.imagePath != null
                              ? Image.asset(
                                  item.imagePath!,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                )
                              : Icon(item.icon, color: item.color, size: 20),
                        ),
                        title: Text(item.label,
                            style: TextStyle(
                                color: context.text,
                                fontWeight: FontWeight.w500,
                                fontSize: 15)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: AppColors.grey),
                        onTap: () {
                          if (i == 0) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DoctorLocationPickerScreen()));
                          } else if (i == 1) {
                            // Switch / verify another account on this email
                            openAccountSwitcher(context);
                          } else if (i == 2) {
                            // My Profile
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfileEditScreen()));
                          } else if (i == 3) {
                            // Themes
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ThemePickerScreen()));
                          } else if (i == 4) {
                            // Language
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const LanguagePickerScreen()));
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Logout
            OutlinedButton.icon(
              onPressed: () async {
                await SessionService.clear();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (_) => false,
                );
              },
              icon:
                  const Icon(Icons.logout_rounded, color: Colors.grey, size: 20),
              label: Text(l.logOut,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Colors.grey, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.grey.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData? icon;
  final String? imagePath;
  final String label, action;
  final Color color;
  const _MenuItem.icon(this.icon, this.label, this.color, this.action)
      : imagePath = null;
  const _MenuItem.image(this.imagePath, this.label, this.color, this.action)
      : icon = null;
}
