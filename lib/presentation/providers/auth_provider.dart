import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/google_sign_in_service.dart';
import '../../data/repositories/profile_repository.dart';

/// Trạng thái đăng nhập dùng chung toàn app (khung chung T-0).
///
/// Màn hình đọc bằng `context.watch<AuthProvider>()` (vd: Hồ sơ hiện [user]),
/// gọi hành động bằng `context.read<AuthProvider>().login(...)`.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  }) : _auth = authRepository ?? AuthRepository(),
       _profile = profileRepository ?? ProfileRepository();

  final AuthRepository _auth;
  final ProfileRepository _profile;

  User? _user;
  bool _loggingOut = false;

  /// main.dart gán: dọn dữ liệu cục bộ gắn với phiên (giỏ hàng) khi đăng xuất / hết phiên
  Future<void> Function()? _onSessionCleared;
  set onSessionCleared(Future<void> Function()? callback) =>
      _onSessionCleared = callback;

  User? get user => _user;
  bool get isLoggedIn => TokenStorage.instance.hasToken;

  /// Đang đăng xuất: lỗi 401 lúc này không cần chuyển màn hình lần nữa
  bool get isLoggingOut => _loggingOut;

  /// Splash gọi khi mở app (T-1): còn token thì lấy thông tin tài khoản (A8).
  /// Trả về true nếu vào thẳng Trang chủ được. Mất mạng vẫn coi là đã đăng nhập.
  Future<bool> restoreSession() async {
    if (!isLoggedIn) return false;
    try {
      _user = await _profile.me();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _clear();
        return false;
      }
      return true;
    }
  }

  /// A1. Đăng nhập. Lỗi (sai mật khẩu, tài khoản bị khóa…) ném ApiException để màn hình hiện `message`.
  Future<void> login(String email, String password) async {
    await applySession(await _auth.login(email, password));
  }

  /// A4. Đăng ký bước 3 xong là đăng nhập luôn
  Future<void> register({
    required String fullName,
    required String email,
    required String otp,
    required String password,
  }) async {
    await applySession(
      await _auth.register(
        fullName: fullName,
        email: email,
        otp: otp,
        password: password,
      ),
    );
  }

  /// Lưu phiên đăng nhập (dùng cho A1, A4, A12)
  Future<void> applySession(AuthSession session) async {
    await TokenStorage.instance.save(
      session.token,
      expiresAt: session.expiresAt,
    );
    _user = session.user;
    notifyListeners();
  }

  /// Tải lại thông tin tài khoản (vd: sau khi mua khóa học, số liệu thống kê đổi)
  Future<void> refreshUser() async {
    if (!isLoggedIn) return;
    _user = await _profile.me();
    notifyListeners();
  }

  /// Cập nhật user sau khi sửa hồ sơ (A9) hoặc đổi ảnh (A10)
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// A7. Đăng xuất: báo server thu hồi token, rồi xóa token trên máy dù API thành công hay lỗi mạng.
  Future<void> logout() async {
    _loggingOut = true;
    try {
      await _auth.logout();
    } catch (_) {
      // Bỏ qua: token trên máy vẫn bị xóa bên dưới
    } finally {
      await GoogleSignInService.instance.signOut();
      await _clear();
      _loggingOut = false;
    }
  }

  /// Server báo token hết hạn / bị thu hồi (401)
  Future<void> handleSessionExpired() => _clear();

  Future<void> _clear() async {
    await TokenStorage.instance.clear();
    // Giỏ hàng thuộc về phiên đăng nhập, không để lại cho tài khoản kế tiếp
    await _onSessionCleared?.call();
    _user = null;
    notifyListeners();
  }
}
