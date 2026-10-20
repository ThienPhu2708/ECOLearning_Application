import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

/// Nhóm H: Quiz cuối khóa và chứng chỉ (Task_Tuan10.docx mục 6.8). Người dùng chính: Ngọc.
///
/// Đáp án là vị trí 0 – 3 trong `options`, `-1` là chưa chọn.
/// Các hàm trả `Map` theo đúng mẫu JSON trong tài liệu; Ngọc tạo model khi dựng màn hình quiz.
class QuizRepository {
  QuizRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// H1. Thông tin quiz + điều kiện làm bài (canStart, reason, activeAttemptId, lastResult…)
  Future<Map<String, dynamic>> info(String courseId) async => JsonUtils.asMap(await _api.get('/courses/$courseId/quiz'));

  /// H2. Bắt đầu (hoặc tiếp tục lượt đang làm dở): attemptId, expiresAt, questions, answers
  Future<Map<String, dynamic>> start(String courseId) async =>
      JsonUtils.asMap(await _api.post('/courses/$courseId/quiz/start'));

  /// H3. Lưu nháp đáp án. Trả false nếu đã hết giờ.
  Future<bool> saveDraft(int attemptId, List<int> answers) async =>
      JsonUtils.asBool(JsonUtils.asMap(await _api.put('/quiz-attempts/$attemptId/draft', data: {'answers': answers}))['saved']);

  /// H4. Nộp bài: score (thang 10), correct, total, passed, passPercent, timedOut
  Future<Map<String, dynamic>> submit(int attemptId, List<int> answers) async =>
      JsonUtils.asMap(await _api.post('/quiz-attempts/$attemptId/submit', data: {'answers': answers}));

  /// H5. Nhận chứng chỉ (học đủ bài + đạt quiz)
  Future<Map<String, dynamic>> claimCertificate(String courseId) async =>
      JsonUtils.asMap(await _api.post('/courses/$courseId/certificate'));

  /// H6. Danh sách chứng chỉ của tôi
  Future<List<Map<String, dynamic>>> certificates() async => JsonUtils.asMapList(await _api.get('/certificates'));

  /// H7. Chi tiết chứng chỉ: code, studentName, courseTitle, instructor, issuedAt, durationSeconds
  Future<Map<String, dynamic>> certificate(String courseId) async =>
      JsonUtils.asMap(await _api.get('/certificates/$courseId'));
}
