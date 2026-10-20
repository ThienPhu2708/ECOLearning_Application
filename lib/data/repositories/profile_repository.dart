import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/user.dart';

/// Nhóm A (hồ sơ): A8 – A11 (Task_Tuan10.docx mục 6.1). Người dùng chính: Ngọc (màn Hồ sơ), Thư (Splash gọi A8).
class ProfileRepository {
  ProfileRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// A8. Thông tin tài khoản + thống kê. Splash gọi để kiểm tra token còn hạn.
  Future<User> me() async => User.fromJson(JsonUtils.asMap(await _api.get('/me')));

  /// A9. Sửa thông tin cá nhân
  Future<User> updateMe({
    required String fullName,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) async {
    final data = await _api.put('/me', data: {
      'fullName': fullName.trim(),
      'phone': phone?.trim(),
      'gender': gender,
      'birthDate': birthDate == null
          ? null
          : '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
    });
    return User.fromJson(JsonUtils.asMap(data));
  }

  /// A10. Đổi ảnh đại diện (file chọn bằng image_picker). Trả đường dẫn ảnh mới.
  Future<String> uploadAvatar(String filePath) async {
    final data = await _api.upload('/me/avatar', filePath: filePath);
    return JsonUtils.asString(JsonUtils.asMap(data)['avatarUrl']);
  }

  /// A11. Đổi mật khẩu
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.post('/me/change-password', data: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }
}
