// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final languages = [
      _LangOption(code: 'en', label: 'English',  nativeLabel: 'English',    flag: '🇺🇸'),
      _LangOption(code: 'ar', label: 'Arabic',   nativeLabel: 'العربية',    flag: '🇸🇦'),
      _LangOption(code: 'fr', label: 'French',   nativeLabel: 'Français',   flag: '🇫🇷'),
      _LangOption(code: 'de', label: 'German',   nativeLabel: 'Deutsch',    flag: '🇩🇪'),
      _LangOption(code: 'es', label: 'Spanish',  nativeLabel: 'Español',    flag: '🇪🇸'),
      _LangOption(code: 'ru', label: 'Russian',  nativeLabel: 'Русский',    flag: '🇷🇺'),
      _LangOption(code: 'tr', label: 'Turkish',  nativeLabel: 'Türkçe',     flag: '🇹🇷'),
    ];

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
          l.language,
          style: TextStyle(color: context.text, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Locale>(
          valueListenable: langNotifier,
          builder: (context, currentLocale, _) {
            return Padding(
              padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.chooseLanguage,
                  style: const TextStyle(color: AppColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                  decoration: BoxDecoration(
                    color: context.card,
                    borderRadius: BorderRadius.circular(16),
                    border: context.isDark ? Border.all(color: context.divider) : null,
                    boxShadow: context.isDark
                        ? null
                        : [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                          )],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: languages.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: context.divider, height: 1, indent: 64),
                      itemBuilder: (_, i) {
                        final lang = languages[i];
                        final isSelected = currentLocale.languageCode == lang.code;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.12)
                                  : context.isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primary.withOpacity(0.4),
                                      width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(lang.flag,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          title: Text(lang.label,
                              style: TextStyle(
                                  color: isSelected ? AppColors.primary : context.text,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 15)),
                          subtitle: Text(lang.nativeLabel,
                              style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.7)
                                      : AppColors.grey,
                                  fontSize: 12)),
                          trailing: AnimatedContainer(
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
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                          onTap: () {
                            langNotifier.value = Locale(lang.code);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),
                ), // Expanded
              ],
            ),
          );
          },
        ),
      ),
    );
  }
}

class _LangOption {
  final String code, label, nativeLabel, flag;
  const _LangOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.flag,
  });
}
