import '../../core/utils/formatters.dart';
import '../../core/utils/json_utils.dart';

/// Model Bài học và Video trong khóa học
class Lesson {
  final String id;
  final String title;
  final String duration; // VD: "12:40"
  final int durationSeconds; // Số giây (VD: 760)
  bool isCompleted; // Tích xanh khi xem >= 80% (server quyết định, G4)
  final bool isFree; // Cho phép xem thử (Preview) - API: isPreview
  bool isCurrent; // Đang phát
  int lastPositionSeconds; // Mốc thời gian xem dở
  final String? videoSummary;
  final String? videoUrl; // Chỉ có khi gọi G3 (bài đã sở hữu) hoặc B8 (xem thử)

  Lesson({
    required this.id,
    required this.title,
    required this.duration,
    required this.durationSeconds,
    this.isCompleted = false,
    this.isFree = false,
    this.isCurrent = false,
    this.lastPositionSeconds = 0,
    this.videoSummary,
    this.videoUrl,
  });

  /// Bài trong đề cương (B3, G2) hoặc chi tiết một bài để phát (G3)
  factory Lesson.fromJson(Map<String, dynamic> json) {
    final seconds = JsonUtils.asInt(json['durationSeconds']);
    return Lesson(
      id: JsonUtils.asString(json['id']),
      title: JsonUtils.asString(json['title']),
      duration: AppFormatters.formatDurationFromSeconds(seconds),
      durationSeconds: seconds,
      isCompleted: JsonUtils.asBool(json['isCompleted']),
      isFree: JsonUtils.asBool(json['isPreview']),
      lastPositionSeconds: JsonUtils.asInt(json['lastPositionSeconds']),
      videoSummary: JsonUtils.asStringOrNull(json['summary']),
      videoUrl: JsonUtils.asStringOrNull(json['videoUrl']),
    );
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? duration,
    int? durationSeconds,
    bool? isCompleted,
    bool? isFree,
    bool? isCurrent,
    int? lastPositionSeconds,
    String? videoSummary,
    String? videoUrl,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      isFree: isFree ?? this.isFree,
      isCurrent: isCurrent ?? this.isCurrent,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      videoSummary: videoSummary ?? this.videoSummary,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

/// Model Chương học (Nhóm bài học dạng Accordion)
class Chapter {
  final String id;
  final String title;
  final List<Lesson> lessons;

  Chapter({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: JsonUtils.asString(json['id']),
      title: JsonUtils.asString(json['title']),
      lessons: JsonUtils.asMapList(json['lessons']).map(Lesson.fromJson).toList(),
    );
  }
}
