// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/api_service.dart';
import '../../auth/model/user_model.dart';

//import '../../l10n/app_localizations.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  int _genderIndex = 0;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConf = true;
  bool _isSaving = false;

  String? _nameError;
  String? _emailError;
  String? _nationalError;
  String? _newPassError;
  String? _confirmPassError;

  File? _pickedImage;

  static const _prefNational = 'profile_national';
  static const _prefGender = 'profile_gender';

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await SessionService.load();
    final user = SessionService.currentUser;
    setState(() {
      _nameController.text = user?.name ?? '';
      _emailController.text = user?.email ?? '';
      _nationalController.text = prefs.getString(_prefNational) ?? '';
      _genderIndex = prefs.getInt(_prefGender) ?? 0;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nationalController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── Photo picker ────────────────────────────────────────
  Future<void> _pickPhoto() async {
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
            width: 40,
            height: 4,
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
              child: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
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
              child: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
            ),
            title: Text('Choose from gallery',
                style: TextStyle(color: context.text)),
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

  // ── Validation ──────────────────────────────────────────
  bool _validate() {
    bool ok = true;
    setState(() {
      // Name
      _nameError =
          _nameController.text.trim().isEmpty ? 'Full name is required' : null;
      if (_nameError != null) ok = false;

      // Email
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Email is required';
        ok = false;
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Enter a valid email with @';
        ok = false;
      } else {
        _emailError = null;
      }

      // National ID — validation disabled; clear any previous error
      _nationalError = null;

      // Password — only validate if user typed something in new password
      final newPass = _newPassController.text;
      if (newPass.isNotEmpty) {
        if (newPass[0] != newPass[0].toUpperCase() ||
            newPass[0] == newPass[0].toLowerCase()) {
          _newPassError = 'Must start with an uppercase letter';
          ok = false;
        } else if (!newPass.contains(RegExp(r'[0-9]'))) {
          _newPassError = 'Must contain at least one number';
          ok = false;
        } else if (!newPass.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
          _newPassError = 'Must contain at least one symbol';
          ok = false;
        } else {
          _newPassError = null;
        }

        _confirmPassError = _confirmPassController.text != newPass
            ? 'Passwords do not match'
            : null;
        if (_confirmPassError != null) ok = false;
      } else {
        _newPassError = null;
        _confirmPassError = null;
      }
    });
    return ok;
  }

  // ── Save ────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    final response = await ApiService.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      image: _pickedImage,
    );

    if (response['error'] != null) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'])),
      );
      return;
    }

    // Use the newly uploaded image URL, or fall back to the existing one
    // if the user saved without picking a new photo.
    final imageUrl = response['image'] != null
        ? '${ApiService.baseUrl}/${response['image']}'
        : SessionService.currentUser?.image;

    final updatedUser = UserModel(
      id: SessionService.currentUser!.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: SessionService.currentUser!.role,
      token: SessionService.currentUser!.token,
      image: imageUrl,
      latitude: SessionService.currentUser!.latitude,
      longitude: SessionService.currentUser!.longitude,
    );

    await SessionService.saveUser(updatedUser);

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile saved successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.pop(context);
  }

  // ── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final genderOptions = ['Male', 'Female'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: TextStyle(color: context.text, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile photo ──────────────────────────────
            Center(
              child: Stack(children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2.5),
                      color: context.card,
                    ),
                    child: ClipOval(
                      child: _pickedImage != null
                          ? Image.file(
                              _pickedImage!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            )
                          : (SessionService.currentUser?.image != null
                              ? Image.network(
                                  SessionService.currentUser!.image!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  size: 52,
                                  color: AppColors.grey,
                                )),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Tap to change photo',
                  style: TextStyle(color: AppColors.grey, fontSize: 13)),
            ),
            const SizedBox(height: 28),

            // ── Full name ──────────────────────────────────
            _label(context, 'Full Name'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                errorText: _nameError,
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: AppColors.grey, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // ── Email ──────────────────────────────────────
            _label(context, 'Email'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                errorText: _emailError,
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppColors.grey, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // ── National ID ────────────────────────────────
            _label(context, 'National ID'),
            TextField(
              controller: _nationalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              decoration: InputDecoration(
                hintText: '14-digit national ID',
                errorText: _nationalError,
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: AppColors.grey, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // ── Gender ─────────────────────────────────────
            _label(context, 'Gender'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _genderIndex,
                  isExpanded: true,
                  dropdownColor: context.card,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.grey),
                  items: List.generate(
                    genderOptions.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(genderOptions[i],
                          style: TextStyle(color: context.text)),
                    ),
                  ),
                  onChanged: (v) => setState(() => _genderIndex = v!),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Change password section ────────────────────
            Row(children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Change Password',
                  style: TextStyle(
                    color: context.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
            const SizedBox(height: 6),
            Text('Leave blank to keep your current password',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: 16),

            _label(context, 'Current Password'),
            TextField(
              controller: _oldPassController,
              obscureText: _obscureOld,
              decoration: InputDecoration(
                hintText: 'Enter current password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.grey, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOld
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label(context, 'New Password'),
            TextField(
              controller: _newPassController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                errorText: _newPassError,
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.grey, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label(context, 'Confirm New Password'),
            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConf,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                errorText: _confirmPassError,
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.grey, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConf
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConf = !_obscureConf),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── Save button ────────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 32),
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
