// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'theme_setup_screen.dart';

/// First-run step 1: choose the app language. Applies immediately and persists,
/// then continues to the theme setup screen.
class LanguageSetupScreen extends StatefulWidget {
  const LanguageSetupScreen({super.key});

  @override
  State<LanguageSetupScreen> createState() => _LanguageSetupScreenState();
}

class _LanguageSetupScreenState extends State<LanguageSetupScreen> {
  static const _languages = [
    _Lang('en', 'English', 'English', '🇺🇸'),
    _Lang('ar', 'Arabic', 'العربية', '🇸🇦'),
    _Lang('fr', 'French', 'Français', '🇫🇷'),
    _Lang('de', 'German', 'Deutsch', '🇩🇪'),
    _Lang('es', 'Spanish', 'Español', '🇪🇸'),
    _Lang('ru', 'Russian', 'Русский', '🇷🇺'),
    _Lang('tr', 'Turkish', 'Türkçe', '🇹🇷'),
  ];

  late String _selected = langNotifier.value.languageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                child: const Icon(Icons.language_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 18),
              Text('Choose your language',
                  style: TextStyle(
                      color: context.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('You can change this anytime in the menu.',
                  style: TextStyle(color: AppColors.grey, fontSize: 14)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _languages.length,
                  itemBuilder: (_, i) {
                    final lang = _languages[i];
                    return _FlagTile(
                      lang: lang,
                      selected: _selected == lang.code,
                      onTap: () {
                        setState(() => _selected = lang.code);
                        setLocale(lang.code);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ThemeSetupScreen()),
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

class _FlagTile extends StatelessWidget {
  final _Lang lang;
  final bool selected;
  final VoidCallback onTap;
  const _FlagTile(
      {required this.lang, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.card,
              border: Border.all(
                color: selected ? AppColors.primary : context.divider,
                width: selected ? 2.5 : 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 12)
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(lang.flag, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 8),
          Text(
            lang.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.primary : context.text,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Lang {
  final String code, label, nativeLabel, flag;
  const _Lang(this.code, this.label, this.nativeLabel, this.flag);
}
