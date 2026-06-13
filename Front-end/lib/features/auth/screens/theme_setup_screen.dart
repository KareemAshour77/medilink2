// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'onboarding_screen.dart';

/// First-run step 2: choose the app theme. Applies immediately and persists,
/// then continues to the onboarding screen.
class ThemeSetupScreen extends StatefulWidget {
  const ThemeSetupScreen({super.key});

  @override
  State<ThemeSetupScreen> createState() => _ThemeSetupScreenState();
}

class _ThemeSetupScreenState extends State<ThemeSetupScreen> {
  late ThemeMode _selected = themeNotifier.value;

  static const _options = [
    _ThemeOpt(ThemeMode.light, 'Light', 'Bright and clean',
        Icons.light_mode_rounded),
    _ThemeOpt(ThemeMode.dark, 'Dark', 'Easy on the eyes',
        Icons.dark_mode_rounded),
    _ThemeOpt(ThemeMode.system, 'System', 'Match your device',
        Icons.brightness_auto_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 18),
              Text('Choose your theme',
                  style: TextStyle(
                      color: context.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('You can change this anytime in the menu.',
                  style: TextStyle(color: AppColors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              for (final opt in _options) ...[
                _ThemeCard(
                  opt: opt,
                  selected: _selected == opt.mode,
                  onTap: () {
                    setState(() => _selected = opt.mode);
                    setThemeMode(opt.mode);
                  },
                ),
                const SizedBox(height: 12),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OnboardingScreen()),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final _ThemeOpt opt;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeCard(
      {required this.opt, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : context.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(selected ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(opt.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opt.label,
                    style: TextStyle(
                        color: selected ? AppColors.primary : context.text,
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600)),
                Text(opt.subtitle,
                    style:
                        const TextStyle(color: AppColors.grey, fontSize: 12.5)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.grey,
                  width: 1.5),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }
}

class _ThemeOpt {
  final ThemeMode mode;
  final String label, subtitle;
  final IconData icon;
  const _ThemeOpt(this.mode, this.label, this.subtitle, this.icon);
}
