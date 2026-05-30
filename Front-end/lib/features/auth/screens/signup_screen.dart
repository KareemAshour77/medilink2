import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  /// When coming from Google Sign-In these are pre-filled and the email
  /// field is locked (the user already verified it with Google).
  final String? prefillEmail;
  final String? prefillName;
  final String? prefillImageUrl;

  const SignupScreen({
    super.key,
    this.prefillEmail,
    this.prefillName,
    this.prefillImageUrl,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _genderIndex = 0;
  int _jobIndex    = 0;
  bool _obscure    = true;
  bool _loading    = false;
  File? _pickedImage;

  final _nameController      = TextEditingController();
  final _nationalController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passController      = TextEditingController();
  final _confirmController   = TextEditingController();
  final _specialtyController = TextEditingController();

  String? _nameError;
  String? _nationalError;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    // Pre-fill from Google if provided
    if (widget.prefillName != null) {
      _nameController.text = widget.prefillName!;
    }
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            ),
            title: Text('Take a photo', style: TextStyle(color: context.text)),
            onTap: () async {
              Navigator.pop(context);
              final x = await ImagePicker()
                  .pickImage(source: ImageSource.camera, imageQuality: 80);
              if (x != null) setState(() => _pickedImage = File(x.path));
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            ),
            title: Text('Choose from gallery', style: TextStyle(color: context.text)),
            onTap: () async {
              Navigator.pop(context);
              final x = await ImagePicker()
                  .pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (x != null) setState(() => _pickedImage = File(x.path));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  bool _validateStep0(BuildContext context) {
    final l = context.l;
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? l.fullNameReq : null;

      final national = _nationalController.text.trim();
      if (national.isEmpty) {
        _nationalError = l.nationalIdReq;
      } else if (national.length != 14) {
        _nationalError = l.nationalIdMiss;
      } else {
        _nationalError = null;
      }

      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = l.emailReq;
      } else if (!email.contains('@')) {
        _emailError = l.emailMissAt;
      } else if (!email.contains('.')) {
        _emailError = l.emailMissDot;
      } else {
        _emailError = null;
      }

      final pass = _passController.text;
      if (pass.isEmpty) {
        _passError = l.newPasswordReq;
      } else if (pass[0] != pass[0].toUpperCase() || pass[0] == pass[0].toLowerCase()) {
        _passError = l.newPasswordUpp;
      } else if (!pass.contains(RegExp(r'[0-9]'))) {
        _passError = l.newPasswordNum;
      } else if (!pass.contains(RegExp(r'[!_@#\$%^&*(),.?":{}|<>]'))) {
        _passError = l.newPasswordSym;
      } else {
        _passError = null;
      }

      _confirmError = _confirmController.text != _passController.text
          ? l.confirmPasswordMatch
          : null;
    });

    return _nameError     == null &&
           _nationalError == null &&
           _emailError    == null &&
           _passError     == null &&
           _confirmError  == null;
  }

  Future<void> _submitSignup() async {
    if (!_validateStep0(context)) return;

    setState(() => _loading = true);

    // Must match backend ENUM: patient | doctor | pharmacy | lab | radiology
    final roles = ['patient', 'doctor', 'pharmacy', 'lab'];

    final result = await ApiService.signUp(
      name:      _nameController.text.trim(),
      email:     _emailController.text.trim(),
      password:  _passController.text,
      role:      roles[_jobIndex],
      image:     _pickedImage,
      specialty: _jobIndex == 1 ? _specialtyController.text.trim() : null,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (!mounted) return;

    // NestJS error responses always include a 'statusCode' field.
    // A missing statusCode means the request succeeded.
    if (result['error'] != null || result['statusCode'] != null) {
      final message = result['error'] ?? result['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              message is List ? message.first : (message ?? 'Sign up failed')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Backend stored pending data and sent OTP in one call.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmailVerificationScreen(email: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.signUpTitle, style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: _profileStep(context),
    );
  }

  Widget _profileStep(BuildContext context) {
    final l = context.l;
    final genderOptions = [l.male, l.female];
    final jobOptions    = [l.patient, l.doctor, l.pharmacy, l.scan];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.completeProfile,
              style: TextStyle(
                  color: context.text, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(l.onlyYouCanSee,
              style: const TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 28),

          // Avatar
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: context.card,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : null,
                  child: _pickedImage == null
                      ? const Icon(Icons.person_outline_rounded,
                          size: 48, color: AppColors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Tap to add photo',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 20),

          _label(context, l.fullName),
          TextField(
            controller: _nameController,
            decoration:
                InputDecoration(hintText: l.fullNameHint, errorText: _nameError),
          ),
          const SizedBox(height: 16),

          _label(context, l.gender),
          _dropdown(context, genderOptions, _genderIndex,
              (v) => setState(() => _genderIndex = v!)),
          const SizedBox(height: 16),

          _label(context, l.registerAs),
          _dropdown(context, jobOptions, _jobIndex,
              (v) => setState(() => _jobIndex = v!)),
          const SizedBox(height: 16),

          if (_jobIndex == 1) ...[
            _label(context, 'Specialty'),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                hintText: 'e.g. Cardiologist, Pediatrician',
              ),
            ),
            const SizedBox(height: 16),
          ],

          _label(context, l.nationalId),
          TextField(
            controller: _nationalController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
            ],
            decoration: InputDecoration(
                hintText: l.nationalIdHint, errorText: _nationalError),
          ),
          const SizedBox(height: 16),

          _label(context, l.email),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            // Lock the field when email came from Google (already verified)
            readOnly: widget.prefillEmail != null,
            decoration: InputDecoration(
              hintText: l.emailHint,
              errorText: _emailError,
              suffixIcon: widget.prefillEmail != null
                  ? const Tooltip(
                      message: 'Verified by Google',
                      child: Icon(Icons.verified_rounded,
                          color: Colors.green, size: 20),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          _label(context, l.createPassword),
          TextField(
            controller: _passController,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: l.newPasswordHint,
              errorText: _passError,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _label(context, l.confirmPassword),
          TextField(
            controller: _confirmController,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: l.confirmPasswordHint,
              errorText: _confirmError,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submitSignup,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(l.signUp),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: TextSpan(
                  text: l.alreadyHaveAccount,
                  style: const TextStyle(color: AppColors.grey),
                  children: [
                    TextSpan(
                      text: l.signIn,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(BuildContext context, List<String> options, int value,
      ValueChanged<int?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: context.card,
          items: List.generate(
            options.length,
            (i) => DropdownMenuItem(
              value: i,
              child: Text(options[i], style: TextStyle(color: context.text)),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
              color: context.text,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      );
}
