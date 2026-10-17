import 'package:flutter/widgets.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'app_settings.dart';
import 'device_prefs.dart';
import 'i18n/i18n.dart';
import 'notices.dart';
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

  /// How the nurse signed in this session (null after a restored session).
  SignInProvider? lastProvider;
  bool usedPassword = false;

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
      _apply(await _auth.login(emailOrPhone, password), password: true);

  Future<void> register(RegisterRequest request) async =>
      _apply(await _auth.register(request), password: true);

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
      provider: provider,
    );
    return true;
  }

  void _apply(
    AuthResult result, {
    SignInProvider? provider,
    bool password = false,
  }) {
    user = result.user;
    isNewUser = result.isNewUser;
    lastProvider = provider;
    usedPassword = password;
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
    required this.settings,
    required this.inbox,
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

  /// Language, clock and notification preferences.
  final AppSettings settings;

  /// Every notification the nurse has had, for the Notifications screen.
  final NoticeInbox inbox;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above $context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      repository != old.repository || auth != old.auth || sync != old.sync;
}

extension ReminderSync on AppScope {
  /// Notification texts in the nurse's language (no BuildContext needed).
  NoticeTr get noticeTr =>
      (text, [args = const {}]) => translate(settings.language, text, args);

  /// Re-plans duty notifications (before start, forgot to start, before the main shift
  /// and OT end) for the next two weeks. They always appear in the in-app list; they
  /// are pushed to the phone only when notifications are on.
  Future<void> rescheduleReminders() async {
    final now = today();
    // From yesterday, so a night duty running into this morning is included.
    final shifts = await repository.shifts(
      from: now.subtract(const Duration(days: 1)),
      to: now.add(const Duration(days: 14)),
    );
    final notices = planDutyNotices(
      shifts,
      now,
      NoticeOptions(
        lead: settings.reminderLead,
        forgotStart: settings.forgotStartAlert,
        endReminders: settings.endReminders,
      ),
      noticeTr,
    );
    await reminders.schedule(notices);
    await inbox.replacePlanned(notices, now);
  }

  /// A one-off notification (day summary, pay details): pushed if notifications are on,
  /// and always kept in the in-app list.
  Future<void> notify(Notice notice) async {
    await inbox.add(notice);
    try {
      await reminders.show(notice);
    } catch (_) {
      // The in-app list still has it.
    }
  }
}
