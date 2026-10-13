import 'package:flutter/foundation.dart';

/// Build-time configuration via `--dart-define`:
///
///   flutter run --dart-define=API_BASE_URL=https://api.example.lk
///   flutter run --dart-define=DEMO_MODE=true        (no backend, sample data)
abstract final class AppConfig {
  static const _apiOverride = String.fromEnvironment('API_BASE_URL');
  static const demoMode = bool.fromEnvironment('DEMO_MODE');

  /// Google sign-in: the OAuth *Web* client ID (must also be in the API's GOOGLE_CLIENT_IDS),
  /// and on iOS the iOS client ID. Empty = Google button hidden.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// `--dart-define=QUICK_LOGIN=true|false` forces the quick test logins on or off.
  static const _quickLoginOverride = String.fromEnvironment('QUICK_LOGIN');

  /// One-tap test accounts on the sign-in screen. On in demo mode and in debug/profile
  /// builds that talk to a local API (localhost, emulator or LAN); never in a release
  /// build against a real server unless forced.
  static bool get quickLogin {
    if (_quickLoginOverride.isNotEmpty) return _quickLoginOverride == 'true';
    if (demoMode) return true;
    if (kReleaseMode) return false;
    return isLocalHost(Uri.tryParse(apiBaseUrl)?.host ?? '');
  }

  static bool isLocalHost(String host) {
    if (host == 'localhost' || host.endsWith('.local')) return true;
    final p = host.split('.').map(int.tryParse).toList();
    if (p.length != 4 || p.contains(null)) return false;
    final (a, b) = (p[0]!, p[1]!);
    return a == 127 ||
        a == 10 ||
        (a == 192 && b == 168) ||
        (a == 172 && b >= 16 && b <= 31);
  }

  /// Defaults point at a locally running sl-nurse-api. The Android emulator reaches
  /// the host machine through 10.0.2.2, not localhost.
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _apiOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }
}
