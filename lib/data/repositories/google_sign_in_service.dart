import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_exception.dart';

/// Lấy Google ID token trên máy để gửi cho server (A12 `POST /auth/google`).
/// Cần cấu hình Google Cloud: xem [ApiConfig.googleServerClientId].
class GoogleSignInService {
  GoogleSignInService._();
  static final GoogleSignInService instance = GoogleSignInService._();

  bool _initialized = false;

  /// Trả ID token, hoặc null nếu người dùng tự hủy. Lỗi khác ném [ApiException] với câu tiếng Việt.
  Future<String?> signIn() async {
    if (ApiConfig.googleServerClientId.isEmpty) {
      throw const ApiException(
        code: 'GOOGLE_NOT_CONFIGURED',
        message:
            'Đăng nhập Google chưa được cấu hình (thiếu GOOGLE_SERVER_CLIENT_ID).',
      );
    }
    try {
      final google = GoogleSignIn.instance;
      if (!_initialized) {
        await google.initialize(serverClientId: ApiConfig.googleServerClientId);
        _initialized = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          code: 'GOOGLE_NO_TOKEN',
          message: 'Không lấy được thông tin từ Google, vui lòng thử lại.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw ApiException(
        code: 'GOOGLE_FAILED',
        message: 'Đăng nhập Google không thành công (${e.code.name}).',
      );
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
