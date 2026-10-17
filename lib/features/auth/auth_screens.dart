import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_waves.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pastel_card.dart';
import '../../data/models.dart';
import '../roster/roster_widgets.dart';
import 'quick_login.dart';
import '../../core/i18n/i18n.dart';

/* ------------------------------------------------------------------ *
 * Welcome (reference: "Your passport to fitness success")
 * ------------------------------------------------------------------ */
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.notice});

  /// e.g. "Your session has expired".
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            // The actions are pinned to the bottom, so Get Started is always one tap
            // away whatever the screen size; the story scrolls above them.
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                      AppSpacing.screenPadding,
                      8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Nurse Companion',
                              style: text.titleMedium?.copyWith(
                                color: AppColors.lavenderDeep,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: LogoColors.charcoal.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const AppLogo(size: 172),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.tr('Your companion\nfor every shift'),
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            fontSize: 30,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Track duties and OT, scan your roster, and see what this month\'s salary will be. All in one place.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        const _Highlights(),
                        if (notice != null) ...[
                          const SizedBox(height: 16),
                          PastelCard(
                            color: AppColors.peach,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              notice!,
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    8,
                    AppSpacing.screenPadding,
                    8,
                  ),
                  child: const _WelcomeActions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three things the app does for a busy nurse, as compact rows.
class _Highlights extends StatelessWidget {
  const _Highlights();

  static const _items = [
    (
      icon: Icons.touch_app_rounded,
      color: AppColors.lavender,
      text:
          'One tap to start a duty. OT switches on by itself on D and 24 duties',
    ),
    (
      icon: Icons.document_scanner_rounded,
      color: AppColors.sky,
      text: 'Snap your ward roster and the whole month is filled in',
    ),
    (
      icon: Icons.payments_rounded,
      color: AppColors.mint,
      text: 'Know your salary, OT and night allowance before payday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 19, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(item.text),
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/* ------------------------------------------------------------------ *
 * Shared form plumbing
 * ------------------------------------------------------------------ */
abstract final class Validators {
  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// Mirrors the API: 8–72 chars with a letter and a number.
  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'At least 8 characters';
    if (s.length > 72) return 'At most 72 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  static String? slPhone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^(?:\+94|94|0)\d{9}$').hasMatch(s)
        ? null
        : 'e.g. 077 123 4567';
  }

  /// One box for either: "@" means email, otherwise a Sri Lankan mobile number.
  static String? emailOrPhone(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter your email or mobile number';
    return s.contains('@')
        ? email(s)
        : (slPhone(s) == null
              ? null
              : 'Enter an email or a mobile like 077 123 4567');
  }

  static String? required(String? v) =>
      (v ?? '').trim().length < 2 ? 'Required' : null;
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: BackgroundWaves(
        child: SafeArea(
          child: ResponsiveContent(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Pushed from the welcome screen: back. Shown as the start page: brand.
                if (!(ModalRoute.of(context)?.isFirst ?? true))
                  const PageHeader(title: '')
                else
                  Row(
                    children: [
                      const AppLogo(size: 30),
                      const SizedBox(width: 8),
                      Text(
                        'Nurse Companion',
                        style: text.titleMedium?.copyWith(
                          color: AppColors.lavenderDeep,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Text(title, style: text.headlineMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: text.bodyMedium),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: const TextStyle(fontSize: 15)),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: PastelCard(
      color: AppColors.peach,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.peachDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

/* ------------------------------------------------------------------ *
 * Google / Apple: the primary, one-tap path
 * ------------------------------------------------------------------ */

/// Social sign-in buttons shown when both the device build and the API support them.
/// Lays out nothing when no provider is available, so the email/mobile form leads.
/// Whether Google sign-in can be offered: supported on this device and accepted by the API.
bool googleAvailable(AppScope scope) =>
    scope.social.supports(SignInProvider.google) &&
    scope.auth.serverProviders.contains(SignInProvider.google);

/// Google's sign-in button: white, with the multicolour G (per Google's brand guidance).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.label});

  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          elevation: 1,
          shadowColor: Colors.black26,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleMark(),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label ?? context.tr('Continue with Google'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Get Started actions. With Google available it leads (one tap, no password to
/// remember); email or mobile follows as the alternative.
class _WelcomeActions extends StatefulWidget {
  const _WelcomeActions();

  @override
  State<_WelcomeActions> createState() => _WelcomeActionsState();
}

class _WelcomeActionsState extends State<_WelcomeActions> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).auth.loadProviders();
    });
  }

  Future<void> _google() async {
    final scope = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await scope.auth.signInWith(scope.social, SignInProvider.google);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : context.tr(
                  'Google sign-in didn\'t work. Please try again or use your email/mobile.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.auth,
      builder: (context, _) {
        final google = googleAvailable(scope);
        final getStarted = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                google
                    ? context.tr('Use email or mobile')
                    : context.tr('Get Started'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        );
        return Column(
          children: [
            if (_error != null) _ErrorBanner(_error!),
            if (google) ...[
              GoogleButton(onPressed: _busy ? null : _google),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: google
                  ? OutlinedButton(
                      key: const ValueKey('get-started'),
                      onPressed: _busy ? null : () => _open(LoginScreen()),
                      child: getStarted,
                    )
                  : FilledButton(
                      key: const ValueKey('get-started'),
                      onPressed: () => _open(LoginScreen()),
                      child: getStarted,
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => _open(const RegisterScreen()),
              child: Text(context.tr('New here? Create an account')),
            ),
          ],
        );
      },
    );
  }
}

class _SocialButtons extends StatefulWidget {
  const _SocialButtons({
    required this.busy,
    required this.onBusy,
    required this.onError,
  });

  final bool busy;
  final ValueChanged<bool> onBusy;
  final ValueChanged<String?> onError;

  @override
  State<_SocialButtons> createState() => _SocialButtonsState();
}

class _SocialButtonsState extends State<_SocialButtons> {
  @override
  void initState() {
    super.initState();
    // Ask the API which providers it accepts (it needs client IDs configured).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).auth.loadProviders();
    });
  }

  Future<void> _signIn(SignInProvider provider) async {
    final scope = AppScope.of(context);
    widget.onBusy(true);
    widget.onError(null);
    try {
      final done = await scope.auth.signInWith(scope.social, provider);
      if (done && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      widget.onError(
        e is ApiException
            ? e.message
            : '${provider.label} sign-in didn\'t work. Please try again or use your email/mobile.',
      );
    } finally {
      if (mounted) widget.onBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.auth,
      builder: (context, _) {
        final providers = [
          for (final p in SignInProvider.values)
            if (scope.social.supports(p) &&
                scope.auth.serverProviders.contains(p))
              p,
        ];
        if (providers.isEmpty) return const SizedBox.shrink();
        final lastWasGoogle =
            scope.prefs.read('signInMethod') == SignInProvider.google.api;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (providers.contains(SignInProvider.google))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: AppColors.mintDeep,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lastWasGoogle
                            ? context.tr('You used Google last time')
                            : context.tr('Fastest: one tap, no password'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mintDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            for (final p in providers) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: p == SignInProvider.apple
                    ? FilledButton.icon(
                        onPressed: widget.busy ? null : () => _signIn(p),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.apple, size: 22),
                        label: Text(
                          context.tr('Continue with Apple'),
                          style: TextStyle(fontSize: 15),
                        ),
                      )
                    : GoogleButton(
                        onPressed: widget.busy ? null : () => _signIn(p),
                      ),
              ),
              const SizedBox(height: 10),
            ],
            const _OrDivider(),
          ],
        );
      },
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

/* ------------------------------------------------------------------ *
 * Login
 * ------------------------------------------------------------------ */
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key, this.notice, bool? showQuickLogin})
    : showQuickLogin = showQuickLogin ?? AppConfig.quickLogin;

  /// e.g. "Your session has expired".
  final String? notice;

  /// One-tap seeded test accounts (local and demo builds only).
  final bool showQuickLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Returning on this device: the id is filled in and only the password is needed.
  bool _remembered = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final last = AppScope.of(context).prefs.lastLoginId;
    if (last.isNotEmpty) {
      _id.text = last;
      _remembered = true;
    }
  }

  /// Signs in as a seeded test account with one tap.
  void _quickLogin(QuickLoginAccount account) {
    _id.text = account.email;
    _password.text = QuickLogin.password;
    _submit();
  }

  void _forgetId() {
    setState(() {
      _remembered = false;
      _id.clear();
      _password.clear();
    });
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).auth.login(_id.text.trim(), _password.text);
      // The root swaps to the app shell; drop the auth pages.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _AuthScaffold(
      title: context.tr('Welcome back'),
      subtitle: _remembered
          ? context.tr('Enter your password to continue.')
          : context.tr('Sign in to see your shifts and salary.'),
      child: Column(
        children: [
          if (widget.showQuickLogin)
            QuickLoginStrip(onPick: _quickLogin, busy: _busy),
          if (widget.notice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PastelCard(
                color: AppColors.peach,
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.notice!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          if (_error != null) _ErrorBanner(_error!),
          _SocialButtons(
            busy: _busy,
            onBusy: (b) => setState(() => _busy = b),
            onError: (e) => setState(() => _error = e),
          ),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                children: [
                  TextFormField(
                    controller: _id,
                    // A returning nurse goes straight to the password.
                    autofocus: !_remembered,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.telephoneNumber,
                    ],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: context.tr('Email or mobile'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      suffixIcon: _remembered
                          ? TextButton(
                              onPressed: _forgetId,
                              child: Text(context.tr('Not you?')),
                            )
                          : null,
                    ),
                    validator: (v) =>
                        context.trOrNull(Validators.emailOrPhone(v)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    autofocus: _remembered,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.tr('Password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? context.tr('Show password')
                            : context.tr('Hide password'),
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => (v ?? '').isEmpty
                        ? context.tr('Enter your password')
                        : null,
                  ),
                  const SizedBox(height: 22),
                  _SubmitButton(
                    label: context.tr('Sign in'),
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final route = MaterialPageRoute<void>(
                builder: (_) => const RegisterScreen(),
              );
              // As the start page, sign-in stays underneath; pushed, it is replaced.
              final nav = Navigator.of(context);
              (ModalRoute.of(context)?.isFirst ?? true)
                  ? nav.push(route)
                  : nav.pushReplacement(route);
            },
            child: Text(context.tr('New here? Create an account')),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ *
 * Register: one tap with Google/Apple, or three quick fields
 * ------------------------------------------------------------------ */
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = const {});
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.of(context).auth.register(
        RegisterRequest(
          fullName: _name.text.trim(),
          emailOrPhone: _contact.text.trim(),
          password: _password.text,
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      // The API reports email/phone separately; both map to the single contact box.
      final errors = {
        for (final entry in e.fieldErrors.entries)
          (entry.key == 'email' || entry.key == 'phone')
                  ? 'contact'
                  : entry.key:
              entry.value,
      };
      setState(() {
        _serverErrors = errors;
        _error = errors.isEmpty ? e.message : null;
      });
      _form.currentState!.validate();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _AuthScaffold(
      title: context.tr('Create your account'),
      subtitle: context.tr(
        'Takes 10 seconds. Pay and ward details can wait until you need them.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(_error!),
          _SocialButtons(
            busy: _busy,
            onBusy: (b) => setState(() => _busy = b),
            onError: (e) => setState(() => _error = e),
          ),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: context.tr('Your name'),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) =>
                        _serverErrors['fullName'] ??
                        context.trOrNull(Validators.required(v)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contact,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.telephoneNumber,
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: context.tr('Email or mobile'),
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) =>
                        _serverErrors['contact'] ??
                        context.trOrNull(Validators.emailOrPhone(v)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.tr('Password'),
                      helperText: '8+ characters with letters and numbers',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? context.tr('Show password')
                            : context.tr('Hide password'),
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        _serverErrors['password'] ??
                        context.trOrNull(Validators.password(v)),
                  ),
                  const SizedBox(height: 22),
                  _SubmitButton(
                    label: context.tr('Create account'),
                    busy: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'No salary or ward details needed now: we\'ll ask only when a feature needs them.',
            ),
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () {
                final nav = Navigator.of(context);
                // Sign-in is already the start page underneath: just go back to it.
                if (AppScope.of(context).prefs.welcomeSeen) {
                  nav.pop();
                } else {
                  nav.pushReplacement(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                }
              },
              child: Text(context.tr('Already registered? Sign in')),
            ),
          ),
        ],
      ),
    );
  }
}
