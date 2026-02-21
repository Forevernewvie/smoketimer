import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
  ];

  static const Locale fallbackLocale = Locale('ko');

  static const Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
        'ko': <String, String>{'settingsTitle': '설정', 'darkModeLabel': '다크 모드'},
        'en': <String, String>{
          'settingsTitle': 'Settings',
          'darkModeLabel': 'Dark Mode',
        },
      };

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(
      localization != null,
      'AppLocalizations not found in context. '
      'Ensure AppLocalizations.delegate is added to localizationsDelegates.',
    );
    return localization!;
  }

  static Locale resolve(Locale? locale) {
    if (locale == null) {
      return fallbackLocale;
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return fallbackLocale;
  }

  String lookup(String key) {
    final languageCode = locale.languageCode;
    final localized = _localizedValues[languageCode]?[key];
    if (localized != null) {
      return localized;
    }

    final fallback = _localizedValues[fallbackLocale.languageCode]?[key];
    if (fallback != null) {
      return fallback;
    }

    // Safe fallback for missing translation keys.
    return key;
  }

  String get settingsTitle => lookup('settingsTitle');
  String get darkModeLabel => lookup('darkModeLabel');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
