// lib/features/auth/screens/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  String _enteredCode = '';
  bool _hasError = false;
  bool _loading = false;
  bool _resending = false;

  // ── Verify against backend ────────────────────────────────────────────────

  Future<void> _verify() async {
    if (_enteredCode.length < 6) {
      setState(() => _hasError = true);
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    final result = await ApiService.verifyCode(
      email: widget.email,
      code: _enteredCode,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (result['error'] != null) {
      // Network error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    } else if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      setState(() => _hasError = true);
      final msg = result['message'] ?? 'Incorrect code.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  // ── Resend ────────────────────────────────────────────────────────────────

  Future<void> _resend() async {
    setState(() => _resending = true);

    final result = await ApiService.sendVerificationCode(email: widget.email);

    setState(() => _resending = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // ignore: prefer_if_null_operators
        content: Text(result['error'] != null
            ? result['error']
            : 'A new code was sent to ${widget.email}'),
        backgroundColor:
            result['error'] != null ? Colors.red : AppColors.primary,
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verification', style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Email verification',
                  style: TextStyle(
                      color: context.text,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: AppColors.grey, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(
                        text: '. Enter it below to verify your account.'),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              MaterialPinField(
                length: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (v) => setState(() {
                  _enteredCode = v;
                  _hasError = false;
                }),
                onCompleted: (_) => _verify(),
                theme: MaterialPinTheme(
                  shape: MaterialPinShape.outlined,
                  borderRadius: BorderRadius.circular(12),
                  cellSize: const Size(48, 56),
                  fillColor: context.card,
                  focusedFillColor: context.card,
                  filledFillColor: context.card,
                  borderColor: _hasError
                      ? Colors.red.withOpacity(0.4)
                      : context.divider,
                  focusedBorderColor:
                      _hasError ? Colors.red : AppColors.primary,
                  filledBorderColor:
                      _hasError ? Colors.red : AppColors.primary,
                  textStyle: TextStyle(
                      color: context.text,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: 4),
                const Text('Incorrect code. Please try again.',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              const Center(
                child:  Text("Didn't receive a code?",
                    style: TextStyle(color: AppColors.grey, fontSize: 13)),
              ),
              Center(
                child: _resending
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend code',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
