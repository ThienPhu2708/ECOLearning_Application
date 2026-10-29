import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

/// Nhóm J: Hỗ trợ — báo cáo vi phạm khóa học và gửi liên hệ (giống website).
class SupportRepository {
  SupportRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// J1. Các loại vi phạm được chọn khi báo cáo
  Future<List<String>> violationTypes() async =>
      JsonUtils.asStringList(await _api.get('/violation-types'));

  /// J2. Báo cáo vi phạm khóa học đã đăng ký; [lessonId] để trống nếu báo cáo cả khóa.
  /// Lỗi 400 theo trường (`type`, `description`, `lessonId`), 403 `NOT_ENROLLED`,
  /// 409 `REPORT_PENDING` (đã có báo cáo đang chờ xử lý cho khóa này).
  Future<void> reportCourse(
    String courseId, {
    required String type,
    required String description,
    String? lessonId,
  }) async {
    await _api.post(
      '/courses/${Uri.encodeComponent(courseId)}/reports',
      data: {
        'type': type,
        'description': description.trim(),
        if (lessonId != null && lessonId.isNotEmpty) 'lessonId': lessonId,
      },
    );
  }

  /// J3. Gửi liên hệ tới đội hỗ trợ (email). Đã đăng nhập thì bỏ trống họ tên / email,
  /// server lấy theo tài khoản. Lỗi 429 khi gửi quá 5 lần trong 10 phút.
  Future<void> contact({
    String? fullName,
    String? email,
    String? subject,
    required String content,
  }) async {
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    await _api.post(
      '/contact',
      data: {
        'fullName': ?clean(fullName),
        'email': ?clean(email),
        'subject': ?clean(subject),
        'content': content.trim(),
      },
    );
  }
}
