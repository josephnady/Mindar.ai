import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps platform keychain/keystore so the JWT never touches plain
/// SharedPreferences. Used by ApiService to attach the Authorization header
/// and by the splash screen to decide whether to route to login or home.
class TokenStorage {
  static const _tokenKey = 'mindar_auth_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
