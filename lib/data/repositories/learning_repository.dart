import '../../core/network/api_client.dart';
import '../../core/network/paged_result.dart';
import '../../core/utils/json_utils.dart';
import '../models/course.dart';
import '../models/lesson.dart';

/// Lọc "Khóa học của tôi" (G1)
class MyCourseStatus {
  MyCourseStatus._();
  static const inProgress = 'in-progress';
  static const completed = 'completed';
  static const certified = 'certified';
}

/// Không gian học của một khóa (G2)
class LearningOverview {
  final String courseId;
  final String title;
  final double progress;
  final String? currentLessonId;
  final List<Chapter> chapters;
  final bool quizAvailable;
  final bool quizPassed;
  final bool certificateIssued;
  final bool canReview;

  const LearningOverview({
    required this.courseId,
    required this.title,
    required this.progress,
    required this.currentLessonId,
    required this.chapters,
    required this.quizAvailable,
    required this.quizPassed,
    required this.certificateIssued,
    required this.canReview,
  });

  factory LearningOverview.fromJson(Map<String, dynamic> json) {
    final quiz = JsonUtils.asMap(json['quiz']);
    return LearningOverview(
      courseId: JsonUtils.asString(json['courseId']),
      title: JsonUtils.asString(json['title']),
      progress: JsonUtils.asDouble(json['progress']),
      currentLessonId: JsonUtils.asStringOrNull(json['currentLessonId']),
      chapters: JsonUtils.asMapList(
        json['chapters'],
      ).map(Chapter.fromJson).toList(),
      quizAvailable: JsonUtils.asBool(quiz['available']),
      quizPassed: JsonUtils.asBool(quiz['passed']),
      certificateIssued: JsonUtils.asBool(
        JsonUtils.asMap(json['certificate'])['issued'],
      ),
      canReview: JsonUtils.asBool(json['canReview']),
    );
  }
}

/// Kết quả lưu tiến độ (G4)
class ProgressResult {
  final bool lessonCompleted;
  final double courseProgress;

  const ProgressResult({
    required this.lessonCompleted,
    required this.courseProgress,
  });
}

/// Nhóm G: Học tập và tiến độ (Task_Tuan10.docx mục 6.7 và luồng 6.10). Người dùng chính: Ngọc.
class LearningRepository {
  LearningRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// G1. Khóa học của tôi ([status]: MyCourseStatus.inProgress / completed)
  Future<PagedResult<Course>> myCourses({
    String status = MyCourseStatus.inProgress,
    int page = 1,
  }) async {
    final raw = JsonUtils.asMap(
      await _api.get(
        '/my-courses',
        query: {'status': status, 'page': page, 'separateCertificates': true},
      ),
    );
    final counts = JsonUtils.asMap(raw['counts']);
    // Older servers have two tabs. Partition their real completed-course data
    // locally until the server supports the certified status explicitly.
    if (status == MyCourseStatus.inProgress ||
        !counts.containsKey('completed') ||
        counts.containsKey('certified')) {
      return PagedResult.fromJson(raw, Course.fromJson);
    }
    final all = <String, Course>{};
    var next = 1;
    while (true) {
      final response =
          status == MyCourseStatus.completed && page == 1 && next == 1
          ? raw
          : JsonUtils.asMap(
              await _api.get(
                '/my-courses',
                query: {'status': MyCourseStatus.completed, 'page': next},
              ),
            );
      final batch = PagedResult.fromJson(response, Course.fromJson);
      if (batch.page != next) {
        throw const FormatException('Không tải được trang khóa học tiếp theo.');
      }
      for (final course in batch.items) {
        all[course.id] = course;
      }
      if (!batch.hasMore) break;
      next++;
    }
    final items = all.values
        .where(
          (course) => status == MyCourseStatus.certified
              ? course.hasCertificate
              : !course.hasCertificate,
        )
        .toList();
    const size = 12;
    final totalPages = (items.length + size - 1) ~/ size;
    final selected = page.clamp(1, totalPages == 0 ? 1 : totalPages);
    return PagedResult(
      items: items.skip((selected - 1) * size).take(size).toList(),
      page: selected,
      pageSize: size,
      total: items.length,
      totalPages: totalPages,
    );
  }

  /// G2. Đề cương kèm tiến độ từng bài
  Future<LearningOverview> overview(String courseId) async =>
      LearningOverview.fromJson(
        JsonUtils.asMap(await _api.get('/learning/$courseId')),
      );

  /// G3. Một bài + link video để phát (có lastPositionSeconds để tua tới mốc cũ)
  Future<Lesson> lesson(String courseId, String lessonId) async =>
      Lesson.fromJson(
        JsonUtils.asMap(
          await _api.get('/learning/$courseId/lessons/$lessonId'),
        ),
      );

  /// G4. Lưu tiến độ. Gọi mỗi 15 giây khi phát, khi tạm dừng, chuyển bài, thoát màn hình, app chuyển nền.
  Future<ProgressResult> saveProgress(
    String courseId,
    String lessonId, {
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final map = JsonUtils.asMap(
      await _api.post(
        '/learning/$courseId/lessons/$lessonId/progress',
        data: {
          'positionSeconds': positionSeconds,
          'durationSeconds': durationSeconds,
        },
      ),
    );
    return ProgressResult(
      lessonCompleted: JsonUtils.asBool(map['lessonCompleted']),
      courseProgress: JsonUtils.asDouble(map['courseProgress']),
    );
  }
}
