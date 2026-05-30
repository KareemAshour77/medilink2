import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LangToggleButton extends StatelessWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: langNotifier,
      builder: (_, locale, __) => GestureDetector(
        onTap: toggleLang,
child: Container(
  
  margin: locale.languageCode == 'en'
      ? const EdgeInsets.only(right: 10)
      : locale.languageCode == 'ar'
          ? const EdgeInsets.only(left: 10)
          : locale.languageCode == 'fr'
          ? const EdgeInsets.only(right: 10)
          : locale.languageCode == 'de'
          ? const EdgeInsets.only(right: 10)
          : locale.languageCode == 'es'
          ? const EdgeInsets.only(right: 10)
          : locale.languageCode == 'ru'
          ? const EdgeInsets.only(right: 10)
          : const EdgeInsets.only(right: 10),

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.bop.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bop.withOpacity(0.3)),
          ),
child: Text(
  locale.languageCode == 'en'
      ? 'EN'
      : locale.languageCode == 'ar'
          ? 'AR'
          :  locale.languageCode == 'fr'
          ? "FR"
          :  locale.languageCode == 'de'
          ? "DE"
          :  locale.languageCode == 'es'
          ? "ES"
          : locale.languageCode == 'ru'
          ? "RU"
          : "tr",
  style: const TextStyle(
    color: AppColors.bop,
    fontWeight: FontWeight.bold,
    fontSize: 15,
  ),
),
        ),
      ),
    );
  }
}
