import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nurse_companion/core/app_settings.dart';
import 'package:nurse_companion/core/i18n/i18n.dart';
import 'package:nurse_companion/core/i18n/strings_si.dart';
import 'package:nurse_companion/core/i18n/strings_si_more.dart';
import 'package:nurse_companion/core/i18n/strings_ta.dart';
import 'package:nurse_companion/core/i18n/strings_ta_more.dart';

final _sinhala = {...sinhalaStrings, ...sinhalaStringsMore};
final _tamil = {...tamilStrings, ...tamilStringsMore};

/// Every literal passed to context.tr(...) in lib/.
Set<String> translatedLiterals() {
  final re = RegExp(r"""tr\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""");
  final keys = <String>{};
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart') || f.path.contains('i18n')) {
      continue;
    }
    for (final m in re.allMatches(f.readAsStringSync())) {
      keys.add(
        (m.group(1) ?? m.group(2)!)
            .replaceAll(r"\'", "'")
            .replaceAll(r'\n', '\n'),
      );
    }
  }
  return keys;
}

void main() {
  test('every translated text has Sinhala and Tamil versions', () {
    final keys = translatedLiterals();
    expect(keys, isNotEmpty);
    expect(keys.difference(_sinhala.keys.toSet()), isEmpty);
    expect(keys.difference(_tamil.keys.toSet()), isEmpty);
    // The two parts never define the same text twice.
    expect(
      sinhalaStrings.keys.toSet().intersection(sinhalaStringsMore.keys.toSet()),
      isEmpty,
    );
    expect(
      tamilStrings.keys.toSet().intersection(tamilStringsMore.keys.toSet()),
      isEmpty,
    );
    // Sinhala and Tamil cover the same texts.
    expect(_sinhala.keys.toSet(), _tamil.keys.toSet());
  });

  test('translations keep their placeholders', () {
    final placeholder = RegExp(r'\{\w+\}');
    for (final table in [_sinhala, _tamil]) {
      for (final e in table.entries) {
        final want = placeholder.allMatches(e.key).map((m) => m[0]).toSet();
        final got = placeholder.allMatches(e.value).map((m) => m[0]).toSet();
        expect(got, want, reason: e.key);
      }
    }
  });

  test('falls back to English and fills placeholders', () {
    expect(
      translate(AppLanguage.sinhala, 'Not translated yet'),
      'Not translated yet',
    );
    expect(
      translate(AppLanguage.tamil, 'Hello Nurse {name},', {'name': 'Kasun'}),
      'வணக்கம் தாதி Kasun,',
    );
  });
}
