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
