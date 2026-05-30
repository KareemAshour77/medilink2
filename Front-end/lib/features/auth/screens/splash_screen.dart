import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_theme.dart';
import '../screens/onboarding_screen.dart';
import 'package:medilink/core/services/session_service.dart';
import 'package:medilink/core/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      if (SessionService.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 980,
                height: 320,
                child: Image.asset(
                  'assets/images/logo.png',
                ),
              ),
              Text(
                'Your Link to Doctors',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
