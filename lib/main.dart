import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_scope.dart';
import 'core/config.dart';
import 'core/network/api_client.dart';
import 'core/network/token_store.dart';
import 'core/reminders.dart';
import 'core/social_sign_in.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/api_repository.dart';
import 'data/mock_repository.dart';
import 'data/repository.dart';
import 'features/auth/auth_screens.dart';
import 'features/shell/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // On web, `?tab=1` opens a tab directly (handy for previews and screenshots).
  final tab = kIsWeb
      ? int.tryParse(Uri.base.queryParameters['tab'] ?? '')
      : null;

  final NurseRepository repository;
  final AuthController auth;
  final SocialSignIn social;
  final ReminderService reminders = LocalReminderService();
  if (AppConfig.demoMode) {
    final mock = MockRepository();
    repository = mock;
    auth = AuthController(MockAuthService(mock));
    social = FakeSocialSignIn();
  } else {
    social = PlatformSocialSignIn();
    final api = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokens: SecureTokenStore(),
    );
    repository = ApiRepository(api);
    auth = AuthController(ApiAuthService(api));
    api.onSessionExpired = auth.sessionExpired;
  }
  runApp(
    NurseCompanionApp(
      repository: repository,
      auth: auth,
      social: social,
      reminders: reminders,
      initialTab: (tab ?? 0).clamp(0, 3),
    ),
  );
}

class NurseCompanionApp extends StatefulWidget {
  const NurseCompanionApp({
    super.key,
    required this.repository,
    required this.auth,
    required this.social,
    required this.reminders,
    this.initialTab = 0,
    this.today,
  });

  final NurseRepository repository;
  final AuthController auth;
  final SocialSignIn social;
  final ReminderService reminders;
  final int initialTab;

  /// Fixed clock for tests and screenshots; defaults to the device clock.
  final DateTime Function()? today;

  @override
  State<NurseCompanionApp> createState() => _NurseCompanionAppState();
}

class _NurseCompanionAppState extends State<NurseCompanionApp> {
  final _sync = DataSync();
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.auth.restore();
  }

  @override
  void dispose() {
    _sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: widget.repository,
      auth: widget.auth,
      sync: _sync,
      today: widget.today ?? DateTime.now,
      social: widget.social,
      reminders: widget.reminders,
      child: MaterialApp(
        title: 'Nurse Companion',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigator,
        theme: AppTheme.light(),
        home: AuthGate(
          auth: widget.auth,
          navigator: _navigator,
          initialTab: widget.initialTab,
        ),
      ),
    );
  }
}

/// Shows the welcome flow or the app depending on the session.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.navigator,
    required this.initialTab,
  });

  final AuthController auth;
  final GlobalKey<NavigatorState> navigator;
  final int initialTab;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  SessionStatus? _last;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuth);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuth);
    super.dispose();
  }

  void _onAuth() {
    final status = widget.auth.status;
    // Any change of session (sign in, sign out, expiry) clears pushed pages.
    if (_last != null && status != _last) {
      widget.navigator.currentState?.popUntil((r) => r.isFirst);
    }
    _last = status;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (widget.auth.status) {
      SessionStatus.unknown => const _Splash(),
      SessionStatus.signedOut => WelcomeScreen(
        notice: widget.auth.signedOutReason,
      ),
      SessionStatus.signedIn => AppShell(initialTab: widget.initialTab),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(key: ValueKey(widget.auth.status), child: child),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Icon(
        Icons.health_and_safety_rounded,
        size: 64,
        color: AppColors.lavenderDeep,
      ),
    ),
  );
}
