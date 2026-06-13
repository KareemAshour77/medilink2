// lib/features/auth/screens/email_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/router.dart';
import '../model/user_model.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  /// When true (verifying a *secondary* account from the account chooser /
  /// switcher), success pops back with {access_token, user} instead of clearing
  /// the session and auto-logging in. This keeps the current login intact.
  final bool popOnSuccess;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.role,
    this.popOnSuccess = false,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _pinController = PinInputController();

  String _enteredCode = '';
  bool _hasError = false;
  bool _loading = false;
  bool _resending = false;
  bool _verified = false; // drives the success overlay

  // Resend cooldown (matches backend's 30s rate-limit) and code expiry (5 min,
  // enforced server-side). Both tick down once per second.
  static const _resendSeconds = 30;
  static const _expirySeconds = 300;
  int _resendIn = _resendSeconds;
  int _expiresIn = _expirySeconds;
  Timer? _ticker;

  // A six-digit code spotted on the clipboard → offer a one-tap paste chip.
  String? _clipboardCode;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  // ── Timers ────────────────────────────────────────────────────────────────

  void _startTimers() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendIn > 0) _resendIn--;
        if (_expiresIn > 0) _expiresIn--;
      });
      if (_resendIn == 0 && _expiresIn == 0) _ticker?.cancel();
    });
  }

  void _resetTimersAfterSend() {
    setState(() {
      _resendIn = _resendSeconds;
      _expiresIn = _expirySeconds;
      _hasError = false;
      _clipboardCode = null;
    });
    _enteredCode = '';
    _pinController.clear();
    _startTimers();
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  // ── Verify against backend ────────────────────────────────────────────────

  Future<void> _verify() async {
    if (_expiresIn == 0) return;
    if (_enteredCode.length < 6) {
      setState(() => _hasError = true);
      _pinController.triggerError();
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    final result = await ApiService.verifyCode(
      email: widget.email,
      role: widget.role,
      code: _enteredCode,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['error'] != null) {
      // Network error
      AppSnackBar.show(context, result['error'].toString());
    } else if (result['success'] == true) {
      final token = result['access_token'];
      final responseUser = result['user'] as Map<String, dynamic>?;

      // Verifying a secondary account (from the chooser/switcher): don't touch
      // the current session — just play the checkmark and hand the result back.
      if (widget.popOnSuccess) {
        await _playSuccess();
        if (!mounted) return;
        Navigator.pop(context, {'access_token': token, 'user': responseUser});
        return;
      }

      // Auto-login: the backend returns a token on verify, so we drop the user
      // straight into their home instead of back to the login screen.
      if (token != null && responseUser != null) {
        final user = UserModel.fromJson({
          ...responseUser,
          'access_token': token,
        });
        await SessionService.clear();
        await SessionService.save(user);
        // No loadFromServer() — a freshly verified account has no notifications
        // yet, so it would just be an empty round-trip.
        ChatService.instance.connect().catchError((_) {});
        FcmService.instance.uploadToken().catchError((_) {});

        if (!mounted) return;
        await _playSuccessThenRoute(const RoleRouter());
      } else {
        // Fallback (older backend without a token) → go to login.
        if (!mounted) return;
        await _playSuccessThenRoute(const LoginScreen());
      }
    } else {
      setState(() => _hasError = true);
      _pinController.triggerError();
      final msg = result['message'] ?? 'Incorrect code.';
      AppSnackBar.show(context, msg);
    }
  }

  // Shows the checkmark overlay briefly (no navigation).
  Future<void> _playSuccess() async {
    _ticker?.cancel();
    setState(() => _verified = true);
    await Future.delayed(const Duration(milliseconds: 950));
  }

  // Shows the checkmark overlay briefly, then clears the stack into [home].
  Future<void> _playSuccessThenRoute(Widget home) async {
    await _playSuccess();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
      (_) => false,
    );
  }

  // ── Resend ────────────────────────────────────────────────────────────────

  Future<void> _resend() async {
    if (_resendIn > 0 || _resending) return;
    setState(() => _resending = true);

    final result = await ApiService.sendVerificationCode(
      email: widget.email,
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _resending = false);

    final failed = result['error'] != null;
    AppSnackBar.show(
      context,
      failed
          ? result['error'].toString()
          : 'A new code was sent to ${widget.email}',
      backgroundColor: failed ? Colors.red : AppColors.primary,
    );
    if (!failed) _resetTimersAfterSend();
  }

  // ── Clipboard ─────────────────────────────────────────────────────────────

  void _onClipboardFound(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 6 && mounted) {
      setState(() => _clipboardCode = digits);
    }
  }

  void _applyClipboard() {
    final code = _clipboardCode;
    if (code == null) return;
    _pinController.setText(code);
    setState(() {
      _enteredCode = code;
      _clipboardCode = null;
      _hasError = false;
    });
    _verify();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final expired = _expiresIn == 0;
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _headerBadge(),
                  const SizedBox(height: 24),
                  Text('Verify your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.text,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Enter the 6-digit code we sent to',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.grey, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 8),
                  _emailPill(),
                  const SizedBox(height: 28),
                  if (_clipboardCode != null) _pasteChip(),
                  _pinField(expired),
                  if (_hasError) ...[
                    const SizedBox(height: 8),
                    const Text('Incorrect code. Please try again.',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  _expiryLine(expired),
                  const SizedBox(height: 18),
                  _resendRow(),
                  const SizedBox(height: 6),
                  _changeEmail(),
                  const SizedBox(height: 28),
                  _verifyButton(expired),
                ],
              ),
            ),
          ),
          if (_verified) _successOverlay(),
        ],
      ),
    );
  }

  Widget _headerBadge() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: const Icon(Icons.mark_email_unread_outlined,
          color: AppColors.primary, size: 40),
    );
  }

  Widget _emailPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(widget.email,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _pasteChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ActionChip(
        avatar: const Icon(Icons.content_paste_rounded,
            size: 18, color: AppColors.primary),
        label: Text('Paste $_clipboardCode',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        onPressed: _applyClipboard,
      ),
    );
  }

  Widget _pinField(bool expired) {
    return MaterialPinField(
      length: 6,
      pinController: _pinController,
      keyboardType: TextInputType.number,
      autoFocus: true,
      enabled: !_loading && !expired,
      enableAutofill: true,
      autofillHints: const [AutofillHints.oneTimeCode],
      onClipboardFound: _onClipboardFound,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        borderColor:
            _hasError ? Colors.red.withOpacity(0.4) : context.divider,
        focusedBorderColor: _hasError ? Colors.red : AppColors.primary,
        filledBorderColor: _hasError ? Colors.red : AppColors.primary,
        textStyle: TextStyle(
            color: context.text, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _expiryLine(bool expired) {
    if (expired) {
      return const Text('Code expired — request a new one.',
          style: TextStyle(
              color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 16, color: AppColors.grey),
        const SizedBox(width: 6),
        Text('Code expires in ${_fmt(_expiresIn)}',
            style: const TextStyle(color: AppColors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _resendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Didn't receive it? ",
            style: TextStyle(color: AppColors.grey, fontSize: 13)),
        if (_resending)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          )
        else if (_resendIn > 0)
          Text('Resend in ${_fmt(_resendIn)}',
              style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600))
        else
          GestureDetector(
            onTap: _resend,
            child: const Text('Resend code',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _changeEmail() {
    return TextButton(
      onPressed: _loading ? null : () => Navigator.pop(context),
      child: const Text('Wrong email? Change it',
          style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              decoration: TextDecoration.underline)),
    );
  }

  Widget _verifyButton(bool expired) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_loading || expired) ? null : _verify,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text('Verify'),
      ),
    );
  }

  Widget _successOverlay() {
    return Positioned.fill(
      child: Container(
        color: context.bg.withOpacity(0.96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (_, t, __) => Transform.scale(
                  scale: t,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 52),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Verified',
                  style: TextStyle(
                      color: context.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
