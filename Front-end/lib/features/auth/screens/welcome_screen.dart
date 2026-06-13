// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // Soft branded gradient behind the logo — subtle, not overwhelming.
    final heroColors = isDark
        ? [AppColors.primaryDark.withOpacity(0.22), Colors.transparent]
        : [
            AppColors.primary.withOpacity(0.13),
            AppColors.primary.withOpacity(0.02),
          ];

    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          // ── Branded hero with the logo + soft curved bottom ───────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 44,
              bottom: 40,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: heroColors,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
            ),
            child: Center(
              child: SizedBox(
                height: 76,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),

                    // Tagline — primary, prominent
                    Text(
                      context.l.welcomeCompanion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description — secondary
                    Text(
                      context.l.welcomeDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.text.withOpacity(0.55),
                        fontSize: 14,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Trust indicators — sit naturally under the description
                    _TrustRow(),

                    const Spacer(),

                    // Sign Up — primary CTA
                    _PrimaryButton(
                      label: context.l.signUp,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Log In — secondary
                    _OutlineButton(
                      label: context.l.logIn,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trust indicators ─────────────────────────────────────────────────────────

class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark
        ? Colors.white.withOpacity(0.06)
        : AppColors.primary.withOpacity(0.07);
    final color = isDark ? AppColors.primaryDark : AppColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustChip(label: '500+ Doctors', bg: bg, color: color),
        const SizedBox(width: 8),
        _TrustChip(label: '4.9 ★', bg: bg, color: color),
        const SizedBox(width: 8),
        _TrustChip(label: 'Secure', bg: bg, color: color),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String label;
  final Color bg, color;
  const _TrustChip(
      {required this.label, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outline button ────────────────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.primaryDark.withOpacity(0.55)
                : AppColors.primary.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.primaryDark : AppColors.primary,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
