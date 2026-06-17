double jsonDouble(Object? v) => (v as num?)?.toDouble() ?? 0;

int jsonInt(Object? v) => (v as num?)?.toInt() ?? 0;

String jsonStr(Object? v) => v?.toString() ?? '';

DateTime jsonDate(Object? raw) {
  if (raw == null) return DateTime.now();
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString())?.toUtc() ?? DateTime.now();
}
