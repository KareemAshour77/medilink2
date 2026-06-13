import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _obscure1 = true, _obscure2 = true;
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinController = PinInputController();
  String _code = '';

  // Resend cooldown (matches backend's 30s reset rate-limit).
  static const _resendSeconds = 30;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _pinController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  bool _emailValid(String e) => e.contains('@') && e.contains('.');

  bool _passwordValid(String p) =>
      p.length >= 8 &&
      p.contains(RegExp(r'[A-Z]')) &&
      p.contains(RegExp(r'[0-9]')) &&
      p.contains(RegExp(r'[!_@#\$%^&*(),.?":{}|<>]'));

  void _startResendCooldown() {
    setState(() => _resendIn = _resendSeconds);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _resendIn--);
      if (_resendIn <= 0) _resendTimer?.cancel();
    });
  }

  // ── Step actions ────────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (!_emailValid(email)) {
      AppSnackBar.show(context, 'Please enter a valid email.');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.forgotPassword(email: email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      _startResendCooldown();
      setState(() => _step = 1);
    } else {
      AppSnackBar.show(context, _msg(res, 'Could not send the code.'));
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    final res = await ApiService.forgotPassword(email: _emailCtrl.text.trim());
    if (!mounted) return;
    if (res['success'] == true) {
      _startResendCooldown();
      AppSnackBar.show(context, 'A new code was sent.',
          backgroundColor: AppColors.primary);
    } else {
      AppSnackBar.show(context, _msg(res, 'Could not resend the code.'));
    }
  }

  Future<void> _verifyCode() async {
    if (_code.length < 6) {
      AppSnackBar.show(context, 'Enter the 6-digit code.');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.verifyResetCode(
        email: _emailCtrl.text.trim(), code: _code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      setState(() => _step = 2);
    } else {
      _pinController.triggerError();
      AppSnackBar.show(context, _msg(res, 'Invalid code.'));
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordValid(_passCtrl.text)) {
      AppSnackBar.show(context,
          'Password needs 8+ characters with an uppercase letter, a number, and a symbol.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      AppSnackBar.show(context, 'Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.resetPassword(
      email: _emailCtrl.text.trim(),
      code: _code,
      password: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      AppSnackBar.show(context, 'Password updated. Please sign in.',
          backgroundColor: Colors.green);
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      AppSnackBar.show(context, _msg(res, 'Could not reset the password.'));
    }
  }

  String _msg(Map<String, dynamic> res, String fallback) {
    final m = res['message'] ?? res['error'];
    if (m is List && m.isNotEmpty) return m.first.toString();
    return m?.toString() ?? fallback;
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () =>
              _step > 0 ? setState(() => _step--) : Navigator.pop(context),
        ),
        title: Text(_step == 2 ? 'New Password' : 'Forgot Password',
            style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == 0
              ? _emailStep(context)
              : _step == 1
                  ? _otpStep(context)
                  : _newPassStep(context),
        ),
      ),
    );
  }

  Widget _emailStep(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reset your password',
              style: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Enter your email to receive a verification code.',
              style: TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          _label(context, 'Email'),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Enter your email'),
          ),
          const Spacer(),
          _primaryButton('Send Code', _loading ? null : _sendCode),
        ],
      );

  Widget _otpStep(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email verification',
              style: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Enter the 6-digit code we sent to ${_emailCtrl.text.trim()}.",
              style: const TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 36),
          MaterialPinField(
            length: 6,
            pinController: _pinController,
            keyboardType: TextInputType.number,
            autoFocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _code = v,
            onCompleted: (_) => _verifyCode(),
            theme: MaterialPinTheme(
              shape: MaterialPinShape.outlined,
              borderRadius: BorderRadius.circular(12),
              cellSize: const Size(48, 56),
              fillColor: context.card,
              focusedFillColor: context.card,
              filledFillColor: context.card,
              borderColor: context.divider,
              focusedBorderColor: AppColors.primary,
              filledBorderColor: AppColors.primary,
              textStyle: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: _resendIn > 0
                ? Text('Resend in 0:${_resendIn.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))
                : TextButton(
                    onPressed: _resend,
                    child: const Text('Resend code',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600))),
          ),
          const Spacer(),
          _primaryButton('Verify', _loading ? null : _verifyCode),
        ],
      );

  Widget _newPassStep(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create new password',
              style: TextStyle(
                  color: context.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Must be different from your previous password.',
              style: TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          _label(context, 'New Password'),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure1,
            decoration: InputDecoration(
              hintText: 'New password',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure1
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label(context, 'Confirm Password'),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure2,
            decoration: InputDecoration(
              hintText: 'Confirm password',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure2
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
          ),
          const Spacer(),
          _primaryButton('Save New Password', _loading ? null : _savePassword),
        ],
      );

  Widget _primaryButton(String label, VoidCallback? onPressed) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(label),
        ),
      );

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                color: context.text,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      );
}
