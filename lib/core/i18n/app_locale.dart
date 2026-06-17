import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale {
  tr,
  tk,
  en,
  ru;

  String get code => name;

  Locale get materialLocale => switch (this) {
        AppLocale.tr => const Locale('tr', 'TR'),
        AppLocale.tk => const Locale('tk', 'TM'),
        AppLocale.en => const Locale('en', 'US'),
        AppLocale.ru => const Locale('ru', 'RU'),
      };

  /// BCP 47 tag used by `intl` for number/currency/date formatting.
  String get numberFormatTag => switch (this) {
        AppLocale.tr => 'tr_TR',
        AppLocale.tk => 'tk_TM',
        AppLocale.en => 'en_US',
        AppLocale.ru => 'ru_RU',
      };

  String get nativeName => switch (this) {
        AppLocale.tr => 'Türkçe',
        AppLocale.tk => 'Türkmençe',
        AppLocale.en => 'English',
        AppLocale.ru => 'Русский',
      };
}

AppLocale? appLocaleFromCode(String? code) {
  if (code == null) return null;
  for (final l in AppLocale.values) {
    if (l.code == code) return l;
  }
  return null;
}

/// Mirrors the web's `fallbackChain` so missing keys degrade gracefully.
const _fallbackChain = <AppLocale, List<AppLocale>>{
  AppLocale.tr: [AppLocale.tr, AppLocale.en],
  AppLocale.tk: [AppLocale.tk, AppLocale.en, AppLocale.tr],
  AppLocale.en: [AppLocale.en, AppLocale.tr],
  AppLocale.ru: [AppLocale.ru, AppLocale.en, AppLocale.tr],
};

class LocaleBundle {
  LocaleBundle(this.locale, this.entries);

  final AppLocale locale;
  final Map<String, String> entries;
}

class LocaleService {
  LocaleService(this._bundles);

  final Map<AppLocale, Map<String, String>> _bundles;

  String translate(AppLocale locale, String key, [Map<String, Object?>? vars]) {
    final chain = _fallbackChain[locale] ?? const [AppLocale.en];
    String raw = key;
    for (final l in chain) {
      final candidate = _bundles[l]?[key];
      if (candidate != null && candidate.isNotEmpty) {
        raw = candidate;
        break;
      }
    }
    return _interpolate(raw, vars);
  }

  String _interpolate(String template, Map<String, Object?>? vars) {
    if (vars == null || vars.isEmpty) return template;
    var out = template;
    vars.forEach((k, v) => out = out.replaceAll('{$k}', '${v ?? ''}'));
    return out;
  }

  static Future<LocaleService> load() async {
    final bundles = <AppLocale, Map<String, String>>{};
    for (final locale in AppLocale.values) {
      final raw = await rootBundle.loadString('assets/locales/${locale.code}.json');
      final map = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v?.toString() ?? ''));
      bundles[locale] = map;
    }
    return LocaleService(bundles);
  }
}

const _prefsKey = 'hanpay_locale';

class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    Future.microtask(_restore);
    return AppLocale.tr;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = appLocaleFromCode(prefs.getString(_prefsKey));
    if (saved != null && saved != state) {
      state = saved;
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.code);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

final localeServiceProvider = FutureProvider<LocaleService>((ref) {
  return LocaleService.load();
});

/// Convenience: synchronous translate fn bound to the current locale.
/// Use only after [localeServiceProvider] has loaded.
typedef Translator = String Function(String key, [Map<String, Object?>? vars]);

final translatorProvider = Provider<Translator>((ref) {
  final locale = ref.watch(localeControllerProvider);
  final serviceAsync = ref.watch(localeServiceProvider);
  return serviceAsync.maybeWhen(
    data: (service) => (key, [vars]) => service.translate(locale, key, vars),
    orElse: () => (key, [_]) => key,
  );
});

/// Currency / number formatter tied to the active locale.
final currencyFormatProvider = Provider.family<NumberFormat, String>((ref, currency) {
  final locale = ref.watch(localeControllerProvider);
  return NumberFormat.currency(
    locale: locale.numberFormatTag,
    symbol: currency == 'USD' ? r'$' : currency,
    decimalDigits: 2,
  );
});

final numberFormatProvider = Provider<NumberFormat>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return NumberFormat.decimalPatternDigits(locale: locale.numberFormatTag, decimalDigits: 2);
});
