import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/model/user_model.dart';

// Persistence keys for the user's theme + language choice.
const _kThemeKey = 'app_theme_mode';
const _kLocaleKey = 'app_locale';

// ─── Global theme notifier ────────────────────────────────────────────────────
// Every widget that reads this will rebuild automatically when theme changes.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void toggleTheme() {
  setThemeMode(
      themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
}

// Set + persist the theme mode.
Future<void> setThemeMode(ThemeMode mode) async {
  themeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kThemeKey,
    mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.system
            ? 'system'
            : 'light',
  );
}

// ─── Language notifier ────────────────────────────────────────────────────────
final langNotifier = ValueNotifier<Locale>(const Locale('en'));

void toggleLang() {
  final langs = ['ar', 'en', 'fr', 'de', 'es', 'ru', 'tr'];
  int current = langs.indexOf(langNotifier.value.languageCode);

  int next = (current + 1) % langs.length;

  setLocale(langs[next]);
}

// Set + persist the app language.
Future<void> setLocale(String code) async {
  langNotifier.value = Locale(code);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLocaleKey, code);
}

// Load the saved theme + language at startup (call before runApp).
Future<void> loadSavedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_kLocaleKey);
  if (code != null) langNotifier.value = Locale(code);
  final theme = prefs.getString(_kThemeKey);
  if (theme != null) {
    themeNotifier.value = theme == 'dark'
        ? ThemeMode.dark
        : theme == 'system'
            ? ThemeMode.system
            : ThemeMode.light;
  }
}

bool get isArabic => langNotifier.value.languageCode == 'ar';

// ─── Color palette ────────────────────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF164869);
  static const primaryDark = Color(0xFF1A8FB5);
  static const bgLight = Color(0xFFF5F7FA);
  static const bgDark = Color(0xFF000000);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1E2740);
  static const textLight = Color(0xFF1A2035);
  static const textDark = Color(0xFFEEF0F5);
  static const grey = Color(0xFF8A94A6);
  static const dividerLight = Color(0xFFEEF0F3);
  static const dividerDark = Color(0xFF2A3450);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE53935);
  static const purple = Color(0xFF9C27B0);
  static const cyan = Color(0xFF00BCD4);
  static const bop = Color(0xFF2BB5E0);
  static const pharcat = Color(0xFFdb2d39);
  static const pharcatdark = Color(0xFF861820);
  static const labcat = Color(0xFF01a610);
  static const labcatdark = Color(0xFF2E7D32);
  static const scancat = Color(0xFF019395);
  static const scancatdark = Color(0xFF015152);
  static const label = Color(0xFF000000);
}

// ─── Helper: read isDark from context ────────────────────────────────────────
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.bgDark : AppColors.bgLight;
  Color get card => isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get text => isDark ? AppColors.textDark : AppColors.textLight;
  Color get divider => isDark ? AppColors.dividerDark : AppColors.dividerLight;
}

extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
}

// ─── Themes ───────────────────────────────────────────────────────────────────
ThemeData _base(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? const Color.fromARGB(255, 1, 1, 2) : AppColors.bgLight;
  final card = isDark ? AppColors.cardDark : AppColors.cardLight;
  final text = isDark ? AppColors.textDark : AppColors.textLight;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: text),
      titleTextStyle: GoogleFonts.poppins(
          color: text, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    cardColor: card,
    dividerColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.grey, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
  );
}

class RoleTheme {
  static const doctor = Color(0xFF2E7D32); // Green
  static const pharmacy = Color(0xFF6A1B9A); // Purple
  static const labs = Color(0xFFE65100); // Orange
  static const patient = AppColors.primary; // Your existing blue

  Color forRole(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return doctor;
      case UserRole.pharmacy:
        return pharmacy;
      case UserRole.labs:
        return labs;
      default:
        return patient;
    }
  }
}

final lightTheme = _base(Brightness.light);
final darkTheme = _base(Brightness.dark);
