// ─────────────────────────────────────────────────────────────────────────────
// app_config.dart
//
// Single source of truth for backend base URLs and ports.
//
// Two backends:
//   • NestJS REST API  → auth, users, reminders, medical records   (port 5000)
//   • FastAPI AI server → chat, X-ray, brain MRI, prescription,     (port 8000)
//                         and report images served at /static/...
//
// How the correct host is chosen
// ──────────────────────────────
//   APP_ENV=local  → host = localhost   (Flutter Web / Chrome, desktop)
//   APP_ENV=phone  → host = PC_IP        (real Android / iOS device)
//
// If APP_ENV is not passed via --dart-define it is auto-detected:
//   • Flutter Web (Chrome)        → local
//   • Real Android / iOS device   → phone   (PC_IP required)
//   • Anything else               → local   (safe fallback)
//
// Everything can be overridden from the command line without editing code:
//
//   flutter run -d chrome \
//     --dart-define=APP_ENV=local
//
//   flutter run -d <android-device-id> \
//     --dart-define=APP_ENV=phone --dart-define=PC_IP=192.168.1.8
//
//   # Fully explicit override (wins over everything else):
//   flutter run -d chrome \
//     --dart-define=NEST_BASE_URL=http://localhost:5000 \
//     --dart-define=FASTAPI_BASE_URL=http://localhost:8000
//
// Supported dart-define keys:
//   APP_ENV, PC_IP, NEST_PORT, FASTAPI_PORT, NEST_BASE_URL, FASTAPI_BASE_URL
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart' show langNotifier;

class AppConfig {
  AppConfig._();

  // ── Language ───────────────────────────────────────────────────────────────
  // Single source of truth is the global `langNotifier`. The backend only
  // localizes 'en' / 'ar'; other UI locales are sent as-is and the backend
  // normalizes anything non-Arabic to English.

  /// Current app language code, e.g. 'en', 'ar', 'fr'.
  static String get appLang => langNotifier.value.languageCode;

  /// True when the UI language is Arabic.
  static bool get isArabicLang => appLang == 'ar';

  /// Common headers to attach to every API request so the backend can localize
  /// user-facing errors. Sent as a header because a Multer fileFilter cannot
  /// read multipart body fields.
  static Map<String, String> appLangHeaders() => {'app-lang': appLang};

  // ── Raw dart-define inputs ─────────────────────────────────────────────────
  static const String _envDefine =
      String.fromEnvironment('APP_ENV', defaultValue: '');
  static const String _pcIpDefine =
      String.fromEnvironment('PC_IP', defaultValue: '');
  static const String _nestPortDefine =
      String.fromEnvironment('NEST_PORT', defaultValue: '5000');
  static const String _fastApiPortDefine =
      String.fromEnvironment('FASTAPI_PORT', defaultValue: '8000');
  static const String _securityPortDefine =
      String.fromEnvironment('SECURITY_PORT', defaultValue: '8080');
  static const String _nestBaseUrlDefine =
      String.fromEnvironment('NEST_BASE_URL', defaultValue: '');
  static const String _fastApiBaseUrlDefine =
      String.fromEnvironment('FASTAPI_BASE_URL', defaultValue: '');
  static const String _securityBaseUrlDefine =
      String.fromEnvironment('SECURITY_BASE_URL', defaultValue: '');

  // ── Resolved environment ───────────────────────────────────────────────────

  /// 'local' or 'phone'. Explicit APP_ENV wins; otherwise auto-detected.
  static String get appEnv {
    if (_envDefine.isNotEmpty) return _envDefine.toLowerCase();
    if (kIsWeb) return 'local';
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'phone';
    }
    return 'local';
  }

  static bool get isPhone => appEnv == 'phone';

  static String get pcIp => _pcIpDefine.trim();
  static int get nestPort => int.tryParse(_nestPortDefine) ?? 5000;
  static int get fastApiPort => int.tryParse(_fastApiPortDefine) ?? 8000;
  static int get securityPort => int.tryParse(_securityPortDefine) ?? 8080;

  /// The host all default base URLs are built from.
  /// phone → PC_IP, everything else → localhost.
  static String get _host {
    if (isPhone) {
      // On a real device, localhost points at the phone itself, not the PC.
      // PC_IP is required; if missing we fall back to localhost so the app
      // still boots, and a clear warning is printed (see [debugLog]).
      return pcIp.isEmpty ? 'localhost' : pcIp;
    }
    return 'localhost';
  }

  // ── Base URLs ──────────────────────────────────────────────────────────────

  /// NestJS REST API (auth, users, reminders, medical records).
  static String get nestBaseUrl {
    if (_nestBaseUrlDefine.isNotEmpty) {
      return _stripTrailingSlash(_nestBaseUrlDefine);
    }
    return 'http://$_host:$nestPort';
  }

  /// FastAPI AI server (chat, X-ray, brain MRI, prescription, report images).
  static String get fastApiBaseUrl {
    if (_fastApiBaseUrlDefine.isNotEmpty) {
      return _stripTrailingSlash(_fastApiBaseUrlDefine);
    }
    return 'http://$_host:$fastApiPort';
  }

  /// Optional FastAPI security backend (secure auth, access control, emergency
  /// access). Default port 8080. Only used by SecurityApiService.
  static String get securityBaseUrl {
    if (_securityBaseUrlDefine.isNotEmpty) {
      return _stripTrailingSlash(_securityBaseUrlDefine);
    }
    return 'http://$_host:$securityPort';
  }

  // ── URL helpers ────────────────────────────────────────────────────────────

  /// Joins a path onto the Nest base URL.
  static String resolveNestUrl(String path) => _join(nestBaseUrl, path);

  /// Joins a path onto the FastAPI base URL.
  static String resolveFastApiUrl(String path) => _join(fastApiBaseUrl, path);

  /// Converts a (possibly relative) report/static image URL to a full URL.
  ///
  /// Report images are served by FastAPI under `/static/reports/...`.
  ///   • null / empty                 → null
  ///   • starts with http:// https:// → returned unchanged
  ///   • starts with /                → FastAPI base + path
  ///   • otherwise                    → FastAPI base + / + path
  static String? resolveReportImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return _join(fastApiBaseUrl, url);
  }

  static String _join(String base, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final b = _stripTrailingSlash(base);
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  // ── Debug logging (debug builds only, prints once) ─────────────────────────

  static bool _logged = false;

  /// Logs the resolved configuration once, in debug mode only.
  /// Never logs secrets or binary data — base URLs and platform target only.
  static void debugLog() {
    if (!kDebugMode || _logged) return;
    _logged = true;

    final platform = kIsWeb ? 'web (chrome)' : defaultTargetPlatform.name;

    debugPrint('════════════ MediLink AppConfig ════════════');
    debugPrint('APP_ENV          : $appEnv');
    debugPrint('platform target  : $platform');
    debugPrint('PC_IP            : ${pcIp.isEmpty ? '(not set)' : pcIp}');
    debugPrint('Nest base URL    : $nestBaseUrl');
    debugPrint('FastAPI base URL : $fastApiBaseUrl');
    debugPrint('sample report URL: '
        '${resolveReportImageUrl('/static/reports/xray/report.png')}');

    if (isPhone && pcIp.isEmpty && _nestBaseUrlDefine.isEmpty) {
      debugPrint('');
      debugPrint('⚠️  APP_ENV=phone but PC_IP is missing.');
      debugPrint('    A real device cannot reach the PC via "localhost".');
      debugPrint('    Re-run with your PC IP, e.g.:');
      debugPrint('    flutter run -d <device-id> '
          '--dart-define=APP_ENV=phone --dart-define=PC_IP=YOUR_PC_IP');
    }
    debugPrint('═════════════════════════════════════════════');
  }
}
