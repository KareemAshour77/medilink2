// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.themes,
          style: TextStyle(color: context.text, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.chooseTheme,
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Preview cards row
                Row(
                  children: [
                    _ThemePreviewCard(
                      label: l.lightTheme,
                      icon: Icons.wb_sunny_outlined,
                      accentColor: const Color(0xFFFF9800),
                      isLight: true,
                      isSelected: currentMode == ThemeMode.light,
                      onTap: () {
                        themeNotifier.value = ThemeMode.light;
                      },
                    ),
                    const SizedBox(width: 14),
                    _ThemePreviewCard(
                      label: l.darkTheme,
                      icon: Icons.nightlight_round,
                      accentColor: const Color(0xFF90CAF9),
                      isLight: false,
                      isSelected: currentMode == ThemeMode.dark,
                      onTap: () {
                        themeNotifier.value = ThemeMode.dark;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // System default option
                _SystemThemeTile(
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () {
                    themeNotifier.value = ThemeMode.system;
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Preview card (Light / Dark) ───────────────────────────────────────────────
class _ThemePreviewCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isLight;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isLight,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isLight ? const Color(0xFFF5F5F5) : const Color(0xFF1E1E2E);
    final mockText = isLight ? const Color(0xFF212121) : const Color(0xFFE0E0E0);
    final mockSub = isLight ? const Color(0xFF757575) : const Color(0xFF9E9E9E);
    final mockCard = isLight ? Colors.white : const Color(0xFF2A2A3E);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.bop: Colors.transparent,
              width: 2.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mini UI preview
                Container(
                  height: 140,
                  color: cardBg,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fake top bar
                      Row(children: [
                        Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: accentColor, size: 14)),
                        const SizedBox(width: 8),
                        Container(width: 60, height: 9,
                            decoration: BoxDecoration(
                              color: mockText.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            )),
                      ]),
                      const SizedBox(height: 12),
                      // Fake card
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: mockCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              )),
                          const SizedBox(width: 8),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 55, height: 8,
                                decoration: BoxDecoration(
                                  color: mockText.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                )),
                            const SizedBox(height: 4),
                            Container(width: 40, height: 6,
                                decoration: BoxDecoration(
                                  color: mockSub.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                )),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      // Fake button
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Label row
                Container(
                  color: context.card,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              color: context.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.grey,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                          : null,
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── System default tile ───────────────────────────────────────────────────────
class _SystemThemeTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _SystemThemeTile({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.brightness_auto_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.systemDefault,
                  style: TextStyle(
                      color: context.text, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(l.followsDeviceSetting,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }
}
