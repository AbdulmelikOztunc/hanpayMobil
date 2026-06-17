import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _sessionKey = 'hanpay_auth_session';

class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveSession(String encoded) =>
      _storage.write(key: _sessionKey, value: encoded);

  Future<String?> readSession() => _storage.read(key: _sessionKey);

  Future<void> clearSession() => _storage.delete(key: _sessionKey);
}
