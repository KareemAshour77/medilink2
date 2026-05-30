// ignore_for_file: deprecated_member_use, prefer_const_constructors, prefer_const_literals_to_create_immutables
//test
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/api_service.dart';
import '../../patient/screens/home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../model/user_model.dart';
import 'package:medilink/core/services/session_service.dart';
import 'package:medilink/core/services/in_app_notification_store.dart';
import 'package:medilink/core/router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
// Google Sign-In
import 'package:medilink/core/services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false; // separate spinner for the Google button
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _emailError = _emailCtrl.text.trim().isEmpty ? 'Email is required' : null;
      _passwordError =
          _passwordCtrl.text.isEmpty ? 'Password is required' : null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _loading = true);

    final result = await ApiService.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    // print(result);

    setState(() => _loading = false);

    if (!mounted) return;

    if (result['access_token'] != null) {
      final token = result['access_token'];
      final decoded = JwtDecoder.decode(token);
      final responseUser = result['user'] as Map<String, dynamic>?;

      final user = UserModel.fromJson({
        'id': responseUser?['id'] ?? decoded['sub'],
        'email': responseUser?['email'] ?? decoded['email'],
        'name': responseUser?['name'] ?? '',
        'role': responseUser?['role'] ?? decoded['role'],
        'image': responseUser?['image'],
        'latitude': responseUser?['latitude'],
        'longitude': responseUser?['longitude'],
        'access_token': token,
      });

      debugPrint('user = ${user.name}, role = ${user.role}');

      await SessionService.clear();
      await SessionService.save(user);
      await InAppNotificationStore.instance.loadFromServer();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleRouter()),
        (_) => false,
      );
    } else if (result['error'] != null) {
      // ❌ Connection error
      setState(() => _emailError = result['error']);
    } else if (result['statusCode'] == 401 ||
        result['message'] == 'Invalid email or password') {
      // ❌ Wrong credentials
      setState(() => _emailError = 'Invalid email or password');
    } else {
      // ❌ Any other server error
      setState(() => _emailError = result['message'] ?? 'Login failed');
    }
  }

  // Future<void> _login() async {
  //   // Basic validation
  //   setState(() {
  //     _emailError = _emailCtrl.text.trim().isEmpty ? 'Email is required' : null;
  //     _passwordError = _passwordCtrl.text.isEmpty ? 'Password is required' : null;
  //   });
  //   if (_emailError != null || _passwordError != null) return;

  //   setState(() => _loading = true);

  //   final result = await ApiService.login(
  //     email: _emailCtrl.text.trim(),
  //     password: _passwordCtrl.text,
  //   );

  //   setState(() => _loading = false);

  //   if (!mounted) return;

  //   final user = UserModel.fromJson(result);
  //   await SessionService.save(user);
  //   if (context.mounted) {
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (_) => const RoleRouter()),
  //       (_) => false,
  //     );
  //   } else if (result['error'] != null) {
  //     setState(() => _emailError = result['error']);
  //   } else if (result['statusCode'] == 401 || result['message'] == 'Invalid email or password') {
  //     setState(() => _emailError = 'Invalid email or password');
  //   } else {
  //     setState(() => _emailError = result['message'] ?? 'Login failed');
  //   }
  // }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (!mounted) return;

      // User cancelled the picker — silent, no error shown
      if (result == null) return;

      // ── Email exists in DB → log in ──────────────────────────────────────
      if (result is GoogleSignedIn) {
        await SessionService.clear();
        await SessionService.save(result.user);
        await InAppNotificationStore.instance.loadFromServer();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
          (_) => false,
        );
        return;
      }

      // ── Email NOT in DB → go to sign-up with pre-filled data ─────────────
      if (result is GoogleNeedsSignUp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignupScreen(
              prefillEmail: result.email,
              prefillName: result.name,
              prefillImageUrl: result.picture,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.login, style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(l.helloThere,
                style: TextStyle(
                    color: context.text,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l.loginToContinue,
                style: TextStyle(color: AppColors.grey, fontSize: 15)),
            const SizedBox(height: 36),

            _label(context, l.emailOrPhone),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: l.enterEmailOrPhone,
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 18),

            _label(context, l.password),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: l.password,
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen())),
                child: Text(l.forgotPassword,
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(l.login),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
                style: TextButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SocialDivider(),
            const SizedBox(height: 16),
            _SocialRow(
              onGoogleTap: _handleGoogleSignIn,
              googleLoading: _googleLoading,
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: RichText(
                  text: TextSpan(
                    text: l.dontHaveAccount,
                    style: TextStyle(color: AppColors.grey),
                    children: [
                      TextSpan(
                        text: l.signUp,
                        style: TextStyle(
                            color: AppColors.primary.withOpacity(0.9),
                            fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: context.text,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      );
}

class _SocialDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Divider(color: AppColors.grey.withOpacity(0.3))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(context.l.orSignInWith,
                style: TextStyle(color: AppColors.grey, fontSize: 13))),
        Expanded(child: Divider(color: AppColors.grey.withOpacity(0.3))),
      ]);
}

class _SocialRow extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final bool googleLoading;
  const _SocialRow({this.onGoogleTap, this.googleLoading = false});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _SocialBtn(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          onTap: onGoogleTap,
          isLoading: googleLoading,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SocialBtn(icon: Icons.apple, label: 'Apple')),
      ]);
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  const _SocialBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.divider),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(icon, color: context.text, size: 22),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: context.text, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}
