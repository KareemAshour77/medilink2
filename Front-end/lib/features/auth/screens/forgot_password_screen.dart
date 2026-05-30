import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _obscure1 = true, _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context),
        ),
        title: Text(_step == 2 ? 'New Password' : 'Forgot Password',
            style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding( 
        padding: const EdgeInsets.all(24),
        child: _step == 0 ? _emailStep(context) : _step == 1 ? _otpStep(context) : _newPassStep(context),
      ),
      ),
    );
  }

  Widget _emailStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Reset your password',
          style: TextStyle(color: context.text, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Enter your email to receive a verification code.',
          style: TextStyle(color: AppColors.grey, fontSize: 14)),
      const SizedBox(height: 32),
      _label(context, 'Email'),
      const TextField(keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: 'Enter your email')),
      const Spacer(),
      ElevatedButton(
          onPressed: () => setState(() => _step = 1), child: const Text('Send Code')),
    ],
  );

  Widget _otpStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Email verification',
          style: TextStyle(color: context.text, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text("Enter the code we sent to your email.",
          style: TextStyle(color: AppColors.grey, fontSize: 14)),
      const SizedBox(height: 36),
      MaterialPinField(
        length: 4,
        onChanged: (_) {},
        theme: MaterialPinTheme(
          shape: MaterialPinShape.outlined,
          borderRadius: BorderRadius.circular(12),
          cellSize: const Size(62, 62),
          fillColor: context.card,
          focusedFillColor: context.card,
          filledFillColor: context.card,
          borderColor: context.divider,
          focusedBorderColor: AppColors.primary,
          filledBorderColor: AppColors.primary,
          textStyle: TextStyle(color: context.text, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      Center(child: TextButton(onPressed: () {},
          child: const Text('Resend code',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)))),
      const Spacer(),
      ElevatedButton(
          onPressed: () => setState(() => _step = 2), child: const Text('Verify')),
    ],
  );

  Widget _newPassStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Create new password',
          style: TextStyle(color: context.text, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Must be different from your previous password.',
          style: TextStyle(color: AppColors.grey, fontSize: 14)),
      const SizedBox(height: 32),
      _label(context, 'New Password'),
      TextField(
        obscureText: _obscure1,
        decoration: InputDecoration(
          hintText: 'New password',
          suffixIcon: IconButton(
            icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.grey),
            onPressed: () => setState(() => _obscure1 = !_obscure1),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _label(context, 'Confirm Password'),
      TextField(
        obscureText: _obscure2,
        decoration: InputDecoration(
          hintText: 'Confirm password',
          suffixIcon: IconButton(
            icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.grey),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),
      ),
      const Spacer(),
      ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        child: const Text('Save New Password'),
      ),
    ],
  );

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(color: context.text, fontSize: 14, fontWeight: FontWeight.w500)),
  );
}
