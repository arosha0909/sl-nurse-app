import 'package:shared_preferences/shared_preferences.dart';

/// What this device remembers between launches so a returning nurse gets in fast:
/// the welcome screen is shown only until the first sign-in, and the sign-in screen
/// comes back with the last email or mobile already filled in.
abstract interface class DevicePrefs {
  bool get welcomeSeen;

  /// Email or mobile of the last account signed in on this device ('' if none).
  String get lastLoginId;

  Future<void> markWelcomeSeen();
  Future<void> rememberLoginId(String id);

  /// The first-run app guide has been shown (finished or skipped) on this device.
  bool get guideSeen;
  Future<void> markGuideSeen();

  /// App settings (see AppSettings); null when never set.
  String? read(String key);
  Future<void> write(String key, String value);
}

class SharedDevicePrefs implements DevicePrefs {
  SharedDevicePrefs._(this._prefs);

  static const _welcomeKey = 'device.welcomeSeen';
  static const _loginIdKey = 'device.lastLoginId';
  static const _guideKey = 'device.guideSeen';

  final SharedPreferences _prefs;

  /// Loaded before the first frame so the app opens on the right screen without a flash.
  /// Falls back to memory if storage is unavailable.
  static Future<DevicePrefs> load() async {
    try {
      return SharedDevicePrefs._(await SharedPreferences.getInstance());
    } catch (_) {
      return MemoryDevicePrefs();
    }
  }

  @override
  bool get welcomeSeen => _prefs.getBool(_welcomeKey) ?? false;

  @override
  String get lastLoginId => _prefs.getString(_loginIdKey) ?? '';

  @override
  Future<void> markWelcomeSeen() async {
    if (!welcomeSeen) await _prefs.setBool(_welcomeKey, true);
  }

  @override
  Future<void> rememberLoginId(String id) async {
    if (id.isNotEmpty && id != lastLoginId) {
      await _prefs.setString(_loginIdKey, id);
    }
  }

  @override
  bool get guideSeen => _prefs.getBool(_guideKey) ?? false;

  @override
  Future<void> markGuideSeen() => _prefs.setBool(_guideKey, true);

  @override
  String? read(String key) => _prefs.getString('settings.$key');

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString('settings.$key', value);
}

/// Tests, demo mode and devices without storage.
class MemoryDevicePrefs implements DevicePrefs {
  MemoryDevicePrefs({
    this.welcomeSeen = false,
    this.lastLoginId = '',
    this.guideSeen = false,
  });

  @override
  bool guideSeen;

  @override
  Future<void> markGuideSeen() async => guideSeen = true;

  @override
  bool welcomeSeen;

  @override
  String lastLoginId;

  @override
  Future<void> markWelcomeSeen() async => welcomeSeen = true;

  @override
  Future<void> rememberLoginId(String id) async {
    if (id.isNotEmpty) lastLoginId = id;
  }

  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
