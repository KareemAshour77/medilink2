import 'package:google_sign_in/google_sign_in.dart';
import '../../features/auth/model/user_model.dart';
import 'api_service.dart';

// ── Result types ──────────────────────────────────────────────────────────────

/// Returned when Google verified the token AND the email exists in the DB.
class GoogleSignedIn {
  final UserModel user;
  const GoogleSignedIn(this.user);
}

/// Returned when Google verified the token but the email is NOT in the DB yet.
/// The app should navigate to the sign-up screen with these values pre-filled.
class GoogleNeedsSignUp {
  final String email;
  final String name;
  final String? picture;
  const GoogleNeedsSignUp({
    required this.email,
    required this.name,
    this.picture,
  });
}

/// Returned when the email has several role-accounts → show the role chooser.
class GoogleMultipleAccounts {
  final List<Map<String, dynamic>> accounts;
  const GoogleMultipleAccounts(this.accounts);
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Handles Google Sign-In without Firebase.
///
/// Flow:
///  1. Initialise the GoogleSignIn singleton (once per app lifecycle)
///  2. Sign out any cached account so the picker always shows
///  3. Call authenticate() — throws GoogleSignInException on cancel/error
///  4. Read the ID token (synchronous getter in v7)
///  5. POST the token to the NestJS backend → POST /auth/google
///  5a. Email exists in DB  → backend returns JWT  → [GoogleSignedIn]
///  5b. Email missing in DB → backend returns needsRegistration flag
///                          → [GoogleNeedsSignUp] (go to sign-up screen)
class GoogleAuthService {
  static const _serverClientId =
      '669071522436-pf75utbpug1tqufsbgc4fv5gkkcorc1a.apps.googleusercontent.com';

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Returns:
  ///  • `null`               – user cancelled the picker (no error)
  ///  • [GoogleSignedIn]     – logged in successfully
  ///  • [GoogleNeedsSignUp]  – email not in DB; navigate to sign-up
  ///
  /// Throws a [String] on any other failure.
  static Future<Object?> signInWithGoogle() async {
    await _ensureInitialized();

    // Clear cached account → picker always shows
    await GoogleSignIn.instance.signOut();

    // Open the Google account picker
    GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // user cancelled — not an error
      }
      throw e.description ?? e.toString();
    }

    // Get the ID token (synchronous getter in v7)
    final String? idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw 'Google did not return an ID token. Please try again.';
    }

    // Send to backend
    final Map<String, dynamic> result =
        await ApiService.googleSignIn(idToken: idToken);

    // Connection / server error
    if (result['error'] != null) {
      throw result['error'].toString();
    }

    // Email not registered → go to sign-up
    if (result['needsRegistration'] == true) {
      final data = result['googleData'] as Map<String, dynamic>? ?? {};
      return GoogleNeedsSignUp(
        email: data['email']?.toString() ?? googleUser.email,
        name: data['name']?.toString() ?? googleUser.displayName ?? '',
        picture: data['picture']?.toString() ?? googleUser.photoUrl,
      );
    }

    // Several role-accounts on this email → role chooser
    if (result['accounts'] is List && (result['accounts'] as List).isNotEmpty) {
      final accounts = (result['accounts'] as List)
          .map((a) => (a as Map).cast<String, dynamic>())
          .toList();
      return GoogleMultipleAccounts(accounts);
    }

    // Missing token (unexpected server error)
    if (result['access_token'] == null) {
      throw result['message']?.toString() ?? 'Google sign-in failed';
    }

    // Successful login → build UserModel
    final responseUser = result['user'] as Map<String, dynamic>?;
    final user = UserModel.fromJson({
      'id': responseUser?['id'],
      'name': responseUser?['name'] ?? googleUser.displayName ?? '',
      'email': responseUser?['email'] ?? googleUser.email,
      'role': responseUser?['role'] ?? 'patient',
      'image': responseUser?['image'] ?? googleUser.photoUrl,
      'access_token': result['access_token'],
    });
    return GoogleSignedIn(user);
  }

  /// Signs the user out of Google on this device.
  static Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
