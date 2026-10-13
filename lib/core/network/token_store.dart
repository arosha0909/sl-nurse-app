import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Where tokens live between app launches.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

/// Keychain (iOS) / EncryptedSharedPreferences-backed Keystore (Android) / WebCrypto (web).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _access = 'auth.access';
  static const _refresh = 'auth.refresh';

  @override
  Future<AuthTokens?> read() async {
    try {
      final access = await _storage.read(key: _access);
      final refresh = await _storage.read(key: _refresh);
      if (access == null || refresh == null) return null;
      return AuthTokens(accessToken: access, refreshToken: refresh);
    } catch (_) {
      // Corrupted / inaccessible keystore (e.g. after a device restore): start signed out.
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _access, value: tokens.accessToken);
    await _storage.write(key: _refresh, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}

/// For tests and demo mode.
class MemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
