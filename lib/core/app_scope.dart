import 'package:flutter/widgets.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'device_prefs.dart';
import 'reminders.dart';
import 'social_sign_in.dart';

enum SessionStatus { unknown, signedOut, signedIn }

/// Owns the signed-in user. Screens read it through [AppScope].
class AuthController extends ChangeNotifier {
  AuthController(this._auth);

  final AuthService _auth;

  SessionStatus status = SessionStatus.unknown;
  UserProfile? user;

  /// Set when the session ended on its own (e.g. refresh token revoked), to tell the user why.
  String? signedOutReason;

  /// True for the rest of the session after sign-up, so the dashboard greets the new nurse.
  bool isNewUser = false;

  /// Social providers both this device and the API support (loaded by the sign-in screens).
  Set<SignInProvider> serverProviders = const {};

  Future<void> loadProviders() async {
    serverProviders = await _auth.enabledProviders();
    notifyListeners();
  }

  Future<void> restore() async {
    try {
      user = await _auth.restore();
    } catch (_) {
      // Offline at launch: there is no cached data, so ask to sign in again.
      user = null;
    }
    status = user == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    notifyListeners();
  }

  Future<void> login(String emailOrPhone, String password) async =>
      _apply(await _auth.login(emailOrPhone, password));

  Future<void> register(RegisterRequest request) async =>
      _apply(await _auth.register(request));

  /// Google / Apple: returns false if the nurse cancelled the provider's sheet.
  Future<bool> signInWith(SocialSignIn social, SignInProvider provider) async {
    final credential = await social.signIn(provider);
    if (credential == null) return false;
    _apply(
      await _auth.signInWithProvider(
        provider,
        credential.idToken,
        fullName: credential.fullName,
      ),
    );
    return true;
  }

  void _apply(AuthResult result) {
    user = result.user;
    isNewUser = result.isNewUser;
    _signedIn();
  }

  Future<void> logout() async {
    await _auth.logout();
    _signedOut(null);
  }

  /// Called by the API client when a refresh fails.
  void sessionExpired() {
    if (status == SessionStatus.signedIn) {
      _signedOut('Your session has expired. Please sign in again.');
    }
  }

  void updateUser(UserProfile updated) {
    user = updated;
    notifyListeners();
  }

  void _signedIn() {
    signedOutReason = null;
    status = SessionStatus.signedIn;
    notifyListeners();
  }

  void _signedOut(String? reason) {
    user = null;
    isNewUser = false;
    signedOutReason = reason;
    status = SessionStatus.signedOut;
    notifyListeners();
  }
}

/// Bumped after every write so open screens reload their data.
class DataSync extends ChangeNotifier {
  int revision = 0;

  void changed() {
    revision++;
    notifyListeners();
  }
}

/// Dependency scope for the whole app.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.auth,
    required this.sync,
    required this.today,
    required this.social,
    required this.reminders,
    required this.prefs,
    required super.child,
  });

  final NurseRepository repository;
  final AuthController auth;
  final DataSync sync;

  /// "Today" for the whole UI; injectable so tests and demos are deterministic.
  final DateTime Function() today;

  /// Google / Apple sign-in on the device.
  final SocialSignIn social;

  /// Local shift reminders (offered after the first check-in).
  final ReminderService reminders;

  /// Per-device memory: welcome seen, last sign-in id.
  final DevicePrefs prefs;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above $context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      repository != old.repository || auth != old.auth || sync != old.sync;
}
