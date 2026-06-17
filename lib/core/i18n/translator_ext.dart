import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';

extension TranslatorRef on WidgetRef {
  String t(String key, [Map<String, Object?>? vars]) =>
      read(translatorProvider)(key, vars);

  String tw(String key, [Map<String, Object?>? vars]) =>
      watch(translatorProvider)(key, vars);
}

extension TranslatorReadRef on Ref {
  String t(String key, [Map<String, Object?>? vars]) =>
      read(translatorProvider)(key, vars);
}
