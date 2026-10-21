import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/json_utils.dart';
import '../models/auth_session.dart';

/// Nhóm A: Tài khoản (Task_Tuan10.docx mục 6.1). Người dùng chính: Thư (A1 – A6, A12), Ngọc (A7).
/// Lưu / xóa token do AuthProvider làm, repository chỉ gọi API.
class AuthRepository {
  AuthRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// A1. Đăng nhập email + mật khẩu
  Future<AuthSession> login(String email, String password) async {
    final data = await _api.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return AuthSession.fromJson(JsonUtils.asMap(data));
  }

  /// A2. Đăng ký bước 1: gửi OTP về email. Trả số giây mã còn hiệu lực.
  Future<int> sendRegisterOtp({
    required String fullName,
    required String email,
  }) async {
    final data = await _api.post(
      '/auth/register/send-otp',
      data: {'fullName': fullName.trim(), 'email': email.trim()},
    );
    return JsonUtils.asInt(
      JsonUtils.asMap(data)['expiresInSeconds'],
      fallback: 300,
    );
  }

  /// A3. Đăng ký bước 2: kiểm tra mã OTP
  Future<bool> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _api.post(
      '/auth/register/verify-otp',
      data: {'email': email.trim(), 'otp': otp.trim()},
    );
    return JsonUtils.asBool(JsonUtils.asMap(data)['valid']);
  }

  /// A4. Đăng ký bước 3: đặt mật khẩu, tạo tài khoản và đăng nhập luôn
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String otp,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/register',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'password': password,
      },
    );
    return AuthSession.fromJson(JsonUtils.asMap(data));
  }

  /// A5. Quên mật khẩu: gửi OTP về email
  Future<int> sendForgotOtp(String email) async {
    final data = await _api.post(
      '/auth/forgot/send-otp',
      data: {'email': email.trim()},
    );
    return JsonUtils.asInt(
      JsonUtils.asMap(data)['expiresInSeconds'],
      fallback: 300,
    );
  }

  /// Quên mật khẩu: kiểm tra mã OTP trước khi cho nhập mật khẩu mới (`POST /auth/forgot/verify-otp`).
  /// Trả null nếu server chưa có API này (404), khi đó app kiểm mã ở bước đặt mật khẩu (A6).
  Future<bool?> verifyForgotOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final data = await _api.post(
        '/auth/forgot/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      return JsonUtils.asBool(JsonUtils.asMap(data)['valid'], fallback: true);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.code == 'API_NOT_FOUND') return null;
      rethrow;
    }
  }

  /// A6. Quên mật khẩu: đặt mật khẩu mới
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/forgot/reset',
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
    );
  }

  /// A7. Đăng xuất: thu hồi token trên server
  Future<void> logout() async {
    await _api.post('/auth/logout');
  }

  /// A12. Đăng nhập Google (tùy chọn, P3)
  Future<AuthSession> loginWithGoogle(String idToken) async {
    final data = await _api.post('/auth/google', data: {'idToken': idToken});
    return AuthSession.fromJson(JsonUtils.asMap(data));
  }
}
