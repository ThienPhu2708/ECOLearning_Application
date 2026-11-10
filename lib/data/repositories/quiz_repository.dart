import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

/// Nhóm H: Quiz cuối khóa và chứng chỉ (Task_Tuan10.docx mục 6.8). Người dùng chính: Ngọc.
///
/// Đáp án là vị trí 0 – 3 trong `options`, `-1` là chưa chọn.
/// Các hàm trả `Map` theo đúng mẫu JSON trong tài liệu; Ngọc tạo model khi dựng màn hình quiz.
class QuizRepository {
  QuizRepository({ApiClient? client})
    : _api = client ?? ApiClient.instance,
      _usePersistentClientKey = client == null;
  final ApiClient _api;
  final bool _usePersistentClientKey;
  static const _clientKeyPreference = 'quiz.clientKey';
  static Future<String>? _installationClientKey;
  late final Future<String> _clientKey = _usePersistentClientKey
      ? (_installationClientKey ??= _loadClientKey())
      : Future.value(_newClientKey());

  static String _newClientKey() => List.generate(
    32,
    (_) => Random.secure().nextInt(16).toRadixString(16),
  ).join();

  static Future<String> _loadClientKey() async {
    final preferences = SharedPreferencesAsync();
    try {
      final stored = await preferences.getString(_clientKeyPreference);
      if (stored != null && RegExp(r'^[a-f0-9]{32}$').hasMatch(stored)) {
        return stored;
      }
      final key = _newClientKey();
      await preferences.setString(_clientKeyPreference, key);
      return key;
    } on Exception {
      return _newClientKey();
    }
  }

  final Map<int, String> _writers = {};
  Future<Map<String, dynamic>> takeOver(String courseId) =>
      _start(courseId, true);
  Future<Map<String, dynamic>> _start(String courseId, bool takeover) async {
    final result = JsonUtils.asMap(
      await _api.post(
        '/courses/$courseId/quiz/start',
        data: {'clientKey': await _clientKey, 'takeover': takeover},
      ),
    );
    final token = JsonUtils.asStringOrNull(result['writerToken']);
    if (token != null) _writers[JsonUtils.asInt(result['attemptId'])] = token;
    return result;
  }

  /// H1. Thông tin quiz + điều kiện làm bài (canStart, reason, activeAttemptId, lastResult…)
  Future<Map<String, dynamic>> info(String courseId) async =>
      JsonUtils.asMap(await _api.get('/courses/$courseId/quiz'));

  /// H2. Bắt đầu (hoặc tiếp tục lượt đang làm dở): attemptId, expiresAt, questions, answers
  Future<Map<String, dynamic>> start(String courseId) async =>
      _start(courseId, false);

  /// H3. Lưu nháp đáp án. Trả false nếu đã hết giờ.
  Future<bool> saveDraft(int attemptId, List<int> answers) async =>
      JsonUtils.asBool(
        JsonUtils.asMap(
          await _api.put(
            '/quiz-attempts/$attemptId/draft',
            data: {
              'answers': answers,
              if (_writers.containsKey(attemptId))
                'writerToken': _writers[attemptId],
            },
          ),
        )['saved'],
      );

  /// H4. Nộp bài: score (thang 10), correct, total, passed, passPercent, timedOut
  Future<Map<String, dynamic>> submit(int attemptId, List<int> answers) async =>
      JsonUtils.asMap(
        await _api.post(
          '/quiz-attempts/$attemptId/submit',
          data: {
            'answers': answers,
            if (_writers.containsKey(attemptId))
              'writerToken': _writers[attemptId],
          },
        ),
      );

  Future<Map<String, dynamic>> resume(
    int attemptId, {
    bool takeover = false,
  }) async {
    final data = JsonUtils.asMap(
      await _api.post(
        '/quiz-attempts/$attemptId/resume',
        data: {'clientKey': await _clientKey, 'takeover': takeover},
      ),
    );
    final token = JsonUtils.asStringOrNull(data['writerToken']);
    if (token != null) _writers[JsonUtils.asInt(data['attemptId'])] = token;
    return data;
  }

  Future<List<Map<String, dynamic>>> history(String courseId) async =>
      JsonUtils.asMapList(await _api.get('/courses/$courseId/quiz/history'));
  Future<Map<String, dynamic>> result(int attemptId) async =>
      JsonUtils.asMap(await _api.get('/quiz-attempts/$attemptId/result'));
  Future<Map<String, dynamic>> support(String courseId) async =>
      JsonUtils.asMap(await _api.get('/courses/$courseId/quiz/support'));
  Future<void> report(
    int attemptId,
    int questionId,
    String reason,
    String content,
  ) async {
    await _api.post(
      '/quiz-attempts/$attemptId/reports',
      data: {'questionId': questionId, 'reason': reason, 'content': content},
    );
  }

  Future<void> appeal(String courseId, int attemptId, String content) async {
    await _api.post(
      '/courses/$courseId/quiz/appeals',
      data: {'attemptId': attemptId, 'content': content},
    );
  }

  Future<Map<String, dynamic>> startRetake(
    String courseId,
    int reviewId, {
    bool takeover = false,
  }) async {
    final data = JsonUtils.asMap(
      await _api.post(
        '/courses/$courseId/quiz/retakes/$reviewId/start',
        data: {'clientKey': await _clientKey, 'takeover': takeover},
      ),
    );
    final token = JsonUtils.asStringOrNull(data['writerToken']);
    if (token != null) _writers[JsonUtils.asInt(data['attemptId'])] = token;
    return data;
  }

  Future<int> visibility(
    int attemptId,
    String eventKey, {
    required bool returned,
  }) async => JsonUtils.asInt(
    JsonUtils.asMap(
      await _api.post(
        '/quiz-attempts/$attemptId/visibility',
        data: {
          'eventKey': eventKey,
          'returned': returned,
          'writerToken': _writers[attemptId],
        },
      ),
    )['count'],
  );
  Future<Map<String, dynamic>> checkWriter(int attemptId) async =>
      JsonUtils.asMap(
        await _api.post(
          '/quiz-attempts/$attemptId/writer/check',
          data: {'writerToken': _writers[attemptId]},
        ),
      );

  /// H5. Nhận chứng chỉ (học đủ bài + đạt quiz)
  Future<Map<String, dynamic>> claimCertificate(String courseId) async =>
      JsonUtils.asMap(await _api.post('/courses/$courseId/certificate'));

  /// H6. Danh sách chứng chỉ của tôi
  Future<List<Map<String, dynamic>>> certificates() async =>
      JsonUtils.asMapList(await _api.get('/certificates'));

  /// H7. Chi tiết chứng chỉ: code, studentName, courseTitle, instructor, issuedAt, durationSeconds
  Future<Map<String, dynamic>> certificate(String courseId) async =>
      JsonUtils.asMap(await _api.get('/certificates/$courseId'));
}
