import 'package:flutter/widgets.dart';

import '../app_settings.dart';
import 'strings_si.dart';
import 'strings_ta.dart';

/// Makes the chosen language available to every screen, and rebuilds them when it changes.
class AppStrings extends InheritedWidget {
  const AppStrings({super.key, required this.language, required super.child});

  final AppLanguage language;

  static AppLanguage languageOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStrings>()?.language ??
      AppLanguage.english;

  @override
  bool updateShouldNotify(AppStrings old) => language != old.language;
}

/// Translations are keyed by the English text, so a screen is translated by wrapping its
/// strings in `context.tr(...)`, and anything not translated yet simply stays in English.
/// Placeholders use braces: `context.tr('Hello {name}', {'name': first})`.
extension Translate on BuildContext {
  String tr(String english, [Map<String, Object?> args = const {}]) =>
      translate(AppStrings.languageOf(this), english, args);
}

String translate(
  AppLanguage language,
  String english, [
  Map<String, Object?> args = const {},
]) {
  var text = switch (language) {
    AppLanguage.english => english,
    AppLanguage.sinhala => sinhalaStrings[english] ?? english,
    AppLanguage.tamil => tamilStrings[english] ?? english,
  };
  args.forEach((key, value) => text = text.replaceAll('{$key}', '$value'));
  return text;
}
