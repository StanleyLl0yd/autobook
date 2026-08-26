import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  const AppLocalizations(this.locale, this._values);

  final Locale locale;
  final Map<String, String> _values;

  static const supportedLocales = <Locale>[Locale('ru'), Locale('en')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(result != null, 'AppLocalizations is not available in this context');
    return result!;
  }

  String text(String key, [Map<String, Object> parameters = const {}]) {
    var value = _values[key] ?? key;
    for (final entry in parameters.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return value;
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final languageCode = supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    )
        ? locale.languageCode
        : 'en';
    final raw = await rootBundle.loadString(
      'lib/l10n/app_$languageCode.arb',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final values = <String, String>{};
    for (final entry in json.entries) {
      if (!entry.key.startsWith('@') && entry.value is String) {
        values[entry.key] = entry.value as String;
      }
    }
    return AppLocalizations(Locale(languageCode), values);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

