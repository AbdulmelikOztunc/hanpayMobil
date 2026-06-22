enum ReceiverPhoneCountry {
  tr,
  tm;

  String get apiValue => switch (this) {
        ReceiverPhoneCountry.tr => 'TR',
        ReceiverPhoneCountry.tm => 'TM',
      };

  static ReceiverPhoneCountry? fromApi(String? raw) {
    final u = (raw ?? '').trim().toUpperCase();
    if (u == 'TR') return ReceiverPhoneCountry.tr;
    if (u == 'TM') return ReceiverPhoneCountry.tm;
    return null;
  }
}

const _tmCode = '993';
const _trCode = '90';
const _tmLen = 8;
const _trLen = 10;

String extractReceiverNationalDigits(ReceiverPhoneCountry country, String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (country == ReceiverPhoneCountry.tm) {
    if (digits.startsWith(_tmCode)) digits = digits.substring(3);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.length > _tmLen ? digits.substring(0, _tmLen) : digits;
  }
  if (digits.startsWith(_trCode)) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return digits.length > _trLen ? digits.substring(0, _trLen) : digits;
}

String formatReceiverPhoneInput(ReceiverPhoneCountry country, String value) {
  final trimmed = value.trim();
  final national = extractReceiverNationalDigits(country, value);

  if (national.isEmpty) {
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('+')) {
      return country == ReceiverPhoneCountry.tm ? '+993 ' : '+90 ';
    }
    return '';
  }

  if (country == ReceiverPhoneCountry.tm) {
    final parts = [
      national.substring(0, national.length.clamp(0, 2)),
      if (national.length > 2) national.substring(2, national.length.clamp(2, 5)),
      if (national.length > 5) national.substring(5, national.length.clamp(5, 8)),
    ].where((p) => p.isNotEmpty);
    return '+993 ${parts.join(' ')}';
  }

  final parts = [
    national.substring(0, national.length.clamp(0, 3)),
    if (national.length > 3) national.substring(3, national.length.clamp(3, 6)),
    if (national.length > 6) national.substring(6, national.length.clamp(6, 8)),
    if (national.length > 8) national.substring(8, national.length.clamp(8, 10)),
  ].where((p) => p.isNotEmpty);
  return '+90 ${parts.join(' ')}';
}

/// API: national digits only, e.g. "61234567" / "5551234567".
String receiverPhoneForApi(ReceiverPhoneCountry country, String display) {
  final national = extractReceiverNationalDigits(country, display);
  return national.isNotEmpty ? national : display.trim();
}

bool isReceiverPhoneComplete(ReceiverPhoneCountry country, String display) {
  final national = extractReceiverNationalDigits(country, display);
  return national.length == (country == ReceiverPhoneCountry.tm ? _tmLen : _trLen);
}

String receiverPhonePlaceholderKey(ReceiverPhoneCountry country) =>
    country == ReceiverPhoneCountry.tm ? 'placeholder_phone_tm' : 'placeholder_phone_tr';

({ReceiverPhoneCountry country, String display}) parsePhoneFromStored(
  String? stored, {
  ReceiverPhoneCountry? countryHint,
}) {
  final raw = (stored ?? '').trim();
  final defaultCountry = countryHint ?? ReceiverPhoneCountry.tm;
  if (raw.isEmpty) return (country: defaultCountry, display: '');

  if (countryHint != null) {
    return (country: countryHint, display: formatReceiverPhoneInput(countryHint, raw));
  }

  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith(_trCode) && digits.length > _trLen) {
    return (country: ReceiverPhoneCountry.tr, display: formatReceiverPhoneInput(ReceiverPhoneCountry.tr, raw));
  }
  if (digits.startsWith(_tmCode)) {
    return (country: ReceiverPhoneCountry.tm, display: formatReceiverPhoneInput(ReceiverPhoneCountry.tm, raw));
  }
  if (digits.length == _trLen) {
    return (country: ReceiverPhoneCountry.tr, display: formatReceiverPhoneInput(ReceiverPhoneCountry.tr, digits));
  }
  if (digits.length == _tmLen) {
    return (country: ReceiverPhoneCountry.tm, display: formatReceiverPhoneInput(ReceiverPhoneCountry.tm, digits));
  }

  return (country: defaultCountry, display: formatReceiverPhoneInput(defaultCountry, raw));
}
