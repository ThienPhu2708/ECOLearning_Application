import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu token đăng nhập an toàn trên máy (Keystore Android / Keychain iOS).
/// Token được giữ sẵn trong bộ nhớ để [ApiClient] gắn vào header mà không phải đọc lại mỗi lần gọi API.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _keyToken = 'auth_token';
  static const _keyExpiresAt = 'auth_expires_at';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  DateTime? _expiresAt;

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Gọi 1 lần khi mở app (main.dart). Token đã hết hạn thì xóa luôn.
  Future<void> load() async {
    try {
      _token = await _storage.read(key: _keyToken);
      final exp = await _storage.read(key: _keyExpiresAt);
      _expiresAt = exp == null ? null : DateTime.tryParse(exp);
    } catch (_) {
      _token = null;
      _expiresAt = null;
    }
    if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
      await clear();
    }
  }

  Future<void> save(String token, {DateTime? expiresAt}) async {
    _token = token;
    _expiresAt = expiresAt;
    await _storage.write(key: _keyToken, value: token);
    if (expiresAt != null) {
      await _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String());
    } else {
      await _storage.delete(key: _keyExpiresAt);
    }
  }

  Future<void> clear() async {
    _token = null;
    _expiresAt = null;
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyExpiresAt);
    } catch (_) {
      // Không xóa được trên máy vẫn coi như đã đăng xuất (token trong bộ nhớ đã bỏ)
    }
  }
}
