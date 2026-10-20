import '../../core/utils/json_utils.dart';
import 'user.dart';

/// Kết quả đăng nhập / đăng ký (A1, A4, A12): `{ "token", "expiresAt", "user" }`
class AuthSession {
  final String token;
  final DateTime? expiresAt;
  final User user;

  const AuthSession({required this.token, required this.expiresAt, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: JsonUtils.asString(json['token']),
      expiresAt: JsonUtils.asDate(json['expiresAt']),
      user: User.fromJson(JsonUtils.asMap(json['user'])),
    );
  }
}
