// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medilink/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:medilink/core/services/session_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SessionService.clear();
  // await SessionService.save(UserModel(
  //   id: '1',
  //   name: 'Ahmed',
  //   email: 'ahmed@test.com',
  //   role: UserRole.labs, // change to .pharmacy or .labs to test others
  //   token: 'test_token',
  // ));
  await NotificationService.init();
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
