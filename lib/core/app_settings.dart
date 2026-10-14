import 'package:flutter/widgets.dart';

import 'device_prefs.dart';
import 'format.dart';

enum AppLanguage {
  english('en', 'English', 'English'),
  sinhala('si', 'සිංහල', 'Sinhala'),
  tamil('ta', 'தமிழ்', 'Tamil');

  const AppLanguage(this.code, this.nativeName, this.englishName);
  final String code;

  /// The language's own name, so anyone can find theirs.
  final String nativeName;
  final String englishName;

  Locale get locale => Locale(code);

  static AppLanguage parse(String? code) => values.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLanguage.english,
  );
}

/// Per-device app preferences (not tied to the account), saved in [DevicePrefs].
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs)
    : language = AppLanguage.parse(_prefs.read(_languageKey)),
      use24h = _prefs.read(_clockKey) == '24',
      reminderLeadMinutes =
          int.tryParse(_prefs.read(_leadKey) ?? '') ?? defaultReminderLead,
      otAlerts = _prefs.read(_otAlertKey) != 'off' {
    Fmt.use24h = use24h;
  }

  static const _languageKey = 'language';
  static const _clockKey = 'clock';
  static const _leadKey = 'reminderLead';
  static const _otAlertKey = 'otAlerts';

  static const defaultReminderLead = 60;
  static const reminderLeadOptions = [30, 60, 120];

  final DevicePrefs _prefs;

  AppLanguage language;

  /// 24-hour clock ("19:00") instead of "07:00 PM".
  bool use24h;

  /// How long before a rostered shift the reminder fires.
  int reminderLeadMinutes;

  /// "Switched to OT" notification on long duties.
  bool otAlerts;

  Duration get reminderLead => Duration(minutes: reminderLeadMinutes);

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    notifyListeners();
    await _prefs.write(_languageKey, value.code);
  }

  Future<void> setUse24h(bool value) async {
    use24h = value;
    Fmt.use24h = value;
    notifyListeners();
    await _prefs.write(_clockKey, value ? '24' : '12');
  }

  Future<void> setReminderLead(int minutes) async {
    reminderLeadMinutes = minutes;
    notifyListeners();
    await _prefs.write(_leadKey, '$minutes');
  }

  Future<void> setOtAlerts(bool value) async {
    otAlerts = value;
    notifyListeners();
    await _prefs.write(_otAlertKey, value ? 'on' : 'off');
  }
}
