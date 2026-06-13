import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/in_app_notification_store.dart';
import '../../../core/services/session_service.dart';
import '../../../core/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../model/user_model.dart';
import 'email_verification_screen.dart';

/// In-app entry point: fetch every account on the logged-in user's email and
/// open the chooser so they can switch to (or verify) a sibling account.
Future<void> openAccountSwitcher(BuildContext context) async {
  final res = await ApiService.myAccounts();
  if (!context.mounted) return;
  final list = res['accounts'];
  if (list is! List || list.length <= 1) {
    AppSnackBar.show(context, 'No other accounts on this email.');
    return;
  }
  final accounts =
      list.map((a) => (a as Map).cast<String, dynamic>()).toList();
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => RoleChooserScreen(accounts: accounts)),
  );
}

/// Shown after login/Google when one email has several role-accounts.
/// Picking one saves that account's session and enters its home.
class RoleChooserScreen extends StatefulWidget {
  /// Each map is a backend account: {id, name, email, role, image,
  /// verification_status, access_token}.
  final List<Map<String, dynamic>> accounts;

  const RoleChooserScreen({super.key, required this.accounts});

  @override
  State<RoleChooserScreen> createState() => _RoleChooserScreenState();
}

class _RoleChooserScreenState extends State<RoleChooserScreen> {
  bool _busy = false;

  Future<void> _choose(Map<String, dynamic> account) async {
    if (_busy) return;
    setState(() => _busy = true);

    final user = UserModel.fromJson({
      ...account,
      'access_token': account['access_token'],
    });

    await SessionService.clear();
    await SessionService.save(user);
    await InAppNotificationStore.instance.loadFromServer();
    ChatService.instance.connect().catchError((_) {});
    FcmService.instance.uploadToken().catchError((_) {});

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleRouter()),
      (_) => false,
    );
  }

  // A pending (email-unverified) account: auto-send a fresh code, open the OTP
  // screen, and on success mark this account verified in place — staying on the
  // chooser so the user can now pick it.
  Future<void> _verifyPending(Map<String, dynamic> account) async {
    if (_busy) return;
    final email = (account['email'] ?? '').toString();
    final role = (account['role'] ?? '').toString();

    setState(() => _busy = true);
    await ApiService.sendVerificationCode(email: email, role: role);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(
          email: email,
          role: role,
          popOnSuccess: true,
        ),
      ),
    );

    if (!mounted || result == null) return;
    if (result['access_token'] != null) {
      setState(() {
        account['email_verified'] = true;
        account['access_token'] = result['access_token'];
        final u = result['user'];
        if (u is Map) {
          account['verification_status'] = u['verification_status'];
          account['image'] ??= u['image'];
        }
      });
      AppSnackBar.show(context, 'Account verified — you can now use it.',
          backgroundColor: Colors.green);
    }
  }

  ({IconData icon, String label, String asset}) _roleMeta(
      String role, bool isDark) {
    final shade = isDark ? 'white' : 'black';
    switch (role.toLowerCase()) {
      case 'doctor':
        return (
          icon: Icons.medical_services_rounded,
          label: 'Doctor',
          asset: 'assets/images/doctor $shade.png',
        );
      case 'pharmacy':
        return (
          icon: Icons.local_pharmacy_rounded,
          label: 'Pharmacy',
          asset: 'assets/images/pharmacy $shade.png',
        );
      case 'lab':
      case 'radiology':
        return (
          icon: Icons.biotech_rounded,
          label: 'Lab',
          asset: 'assets/images/lab $shade.png',
        );
      default:
        return (
          icon: Icons.person_rounded,
          label: 'Patient',
          asset: 'assets/images/user $shade.png',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Choose account', style: TextStyle(color: context.text)),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Continue as',
                style: TextStyle(
                    color: context.text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('This email has more than one account. Pick the one you want to use.',
                style: TextStyle(color: AppColors.grey, fontSize: 13.5)),
            const SizedBox(height: 20),
            ...widget.accounts.map(_accountCard),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(Map<String, dynamic> account) {
    final role = (account['role'] ?? '').toString();
    final meta = _roleMeta(role, context.isDark);
    final isDoctor = role.toLowerCase() == 'doctor';
    final rawName = (account['name'] ?? '').toString();
    final name = (isDoctor && rawName.isNotEmpty) ? 'Dr. $rawName' : rawName;
    final image = account['image']?.toString();
    final imageUrl = (image != null && image.isNotEmpty)
        ? (image.startsWith('http') ? image : '${ApiService.baseUrl}/$image')
        : null;
    final verified = account['email_verified'] != false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => verified ? _choose(account) : _verifyPending(account),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.divider),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 52,
                color: AppColors.primary.withOpacity(0.10),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(meta.asset, fit: BoxFit.contain),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(meta.asset, fit: BoxFit.contain),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta.label,
                      style: TextStyle(
                          color: context.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  if (name.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 13)),
                  ],
                  if (!verified) ...[
                    const SizedBox(height: 6),
                    _pendingBadge(),
                  ],
                ],
              ),
            ),
            verified
                ? const Icon(Icons.chevron_right_rounded,
                    color: AppColors.grey)
                : const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.warning),
          ]),
        ),
      ),
    );
  }

  Widget _pendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Tap to verify email',
          style: TextStyle(
              color: AppColors.warning,
              fontSize: 11.5,
              fontWeight: FontWeight.w700)),
    );
  }
}
