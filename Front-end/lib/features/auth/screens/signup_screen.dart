import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../models/national_id_info.dart';
import '../widgets/account_type_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/doctor_pro_badge.dart';
import '../widgets/image_pick_sheet.dart';
import '../widgets/password_field.dart';
import '../widgets/read_only_info_tile.dart';
import '../widgets/step_progress_indicator.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Multi-step registration (Basic Info → Identity → Verification).
/// Patient and Doctor have rich 3-step flows; Pharmacy/Lab use a lighter
/// 2-step flow that posts to the legacy /auth/signup endpoint.
class SignupScreen extends StatefulWidget {
  /// When coming from Google Sign-In these pre-fill and lock the email field.
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
  // 'patient' | 'doctor' | 'pharmacy' | 'lab'
  String _role = 'patient';
  int _step = 0;
  bool _loading = false;

  // Step 1 — basic
  File? _profileImage;

  // Identity / account
  final _nameCtrl = TextEditingController();
  final _nationalCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Doctor professional
  final _specialtyCtrl = TextEditingController();
  final _syndicateCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  bool _onlineConsultation = false;

  // Verification
  bool _acceptedTerms = false;

  // True when the entered email already has an account → shared password, so
  // the password fields are hidden and the backend reuses the existing one.
  bool _emailExists = false;
  Timer? _emailDebounce;

  bool get _isPatient => _role == 'patient';
  bool get _isDoctor => _role == 'doctor';
  bool get _isRich => _isPatient || _isDoctor; // 3-step flows

  int get _lastStep => _isRich ? 2 : 1;
  // Gender is derived from the National ID (step 2); defaults to male until a
  // valid ID is entered (e.g. for pharmacy/lab which have no National ID).
  String get _genderStr => _idInfo.gender ?? 'male';

  NationalIdInfo get _idInfo => NationalIdInfo.parse(_nationalCtrl.text.trim());

  List<String> get _stepLabels => _isRich
      ? const ['Basic Info', 'Identity', 'Verification']
      : const ['Basic Info', 'Account'];

  @override
  void initState() {
    super.initState();
    if (widget.prefillName != null) _nameCtrl.text = widget.prefillName!;
    if (widget.prefillEmail != null) _emailCtrl.text = widget.prefillEmail!;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _nationalCtrl,
      _emailCtrl,
      _passCtrl,
      _confirmCtrl,
      _specialtyCtrl,
      _syndicateCtrl,
      _experienceCtrl,
      _clinicCtrl,
      _feeCtrl,
    ]) {
      c.dispose();
    }
    _emailDebounce?.cancel();
    super.dispose();
  }

  // Checks (debounced) whether the typed email already has an account, so we can
  // skip the password step (shared password per email).
  void _onEmailChanged(String value) {
    setState(() {}); // live-update Next button + validation
    _emailDebounce?.cancel();
    final email = value.trim();
    if (!_emailValid(email)) {
      if (_emailExists) setState(() => _emailExists = false);
      return;
    }
    _emailDebounce = Timer(const Duration(milliseconds: 400), () async {
      final status = await ApiService.accountStatus(email: email);
      if (!mounted) return;
      setState(() => _emailExists = status['exists'] == true);
    });
  }

  // ── Validation (drives the Next button enabled state) ──────────────────────
  bool _emailValid(String e) => e.contains('@') && e.contains('.');

  bool _passwordValid(String p) =>
      p.length >= 8 &&
      p.contains(RegExp(r'[A-Z]')) &&
      p.contains(RegExp(r'[0-9]')) &&
      p.contains(RegExp(r'[!_@#\$%^&*(),.?":{}|<>]'));

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty;
      case 1:
        final emailOk = _emailValid(_emailCtrl.text.trim());
        // When the email already exists the shared password is reused, so no
        // password input is required here.
        final passOk = _emailExists || _passwordValid(_passCtrl.text);
        final confirmOk = _emailExists || _confirmCtrl.text == _passCtrl.text;
        if (!_isRich) return emailOk && passOk && confirmOk;
        final idOk = _idInfo.isValid;
        if (_isDoctor) {
          return idOk &&
              emailOk &&
              passOk &&
              confirmOk &&
              _specialtyCtrl.text.trim().isNotEmpty &&
              _syndicateCtrl.text.trim().isNotEmpty &&
              int.tryParse(_experienceCtrl.text.trim()) != null;
        }
        return idOk && emailOk && passOk && confirmOk;
      case 2:
        return _acceptedTerms;
      default:
        return false;
    }
  }

  void _next() {
    if (_step < _lastStep) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    Map<String, dynamic> result;

    // When the email already exists, omit the password (shared per email).
    final password = _emailExists ? null : _passCtrl.text;

    if (_isPatient) {
      result = await ApiService.registerPatient(
        fullName: _nameCtrl.text.trim(),
        gender: _genderStr,
        nationalId: _nationalCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: password,
        profileImage: _profileImage,
      );
    } else if (_isDoctor) {
      result = await ApiService.registerDoctor(
        fullName: _nameCtrl.text.trim(),
        gender: _genderStr,
        nationalId: _nationalCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: password,
        specialty: _specialtyCtrl.text.trim(),
        syndicateNumber: _syndicateCtrl.text.trim(),
        yearsOfExperience: int.parse(_experienceCtrl.text.trim()),
        clinicName: _clinicCtrl.text.trim().isEmpty
            ? null
            : _clinicCtrl.text.trim(),
        consultationFee: double.tryParse(_feeCtrl.text.trim()),
        onlineConsultation: _onlineConsultation,
        profileImage: _profileImage,
      );
    } else {
      // Pharmacy / Lab → legacy signup endpoint.
      result = await ApiService.signUp(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: password,
        role: _role,
        image: _profileImage,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['error'] != null || result['statusCode'] != null) {
      AppSnackBar.show(context, _errorMessage(result));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // 0 = male, 1 = female — derived from the National ID.
    await prefs.setInt('profile_gender', _genderStr == 'female' ? 1 : 0);
    if (!mounted) return;

    // push (not pushReplacement) so the populated form stays beneath the
    // verification screen — "Wrong email? Change it" pops back to it intact.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmailVerificationScreen(email: _emailCtrl.text.trim(), role: _role),
      ),
    );
  }

  String _errorMessage(Map<String, dynamic> result) {
    final statusCode = result['statusCode'] as int?;
    switch (statusCode) {
      case 409:
        final raw = result['message'];
        return raw is String
            ? raw
            : 'This email or national ID is already registered.';
      case 400:
        final raw = result['message'];
        return raw is List
            ? raw.first.toString()
            : (raw?.toString() ?? 'Please check your details and try again.');
      case 500:
        return 'Server error. Please try again later.';
      default:
        final raw = result['error'] ?? result['message'];
        return raw is List
            ? raw.first.toString()
            : (raw?.toString() ?? 'Sign up failed. Please try again.');
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: _back,
        ),
        title: Text('Create Account', style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: StepProgressIndicator(
              steps: _stepLabels,
              currentIndex: _step,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: SingleChildScrollView(
                key: ValueKey('${_role}_$_step'),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _stepBody(),
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _stepBody() {
    if (_step == 0) return _basicInfoStep();
    if (_step == 1) return _identityStep();
    return _verificationStep();
  }

  // ── Step 1: Basic Info ─────────────────────────────────────────────────────
  Widget _basicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Basic Information', 'Tell us a little about you'),
        const SizedBox(height: 20),
        Center(child: _avatar()),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Full Name',
          hint: 'Enter your full name',
          controller: _nameCtrl,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Text('Account Type',
            style: TextStyle(
                color: context.text, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AccountTypeCard(
              icon: Icons.person_rounded,
              label: 'Patient',
              selected: _role == 'patient',
              onTap: () => setState(() => _role = 'patient'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AccountTypeCard(
              icon: Icons.medical_services_rounded,
              label: 'Doctor',
              selected: _role == 'doctor',
              onTap: () => setState(() => _role = 'doctor'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: AccountTypeCard(
              icon: Icons.local_pharmacy_rounded,
              label: 'Pharmacy',
              selected: _role == 'pharmacy',
              onTap: () => setState(() => _role = 'pharmacy'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AccountTypeCard(
              icon: Icons.biotech_rounded,
              label: 'Lab',
              selected: _role == 'lab',
              onTap: () => setState(() => _role = 'lab'),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _signInLink(),
      ],
    );
  }

  Widget _avatar() {
    return GestureDetector(
      onTap: () async {
        final f = await showImagePickSheet(context);
        if (f != null) setState(() => _profileImage = f);
      },
      child: Column(
        children: [
          Stack(children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: context.card,
              backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? const Icon(Icons.person_outline_rounded,
                      size: 46, color: AppColors.grey)
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
          const SizedBox(height: 8),
          const Text('Add photo (optional)',
              style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Step 2: Identity / Account ─────────────────────────────────────────────
  Widget _identityStep() {
    if (_isDoctor) return _doctorIdentityStep();
    if (_isPatient) return _patientIdentityStep();
    return _basicCredentialsStep();
  }

  Widget _patientIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Identity', 'Verify who you are'),
        const SizedBox(height: 20),
        _nationalIdField(),
        const SizedBox(height: 16),
        _extractedInfo(),
        const SizedBox(height: 18),
        _emailField(),
        const SizedBox(height: 18),
        _passwordFields(),
      ],
    );
  }

  Widget _doctorIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DoctorProBadge(),
        const SizedBox(height: 18),
        _title('Professional Details', 'Your medical credentials'),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Specialty',
          hint: 'e.g. Cardiologist, Pediatrician',
          controller: _specialtyCtrl,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _nationalIdField(),
        const SizedBox(height: 16),
        _extractedInfo(),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Medical Syndicate Number',
          hint: 'Syndicate registration number',
          controller: _syndicateCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Years of Experience',
          hint: 'e.g. 8',
          controller: _experienceCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Clinic Name (optional)',
          hint: 'Your clinic / hospital',
          controller: _clinicCtrl,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Consultation Fee (optional)',
          hint: 'e.g. 200',
          controller: _feeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 16),
        _onlineSwitch(),
        const SizedBox(height: 18),
        _emailField(),
        const SizedBox(height: 18),
        _passwordFields(),
      ],
    );
  }

  Widget _basicCredentialsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Account', 'Set up your login'),
        const SizedBox(height: 20),
        _emailField(),
        const SizedBox(height: 18),
        _passwordFields(),
      ],
    );
  }

  Widget _nationalIdField() {
    final value = _nationalCtrl.text.trim();
    final invalid = value.length == 14 && !_idInfo.isValid;
    return AuthTextField(
      label: 'National ID',
      hint: '14-digit national ID',
      controller: _nationalCtrl,
      keyboardType: TextInputType.number,
      maxLength: 14,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(14),
      ],
      errorText: invalid ? 'Invalid national ID number' : null,
      onChanged: (_) => setState(() {}),
    );
  }

  // Read-only DOB + gender extracted from the National ID (display only).
  Widget _extractedInfo() {
    final info = _idInfo;
    if (!info.isValid) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadOnlyInfoTile(
          icon: Icons.cake_rounded,
          label: 'Date of Birth',
          value: info.dateOfBirthLabel ?? '—',
        ),
        const SizedBox(height: 12),
        ReadOnlyInfoTile(
          icon: info.gender == 'female'
              ? Icons.female_rounded
              : Icons.male_rounded,
          label: 'Gender (from ID)',
          value: info.gender == 'female' ? 'Female' : 'Male',
        ),
      ],
    );
  }

  Widget _emailField() {
    return AuthTextField(
      label: 'Email',
      hint: 'you@example.com',
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      readOnly: widget.prefillEmail != null,
      onChanged: _onEmailChanged,
      suffixIcon: widget.prefillEmail != null
          ? const Tooltip(
              message: 'Verified by Google',
              child: Icon(Icons.verified_rounded, color: Colors.green, size: 20),
            )
          : null,
    );
  }

  Widget _passwordFields() {
    // Shared password per email: if this email already has an account, we reuse
    // its password — so hide the inputs and explain why.
    if (_emailExists) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This email already has an account. We\'ll use your existing password.',
              style: TextStyle(color: context.text, fontSize: 13),
            ),
          ),
        ]),
      );
    }
    return Column(
      children: [
        PasswordField(
          label: 'Password',
          hint: 'Create a strong password',
          controller: _passCtrl,
          showStrength: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        PasswordField(
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          controller: _confirmCtrl,
          onChanged: (_) => setState(() {}),
          errorText: _confirmCtrl.text.isNotEmpty &&
                  _confirmCtrl.text != _passCtrl.text
              ? 'Passwords do not match'
              : null,
        ),
      ],
    );
  }

  Widget _onlineSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary,
        title: Text('Offer online consultation',
            style: TextStyle(color: context.text, fontSize: 14)),
        value: _onlineConsultation,
        onChanged: (v) => setState(() => _onlineConsultation = v),
      ),
    );
  }

  // ── Step 3: Verification ───────────────────────────────────────────────────
  Widget _verificationStep() {
    return _isDoctor ? _doctorVerification() : _patientVerification();
  }

  Widget _patientVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Review & Confirm', 'Check your details before creating'),
        const SizedBox(height: 18),
        _reviewCard([
          (Icons.person_outline_rounded, 'Full Name', _nameCtrl.text.trim()),
          (Icons.wc_rounded, 'Gender',
              _genderStr == 'female' ? 'Female' : 'Male'),
          (Icons.badge_outlined, 'National ID', _nationalCtrl.text.trim()),
          (Icons.cake_outlined, 'Date of Birth', _idInfo.dateOfBirthLabel ?? '—'),
          (Icons.email_outlined, 'Email', _emailCtrl.text.trim()),
        ]),
        const SizedBox(height: 18),
        _termsCheckbox(),
      ],
    );
  }

  Widget _doctorVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Review & Confirm', 'Check your details before creating'),
        const SizedBox(height: 18),
        _reviewCard([
          (Icons.person_outline_rounded, 'Full Name', _nameCtrl.text.trim()),
          (Icons.wc_rounded, 'Gender',
              _genderStr == 'female' ? 'Female' : 'Male'),
          (Icons.medical_services_outlined, 'Specialty',
              _specialtyCtrl.text.trim()),
          (Icons.badge_outlined, 'National ID', _nationalCtrl.text.trim()),
          (Icons.cake_outlined, 'Date of Birth', _idInfo.dateOfBirthLabel ?? '—'),
          (Icons.assignment_ind_outlined, 'Syndicate №',
              _syndicateCtrl.text.trim()),
          (Icons.workspace_premium_outlined, 'Experience',
              '${_experienceCtrl.text.trim()} yrs'),
          if (_clinicCtrl.text.trim().isNotEmpty)
            (Icons.local_hospital_outlined, 'Clinic', _clinicCtrl.text.trim()),
          if (_feeCtrl.text.trim().isNotEmpty)
            (Icons.payments_outlined, 'Fee', _feeCtrl.text.trim()),
          (Icons.videocam_outlined, 'Online Consultation',
              _onlineConsultation ? 'Enabled' : 'Disabled'),
          (Icons.email_outlined, 'Email', _emailCtrl.text.trim()),
        ]),
        const SizedBox(height: 18),
        _termsCheckbox(),
      ],
    );
  }

  Widget _reviewCard(List<(IconData, String, String)> rows) {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(rows[i].$1,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2,
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(
                          rows[i].$3.isEmpty ? '—' : rows[i].$3,
                          style: TextStyle(
                              color: context.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              Divider(height: 1, color: context.divider, indent: 62),
          ],
        ],
      ),
    );
  }

  Widget _termsCheckbox() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptedTerms,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'I accept the Terms and Conditions and Privacy Policy.',
                style: TextStyle(color: context.text, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared chrome ──────────────────────────────────────────────────────────
  Widget _title(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: context.text,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: AppColors.grey, fontSize: 13.5)),
      ],
    );
  }

  Widget _signInLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoginScreen())),
        child: RichText(
          text: const TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(color: AppColors.grey),
            children: [
              TextSpan(
                text: 'Sign In',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final isLast = _step == _lastStep;
    final label = isLast
        ? (_isDoctor ? 'Create Doctor Account' : 'Create Account')
        : 'Next';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : _back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  side: const BorderSide(color: AppColors.primary, width: 1.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_stepValid && !_loading) ? _next : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 54),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(label),
            ),
          ),
        ]),
      ),
    );
  }
}
