import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../data/models.dart';
import 'config.dart';

/// What the device hands back after a successful Google / Apple sign-in.
class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.fullName,
  });

  final SignInProvider provider;

  /// Verified by the API against the provider's keys; never trusted on the device.
  final String idToken;

  /// Apple shares the name only on the very first sign-in, and never inside the token.
  final String? fullName;
}

/// Obtains provider ID tokens on the device. Faked in tests and demo mode.
abstract interface class SocialSignIn {
  /// Whether this device/build can offer [provider] at all (plugin + configuration).
  bool supports(SignInProvider provider);

  /// Returns null when the nurse cancels.
  Future<SocialCredential?> signIn(SignInProvider provider);

  Future<void> signOut();
}

class PlatformSocialSignIn implements SocialSignIn {
  bool _googleReady = false;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  bool supports(SignInProvider provider) => switch (provider) {
    // The web needs Google's rendered button instead of authenticate(); mobile only here.
    SignInProvider.google =>
      _isMobile && AppConfig.googleServerClientId.isNotEmpty,
    // Native Sign in with Apple is iOS-only (Android would need a web redirect flow).
    SignInProvider.apple =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
  };

  @override
  Future<SocialCredential?> signIn(SignInProvider provider) =>
      provider == SignInProvider.google ? _google() : _apple();

  Future<SocialCredential?> _google() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        serverClientId: AppConfig.googleServerClientId,
        clientId: AppConfig.googleIosClientId.isEmpty
            ? null
            : AppConfig.googleIosClientId,
      );
      _googleReady = true;
    }
    try {
      final account = await google.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final token = account.authentication.idToken;
      if (token == null) throw StateError('Google did not return an ID token');
      return SocialCredential(
        provider: SignInProvider.google,
        idToken: token,
        fullName: account.displayName,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<SocialCredential?> _apple() async {
    try {
      final c = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.fullName,
          AppleIDAuthorizationScopes.email,
        ],
      );
      final token = c.identityToken;
      if (token == null) {
        throw StateError('Apple did not return an identity token');
      }
      final name = [
        c.givenName,
        c.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      return SocialCredential(
        provider: SignInProvider.apple,
        idToken: token,
        fullName: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }
}

/// Demo mode and tests: pretends the provider handed back a token.
class FakeSocialSignIn implements SocialSignIn {
  FakeSocialSignIn({
    this.cancel = false,
    this.available = SignInProvider.values,
  });

  final bool cancel;
  final List<SignInProvider> available;
  final requested = <SignInProvider>[];

  @override
  bool supports(SignInProvider provider) => available.contains(provider);

  @override
  Future<SocialCredential?> signIn(SignInProvider provider) async {
    requested.add(provider);
    if (cancel) return null;
    return SocialCredential(
      provider: provider,
      idToken: 'fake-${provider.api}-token',
      fullName: 'Dilani Perera',
    );
  }

  @override
  Future<void> signOut() async {}
}
