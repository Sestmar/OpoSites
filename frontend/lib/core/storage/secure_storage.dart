import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro de tokens JWT.
///
/// Android → EncryptedSharedPreferences.
/// iOS     → Keychain.
/// Web     → memoria (solo para desarrollo; no persiste entre recargas).
///
/// Es la única clase en el proyecto que lee/escribe tokens.
class SecureStorage {
  SecureStorage()
      : _storage = kIsWeb
            ? null
            : const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
              );

  final FlutterSecureStorage? _storage;

  // ── Fallback en memoria para web ──────────────────────────────────────────
  final Map<String, String> _memStore = {};

  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _memStore[key] = value;
    } else {
      await _storage!.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) return _memStore[key];
    return _storage!.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      _memStore.remove(key);
    } else {
      await _storage!.delete(key: key);
    }
  }

  // ── API pública ───────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      Future.wait([
        _write(_accessTokenKey,  accessToken),
        _write(_refreshTokenKey, refreshToken),
      ]);

  Future<String?> getAccessToken()  => _read(_accessTokenKey);
  Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  Future<bool> hasTokens() async {
    final token = await _read(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() =>
      Future.wait([
        _delete(_accessTokenKey),
        _delete(_refreshTokenKey),
      ]);
}
