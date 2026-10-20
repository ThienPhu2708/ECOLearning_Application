import '../../core/utils/formatters.dart';
import '../../core/utils/json_utils.dart';
import 'lesson.dart';

/// Model Khóa học theo chuẩn Mục 7 trong QuyChuanThietKe_App.md.
///
/// Dùng chung cho thẻ khóa học (CourseSummary, mục 5.5 Task_Tuan10.docx), chi tiết khóa học (B3)
/// và "Khóa học của tôi" (G1). Trường nào API không trả thì giữ giá trị mặc định.
class Course {
  static const String defaultInstructorAvatar =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';

  final String id;
  final String title;
  final String category;
  final String categoryId;
  final String instructor;
  final String instructorRole;
  final String instructorAvatar;
  final double rating;
  final int reviewCount;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final String tag;
  final String level;
  final String duration;
  final int durationSeconds;
  final int lessonsCount;
  double progress; // 0 - 100
  bool isEnrolled;
  bool isCompleted;
  bool isFavorite;
  bool canReview;
  final String description;
  final List<String> outcomes;
  final List<Chapter> chapters;

  // "Khóa học của tôi" (G1)
  final String? lastLessonId;
  final bool hasCertificate;

  // Thông tin đánh giá của học viên (nếu có)
  double? myReviewRating;
  String? myReviewComment;

  Course({
    required this.id,
    required this.title,
    required this.category,
    this.categoryId = '',
    required this.instructor,
    this.instructorRole = 'Chuyên gia giảng dạy',
    this.instructorAvatar = defaultInstructorAvatar,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.tag,
    required this.level,
    required this.duration,
    this.durationSeconds = 0,
    required this.lessonsCount,
    this.progress = 0,
    this.isEnrolled = false,
    this.isCompleted = false,
    this.isFavorite = false,
    this.canReview = false,
    this.description = '',
    this.outcomes = const [],
    this.chapters = const [],
    this.lastLessonId,
    this.hasCertificate = false,
    this.myReviewRating,
    this.myReviewComment,
  });

  bool get isFree => price <= 0;

  /// CourseSummary (B2, C1, D2…), chi tiết khóa học (B3) hoặc khóa học của tôi (G1)
  factory Course.fromJson(Map<String, dynamic> json) {
    final seconds = JsonUtils.asInt(json['durationSeconds']);
    final price = JsonUtils.asDouble(json['price']);
    final progress = JsonUtils.asDouble(json['progress']);
    final myReview = JsonUtils.asMap(json['myReview']);
    final instructorInfo = JsonUtils.asMap(json['instructorInfo']);
    return Course(
      id: JsonUtils.asString(json['id']),
      title: JsonUtils.asString(json['title']),
      category: JsonUtils.asString(json['category']),
      categoryId: JsonUtils.asString(json['categoryId']),
      instructor: JsonUtils.asString(json['instructor']),
      instructorRole: JsonUtils.asStringOrNull(instructorInfo['title']) ?? 'Chuyên gia giảng dạy',
      instructorAvatar: JsonUtils.asStringOrNull(json['instructorAvatar']) ?? defaultInstructorAvatar,
      rating: JsonUtils.asDouble(json['rating']),
      reviewCount: JsonUtils.asInt(json['reviewCount']),
      price: price,
      originalPrice: JsonUtils.asDouble(json['originalPrice'], fallback: price),
      imageUrl: JsonUtils.asString(json['imageUrl']),
      tag: JsonUtils.asString(json['tag']),
      level: JsonUtils.asString(json['level']),
      duration: AppFormatters.formatTotalDuration(seconds),
      durationSeconds: seconds,
      lessonsCount: JsonUtils.asInt(json['lessonsCount']),
      progress: progress,
      isEnrolled: JsonUtils.asBool(json['isEnrolled']),
      isCompleted: JsonUtils.asBool(json['isCompleted'], fallback: progress >= 100),
      isFavorite: JsonUtils.asBool(json['isFavorite']),
      canReview: JsonUtils.asBool(json['canReview']),
      description: JsonUtils.asString(json['description']),
      outcomes: JsonUtils.asStringList(json['outcomes']),
      chapters: JsonUtils.asMapList(json['chapters']).map(Chapter.fromJson).toList(),
      lastLessonId: JsonUtils.asStringOrNull(json['lastLessonId']),
      hasCertificate: JsonUtils.asBool(json['hasCertificate']),
      myReviewRating: myReview.isEmpty ? null : JsonUtils.asDouble(myReview['rating']),
      myReviewComment: myReview.isEmpty ? null : JsonUtils.asStringOrNull(myReview['comment']),
    );
  }

  Course copyWith({
    String? id,
    String? title,
    String? category,
    String? categoryId,
    String? instructor,
    String? instructorRole,
    String? instructorAvatar,
    double? rating,
    int? reviewCount,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? tag,
    String? level,
    String? duration,
    int? durationSeconds,
    int? lessonsCount,
    double? progress,
    bool? isEnrolled,
    bool? isCompleted,
    bool? isFavorite,
    bool? canReview,
    String? description,
    List<String>? outcomes,
    List<Chapter>? chapters,
    String? lastLessonId,
    bool? hasCertificate,
    double? myReviewRating,
    String? myReviewComment,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      instructor: instructor ?? this.instructor,
      instructorRole: instructorRole ?? this.instructorRole,
      instructorAvatar: instructorAvatar ?? this.instructorAvatar,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      progress: progress ?? this.progress,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      canReview: canReview ?? this.canReview,
      description: description ?? this.description,
      outcomes: outcomes ?? this.outcomes,
      chapters: chapters ?? this.chapters,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      hasCertificate: hasCertificate ?? this.hasCertificate,
      myReviewRating: myReviewRating ?? this.myReviewRating,
      myReviewComment: myReviewComment ?? this.myReviewComment,
    );
  }
}
