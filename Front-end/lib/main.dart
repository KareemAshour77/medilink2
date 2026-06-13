// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medilink/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:medilink/core/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Restore session from SharedPreferences — keeps user logged in across restarts.
  await SessionService.load();
  // Apply the saved theme + language before the first frame.
  await loadSavedPreferences();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  // FcmService.init() registers FCM handlers. Call after NotificationService so the
  // chat channel exists before any incoming push is shown.
  FcmService.instance.init().catchError((_) {});
  // Re-upload FCM token on every startup so the backend always has a fresh token
  // (e.g. after token rotation or a clean reinstall).
  if (SessionService.isLoggedIn) {
    FcmService.instance.uploadToken().catchError((_) {});
  }

  // Recover a pending chat navigation written by the background notification
  // response handler when the user tapped a local notification while the app
  // was terminated (data-only FCM → background isolate showed local notification
  // → user tapped body → handler wrote conversationId to SharedPreferences).
  final prefs = await SharedPreferences.getInstance();
  final pendingConv = prefs.getString('pending_chat_nav');
  if (pendingConv != null && pendingConv.isNotEmpty) {
    PendingNavigation.chatConversationId = pendingConv;
    await prefs.remove('pending_chat_nav');
  }
  FlutterNativeSplash.remove();
  runApp(const MediLinkApp());
}

class MediLinkApp extends StatelessWidget {
  const MediLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: langNotifier,
          builder: (_, locale, __) {
            return MaterialApp(
              title: 'MediLink',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: mode,
              locale: locale,
              supportedLocales: const [
                Locale('en'), // English
                Locale('ar'), // Arabic
                Locale('de'), // German
                Locale('fr'), // French
                Locale('es'), // Spanish
                Locale('ru'), // Russian
                Locale('tr'), // Turkish
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: child!,
                );
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
